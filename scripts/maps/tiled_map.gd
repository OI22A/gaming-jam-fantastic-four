class_name TiledMap
extends GameMap
## Único mapa jugable: "Mapa (Videojuego 24 horas)" hecho en Tiled.
##
## Lee `res://assets/map/mapa.tmx` en tiempo de ejecución con TmxReader:
## - dibuja cada capa de tiles (con sus tilesets y texturas) en el orden de Tiled;
## - convierte cada rectángulo del grupo de objetos "colisiones" en una colisión
##   sólida (misma posición y tamaño), reutilizando el StaticBody2D "Walls" de GameMap;
## - mantiene la API de GameMap (bounds, apariciones, Lucky Blocks, obstáculos),
##   por lo que bots, bomba, HUD y minimapa funcionan sin cambios.

const TMX_PATH := "res://assets/map/mapa.tmx"
const COLLISION_GROUP := "colisiones"

## Capas que se dibujan por encima de los personajes (techos y copas); el resto queda
## por debajo. Los nombres son los de las capas en Tiled.
@export var overhead_layers: PackedStringArray = ["Edificios 2", "Edificios", "Decoración 2"]
## Dibuja en pantalla los rectángulos de colisión (útil para depurar).
@export var debug_collisions := false

## Puntos transitables (centro de celda, con holgura de al menos 64 px a cualquier
## colisión y dentro de la zona navegable de los bots).
const SPAWN_POINTS: Array[Vector2] = [
	Vector2(720, 688),
	Vector2(1488, 1392),
	Vector2(112, 1328),
	Vector2(1328, 176),
	Vector2(304, 112),
	Vector2(112, 720),
	Vector2(1296, 816),
	Vector2(880, 1232),
	Vector2(848, 208),
	Vector2(464, 1488),
	Vector2(432, 432),
	Vector2(1232, 1168),
]
const LUCKY_BLOCK_POINTS: Array[Vector2] = [
	Vector2(976, 912),
	Vector2(592, 1232),
	Vector2(368, 688),
	Vector2(1264, 1488),
	Vector2(784, 432),
	Vector2(1136, 688),
	Vector2(1328, 1008),
	Vector2(1072, 1232),
]

var tmx_data: Dictionary = {}
var _background := Color(0.23, 0.69, 0.33)


func _init() -> void:
	map_id = "tiled"
	display_name = "Mapa del Barrio"
	# El TMX ya está a escala real (1 px de Tiled = 1 px de juego).
	layout_scale = 1.0
	scale_to_default_size = false


func _ready() -> void:
	super._ready()
	_build_tile_layers()
	_build_outside_mask()


func _define_layout() -> void:
	tmx_data = TmxReader.read(TMX_PATH)
	if not tmx_data.ok:
		push_error("TiledMap: %s" % tmx_data.error)
		return
	map_size = tmx_data.pixel_size
	_background = tmx_data.background
	ground_color = _background
	# Una colisión por cada objeto de la capa "colisiones" (sin duplicar rectángulos).
	var seen := {}
	for rect: Rect2 in tmx_data.objects.get(COLLISION_GROUP, []):
		if seen.has(rect):
			continue
		seen[rect] = true
		add_obstacle(rect, "tiled", Color(0.5, 0.5, 0.5))
	_define_court_shortcuts()
	spawn_points.assign(SPAWN_POINTS)
	lucky_block_points.assign(LUCKY_BLOCK_POINTS)


## Atajos por las puertas de la cancha (solo para quien NO lleva la bomba, con E / Espacio).
## La cancha ya está cerrada por las colisiones del mapa; cada puerta se cierra con una
## barrera para que solo se pueda cruzar usando el atajo, que es de un solo sentido:
##   puerta izquierda: entrada al norte  -> salida al sur
##   puerta derecha:   entrada al sur    -> salida al norte
func _define_court_shortcuts() -> void:
	add_shortcut(
		Vector2(176.0, 764.0),
		Vector2(172.0, 1112.0),
		[Rect2(160.0, 800.0, 35.0, 62.0), Rect2(160.0, 1025.0, 35.0, 63.0)]
	)
	add_shortcut(
		Vector2(817.0, 1112.0),
		Vector2(817.0, 764.0),
		[Rect2(799.0, 800.0, 37.0, 63.0), Rect2(799.0, 1025.0, 36.0, 63.0)]
	)


