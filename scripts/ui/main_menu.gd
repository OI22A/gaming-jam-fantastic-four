class_name MainMenu
extends CanvasLayer
## Menú principal con la portada del juego: la imagen ya trae el título "Papa FF", así
## que debajo se colocan los controles (jugar, volumen y bots rivales) con un estilo
## que imita al título: formas negras inclinadas, texto blanco y acentos amarillo/naranja.

const RulesScreenScript := preload("res://scripts/ui/rules_screen.gd")
const COVER_PATH := "res://assets/art/ui/portada.png"
const COLOR_BLACK := Color(0.04, 0.04, 0.05, 0.9)
const COLOR_YELLOW := Color(1.0, 0.82, 0.12)
const COLOR_ORANGE := Color(1.0, 0.52, 0.08)
const COLOR_ORANGE_DARK := Color(0.82, 0.3, 0.04)
## Inclinación de los botones y de la letra. Si en pantalla se ven inclinados hacia el
## lado contrario al título, cambia el signo de estos dos valores.
const BUTTON_SKEW := Vector2(-0.2, 0.0)
const FONT_SLANT := 0.2
## Zona de la portada (proporción de la pantalla) libre debajo del título.
const AREA_LEFT := 0.56
const AREA_TOP := 0.655
const AREA_RIGHT := 0.92
const AREA_BOTTOM := 0.96

var _play_button: Button
var _rules: CanvasLayer


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var cover := TextureRect.new()
	cover.texture = TmxReader.load_texture(COVER_PATH)
	cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cover)

	var font := _make_font()

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.anchor_left = AREA_LEFT
	box.anchor_top = AREA_TOP
	box.anchor_right = AREA_RIGHT
	box.anchor_bottom = AREA_BOTTOM
	add_child(box)

	_play_button = Button.new()
	_play_button.text = "¡JUGAR!"
	_play_button.custom_minimum_size = Vector2(0.0, 62.0)
	_play_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_button(_play_button, font)
	_play_button.pressed.connect(_on_play_pressed)
	box.add_child(_play_button)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", _make_box(Color(0.04, 0.04, 0.05, 0.82), COLOR_ORANGE, 2, Vector2.ZERO)
	)
	box.add_child(panel)

	var options := GridContainer.new()
	options.columns = 2
	options.add_theme_constant_override("h_separation", 14)
	options.add_theme_constant_override("v_separation", 8)
	panel.add_child(options)

	options.add_child(_make_option_label("VOLUMEN", font))
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = 0.8
	volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	volume.value_changed.connect(AudioManager.set_master_volume)
	AudioManager.set_master_volume(volume.value)
	options.add_child(volume)

	options.add_child(_make_option_label("BOTS RIVALES", font))
	var bots_spin := SpinBox.new()
	bots_spin.min_value = GameManager.MIN_BOTS
	bots_spin.max_value = GameManager.MAX_BOTS
	bots_spin.value = GameManager.bot_count
	bots_spin.value_changed.connect(func(v: float) -> void: GameManager.bot_count = int(v))
	options.add_child(bots_spin)

	var help := Label.new()
	help.text = (
		"Mover: WASD / Flechas   ·   Atajo sin bomba: E / Espacio"
		+ "   ·   Pausa: Esc   ·   Reiniciar: R"
	)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 13)
	_outline(help)
	box.add_child(help)

	var credits := Label.new()
	credits.text = "AI GAME JAM  ·  FantasticFour"
	credits.modulate = Color(1.0, 1.0, 1.0, 0.8)
	_outline(credits)
	add_child(credits)
	credits.set_anchors_and_offsets_preset(
		Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 16
	)

	_play_button.grab_focus()


## "Jugar" abre las reglas; la partida solo empieza al confirmarlas.
func _on_play_pressed() -> void:
	if _rules != null:
		return
	_rules = RulesScreenScript.new()
	_rules.confirmed.connect(_on_rules_confirmed)
	_rules.cancelled.connect(_on_rules_cancelled)
	add_child(_rules)


func _on_rules_confirmed() -> void:
	GameManager.start_match(GameManager.DEFAULT_MAP_ID)


func _on_rules_cancelled() -> void:
	_rules.queue_free()
	_rules = null
	_play_button.grab_focus()


## Letra gruesa e inclinada a partir de la fuente por defecto (funciona también en Web).
func _make_font() -> FontVariation:
	var font := FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = 0.8
	var slant := Vector2(FONT_SLANT, 1.0)
	font.variation_transform = Transform2D(Vector2(1.0, 0.0), slant, Vector2.ZERO)
	return font


func _make_box(fill: Color, border: Color, border_width: int, skew: Vector2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.skew = skew
	box.set_content_margin_all(12.0)
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	box.shadow_size = 6
	return box


## Negro con borde amarillo; al pasar el ratón se vuelve naranja con letra negra.
func _style_button(button: Button, font: Font) -> void:
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 34)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.BLACK)
	button.add_theme_color_override("font_pressed_color", Color.BLACK)
	button.add_theme_stylebox_override(
		"normal", _make_box(COLOR_BLACK, COLOR_YELLOW, 3, BUTTON_SKEW)
	)
	button.add_theme_stylebox_override(
		"focus", _make_box(COLOR_BLACK, Color.WHITE, 3, BUTTON_SKEW)
	)
	button.add_theme_stylebox_override(
		"hover", _make_box(COLOR_ORANGE, COLOR_YELLOW, 3, BUTTON_SKEW)
	)
	button.add_theme_stylebox_override(
		"pressed", _make_box(COLOR_ORANGE_DARK, COLOR_YELLOW, 3, BUTTON_SKEW)
	)


func _make_option_label(text: String, font: Font) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", COLOR_YELLOW)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


## Contorno negro para que el texto se lea sobre la ilustración.
func _outline(label: Label) -> void:
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)