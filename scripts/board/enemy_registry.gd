class_name EnemyRegistry
extends Node
## Lista canônica de inimigos vivos. Evita get_nodes_in_group em hot paths
## e fornece occupied_cells() para a validação anti-bloqueio.

var alive: Array[Enemy] = []


func register(enemy: Enemy) -> void:
	alive.append(enemy)
	enemy.died.connect(_on_died)
	enemy.leaked.connect(_on_leaked)
	GameEvents.enemy_spawned.emit(enemy)


## Célula atual + próxima célula de cada inimigo vivo, deduplicadas.
## A "próxima" garante que a célula-alvo de um inimigo nunca vira sólida.
func occupied_cells() -> Array[Vector2i]:
	var seen: Dictionary = {}
	for enemy in alive:
		seen[enemy.current_cell()] = true
		seen[enemy.next_cell()] = true
	var cells: Array[Vector2i] = []
	for cell: Vector2i in seen:
		cells.append(cell)
	return cells


func _on_died(enemy: Enemy) -> void:
	alive.erase(enemy)
	GameEvents.enemy_died.emit(enemy, enemy.data.gold_reward)


func _on_leaked(enemy: Enemy) -> void:
	alive.erase(enemy)
	GameEvents.enemy_leaked.emit(enemy, enemy.data.lives_cost)
