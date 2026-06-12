class_name GameLevel
extends Node2D
## Orquestrador da partida: carrega o mapa, injeta dependências nos sistemas
## (grid, registry, economia, build controller, UI) e centraliza o tabuleiro.

const DEFAULT_MAP := preload("res://data/maps/map_01.tres")
const RULES := preload("res://data/game_rules.tres")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const DEBUG_ENEMY := preload("res://data/enemies/normal.tres")
const TOWER_CATALOG: Array[TowerData] = [
	preload("res://data/towers/archer.tres"),
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
@onready var _build: BuildController = $BuildController
@onready var _hud: Hud = $UI/HUD
@onready var _tower_panel: TowerPanel = $UI/TowerPanel

var _map: MapData


func _ready() -> void:
	_map = next_map if next_map != null else DEFAULT_MAP
	next_map = null
	_grid.setup(_map)
	_overlay.setup(_grid)
	_economy.setup(_map, RULES)
	_build.setup(_grid, _registry, _economy, _board, _towers, _projectiles, _overlay, TOWER_CATALOG)
	_hud.setup(_build, _economy, TOWER_CATALOG)
	_tower_panel.setup(_build, _economy)
	_board.position = ((get_viewport_rect().size - _grid.grid_pixel_size()) * 0.5).floor()
	GameEvents.game_over.connect(_on_game_over)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"start_wave"):
		# Spawner provisório do M2/M3 — substituído pelo WaveManager no M4
		_spawn_debug_enemy()


func _spawn_debug_enemy() -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	_enemies.add_child(enemy)
	enemy.setup(_grid, DEBUG_ENEMY)
	enemy.start()
	_registry.register(enemy)


func _on_game_over(won: bool) -> void:
	# Telas de vitória/derrota chegam no M5
	get_tree().paused = true
	print("GAME OVER — venceu: %s" % won)
