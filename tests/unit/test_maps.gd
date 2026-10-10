extends GutTest
## RF-02: el mapa de Tiled es el único mapa jugable, con arte por capas y
## colisiones tomadas del grupo de objetos "colisiones" del .tmx.

const MAP_ID := "tiled"


func _load_map() -> TiledMap:
	var scene: PackedScene = load(GameManager.MAPS[MAP_ID].scene)
	var map := scene.instantiate() as TiledMap
	add_child_autofree(map)
	return map


func test_there_is_exactly_one_playable_map() -> void:
	assert_eq(GameManager.MAPS.size(), 1)
	assert_true(GameManager.MAPS.has(GameManager.DEFAULT_MAP_ID))
	assert_eq(GameManager.current_map_id, GameManager.DEFAULT_MAP_ID)


func test_tmx_is_read_with_original_dimensions() -> void:
	var data := TmxReader.read(TiledMap.TMX_PATH)
	assert_true(data.ok, data.error)
	assert_eq(data.width, 50)
	assert_eq(data.height, 50)
	assert_eq(data.tile_size, Vector2i(32, 32))
	assert_eq(data.pixel_size, Vector2(1600.0, 1600.0))
	assert_eq(data.tilesets.size(), 14)
	assert_eq(data.layers.size(), 12)
	assert_eq(data.objects[TiledMap.COLLISION_GROUP].size(), 243)
	for tileset in data.tilesets:
		var has_art: bool = tileset.texture != null or not tileset.tiles.is_empty()
		assert_true(has_art, "Tileset %d sin texturas" % tileset.firstgid)


func test_map_size_and_tile_layers_follow_the_tmx() -> void:
	var map := _load_map()
	assert_eq(map.map_size, Vector2(1600.0, 1600.0))
	assert_eq(map.get_bounds(), Rect2(Vector2.ZERO, Vector2(1600.0, 1600.0)))
	var layers := map.get_node("TileLayers")
	assert_eq(layers.get_child_count(), 11, "Once capas con tiles (la duodécima está vacía).")
	assert_eq(layers.get_child(0).name, &"Piso", "El orden de capas debe ser el de Tiled.")
	assert_eq(layers.get_child(layers.get_child_count() - 1).name, &"Decoración_2")


func test_collisions_match_tmx_objects_without_duplicates() -> void:
	var map := _load_map()
	var rects: Array = map.tmx_data.objects[TiledMap.COLLISION_GROUP]
	assert_eq(map.obstacles.size(), rects.size())
	var walls := map.get_node("Walls") as StaticBody2D
	assert_eq(walls.collision_layer, 1)
	assert_eq(walls.get_child_count(), rects.size() + 4, "Un shape por objeto + 4 muros del borde.")
	var seen := {}
	for i in rects.size():
		var rect: Rect2 = rects[i]
		assert_false(seen.has(rect), "Colisión duplicada %s" % rect)
		seen[rect] = true
		var shape := walls.get_child(i) as CollisionShape2D
		assert_eq(shape.position, rect.get_center(), "Posición de la colisión %d" % i)
		assert_eq((shape.shape as RectangleShape2D).size, rect.size, "Tamaño de la colisión %d" % i)


func test_spawn_and_block_points_are_walkable() -> void:
	var map := _load_map()
	var bounds := map.get_bounds()
	assert_gte(map.get_spawn_points().size(), GameManager.MAX_BOTS + 1)
	assert_gte(map.get_spawn_points().size(), 10)
	assert_gte(map.get_lucky_block_points().size(), 4)
	var all_points: Array[Vector2] = map.get_spawn_points() + map.get_lucky_block_points()
	var clearance := Character.BODY_RADIUS + 22.0 + 8.0
	for point in all_points:
		assert_true(bounds.has_point(point), "%s fuera del mapa" % point)
		for rect in map.get_obstacle_rects():
			assert_false(
				rect.grow(clearance).has_point(point), "%s cae junto a la colisión %s" % [point, rect]
			)


func test_spawn_points_are_connected_for_bots() -> void:
	var map := _load_map()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var nav_map := map.get_world_2d().navigation_map
	var spawns := map.get_spawn_points()
	for i in range(1, spawns.size()):
		var path := NavigationServer2D.map_get_path(nav_map, spawns[0], spawns[i], true)
		assert_gt(path.size(), 1, "Sin ruta de %s a %s" % [spawns[0], spawns[i]])
		if not path.is_empty():
			assert_lt(path[path.size() - 1].distance_to(spawns[i]), 40.0, "Ruta incompleta a %s" % spawns[i])


