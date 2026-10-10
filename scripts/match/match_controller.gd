class_name MatchController
extends Node2D
## Gestión de la partida (RF-01 / RF-05): construye el mapa, los personajes y los
## sistemas (bomba, efectos, Lucky Blocks, cámara, HUD) y dirige las rondas.
##
## Flujo:  COUNTDOWN (3 s) -> ROUND (la bomba corre) -> explosión ->
##         el portador queda eliminado ->
##           * si era el jugador: DERROTA
##           * si no quedan bots:  VICTORIA
##           * si no: ROUND_END (pausa breve) -> nueva COUNTDOWN
##
## Modo 2 jugadores (GameManager.two_players): P1 y P2 juegan con la misma cámara.
##   * Si muere un jugador, la partida sigue y la cámara solo enfoca al que sigue vivo
##     (el cambio se aplica al empezar la siguiente ronda).
##   * Si mueren los dos: DERROTA (fin de partida como siempre).
##   * Si no quedan bots y solo queda un jugador vivo: gana ese jugador ("Ganó P1" / "Ganó P2").
##     Si quedan los dos jugadores sin bots, se sigue jugando hasta que quede uno.
##
## Se destruye y recrea al reiniciar la partida (ver main.gd).

enum Phase { COUNTDOWN, ROUND, ROUND_END, DONE }

const BOT_NAMES := ["Bot Alfa", "Bot Beta", "Bot Gamma", "Bot Delta", "Bot Épsilon"]
const BOT_COLORS := [
	Color(1.0, 0.45, 0.35),
	Color(0.4, 0.85, 0.45),
	Color(0.95, 0.8, 0.3),
	Color(0.8, 0.5, 0.95),
	Color(0.95, 0.55, 0.8),
]

@export var map_id := GameManager.DEFAULT_MAP_ID
@export var countdown_seconds := 3
@export var round_end_delay := 2.0
@export var bomb_duration := 60.0

var map: GameMap
## En 1 jugador es el único jugador; en 2 jugadores es P1 (compatibilidad).
var player: PlayerCharacter
## Jugadores humanos: [player] en 1 jugador, [P1, P2] en 2 jugadores.
var players: Array[PlayerCharacter] = []
var camera: Camera2D
var characters: Array[Character] = []
var bomb: BombManager
var effects: EffectManager
var spawner: LuckyBlockSpawner
var hud: Hud
var phase: Phase = Phase.COUNTDOWN

var _phase_time := 0.0
var _last_tick := -1
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_build_map()
	_build_characters()
	_build_systems()
	_build_camera()
	_build_hud()
	GameEvents.bomb_exploded.connect(_on_bomb_exploded)
	_begin_countdown()


func _process(delta: float) -> void:
	match phase:
		Phase.COUNTDOWN:
			_phase_time -= delta
			var seconds := ceili(_phase_time)
			if seconds != _last_tick and seconds > 0:
				_last_tick = seconds
				GameEvents.countdown_tick.emit(seconds)
			if _phase_time <= 0.0:
				_start_round()
		Phase.ROUND_END:
			_phase_time -= delta
			if _phase_time <= 0.0:
				_begin_countdown()


func get_alive_characters() -> Array[Character]:
	var alive: Array[Character] = []
	for character in characters:
		if not character.is_eliminated:
			alive.append(character)
	return alive


## Para pruebas automatizadas: salta la cuenta regresiva.
func debug_skip_countdown() -> void:
	_phase_time = 0.0


# --- Construcción -------------------------------------------------------------


func _build_map() -> void:
	var info: Dictionary = GameManager.MAPS.get(map_id, GameManager.MAPS[GameManager.DEFAULT_MAP_ID])
	var scene: PackedScene = load(info.scene)
	map = scene.instantiate() as GameMap
	add_child(map)


func _build_characters() -> void:
	var spawns := map.get_spawn_points()
	var human_total := 2 if GameManager.two_players else 1
	for i in human_total:
		var human := PlayerCharacter.new()
		if GameManager.two_players:
			human.player_index = i + 1
		human.game_map = map
		add_child(human)
		characters.append(human)
		players.append(human)
	player = players[0]
	var bot_total := clampi(GameManager.bot_count, GameManager.MIN_BOTS, spawns.size() - human_total)
	for i in bot_total:
		var bot := BotCharacter.new()
		bot.display_name = BOT_NAMES[i % BOT_NAMES.size()]
		bot.body_color = BOT_COLORS[i % BOT_COLORS.size()]
		bot.arena_bounds = map.get_bounds()
		bot.game_map = map
		add_child(bot)
		characters.append(bot)
	_reset_positions()


