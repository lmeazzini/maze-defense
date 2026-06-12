class_name GameLevel
extends Node2D
## Orquestrador da partida: carrega o mapa, injeta dependências nos sistemas
## (grid, registry, economia, build controller, UI) e centraliza o tabuleiro.

const DEFAULT_MAP := preload("res://data/maps/map_01.tres")
const RULES := preload("res://data/game_rules.tres")
const TOWER_CATALOG: Array[TowerData] = [
	preload("res://data/towers/archer.tres"),
	preload("res://data/towers/cannon.tres"),
	preload("res://data/towers/ice.tres"),
	preload("res://data/towers/sniper.tres"),
]

## Definido pela seleção de mapa antes da troca de cena (M5)
static var next_map: MapData

@onready var _board: Node2D = $Board
@onready var _grid: GridManager = $Board/GridManager
@onready var _overlay: GridOverlay = $Board/GridOverlay
@onready var _towers: Node2D = $Board/Towers
@onready var _enemies: Node2D = $Board/Enemies
@onready var _projectiles: Node2D = $Board/Projectiles
@onready var _registry: EnemyRegistry = $EnemyRegistry
@onready var _economy: Economy = $Economy
@onready var _waves: WaveManager = $WaveManager
@onready var _build: BuildController = $BuildController
@onready var _hud: Hud = $UI/HUD
@onready var _tower_panel: TowerPanel = $UI/TowerPanel
@onready var _pause_menu: PauseMenu = $UI/PauseMenu
@onready var _result: ResultScreen = $UI/ResultScreen

var _map: MapData


func _ready() -> void:
	_map = next_map if next_map != null else DEFAULT_MAP
	next_map = null
	_grid.setup(_map)
	_overlay.setup(_grid)
	_economy.setup(_map, RULES)
	_waves.setup(_map, _grid, _registry, _enemies, _economy, RULES)
	_build.setup(_grid, _registry, _economy, _board, _towers, _projectiles, _overlay, TOWER_CATALOG)
	_hud.setup(_build, _economy, _waves, TOWER_CATALOG)
	_tower_panel.setup(_build, _economy)
	_board.position = ((get_viewport_rect().size - _grid.grid_pixel_size()) * 0.5).floor()
	GameEvents.game_over.connect(_on_game_over)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"start_wave"):
		_waves.call_next_wave()
	elif event.is_action_pressed(&"cycle_speed"):
		_hud.cycle_speed()
	elif event.is_action_pressed(&"pause"):
		if _result.visible:
			return
		if _build.is_building():
			_build.exit_build_mode()
		else:
			_pause_menu.toggle()


func _on_game_over(won: bool) -> void:
	get_tree().paused = true
	var stars := 0
	if won:
		if _economy.lives >= _map.starting_lives:
			stars = 3
		elif _economy.lives >= 10:
			stars = 2
		else:
			stars = 1
		SaveManager.record_result(_map.id, _waves.wave_index, stars)
		var next := MapCatalog.next_after(_map.id)
		if next != null:
			SaveManager.unlock_map(next.id)
	else:
		# Derrota na onda N = venceu N-1 ondas
		SaveManager.record_result(_map.id, maxi(_waves.wave_index - 1, 0), 0)
	_result.show_result(won, _map, _waves.wave_index if won else _waves.wave_index - 1,
		_waves.waves_total(), stars)
