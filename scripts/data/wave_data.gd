class_name WaveData
extends Resource
## Uma onda: sequência de grupos de spawn + bônus de conclusão.

@export var groups: Array[SpawnGroupData] = []
@export var end_bonus_gold: int = 20
## Janela de preparação; chamar a onda antes dá bônus proporcional ao tempo restante
@export var prep_time: float = 30.0
