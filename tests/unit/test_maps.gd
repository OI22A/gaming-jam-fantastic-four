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
		assert_eq(map.get_spawn_points().size(), 10, "%s: diez apariciones" % id)
		assert_gte(map.shortcuts.size(), 2, "%s: pares de atajos" % id)
		assert_eq(map.map_size, Vector2(2400.0, 1350.0))
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


func test_shortcut_rejects_carrier_and_locks_pair_during_animation() -> void:
	var map := _load_map("park")
	var entry: Vector2 = map.shortcuts[0].entry
	var first := Character.new()
	add_child_autofree(first)
	first.global_position = entry
	assert_true(map.try_use_shortcut(first))
	assert_true(first.is_using_shortcut)
	assert_true((first.collision_mask & 1) != 0, "El no portador tampoco debe poder cruzar caminando.")
	assert_almost_eq(map.shortcut_use_seconds, 3.2, 0.001)
	var second := Character.new()
	add_child_autofree(second)
	second.global_position = entry
	assert_false(map.try_use_shortcut(second))
	var carrier := Character.new()
	add_child_autofree(carrier)
	carrier.global_position = entry
	carrier.has_bomb = true
	assert_false(map.try_use_shortcut(carrier))
	assert_true((carrier.collision_mask & 1) != 0, "El portador debe chocar con la barrera del atajo.")
	assert_eq(map.get_node("ShortcutBarriers").collision_layer, 1)
	assert_gte(
		map.get_node("ShortcutBarriers").get_child_count(), map.shortcuts.size() * 4,
		"Cada zona segura debe quedar cerrada con laterales y puertas."
	)


func test_shortcut_exit_cannot_be_used_as_an_entry() -> void:
	var map := _load_map("park")
	var character := Character.new()
	add_child_autofree(character)
	character.global_position = map.shortcuts[0].exit
	assert_false(map.try_use_shortcut(character), "La salida no debe permitir reingresar.")
