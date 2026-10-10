class_name RewardTable
extends RefCounted
## Tabla de recompensas de los Lucky Blocks (RF-06).
##
## Cada recompensa tiene rareza, peso (probabilidad relativa) y una lista de
## efectos. Los pesos suman 100, así que `weight` equivale a porcentaje.
##
## Tipos de efecto (ver EffectManager):
##   "speed"        multiplicador de velocidad del recolector (>1 mejora, <1 penaliza)
##   "extra_time"   segundos añadidos (o restados si es negativo) a la bomba
##   "mark_rivals"  marca a todos los rivales (visibles en el minimapa)
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
	Rarity.COMMON: Color(0.8, 0.8, 0.8),
	Rarity.RARE: Color(0.35, 0.65, 1.0),
	Rarity.EPIC: Color(0.75, 0.4, 1.0),
	Rarity.LEGENDARY: Color(1.0, 0.75, 0.2),
}

const REWARDS := [
	{
		"id": "speed_boost",
		"name": "Zapatillas veloces",
		"rarity": Rarity.COMMON,
		"weight": 28,
		"effects": [{"type": "speed", "magnitude": 1.4, "duration": 5.0}],
	},
	{
		"id": "extra_time_small",
		"name": "Mecha lenta (+3 s)",
		"rarity": Rarity.COMMON,
		"weight": 24,
		"effects": [{"type": "extra_time", "magnitude": 3.0, "duration": 0.0}],
	},
	{
		"id": "heavy_boots",
		"name": "Botas pesadas (penalización)",
		"rarity": Rarity.COMMON,
		"weight": 10,
		"effects": [{"type": "speed", "magnitude": 0.7, "duration": 4.0}],
	},
	{
		"id": "short_fuse",
		"name": "Mecha corta (-3 s)",
		"rarity": Rarity.COMMON,
		"weight": 8,
		"effects": [{"type": "extra_time", "magnitude": -3.0, "duration": 0.0}],
	},
	{
		"id": "radar",
		"name": "Radar (marca a los rivales)",
		"rarity": Rarity.RARE,
		"weight": 12,
		"effects": [{"type": "mark_rivals", "magnitude": 0.0, "duration": 8.0}],
	},
	{
		"id": "speed_burst",
		"name": "Ráfaga de velocidad",
		"rarity": Rarity.RARE,
		"weight": 8,
		"effects": [{"type": "speed", "magnitude": 1.6, "duration": 7.0}],
	},
	{
		"id": "super_speed",
		"name": "Súper velocidad",
		"rarity": Rarity.EPIC,
		"weight": 5,
		"effects": [{"type": "speed", "magnitude": 1.9, "duration": 6.0}],
	},
	{
		"id": "extra_time_big",
		"name": "Mecha larga (+6 s)",
		"rarity": Rarity.EPIC,
		"weight": 4,
		"effects": [{"type": "extra_time", "magnitude": 6.0, "duration": 0.0}],
	},
	{
		"id": "jackpot",
		"name": "¡JACKPOT!",
		"rarity": Rarity.LEGENDARY,
		"weight": 1,
		"effects":
		[
			{"type": "speed", "magnitude": 2.0, "duration": 8.0},
			{"type": "extra_time", "magnitude": 8.0, "duration": 0.0},
			{"type": "mark_rivals", "magnitude": 0.0, "duration": 8.0},
		],
	},
]


static func total_weight() -> int:
	var total := 0
	for reward in REWARDS:
		var entry: Dictionary = reward
		total += int(entry.weight)
	return total


## Elige una recompensa al azar respetando los pesos. Devuelve una copia.
static func pick(rng: RandomNumberGenerator = null) -> Dictionary:
	var roll: float
	if rng != null:
		roll = rng.randf() * total_weight()
	else:
		roll = randf() * total_weight()
	return pick_by_roll(roll)


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
