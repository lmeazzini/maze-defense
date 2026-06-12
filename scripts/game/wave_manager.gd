class_name WaveManager
extends Node
## FSM de ondas: PREP (jogador chama, bônus por antecipação) → SPAWNING
## (fila achatada com timers em delta acumulado — respeita time_scale de graça)
## → IN_PROGRESS (espera o último morrer/vazar) → PREP ou DONE.

enum State { PREP, SPAWNING, IN_PROGRESS, DONE }

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")

var state := State.PREP
## 1-based após a primeira chamada; 0 = antes da primeira onda
var wave_index: int = 0
var prep_time_left: float = 0.0

var _map: MapData
var _grid: GridManager
var _registry: EnemyRegistry
var _container: Node2D
var _economy: Economy
var _rules: GameRules

var _queue: Array[Dictionary] = []  # {delay, enemy, hp_mult} — delay relativo ao spawn anterior
var _spawn_clock: float = 0.0
var _alive: int = 0


func setup(
	map: MapData,
	grid: GridManager,
	registry: EnemyRegistry,
	container: Node2D,
	economy: Economy,
	rules: GameRules,
) -> void:
	_map = map
	_grid = grid
	_registry = registry
	_container = container
	_economy = economy
	_rules = rules
	if not map.waves.is_empty():
		prep_time_left = map.waves[0].prep_time
	GameEvents.enemy_died.connect(_on_enemy_removed)
	GameEvents.enemy_leaked.connect(_on_enemy_removed)


func waves_total() -> int:
	return _map.waves.size()


func can_call_wave() -> bool:
	return state == State.PREP and wave_index < waves_total()


## Bônus por chamar antecipadamente — só a partir da 2ª onda
## (clicar rápido na 1ª não é antecipação de nada).
func early_bonus() -> int:
	if state != State.PREP or wave_index == 0:
		return 0
	return int(floor(maxf(prep_time_left, 0.0) * _rules.early_call_gold_per_second))


func call_next_wave() -> void:
	if not can_call_wave():
		return
	var bonus := early_bonus()
	if bonus > 0:
		_economy.add_gold(bonus)
	wave_index += 1
	_build_queue(_map.waves[wave_index - 1])
	state = State.SPAWNING
	_spawn_clock = 0.0
	GameEvents.wave_started.emit(wave_index)


func _physics_process(delta: float) -> void:
	match state:
		State.PREP:
			prep_time_left = maxf(prep_time_left - delta, 0.0)
		State.SPAWNING:
			_spawn_clock += delta
			while not _queue.is_empty() and _spawn_clock >= float(_queue[0]["delay"]):
				_spawn_clock -= float(_queue[0]["delay"])
				var item: Dictionary = _queue.pop_front()
				_spawn(item["enemy"], item["hp_mult"])
			if _queue.is_empty():
				state = State.IN_PROGRESS
				_check_wave_end()


func _build_queue(wave: WaveData) -> void:
	_queue.clear()
	for group in wave.groups:
		for i in group.count:
			_queue.append({
				"delay": group.start_delay if i == 0 else group.spawn_interval,
				"enemy": group.enemy,
				"hp_mult": group.hp_multiplier,
			})


func _spawn(data: EnemyData, hp_mult: float) -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	_container.add_child(enemy)
	enemy.setup(_grid, data, hp_mult)
	enemy.start()
	_registry.register(enemy)
	_alive += 1


func _on_enemy_removed(_enemy: Node2D, _amount: int) -> void:
	_alive = maxi(_alive - 1, 0)
	_check_wave_end()


func _check_wave_end() -> void:
	if state != State.IN_PROGRESS or _alive > 0:
		return
	var wave := _map.waves[wave_index - 1]
	GameEvents.wave_completed.emit(wave_index, wave.end_bonus_gold)
	if wave_index >= waves_total():
		state = State.DONE
		GameEvents.all_waves_completed.emit()
		GameEvents.game_over.emit(true)
	else:
		state = State.PREP
		prep_time_left = _map.waves[wave_index].prep_time
