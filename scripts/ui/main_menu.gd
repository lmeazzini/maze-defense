extends Control
## Menu principal: Jogar → seleção de mapa; Opções; Sair.

const MENU_MUSIC := preload("res://assets/audio/music/menu.ogg")

@onready var _settings: SettingsPanel = $SettingsPanel


func _ready() -> void:
	AudioManager.play_music(MENU_MUSIC)
	%Title.text = Strings.get_text(&"GAME_TITLE")
	%PlayButton.text = Strings.get_text(&"UI_PLAY")
	%SettingsButton.text = Strings.get_text(&"UI_SETTINGS")
	%QuitButton.text = Strings.get_text(&"UI_QUIT")
	%PlayButton.pressed.connect(_on_play)
	%SettingsButton.pressed.connect(_settings.open)
	%QuitButton.pressed.connect(get_tree().quit)


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/map_select.tscn")
