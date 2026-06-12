extends Control
## Seleção de mapa: cards com lock/estrelas/melhor onda vindos do SaveManager.

const GAME_SCENE := "res://scenes/game_level.tscn"


func _ready() -> void:
	%Title.text = Strings.get_text(&"UI_MAP_SELECT")
	%BackButton.text = Strings.get_text(&"UI_BACK")
	%BackButton.pressed.connect(
		func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	for map in MapCatalog.all():
		%Cards.add_child(_make_card(map))


func _make_card(map: MapData) -> PanelContainer:
	var unlocked := SaveManager.is_unlocked(map.id)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 200)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 16)
	margin.add_theme_constant_override(&"margin_top", 16)
	margin.add_theme_constant_override(&"margin_right", 16)
	margin.add_theme_constant_override(&"margin_bottom", 16)
	card.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 8)
	margin.add_child(vbox)

	var name_label := Label.new()
	name_label.text = Strings.get_text(map.name_key)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override(&"font_size", 22)
	vbox.add_child(name_label)

	var info := Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if unlocked:
		var stars := SaveManager.get_stars(map.id)
		var best := SaveManager.get_best_wave(map.id)
		info.text = "★".repeat(stars) + "☆".repeat(3 - stars) + "\n" \
			+ Strings.get_text(&"UI_BEST_WAVE") % best + "\n" \
			+ "%d×%d — %d %s" % [map.grid_size.x, map.grid_size.y, map.waves.size(), "ondas"]
	else:
		info.text = "🔒 " + Strings.get_text(&"UI_LOCKED")
	vbox.add_child(info)

	var play := Button.new()
	play.text = Strings.get_text(&"UI_PLAY")
	play.focus_mode = Control.FOCUS_NONE
	play.disabled = not unlocked
	play.pressed.connect(_on_play.bind(map))
	vbox.add_child(play)
	return card


func _on_play(map: MapData) -> void:
	GameLevel.next_map = map
	get_tree().change_scene_to_file(GAME_SCENE)
