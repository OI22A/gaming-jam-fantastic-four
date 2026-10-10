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
## Se precarga por ruta (en vez de usar el class_name) para que el juego arranque aunque
## Godot aún no haya registrado la clase nueva (p. ej. al ejecutar sin abrir el editor).
const SpriteScript := preload("res://scripts/characters/character_sprite.gd")
const BombSpriteScript := preload("res://scripts/characters/bomb_sprite.gd")

@export var display_name := "Personaje"
@export var base_speed := 230.0
@export var body_color := Color(0.35, 0.65, 1.0)
## Color del nombre bajo el personaje (los jugadores P1/P2 lo usan para distinguirse).
var name_color := Color.WHITE

var has_bomb := false:
	set(value):
		if value == has_bomb:
			return
		has_bomb = value
		collision_mask = 3 | (8 if value else 0)
		queue_redraw()
var is_eliminated := false
var is_using_shortcut := false
var game_map: GameMap
var _sprite: AnimatedSprite2D
var _bomb_sprite: Node2D
var _transfer_flash_left := 0.0
## effect_id -> multiplicador de velocidad (>=1, solo mejoras).
var speed_modifiers: Dictionary = {}
## effect_id -> true. Si no está vacío, el personaje está "marcado" (visible en minimapa).
var marks: Dictionary = {}


func _ready() -> void:
	add_to_group("characters")
	z_index = 2
	collision_layer = 2
	collision_mask = 3
	if has_bomb:
		collision_mask |= 8
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = BODY_RADIUS
		shape.shape = circle
		add_child(shape)
	_sprite = SpriteScript.new()
	add_child(_sprite)
	# La papa-bomba flota sobre la cabeza (la base de la papa queda justo encima del sprite).
	_bomb_sprite = BombSpriteScript.new()
	_bomb_sprite.position = Vector2(0.0, -BODY_RADIUS - 8.0)
	_bomb_sprite.visible = has_bomb
	add_child(_bomb_sprite)
	GameEvents.bomb_transferred.connect(_on_bomb_transferred)


## Los bots lo sobrescriben: indica si entran solos a un atajo cercano.
func can_auto_use_shortcut() -> bool:
	return false


func _on_bomb_transferred(_from: Node, to: Node) -> void:
	if to == self:
		flash_transfer()


func _physics_process(_delta: float) -> void:
	if _transfer_flash_left > 0.0:
		_transfer_flash_left -= _delta
	if is_eliminated or not GameManager.is_playing():
		velocity = Vector2.ZERO
		return
	if is_using_shortcut:
		velocity = Vector2.ZERO
		return
	if not has_bomb and game_map != null:
		var use_automatically := can_auto_use_shortcut()
		if use_automatically or wants_shortcut():
			if game_map.try_use_shortcut(self):
				return
	velocity = get_input_direction().limit_length(1.0) * get_current_speed()
	move_and_slide()


func _process(_delta: float) -> void:
	# Parpadeo al recibir la bomba (los sprites son nodos hijos, no parte de _draw).
	var blink_hidden := _transfer_flash_left > 0.0 and int(_transfer_flash_left * 12.0) % 2 == 0
	if _sprite != null:
		_sprite.visible = not blink_hidden
	if _bomb_sprite != null:
		_bomb_sprite.visible = has_bomb and not blink_hidden
	queue_redraw()


func flash_transfer() -> void:
	_transfer_flash_left = 0.9


## Indica si el personaje pide usar un atajo en este frame. PlayerCharacter lo
## sobrescribe con la tecla de atajo que le corresponde (E / Espacio / E de P1 / Espacio de P2).
func wants_shortcut() -> bool:
	return false


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
	if _transfer_flash_left > 0.0 and int(_transfer_flash_left * 12.0) % 2 == 0:
		return
	if is_marked():
		draw_arc(Vector2.ZERO, BODY_RADIUS + 8.0, 0.0, TAU, 32, Color(1.0, 0.9, 0.2), 3.0)
	# Sombra bajo los pies; el cuerpo lo dibuja CharacterSprite.
	draw_set_transform(Vector2(0.0, BODY_RADIUS - 3.0), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, BODY_RADIUS * 0.9, Color(0.0, 0.0, 0.0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(-50.0, BODY_RADIUS + 20.0),
		display_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		100.0,
		13,
		name_color
	)
