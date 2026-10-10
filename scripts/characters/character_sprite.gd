class_name CharacterSprite
extends AnimatedSprite2D
## Sprite animado de 8 direcciones para jugador y bots (hoja "8Dir_LowRez_Run").
##
## Cada PNG `assets/art/characters/run_<dirección>.png` mide 32x16: dos fotogramas de
## 16x16 del ciclo de carrera. No hay animación de reposo, así que parado se muestra el
## primer fotograma de la última dirección. La dirección sale del movimiento real del
## personaje (por eso también anima los atajos), no de la tecla pulsada.
##
## La camiseta naranja del sprite base se tiñe con `body_color` del personaje, de modo
## que cada bot sigue siendo distinguible.

const DIRECTIONS: Array[String] = [
	"right", "right_down", "down", "left_down", "left", "left_up", "up", "right_up"
]
const FRAME_SIZE := Vector2i(16, 16)
const SPRITE_SCALE := 2.0
const RUN_FPS := 8.0
## Los pies quedan algo por encima del borde inferior del círculo de colisión.
const SPRITE_OFFSET := Vector2(0.0, -4.0)
## Color de la camiseta en el arte original.
const SHIRT_SOURCE := Color8(223, 113, 38)
## Si el personaje no se mueve durante este tiempo, vuelve a la pose de reposo.
const IDLE_AFTER := 0.1

const SHIRT_SHADER_CODE := """
shader_type canvas_item;
uniform vec4 shirt_source : source_color = vec4(0.875, 0.443, 0.149, 1.0);
uniform vec4 shirt_target : source_color = vec4(0.25, 0.6, 1.0, 1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a > 0.0 && distance(c.rgb, shirt_source.rgb) < 0.02) {
		c.rgb = shirt_target.rgb;
	}
	COLOR = c;
}
"""

static var _frames: SpriteFrames
static var _shader: Shader

var facing := "down"
var _character: Character
var _last_position := Vector2.ZERO
var _idle_timer := 0.0


## Nombre de la dirección (de las 8 posibles) más cercana al vector `direction`.
static func direction_name(direction: Vector2) -> String:
	if direction.length_squared() < 0.000001:
		return "down"
	var index := int(roundf(direction.angle() / (PI / 4.0)))
	return DIRECTIONS[posmod(index, 8)]


static func build_frames() -> SpriteFrames:
	if _frames != null:
		return _frames
	_frames = SpriteFrames.new()
	_frames.remove_animation("default")
	for direction in DIRECTIONS:
		var texture := TmxReader.load_texture("res://assets/art/characters/run_%s.png" % direction)
		var run := "run_" + direction
		var idle := "idle_" + direction
		_frames.add_animation(run)
		_frames.set_animation_speed(run, RUN_FPS)
		_frames.set_animation_loop(run, true)
		_frames.add_animation(idle)
		_frames.set_animation_speed(idle, 1.0)
		_frames.set_animation_loop(idle, false)
		for column in 2:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(Vector2(column * FRAME_SIZE.x, 0), Vector2(FRAME_SIZE))
			_frames.add_frame(run, atlas)
			if column == 0:
				_frames.add_frame(idle, atlas)
	return _frames


func _init() -> void:
	name = "Sprite"
	sprite_frames = build_frames()
	scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	position = SPRITE_OFFSET
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _ready() -> void:
	_character = get_parent() as Character
	if _character != null:
		_last_position = _character.global_position
		set_shirt_color(_character.body_color)
	_apply(false)


func set_shirt_color(color: Color) -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHIRT_SHADER_CODE
	var shader_material := ShaderMaterial.new()
	shader_material.shader = _shader
	shader_material.set_shader_parameter("shirt_source", SHIRT_SOURCE)
	shader_material.set_shader_parameter("shirt_target", color)
	material = shader_material


func _process(delta: float) -> void:
	if _character == null:
		return
	var moved := _character.global_position - _last_position
	_last_position = _character.global_position
	if moved.length() > 0.05:
		facing = direction_name(moved)
		_idle_timer = 0.0
	else:
		_idle_timer += delta
	speed_scale = clampf(_character.get_speed_multiplier(), 1.0, 2.0)
	_apply(_idle_timer < IDLE_AFTER)


## Muestra la animación de carrera (o la pose de reposo) de la dirección actual.
func _apply(running: bool) -> void:
	var wanted := ("run_" if running else "idle_") + facing
	if animation != StringName(wanted):
		var keep_frame := frame
		var keep_progress := frame_progress
		play(wanted)
		if running and animation.begins_with("run_"):
			set_frame_and_progress(mini(keep_frame, 1), keep_progress)
	elif not is_playing():
		play(wanted)
