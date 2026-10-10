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
var player: PlayerCharacter
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
	player = PlayerCharacter.new()
	player.game_map = map
	add_child(player)
	characters.append(player)
	var bot_total := clampi(GameManager.bot_count, GameManager.MIN_BOTS, spawns.size() - 1)
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
	var camera := Camera2D.new()
	var bounds := map.get_bounds()
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	camera.position_smoothing_enabled = true
	player.add_child(camera)


func _build_hud() -> void:
	hud = Hud.new()
	add_child(hud)
	hud.setup(player, effects, bomb, map, get_alive_characters)


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

	if holder == player:
		_finish(false)
	elif _alive_bot_count() == 0:
		_finish(true)
	else:
		GameManager.set_state(GameManager.State.ROUND_END)
		_phase_time = round_end_delay


func _alive_bot_count() -> int:
	var count := 0
	for character in get_alive_characters():
		if character is BotCharacter:
			count += 1
	return count


func _finish(player_won: bool) -> void:
	phase = Phase.DONE
	bomb.stop()
	effects.clear_all()
	GameManager.end_match(player_won)
