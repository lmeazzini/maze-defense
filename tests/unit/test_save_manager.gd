extends GutTest
## Persistência: defaults, desbloqueio, melhor resultado (máximos),
## volumes e sobrevivência a save corrompido.


func before_each() -> void:
	_wipe_save()
	SaveManager.load_profile()


func after_all() -> void:
	_wipe_save()
	SaveManager.load_profile()


func _wipe_save() -> void:
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		DirAccess.remove_absolute(SaveManager.SAVE_PATH)


func test_defaults_only_first_map_unlocked() -> void:
	assert_true(SaveManager.is_unlocked(&"map_01"))
	assert_false(SaveManager.is_unlocked(&"map_02"))
	assert_false(SaveManager.is_unlocked(&"map_03"))
	assert_eq(SaveManager.get_stars(&"map_01"), 0)
	assert_eq(SaveManager.get_best_wave(&"map_01"), 0)


func test_unlock_and_results_persist_across_reload() -> void:
	SaveManager.unlock_map(&"map_02")
	SaveManager.record_result(&"map_01", 15, 2)
	SaveManager.set_volume(&"Music", 0.5)
	SaveManager.load_profile()  # relê do disco
	assert_true(SaveManager.is_unlocked(&"map_02"))
	assert_eq(SaveManager.get_best_wave(&"map_01"), 15)
	assert_eq(SaveManager.get_stars(&"map_01"), 2)
	assert_almost_eq(SaveManager.get_volume(&"Music"), 0.5, 0.001)


func test_record_keeps_maximums() -> void:
	SaveManager.record_result(&"map_01", 15, 3)
	SaveManager.record_result(&"map_01", 8, 1)  # resultado pior não rebaixa
	assert_eq(SaveManager.get_best_wave(&"map_01"), 15)
	assert_eq(SaveManager.get_stars(&"map_01"), 3)


func test_corrupt_save_falls_back_to_defaults() -> void:
	var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	file.store_string("{ isso não é json válido !!!")
	file.close()
	SaveManager.load_profile()
	assert_true(SaveManager.is_unlocked(&"map_01"), "Defaults após corrupção")
	assert_false(SaveManager.is_unlocked(&"map_02"))
