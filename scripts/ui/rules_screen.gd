class_name RulesScreen
extends CanvasLayer
## Pantalla de reglas que aparece al pulsar "Jugar", antes de iniciar la partida.
##
## La partida solo empieza cuando el jugador pulsa "¡Entendido!" (señal `confirmed`).
## "Volver" o Esc emiten `cancelled` y no inician nada.
##
## Los números del texto (tiempos, probabilidades, recompensas) se leen de las mismas
## constantes que usa el juego, para que las reglas mostradas no queden desactualizadas
## si se rebalancea algo (ver `build_left_text()`, `build_middle_text()` y `build_right_text()`).

signal confirmed
signal cancelled

## Segundos tras abrirse en los que "¡Entendido!" aún no responde, para que un doble
## clic o una tecla repetida sobre "Jugar" no se salten las reglas sin leerlas.
const ARM_DELAY := 0.25

## Nombre y descripción de la probabilidad por rareza (el color viene de RewardTable).
const RARITY_LABELS := {
	RewardTable.Rarity.COMMON: ["Bronce", "alta"],
	RewardTable.Rarity.RARE: ["Plateado", "baja"],
	RewardTable.Rarity.LEGENDARY: ["Dorado", "muy baja"],
}
## Qué hace cada recompensa. Si se agrega una nueva sin descripción, se muestra su nombre.
const REWARD_HINTS := {
	"speed_boost": "corres más rápido",
	"silver_speed": "corres mucho más rápido",
	"radar": "minimapa arriba a la derecha con todos los jugadores vivos",
	"extra_time": "suma segundos al temporizador de la bomba",
	"golden_transfer": "la bomba pasa a otro jugador al azar",
}

## Si es true muestra la versión del modo 2 jugadores (controles de P1 y P2).
## Debe asignarse antes de añadir la pantalla al árbol.
var two_players := false

var confirm_button: Button
var back_button: Button

var _armed := false
var _done := false


