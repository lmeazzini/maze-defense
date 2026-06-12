class_name Tower
extends Node2D
## Torre parametrizada por TowerData (1 cena para os 4 tipos).
## Mira por checagem de distância² no registry a cada tiro — sem Area2D.

var data: TowerData
var level: int = 1
var cell: Vector2i
## Soma de tudo que foi pago (construção + upgrades) — base do refund de 70%
var invested: int = 0

var _registry: EnemyRegistry
var _projectiles: Node2D
var _cooldown: float = 0.0
var _aim_angle: float = 0.0


func setup(tower_data: TowerData, registry: EnemyRegistry, projectiles: Node2D, grid_cell: Vector2i) -> void:
	data = tower_data
	_registry = registry
	_projectiles = projectiles
	cell = grid_cell
	invested = data.levels[0].cost


func stats() -> TowerLevelData:
	return data.levels[level - 1]


func can_upgrade() -> bool:
	return level < data.levels.size()


func upgrade_cost() -> int:
	assert(can_upgrade())
	return data.levels[level].cost


func upgrade() -> void:
	assert(can_upgrade())
	level += 1
	invested += stats().cost
	queue_redraw()


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var target := _acquire_target()
	if target == null:
		return
	_aim_angle = (target.position - position).angle()
	_fire(target)
	_cooldown = 1.0 / stats().fire_rate
	queue_redraw()


## Reaquisição a cada tiro: barato e mantém "primeiro da fila" sempre correto.
func _acquire_target() -> Enemy:
	var best: Enemy = null
	var range_sq := stats().range_px * stats().range_px
	for enemy in _registry.alive:
		if position.distance_squared_to(enemy.position) > range_sq:
			continue
		if best == null or _is_better(enemy, best):
			best = enemy
	return best


func _is_better(a: Enemy, b: Enemy) -> bool:
	match data.targeting:
		TowerData.Targeting.FIRST_IN_PATH:
			return a.remaining_distance < b.remaining_distance
		TowerData.Targeting.STRONGEST:
			return a.current_hp > b.current_hp
	return false


func _fire(target: Enemy) -> void:
	if data.shoot_sfx != null:
		AudioManager.play_sfx(data.shoot_sfx)
	if data.projectile_scene != null:
		var projectile: Projectile = data.projectile_scene.instantiate()
		_projectiles.add_child(projectile)
		projectile.position = position
		projectile.launch(target, stats().damage, data.damage_type, stats().splash_radius, _registry)
	else:
		# Hit instantâneo (Sniper, Gelo) — sem tunneling por definição
		target.take_damage(stats().damage, data.damage_type)
		if stats().slow_factor < 1.0:
			target.apply_slow(stats().slow_factor, stats().slow_duration)
		_spawn_hit_flash(target.position)


func _spawn_hit_flash(at: Vector2) -> void:
	var flash := preload("res://scenes/projectiles/hit_flash.tscn").instantiate()
	_projectiles.add_child(flash)
	(flash as HitFlash).show_line(position, at, data.placeholder_color)


func _draw() -> void:
	if data == null:
		return
	var half := GridManager.CELL_SIZE * 0.5 - 6.0
	if data.base_sprite != null:
		var size := Vector2.ONE * GridManager.CELL_SIZE
		draw_texture_rect(data.base_sprite, Rect2(size * -0.5, size), false)
		var turret := stats().sprite
		if turret != null:
			# Sprites do pack apontam para cima (-Y) → compensa com +PI/2
			draw_set_transform(Vector2.ZERO, _aim_angle + PI / 2.0, Vector2.ONE)
			var tint := data.placeholder_color.lerp(Color.WHITE, 0.55)
			draw_texture_rect(turret, Rect2(size * -0.5, size), false, tint)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_rect(Rect2(Vector2.ONE * -half, Vector2.ONE * half * 2.0), data.placeholder_color)
		var barrel := Vector2.RIGHT.rotated(_aim_angle) * (half + 8.0)
		draw_line(Vector2.ZERO, barrel, Color(0.1, 0.1, 0.1), 6.0)
	# Pips de nível
	for i in level:
		draw_circle(Vector2(-half + 7.0 + i * 10.0, half - 7.0), 3.5, Color.WHITE)
