class_name LuckyBlock
extends Area2D
## Lucky Block (RF-06). Solo lo puede recoger quien lleva la bomba.
##
## Se vigila el solapamiento en cada frame de física (en lugar de la señal
## body_entered) para cubrir el caso de recibir la bomba estando ya dentro del bloque.

signal collected(block: LuckyBlock, collector: Character)

const SIZE := 30.0

var is_active := true
var rarity: int = RewardTable.Rarity.COMMON
var _time := 0.0


func _init() -> void:
	collision_layer = 4
	collision_mask = 2


func _ready() -> void:
	add_to_group("lucky_blocks")
	z_index = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(SIZE, SIZE)
	shape.shape = rect
	add_child(shape)


func _physics_process(_delta: float) -> void:
	if not is_active or not GameManager.is_playing():
		return
	for body in get_overlapping_bodies():
		var character := body as Character
		if character != null and character.has_bomb and not character.is_eliminated:
			is_active = false
			visible = false
			collected.emit(self, character)
			return


func _process(delta: float) -> void:
	var human_has_bomb := false
	for node in get_tree().get_nodes_in_group("characters"):
		var character := node as Character
		if character is PlayerCharacter and character.has_bomb and not character.is_eliminated:
			human_has_bomb = true
			break
	visible = is_active and human_has_bomb
	if is_active:
		_time += delta
		if visible:
			queue_redraw()


func activate() -> void:
	is_active = true
	visible = true


func _draw() -> void:
	var bob := sin(_time * 3.0) * 3.0
	var rect := Rect2(Vector2(-SIZE / 2.0, -SIZE / 2.0 + bob), Vector2(SIZE, SIZE))
	var base := RewardTable.rarity_color(rarity)
	var ink := base.darkened(0.55)
	draw_rect(rect, base)
	# Brillo metálico: franja clara arriba y sombra abajo.
	draw_rect(Rect2(rect.position + Vector2(3.0, 3.0), Vector2(SIZE - 6.0, 3.0)), base.lightened(0.5))
	draw_rect(Rect2(rect.position + Vector2(3.0, SIZE - 6.0), Vector2(SIZE - 6.0, 3.0)), base.darkened(0.25))
	draw_rect(rect, ink, false, 3.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-8.0, 8.0 + bob),
		"?",
		HORIZONTAL_ALIGNMENT_CENTER,
		16.0,
		24,
		ink
	)
