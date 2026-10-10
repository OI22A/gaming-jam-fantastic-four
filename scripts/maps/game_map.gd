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
const SHORTCUT_INTERACTION_RADIUS := 56.0
const SHORTCUT_WIDTH := 96.0
const SHORTCUT_GATE_DEPTH := 34.0
const SHORTCUT_WALL_THICKNESS := 12.0

@export var map_id := "map"
@export var display_name := "Mapa"
@export var map_size := Vector2(2400.0, 1350.0)
@export var shortcut_use_seconds := 3.2
@export var ground_color := Color(0.35, 0.6, 0.3)

## Cada obstáculo: {rect: Rect2, kind: String, color: Color}
var obstacles: Array[Dictionary] = []
var spawn_points: Array[Vector2] = []
var lucky_block_points: Array[Vector2] = []
## Cada atajo tiene una entrada interactiva, una salida y un corredor cerrado.
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
		if character.global_position.distance_to(entry) > SHORTCUT_INTERACTION_RADIUS:
			continue
		_shortcut_busy[index] = true
		character.is_using_shortcut = true
		character.velocity = Vector2.ZERO
		var old_z := character.z_index
		character.z_index = 20
		var tween := character.create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(character, "global_position", exit, shortcut_use_seconds)
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
		var score := exit.distance_to(threat) - from.distance_to(entry)
		if score > best_score:
			best_score = score
			best = entry
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
	shortcut_barriers.collision_layer = 1
	shortcut_barriers.collision_mask = 0
	add_child(shortcut_barriers)
	for route in shortcuts:
		_add_shortcut_walls(shortcut_barriers, route.entry, route.exit)
	var b := get_bounds()
	var t := WALL_THICKNESS
	_add_rect_shape(body, Rect2(b.position.x - t, b.position.y - t, b.size.x + 2.0 * t, t))
	_add_rect_shape(body, Rect2(b.position.x - t, b.end.y, b.size.x + 2.0 * t, t))
	_add_rect_shape(body, Rect2(b.position.x - t, b.position.y, t, b.size.y))
	_add_rect_shape(body, Rect2(b.end.x, b.position.y, t, b.size.y))


func _add_shortcut_walls(body: StaticBody2D, entry: Vector2, exit: Vector2) -> void:
	var direction := (exit - entry).normalized()
	var side := direction.orthogonal() * (SHORTCUT_WIDTH * 0.5)
	var entry_gate := entry + direction * SHORTCUT_GATE_DEPTH
	var exit_gate := exit - direction * SHORTCUT_GATE_DEPTH
	_add_wall_segment(body, entry_gate + side, exit_gate + side, SHORTCUT_WALL_THICKNESS)
	_add_wall_segment(body, entry_gate - side, exit_gate - side, SHORTCUT_WALL_THICKNESS)
	_add_wall_segment(body, entry_gate + side, entry_gate - side, SHORTCUT_WALL_THICKNESS)
	_add_wall_segment(body, exit_gate + side, exit_gate - side, SHORTCUT_WALL_THICKNESS)


func _add_wall_segment(
	body: StaticBody2D, start: Vector2, end: Vector2, thickness: float
) -> void:
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	var delta := end - start
	rectangle.size = Vector2(delta.length(), thickness)
	shape.shape = rectangle
	shape.position = (start + end) * 0.5
	shape.rotation = delta.angle()
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
		_draw_shortcut(route.entry, route.exit)
	for obstacle in obstacles:
		_draw_obstacle(obstacle)


func _draw_shortcut(entry: Vector2, exit: Vector2) -> void:
	var direction := (exit - entry).normalized()
	var side := direction.orthogonal() * (SHORTCUT_WIDTH * 0.5)
	var corridor := PackedVector2Array(
		[entry + side, exit + side, exit - side, entry - side]
	)
	draw_colored_polygon(corridor, Color(0.19, 0.1, 0.32, 0.9))
	draw_polyline(
		PackedVector2Array([entry + side, exit + side, exit - side, entry - side, entry + side]),
		Color(0.8, 0.55, 1.0),
		6.0
	)
	var entry_gate := entry + direction * SHORTCUT_GATE_DEPTH
	var exit_gate := exit - direction * SHORTCUT_GATE_DEPTH
	draw_line(entry_gate + side, entry_gate - side, Color(1.0, 0.78, 0.25), 8.0)
	draw_line(exit_gate + side, exit_gate - side, Color(0.4, 0.9, 1.0), 8.0)
	draw_circle(entry, 15.0, Color(1.0, 0.78, 0.25))
	draw_circle(exit, 15.0, Color(0.4, 0.9, 1.0))
	draw_string(
		ThemeDB.fallback_font,
		entry + Vector2(18.0, -16.0),
		"ENTRADA",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		16,
		Color.WHITE
	)
	draw_string(
		ThemeDB.fallback_font,
		exit + Vector2(18.0, -16.0),
		"SALIDA",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		16,
		Color.WHITE
	)


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
