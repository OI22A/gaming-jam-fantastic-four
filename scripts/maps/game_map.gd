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
const LAYOUT_SCALE := 1.25
const SHORTCUT_RADIUS := 56.0

@export var map_id := "map"
@export var display_name := "Mapa"
@export var map_size := Vector2(2400.0, 1350.0)
@export var shortcut_use_seconds := 1.2
@export var ground_color := Color(0.35, 0.6, 0.3)

## Cada obstáculo: {rect: Rect2, kind: String, color: Color}
var obstacles: Array[Dictionary] = []
var spawn_points: Array[Vector2] = []
var lucky_block_points: Array[Vector2] = []
## Cada atajo conecta dos zonas y se bloquea durante la animación de uso.
var shortcuts: Array[Dictionary] = []
var _shortcut_busy: Array[bool] = []


func _ready() -> void:
	_define_layout()
	_scale_layout()
	_build_navigation()
	_build_collision()
	queue_redraw()


## Sobrescribir en cada mapa.
func _define_layout() -> void:
	pass


func add_obstacle(rect: Rect2, kind: String = "block", color: Color = Color(0.5, 0.5, 0.5)) -> void:
	obstacles.append({"rect": rect, "kind": kind, "color": color})


func add_shortcut(entry: Vector2, exit: Vector2) -> void:
	shortcuts.append({"entry": entry, "exit": exit})


func _scale_layout() -> void:
	map_size = Vector2(1920.0, 1080.0) * LAYOUT_SCALE
	for i in obstacles.size():
		var obstacle: Dictionary = obstacles[i]
		var rect: Rect2 = obstacle.rect
		obstacle.rect = Rect2(rect.position * LAYOUT_SCALE, rect.size * LAYOUT_SCALE)
		obstacles[i] = obstacle
	for i in spawn_points.size():
		spawn_points[i] = spawn_points[i] * LAYOUT_SCALE
	for i in lucky_block_points.size():
		lucky_block_points[i] = lucky_block_points[i] * LAYOUT_SCALE
	for i in shortcuts.size():
		var route: Dictionary = shortcuts[i]
		var entry: Vector2 = route.entry
		var exit: Vector2 = route.exit
		route.entry = entry * LAYOUT_SCALE
		route.exit = exit * LAYOUT_SCALE
		shortcuts[i] = route
		_shortcut_busy.append(false)


func _build_navigation() -> void:
	var region := NavigationRegion2D.new()
	region.name = "Navigation"
	region.navigation_layers = 1
	region.navigation_polygon = _make_navigation_polygon(true)
	add_child(region)


func _make_navigation_polygon(block_shortcuts: bool) -> NavigationPolygon:
	var polygon := NavigationPolygon.new()
	polygon.add_outline(
		PackedVector2Array(
			[
				Vector2(24, 24),
				Vector2(map_size.x - 24, 24),
				map_size - Vector2(24, 24),
				Vector2(24, map_size.y - 24),
			]
		)
	)
	for obstacle in obstacles:
		var rect: Rect2 = obstacle.rect.grow(Character.BODY_RADIUS + 8.0)
		_add_navigation_hole(polygon, rect)
	if block_shortcuts:
		for route in shortcuts:
			_add_navigation_hole(polygon, Rect2(route.entry - Vector2(52, 52), Vector2(104, 104)))
			_add_navigation_hole(polygon, Rect2(route.exit - Vector2(52, 52), Vector2(104, 104)))
	polygon.make_polygons_from_outlines()
	return polygon


func _add_navigation_hole(polygon: NavigationPolygon, rect: Rect2) -> void:
	polygon.add_outline(
		PackedVector2Array(
			[
				rect.position,
				Vector2(rect.position.x, rect.end.y),
				rect.end,
				Vector2(rect.end.x, rect.position.y),
			]
		)
	)


