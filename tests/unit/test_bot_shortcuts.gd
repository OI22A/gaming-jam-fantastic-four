extends GutTest
## Los bots no deben amontonarse ni rebotar entre atajos: solo huyen por uno cuando
## está libre, cerca y claramente más cerca de ellos que del portador.

var map: TiledMap


func before_each() -> void:
	map = (load(GameManager.MAPS["tiled"].scene) as PackedScene).instantiate() as TiledMap
	add_child_autofree(map)


func _bot() -> BotCharacter:
	var bot := BotCharacter.new()
	add_child_autofree(bot)
	return bot


func test_busy_shortcut_is_skipped() -> void:
	var from := Vector2(176.0, 700.0)
	var threat := Vector2(176.0, 300.0)
	assert_eq(map.escape_shortcut_entry(from, threat), map.shortcuts[0].entry)
	map._shortcut_busy[0] = true
	assert_eq(map.escape_shortcut_entry(from, threat), Vector2.ZERO, "Ocupado: huir a pie.")


func test_far_shortcuts_are_ignored() -> void:
	var far_point := Vector2(1300.0, 300.0)
	assert_eq(map.escape_shortcut_entry(far_point, Vector2(1300.0, 100.0)), Vector2.ZERO)


func test_shortcut_must_be_clearly_closer_than_the_holder() -> void:
	var from := Vector2(176.0, 700.0)
	var close_threat := Vector2(176.0, 720.0)  # el portador está más cerca de la entrada que el bot
	assert_eq(map.escape_shortcut_entry(from, close_threat), Vector2.ZERO)


func test_only_one_bot_claims_the_same_entry() -> void:
	var first := _bot()
	var second := _bot()
	var from := Vector2(176.0, 700.0)
	var threat := Vector2(176.0, 300.0)
	assert_eq(map.escape_shortcut_entry(from, threat, first), map.shortcuts[0].entry)
	assert_eq(map.escape_shortcut_entry(from, threat, second), Vector2.ZERO, "Ya reservada.")
	assert_eq(map.escape_shortcut_entry(from, threat, first), map.shortcuts[0].entry, "El dueño la conserva.")


func test_claim_expires() -> void:
	var first := _bot()
	var second := _bot()
	var from := Vector2(176.0, 700.0)
	var threat := Vector2(176.0, 300.0)
	map.escape_shortcut_entry(from, threat, first)
	map._shortcut_claims[0].until = Time.get_ticks_msec() - 1
	assert_eq(map.escape_shortcut_entry(from, threat, second), map.shortcuts[0].entry)


func test_bot_cooldown_blocks_automatic_use() -> void:
	var bot := _bot()
	assert_false(bot.can_auto_use_shortcut(), "Solo usa atajos mientras huye.")
	bot.mode = BotCharacter.Mode.FLEE
	assert_true(bot.can_auto_use_shortcut())
	bot.mark_shortcut_used()
	assert_false(bot.can_auto_use_shortcut(), "Enfriamiento tras usar un atajo.")


func test_player_never_uses_shortcuts_automatically() -> void:
	var player := PlayerCharacter.new()
	add_child_autofree(player)
	assert_false(player.can_auto_use_shortcut())