func _build_systems() -> void:
	bomb = BombManager.new()
	bomb.duration = bomb_duration
	add_child(bomb)
	bomb.setup(characters)

	effects = EffectManager.new()
	add_child(effects)

	spawner = LuckyBlockSpawner.new()
	add_child(spawner)
	spawner.setup(map.get_lucky_block_points(), effects, get_alive_characters)


func _build_camera() -> void:
	if GameManager.two_players:
		_build_dual_camera()
		return
	var follow := Camera2D.new()
	var bounds := map.get_bounds()
	follow.limit_left = int(bounds.position.x)
	follow.limit_top = int(bounds.position.y)
	follow.limit_right = int(bounds.end.x)
	follow.limit_bottom = int(bounds.end.y)
	follow.position_smoothing_enabled = true
	player.add_child(follow)
	camera = follow


## Cámara compartida: enfoca el punto medio de los jugadores y ajusta el zoom (ver DualCamera).
func _build_dual_camera() -> void:
	var dual := DualCamera.new()
	add_child(dual)
	dual.set_bounds(map.get_bounds())
	camera = dual
	_update_camera_targets()
	dual.global_position = _midpoint_of(dual.get_targets())
	dual.reset_smoothing()


## La cámara pasa a enfocar solo a los jugadores que siguen vivos.
func _update_camera_targets() -> void:
	var dual := camera as DualCamera
	if dual == null:
		return
	var targets: Array[Node2D] = []
	for human in players:
		if not human.is_eliminated:
			targets.append(human)
	dual.set_targets(targets)


func _midpoint_of(nodes: Array[Node2D]) -> Vector2:
	if nodes.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	for node in nodes:
		sum += node.global_position
	return sum / nodes.size()


func _build_hud() -> void:
	hud = Hud.new()
	add_child(hud)
	hud.setup(player, effects, bomb, map, get_alive_characters, players)


# --- Rondas -------------------------------------------------------------------


func _reset_positions() -> void:
	var spawns := map.get_spawn_points()
	spawns.shuffle()
	var i := 0
	for character in get_alive_characters():
		character.global_position = spawns[i % spawns.size()]
		character.velocity = Vector2.ZERO
		i += 1


func _begin_countdown() -> void:
	phase = Phase.COUNTDOWN
	_phase_time = float(countdown_seconds)
	_last_tick = -1
	effects.clear_all()
	_reset_positions()
	_update_camera_targets()
	GameManager.set_state(GameManager.State.COUNTDOWN)


func _start_round() -> void:
	phase = Phase.ROUND
	GameManager.round_number += 1
	var alive := get_alive_characters()
	var holder := alive[_rng.randi_range(0, alive.size() - 1)]
	bomb.start_round(holder)
	GameManager.set_state(GameManager.State.PLAYING)
	GameEvents.round_started.emit(GameManager.round_number, holder)


func _on_bomb_exploded(holder_node: Node) -> void:
	var holder := holder_node as Character
	if holder == null or phase != Phase.ROUND:
		return
	phase = Phase.ROUND_END
	holder.has_bomb = false
	holder.is_eliminated = true
	holder.visible = false
	holder.set_deferred("collision_layer", 0)
	effects.clear_for(holder)

	var fx := ExplosionFx.new()
	fx.position = holder.global_position
	add_child(fx)
	GameEvents.character_eliminated.emit(holder)

	var humans_alive := _alive_human_count()
	if humans_alive == 0:
		_finish(false)
	elif _alive_bot_count() == 0 and humans_alive == 1:
		_finish(true, _last_human_alive())
	else:
		GameManager.set_state(GameManager.State.ROUND_END)
		_phase_time = round_end_delay


func _alive_bot_count() -> int:
	var count := 0
	for character in get_alive_characters():
		if character is BotCharacter:
			count += 1
	return count


func _alive_human_count() -> int:
	var count := 0
	for human in players:
		if not human.is_eliminated:
			count += 1
	return count


func _last_human_alive() -> PlayerCharacter:
	for human in players:
		if not human.is_eliminated:
			return human
	return null


## `winner` solo se usa en 2 jugadores: su etiqueta ("P1"/"P2") se muestra en el mensaje de victoria.
func _finish(player_won: bool, winner: PlayerCharacter = null) -> void:
	phase = Phase.DONE
	bomb.stop()
	effects.clear_all()
	var label := winner.display_name if (winner != null and GameManager.two_players) else ""
	GameManager.end_match(player_won, label)
