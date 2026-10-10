extends GutTest
## Sprites de 8 direcciones para jugador y bots.


func test_direction_names_cover_eight_directions() -> void:
	assert_eq(CharacterSprite.direction_name(Vector2.RIGHT), "right")
	assert_eq(CharacterSprite.direction_name(Vector2(1, 1)), "right_down")
	assert_eq(CharacterSprite.direction_name(Vector2.DOWN), "down")
	assert_eq(CharacterSprite.direction_name(Vector2(-1, 1)), "left_down")
	assert_eq(CharacterSprite.direction_name(Vector2.LEFT), "left")
	assert_eq(CharacterSprite.direction_name(Vector2(-1, -1)), "left_up")
	assert_eq(CharacterSprite.direction_name(Vector2.UP), "up")
	assert_eq(CharacterSprite.direction_name(Vector2(1, -1)), "right_up")
	assert_eq(CharacterSprite.direction_name(Vector2(1, 0.1)), "right")


func test_sprite_frames_have_run_and_idle_for_each_direction() -> void:
	var frames := CharacterSprite.build_frames()
	for direction in CharacterSprite.DIRECTIONS:
		assert_eq(frames.get_frame_count("run_" + direction), 2, "run_%s" % direction)
		assert_eq(frames.get_frame_count("idle_" + direction), 1, "idle_%s" % direction)
		var texture := frames.get_frame_texture("run_" + direction, 0) as AtlasTexture
		assert_not_null(texture.atlas, "Falta la textura run_%s.png" % direction)
		assert_eq(texture.atlas.get_size(), Vector2(32, 16))


func test_player_and_bots_get_a_tinted_sprite() -> void:
	var player := PlayerCharacter.new()
	var bot := BotCharacter.new()
	bot.body_color = Color(1.0, 0.0, 0.0)
	add_child_autofree(player)
	add_child_autofree(bot)
	for character in [player, bot]:
		var sprite := character.get_node("Sprite") as CharacterSprite
		assert_not_null(sprite)
		var material := sprite.material as ShaderMaterial
		assert_eq(material.get_shader_parameter("shirt_target"), character.body_color)
		assert_eq(sprite.scale, Vector2(2.0, 2.0))


func test_sprite_runs_toward_movement_direction_and_idles_when_still() -> void:
	var character := Character.new()
	add_child_autofree(character)
	var sprite := character.get_node("Sprite") as CharacterSprite
	await get_tree().process_frame
	assert_eq(sprite.animation, &"idle_down")
	character.global_position += Vector2(-6.0, -6.0)
	await get_tree().process_frame
	assert_eq(sprite.animation, &"run_left_up")
	assert_true(sprite.is_playing())
	await get_tree().create_timer(0.3).timeout
	assert_eq(sprite.animation, &"idle_left_up", "Parado conserva la última dirección.")


func test_sprite_animates_regardless_of_bomb() -> void:
	var character := Character.new()
	add_child_autofree(character)
	character.has_bomb = true
	var sprite := character.get_node("Sprite") as CharacterSprite
	await get_tree().process_frame
	character.global_position += Vector2(8.0, 0.0)
	await get_tree().process_frame
	assert_eq(sprite.animation, &"run_right")
