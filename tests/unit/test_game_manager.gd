extends GutTest
## RF-01: estados de la partida y su ciclo iniciar / pausar / terminar / reiniciar.


func before_each() -> void:
	GameManager.reset()


func after_each() -> void:
	GameManager.reset()


func test_initial_state_is_menu() -> void:
	assert_eq(GameManager.state, GameManager.State.MENU)


func test_start_match_requests_match_and_enters_countdown() -> void:
	watch_signals(GameEvents)
	GameManager.start_match("city")
	assert_eq(GameManager.current_map_id, "city")
	assert_eq(GameManager.state, GameManager.State.COUNTDOWN)
	assert_signal_emitted_with_parameters(GameEvents, "match_requested", ["city"])


func test_invalid_map_keeps_current_map() -> void:
	GameManager.current_map_id = "park"
	GameManager.start_match("no_existe")
	assert_eq(GameManager.current_map_id, "park")


func test_pause_and_resume() -> void:
	GameManager.set_state(GameManager.State.PLAYING)
	GameManager.toggle_pause()
	assert_eq(GameManager.state, GameManager.State.PAUSED)
	assert_true(get_tree().paused)
	GameManager.toggle_pause()
	assert_eq(GameManager.state, GameManager.State.PLAYING)
	assert_false(get_tree().paused)


func test_cannot_pause_from_menu() -> void:
	GameManager.toggle_pause()
	assert_eq(GameManager.state, GameManager.State.MENU)


func test_end_match_stores_result_and_emits() -> void:
	watch_signals(GameEvents)
	GameManager.end_match(true)
	assert_eq(GameManager.state, GameManager.State.ENDED)
	assert_true(GameManager.player_won)
	assert_signal_emitted_with_parameters(GameEvents, "match_ended", [true])


func test_restart_resets_round_counter() -> void:
	GameManager.start_match("park")
	GameManager.round_number = 4
	GameManager.restart_match()
	assert_eq(GameManager.round_number, 0)
	assert_eq(GameManager.state, GameManager.State.COUNTDOWN)
