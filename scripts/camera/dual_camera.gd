class_name DualCamera
extends Camera2D
## Cámara única del modo 2 jugadores (NO divide la pantalla).
##
## Se coloca en el punto medio de los jugadores enfocados y ajusta el zoom para que
## todos aparezcan siempre en pantalla: si se separan se aleja, si se juntan se acerca.
## Con un solo objetivo (el otro jugador murió) simplemente lo sigue con el zoom normal.
##
## Todo el suavizado depende de `delta` (no de frames).

## Margen (en píxeles de mundo) entre los jugadores y el borde de la pantalla.
@export var margin := 220.0
## Zoom máximo (1.0 = escala normal). Nunca se acerca más que esto.
@export var max_zoom := 1.0
## Rapidez del suavizado del zoom (mayor = más rápido).
@export var zoom_speed := 4.0

var _targets: Array[Node2D] = []
var _min_zoom := 0.2


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0


## Límites del mapa: la cámara no se sale de ellos y el zoom mínimo muestra el mapa entero.
func set_bounds(bounds: Rect2) -> void:
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.end.x)
	limit_bottom = int(bounds.end.y)
	var view := get_viewport_rect().size
	_min_zoom = maxf(view.x / bounds.size.x, view.y / bounds.size.y)


## Jugadores que debe enfocar la cámara (se cambia al empezar cada ronda).
func set_targets(targets: Array[Node2D]) -> void:
	_targets = targets


func get_targets() -> Array[Node2D]:
	return _targets


## Zoom necesario para que `rect` (más el margen) quepa en `view_size`.
func zoom_for_rect(rect: Rect2, view_size: Vector2) -> float:
	var needed := Vector2(rect.size.x + margin * 2.0, rect.size.y + margin * 2.0)
	var fit := minf(view_size.x / needed.x, view_size.y / needed.y)
	return clampf(fit, _min_zoom, max_zoom)


func _process(delta: float) -> void:
	if _targets.is_empty():
		return
	var first := _targets[0].global_position
	var rect := Rect2(first, Vector2.ZERO)
	for target in _targets:
		rect = rect.expand(target.global_position)
	global_position = rect.get_center()
	var wanted := zoom_for_rect(rect, get_viewport_rect().size)
	var weight := 1.0 - exp(-zoom_speed * delta)
	zoom = zoom.lerp(Vector2(wanted, wanted), weight)
