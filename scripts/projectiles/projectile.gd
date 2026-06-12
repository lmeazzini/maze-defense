class_name Projectile
extends Node2D
## Projétil viajante (flecha/bala de canhão). Persegue o alvo enquanto vivo;
## se o alvo morre no caminho, segue até a última posição e expira.
## Hit por distância-do-frame: imune a tunneling a 3x de velocidade.

var _target: Enemy
var _last_target_pos: Vector2
var _damage: float
var _type: TowerData.DamageType
var _splash_radius: float = 0.0
var _registry: EnemyRegistry
var _speed: float = 520.0
var _color := Color(0.9, 0.9, 0.6)


func launch(
	target: Enemy,
	damage: float,
	type: TowerData.DamageType,
	splash_radius: float,
	registry: EnemyRegistry,
) -> void:
	_target = target
	_last_target_pos = target.position
	_damage = damage
	_type = type
	_splash_radius = splash_radius
	_registry = registry


func _physics_process(delta: float) -> void:
	if is_instance_valid(_target) and _target.is_alive():
		_last_target_pos = _target.position
	var step := _speed * delta
	var dist := position.distance_to(_last_target_pos)
	if dist <= step:
		position = _last_target_pos
		_impact()
		queue_free()
		return
	position += (_last_target_pos - position) / dist * step
	rotation = (_last_target_pos - position).angle()
	queue_redraw()


func _impact() -> void:
	if _splash_radius > 0.0:
		# Dano em área: atinge todos no raio do ponto de impacto
		var radius_sq := _splash_radius * _splash_radius
		for enemy in _registry.alive.duplicate():
			if position.distance_squared_to(enemy.position) <= radius_sq:
				enemy.take_damage(_damage, _type)
	elif is_instance_valid(_target) and _target.is_alive():
		_target.take_damage(_damage, _type)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, _color)
