extends GutTest
## Modo 2 jugadores: controles separados, cámara compartida, fin de partida y mensajes.

var match_node: MatchController


func before_each() -> void:
	GameManager.reset()
	GameManager.bot_count = 1
	GameManager.two_players = true
	GameManager.set_state(GameManager.State.COUNTDOWN)
	match_node = MatchController.new()
	match_node.map_id = "tiled"
	add_child_autofree(match_node)
	await get_tree().process_frame


func after_each() -> void:
	Input.action_release("p1_right")
	Input.action_release("p2_right")
	GameManager.reset()
	GameManager.bot_count = 3


func _start_round() -> void:
	match_node.debug_skip_countdown()
	await get_tree().process_frame
	await get_tree().process_frame


func _explode(character: Character) -> void:
	match_node.bomb.transfer_to(character)
	match_node.bomb.tick(999.0)


func test_spawns_p1_and_p2_plus_bots() -> void:
	assert_eq(match_node.players.size(), 2)
	assert_eq(match_node.players[0].display_name, "P1")
	assert_eq(match_node.players[1].display_name, "P2")
	assert_eq(match_node.characters.size(), 3)
	assert_ne(match_node.players[0].body_color, match_node.players[1].body_color)
	assert_true(match_node.camera is DualCamera, "El modo 2 jugadores usa la cámara compartida.")


func test_single_player_mode_is_unchanged() -> void:
	match_node.queue_free()
	await get_tree().process_frame
	GameManager.two_players = false
	var single := MatchController.new()
	single.map_id = "tiled"
	add_child_autofree(single)
	await get_tree().process_frame
	assert_eq(single.players.size(), 1)
	assert_eq(single.player.display_name, "Tú")
	assert_false(single.camera is DualCamera)


func test_each_player_reads_only_its_own_keys() -> void:
	var p1 := match_node.players[0]
	var p2 := match_node.players[1]
	Input.action_press("p1_right")
	assert_eq(p1.get_input_direction(), Vector2.RIGHT)
	assert_eq(p2.get_input_direction(), Vector2.ZERO)
	Input.action_release("p1_right")
	Input.action_press("p2_right")
	assert_eq(p1.get_input_direction(), Vector2.ZERO)
	assert_eq(p2.get_input_direction(), Vector2.RIGHT)


func test_shortcut_actions_are_per_player() -> void:
	assert_eq(match_node.players[0]._actions().shortcut, "p1_shortcut")
	assert_eq(match_node.players[1]._actions().shortcut, "p2_shortcut")


func test_camera_zoom_depends_on_player_distance() -> void:
	var cam: DualCamera = match_node.camera
	var view := Vector2(1280.0, 720.0)
	var near := cam.zoom_for_rect(Rect2(Vector2(500, 500), Vector2(50, 50)), view)
	var far := cam.zoom_for_rect(Rect2(Vector2(100, 100), Vector2(1400, 900)), view)
	assert_almost_eq(near, cam.max_zoom, 0.001, "Juntos: zoom normal.")
	assert_lt(far, near, "Separados: la cámara se aleja.")
	assert_gt(far, 0.0)


func test_camera_centers_on_midpoint_of_both_players() -> void:
	var cam: DualCamera = match_node.camera
	match_node.players[0].global_position = Vector2(600, 600)
	match_node.players[1].global_position = Vector2(1000, 800)
	cam._process(0.016)
	assert_eq(cam.global_position, Vector2(800, 700))


func test_camera_has_no_map_limits() -> void:
	var cam: DualCamera = match_node.camera
	var bounds := match_node.map.get_bounds()
	assert_lt(cam.limit_left, int(bounds.position.x), "Sin límite izquierdo.")
	assert_lt(cam.limit_top, int(bounds.position.y), "Sin límite superior.")
	assert_gt(cam.limit_right, int(bounds.end.x), "Sin límite derecho.")
	assert_gt(cam.limit_bottom, int(bounds.end.y), "Sin límite inferior.")


func test_players_in_opposite_corners_both_fit_on_screen() -> void:
	var bounds := match_node.map.get_bounds()
	var near := Vector2.ONE * Character.BODY_RADIUS
	# El jugador no puede pasar de las paredes del borde: su centro queda a >= BODY_RADIUS.
	_assert_both_visible(bounds.position + near, bounds.end - near)
	_assert_both_visible(
		Vector2(bounds.position.x + near.x, bounds.end.y - near.y),
		Vector2(bounds.end.x - near.x, bounds.position.y + near.y)
	)


