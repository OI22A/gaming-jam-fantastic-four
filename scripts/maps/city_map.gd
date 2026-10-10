class_name CityMap
extends GameMap
## Escenario 2: manzanas de edificios con calles, autos estacionados y
## cruces. RF-02.


func _init() -> void:
	map_id = "city"
	display_name = "Calles del Centro"
	ground_color = Color(0.22, 0.23, 0.26)


func _define_layout() -> void:
	var palette := [
		Color(0.55, 0.38, 0.35),
		Color(0.4, 0.45, 0.6),
		Color(0.5, 0.5, 0.42),
		Color(0.38, 0.52, 0.48),
		Color(0.6, 0.45, 0.3),
		Color(0.45, 0.4, 0.55),
	]
	var index := 0
	for row_y in [150.0, 630.0]:
		for col_x in [220.0, 780.0, 1340.0]:
			add_obstacle(
				Rect2(col_x, row_y, 360.0, 300.0), "building", palette[index % palette.size()]
			)
			index += 1
	# Autos estacionados
	add_obstacle(Rect2(320.0, 520.0, 90.0, 44.0), "car", Color(0.8, 0.2, 0.2))
	add_obstacle(Rect2(1180.0, 560.0, 90.0, 44.0), "car", Color(0.2, 0.5, 0.8))
	add_obstacle(Rect2(1560.0, 480.0, 90.0, 44.0), "car", Color(0.9, 0.8, 0.2))

	spawn_points = [
		Vector2(100.0, 100.0),
		Vector2(1820.0, 100.0),
		Vector2(100.0, 980.0),
		Vector2(1820.0, 980.0),
		Vector2(960.0, 540.0),
		Vector2(680.0, 540.0),
	]
	lucky_block_points = [
		Vector2(680.0, 300.0),
		Vector2(1240.0, 300.0),
		Vector2(680.0, 780.0),
		Vector2(1240.0, 780.0),
		Vector2(440.0, 540.0),
		Vector2(1500.0, 540.0),
	]


func _draw_ground_details() -> void:
	# Aceras alrededor de cada manzana
	for obstacle in obstacles:
		if obstacle.kind == "building":
			var rect: Rect2 = obstacle.rect
			draw_rect(rect.grow(14.0), Color(0.45, 0.46, 0.5))
	# Líneas viales discontinuas
	var line_color := Color(0.9, 0.9, 0.9, 0.8)
	var x := 0.0
	while x < 1920.0:
		draw_rect(Rect2(x, 536.0, 30.0, 8.0), line_color)
		x += 60.0
	var y := 0.0
	while y < 1080.0:
		draw_rect(Rect2(676.0, y, 8.0, 30.0), line_color)
		draw_rect(Rect2(1236.0, y, 8.0, 30.0), line_color)
		y += 60.0
