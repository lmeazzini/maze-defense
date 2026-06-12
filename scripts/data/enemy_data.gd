class_name EnemyData
extends Resource
## Definição de um tipo de inimigo. armor reduz apenas dano PHYSICAL.

@export var id: StringName
@export var name_key: StringName
@export var max_hp: float = 50.0
## Pixels por segundo
@export var speed: float = 96.0
@export_range(0.0, 0.9) var armor: float = 0.0
@export var gold_reward: int = 5
@export var lives_cost: int = 1
@export var is_boss: bool = false
@export var sprite: Texture2D
@export var placeholder_color: Color = Color.WHITE
## Raio do placeholder/colisão visual em px
@export var radius: float = 14.0
