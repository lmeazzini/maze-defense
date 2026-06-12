extends GutTest
## Teste de integração end-to-end: instancia a cena REAL da partida e joga
## o mapa 1 inteiro (15 ondas) em time_scale alto até a vitória, validando
## a fiação completa: build → ondas → combate → economia → save → unlock.
## (Prefixo zz para rodar por último — é o teste mais lento da suíte.)

const GAME_SCENE := preload("res://scenes/game_level.tscn")
const SNIPER := preload("res://data/towers/sniper.tres")
const CANNON := preload("res://data/towers/cannon.tres")

var _unpause := func(_won: bool) -> void: get_tree().paused = false


func before_each() -> void:
	# GameLevel pausa a árvore no game_over; despausa logo em seguida
	# para os awaits do GUT não congelarem.
	GameEvents.game_over.connect(_unpause)


func after_each() -> void:
	GameEvents.game_over.disconnect(_unpause)
	Engine.time_scale = 1.0
	get_tree().paused = false


func after_all() -> void:
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		DirAccess.remove_absolute(SaveManager.SAVE_PATH)
	SaveManager.load_profile()


func _start_level() -> Node2D:
	GameLevel.next_map = null  # mapa 1 padrão
	var level: Node2D = GAME_SCENE.instantiate()
	add_child_autoqfree(level)
	return level


func test_full_victory_on_map_01() -> void:
	var level := _start_level()
	await wait_physics_frames(2)
	var economy: Economy = level.get_node("Economy")
	var build: BuildController = level.get_node("BuildController")
	var waves: WaveManager = level.get_node("WaveManager")
	var grid: GridManager = level.get_node("Board/GridManager")
	var towers: Node2D = level.get_node("Board/Towers")
	watch_signals(GameEvents)

	# Kill-box: preenche as linhas vizinhas ao corredor (4) alternando
	# Sniper (físico, longo alcance) e Canhão (explosivo, ignora armadura)
	economy.add_gold(100000)
	for y in [2, 3, 5, 6]:
		for x in range(1, 11):
			var cell := Vector2i(x, y)
			if grid.validate_placement(cell, [] as Array[Vector2i]) != GridManager.PlacementError.OK:
				continue
			build.enter_build_mode(CANNON if (x + y) % 2 == 0 else SNIPER)
			build._try_place(cell)
	build.exit_build_mode()
	assert_gt(towers.get_child_count(), 20, "Kill-box construída")
	for tower: Tower in towers.get_children():
		while tower.can_upgrade():
			economy.spend(tower.upgrade_cost())
			tower.upgrade()

	Engine.time_scale = 20.0
	var safety := 0
	while waves.state != WaveManager.State.DONE and economy.lives > 0 and safety < 400:
		if waves.can_call_wave():
			waves.call_next_wave()
		await wait_physics_frames(15)
		safety += 1
	Engine.time_scale = 1.0

	assert_eq(waves.state, WaveManager.State.DONE, "15 ondas limpas (safety=%d)" % safety)
	assert_gt(economy.lives, 0, "Vidas restantes: %d" % economy.lives)
	assert_signal_emitted_with_parameters(GameEvents, "game_over", [true])
	assert_gte(SaveManager.get_stars(&"map_01"), 1, "Resultado gravado")
	assert_eq(SaveManager.get_best_wave(&"map_01"), 15)
	assert_true(SaveManager.is_unlocked(&"map_02"), "Vitória desbloqueia o mapa 2")


func test_defeat_without_towers() -> void:
	var level := _start_level()
	await wait_physics_frames(2)
	var economy: Economy = level.get_node("Economy")
	var waves: WaveManager = level.get_node("WaveManager")
	watch_signals(GameEvents)

	Engine.time_scale = 20.0
	var safety := 0
	while economy.lives > 0 and safety < 200:
		if waves.can_call_wave():
			waves.call_next_wave()
		await wait_physics_frames(15)
		safety += 1
	Engine.time_scale = 1.0

	assert_eq(economy.lives, 0, "Sem torres, as vidas acabam (safety=%d)" % safety)
	assert_signal_emitted_with_parameters(GameEvents, "game_over", [false])
	var result: ResultScreen = level.get_node("UI/ResultScreen")
	assert_true(result.visible, "Tela de derrota visível")
