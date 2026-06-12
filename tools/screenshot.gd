extends SceneTree
## Ferramenta de verificação visual: abre o GameLevel, monta torres,
## chama uma onda e salva uma screenshot em pleno combate.
## Uso: godot --path . -s tools/screenshot.gd
##
## Nota: sem tipagem das classes do jogo aqui — com -s este script compila
## ANTES dos autoloads registrarem, então referências estáticas a classes
## que usam GameEvents/AudioManager falham. Tudo resolvido em runtime.

var _frames := 0


func _init() -> void:
	process_frame.connect(_on_frame)
	change_scene_to_file.call_deferred("res://scenes/game_level.tscn")


func _on_frame() -> void:
	_frames += 1
	if _frames == 5:
		_setup_combat()
	elif _frames == 240:
		var image := root.get_texture().get_image()
		image.save_png("res://docs/screenshot.png")
		print("screenshot salva")
		quit()


func _setup_combat() -> void:
	var level := current_scene
	var economy: Node = level.get_node("Economy")
	var build: Node = level.get_node("BuildController")
	var waves: Node = level.get_node("WaveManager")
	economy.add_gold(2000)
	var catalog: Array = [
		load("res://data/towers/archer.tres"),
		load("res://data/towers/cannon.tres"),
		load("res://data/towers/ice.tres"),
		load("res://data/towers/sniper.tres"),
	]
	var spots: Array = [
		Vector2i(2, 3), Vector2i(4, 5), Vector2i(6, 3), Vector2i(8, 3),
		Vector2i(3, 5), Vector2i(7, 5), Vector2i(5, 3), Vector2i(9, 5),
	]
	for i in spots.size():
		build.enter_build_mode(catalog[i % catalog.size()])
		build._try_place(spots[i])
	build.exit_build_mode()
	waves.call_next_wave()
	Engine.time_scale = 2.0
