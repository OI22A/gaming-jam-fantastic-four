extends Node
## Punto de entrada. Alterna entre el menú principal y la partida según los
## eventos de GameManager (match_requested / menu_requested).

var _menu: MainMenu
var _match: MatchController


func _ready() -> void:
	GameEvents.match_requested.connect(_on_match_requested)
	GameEvents.menu_requested.connect(_show_menu)
	_show_menu()


func _show_menu() -> void:
	_clear_match()
	if _menu == null:
		_menu = MainMenu.new()
		add_child(_menu)


func _on_match_requested(map_id: String) -> void:
	_clear_match()
	if _menu != null:
		_menu.queue_free()
		_menu = null
	_match = MatchController.new()
	_match.map_id = map_id
	add_child(_match)


func _clear_match() -> void:
	if _match != null:
		# Se saca del árbol antes de liberarlo para que sus personajes
		# desaparezcan de los grupos de inmediato.
		remove_child(_match)
		_match.queue_free()
		_match = null
