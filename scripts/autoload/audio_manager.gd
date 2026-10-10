extends Node
## Gestión de audio (autoload "AudioManager"). RF-09.
##
## - Escucha los eventos de GameEvents y reproduce el sonido asociado.
## - Si existe un archivo en res://assets/audio/sfx/<nombre>.ogg|.wav|.mp3 lo usa;
##   si no, genera un tono sintético para que el juego tenga retroalimentación
##   sonora desde el primer día (placeholder). Para cambiar un sonido basta con
##   soltar el archivo con el nombre correcto.
## - Música de fondo: res://assets/audio/music/music_menu y music_game (.ogg|.mp3).
##   Si falta, suena la música procedural de respaldo.
## - bomb_fuse se sincroniza con el tiempo restante de la bomba para terminar
##   con la explosión.
##
## Nombres de sonido: countdown, go, bomb_tick, bomb_fuse, bomb_transfer,
## bomb_explode, lucky_block, lucky_block_rare, lucky_block_legendary,
## effect_on, effect_off, win, lose.

const SFX_DIR := "res://assets/audio/sfx/"
const SAMPLE_RATE := 22050
const POOL_SIZE := 8
const MUSIC_SECONDS := 8
const MUSIC_DIR := "res://assets/audio/music/"
const TONES := {
	"countdown": {"freq": 660.0, "duration": 0.12, "volume": 0.5},
	"go": {"freq": 990.0, "duration": 0.30, "volume": 0.6},
	"bomb_tick": {"freq": 1200.0, "duration": 0.04, "volume": 0.35},
	"bomb_fuse": {"freq": 300.0, "duration": 0.3, "volume": 0.5},
	"bomb_transfer": {"freq": 440.0, "duration": 0.14, "volume": 0.6},
	"bomb_explode": {"freq": 80.0, "duration": 0.70, "volume": 0.9, "noise": true},
	"lucky_block": {"freq": 1320.0, "duration": 0.22, "volume": 0.55},
	"lucky_block_rare": {"freq": 1600.0, "duration": 0.26, "volume": 0.58},
	"lucky_block_legendary": {"freq": 2100.0, "duration": 0.4, "volume": 0.65},
	"effect_on": {"freq": 780.0, "duration": 0.10, "volume": 0.4},
	"effect_off": {"freq": 330.0, "duration": 0.10, "volume": 0.4},
	"win": {"freq": 880.0, "duration": 0.60, "volume": 0.6},
	"lose": {"freq": 160.0, "duration": 0.60, "volume": 0.6},
}

var sfx_volume_db := 0.0

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _fallback_music: AudioStream
var _music_streams: Dictionary = {}
var _current_music := ""
var _next_player := 0
var _last_tick_second := -1
var _fuse_played := false
var _fuse_player: AudioStreamPlayer
var _audio_unlocked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "Music"
	_fallback_music = _make_music()
	_music_streams["music_menu"] = _load_music("music_menu")
	_music_streams["music_game"] = _load_music("music_game")
	_music_player.volume_db = -15.0
	add_child(_music_player)
	for sfx_name in TONES:
		_streams[sfx_name] = _load_or_generate(sfx_name)
	_fuse_player = AudioStreamPlayer.new()
	_fuse_player.name = "Fuse"
	add_child(_fuse_player)

	GameEvents.sfx_requested.connect(play)
	GameEvents.countdown_tick.connect(func(_s: int) -> void: play("countdown"))
	GameEvents.round_started.connect(_on_round_started)
	GameEvents.bomb_transferred.connect(func(_a: Node, _b: Node) -> void: play("bomb_transfer"))
	GameEvents.bomb_exploded.connect(func(_h: Node) -> void: play("bomb_explode"))
	GameEvents.lucky_block_collected.connect(
		_on_lucky_block_collected
	)
	GameEvents.effect_applied.connect(
		func(_t: Node, _e: String, _d: float) -> void: play("effect_on")
	)
	GameEvents.effect_expired.connect(_on_effect_expired)
	GameEvents.match_ended.connect(func(won: bool) -> void: play("win" if won else "lose"))
	GameEvents.bomb_time_changed.connect(_on_bomb_time_changed)
	GameEvents.state_changed.connect(_on_state_changed)


func play(sfx_name: String) -> void:
	var stream: AudioStream = _streams.get(sfx_name)
	if not _audio_unlocked or stream == null or _players.is_empty():
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.volume_db = sfx_volume_db
	player.play()


