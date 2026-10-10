extends GutTest
## RF-03: el Input Map debe contener las acciones que usa el juego.


func test_required_actions_exist() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right", "pause", "restart"]:
		assert_true(InputMap.has_action(action), "Falta la acción '%s'." % action)


func test_each_movement_action_has_wasd_and_arrow_keys() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		assert_eq(InputMap.action_get_events(action).size(), 2, action)
