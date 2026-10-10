class_name PlayerCharacter
extends Character
## Personaje controlado por el usuario con el teclado (RF-03).
## Acciones definidas en el Input Map: move_left, move_right, move_up, move_down
## (WASD y flechas).


func _init() -> void:
	display_name = "Tú"
	body_color = Color(0.25, 0.6, 1.0)
	base_speed = 230.0


func get_input_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		for action in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(action)
