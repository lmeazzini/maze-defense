extends GutTest
## Movimento, reroteamento mid-cell, vazamento, slow, armadura e registry.
## Física controlada manualmente (set_physics_process(false) + ticks explícitos).

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const CELL := 64.0

var grid: GridManager


func before_each() -> void:
	grid = GridManager.new()
	add_child_autofree(grid)
	var map := MapData.new()
	map.grid_size = Vector2i(8, 5)
	map.entry_cell = Vector2i(0, 2)
	map.exit_cell = Vector2i(7, 2)
	grid.setup(map)


func _make_data(speed: float = 64.0, armor: float = 0.0) -> EnemyData:
	var d := EnemyData.new()
	d.max_hp = 50.0
	d.speed = speed
	d.armor = armor
	d.gold_reward = 5
	d.lives_cost = 1
	return d


func _spawn(data: EnemyData = null) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	add_child_autofree(enemy)
	enemy.set_physics_process(false)
	enemy.setup(grid, data if data != null else _make_data())
	enemy.start()
	return enemy


func test_initial_state() -> void:
	var enemy := _spawn()
	assert_eq(enemy.position, grid.cell_to_world(grid.entry_cell))
	# 7 segmentos de 64px até a saída
	assert_almost_eq(enemy.remaining_distance, 7.0 * CELL, 0.01)
	assert_eq(enemy.current_cell(), Vector2i(0, 2))


func test_movement_consumes_remaining_distance() -> void:
	var enemy := _spawn()
	enemy._physics_process(0.5)  # 64 px/s * 0.5s = 32 px
	assert_almost_eq(enemy.position.x, grid.cell_to_world(grid.entry_cell).x + 32.0, 0.01)
	assert_almost_eq(enemy.remaining_distance, 7.0 * CELL - 32.0, 0.01)


func test_leak_emits_and_forwards_lives_cost() -> void:
	var registry := EnemyRegistry.new()
	add_child_autofree(registry)
	var enemy := _spawn()
	registry.register(enemy)
	watch_signals(enemy)
	watch_signals(GameEvents)
	for i in 10:
		enemy._physics_process(1.0)
	assert_signal_emitted(enemy, "leaked")
	assert_signal_emitted_with_parameters(GameEvents, "enemy_leaked", [enemy, 1])
	assert_eq(registry.alive.size(), 0, "Registry remove o inimigo que vazou")


func test_reroute_keeps_position_and_heading() -> void:
	var enemy := _spawn()
	enemy._physics_process(1.5)  # 96 px: entre a célula (1,2) e a (2,2)
	var pos_before := enemy.position
	var heading_before := enemy.next_cell()
	var remaining_before := enemy.remaining_distance
	assert_eq(heading_before, Vector2i(2, 2), "Sanidade: indo em direção à célula (2,2)")

	grid.commit_tower(Vector2i(4, 2))  # bloqueia a rota direta à frente

	assert_eq(enemy.position, pos_before, "Reroute não teleporta")
	assert_eq(enemy.next_cell(), heading_before, "Reroute mantém o segmento em andamento")
	assert_gt(enemy.remaining_distance, remaining_before, "Desvio aumenta a distância restante")


func test_reroute_then_walks_to_exit() -> void:
	var enemy := _spawn()
	enemy._physics_process(1.5)
	grid.commit_tower(Vector2i(4, 2))
	watch_signals(enemy)
	for i in 16:
		enemy._physics_process(1.0)
	assert_signal_emitted(enemy, "leaked", "Inimigo completa o desvio e chega à saída")


func test_occupied_cells_includes_current_and_next_dedup() -> void:
	var registry := EnemyRegistry.new()
	add_child_autofree(registry)
	var a := _spawn()
	var b := _spawn()
	registry.register(a)
	registry.register(b)
	# Ambos parados na entrada: atual == próxima == entrada → 1 célula única
	assert_eq(registry.occupied_cells(), [Vector2i(0, 2)] as Array[Vector2i])
	a._physics_process(1.0)  # a chega ao centro de (1,2), indo para (2,2)
	var cells := registry.occupied_cells()
	assert_has(cells, Vector2i(0, 2))
	assert_has(cells, Vector2i(1, 2))
	assert_has(cells, Vector2i(2, 2))
	assert_eq(cells.size(), 3)


func test_armor_reduces_only_physical() -> void:
	var enemy := _spawn(_make_data(64.0, 0.7))
	enemy.take_damage(10.0, TowerData.DamageType.PHYSICAL)
	assert_almost_eq(enemy.current_hp, 50.0 - 3.0, 0.01, "Físico reduzido em 70%")
	enemy.take_damage(10.0, TowerData.DamageType.EXPLOSIVE)
	assert_almost_eq(enemy.current_hp, 47.0 - 10.0, 0.01, "Explosivo ignora armadura")


func test_death_emits_and_pays_gold() -> void:
	var registry := EnemyRegistry.new()
	add_child_autofree(registry)
	var enemy := _spawn()
	registry.register(enemy)
	watch_signals(GameEvents)
	enemy.take_damage(100.0, TowerData.DamageType.MAGIC)
	assert_signal_emitted_with_parameters(GameEvents, "enemy_died", [enemy, 5])
	assert_eq(registry.alive.size(), 0)


func test_slow_keeps_strongest_and_renews_duration() -> void:
	var enemy := _spawn()
	enemy.apply_slow(0.5, 2.0)
	assert_almost_eq(enemy.effective_speed(), 32.0, 0.01)
	# Slow mais fraco não substitui o fator, mas renova a duração
	enemy.apply_slow(0.8, 2.0)
	assert_almost_eq(enemy.effective_speed(), 32.0, 0.01)
	# Duração expira com o tempo (descontada no tick de física)
	for i in 5:
		enemy._physics_process(0.5)
	assert_almost_eq(enemy.effective_speed(), 64.0, 0.01, "Slow expirado")


func test_cannot_place_on_enemy_path_cells() -> void:
	var registry := EnemyRegistry.new()
	add_child_autofree(registry)
	var enemy := _spawn()
	registry.register(enemy)
	enemy._physics_process(1.5)  # entre (1,2) e (2,2)
	var cells := registry.occupied_cells()
	for cell in cells:
		assert_eq(
			grid.validate_placement(cell, cells),
			GridManager.PlacementError.ENEMY_ON_CELL,
			"Célula %s ocupada por inimigo deve ser rejeitada" % cell
		)