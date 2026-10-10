class_name LuckyBlockSpawner
extends Node2D
## Coloca los Lucky Blocks del mapa, sortea la recompensa al recogerlos y
## reaparece el bloque tras `respawn_delay` segundos (RF-06).

@export var respawn_delay := 15.0
@export var max_active_blocks := 4

var blocks: Array[LuckyBlock] = []

var _effects: EffectManager
var _characters_provider: Callable
var _rng := RandomNumberGenerator.new()


## `characters_provider` es un Callable que devuelve los personajes vivos.
func setup(points: Array[Vector2], effects: EffectManager, characters_provider: Callable) -> void:
	_rng.randomize()
	_effects = effects
	_characters_provider = characters_provider
	for point in points.slice(0, max_active_blocks):
		var block := LuckyBlock.new()
		block.position = point
		block.rarity = RewardTable.pick_rarity(_rng)
		add_child(block)
		block.collected.connect(_on_block_collected)
		blocks.append(block)


func _on_block_collected(block: LuckyBlock, collector: Character) -> void:
	var reward := RewardTable.pick_for_rarity(block.rarity, _rng)
	var rivals: Array = []
	if _characters_provider.is_valid():
		for character in _characters_provider.call():
			if character != collector:
				rivals.append(character)
	_effects.apply_reward(collector, reward, rivals)
	GameEvents.lucky_block_collected.emit(collector, reward)
	# `false` = el temporizador respeta la pausa del juego.
	get_tree().create_timer(respawn_delay, false).timeout.connect(_respawn.bind(block))


func _respawn(block: LuckyBlock) -> void:
	block.rarity = RewardTable.pick_rarity(_rng)
	block.activate()
