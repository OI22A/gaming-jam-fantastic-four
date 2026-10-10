extends GutTest
## RF-07: aplicar y retirar efectos temporales.

var fx: EffectManager
var holder: Character
var rival: Character


func before_each() -> void:
	holder = autofree(Character.new())
	rival = autofree(Character.new())
	add_child(holder)
	add_child(rival)
	fx = autofree(EffectManager.new())
	add_child(fx)


func test_speed_boost_is_applied_and_removed() -> void:
	fx.apply_effect(holder, "boost", EffectManager.TYPE_SPEED, 1.5, 3.0, "Boost")
	assert_almost_eq(holder.get_current_speed(), holder.base_speed * 1.5, 0.001)
	fx.tick(2.0)
	assert_almost_eq(holder.get_speed_multiplier(), 1.5, 0.001, "Sigue activo.")
	fx.tick(1.5)
	assert_almost_eq(holder.get_speed_multiplier(), 1.0, 0.001, "Debe volver a la velocidad base.")


func test_penalty_slows_down() -> void:
	fx.apply_effect(holder, "heavy", EffectManager.TYPE_SPEED, 0.7, 4.0)
	assert_lt(holder.get_current_speed(), holder.base_speed)


func test_effects_stack_multiplicatively_and_same_id_refreshes() -> void:
	fx.apply_effect(holder, "a", EffectManager.TYPE_SPEED, 1.5, 5.0)
	fx.apply_effect(holder, "b", EffectManager.TYPE_SPEED, 2.0, 5.0)
	assert_almost_eq(holder.get_speed_multiplier(), 3.0, 0.001)
	fx.tick(4.0)
	fx.apply_effect(holder, "a", EffectManager.TYPE_SPEED, 1.5, 5.0)  # refresca
	fx.tick(2.0)
	assert_almost_eq(holder.get_speed_multiplier(), 1.5, 0.001, "b expiró, a se refrescó.")


func test_mark_rivals_reward_marks_only_rivals() -> void:
	var reward := RewardTable.pick_by_roll(RewardTable.total_weight() * 0.5)  # radar
	var radar: Dictionary = {}
	for r in RewardTable.REWARDS:
		if r.id == "radar":
			radar = r
	fx.apply_reward(holder, radar, [rival])
	assert_true(rival.is_marked())
	assert_false(holder.is_marked())
	fx.tick(9.0)
	assert_false(rival.is_marked(), "La marca debe retirarse.")
	assert_not_null(reward)


func test_extra_time_requests_bomb_bonus() -> void:
	watch_signals(GameEvents)
	fx.apply_effect(holder, "t", EffectManager.TYPE_EXTRA_TIME, 3.0, 0.0)
	assert_signal_emitted_with_parameters(GameEvents, "bomb_time_bonus_requested", [3.0])


func test_clear_for_removes_effects_of_one_character() -> void:
	fx.apply_effect(holder, "boost", EffectManager.TYPE_SPEED, 1.5, 5.0)
	fx.apply_effect(rival, "boost", EffectManager.TYPE_SPEED, 1.5, 5.0)
	fx.clear_for(holder)
	assert_almost_eq(holder.get_speed_multiplier(), 1.0, 0.001)
	assert_almost_eq(rival.get_speed_multiplier(), 1.5, 0.001)


func test_apply_reward_jackpot_applies_all_effects() -> void:
	watch_signals(GameEvents)
	fx.apply_reward(holder, RewardTable.pick_by_roll(RewardTable.total_weight() - 0.01), [rival])
	assert_gt(holder.get_speed_multiplier(), 1.0)
	assert_true(rival.is_marked())
	assert_signal_emitted(GameEvents, "bomb_time_bonus_requested")
