class_name MapData
extends Resource
## Definição declarativa de um mapa: grade, entrada/saída, obstáculos e ondas.

@export var id: StringName
@export var name_key: StringName
@export var grid_size: Vector2i = Vector2i(12, 9)
@export var entry_cell: Vector2i = Vector2i(0, 4)
@export var exit_cell: Vector2i = Vector2i(11, 4)
## Células não-construíveis e não-atravessáveis (rochas/água)
@export var blocked_cells: Array[Vector2i] = []
@export var waves: Array[WaveData] = []
@export var starting_gold: int = 200
@export var starting_lives: int = 20
