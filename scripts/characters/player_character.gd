class_name PlayerCharacter
extends Character
## Personaje controlado por el usuario con el teclado (RF-03).
##
## Modo 1 jugador (`player_index == 0`): acciones move_left/right/up/down (WASD y flechas)
## y `shortcut` (E y Espacio).
## Modo 2 jugadores:
##   P1 (`player_index == 1`): WASD + E      -> acciones p1_*
##   P2 (`player_index == 2`): flechas + Espacio -> acciones p2_*

const PLAYER_COLORS := {
	1: Color(0.25, 0.6, 1.0),
	2: Color(0.15, 0.85, 0.85),
}

## 0 = jugador único; 1 = P1; 2 = P2.
var player_index := 0:
	set(value):
		player_index = value
		if value > 0:
			display_name = "P%d" % value
			body_color = PLAYER_COLORS.get(value, body_color)
			name_color = body_color.lightened(0.3)


func _init() -> void:
	display_name = "Tú"
	body_color = Color(0.25, 0.6, 1.0)
	base_speed = 230.0


func get_input_direction() -> Vector2:
	var a := _actions()
	return Input.get_vector(a.left, a.right, a.up, a.down)


func wants_shortcut() -> bool:
	return Input.is_action_just_pressed(_actions().shortcut)


## Nombres de las acciones del Input Map que usa este jugador.
func _actions() -> Dictionary:
	if player_index == 0:
		return {
			"left": "move_left", "right": "move_right", "up": "move_up", "down": "move_down",
			"shortcut": "shortcut",
		}
	var prefix := "p%d_" % player_index
	return {
		"left": prefix + "left", "right": prefix + "right", "up": prefix + "up",
		"down": prefix + "down", "shortcut": prefix + "shortcut",
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		var a := _actions()
		for action in [a.left, a.right, a.up, a.down]:
			Input.action_release(action)
