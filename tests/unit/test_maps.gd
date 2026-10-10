extends GutTest
## RF-02: dos escenarios 2D diferenciados y navegables.


func _load_map(id: String) -> GameMap:
	var scene: PackedScene = load(GameManager.MAPS[id].scene)
	var map := scene.instantiate() as GameMap
	add_child_autofree(map)
	return map


func test_there_are_exactly_two_maps() -> void:
	assert_eq(GameManager.MAPS.size(), 2)


func test_maps_are_distinct() -> void:
	var park := _load_map("park")
	var city := _load_map("city")
	assert_ne(park.display_name, city.display_name)
	assert_ne(park.ground_color, city.ground_color)


func test_spawn_and_block_points_are_valid_for_each_map() -> void:
	for id in GameManager.MAPS:
		var map := _load_map(id)
		var bounds := map.get_bounds()
		assert_gte(
			map.get_spawn_points().size(), GameManager.MAX_BOTS + 1, "%s: puntos de aparición" % id
		)
		assert_gt(map.get_lucky_block_points().size(), 0, "%s: Lucky Blocks" % id)
		var all_points: Array[Vector2] = map.get_spawn_points() + map.get_lucky_block_points()
		for point in all_points:
			assert_true(bounds.has_point(point), "%s: %s fuera del mapa" % [id, point])
			for rect in map.get_obstacle_rects():
				assert_false(
					rect.grow(Character.BODY_RADIUS + 2.0).has_point(point),
					"%s: %s cae dentro de un obstáculo %s" % [id, point, rect]
				)


func test_map_builds_collision_walls() -> void:
	var map := _load_map("park")
	var walls := map.get_node("Walls") as StaticBody2D
	assert_not_null(walls)
	assert_eq(walls.collision_layer, 1)
	assert_gte(walls.get_child_count(), map.obstacles.size() + 4)
