extends Node
## Estado global de la partida (autoload "GameManager"). RF-01.
##
## Responsabilidades:
## - Mantener la máquina de estados de la partida.
## - Iniciar, pausar, reiniciar y terminar partidas.
## - Guardar la configuración elegida en el menú (número de bots).
##
## La construcción de la escena de juego la hace Main (reacciona a
## `GameEvents.match_requested`); el desarrollo de las rondas lo hace
## MatchController.

enum State { MENU, COUNTDOWN, PLAYING, ROUND_END, ENDED, PAUSED }

## Único mapa jugable: el mapa de Tiled (assets/map/mapa.tmx).
const DEFAULT_MAP_ID := "tiled"
const MAPS := {
	"tiled": {"name": "Mapa del Barrio", "scene": "res://scenes/maps/tiled_map.tscn"},
}
const MIN_BOTS := 1
const MAX_BOTS := 10

var state: State = State.MENU
var current_map_id := DEFAULT_MAP_ID
var round_number := 0
var player_won := false
var bot_count := 3
## Modo de juego elegido en el menú: false = 1 jugador, true = 2 jugadores (P1 y P2).
var two_players := false
## En modo 2 jugadores: "P1" o "P2" si ganó uno de ellos; "" si no hay ganador humano.
var winner_label := ""

var _state_before_pause: State = State.MENU


func _ready() -> void:
	# Necesario para poder pausar/reanudar con el árbol en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
	elif event.is_action_pressed("restart") and state != State.MENU:
		restart_match()


func is_playing() -> bool:
	return state == State.PLAYING


func set_state(new_state: State) -> void:
	if new_state == state:
		return
	var old_state := state
	state = new_state
	GameEvents.state_changed.emit(new_state, old_state)


func start_match(map_id: String = "") -> void:
	if MAPS.has(map_id):
		current_map_id = map_id
	round_number = 0
	player_won = false
	winner_label = ""
	get_tree().paused = false
	set_state(State.COUNTDOWN)
	GameEvents.match_requested.emit(current_map_id)


func restart_match() -> void:
	start_match(current_map_id)


## `winner` es la etiqueta del jugador ganador en modo 2 jugadores ("P1" / "P2").
func end_match(won: bool, winner: String = "") -> void:
	player_won = won
	winner_label = winner if won else ""
	set_state(State.ENDED)
	GameEvents.match_ended.emit(won)


func go_to_menu() -> void:
	get_tree().paused = false
	set_state(State.MENU)
	GameEvents.menu_requested.emit()


func toggle_pause() -> void:
	if state == State.PAUSED:
		get_tree().paused = false
		set_state(_state_before_pause)
	elif state == State.COUNTDOWN or state == State.PLAYING:
		_state_before_pause = state
		get_tree().paused = true
		set_state(State.PAUSED)


## Restablece el estado (útil para pruebas automatizadas).
func reset() -> void:
	get_tree().paused = false
	state = State.MENU
	round_number = 0
	player_won = false
	winner_label = ""
	two_players = false
