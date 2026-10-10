class_name MainMenu
extends CanvasLayer
## Menú principal: elegir mapa y número de bots. Iniciar con GameManager.


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.08, 0.1, 0.16)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	var title := Label.new()
	title.text = "PAPA CALIENTE 2D"
	title.add_theme_font_size_override("font_size", 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Que no te explote la bomba. Último en pie gana."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)

	var bots_row := HBoxContainer.new()
	bots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(bots_row)
	var bots_label := Label.new()
	bots_label.text = "Bots rivales: "
	bots_row.add_child(bots_label)
	var bots_spin := SpinBox.new()
	bots_spin.min_value = GameManager.MIN_BOTS
	bots_spin.max_value = GameManager.MAX_BOTS
	bots_spin.value = GameManager.bot_count
	bots_spin.value_changed.connect(func(v: float) -> void: GameManager.bot_count = int(v))
	bots_row.add_child(bots_spin)

	for map_id in GameManager.MAPS:
		var button := Button.new()
		button.text = "Jugar en: %s" % GameManager.MAPS[map_id].name
		button.custom_minimum_size = Vector2(320.0, 48.0)
		button.pressed.connect(GameManager.start_match.bind(map_id))
		box.add_child(button)

	var help := Label.new()
	help.text = "Mover: WASD / Flechas   ·   Pausa: Esc   ·   Reiniciar: R"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(help)

	var credits := Label.new()
	credits.text = "AI GAME JAM  ·  FantasticFour"
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits.modulate = Color(1.0, 1.0, 1.0, 0.5)
	box.add_child(credits)
