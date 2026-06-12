class_name HitFlash
extends Node2D
## Feedback visual de hit instantâneo (Sniper/Gelo): linha breve que some.

const LIFETIME := 0.12

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _color := Color.WHITE
var _age := 0.0


func show_line(from: Vector2, to: Vector2, color: Color) -> void:
	_from = from
	_to = to
	_color = color


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var alpha := 1.0 - _age / LIFETIME
	draw_line(_from, _to, Color(_color, alpha), 3.0)