func _input(event: InputEvent) -> void:
	if _audio_unlocked:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_unlock_audio()
	elif event is InputEventMouseButton and event.pressed:
		_unlock_audio()


func _unlock_audio() -> void:
	_audio_unlocked = true
	if GameManager.state == GameManager.State.MENU:
		_play_music("music_menu")
	else:
		_play_music("music_game")


func set_master_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(value, 0.0, 1.0)))


func _load_music(music_name: String) -> AudioStream:
	for ext in ["ogg", "mp3"]:
		var path := "%s%s.%s" % [MUSIC_DIR, music_name, ext]
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
				stream.loop = true
			return stream
	return null


func _play_music(music_name: String) -> void:
	if not _audio_unlocked or music_name == _current_music:
		return
	_current_music = music_name
	var stream: AudioStream = _music_streams.get(music_name)
	_music_player.stream = stream if stream != null else _fallback_music
	_music_player.play()


func _on_state_changed(new_state: int, _old_state: int) -> void:
	_fuse_player.stream_paused = new_state == GameManager.State.PAUSED
	if new_state == GameManager.State.MENU or new_state == GameManager.State.COUNTDOWN:
		_stop_fuse()
	if new_state == GameManager.State.MENU:
		_play_music("music_menu")
	elif (
		new_state == GameManager.State.COUNTDOWN
		or new_state == GameManager.State.PLAYING
		or new_state == GameManager.State.ROUND_END
	):
		_play_music("music_game")


func _on_lucky_block_collected(_collector: Node, reward: Dictionary) -> void:
	var sfx := "lucky_block"
	match int(reward.get("rarity", 0)):
		RewardTable.Rarity.COMMON:
			sfx = "lucky_block"
		RewardTable.Rarity.RARE:
			sfx = "lucky_block_rare"
		RewardTable.Rarity.LEGENDARY:
			sfx = "lucky_block_legendary"
	play(sfx)


func _on_effect_expired(_target: Node, effect_id: String, reason: int) -> void:
	# Las marcas sobre rivales no deben sonar (una por rival).
	if effect_id.ends_with(":mark_rivals"):
		return
	if (
		reason == GameEvents.MotivoRetiro.EXPIRACION
		or reason == GameEvents.MotivoRetiro.TRANSFERENCIA
	):
		play("effect_off")


func _on_round_started(_round: int, _holder: Node) -> void:
	_last_tick_second = -1
	_stop_fuse()
	play("go")


func _on_bomb_time_changed(time_left: float, _duration: float) -> void:
	_update_fuse(time_left)
	# Tic-tac en los últimos 10 segundos (una vez por segundo).
	if time_left > 10.0 or time_left <= 0.0:
		return
	var second := ceili(time_left)
	if second != _last_tick_second:
		_last_tick_second = second
		play("bomb_tick")


func _update_fuse(time_left: float) -> void:
	var stream: AudioStream = _streams.get("bomb_fuse")
	if not _audio_unlocked or stream == null:
		return
	var length := stream.get_length()
	if time_left <= 0.0 or time_left > length:
		_stop_fuse()
		return
	var target_pos := length - time_left
	if not _fuse_player.playing:
		if _fuse_played:
			return
		_fuse_played = true
		_fuse_player.stream = stream
		_fuse_player.volume_db = sfx_volume_db
		_fuse_player.play(target_pos)
	elif absf(_fuse_player.get_playback_position() - target_pos) > 0.4:
		_fuse_player.seek(target_pos)


func _stop_fuse() -> void:
	_fuse_played = false
	if _fuse_player != null:
		_fuse_player.stop()


func _load_or_generate(sfx_name: String) -> AudioStream:
	for ext in ["ogg", "wav", "mp3"]:
		var path := "%s%s.%s" % [SFX_DIR, sfx_name, ext]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	if not TONES.has(sfx_name):
		return null
	return _make_tone(TONES[sfx_name])


func _make_music() -> AudioStreamWAV:
	var count := SAMPLE_RATE * MUSIC_SECONDS
	var data := PackedByteArray()
	data.resize(count * 2)
	var notes: Array[float] = [110.0, 138.59, 164.81, 138.59]
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var note: float = notes[int(t / 2.0) % notes.size()]
		var wave := sin(TAU * note * t) * 0.14 + sin(TAU * note * 1.5 * t) * 0.04
		var value := int(clampf(wave, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream


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