extends GutTest
## Testes do núcleo crítico: validação anti-bloqueio, revert, becos sem saída,
## cache de caminhos e ausência de passos diagonais.

const NO_ENEMIES: Array[Vector2i] = []

var grid: GridManager


func before_each() -> void:
	grid = GridManager.new()
	add_child_autofree(grid)
	var map := MapData.new()
	map.grid_size = Vector2i(10, 7)
	map.entry_cell = Vector2i(0, 3)
	map.exit_cell = Vector2i(9, 3)
	grid.setup(map)


func test_path_exists_on_empty_grid() -> void:
	var path := grid.entry_path()
	assert_gt(path.size(), 1, "Deve existir caminho entrada→saída na grade vazia")
	assert_eq(path[0], grid.cell_to_world(grid.entry_cell))
	assert_eq(path[-1], grid.cell_to_world(grid.exit_cell))


func test_rejects_out_of_bounds() -> void:
	assert_eq(grid.validate_placement(Vector2i(-1, 0), NO_ENEMIES), GridManager.PlacementError.OUT_OF_BOUNDS)
	assert_eq(grid.validate_placement(Vector2i(10, 3), NO_ENEMIES), GridManager.PlacementError.OUT_OF_BOUNDS)


func test_rejects_entry_and_exit_cells() -> void:
	assert_eq(grid.validate_placement(grid.entry_cell, NO_ENEMIES), GridManager.PlacementError.ENTRY_EXIT_CELL)
	assert_eq(grid.validate_placement(grid.exit_cell, NO_ENEMIES), GridManager.PlacementError.ENTRY_EXIT_CELL)


func test_rejects_occupied_cell() -> void:
	grid.commit_tower(Vector2i(4, 4))
	assert_eq(grid.validate_placement(Vector2i(4, 4), NO_ENEMIES), GridManager.PlacementError.CELL_OCCUPIED)


func test_rejects_fixed_obstacle() -> void:
	var map := MapData.new()
	map.grid_size = Vector2i(10, 7)
	map.entry_cell = Vector2i(0, 3)
	map.exit_cell = Vector2i(9, 3)
	map.blocked_cells = [Vector2i(5, 5)] as Array[Vector2i]
	grid.setup(map)
	assert_true(grid.is_fixed_obstacle(Vector2i(5, 5)))
	assert_eq(grid.validate_placement(Vector2i(5, 5), NO_ENEMIES), GridManager.PlacementError.CELL_OCCUPIED)


func test_rejects_enemy_cell() -> void:
	var enemies: Array[Vector2i] = [Vector2i(3, 3), Vector2i(4, 3)]
	assert_eq(grid.validate_placement(Vector2i(3, 3), enemies), GridManager.PlacementError.ENEMY_ON_CELL)
	assert_eq(grid.validate_placement(Vector2i(4, 3), enemies), GridManager.PlacementError.ENEMY_ON_CELL)
	assert_eq(grid.validate_placement(Vector2i(5, 3), enemies), GridManager.PlacementError.OK)


func test_anti_block_closing_only_gap() -> void:
	# Parede vertical em x=5 com uma única brecha em y=3
	for y in grid.grid_size.y:
		if y != 3:
			grid.commit_tower(Vector2i(5, y))
	assert_gt(grid.entry_path().size(), 0, "Com a brecha aberta ainda há caminho")
	# Fechar a brecha deve ser rejeitado
	assert_eq(grid.validate_placement(Vector2i(5, 3), NO_ENEMIES), GridManager.PlacementError.BLOCKS_PATH)


func test_validate_never_mutates_grid() -> void:
	for y in grid.grid_size.y:
		if y != 3:
			grid.commit_tower(Vector2i(5, y))
	grid.validate_placement(Vector2i(5, 3), NO_ENEMIES)
	assert_false(grid.is_solid(Vector2i(5, 3)), "Revert: célula testada não pode ficar sólida")
	assert_gt(grid.entry_path().size(), 0, "Caminho continua existindo após validação rejeitada")
	# E uma colocação válida em seguida continua funcionando
	assert_eq(grid.validate_placement(Vector2i(2, 0), NO_ENEMIES), GridManager.PlacementError.OK)


func test_dead_end_trap_rejected() -> void:
	# Inimigo no canto (0,6); selar o bolsão não corta entrada→saída,
	# mas prende o inimigo — deve ser rejeitado.
	grid.commit_tower(Vector2i(0, 5))
	var enemies: Array[Vector2i] = [Vector2i(0, 6)]
	assert_eq(grid.validate_placement(Vector2i(1, 6), enemies), GridManager.PlacementError.BLOCKS_PATH)
	# Sem o inimigo lá, a mesma colocação é válida
	assert_eq(grid.validate_placement(Vector2i(1, 6), NO_ENEMIES), GridManager.PlacementError.OK)


func test_path_reroutes_after_commit_and_remove() -> void:
	var direct := grid.entry_path()
	grid.commit_tower(Vector2i(5, 3))
	var detour := grid.entry_path()
	assert_gt(detour.size(), direct.size(), "Caminho com desvio deve ser mais longo")
	grid.remove_tower(Vector2i(5, 3))
	assert_eq(grid.entry_path().size(), direct.size(), "Remover a torre restaura o caminho direto")


func test_no_diagonal_steps() -> void:
	grid.commit_tower(Vector2i(4, 3))
	grid.commit_tower(Vector2i(4, 2))
	var path := grid.entry_path()
	for i in path.size() - 1:
		var step := path[i + 1] - path[i]
		var dx := absf(step.x)
		var dy := absf(step.y)
		assert_true(
			(dx == float(GridManager.CELL_SIZE) and dy == 0.0)
			or (dx == 0.0 and dy == float(GridManager.CELL_SIZE)),
			"Passo %d deve ser ortogonal de exatamente 1 célula: %s" % [i, step]
		)


func test_commit_emits_grid_changed() -> void:
	watch_signals(GameEvents)
	grid.commit_tower(Vector2i(6, 1))
	assert_signal_emitted(GameEvents, "grid_changed")


func test_world_cell_roundtrip() -> void:
	var cell := Vector2i(7, 2)
	assert_eq(grid.world_to_cell(grid.cell_to_world(cell)), cell)
	assert_eq(grid.cell_to_world(Vector2i.ZERO), Vector2(32, 32), "Centro da célula (0,0)")
