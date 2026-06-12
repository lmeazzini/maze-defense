extends GutTest
## FSM de ondas: spawn por fila, bônus de antecipação, conclusão de onda,
## vitória após a última. Física tickada manualmente.

var grid: GridManager
var registry: EnemyRegistry
var economy: Economy
var container: Node2D
var waves: WaveManager


func before_each() -> void:
	grid = GridManager.new()
	add_child_autofree(grid)
	var map := _make_map()
	grid.setup(map)
	registry = EnemyRegistry.new()
	add_child_autofree(registry)
	container = Node2D.new()
	add_child_autofree(container)
	economy = Economy.new()
	add_child_autofree(economy)
	var rules := GameRules.new()
	rules.early_call_gold_per_second = 1.0
	economy.setup(map, rules)
	waves = WaveManager.new()
	add_child_autofree(waves)
	waves.set_physics_process(false)
	waves.setup(map, grid, registry, container, economy, rules)


func _make_map() -> MapData:
	var map := MapData.new()
	map.grid_size = Vector2i(8, 5)
	map.entry_cell = Vector2i(0, 2)
	map.exit_cell = Vector2i(7, 2)
	map.starting_gold = 100
	map.starting_lives = 20
	var normal := EnemyData.new()
	normal.max_hp = 50.0
	normal.speed = 64.0
	normal.gold_reward = 5
	normal.lives_cost = 1

	var g1 := SpawnGroupData.new()
	g1.enemy = normal
	g1.count = 2
	g1.spawn_interval = 0.5
	var w1 := WaveData.new()
	w1.groups = [g1] as Array[SpawnGroupData]
	w1.end_bonus_gold = 10
	w1.prep_time = 30.0

	var g2 := SpawnGroupData.new()
	g2.enemy = normal
	g2.count = 1
	var w2 := WaveData.new()
	w2.groups = [g2] as Array[SpawnGroupData]
	w2.end_bonus_gold = 20
	w2.prep_time = 30.0

	map.waves = [w1, w2] as Array[WaveData]
	return map


func _kill_all() -> void:
	for enemy in registry.alive.duplicate():
		enemy.take_damage(9999.0, TowerData.DamageType.MAGIC)


func test_spawning_follows_intervals() -> void:
	waves.call_next_wave()
	assert_eq(waves.state, WaveManager.State.SPAWNING)
	waves._physics_process(0.0)
	assert_eq(registry.alive.size(), 1, "Primeiro spawn imediato (delay 0)")
	waves._physics_process(0.25)
	assert_eq(registry.alive.size(), 1, "Segundo ainda não (intervalo 0.5)")
	waves._physics_process(0.25)
	assert_eq(registry.alive.size(), 2, "Segundo spawn após 0.5s")
	assert_eq(waves.state, WaveManager.State.IN_PROGRESS)


func test_wave_completion_pays_bonus_and_returns_to_prep() -> void:
	watch_signals(GameEvents)
	waves.call_next_wave()
	waves._physics_process(1.0)
	_kill_all()
	assert_signal_emitted_with_parameters(GameEvents, "wave_completed", [1, 10])
	assert_eq(waves.state, WaveManager.State.PREP)
	# 100 inicial + 2 kills × 5 + bônus 10
	assert_eq(economy.gold, 120)


func test_early_bonus_only_from_second_wave() -> void:
	assert_eq(waves.early_bonus(), 0, "Sem bônus antes da primeira onda")
	waves.call_next_wave()
	waves._physics_process(1.0)
	_kill_all()
	# PREP da onda 2: 30s de prep; após 10s passados, bônus = 20
	waves._physics_process(0.0)  # PREP não tickado ainda
	for i in 10:
		waves._physics_process(1.0)
	assert_eq(waves.early_bonus(), 20)
	var gold_before := economy.gold
	waves.call_next_wave()
	assert_eq(economy.gold, gold_before + 20, "Bônus de antecipação pago")


func test_victory_after_last_wave() -> void:
	watch_signals(GameEvents)
	waves.call_next_wave()
	waves._physics_process(1.0)
	_kill_all()
	waves.call_next_wave()
	waves._physics_process(0.0)
	_kill_all()
	assert_signal_emitted(GameEvents, "all_waves_completed")
	assert_signal_emitted_with_parameters(GameEvents, "game_over", [true])
	assert_eq(waves.state, WaveManager.State.DONE)
	assert_false(waves.can_call_wave())
