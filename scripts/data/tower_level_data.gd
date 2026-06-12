class_name TowerLevelData
extends Resource
## Números de um nível de torre. Nível 1: cost = custo de construção;
## níveis 2/3: cost = custo do upgrade.

@export var cost: int = 50
@export var damage: float = 10.0
@export var range_px: float = 192.0
## Tiros por segundo
@export var fire_rate: float = 1.0
@export var sprite: Texture2D

@export_group("Especiais")
## Canhão: raio do dano em área no impacto
@export var splash_radius: float = 0.0
## Gelo: 0.5 = inimigo anda a 50% da velocidade
@export var slow_factor: float = 1.0
## Gelo: duração do slow em segundos
@export var slow_duration: float = 0.0
