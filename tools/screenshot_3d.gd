extends SceneTree
## Verificação visual da slice 3D: abre o GameLevel3D, coloca alguns blocos
## (formando um desvio no caminho), gera inimigos andando e salva uma screenshot.
## Uso: godot --path . -s tools/screenshot_3d.gd
##
## Sem tipagem das classes do jogo (com -s, compila antes dos autoloads).

var _frames := 0
var _level: Node


func _init() -> void:
	process_frame.connect(_on_frame)
	change_scene_to_file.call_deferred("res://scenes/game_level_3d.tscn")


func _on_frame() -> void:
	_frames += 1
	if _frames == 5:
		_setup()
	elif _frames == 120:
		var image := root.get_texture().get_image()
		image.save_png("res://docs/screenshot_3d.png")
		print("screenshot 3d salva")
		quit()


func _setup() -> void:
	_level = current_scene
	var grid: Node = _level.get_node("GridManager")
	# Bloqueia parte do corredor central (linha 4) para forçar um desvio em "S"
	for c in [Vector2i(3, 4), Vector2i(3, 5), Vector2i(7, 4), Vector2i(7, 3)]:
		grid.commit_tower(c)
	# Gera 3 inimigos em frames diferentes via spawn manual
	for i in 3:
		_level._spawn_enemy()
	Engine.time_scale = 1.0
