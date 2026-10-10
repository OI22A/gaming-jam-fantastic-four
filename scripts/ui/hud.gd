class_name Hud
extends CanvasLayer
## Interfaz de la partida (RF-09): temporizador de la bomba, ronda, quién la
## tiene, efectos activos del jugador, avisos, minimapa (RF-08), pausa y
## pantalla de resultados con botones de reinicio / menú.
##
## Se construye por código para que no dependa de escenas .tscn.

var _player: Character
var _effects: EffectManager
var _bomb: BombManager
var _characters_provider: Callable

var _timer_label: Label
var _round_label: Label
var _holder_label: Label
var _effects_label: Label
var _center_label: Label
var _toast_label: Label
var _result_box: CenterContainer
var _result_title: Label
var _result_detail: Label
var _minimap: Minimap

var _center_ttl := 0.0
var _toast_ttl := 0.0
var _countdown_text := ""


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(
	player: Character,
	effects: EffectManager,
	bomb: BombManager,
	game_map: GameMap,
	characters_provider: Callable
) -> void:
	_player = player
	_effects = effects
	_bomb = bomb
	_characters_provider = characters_provider
	_build_ui()
	_minimap.setup(game_map, characters_provider)
	_minimap.visible = false
	_minimap.z_index = 100

	GameEvents.state_changed.connect(_on_state_changed)
	GameEvents.countdown_tick.connect(_on_countdown_tick)
	GameEvents.round_started.connect(_on_round_started)
	GameEvents.bomb_exploded.connect(_on_bomb_exploded)
	GameEvents.lucky_block_collected.connect(_on_lucky_block_collected)
	GameEvents.match_ended.connect(_on_match_ended)
	GameEvents.effect_applied.connect(_on_effect_applied)
	GameEvents.effect_expired.connect(_on_effect_expired)
	GameEvents.bomb_transferred.connect(_on_bomb_transferred)


func _process(delta: float) -> void:
	if _bomb == null:
		return
	var time_left := _bomb.time_left if _bomb.running else 0.0
	var total_seconds := maxi(0, int(time_left))
	_timer_label.text = "BOMBA  %02d:%02d" % [int(total_seconds / 60), total_seconds % 60]
	_timer_label.add_theme_color_override(
		"font_color", Color(1.0, 0.3, 0.25) if time_left <= 5.0 and _bomb.running else Color.WHITE
	)
	var alive: int = _characters_provider.call().size() if _characters_provider.is_valid() else 0
	_round_label.text = "Ronda %d  ·  Quedan %d" % [GameManager.round_number, alive]
	if _bomb.holder != null and _bomb.running:
		_holder_label.text = "La tiene: %s" % _bomb.holder.display_name
	else:
		_holder_label.text = ""
	_update_minimap_visibility()
	_minimap.queue_redraw()

	var lines: PackedStringArray = []
	for effect in _effects.get_active_for(_player):
		var data: Dictionary = effect
		lines.append("%s  %.1f s" % [data.label, maxf(0.0, float(data.remaining))])
	_effects_label.text = "\n".join(lines)

	if _center_ttl > 0.0:
		_center_ttl -= delta
		if _center_ttl <= 0.0 and GameManager.state != GameManager.State.PAUSED:
			_center_label.text = ""
	if _toast_ttl > 0.0:
		_toast_ttl -= delta
		if _toast_ttl <= 0.0:
			_toast_label.text = ""


# --- Construcción de la interfaz -----------------------------------------------


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top_left := VBoxContainer.new()
	top_left.position = Vector2(16.0, 12.0)
	top_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_left)
	_timer_label = _make_label(34)
	_round_label = _make_label(18)
	_holder_label = _make_label(18)
	top_left.add_child(_timer_label)
	top_left.add_child(_round_label)
	top_left.add_child(_holder_label)

	_effects_label = _make_label(16)
	_effects_label.set_anchors_and_offsets_preset(
		Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 16
	)
	_effects_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(_effects_label)

	_minimap = Minimap.new()
	root.add_child(_minimap)
	_minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_minimap.offset_left = -252.0
	_minimap.offset_top = 12.0
	_minimap.offset_right = -12.0
	_minimap.offset_bottom = 147.0

	_center_label = _make_label(72)
	_center_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(_center_label)

	_toast_label = _make_label(22)
	_toast_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_toast_label.offset_top = -90.0
	_toast_label.offset_bottom = -50.0
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_toast_label)

	_result_box = CenterContainer.new()
	_result_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_box.visible = false
	root.add_child(_result_box)
	var panel := PanelContainer.new()
	_result_box.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	_result_title = _make_label(48)
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_detail = _make_label(20)
	_result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_result_title)
	box.add_child(_result_detail)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	var again := Button.new()
	again.text = "Jugar de nuevo (R)"
	again.pressed.connect(GameManager.restart_match)
	var menu := Button.new()
	menu.text = "Menú"
	menu.pressed.connect(GameManager.go_to_menu)
	buttons.add_child(again)
	buttons.add_child(menu)


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	return label


# --- Reacción a eventos -------------------------------------------------------


func _show_center(text: String, ttl: float = 0.0) -> void:
	_center_label.text = text
	_center_ttl = ttl


func _on_state_changed(new_state: int, old_state: int) -> void:
	if new_state == GameManager.State.PAUSED:
		_show_center("PAUSA\n(Esc para continuar)")
	elif old_state == GameManager.State.PAUSED:
		_show_center(_countdown_text if new_state == GameManager.State.COUNTDOWN else "")


func _on_countdown_tick(seconds_left: int) -> void:
	_countdown_text = str(seconds_left)
	_show_center(_countdown_text)


func _on_round_started(_round_number: int, _holder: Node) -> void:
	_countdown_text = ""
	_show_center("¡YA!", 0.8)


func _on_bomb_exploded(holder: Node) -> void:
	var character := holder as Character
	_show_center("¡BOOM!\n%s eliminado" % (character.display_name if character else "?"), 1.8)


func _on_lucky_block_collected(collector: Node, reward: Dictionary) -> void:
	var character := collector as Character
	_toast_label.text = (
		"%s: %s  [%s]"
		% [
			character.display_name if character else "?",
			reward.name,
			RewardTable.rarity_name(reward.rarity)
		]
	)
	_toast_label.add_theme_color_override("font_color", RewardTable.rarity_color(reward.rarity))
	_toast_ttl = 2.5


func _on_match_ended(player_won: bool) -> void:
	_result_title.text = "¡VICTORIA!" if player_won else "¡DERROTA!"
	_result_detail.text = (
		"Eres el último en pie."
		if player_won
		else "La bomba explotó en tus manos (ronda %d)." % GameManager.round_number
	)
	_result_box.visible = true
	_update_minimap_visibility()


func _on_effect_applied(_target: Node, _effect_id: String, _duration: float) -> void:
	_update_minimap_visibility()


func _on_effect_expired(_target: Node, _effect_id: String, _reason: int) -> void:
	_update_minimap_visibility()


func _on_bomb_transferred(_from: Node, _to: Node) -> void:
	_update_minimap_visibility()


func _update_minimap_visibility() -> void:
	if _minimap == null or _player == null or _effects == null:
		return
	_minimap.visible = _player.has_bomb and _effects.has_tracking(_player)
