class_name ParkMap
extends GameMap
## Escenario 1: parque con ambientación de ciudad (fuente, árboles, bancas),
## rodeado de edificios. RF-02.


func _init() -> void:
	map_id = "park"
	display_name = "Parque Central"
	ground_color = Color(0.32, 0.58, 0.30)


func _define_layout() -> void:
	# Fuente central
	add_obstacle(Rect2(860.0, 470.0, 200.0, 140.0), "fountain", Color(0.35, 0.6, 0.9))
	# Árboles
	var tree_color := Color(0.15, 0.42, 0.18)
	for pos in [
		Vector2(300.0, 250.0),
		Vector2(300.0, 780.0),
		Vector2(1560.0, 250.0),
		Vector2(1560.0, 780.0),
		Vector2(700.0, 200.0),
		Vector2(1156.0, 830.0),
		Vector2(1000.0, 110.0),
	]:
		add_obstacle(Rect2(pos, Vector2(64.0, 64.0)), "tree", tree_color)
	# Bancas
	var bench_color := Color(0.55, 0.36, 0.2)
	add_obstacle(Rect2(500.0, 640.0, 140.0, 32.0), "bench", bench_color)
	add_obstacle(Rect2(1280.0, 400.0, 140.0, 32.0), "bench", bench_color)
	add_obstacle(Rect2(900.0, 780.0, 140.0, 32.0), "bench", bench_color)

	spawn_points = [
		Vector2(200.0, 200.0),
		Vector2(1720.0, 200.0),
		Vector2(200.0, 880.0),
		Vector2(1720.0, 880.0),
		Vector2(960.0, 330.0),
		Vector2(960.0, 920.0),
		Vector2(80.0, 540.0),
		Vector2(1840.0, 540.0),
		Vector2(540.0, 120.0),
		Vector2(1380.0, 960.0),
	]
	add_shortcut(Vector2(160.0, 540.0), Vector2(1760.0, 540.0))
	add_shortcut(Vector2(800.0, 100.0), Vector2(800.0, 980.0))
	lucky_block_points = [
		Vector2(480.0, 400.0),
		Vector2(1440.0, 400.0),
		Vector2(480.0, 780.0),
		Vector2(1440.0, 700.0),
		Vector2(960.0, 210.0),
		Vector2(960.0, 860.0),
	]


func _draw_ground_details() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(GameMap.LAYOUT_SCALE, GameMap.LAYOUT_SCALE))
	var path_color := Color(0.78, 0.7, 0.52)
	draw_rect(Rect2(0.0, 510.0, 1920.0, 60.0), path_color)
	draw_rect(Rect2(930.0, 0.0, 60.0, 1080.0), path_color)
	draw_circle(Vector2(960.0, 540.0), 190.0, path_color)
	# Flores decorativas (semilla fija para que el dibujo sea estable)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var colors := [Color(1.0, 0.5, 0.6), Color(1.0, 0.9, 0.3), Color(0.9, 0.9, 1.0)]
	for i in 90:
		draw_circle(
			Vector2(rng.randf_range(20.0, 1900.0), rng.randf_range(20.0, 1060.0)),
			3.0,
			colors[i % 3]
		)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
