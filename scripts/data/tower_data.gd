class_name TowerData
extends Resource
## Definição de uma torre. Os números de balanceamento ficam em levels (3 níveis).

enum DamageType { PHYSICAL, EXPLOSIVE, MAGIC }
enum Targeting { FIRST_IN_PATH, STRONGEST }

@export var id: StringName
@export var name_key: StringName
@export var damage_type: DamageType = DamageType.PHYSICAL
@export var targeting: Targeting = Targeting.FIRST_IN_PATH
## null = hit instantâneo (Sniper, Gelo)
@export var projectile_scene: PackedScene
@export var levels: Array[TowerLevelData] = []
@export var shoot_sfx: AudioStream
@export var placeholder_color: Color = Color.WHITE
