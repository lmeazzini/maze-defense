class_name Hud
extends Control
## HUD da partida: ouro/vidas/onda no topo, barra de construção embaixo,
## botões de próxima onda (com bônus de antecipação) e velocidade,
## toast de rejeição. Só escuta o bus e chama métodos públicos injetados.

const TOAST_TIME := 1.6
const SPEEDS: Array[int] = [1, 2, 3]

var _build: BuildController
var _economy: Economy
var _waves: WaveManager
var _buttons: Array[Button] = []
var _catalog: Array[TowerData] = []
var _speed_index: int = 0

@onready var _gold_label: Label = %GoldLabel
@onready var _lives_label: Label = %LivesLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _build_bar: HBoxContainer = %BuildBar
@onready var _toast: Label = %Toast
@onready var _next_wave_button: Button = %NextWaveButton
@onready var _speed_button: Button = %SpeedButton


func setup(
	build: BuildController,
	economy: Economy,
	waves: WaveManager,
	catalog: Array[TowerData],
) -> void:
	_build = build
	_economy = economy
	_waves = waves
	_catalog = catalog
	for i in catalog.size():
		var data := catalog[i]
		var button := Button.new()
		button.text = "%s\n%d" % [Strings.get_text(data.name_key), data.levels[0].cost]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_build.enter_build_mode.bind(data))
		_build_bar.add_child(button)
		_buttons.append(button)
	_next_wave_button.pressed.connect(_waves.call_next_wave)
	_speed_button.pressed.connect(cycle_speed)
	GameEvents.gold_changed.connect(_on_gold_changed)
	GameEvents.lives_changed.connect(_on_lives_changed)
	GameEvents.placement_rejected.connect(_on_placement_rejected)
	GameEvents.wave_started.connect(_on_wave_changed)
	GameEvents.wave_completed.connect(_on_wave_changed.unbind(1))
	_toast.hide()
	_on_gold_changed(economy.gold)
	_on_lives_changed(economy.lives)
	_on_wave_changed(0)
	_speed_button.text = Strings.get_text(&"UI_SPEED") % SPEEDS[_speed_index]


func cycle_speed() -> void:
	_speed_index = (_speed_index + 1) % SPEEDS.size()
	Engine.time_scale = float(SPEEDS[_speed_index])
	_speed_button.text = Strings.get_text(&"UI_SPEED") % SPEEDS[_speed_index]
	GameEvents.speed_changed.emit(SPEEDS[_speed_index])


func _process(_delta: float) -> void:
	# Texto/estado do botão de onda dependem de prep_time_left, que muda todo frame
	if _waves == null:
		return
	if _waves.can_call_wave():
		_next_wave_button.disabled = false
		var bonus := _waves.early_bonus()
		_next_wave_button.text = (
			Strings.get_text(&"UI_NEXT_WAVE_BONUS") % bonus if bonus > 0
			else Strings.get_text(&"UI_NEXT_WAVE")
		)
	else:
		_next_wave_button.disabled = true
		if _waves.state == WaveManager.State.DONE:
			_next_wave_button.text = Strings.get_text(&"UI_WAVES_DONE")


func _on_wave_changed(_index: int) -> void:
	_wave_label.text = Strings.get_text(&"UI_WAVE") % [_waves.wave_index, _waves.waves_total()]


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