func _assert_both_visible(a: Vector2, b: Vector2) -> void:
	var cam: DualCamera = match_node.camera
	var view := Vector2(1280.0, 720.0)
	var rect := Rect2(a, Vector2.ZERO).expand(b)
	var wanted := cam.zoom_for_rect(rect, view)
	# Pantalla menos el margen de la cámara: cada jugador debe quedar dentro de esa zona.
	var safe_area := Rect2(Vector2.ZERO, view).grow(-(cam.margin * wanted) + 0.5)
	for point in [a, b]:
		var on_screen: Vector2 = (point - rect.get_center()) * wanted + view * 0.5
		assert_true(
			safe_area.has_point(on_screen),
			"%s queda fuera de la pantalla (zoom %.3f)" % [point, wanted]
		)


func test_map_covers_outside_of_bounds_with_black() -> void:
	var mask = match_node.map.get_node_or_null("OutsideMask")
	assert_not_null(mask, "El mapa cubre de negro lo que queda fuera de sus límites.")
	if mask != null:
		assert_eq(mask.bounds, match_node.map.get_bounds())


func test_dead_player_is_dropped_from_camera_on_next_round() -> void:
	await _start_round()
	var p1 := match_node.players[0]
	var p2 := match_node.players[1]
	_explode(p1)
	assert_eq(GameManager.state, GameManager.State.ROUND_END, "Con un jugador vivo la partida sigue.")
	var cam: DualCamera = match_node.camera
	assert_eq(cam.get_targets().size(), 2, "Durante el fin de ronda aún se ve la explosión.")
	match_node._begin_countdown()
	assert_eq(cam.get_targets().size(), 1)
	assert_eq(cam.get_targets()[0], p2)


func test_both_players_dead_ends_match_as_defeat() -> void:
	await _start_round()
	_explode(match_node.players[0])
	match_node._begin_countdown()
	await _start_round()
	_explode(match_node.players[1])
	assert_eq(GameManager.state, GameManager.State.ENDED)
	assert_false(GameManager.player_won)
	assert_eq(GameManager.winner_label, "")


func test_last_player_standing_wins_with_their_label() -> void:
	await _start_round()
	var bot := match_node.characters[2]
	_explode(bot)
	assert_eq(GameManager.state, GameManager.State.ROUND_END, "Sin bots, pero siguen los dos jugadores.")
	match_node._begin_countdown()
	await _start_round()
	_explode(match_node.players[0])
	assert_eq(GameManager.state, GameManager.State.ENDED)
	assert_true(GameManager.player_won)
	assert_eq(GameManager.winner_label, "P2")


func test_only_bomb_holder_gets_lucky_block_effects() -> void:
	await _start_round()
	var p1 := match_node.players[0]
	var p2 := match_node.players[1]
	match_node.bomb.transfer_to(p1)
	var speed: Dictionary = {}
	for reward in RewardTable.REWARDS:
		if reward.id == "speed_boost":
			speed = reward
	match_node.effects.apply_reward(p1, speed, [p2])
	assert_gt(p1.get_speed_multiplier(), 1.0)
	assert_almost_eq(p2.get_speed_multiplier(), 1.0, 0.001)


func test_result_texts_per_winner() -> void:
	assert_eq(Hud.build_result_texts(true, true, "P1", 3)[0], "¡GANÓ P1!")
	assert_eq(Hud.build_result_texts(true, true, "P2", 3)[0], "¡GANÓ P2!")
	assert_eq(Hud.build_result_texts(false, true, "", 3)[0], "¡DERROTA!")
	assert_eq(Hud.build_result_texts(true, false, "", 3)[0], "¡VICTORIA!")
	assert_eq(Hud.build_result_texts(false, false, "", 3)[0], "¡DERROTA!")


func test_rules_screen_two_player_text_lists_both_control_schemes() -> void:
	var text := RulesScreen.build_middle_text(true)
	assert_string_contains(text, "P1")
	assert_string_contains(text, "W A S D")
	assert_string_contains(text, "P2")
	assert_string_contains(text, "flechas")
	assert_string_contains(text, "Espacio")
