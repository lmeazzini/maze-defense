class_name SpawnGroupData
extends Resource
## Um grupo dentro de uma onda: N inimigos do mesmo tipo, espaçados.

@export var enemy: EnemyData
@export var count: int = 5
## Segundos entre spawns dentro do grupo
@export var spawn_interval: float = 1.0
## Espera após o grupo anterior terminar
@export var start_delay: float = 0.0
## Dial de escala por onda — balanceamento vive nos dados, não no código
@export var hp_multiplier: float = 1.0