func _build_tile_layers() -> void:
	if not tmx_data.get("ok", false):
		return
	var tile_size: Vector2i = tmx_data.tile_size
	var holder := Node2D.new()
	holder.name = "TileLayers"
	holder.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(holder)
	for layer: Dictionary in tmx_data.layers:
		if not layer.visible or _is_empty_layer(layer.gids):
			continue
		var node := TileLayerNode.new()
		node.name = String(layer.name).replace(" ", "_")
		node.data = tmx_data
		node.gids = layer.gids
		node.modulate.a = layer.opacity
		node.z_index = 3 if overhead_layers.has(layer.name) else 0
		holder.add_child(node)
	var markers := ShortcutMarkers.new()
	markers.routes = shortcuts
	markers.z_index = 1
	add_child(markers)
	if debug_collisions:
		var overlay := CollisionOverlay.new()
		overlay.rects = get_obstacle_rects()
		overlay.z_index = 50
		add_child(overlay)


## Cubre de negro todo lo que queda fuera del mapa (la cámara compartida del modo 2 jugadores
## puede mostrar esa zona). z_index 1: tapa las capas de tiles (z 0), que pueden sobresalir del
## borde, pero queda por debajo de los personajes (z 2) y de los techos (z 3).
func _build_outside_mask() -> void:
	var mask := OutsideMask.new()
	mask.name = "OutsideMask"
	mask.bounds = get_bounds()
	mask.z_index = 1
	add_child(mask)


func _is_empty_layer(gids: PackedInt32Array) -> bool:
	for gid in gids:
		if gid != 0:
			return false
	return true


## Solo el color de fondo de Tiled dentro del mapa: el arte lo dibujan las capas de tiles.
## Fuera del mapa no se pinta nada aquí (lo cubre `OutsideMask` y el resto es el fondo negro).
func _draw() -> void:
	draw_rect(get_bounds(), _background)


## Dibuja una capa de tiles. Cada tile se alinea abajo a la izquierda de su celda,
## como hace Tiled (los tiles altos, como árboles y edificios, crecen hacia arriba).
class TileLayerNode:
	extends Node2D

	var data: Dictionary = {}
	var gids := PackedInt32Array()

	func _draw() -> void:
		var tile_size: Vector2i = data.tile_size
		var columns: int = data.width
		for index in gids.size():
			var info := TmxReader.tile_draw_info(data, gids[index])
			if info.is_empty():
				continue
			var texture: Texture2D = info[0]
			var region: Rect2 = info[1]
			var offset: Vector2 = info[2]
			var cell := Vector2((index % columns) * tile_size.x, (index / columns) * tile_size.y)
			var position := Vector2(cell.x, cell.y + tile_size.y - region.size.y) + offset
			draw_texture_rect_region(texture, Rect2(position, region.size), region)


## Cuatro rectángulos negros alrededor del mapa. Nunca se ve en el modo 1 jugador (la cámara
## de seguimiento no sale del mapa); en 2 jugadores es lo que se ve fuera de los bordes.
class OutsideMask:
	extends Node2D

	## Cuánto se extiende la máscara más allá de cada borde (más que cualquier vista posible).
	const EXTENT := 6000.0

	var bounds := Rect2()

	func _draw() -> void:
		var e := EXTENT
		var b := bounds
		draw_rect(Rect2(b.position.x - e, b.position.y - e, b.size.x + 2.0 * e, e), Color.BLACK)
		draw_rect(Rect2(b.position.x - e, b.end.y, b.size.x + 2.0 * e, e), Color.BLACK)
		draw_rect(Rect2(b.position.x - e, b.position.y, e, b.size.y), Color.BLACK)
		draw_rect(Rect2(b.end.x, b.position.y, e, b.size.y), Color.BLACK)


## Marcas de entrada (amarillo) y salida (celeste) de cada atajo.
class ShortcutMarkers:
	extends Node2D

	var routes: Array[Dictionary] = []

	func _draw() -> void:
		for route in routes:
			_marker(route.entry, Color(1.0, 0.78, 0.25), "ENTRADA [E]")
			_marker(route.exit, Color(0.4, 0.9, 1.0), "SALIDA")

	func _marker(point: Vector2, color: Color, label: String) -> void:
		draw_circle(point, 15.0, Color(color, 0.55))
		draw_arc(point, 15.0, 0.0, TAU, 24, color, 3.0)
		draw_string(
			ThemeDB.fallback_font,
			point + Vector2(-34.0, -22.0),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			14,
			Color.WHITE
		)


class CollisionOverlay:
	extends Node2D

	var rects: Array[Rect2] = []

	func _draw() -> void:
		for rect in rects:
			draw_rect(rect, Color(1.0, 0.1, 0.1, 0.35))
			draw_rect(rect, Color(1.0, 0.1, 0.1, 0.9), false, 1.0)