func _ready() -> void:
	layer = 20

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.12, 0.19)
	style.border_color = Color(0.4, 0.5, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var title := Label.new()
	title.text = "CÓMO SE JUEGA · 2 JUGADORES" if two_players else "CÓMO SE JUEGA"
	title.add_theme_font_size_override("font_size", 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 22)
	box.add_child(columns)
	columns.add_child(_make_column(build_left_text(two_players)))
	columns.add_child(_make_column(build_middle_text(two_players)))
	columns.add_child(_make_column(build_right_text(two_players)))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	box.add_child(buttons)

	back_button = Button.new()
	back_button.text = "Volver"
	back_button.custom_minimum_size = Vector2(150.0, 46.0)
	back_button.pressed.connect(_on_back_pressed)
	buttons.add_child(back_button)

	confirm_button = Button.new()
	confirm_button.text = "¡Entendido!"
	confirm_button.custom_minimum_size = Vector2(260.0, 46.0)
	confirm_button.pressed.connect(_on_confirm_pressed)
	buttons.add_child(confirm_button)
	confirm_button.grab_focus()

	get_tree().create_timer(ARM_DELAY).timeout.connect(func() -> void: _armed = true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()


func _on_confirm_pressed() -> void:
	if not _armed or _done:
		return
	_done = true
	confirm_button.disabled = true
	back_button.disabled = true
	confirmed.emit()


func _on_back_pressed() -> void:
	if _done:
		return
	_done = true
	cancelled.emit()


func _make_column(bbcode: String) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = bbcode
	label.scroll_active = true
	label.custom_minimum_size = Vector2(368.0, 470.0)
	label.add_theme_font_size_override("normal_font_size", 15)
	label.add_theme_font_size_override("bold_font_size", 16)
	return label


# --- Contenido -----------------------------------------------------------------


## Columna izquierda: objetivo y bomba.
static func build_left_text(two_players: bool = false) -> String:
	var round_defaults := MatchController.new()
	var bomb_defaults := BombManager.new()
	var countdown := round_defaults.countdown_seconds
	var bomb_seconds := round_defaults.bomb_duration
	var cooldown := bomb_defaults.transfer_cooldown
	round_defaults.free()
	bomb_defaults.free()
	var lines := PackedStringArray()
	lines.append(_heading("OBJETIVO"))
	lines.append("• Quien lleva la bomba es el impostor: si el contador llega a 0, explota y queda eliminado.")
	if two_players:
		lines.append("• Es una sola pantalla: la cámara enfoca el punto medio entre P1 y P2 y se aleja si se separan.")
		lines.append("• Gana el último jugador en pie (\"Ganó P1\" o \"Ganó P2\"). Si uno es eliminado, el otro sigue solo. Si mueren los dos, pierden.")
	else:
		lines.append("• Ganas si todos los bots son eliminados. Pierdes si la bomba te explota a ti: la partida termina al instante.")
	lines.append("")
	lines.append(_heading("LA BOMBA"))
	lines.append(
		"• Cada ronda empieza con %s s de cuenta regresiva. La bomba cae en alguien al azar, con %s s en el contador."
		% [_fmt(countdown), _fmt(bomb_seconds)]
	)
	lines.append(
		"• Pásala tocando a otro jugador. Tras cada pase hay %s s en los que no se puede volver a pasar." % _fmt(cooldown)
	)
	lines.append(
		"• El tiempo no se reinicia al pasarla: solo vuelve a %s s después de una explosión." % _fmt(bomb_seconds)
	)
	lines.append("• Quien está cruzando un atajo no puede recibir la bomba.")
	return "\n".join(lines)


## Columna central: controles y atajos.
static func build_middle_text(two_players: bool = false) -> String:
	var map_defaults := GameMap.new()
	var crossing := map_defaults.shortcut_use_seconds
	map_defaults.free()
	var lines := PackedStringArray()
	lines.append(_heading("CONTROLES"))
	if two_players:
		lines.append("• [color=#4099ff][b]JUGADOR 1 (P1)[/b][/color]: mover con [b]W A S D[/b]  ·  atajo con [b]E[/b]")
		lines.append("• [color=#26d9d9][b]JUGADOR 2 (P2)[/b][/color]: mover con las [b]flechas[/b]  ·  atajo con [b]Espacio[/b]")
	else:
		lines.append("• Mover: [b]WASD[/b] o [b]flechas[/b]")
		lines.append("• Usar atajo: [b]E[/b] o [b]Espacio[/b]")
	lines.append("• Pausa: [b]Esc[/b]   ·   Reiniciar: [b]R[/b]")
	lines.append("")
	lines.append(_heading("ATAJOS (solo si NO llevas la bomba)"))
	lines.append(
		"• Acércate a la [color=#ffc740][b]ENTRADA[/b][/color] (círculo amarillo) y pulsa [b]E[/b] o [b]Espacio[/b]. Estar encima no basta."
		if not two_players
		else "• Acércate a la [color=#ffc740][b]ENTRADA[/b][/color] (círculo amarillo) y pulsa tu tecla de atajo: [b]E[/b] (P1) o [b]Espacio[/b] (P2). Estar encima no basta."
	)
	lines.append(
		"• El cruce es automático y dura %s s: no puedes moverte ni pasar o recibir la bomba. Sales por la [color=#66e6ff][b]SALIDA[/b][/color] (celeste)."
		% _fmt(crossing)
	)
	lines.append(
		"• Son de un solo sentido: no se puede volver a entrar por la salida, y mientras alguien lo usa nadie más puede entrar en ese atajo."
	)
	lines.append("• Quien lleva la bomba no puede usarlos. Los bots los usan solos.")
	return "\n".join(lines)


## Columna derecha: Lucky Blocks.
static func build_right_text(two_players: bool = false) -> String:
	var spawner_defaults := LuckyBlockSpawner.new()
	var max_blocks := spawner_defaults.max_active_blocks
	var respawn := spawner_defaults.respawn_delay
	spawner_defaults.free()
	var lines := PackedStringArray()
	lines.append(_heading("LUCKY BLOCKS"))
	lines.append(
		"• Solo los recoge quien lleva la bomba, y solo los ves en el mapa mientras la llevas tú. Hay hasta %s a la vez y reaparecen a los %s s."
		% [_fmt(max_blocks), _fmt(respawn)]
	)
	lines.append("• El color indica la probabilidad de lo que dan:")
	lines.append_array(_reward_lines())
	lines.append("• Los efectos temporales se pierden al pasar la bomba.")
	if two_players:
		lines.append("• En 2 jugadores ambos ven los Lucky Blocks y las habilidades mientras uno de los dos tenga la bomba, pero los efectos solo se aplican a quien la lleva.")
	return "\n".join(lines)


static func _reward_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	var distribution := RewardTable.rarity_distribution()
	for rarity: int in RewardTable.Rarity.values():
		var rewards: Array[Dictionary] = []
		for reward: Dictionary in RewardTable.REWARDS:
			if int(reward.rarity) == rarity:
				rewards.append(reward)
		if rewards.is_empty():
			continue
		var label: Array = RARITY_LABELS.get(rarity, [RewardTable.rarity_name(rarity), ""])
		var color := RewardTable.rarity_color(rarity).to_html(false)
		var chance := _fmt(float(distribution.get(rarity, 0.0)))
		var suffix := " · probabilidad %s (%s %%)" % [label[1], chance] if label[1] != "" else " (%s %%)" % chance
		lines.append("   [color=#%s][b]%s[/b][/color]%s" % [color, label[0], suffix])
		for reward in rewards:
			lines.append("      – %s" % _reward_description(reward))
	return lines


static func _reward_description(reward: Dictionary) -> String:
	var text: String = reward.name
	var effects: Array = reward.get("effects", [])
	if not effects.is_empty():
		var seconds := float(effects[0].get("duration", 0.0))
		if seconds > 0.0:
			text += " (%s s)" % _fmt(seconds)
	var hint: String = REWARD_HINTS.get(reward.id, "")
	return "%s: %s" % [text, hint] if hint != "" else text


static func _heading(text: String) -> String:
	return "[color=#8fb4ff][b]%s[/b][/color]" % text


## Números sin ceros sobrantes y con coma decimal: 3.0 → "3", 3.2 → "3,2".
static func _fmt(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return ("%.1f" % value).replace(".", ",")
