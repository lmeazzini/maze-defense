extends GutTest
## Mira das torres: primeiro da fila (menor remaining_distance),
## mais forte (maior HP atual) e exclusão por alcance.

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const ARCHER := preload("res://data/towers/archer.tres")

var grid: GridManager
var registry: EnemyRegistry


func before_each() -> void:
	grid = GridManager.new()
	add_child_autofree(grid)
	var map := MapData.new()
	map.grid_size = Vector2i(10, 5)
	map.entry_cell = Vector2i(0, 2)
	map.exit_cell = Vector2i(9, 2)
	grid.setup(map)
	registry = EnemyRegistry.new()
	add_child_autofree(registry)


func _spawn_at(seconds_walked: float, hp: float = 50.0) -> Enemy:
	var data := EnemyData.new()
	data.max_hp = hp
	data.speed = 64.0
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	add_child_autofree(enemy)
	enemy.set_physics_process(false)
	enemy.setup(grid, data)
	enemy.start()
	enemy._physics_process(seconds_walked)
	registry.register(enemy)
	return enemy


func _make_tower(targeting: TowerData.Targeting, range_px: float, at_cell: Vector2i) -> Tower:
	var data := TowerData.new()
	data.targeting = targeting
	var lvl := TowerLevelData.new()
	lvl.range_px = range_px
	data.levels = [lvl] as Array[TowerLevelData]
	var tower := Tower.new()
	add_child_autofree(tower)
	tower.set_physics_process(false)
	tower.setup(data, registry, null, at_cell)
	tower.position = grid.cell_to_world(at_cell)
	return tower


func test_first_in_path_picks_leader() -> void:
	var behind := _spawn_at(1.0)
	var leader := _spawn_at(3.0)
	assert_lt(leader.remaining_distance, behind.remaining_distance)
	var tower := _make_tower(TowerData.Targeting.FIRST_IN_PATH, 1000.0, Vector2i(5, 0))
	assert_eq(tower._acquire_target(), leader)


func test_first_in_path_correct_after_reroute() -> void:
	var a := _spawn_at(3.0)  # à frente na rota direta
	var b := _spawn_at(1.0)
	grid.commit_tower(Vector2i(4, 2))  # desvio recalcula remaining_distance de ambos
	var tower := _make_tower(TowerData.Targeting.FIRST_IN_PATH, 1000.0, Vector2i(5, 0))
	var expected := a if a.remaining_distance < b.remaining_distance else b
	assert_eq(tower._acquire_target(), expected)


func test_strongest_picks_highest_current_hp() -> void:
	var weak := _spawn_at(2.0, 30.0)
	var strong := _spawn_at(1.0, 200.0)
	var tower := _make_tower(TowerData.Targeting.STRONGEST, 1000.0, Vector2i(5, 0))
	assert_eq(tower._acquire_target(), strong)
	# HP atual, não máximo: ferir o forte abaixo do fraco muda o alvo
	strong.take_damage(180.0, TowerData.DamageType.MAGIC)
	assert_eq(tower._acquire_target(), weak)


func test_out_of_range_excluded() -> void:
	var enemy := _spawn_at(0.0)  # na entrada (0,2)
	var tower := _make_tower(TowerData.Targeting.FIRST_IN_PATH, 64.0, Vector2i(9, 0))
	assert_null(tower._acquire_target(), "Inimigo fora do alcance")
	assert_not_null(enemy)


func test_archer_full_cycle_projectile_hits() -> void:
	var enemy := _spawn_at(2.0)
	var hp_before := enemy.current_hp
	var projectiles := Node2D.new()
	add_child_autofree(projectiles)
	var tower := Tower.new()
	add_child_autofree(tower)
	tower.set_physics_process(false)
	tower.setup(ARCHER, registry, projectiles, Vector2i(2, 1))
	tower.position = grid.cell_to_world(Vector2i(2, 1))
	tower._physics_process(0.016)  # cooldown zerado → atira
	assert_eq(projectiles.get_child_count(), 1, "Flecha instanciada")
	var arrow: Projectile = projectiles.get_child(0)
	arrow._physics_process(1.0)  # 520 px num tick: alcança e impacta
	assert_almost_eq(enemy.current_hp, hp_before - ARCHER.levels[0].damage, 0.01)


func test_projectile_expires_on_dead_target_without_crash() -> void:
	var enemy := _spawn_at(2.0)
	var projectiles := Node2D.new()
	add_child_autofree(projectiles)
	var tower := Tower.new()
	add_child_autofree(tower)
	tower.set_physics_process(false)
	tower.setup(ARCHER, registry, projectiles, Vector2i(2, 1))
	tower.position = grid.cell_to_world(Vector2i(2, 1))
	tower._physics_process(0.016)
	var arrow: Projectile = projectiles.get_child(0)
	enemy.take_damage(999.0, TowerData.DamageType.MAGIC)  # morre em voo
	arrow._physics_process(1.0)  # segue até a última posição e expira
	assert_true(arrow.is_queued_for_deletion(), "Flecha expira sem alvo")
