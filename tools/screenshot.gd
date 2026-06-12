extends SceneTree
## Ferramenta de verificação: abre o GameLevel, espera renderizar e salva
## uma screenshot. Uso: godot --path . -s tools/screenshot.gd

var _frames := 0


func _init() -> void:
	process_frame.connect(_on_frame)
	change_scene_to_file.call_deferred("res://scenes/game_level.tscn")


func _on_frame() -> void:
	_frames += 1
	if _frames == 30:
		var image := root.get_texture().get_image()
		image.save_png("res://screenshot_check.png")
		print("screenshot salva")
		quit()
