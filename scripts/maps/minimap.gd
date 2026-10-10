class_name Minimap
extends Control
## Minimapa de rastreo: solo aparece mientras el humano tiene activo Radar.
## Durante esa habilidad muestra las posiciones de todos los personajes vivos.

@export var panel_size := Vector2(240.0, 135.0)
var _map: GameMap
var _characters_provider: Callable


func _init() -> void:
	custom_minimum_size = panel_size
	size = panel_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(game_map: GameMap, characters_provider: Callable) -> void:
	_map = game_map
	_characters_provider = characters_provider


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.1, 0.75))
	if _map == null:
		return
	var factor := size / _map.map_size
	draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 1.0, 1.0, 0.15), false, 1.0)
	for rect in _map.get_obstacle_rects():
		draw_rect(Rect2(rect.position * factor, rect.size * factor), Color(0.6, 0.6, 0.65, 0.8))
	if not _characters_provider.is_valid():
		return
	for node in _characters_provider.call():
		var character := node as Character
		if character == null:
			continue
		var point := character.global_position * factor
		if character is PlayerCharacter:
			# En 2 jugadores cada uno se ve con su color (P1 / P2); en 1 jugador, azul como siempre.
			var dot := character.body_color if GameManager.two_players else Color(0.3, 0.65, 1.0)
			draw_circle(point, 5.0, dot)
		else:
			draw_circle(point, 3.5, Color(0.7, 0.7, 0.7))
