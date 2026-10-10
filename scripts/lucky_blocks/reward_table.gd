class_name RewardTable
extends RefCounted
## Tabla de recompensas de los Lucky Blocks (RF-06).
##
## Cada recompensa tiene rareza, peso (probabilidad relativa) y una lista de
## efectos. Los pesos suman 100, así que `weight` equivale a porcentaje.
##
## Tipos de efecto (ver EffectManager): solo hay recompensas positivas.
## Los pesos de rareza suman exactamente 100.
##
## Para balancear el juego basta con editar esta tabla.

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

const RARITY_NAMES := {
	Rarity.COMMON: "Común",
	Rarity.RARE: "Rara",
	Rarity.EPIC: "Épica",
	Rarity.LEGENDARY: "Legendaria",
}
const RARITY_COLORS := {
	Rarity.COMMON: Color(0.78, 0.42, 0.18),
	Rarity.RARE: Color(0.78, 0.82, 0.88),
	Rarity.EPIC: Color(0.75, 0.4, 1.0),
	Rarity.LEGENDARY: Color(1.0, 0.78, 0.18),
}

const REWARDS := [
	{
		"id": "speed_boost",
		"name": "Velocidad +25 %",
		"rarity": Rarity.COMMON,
		"weight": 74.0 / 3.0,
		"effects": [{"type": "speed", "magnitude": 1.25, "duration": 10.0}],
	},
	{
		"id": "radar",
		"name": "Radar",
		"rarity": Rarity.COMMON,
		"weight": 74.0 / 3.0,
		"effects": [{"type": "mark_rivals", "magnitude": 0.0, "duration": 10.0}],
	},
	{
		"id": "extra_time",
		"name": "Tiempo extra +30 s",
		"rarity": Rarity.COMMON,
		"weight": 74.0 / 3.0,
		"effects": [{"type": "extra_time", "magnitude": 30.0, "duration": 0.0}],
	},
	{
		"id": "silver_speed",
		"name": "Velocidad +50 %",
		"rarity": Rarity.RARE,
		"weight": 25,
		"effects": [{"type": "speed", "magnitude": 1.5, "duration": 10.0}],
	},
	{
		"id": "golden_transfer",
		"name": "Transferencia dorada",
		"rarity": Rarity.LEGENDARY,
		"weight": 1,
		"effects": [{"type": "transfer_random", "magnitude": 0.0, "duration": 0.0}],
	},
]


static func total_weight() -> float:
	var total := 0.0
	for reward in REWARDS:
		var entry: Dictionary = reward
		total += float(entry.weight)
	return total


## Elige una recompensa al azar respetando los pesos. Devuelve una copia.
static func pick(rng: RandomNumberGenerator = null) -> Dictionary:
	var roll: float
	if rng != null:
		roll = rng.randf() * total_weight()
	else:
		roll = randf() * total_weight()
	return pick_by_roll(roll)


static func pick_rarity(rng: RandomNumberGenerator = null) -> int:
	return int(pick(rng).rarity)


static func pick_for_rarity(rarity: int, rng: RandomNumberGenerator = null) -> Dictionary:
	var options: Array[Dictionary] = []
	for reward in REWARDS:
		var entry: Dictionary = reward
		if int(entry.rarity) == rarity:
			options.append(entry)
	if options.is_empty():
		return {}
	var index := (
		rng.randi_range(0, options.size() - 1)
		if rng != null
		else randi_range(0, options.size() - 1)
	)
	return options[index].duplicate(true)


## Versión determinista: `roll` en [0, total_weight()). Pensada para pruebas.
static func pick_by_roll(roll: float) -> Dictionary:
	var accumulated := 0.0
	for reward in REWARDS:
		var entry: Dictionary = reward
		accumulated += float(entry.weight)
		if roll < accumulated:
			return entry.duplicate(true)
	var last: Dictionary = REWARDS[REWARDS.size() - 1]
	return last.duplicate(true)


## Probabilidad (%) de cada rareza. Útil para documentar y verificar el balance.
static func rarity_distribution() -> Dictionary:
	var result := {}
	var total := float(total_weight())
	for reward in REWARDS:
		var entry: Dictionary = reward
		var rarity: int = entry.rarity
		result[rarity] = float(result.get(rarity, 0.0)) + float(entry.weight) / total * 100.0
	return result


static func rarity_name(rarity: int) -> String:
	return RARITY_NAMES.get(rarity, "?")


static func rarity_color(rarity: int) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)
