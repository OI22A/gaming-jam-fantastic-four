class_name GameMap
extends Node2D
## Mapa base (RF-02). Los mapas concretos (ParkMap, CityMap) sobrescriben
## `_define_layout()` y registran obstáculos, puntos de aparición y puntos de
## Lucky Blocks. La colisión y el dibujo se generan automáticamente a partir de
## esos datos, así que no se necesitan arte ni TileMaps para jugar.
##
## Cuando exista arte real se puede reemplazar `_draw()` por Sprites/TileMaps
## conservando la misma API (get_bounds, get_spawn_points, ...).

const WALL_THICKNESS := 200.0

@export var map_id := "map"
@export var display_name := "Mapa"
@export var map_size := Vector2(1920.0, 1080.0)
@export var ground_color := Color(0.35, 0.6, 0.3)

## Cada obstáculo: {rect: Rect2, kind: String, color: Color}
var obstacles: Array[Dictionary] = []
var spawn_points: Array[Vector2] = []
var lucky_block_points: Array[Vector2] = []


func _ready() -> void:
	_define_layout()
	_build_collision()
	queue_redraw()


## Sobrescribir en cada mapa.
func _define_layout() -> void:
	pass


func add_obstacle(rect: Rect2, kind: String = "block", color: Color = Color(0.5, 0.5, 0.5)) -> void:
	obstacles.append({"rect": rect, "kind": kind, "color": color})


func get_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, map_size)


func get_spawn_points() -> Array[Vector2]:
	return spawn_points.duplicate()


func get_lucky_block_points() -> Array[Vector2]:
	return lucky_block_points.duplicate()


func get_obstacle_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for obstacle in obstacles:
		rects.append(obstacle.rect)
	return rects


func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "Walls"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for obstacle in obstacles:
		_add_rect_shape(body, obstacle.rect)
	var b := get_bounds()
	var t := WALL_THICKNESS
	_add_rect_shape(body, Rect2(b.position.x - t, b.position.y - t, b.size.x + 2.0 * t, t))
	_add_rect_shape(body, Rect2(b.position.x - t, b.end.y, b.size.x + 2.0 * t, t))
	_add_rect_shape(body, Rect2(b.position.x - t, b.position.y, t, b.size.y))
	_add_rect_shape(body, Rect2(b.end.x, b.position.y, t, b.size.y))


func _add_rect_shape(body: StaticBody2D, rect: Rect2) -> void:
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	shape.position = rect.get_center()
	body.add_child(shape)


# --- Dibujo -----------------------------------------------------------------


func _draw() -> void:
	_draw_surroundings()
	draw_rect(get_bounds(), ground_color)
	_draw_ground_details()
	for obstacle in obstacles:
		_draw_obstacle(obstacle)


## Marco de edificios de la ciudad alrededor del mapa (ambientación urbana).
func _draw_surroundings() -> void:
	var b := get_bounds()
	draw_rect(
		Rect2(b.position - Vector2(400.0, 400.0), b.size + Vector2(800.0, 800.0)),
		Color(0.13, 0.14, 0.18)
	)
	var x := -200.0
	while x < b.end.x + 200.0:
		var h := 110.0 + float(int(absf(x) / 160.0) * 37 % 5) * 22.0
		_draw_building(Rect2(x, -h - 10.0, 148.0, h), Color(0.28, 0.3, 0.38))
		_draw_building(Rect2(x, b.end.y + 10.0, 148.0, h), Color(0.25, 0.27, 0.35))
		x += 160.0
	var y := 0.0
	while y < b.end.y:
		var w := 110.0 + float(int(y / 160.0) * 29 % 4) * 24.0
		_draw_building(Rect2(-w - 10.0, y, w, 148.0), Color(0.26, 0.28, 0.36))
		_draw_building(Rect2(b.end.x + 10.0, y, w, 148.0), Color(0.27, 0.29, 0.37))
		y += 160.0


## Detalles del suelo (caminos, marcas viales...). Sobrescribir en cada mapa.
func _draw_ground_details() -> void:
	pass


func _draw_building(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
	var window := Color(0.95, 0.85, 0.5, 0.55)
	var wx := rect.position.x + 14.0
	while wx < rect.end.x - 20.0:
		var wy := rect.position.y + 14.0
		while wy < rect.end.y - 20.0:
			draw_rect(Rect2(wx, wy, 16.0, 20.0), window)
			wy += 38.0
		wx += 34.0


func _draw_obstacle(obstacle: Dictionary) -> void:
	var rect: Rect2 = obstacle.rect
	var color: Color = obstacle.color
	var center := rect.get_center()
	match obstacle.kind:
		"building":
			_draw_building(rect, color)
			draw_rect(rect, color.darkened(0.4), false, 4.0)
		"tree":
			draw_circle(center + Vector2(4.0, 6.0), rect.size.x * 0.62, Color(0.0, 0.0, 0.0, 0.25))
			draw_circle(center, rect.size.x * 0.6, color)
			draw_circle(center + Vector2(-8.0, -8.0), rect.size.x * 0.3, color.lightened(0.2))
		"fountain":
			draw_circle(center, rect.size.y * 0.5, Color(0.7, 0.72, 0.78))
			draw_circle(center, rect.size.y * 0.5 - 10.0, color)
			draw_circle(center, rect.size.y * 0.18, Color(0.85, 0.9, 1.0))
		"bench":
			draw_rect(rect, color)
			draw_rect(rect, color.darkened(0.45), false, 2.0)
			draw_line(
				rect.position + Vector2(0.0, rect.size.y * 0.5),
				rect.end - Vector2(0.0, rect.size.y * 0.5),
				color.darkened(0.3),
				2.0
			)
		"car":
			draw_rect(rect, color)
			draw_rect(
				Rect2(
					rect.position + Vector2(rect.size.x * 0.25, 4.0),
					Vector2(rect.size.x * 0.5, rect.size.y - 8.0)
				),
				Color(0.75, 0.88, 1.0, 0.8)
			)
			draw_rect(rect, color.darkened(0.5), false, 2.0)
		_:
			draw_rect(rect, color)
			draw_rect(rect, color.darkened(0.4), false, 2.0)
