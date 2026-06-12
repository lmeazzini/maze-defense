class_name PauseMenu
extends Control
## Pausa a árvore inteira (gameplay PAUSABLE congela; este menu é ALWAYS,
## música continua via AudioManager ALWAYS).

@onready var _settings: SettingsPanel = $SettingsPanel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	%Title.text = Strings.get_text(&"UI_PAUSED")
	%ContinueButton.text = Strings.get_text(&"UI_CONTINUE")
	%SettingsButton.text = Strings.get_text(&"UI_SETTINGS")
	%MenuButton.text = Strings.get_text(&"UI_MAIN_MENU")
	%ContinueButton.pressed.connect(close)
	%SettingsButton.pressed.connect(_settings.open)
	%MenuButton.pressed.connect(_to_main_menu)
	hide()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	show()
	get_tree().paused = true


func close() -> void:
	hide()
	get_tree().paused = false


func _to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