func test_characters_are_blocked_by_tmx_collisions() -> void:
	var map := _load_map()
	var character := Character.new()
	add_child_autofree(character)
	await get_tree().physics_frame
	var tested := 0
	for rect in map.get_obstacle_rects().slice(0, 60):
		# Se coloca el personaje justo a la izquierda del rectángulo y se empuja hacia él.
		var start := Vector2(rect.position.x - Character.BODY_RADIUS - 2.0, rect.get_center().y)
		if not map.get_bounds().has_point(start):
			continue
		character.global_position = start
		if character.test_move(character.transform, Vector2.ZERO):
			continue  # empieza dentro de otro obstáculo
		var collision := KinematicCollision2D.new()
		var blocked := character.test_move(character.transform, Vector2(12.0, 0.0), collision)
		assert_true(blocked, "El personaje atraviesa la colisión %s" % rect)
		tested += 1
	assert_gt(tested, 10)


# --- Atajos de la cancha ------------------------------------------------------


func test_court_has_two_one_way_shortcuts_closed_by_barriers() -> void:
	var map := _load_map()
	assert_eq(map.shortcuts.size(), 2)
	var barriers := map.get_node("ShortcutBarriers") as StaticBody2D
	assert_eq(barriers.collision_layer, 1)
	assert_eq(barriers.get_child_count(), 4, "Cada atajo cierra sus dos puertas.")
	for route in map.shortcuts:
		for point: Vector2 in [route.entry, route.exit]:
			assert_true(map.get_bounds().has_point(point))
			for rect in map.get_obstacle_rects():
				assert_false(rect.grow(Character.BODY_RADIUS + 2.0).has_point(point), "%s sobre %s" % [point, rect])
			for barrier: Rect2 in route.barriers:
				assert_false(barrier.grow(Character.BODY_RADIUS).has_point(point))


func test_court_doors_cannot_be_walked_through() -> void:
	var map := _load_map()
	var character := Character.new()
	add_child_autofree(character)
	await get_tree().physics_frame
	for route in map.shortcuts:
		for barrier: Rect2 in route.barriers:
			var from_top: bool = barrier.position.y < 900.0
			var start := Vector2(barrier.get_center().x, barrier.position.y - Character.BODY_RADIUS - 2.0)
			var push := Vector2(0.0, 30.0)
			if not from_top:
				start.y = barrier.end.y + Character.BODY_RADIUS + 2.0
				push = Vector2(0.0, -30.0)
			character.global_position = start
			assert_true(character.test_move(character.transform, push), "La puerta %s está abierta" % barrier)


func test_shortcut_flow_for_non_carrier_only() -> void:
	var map := _load_map()
	map.shortcut_use_seconds = 0.2
	var route: Dictionary = map.shortcuts[0]
	var runner := Character.new()
	add_child_autofree(runner)
	runner.global_position = route.entry
	assert_true(map.try_use_shortcut(runner))
	assert_true(runner.is_using_shortcut)
	var second := Character.new()
	add_child_autofree(second)
	second.global_position = route.entry
	assert_false(map.try_use_shortcut(second), "El atajo está ocupado.")
	var carrier := Character.new()
	add_child_autofree(carrier)
	carrier.global_position = (map.shortcuts[1] as Dictionary).entry
	carrier.has_bomb = true
	assert_false(map.try_use_shortcut(carrier), "El portador no puede usar el atajo.")
	await get_tree().create_timer(0.5).timeout
	assert_false(runner.is_using_shortcut)
	assert_lt(runner.global_position.distance_to(route.exit), 2.0, "Debe terminar en la salida.")
	assert_false(map.try_use_shortcut(runner), "La salida no sirve como entrada.")


func test_shortcut_points_are_reachable_by_bots() -> void:
	var map := _load_map()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var nav_map := map.get_world_2d().navigation_map
	for route in map.shortcuts:
		for point: Vector2 in [route.entry, route.exit]:
			var path := NavigationServer2D.map_get_path(nav_map, map.get_spawn_points()[0], point, true)
			assert_gt(path.size(), 1, "Sin ruta hasta %s" % point)
			if not path.is_empty():
				assert_lt(path[path.size() - 1].distance_to(point), 60.0, "Ruta incompleta a %s" % point)
