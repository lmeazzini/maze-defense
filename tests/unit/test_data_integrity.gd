extends GutTest
## Carrega TODOS os .tres de data/ e valida invariantes — pega erro de
## edição de balanceamento para sempre.

const TOWERS_DIR := "res://data/towers"
const ENEMIES_DIR := "res://data/enemies"
const MAPS_DIR := "res://data/maps"


func _tres_in(dir_path: String) -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(dir_path)
	assert_not_null(dir, "Diretório existe: %s" % dir_path)
	for file in dir.get_files():
		# Em builds exportados os .tres viram .tres.remap; aqui é sempre dev
		if file.ends_with(".tres"):
			paths.append(dir_path + "/" + file)
	return paths


func test_towers_have_three_valid_levels() -> void:
	var paths := _tres_in(TOWERS_DIR)
	assert_eq(paths.size(), 4, "4 torres")
	for path in paths:
		var tower: TowerData = load(path)
		assert_not_null(tower, path)
		assert_eq(tower.levels.size(), 3, "%s: exatamente 3 níveis" % path)
		for i in 3:
			var lvl := tower.levels[i]
			assert_gt(lvl.cost, 0, "%s nível %d: custo positivo" % [path, i + 1])
			assert_gt(lvl.damage, 0.0, "%s nível %d: dano positivo" % [path, i + 1])
			assert_gt(lvl.range_px, 0.0, "%s nível %d: alcance positivo" % [path, i + 1])
			assert_gt(lvl.fire_rate, 0.0, "%s nível %d: cadência positiva" % [path, i + 1])
		# name_key registrada nas strings (get_text falha em assert se faltar)
		assert_ne(Strings.get_text(tower.name_key), "", path)


func test_enemies_are_valid() -> void:
	var paths := _tres_in(ENEMIES_DIR)
	assert_eq(paths.size(), 5, "5 tipos de inimigo")
	for path in paths:
		var enemy: EnemyData = load(path)
		assert_not_null(enemy, path)
		assert_gt(enemy.max_hp, 0.0, path)
		assert_gt(enemy.speed, 0.0, path)
		assert_between(enemy.armor, 0.0, 0.9, path)
		assert_gt(enemy.gold_reward, 0, path)
		assert_gt(enemy.lives_cost, 0, path)
		if enemy.is_boss:
			assert_eq(enemy.lives_cost, 5, "%s: boss vaza 5 vidas" % path)


func test_maps_are_valid_and_pathable() -> void:
	var paths := _tres_in(MAPS_DIR)
	for path in paths:
		var map: MapData = load(path)
		assert_not_null(map, path)
		assert_ne(map.entry_cell, map.exit_cell, path)
		var region := Rect2i(Vector2i.ZERO, map.grid_size)
		assert_true(region.has_point(map.entry_cell), "%s: entrada dentro da grade" % path)
		assert_true(region.has_point(map.exit_cell), "%s: saída dentro da grade" % path)
		assert_false(map.entry_cell in map.blocked_cells, "%s: entrada não bloqueada" % path)
		assert_false(map.exit_cell in map.blocked_cells, "%s: saída não bloqueada" % path)
		assert_between(map.waves.size(), 15, 20, "%s: 15-20 ondas" % path)
		assert_gt(map.starting_gold, 0, path)
		assert_gt(map.starting_lives, 0, path)
		for w in map.waves.size():
			var wave := map.waves[w]
			assert_gt(wave.groups.size(), 0, "%s onda %d: tem grupos" % [path, w + 1])
			for group in wave.groups:
				assert_not_null(group.enemy, "%s onda %d: inimigo definido" % [path, w + 1])
				assert_gt(group.count, 0, "%s onda %d: count > 0" % [path, w + 1])
				assert_gt(group.hp_multiplier, 0.0, "%s onda %d" % [path, w + 1])
		# Pathable só com obstáculos fixos
		var grid := GridManager.new()
		add_child_autofree(grid)
		grid.setup(map)
		assert_gt(grid.entry_path().size(), 1, "%s: entrada→saída pathable" % path)
