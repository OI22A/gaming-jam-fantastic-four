extends GutTest
## RF-05: temporizador, transferencia y explosión de la bomba.

var bomb: BombManager
var a: Character
var b: Character


func before_each() -> void:
	a = autofree(Character.new())
	b = autofree(Character.new())
	add_child(a)
	add_child(b)
	a.global_position = Vector2(0, 0)
	b.global_position = Vector2(500, 0)
	bomb = autofree(BombManager.new())
	bomb.duration = 10.0
	add_child(bomb)
	var list: Array[Character] = [a, b]
	bomb.setup(list)


func test_start_round_gives_bomb_and_time() -> void:
	bomb.start_round(a)
	assert_true(a.has_bomb)
	assert_eq(bomb.holder, a)
	assert_eq(bomb.time_left, 10.0)


func test_timer_counts_down() -> void:
	bomb.start_round(a)
	bomb.tick(2.5)
	assert_almost_eq(bomb.time_left, 7.5, 0.001)


func test_explodes_at_zero() -> void:
	watch_signals(GameEvents)
	bomb.start_round(a)
	bomb.tick(11.0)
	assert_signal_emitted(GameEvents, "bomb_exploded")
	assert_false(bomb.running)


func test_transfer_on_touch_after_cooldown() -> void:
	watch_signals(GameEvents)
	bomb.start_round(a)
	b.global_position = Vector2(20, 0)
	bomb.tick(0.5)  # aún en enfriamiento
	assert_eq(bomb.holder, a, "No transfiere durante el enfriamiento.")
	bomb.tick(0.6)  # enfriamiento cumplido (1.0 s)
	assert_eq(bomb.holder, b)
	assert_true(b.has_bomb)
	assert_false(a.has_bomb)
	assert_signal_emitted(GameEvents, "bomb_transferred")


func test_no_transfer_when_far() -> void:
	bomb.start_round(a)
	bomb.tick(2.0)
	assert_eq(bomb.holder, a)


func test_eliminated_characters_are_ignored() -> void:
	bomb.start_round(a)
	b.global_position = Vector2(10, 0)
	b.is_eliminated = true
	bomb.tick(2.0)
	assert_eq(bomb.holder, a)


func test_time_bonus_adds_and_subtracts() -> void:
	bomb.start_round(a)
	bomb.add_time(3.0)
	assert_almost_eq(bomb.time_left, 13.0, 0.001)
	bomb.add_time(-20.0)
	assert_eq(bomb.time_left, 0.0, "Nunca baja de cero.")
