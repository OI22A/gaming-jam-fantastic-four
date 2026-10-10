extends GutTest
## RF-03: el Input Map debe contener las acciones que usa el juego.


func test_required_actions_exist() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right", "pause", "restart", "shortcut"]:
		assert_true(InputMap.has_action(action), "Falta la acción '%s'." % action)


func test_each_movement_action_has_wasd_and_arrow_keys() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		assert_eq(InputMap.action_get_events(action).size(), 2, action)


func test_shortcut_has_two_keys() -> void:
	assert_eq(InputMap.action_get_events("shortcut").size(), 2)


func test_two_player_actions_exist_with_one_key_each() -> void:
	for prefix in ["p1_", "p2_"]:
		for suffix in ["up", "down", "left", "right", "shortcut"]:
			var action: String = prefix + suffix
			assert_true(InputMap.has_action(action), "Falta la acción '%s'." % action)
			assert_eq(InputMap.action_get_events(action).size(), 1, action)


func test_p1_uses_wasd_and_e_and_p2_uses_arrows_and_space() -> void:
	var expected := {
		"p1_up": KEY_W, "p1_down": KEY_S, "p1_left": KEY_A, "p1_right": KEY_D, "p1_shortcut": KEY_E,
		"p2_up": KEY_UP, "p2_down": KEY_DOWN, "p2_left": KEY_LEFT, "p2_right": KEY_RIGHT,
		"p2_shortcut": KEY_SPACE,
	}
	for action: String in expected:
		var event := InputMap.action_get_events(action)[0] as InputEventKey
		assert_eq(event.physical_keycode, expected[action], action)
