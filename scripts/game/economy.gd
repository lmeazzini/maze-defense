class_name Economy
extends Node
## Ouro e vidas da partida. Lógica pura — testável headless.
## Conecta-se ao bus: mortes pagam ouro, vazamentos tiram vidas,
## fim de onda paga bônus. game_over(false) emitido uma única vez a 0 vidas.

var gold: int = 0:
	set(value):
		gold = maxi(value, 0)
		GameEvents.gold_changed.emit(gold)

var lives: int = 0:
	set(value):
		lives = maxi(value, 0)
		GameEvents.lives_changed.emit(lives)

var _rules: GameRules
var _game_over_emitted: bool = false


func setup(map: MapData, rules: GameRules) -> void:
	_rules = rules
	gold = map.starting_gold
	lives = map.starting_lives
	GameEvents.enemy_died.connect(_on_enemy_died)
	GameEvents.enemy_leaked.connect(_on_enemy_leaked)
	GameEvents.wave_completed.connect(_on_wave_completed)


func can_afford(cost: int) -> bool:
	return gold >= cost


func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	gold -= cost
	return true


func add_gold(amount: int) -> void:
	gold += amount


func sell_refund(invested: int) -> int:
	return int(floor(invested * _rules.sell_refund_ratio))


func _on_enemy_died(_enemy: Node2D, reward: int) -> void:
	add_gold(reward)


func _on_enemy_leaked(_enemy: Node2D, lives_cost: int) -> void:
	lives -= lives_cost
	if lives == 0 and not _game_over_emitted:
		_game_over_emitted = true
		GameEvents.game_over.emit(false)


func _on_wave_completed(_index: int, bonus: int) -> void:
	add_gold(bonus)
