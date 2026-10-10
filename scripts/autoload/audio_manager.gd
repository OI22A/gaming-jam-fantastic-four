extends Node
## Gestión de audio (autoload "AudioManager"). RF-09.
##
## - Escucha los eventos de GameEvents y reproduce el sonido asociado.
## - Si existe un archivo en res://assets/audio/sfx/<nombre>.ogg|.wav lo usa;
##   si no, genera un tono sintético para que el juego tenga retroalimentación
##   sonora desde el primer día (placeholder). Para cambiar un sonido basta con
##   soltar el archivo con el nombre correcto.
##
## Nombres de sonido: countdown, go, bomb_tick, bomb_transfer, bomb_explode,
## lucky_block, effect_on, effect_off, win, lose.

const SFX_DIR := "res://assets/audio/sfx/"
const SAMPLE_RATE := 22050
const POOL_SIZE := 8
const TONES := {
	"countdown": {"freq": 660.0, "duration": 0.12, "volume": 0.5},
	"go": {"freq": 990.0, "duration": 0.30, "volume": 0.6},
	"bomb_tick": {"freq": 1200.0, "duration": 0.04, "volume": 0.35},
	"bomb_transfer": {"freq": 440.0, "duration": 0.14, "volume": 0.6},
	"bomb_explode": {"freq": 80.0, "duration": 0.70, "volume": 0.9, "noise": true},
	"lucky_block": {"freq": 1320.0, "duration": 0.22, "volume": 0.55},
	"effect_on": {"freq": 780.0, "duration": 0.10, "volume": 0.4},
	"effect_off": {"freq": 330.0, "duration": 0.10, "volume": 0.4},
	"win": {"freq": 880.0, "duration": 0.60, "volume": 0.6},
	"lose": {"freq": 160.0, "duration": 0.60, "volume": 0.6},
}

var sfx_volume_db := 0.0

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _last_tick_second := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	for sfx_name in TONES:
		_streams[sfx_name] = _load_or_generate(sfx_name)

	GameEvents.sfx_requested.connect(play)
	GameEvents.countdown_tick.connect(func(_s: int) -> void: play("countdown"))
	GameEvents.round_started.connect(_on_round_started)
	GameEvents.bomb_transferred.connect(func(_a: Node, _b: Node) -> void: play("bomb_transfer"))
	GameEvents.bomb_exploded.connect(func(_h: Node) -> void: play("bomb_explode"))
	GameEvents.lucky_block_collected.connect(
		func(_c: Node, _r: Dictionary) -> void: play("lucky_block")
	)
	GameEvents.effect_applied.connect(
		func(_t: Node, _e: String, _d: float) -> void: play("effect_on")
	)
	GameEvents.effect_expired.connect(func(_t: Node, _e: String) -> void: play("effect_off"))
	GameEvents.match_ended.connect(func(won: bool) -> void: play("win" if won else "lose"))
	GameEvents.bomb_time_changed.connect(_on_bomb_time_changed)


func play(sfx_name: String) -> void:
	var stream: AudioStream = _streams.get(sfx_name)
	if stream == null or _players.is_empty():
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.volume_db = sfx_volume_db
	player.play()


func _on_round_started(_round: int, _holder: Node) -> void:
	_last_tick_second = -1
	play("go")


func _on_bomb_time_changed(time_left: float, _duration: float) -> void:
	# Tic-tac en los últimos 5 segundos (una vez por segundo).
	if time_left > 5.0 or time_left <= 0.0:
		return
	var second := ceili(time_left)
	if second != _last_tick_second:
		_last_tick_second = second
		play("bomb_tick")


func _load_or_generate(sfx_name: String) -> AudioStream:
	for ext in ["ogg", "wav"]:
		var path := "%s%s.%s" % [SFX_DIR, sfx_name, ext]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return _make_tone(TONES[sfx_name])


func _make_tone(def: Dictionary) -> AudioStreamWAV:
	var freq: float = def.freq
	var volume: float = def.volume
	var noisy: bool = def.get("noise", false)
	var count := int(SAMPLE_RATE * float(def.duration))
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t: float = float(i) / SAMPLE_RATE
		var envelope: float = 1.0 - float(i) / count
		var sample: float = sin(TAU * freq * t)
		if noisy:
			sample = randf_range(-1.0, 1.0) * 0.7 + sample * 0.3
		var value := int(clampf(sample * envelope * volume, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav
