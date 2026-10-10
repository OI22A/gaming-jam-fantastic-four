extends GutTest
## RF-06: Lucky Blocks con distintas rarezas y probabilidades.


func test_weights_sum_to_100() -> void:
	assert_eq(RewardTable.total_weight(), 100, "Los pesos deben sumar 100 (= porcentajes).")


func test_roll_zero_returns_first_reward() -> void:
	assert_eq(RewardTable.pick_by_roll(0.0).id, "speed_boost")


func test_roll_max_returns_legendary() -> void:
	var reward := RewardTable.pick_by_roll(RewardTable.total_weight() - 0.01)
	assert_eq(reward.rarity, RewardTable.Rarity.LEGENDARY)


func test_rarity_distribution_matches_design() -> void:
	var dist := RewardTable.rarity_distribution()
	assert_almost_eq(float(dist[RewardTable.Rarity.COMMON]), 74.0, 0.01)
	assert_almost_eq(float(dist[RewardTable.Rarity.RARE]), 25.0, 0.01)
	assert_almost_eq(float(dist.get(RewardTable.Rarity.EPIC, 0.0)), 0.0, 0.01)
	assert_almost_eq(float(dist[RewardTable.Rarity.LEGENDARY]), 1.0, 0.01)


func test_rewards_do_not_apply_penalties() -> void:
	for reward in RewardTable.REWARDS:
		for effect in reward.effects:
			assert_gte(float(effect.get("magnitude", 0.0)), 0.0)
			if effect.type == "speed":
				assert_gte(float(effect.magnitude), 1.0)


func test_every_reward_is_well_formed() -> void:
	for reward in RewardTable.REWARDS:
		var entry: Dictionary = reward
		assert_true(
			entry.has_all(["id", "name", "rarity", "weight", "effects"]),
			"Campos de %s" % entry.get("id")
		)
		assert_gt(entry.effects.size(), 0)


func test_pick_returns_independent_copy() -> void:
	var a := RewardTable.pick_by_roll(0.0)
	a.name = "modificada"
	assert_ne(RewardTable.pick_by_roll(0.0).name, "modificada")
