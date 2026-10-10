class_name MainMenu
extends CanvasLayer
## Menú principal con la portada del juego: la imagen ya trae el título "Papa FF", así
## que debajo se colocan los controles (jugar, 2 jugadores, volumen y bots rivales) con un
## estilo que imita al título: formas negras inclinadas, texto blanco y acentos amarillo/naranja.
##
## "Jugar" y "2 Jugadores" no inician la partida: primero muestran las reglas y esperan a
## que el jugador pulse "¡Entendido!" (ver RulesScreen).

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
const AREA_LEFT := 0.54
const AREA_TOP := 0.655
const AREA_RIGHT := 0.94
const AREA_BOTTOM := 0.97

## Se rellena mientras se muestran las reglas (entre pulsar "Jugar" y empezar la partida).
var rules_screen: RulesScreen
var play_button: Button
var two_players_button: Button

var _pending_two_players := false
var _volume_slider: HSlider
var _bots_spin: SpinBox


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

	var play_row := HBoxContainer.new()
	play_row.add_theme_constant_override("separation", 12)
	box.add_child(play_row)

	play_button = Button.new()
	play_button.text = "¡JUGAR!"
	play_button.custom_minimum_size = Vector2(0.0, 56.0)
	play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_button(play_button, font, 28)
	play_button.pressed.connect(_on_play_pressed.bind(false))
	play_row.add_child(play_button)

	two_players_button = Button.new()
	two_players_button.text = "2 JUGADORES"
	two_players_button.custom_minimum_size = Vector2(0.0, 56.0)
	two_players_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	two_players_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_button(two_players_button, font, 28)
	two_players_button.pressed.connect(_on_play_pressed.bind(true))
	play_row.add_child(two_players_button)

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
	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 1.0
	_volume_slider.step = 0.05
	_volume_slider.value = 0.8
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_volume_slider.value_changed.connect(AudioManager.set_master_volume)
	AudioManager.set_master_volume(_volume_slider.value)
	options.add_child(_volume_slider)

	options.add_child(_make_option_label("BOTS RIVALES", font))
	_bots_spin = SpinBox.new()
	_bots_spin.min_value = GameManager.MIN_BOTS
	_bots_spin.max_value = GameManager.MAX_BOTS
	_bots_spin.value = GameManager.bot_count
	_bots_spin.value_changed.connect(func(v: float) -> void: GameManager.bot_count = int(v))
	options.add_child(_bots_spin)

	var help := Label.new()
	help.text = (
		"1 jugador: WASD / Flechas, atajo E / Espacio   ·   2 jugadores: P1 WASD + E, P2 Flechas + Espacio"
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

	play_button.grab_focus()


## "Jugar" / "2 Jugadores" no inician la partida: primero muestran las reglas (y en 2 jugadores
## los controles de P1 y P2) y esperan a "¡Entendido!".
func _on_play_pressed(two_players: bool = false) -> void:
	if rules_screen != null:
		return
	_pending_two_players = two_players
	_set_menu_enabled(false)
	rules_screen = RulesScreen.new()
	rules_screen.two_players = two_players
	rules_screen.confirmed.connect(_on_rules_confirmed)
	rules_screen.cancelled.connect(_on_rules_cancelled)
	add_child(rules_screen)


func _on_rules_confirmed() -> void:
	GameManager.two_players = _pending_two_players
	GameManager.start_match(GameManager.DEFAULT_MAP_ID)


func _on_rules_cancelled() -> void:
	rules_screen.queue_free()
	rules_screen = null
	_set_menu_enabled(true)
	play_button.grab_focus()


## Mientras las reglas están abiertas, el menú de fondo no debe poder usarse (ni con Tab).
func _set_menu_enabled(enabled: bool) -> void:
	play_button.disabled = not enabled
	two_players_button.disabled = not enabled
	_bots_spin.editable = enabled
	_volume_slider.editable = enabled


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
func _style_button(button: Button, font: Font, font_size: int) -> void:
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.BLACK)
	button.add_theme_color_override("font_pressed_color", Color.BLACK)
	button.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6))
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
	button.add_theme_stylebox_override(
		"disabled", _make_box(Color(0.08, 0.08, 0.09, 0.9), Color(0.4, 0.4, 0.4), 3, BUTTON_SKEW)
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