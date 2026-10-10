class_name BombManager
extends Node
## Gestión de la bomba (RF-05): temporizador, transferencias y explosión.
##
## - Quien tiene la bomba la transfiere tocando a otro personaje vivo.
## - Tras una transferencia hay un enfriamiento (`transfer_cooldown`) para evitar
##   rebotes instantáneos.
## - Cuando el tiempo llega a 0 emite `GameEvents.bomb_exploded(holder)`;
##   MatchController decide las consecuencias (eliminación).
## - Los efectos de "tiempo adicional" llegan por `bomb_time_bonus_requested`.

@export var duration := 60.0
@export var transfer_cooldown := 1.5
@export var touch_distance := 40.0

var holder: Character = null
var time_left := 0.0
var running := false

var _characters: Array[Character] = []
var _cooldown := 0.0


func _ready() -> void:
	add_to_group("bomb_manager")
	GameEvents.bomb_time_bonus_requested.connect(add_time)
	GameEvents.bomb_transfer_random_requested.connect(transfer_to_random)


## `characters` se guarda por referencia; los eliminados se ignoran.
func setup(characters: Array[Character]) -> void:
	_characters = characters


func start_round(first_holder: Character, round_duration: float = -1.0) -> void:
	if holder != null:
		holder.has_bomb = false
	if round_duration > 0.0:
		duration = round_duration
	holder = first_holder
	holder.has_bomb = true
	time_left = duration
	_cooldown = transfer_cooldown
	running = true
	GameEvents.bomb_time_changed.emit(time_left, duration)


func stop() -> void:
	running = false


func is_transfer_cooling_down() -> bool:
	return _cooldown > 0.0


func add_time(seconds: float) -> void:
	if not running:
		return
	time_left = maxf(0.0, time_left + seconds)
	GameEvents.bomb_time_changed.emit(time_left, duration)


func transfer_to_random() -> void:
	var candidates: Array[Character] = []
	for character in _characters:
		if character != holder and not character.is_eliminated and not character.is_using_shortcut:
			candidates.append(character)
	if candidates.is_empty():
		return
	transfer_to(candidates[randi_range(0, candidates.size() - 1)])


func transfer_to(new_holder: Character) -> void:
	if (
		new_holder == null
		or new_holder == holder
		or new_holder.is_eliminated
		or new_holder.is_using_shortcut
	):
		return
	var previous := holder
	if previous != null:
		previous.has_bomb = false
	holder = new_holder
	holder.has_bomb = true
	_cooldown = transfer_cooldown
	GameEvents.bomb_transferred.emit(previous, holder)


func _physics_process(delta: float) -> void:
	if GameManager.is_playing():
		tick(delta)


## Avanza el temporizador. Público para poder probarlo sin depender del motor.
func tick(delta: float) -> void:
	if not running or holder == null:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	time_left = maxf(0.0, time_left - delta)
	GameEvents.bomb_time_changed.emit(time_left, duration)

	if _cooldown <= 0.0 and time_left > 0.0:
		var touched := _find_touched_character()
		if touched != null:
			transfer_to(touched)

	if time_left <= 0.0:
		running = false
		GameEvents.bomb_exploded.emit(holder)


func _find_touched_character() -> Character:
	var best: Character = null
	var best_distance := touch_distance
	for candidate in _characters:
		if candidate == holder or candidate.is_eliminated or candidate.is_using_shortcut:
			continue
		var distance := holder.global_position.distance_to(candidate.global_position)
		if distance <= best_distance:
			best_distance = distance
			best = candidate
	return best
