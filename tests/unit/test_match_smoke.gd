extends GutTest
## Prueba de humo del flujo completo (RF-01, RF-04, RF-05, RF-08, RF-09):
## crea una partida real, salta la cuenta regresiva y hace explotar la bomba.

var match_node: MatchController


func before_each() -> void:
	GameManager.reset()
	GameManager.bot_count = 2
	GameManager.set_state(GameManager.State.COUNTDOWN)
	match_node = MatchController.new()
	match_node.map_id = "park"
	add_child_autofree(match_node)
	await get_tree().process_frame


func after_each() -> void:
	GameManager.reset()
	GameManager.bot_count = 3


func test_match_spawns_player_and_bots() -> void:
	assert_eq(match_node.characters.size(), 3)
	assert_not_null(match_node.player)
	assert_not_null(match_node.hud)
	assert_eq(GameManager.state, GameManager.State.COUNTDOWN)


func test_countdown_leads_to_playing_with_one_bomb_holder() -> void:
	match_node.debug_skip_countdown()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(GameManager.state, GameManager.State.PLAYING)
	var holders := 0
	for c in match_node.characters:
		if c.has_bomb:
			holders += 1
	assert_eq(holders, 1, "Exactamente un personaje con la bomba.")
	assert_eq(GameManager.round_number, 1)


func test_bots_move_while_playing() -> void:
	match_node.debug_skip_countdown()
	await get_tree().process_frame
	var bot: BotCharacter = match_node.characters[1]
	var start := bot.global_position
	for i in 30:
		await get_tree().physics_frame
	assert_gt(bot.global_position.distance_to(start), 5.0, "El bot debe desplazarse.")


func test_explosion_eliminates_holder_and_advances() -> void:
	match_node.debug_skip_countdown()
	await get_tree().process_frame
	var holder := match_node.bomb.holder
	if holder == match_node.player:
		# Garantiza el caso "bot eliminado": pasa la bomba a un bot.
		match_node.bomb.transfer_to(match_node.characters[1])
		holder = match_node.bomb.holder
	match_node.bomb.tick(999.0)
	assert_true(holder.is_eliminated)
	assert_eq(GameManager.state, GameManager.State.ROUND_END)
	assert_eq(match_node.get_alive_characters().size(), 2)


func test_player_explosion_ends_match_as_defeat() -> void:
	match_node.debug_skip_countdown()
	await get_tree().process_frame
	match_node.bomb.transfer_to(match_node.player)
	match_node.bomb.tick(999.0)
	assert_eq(GameManager.state, GameManager.State.ENDED)
	assert_false(GameManager.player_won)


func test_last_bot_eliminated_means_victory() -> void:
	match_node.debug_skip_countdown()
	await get_tree().process_frame
	# Elimina bots uno a uno hasta ganar.
	for bot in match_node.characters.slice(1):
		match_node.bomb.transfer_to(bot)
		match_node.bomb.tick(999.0)
		if GameManager.state == GameManager.State.ENDED:
			break
		match_node._begin_countdown()
		match_node.debug_skip_countdown()
		await get_tree().process_frame
	assert_eq(GameManager.state, GameManager.State.ENDED)
	assert_true(GameManager.player_won)
