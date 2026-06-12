extends Node
## Bus de sinais global. Zero estado — apenas notificações entre sistemas.
## Consultas síncronas (ex: caminhos do GridManager) NÃO passam por aqui.

@warning_ignore_start("unused_signal")

# Grade / construção
signal grid_changed
signal tower_placed(tower: Node2D)
signal tower_sold(cell: Vector2i, refund: int)
signal build_mode_changed(tower_data: Resource)
signal placement_rejected(reason: int)

# Inimigos
signal enemy_spawned(enemy: Node2D)
signal enemy_died(enemy: Node2D, gold: int)
signal enemy_leaked(enemy: Node2D, lives_cost: int)

# Economia
signal gold_changed(gold: int)
signal lives_changed(lives: int)

# Ondas / partida
signal wave_started(index: int)
signal wave_completed(index: int, bonus: int)
signal all_waves_completed
signal game_over(won: bool)
signal speed_changed(multiplier: int)

@warning_ignore_restore("unused_signal")
