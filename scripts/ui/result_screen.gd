class_name ResultScreen
extends Control
## Tela única de vitória/derrota: estrelas, ondas vencidas e navegação
## (reiniciar / próximo mapa / menu). PROCESS_MODE_ALWAYS — a árvore está pausada.

var _map: MapData
var _next: MapData


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	%RestartButton.text = Strings.get_text(&"UI_RESTART")
	%NextButton.text = Strings.get_text(&"UI_NEXT_MAP")
	%MenuButton.text = Strings.get_text(&"UI_MAIN_MENU")
	%RestartButton.pressed.connect(_restart)
	%NextButton.pressed.connect(_play_next)
	%MenuButton.pressed.connect(_to_menu)
	hide()


func show_result(won: bool, map: MapData, waves_cleared: int, total_waves: int, stars: int) -> void:
	_map = map
	_next = MapCatalog.next_after(map.id) if won else null
	%Title.text = Strings.get_text(&"UI_VICTORY" if won else &"UI_DEFEAT")
	%Title.add_theme_color_override(
		&"font_color",
		Color(0.35, 0.85, 0.4) if won else Color(0.9, 0.3, 0.25)
	)
	%Stars.text = "★".repeat(stars) + "☆".repeat(3 - stars) if won else ""
	%Stars.visible = won
	%Detail.text = Strings.get_text(&"UI_WAVE") % [waves_cleared, total_waves]
	%NextButton.visible = _next != null
	show()


func _restart() -> void:
	GameLevel.next_map = _map
	_change_scene("res://scenes/game_level.tscn")


func _play_next() -> void:
	GameLevel.next_map = _next
	_change_scene("res://scenes/game_level.tscn")


func _to_menu() -> void:
	_change_scene("res://scenes/main_menu.tscn")


func _change_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
