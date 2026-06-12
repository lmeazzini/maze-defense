extends GutTest
## Economia: gastos, refund de 70%, ouro por kill, vidas e game_over.

var economy: Economy
var rules: GameRules


func before_each() -> void:
	economy = Economy.new()
	add_child_autofree(economy)
	rules = GameRules.new()
	rules.sell_refund_ratio = 0.7
	var map := MapData.new()
	map.starting_gold = 100
	map.starting_lives = 20
	economy.setup(map, rules)


func test_initial_values_and_signals() -> void:
	assert_eq(economy.gold, 100)
	assert_eq(economy.lives, 20)


func test_spend_boundaries() -> void:
	assert_true(economy.can_afford(100))
	assert_false(economy.can_afford(101))
	assert_true(economy.spend(100))
	assert_eq(economy.gold, 0)
	assert_false(economy.spend(1), "Sem saldo, gasto recusado")
	assert_eq(economy.gold, 0)


func test_sell_refund_is_70_percent_floored() -> void:
	# Torre 50 + upgrades 40 e 60 = 150 investido → floor(105) = 105
	assert_eq(economy.sell_refund(150), 105)
	# floor(50 * 0.7) = 35
	assert_eq(economy.sell_refund(50), 35)
	# floor(45 * 0.7) = floor(31.5) = 31
	assert_eq(economy.sell_refund(45), 31)


func test_kill_pays_gold_and_wave_bonus() -> void:
	GameEvents.enemy_died.emit(null, 5)
	assert_eq(economy.gold, 105)
	GameEvents.wave_completed.emit(1, 20)
	assert_eq(economy.gold, 125)


func test_leak_costs_lives_and_boss_costs_five() -> void:
	GameEvents.enemy_leaked.emit(null, 1)
	assert_eq(economy.lives, 19)
	GameEvents.enemy_leaked.emit(null, 5)
	assert_eq(economy.lives, 14)


func test_game_over_emitted_once_at_zero() -> void:
	watch_signals(GameEvents)
	for i in 4:
		GameEvents.enemy_leaked.emit(null, 5)
	assert_eq(economy.lives, 0)
	assert_signal_emitted_with_parameters(GameEvents, "game_over", [false])
	assert_signal_emit_count(GameEvents, "game_over", 1, "Vazamentos após 0 não re-emitem")
