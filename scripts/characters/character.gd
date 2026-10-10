class_name Character
extends CharacterBody2D
## Personaje base (jugador o bot). RF-03 / RF-04 / RF-07.
##
## Capas de colisión del proyecto:
##   1 = mundo (paredes y obstáculos)   2 = personajes   3 = Lucky Blocks
##
## Los efectos temporales NO modifican `base_speed`: registran su multiplicador
## en `speed_modifiers` (y las marcas en `marks`) y EffectManager los retira al
## expirar. Así nunca se "pierde" la velocidad original.

const BODY_RADIUS := 14.0

@export var display_name := "Personaje"
@export var base_speed := 230.0
@export var body_color := Color(0.35, 0.65, 1.0)

var has_bomb := false:
	set(value):
		if value == has_bomb:
			return
		has_bomb = value
		queue_redraw()
var is_eliminated := false
## effect_id -> multiplicador de velocidad (>1 mejora, <1 penaliza).
var speed_modifiers: Dictionary = {}
## effect_id -> true. Si no está vacío, el personaje está "marcado" (visible en minimapa).
var marks: Dictionary = {}


func _ready() -> void:
	add_to_group("characters")
	z_index = 2
	collision_layer = 2
	collision_mask = 3
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = BODY_RADIUS
		shape.shape = circle
		add_child(shape)


func _physics_process(_delta: float) -> void:
	if is_eliminated or not GameManager.is_playing():
		velocity = Vector2.ZERO
		return
	velocity = get_input_direction().limit_length(1.0) * get_current_speed()
	move_and_slide()


func _process(_delta: float) -> void:
	queue_redraw()


## Dirección deseada de movimiento. La sobrescriben PlayerCharacter y BotCharacter.
func get_input_direction() -> Vector2:
	return Vector2.ZERO


func get_speed_multiplier() -> float:
	var multiplier := 1.0
	for value in speed_modifiers.values():
		multiplier *= float(value)
	return multiplier


func get_current_speed() -> float:
	return base_speed * get_speed_multiplier()


func is_marked() -> bool:
	return not marks.is_empty()


func _draw() -> void:
	if is_marked():
		draw_arc(Vector2.ZERO, BODY_RADIUS + 8.0, 0.0, TAU, 32, Color(1.0, 0.9, 0.2), 3.0)
	draw_circle(Vector2.ZERO, BODY_RADIUS, body_color)
	draw_arc(Vector2.ZERO, BODY_RADIUS, 0.0, TAU, 24, Color(0.0, 0.0, 0.0, 0.6), 2.0)
	if has_bomb:
		var bomb_pos := Vector2(0.0, -BODY_RADIUS - 14.0)
		draw_circle(bomb_pos, 9.0, Color(0.1, 0.1, 0.1))
		draw_line(
			bomb_pos + Vector2(3.0, -8.0),
			bomb_pos + Vector2(8.0, -14.0),
			Color(0.8, 0.65, 0.4),
			2.0
		)
		draw_circle(bomb_pos + Vector2(8.0, -14.0), 3.5, Color(1.0, 0.6, 0.1))
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(-50.0, BODY_RADIUS + 18.0),
		display_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		100.0,
		13,
		Color.WHITE
	)
