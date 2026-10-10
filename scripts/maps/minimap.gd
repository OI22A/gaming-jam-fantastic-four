class_name Minimap
extends Control
## Minimapa (RF-08). Muestra el mapa a escala y las posiciones relevantes:
##   - Jugador: azul        - Quien tiene la bomba: rojo
##   - Marcados (efecto "radar"): anillo amarillo
##   - Resto de rivales: gris (si `show_unmarked_rivals` es true)

@export var panel_size := Vector2(240.0, 135.0)
@export var show_unmarked_rivals := true

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
		if character.is_marked():
			draw_arc(point, 7.0, 0.0, TAU, 16, Color(1.0, 0.9, 0.2), 2.0)
		if character.has_bomb:
			draw_circle(point, 5.0, Color(1.0, 0.25, 0.2))
		elif character is PlayerCharacter:
			draw_circle(point, 5.0, Color(0.3, 0.65, 1.0))
		elif character.is_marked() or show_unmarked_rivals:
			draw_circle(point, 3.5, Color(0.7, 0.7, 0.7))
