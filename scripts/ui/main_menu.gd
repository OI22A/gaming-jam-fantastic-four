class_name MainMenu
extends CanvasLayer
## Menú principal: elegir número de bots e iniciar la partida con GameManager.


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

	var volume_row := HBoxContainer.new()
	volume_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(volume_row)
	var volume_label := Label.new()
	volume_label.text = "Volumen: "
	volume_row.add_child(volume_label)
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = 0.8
	volume.custom_minimum_size.x = 220.0
	volume.value_changed.connect(AudioManager.set_master_volume)
	AudioManager.set_master_volume(volume.value)
	volume_row.add_child(volume)

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

	var play_button := Button.new()
	play_button.text = "Jugar"
	play_button.custom_minimum_size = Vector2(320.0, 48.0)
	play_button.pressed.connect(GameManager.start_match.bind(GameManager.DEFAULT_MAP_ID))
	box.add_child(play_button)

	var help := Label.new()
	help.text = (
		"Mover: WASD / Flechas   ·   Atajo sin bomba: E / Espacio"
		+ "   ·   Pausa: Esc   ·   Reiniciar: R"
	)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(help)

	var credits := Label.new()
	credits.text = "AI GAME JAM  ·  FantasticFour"
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits.modulate = Color(1.0, 1.0, 1.0, 0.5)
	box.add_child(credits)