func try_use_shortcut(character: Character) -> bool:
	if (
		character == null
		or character.has_bomb
		or character.is_eliminated
		or character.is_using_shortcut
	):
		return false
	for index in shortcuts.size():
		if _shortcut_busy[index]:
			continue
		var route: Dictionary = shortcuts[index]
		var entry: Vector2 = route.entry
		var exit: Vector2 = route.exit
		var start := entry
		var destination := exit
		if character.global_position.distance_to(exit) < character.global_position.distance_to(entry):
			start = exit
			destination = entry
		if character.global_position.distance_to(start) > SHORTCUT_RADIUS:
			continue
		_shortcut_busy[index] = true
		character.is_using_shortcut = true
		character.velocity = Vector2.ZERO
		var midpoint := (start + destination) * 0.5 + Vector2(0.0, -90.0)
		var old_z := character.z_index
		character.z_index = 5
		var tween := character.create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(character, "global_position", midpoint, shortcut_use_seconds * 0.5)
		tween.tween_property(character, "global_position", destination, shortcut_use_seconds * 0.5)
		tween.finished.connect(_finish_shortcut.bind(index, character, old_z))
		return true
	return false


func _finish_shortcut(index: int, character: Character, old_z: int) -> void:
	if index < _shortcut_busy.size():
		_shortcut_busy[index] = false
	if is_instance_valid(character):
		character.is_using_shortcut = false
		character.z_index = old_z
		character.velocity = Vector2.ZERO


func nearest_shortcut_entry(from: Vector2) -> Vector2:
	var best := Vector2.ZERO
	var distance := INF
	for route in shortcuts:
		var entry: Vector2 = route.entry
		var candidate := from.distance_to(entry)
		if candidate < distance:
			distance = candidate
			best = entry
	return best


func escape_shortcut_entry(from: Vector2, threat: Vector2) -> Vector2:
	var best := Vector2.ZERO
	var best_score := -INF
	for route in shortcuts:
		var entry: Vector2 = route.entry
		var exit: Vector2 = route.exit
		var forward_score := exit.distance_to(threat) - from.distance_to(entry)
		if forward_score > best_score:
			best_score = forward_score
			best = entry
		var reverse_score := entry.distance_to(threat) - from.distance_to(exit)
		if reverse_score > best_score:
			best_score = reverse_score
			best = exit
	return best


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
	var shortcut_barriers := StaticBody2D.new()
	shortcut_barriers.name = "ShortcutBarriers"
	shortcut_barriers.collision_layer = 8
	shortcut_barriers.collision_mask = 0
	add_child(shortcut_barriers)
	for route in shortcuts:
		_add_shortcut_barrier(shortcut_barriers, route.entry)
		_add_shortcut_barrier(shortcut_barriers, route.exit)
	var b := get_bounds()
	var t := WALL_THICKNESS
	_add_rect_shape(body, Rect2(b.position.x - t, b.position.y - t, b.size.x + 2.0 * t, t))
	_add_rect_shape(body, Rect2(b.position.x - t, b.end.y, b.size.x + 2.0 * t, t))
	_add_rect_shape(body, Rect2(b.position.x - t, b.position.y, t, b.size.y))
	_add_rect_shape(body, Rect2(b.end.x, b.position.y, t, b.size.y))


func _add_shortcut_barrier(body: StaticBody2D, point: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = SHORTCUT_RADIUS
	shape.shape = circle
	shape.position = point
	body.add_child(shape)


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
	for route in shortcuts:
		_draw_shortcut(route.entry)
		_draw_shortcut(route.exit)
	for obstacle in obstacles:
		_draw_obstacle(obstacle)


func _draw_shortcut(point: Vector2) -> void:
	draw_circle(point, SHORTCUT_RADIUS, Color(0.4, 0.15, 0.72, 0.45))
	draw_arc(point, SHORTCUT_RADIUS - 4.0, 0.0, TAU, 40, Color(0.8, 0.55, 1.0), 5.0)


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
