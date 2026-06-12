class_name Hud
extends Control
## HUD da partida: ouro/vidas no topo, barra de construção embaixo,
## toast de rejeição. Só escuta o bus — zero acoplamento com gameplay.

const TOAST_TIME := 1.6

var _build: BuildController
var _economy: Economy
var _buttons: Array[Button] = []
var _catalog: Array[TowerData] = []

@onready var _gold_label: Label = %GoldLabel
@onready var _lives_label: Label = %LivesLabel
@onready var _build_bar: HBoxContainer = %BuildBar
@onready var _toast: Label = %Toast


func setup(build: BuildController, economy: Economy, catalog: Array[TowerData]) -> void:
	_build = build
	_economy = economy
	_catalog = catalog
	for i in catalog.size():
		var data := catalog[i]
		var button := Button.new()
		button.text = "%s\n%d" % [Strings.get_text(data.name_key), data.levels[0].cost]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_build.enter_build_mode.bind(data))
		_build_bar.add_child(button)
		_buttons.append(button)
	GameEvents.gold_changed.connect(_on_gold_changed)
	GameEvents.lives_changed.connect(_on_lives_changed)
	GameEvents.placement_rejected.connect(_on_placement_rejected)
	_toast.hide()
	_on_gold_changed(economy.gold)
	_on_lives_changed(economy.lives)


func _on_gold_changed(gold: int) -> void:
	_gold_label.text = "%s: %d" % [Strings.get_text(&"UI_GOLD"), gold]
	for i in _buttons.size():
		_buttons[i].disabled = gold < _catalog[i].levels[0].cost


func _on_lives_changed(lives: int) -> void:
	_lives_label.text = "%s: %d" % [Strings.get_text(&"UI_LIVES"), lives]


func _on_placement_rejected(reason: int) -> void:
	_toast.text = _reason_text(reason)
	_toast.show()
	# Timer real-time: o toast não pode durar 3x menos a 3x de velocidade
	get_tree().create_timer(TOAST_TIME, true, false, true).timeout.connect(_toast.hide)


func _reason_text(reason: int) -> String:
	match reason:
		GridManager.PlacementError.BLOCKS_PATH:
			return Strings.get_text(&"MSG_BLOCKED")
		GridManager.PlacementError.ENEMY_ON_CELL:
			return Strings.get_text(&"MSG_ENEMY_ON_CELL")
		BuildController.REASON_NO_GOLD:
			return Strings.get_text(&"MSG_NO_GOLD")
		_:
			return Strings.get_text(&"MSG_CELL_OCCUPIED")
