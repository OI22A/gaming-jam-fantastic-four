class_name BotCharacter
extends Character
## Bot controlado por IA (RF-04).
##
## Comportamiento (se decide cada `decision_interval` segundos):
## - Con la bomba: persigue al rival más cercano; a veces se desvía a un Lucky Block.
## - Sin la bomba: huye de quien la tiene si está a la vista; si no, deambula.
## - Evita obstáculos con rayos de detección (capa 1) y rodeándolos.
## - Cerca de los bordes, al huir, se empuja hacia el centro para no quedar arrinconado.
##
## Para ajustar la dificultad: `base_speed`, `decision_interval`, `sight_range`
## y `block_seek_chance`.

enum Mode { WANDER, CHASE, FLEE, SEEK_BLOCK }

const AVOID_ANGLES := [0.0, 0.6, -0.6, 1.2, -1.2, 1.9, -1.9]

@export var sight_range := 700.0
@export var decision_interval := 0.25
@export var ray_length := 60.0
@export_range(0.0, 1.0) var block_seek_chance := 0.3

var arena_bounds := Rect2(0.0, 0.0, 1920.0, 1080.0)
var mode: Mode = Mode.WANDER

var _goal := Vector2.ZERO
var _goal_block: LuckyBlock = null
var _desired := Vector2.ZERO
var _timer := 0.0
var _last_position := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	display_name = "Bot"
	base_speed = 205.0
	body_color = Color(1.0, 0.45, 0.35)


func _ready() -> void:
	super._ready()
	_rng.randomize()
	_timer = _rng.randf_range(0.0, decision_interval)
	_last_position = global_position


func get_input_direction() -> Vector2:
	_timer -= get_physics_process_delta_time()
	if _timer <= 0.0:
		_timer = decision_interval * _rng.randf_range(0.8, 1.4)
		_decide()
	return _steer(_desired)


func _decide() -> void:
	var stuck := global_position.distance_to(_last_position) < 3.0
	_last_position = global_position
	var others := _get_others()

	if has_bomb:
		if mode == Mode.SEEK_BLOCK and is_instance_valid(_goal_block) and _goal_block.is_active:
			_desired = _direction_to(_goal_block.global_position)
			return
		_goal_block = _pick_block()
		if _goal_block != null:
			mode = Mode.SEEK_BLOCK
			_desired = _direction_to(_goal_block.global_position)
			return
		var prey := _nearest(others)
		if prey != null:
			mode = Mode.CHASE
			_desired = _direction_to(prey.global_position)
			return
	else:
		var holder := _find_holder(others)
		if holder != null and global_position.distance_to(holder.global_position) < sight_range:
			mode = Mode.FLEE
			var away := (global_position - holder.global_position).normalized()
			var steer := away + _edge_push() * 1.2
			_desired = steer.normalized() if steer.length() > 0.01 else away
			return

	mode = Mode.WANDER
	if _goal == Vector2.ZERO or global_position.distance_to(_goal) < 50.0 or stuck:
		_goal = Vector2(
			_rng.randf_range(arena_bounds.position.x + 100.0, arena_bounds.end.x - 100.0),
			_rng.randf_range(arena_bounds.position.y + 100.0, arena_bounds.end.y - 100.0)
		)
	_desired = _direction_to(_goal)


func _get_others() -> Array[Character]:
	var result: Array[Character] = []
	for node in get_tree().get_nodes_in_group("characters"):
		var other := node as Character
		if other != null and other != self and not other.is_eliminated:
			result.append(other)
	return result


func _find_holder(others: Array[Character]) -> Character:
	for other in others:
		if other.has_bomb:
			return other
	return null


func _nearest(others: Array[Character]) -> Character:
	var best: Character = null
	var best_distance := INF
	for other in others:
		var distance := global_position.distance_to(other.global_position)
		if distance < best_distance:
			best_distance = distance
			best = other
	return best


func _pick_block() -> LuckyBlock:
	if _rng.randf() > block_seek_chance:
		return null
	var best: LuckyBlock = null
	var best_distance := 450.0
	for node in get_tree().get_nodes_in_group("lucky_blocks"):
		var block := node as LuckyBlock
		if block == null or not block.is_active:
			continue
		var distance := global_position.distance_to(block.global_position)
		if distance < best_distance:
			best_distance = distance
			best = block
	return best


func _direction_to(point: Vector2) -> Vector2:
	return (point - global_position).normalized()


func _edge_push() -> Vector2:
	var margin := 140.0
	var push := Vector2.ZERO
	if global_position.x < arena_bounds.position.x + margin:
		push.x += 1.0
	if global_position.x > arena_bounds.end.x - margin:
		push.x -= 1.0
	if global_position.y < arena_bounds.position.y + margin:
		push.y += 1.0
	if global_position.y > arena_bounds.end.y - margin:
		push.y -= 1.0
	return push


## Devuelve la dirección libre más cercana a `direction` (evita obstáculos).
func _steer(direction: Vector2) -> Vector2:
	if direction == Vector2.ZERO:
		return Vector2.ZERO
	for angle in AVOID_ANGLES:
		var candidate := direction.rotated(angle)
		if not _is_blocked(candidate):
			return candidate
	return direction.rotated(PI * 0.5)


func _is_blocked(direction: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position, global_position + direction * ray_length, 1
	)
	return not space.intersect_ray(query).is_empty()
