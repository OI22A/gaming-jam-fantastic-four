class_name BombSprite
extends Node2D
## Aspecto visual de la bomba: una papa con la mecha encendida. Solo es "vista":
## no decide quién lleva la bomba ni cuánto tiempo queda. Character la muestra u
## oculta según `has_bomb`, y este nodo escucha `GameEvents.bomb_time_changed`
## (la misma señal que ya usan el HUD y el audio) para intensificar la llama.
##
## Arte (assets/art/bomb/), ambos con el MISMO lienzo de 30x45 px para que alineen:
##   - potato_bomb.png:  papa + mecha, sin llama (estática).
##   - potato_flame.png: 4 fotogramas de la llama en horizontal (120x45 en total).
## Si reemplazas los PNG por otros de distinto tamaño, ajusta BODY_ANCHOR y FLAME_PIVOT.

const BODY_PATH := "res://assets/art/bomb/potato_bomb.png"
const FLAME_PATH := "res://assets/art/bomb/potato_flame.png"
const FLAME_FRAME_COUNT := 4
const FLAME_FPS := 8.0
## Píxel del PNG del cuerpo que queda en el origen del nodo: centro del borde
## inferior de la papa. Así Character solo debe colocar el nodo sobre la cabeza.
const BODY_ANCHOR := Vector2(13.0, 45.0)
## Base de la llama (en píxeles de un fotograma). Es el pivote al escalarla, para
## que crezca sin despegarse de la punta de la mecha.
const FLAME_PIVOT := Vector2(24.0, 15.0)
## La llama se intensifica en los últimos segundos (mismo umbral que el tic-tac).
const DANGER_SECONDS := 10.0
const MAX_FLAME_SCALE := 1.4
const MAX_FLAME_SPEED := 2.2
## Tinte de la llama cuando el tiempo está por agotarse (más rojiza).
const HOT_TINT := Color(1.0, 0.72, 0.55)

static var _body_texture: Texture2D
static var _flame_frames: SpriteFrames

## 0.0 = llama normal, 1.0 = máxima intensidad (tiempo en cero).
var intensity := 0.0
var _body: Sprite2D
var _flame: AnimatedSprite2D


## Intensidad (0..1) de la llama para un tiempo restante dado. Pública y estática
## para poder probarla sin depender del motor.
static func intensity_for(time_left: float) -> float:
	return clampf(1.0 - time_left / DANGER_SECONDS, 0.0, 1.0)


static func body_texture() -> Texture2D:
	if _body_texture == null:
		_body_texture = TmxReader.load_texture(BODY_PATH)
	return _body_texture


static func build_flame_frames() -> SpriteFrames:
	if _flame_frames != null:
		return _flame_frames
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("burn")
	frames.set_animation_speed("burn", FLAME_FPS)
	frames.set_animation_loop("burn", true)
	var texture := TmxReader.load_texture(FLAME_PATH)
	if texture == null:
		return frames
	var frame_size := Vector2(float(texture.get_width()) / FLAME_FRAME_COUNT, texture.get_height())
	for column in FLAME_FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(Vector2(column * frame_size.x, 0.0), frame_size)
		frames.add_frame("burn", atlas)
	_flame_frames = frames
	return _flame_frames


func _init() -> void:
	name = "BombSprite"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body = Sprite2D.new()
	_body.name = "Body"
	_body.texture = body_texture()
	_body.centered = false
	_body.offset = -BODY_ANCHOR
	add_child(_body)
	# Misma esquina superior izquierda que el cuerpo; el nodo vive en el pivote.
	_flame = AnimatedSprite2D.new()
	_flame.name = "Flame"
	_flame.sprite_frames = build_flame_frames()
	_flame.centered = false
	_flame.offset = -FLAME_PIVOT
	_flame.position = FLAME_PIVOT - BODY_ANCHOR
	add_child(_flame)


func _ready() -> void:
	_flame.play("burn")
	GameEvents.bomb_time_changed.connect(_on_bomb_time_changed)


## Ajusta la llama: más grande, más rápida y más rojiza cuanto más cerca de 1.0.
func set_intensity(value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	if is_equal_approx(value, intensity):
		return
	intensity = value
	_flame.scale = Vector2.ONE * lerpf(1.0, MAX_FLAME_SCALE, intensity)
	_flame.speed_scale = lerpf(1.0, MAX_FLAME_SPEED, intensity)
	_flame.modulate = Color.WHITE.lerp(HOT_TINT, intensity)


func _on_bomb_time_changed(time_left: float, _duration: float) -> void:
	set_intensity(intensity_for(time_left))
