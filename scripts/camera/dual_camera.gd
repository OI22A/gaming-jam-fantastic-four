class_name DualCamera
extends Camera2D
## Cámara única del modo 2 jugadores (NO divide la pantalla).
##
## Se coloca en el punto medio de los jugadores enfocados y ajusta el zoom para que
## todos aparezcan siempre en pantalla: si se separan se aleja, si se juntan se acerca.
## Con un solo objetivo (el otro jugador murió) simplemente lo sigue con el zoom normal.
##
## La cámara NO tiene límites de mapa: el zoom puede alejarse hasta mostrar el mapa completo
## (más el margen) aunque cada jugador esté en una esquina opuesta. Lo que quede fuera del mapa
## se ve negro (ver `TiledMap.OutsideMask`); los jugadores no pueden salir porque el mapa tiene
## paredes perimetrales.
##
## Todo el suavizado depende de `delta` (no de frames).

## Zoom mínimo de respaldo si todavía no se llamó a `set_bounds`.
const FALLBACK_MIN_ZOOM := 0.2

## Margen (en píxeles de mundo) entre los jugadores y el borde de la pantalla.
@export var margin := 220.0
## Zoom máximo (1.0 = escala normal). Nunca se acerca más que esto.
@export var max_zoom := 1.0
## Rapidez del suavizado del zoom (mayor = más rápido).
@export var zoom_speed := 4.0

var _targets: Array[Node2D] = []
var _bounds := Rect2()


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0


## Guarda el rectángulo del mapa. Ya NO se usan `limit_*` de Camera2D: así la cámara puede
## centrarse en el punto medio aunque eso muestre zonas fuera del mapa (se ven en negro).
func set_bounds(bounds: Rect2) -> void:
	_bounds = bounds


## Zoom más lejano que usa la cámara: el que muestra el mapa completo más el margen.
## Como los jugadores nunca salen del mapa, con este zoom siempre caben los dos.
func min_zoom_for(view_size: Vector2) -> float:
	if _bounds.size.x <= 0.0 or _bounds.size.y <= 0.0:
		return FALLBACK_MIN_ZOOM
	return minf(_fit_zoom(_bounds.size, view_size), max_zoom)


## Jugadores que debe enfocar la cámara (se cambia al empezar cada ronda).
func set_targets(targets: Array[Node2D]) -> void:
	_targets = targets


func get_targets() -> Array[Node2D]:
	return _targets


## Zoom necesario para que `rect` (más el margen) quepa en `view_size`.
func zoom_for_rect(rect: Rect2, view_size: Vector2) -> float:
	return clampf(_fit_zoom(rect.size, view_size), min_zoom_for(view_size), max_zoom)


func _fit_zoom(extent: Vector2, view_size: Vector2) -> float:
	var needed := extent + Vector2(margin, margin) * 2.0
	return minf(view_size.x / needed.x, view_size.y / needed.y)


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
