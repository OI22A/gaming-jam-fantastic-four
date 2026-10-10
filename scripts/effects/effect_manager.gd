class_name EffectManager
extends Node
## Aplica y retira efectos temporales (RF-07): mejoras de velocidad,
## rastreo de jugadores y tiempo adicional de la bomba.
##
## - Un mismo efecto (mismo id) sobre el mismo personaje se refresca, no se acumula.
## - Efectos distintos se combinan (los multiplicadores de velocidad se multiplican).
## - "extra_time" es instantáneo: pide a BombManager añadir/restar segundos.

const TYPE_SPEED := "speed"
const TYPE_MARK := "mark"
const TYPE_MARK_RIVALS := "mark_rivals"
const TYPE_EXTRA_TIME := "extra_time"
const TYPE_TRANSFER_RANDOM := "transfer_random"
const TYPE_TRACKING := "tracking"

var _active: Array[Dictionary] = []


func _ready() -> void:
	GameEvents.bomb_transferred.connect(_on_bomb_transferred)


func _on_bomb_transferred(from_holder: Node, _to_holder: Node) -> void:
	var previous := from_holder as Character
	if previous != null:
		clear_for(previous, GameEvents.MotivoRetiro.TRANSFERENCIA)


func _physics_process(delta: float) -> void:
	if GameManager.is_playing():
		tick(delta)


## Aplica todos los efectos de una recompensa del RewardTable.
func apply_reward(collector: Character, reward: Dictionary, rivals: Array) -> void:
	var label: String = reward.get("name", "Efecto")
	for effect in reward.get("effects", []):
		var data: Dictionary = effect
		var type: String = data.type
		var effect_id := "%s:%s" % [reward.get("id", "reward"), type]
		if type == TYPE_MARK_RIVALS:
			apply_effect(
				collector,
				"%s:tracking" % reward.get("id", "reward"),
				TYPE_TRACKING,
				0.0,
				float(data.duration),
				"Rastreo"
			)
			for rival in rivals:
				apply_effect(
					rival, effect_id, TYPE_MARK, 0.0, float(data.duration), "Marcado", collector
				)
		else:
			apply_effect(
				collector, effect_id, type, float(data.magnitude), float(data.duration), label
			)


func apply_effect(
	target: Character,
	effect_id: String,
	type: String,
	magnitude: float,
	duration: float,
	label: String = "",
	owner: Character = null
) -> void:
	if target == null or target.is_eliminated:
		return
	if type == TYPE_EXTRA_TIME:
		GameEvents.bomb_time_bonus_requested.emit(magnitude)
		GameEvents.effect_applied.emit(target, effect_id, 0.0)
		return
	if type == TYPE_TRANSFER_RANDOM:
		GameEvents.bomb_transfer_random_requested.emit()
		GameEvents.effect_applied.emit(target, effect_id, 0.0)
		return

	var index := _find(target, effect_id)
	if index >= 0:
		_active[index].remaining = duration
		return

	(
		_active
		. append(
			{
				"target": target,
				"owner": owner if owner != null else target,
				"id": effect_id,
				"type": type,
				"magnitude": magnitude,
				"remaining": duration,
				"duration": duration,
				"label": label,
			}
		)
	)
	match type:
		TYPE_SPEED:
			target.speed_modifiers[effect_id] = magnitude
		TYPE_MARK:
			target.marks[effect_id] = true
	GameEvents.effect_applied.emit(target, effect_id, duration)


func tick(delta: float) -> void:
	for i in range(_active.size() - 1, -1, -1):
		var effect := _active[i]
		var target := effect.target as Character
		effect.remaining -= delta
		var target_gone := (
			target == null or not is_instance_valid(target) or target.is_eliminated
		)
		if target_gone:
			_expire(i, GameEvents.MotivoRetiro.ELIMINACION)
		elif effect.remaining <= 0.0:
			_expire(i, GameEvents.MotivoRetiro.EXPIRACION)


func clear_all() -> void:
	for i in range(_active.size() - 1, -1, -1):
		_expire(i, GameEvents.MotivoRetiro.FIN_PARTIDA)


func clear_for(target: Character, reason: int = GameEvents.MotivoRetiro.ELIMINACION) -> void:
	for i in range(_active.size() - 1, -1, -1):
		if _active[i].target == target or _active[i].owner == target:
			_expire(i, reason)


## Efectos activos de un personaje: [{id, type, label, remaining, duration, magnitude}].
func get_active_for(target: Character) -> Array:
	var result: Array = []
	for effect in _active:
		if effect.target == target:
			result.append(effect)
	return result


func has_tracking(target: Character) -> bool:
	for effect in _active:
		if effect.target == target and effect.type == TYPE_TRACKING:
			return true
	return false


func _find(target: Character, effect_id: String) -> int:
	for i in _active.size():
		if _active[i].target == target and _active[i].id == effect_id:
			return i
	return -1


func _expire(index: int, reason: int) -> void:
	var effect := _active[index]
	_active.remove_at(index)
	var target := effect.target as Character
	if target != null and is_instance_valid(target):
		target.speed_modifiers.erase(effect.id)
		target.marks.erase(effect.id)
		GameEvents.effect_expired.emit(target, effect.id, reason)