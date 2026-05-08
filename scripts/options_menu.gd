extends Node2D

var font: FontFile
var cursor_node: Label
var cursor_angle: float = 0.0
var sliders = {}
var toggle_states = {}
var section_labels = []

# Options data structure
var audio_options = [
	{"key": "master_volume",  "label": "Volume Principal",   "subtitle": "l'intensité du monde",    "type": "slider", "value": 80.0},
	{"key": "music_volume",   "label": "Volume Musique",     "subtitle": "la mélodie du vent",       "type": "slider", "value": 70.0},
	{"key": "sfx_volume",     "label": "Volume Effets",      "subtitle": "les échos de l'action",    "type": "slider", "value": 90.0},
]

var display_options = [
	{"key": "fullscreen",     "label": "Plein Écran",        "subtitle": "engloutir la lumière",     "type": "toggle", "value": true},
	{"key": "vsync",          "label": "Synchronisation V",  "subtitle": "dompter le temps",         "type": "toggle", "value": true},
	{"key": "particles",      "label": "Particules",         "subtitle": "la poussière du passage",  "type": "toggle", "value": true},
]

var gameplay_options = [
	{"key": "screen_shake",   "label": "Tremblement Écran",  "subtitle": "ressentir l'impact",       "type": "toggle", "value": true},
	{"key": "autosave",       "label": "Sauvegarde Auto",    "subtitle": "ne rien laisser au hasard","type": "toggle", "value": true},
]

func _ready() -> void:
	font = load("res://assets (photos, musiques...)/IMFellEnglish-Regular.ttf")
	_load_saved_options()
	_setup_cursor()
	_setup_click_sound()
	_setup_blur()
	_setup_vignette()
	_setup_title()
	_setup_back_button()
	_setup_all_options()

func _process(delta):
	if cursor_node:
		cursor_node.position = get_viewport().get_mouse_position() - Vector2(14, 14)
		cursor_angle += delta * 40.0
		cursor_node.rotation_degrees = cursor_angle

func _load_saved_options() -> void:
	for opt in audio_options:
		var saved = _get_setting(opt["key"], opt["value"])
		opt["value"] = saved
	for opt in display_options:
		var saved = _get_setting(opt["key"], opt["value"])
		opt["value"] = saved
	for opt in gameplay_options:
		var saved = _get_setting(opt["key"], opt["value"])
		opt["value"] = saved

func _get_setting(key: String, default_val) -> Variant:
	if ProjectSettings.has_setting("game/options/" + key):
		return ProjectSettings.get_setting("game/options/" + key)
	return default_val

func _save_setting(key: String, value: Variant) -> void:
	ProjectSettings.set_setting("game/options/" + key, value)
	_apply_option(key, value)

func _apply_option(key: String, value: Variant) -> void:
	match key:
		"master_volume":
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(float(value) / 100.0))
		"music_volume":
			var bus = AudioServer.get_bus_index("Music")
			if bus >= 0:
				AudioServer.set_bus_volume_db(bus, linear_to_db(float(value) / 100.0))
		"sfx_volume":
			var bus = AudioServer.get_bus_index("SFX")
			if bus >= 0:
				AudioServer.set_bus_volume_db(bus, linear_to_db(float(value) / 100.0))
		"fullscreen":
			if value:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		"vsync":
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED
			)

func _setup_cursor():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	cursor_node = Label.new()
	cursor_node.text = "✦"
	cursor_node.add_theme_font_size_override("font_size", 18)
	cursor_node.add_theme_color_override("font_color", Color(0.85, 0.65, 0.2, 0.9))
	cursor_node.z_index = 100
	add_child(cursor_node)

func _setup_click_sound() -> void:
	var click = AudioStreamPlayer.new()
	click.stream = load("res://assets (photos, musiques...)/interaction.mp3")
	click.volume_db = -5.0
	click.name = "ClickSound"
	add_child(click)

func _setup_blur():
	# Dark semi-transparent overlay with blur effect on top of background
	var blur_rect = ColorRect.new()
	blur_rect.size = Vector2(1920, 1080)
	blur_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	blur_rect.z_index = 1
	add_child(blur_rect)

	var blur_shader_code = """
shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 col = vec4(0.0);
	float total = 0.0;
	for (int x = -3; x <= 3; x++) {
		for (int y = -3; y <= 3; y++) {
			vec2 offset = vec2(float(x), float(y)) * 0.0022;
			col += texture(SCREEN_TEXTURE, uv + offset);
			total += 1.0;
		}
	}
	col /= total;
	// Darken significantly so text is readable
	col.rgb *= 0.28;
	COLOR = vec4(col.rgb, 1.0);
}
"""
	var shader = Shader.new()
	shader.code = blur_shader_code
	var mat = ShaderMaterial.new()
	mat.shader = shader
	blur_rect.material = mat

func _setup_vignette():
	var vignette = ColorRect.new()
	vignette.size = Vector2(1920, 1080)
	vignette.z_index = 2
	add_child(vignette)
	var shader_code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV - 0.5;
	float vign = 1.0 - smoothstep(0.15, 0.75, length(uv * vec2(1.2, 1.4)));
	vign = pow(vign, 0.8);
	COLOR = vec4(0.0, 0.0, 0.0, 1.0 - vign);
}
"""
	var shader = Shader.new()
	shader.code = shader_code
	var mat = ShaderMaterial.new()
	mat.shader = shader
	vignette.material = mat

func _setup_title():
	var title = RichTextLabel.new()
	title.bbcode_enabled = true
	title.position = Vector2(0, 80)
	title.size = Vector2(1920, 120)
	title.add_theme_font_size_override("normal_font_size", 46)
	title.add_theme_font_override("normal_font", font)
	title.z_index = 10
	title.modulate.a = 0.0
	add_child(title)
	title.text = "[center][color=#c8a84b]OPTIONS[/color][/center]"

	var sub = RichTextLabel.new()
	sub.bbcode_enabled = true
	sub.position = Vector2(0, 156)
	sub.size = Vector2(1920, 40)
	sub.add_theme_font_size_override("normal_font_size", 13)
	sub.add_theme_font_override("normal_font", font)
	sub.z_index = 10
	sub.modulate.a = 0.0
	add_child(sub)
	sub.text = "[center][color=#7a5c2e]configurer le destin[/color][/center]"

	var t1 = create_tween()
	t1.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t1.tween_property(title, "modulate:a", 1.0, 1.2)

	var t2 = create_tween()
	t2.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t2.tween_property(sub, "modulate:a", 1.0, 1.5)

	# Separator line
	var sep = ColorRect.new()
	sep.size = Vector2(600, 1)
	sep.position = Vector2(660, 210)
	sep.color = Color(0.78, 0.55, 0.18, 0.25)
	sep.z_index = 10
	add_child(sep)

func _setup_back_button():
	var container = Control.new()
	container.size = Vector2(300, 56)
	container.position = Vector2(90, 980)
	container.z_index = 10
	container.modulate.a = 0.0
	add_child(container)

	var line = ColorRect.new()
	line.size = Vector2(2, 36)
	line.position = Vector2(0, 10)
	line.color = Color(0.78, 0.55, 0.18, 0.6)
	line.name = "Line"
	container.add_child(line)

	var bg = ColorRect.new()
	bg.size = Vector2(300, 56)
	bg.color = Color(0.0, 0.0, 0.0, 0.0)
	bg.name = "BG"
	container.add_child(bg)

	var label = Label.new()
	label.text = "← Retour"
	label.position = Vector2(16, 4)
	label.size = Vector2(280, 32)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_font_override("font", font)
	label.add_theme_color_override("font_color", Color(0.92, 0.80, 0.45, 1.0))
	label.name = "Label"
	container.add_child(label)

	var sublabel = Label.new()
	sublabel.text = "oublier les réglages"
	sublabel.position = Vector2(18, 34)
	sublabel.size = Vector2(280, 20)
	sublabel.add_theme_font_size_override("font_size", 10)
	sublabel.add_theme_font_override("font", font)
	sublabel.add_theme_color_override("font_color", Color(0.55, 0.42, 0.22, 0.5))
	container.add_child(sublabel)

	var btn = Button.new()
	btn.flat = true
	btn.size = Vector2(300, 56)
	var empty = StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(s, empty)
	container.add_child(btn)

	var t = create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(container, "modulate:a", 1.0, 1.0)

	btn.mouse_entered.connect(func():
		var tw = create_tween()
		tw.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(container, "position:x", 110.0, 0.25)
		tw.tween_property(label, "theme_override_colors/font_color", Color(1.0, 0.95, 0.65, 1.0), 0.25)
		tw.tween_property(line, "color", Color(0.72, 0.22, 0.92, 1.0), 0.25)
		tw.tween_property(bg, "color", Color(0.72, 0.22, 0.92, 0.07), 0.25)
		if cursor_node:
			cursor_node.add_theme_color_override("font_color", Color(0.7, 0.25, 0.9, 1.0))
	)
	btn.mouse_exited.connect(func():
		var tw = create_tween()
		tw.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(container, "position:x", 90.0, 0.3)
		tw.tween_property(label, "theme_override_colors/font_color", Color(0.92, 0.80, 0.45, 1.0), 0.3)
		tw.tween_property(line, "color", Color(0.78, 0.55, 0.18, 0.6), 0.3)
		tw.tween_property(bg, "color", Color(0.0, 0.0, 0.0, 0.0), 0.3)
		if cursor_node:
			cursor_node.add_theme_color_override("font_color", Color(0.85, 0.65, 0.2, 0.9))
	)
	btn.pressed.connect(_go_back)

func _setup_all_options():
	# Left column: Audio (x=200), Right column: Display + Gameplay (x=900)
	await get_tree().create_timer(0.3).timeout
	_setup_section("SON", audio_options, Vector2(200, 250), 0)
	await get_tree().create_timer(0.15).timeout
	_setup_section("AFFICHAGE", display_options, Vector2(900, 250), audio_options.size())
	await get_tree().create_timer(0.15).timeout
	_setup_section("GAMEPLAY", gameplay_options, Vector2(900, 560), audio_options.size() + display_options.size())

func _setup_section(title: String, options: Array, base_pos: Vector2, start_index: int):
	# Section title
	var sec_label = RichTextLabel.new()
	sec_label.bbcode_enabled = true
	sec_label.position = base_pos - Vector2(0, 40)
	sec_label.size = Vector2(500, 50)
	sec_label.add_theme_font_size_override("normal_font_size", 11)
	sec_label.add_theme_font_override("normal_font", font)
	sec_label.z_index = 10
	sec_label.modulate.a = 0.0
	add_child(sec_label)
	sec_label.text = "[color=#7a5c2e]— " + title + " —[/color]"

	var t0 = create_tween()
	t0.tween_property(sec_label, "modulate:a", 1.0, 0.8)

	var ROW_H = 80.0
	for i in range(options.size()):
		await get_tree().create_timer(0.12 * i).timeout
		var opt = options[i]
		var y = base_pos.y + i * ROW_H
		_create_option_row(opt, Vector2(base_pos.x, y), start_index + i)

func _create_option_row(opt: Dictionary, pos: Vector2, global_index: int):
	var container = Control.new()
	container.size = Vector2(540, 72)
	container.position = Vector2(pos.x - 20.0, pos.y)
	container.modulate.a = 0.0
	container.z_index = 10
	add_child(container)

	# Accent line
	var line = ColorRect.new()
	line.size = Vector2(2, 36)
	line.position = Vector2(0, 18)
	line.color = Color(0.78, 0.55, 0.18, 0.45)
	container.add_child(line)

	# Label
	var label = Label.new()
	label.text = opt["label"]
	label.position = Vector2(16, 4)
	label.size = Vector2(300, 30)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_font_override("font", font)
	label.add_theme_color_override("font_color", Color(0.92, 0.80, 0.45, 1.0))
	container.add_child(label)

	var sublabel = Label.new()
	sublabel.text = opt["subtitle"]
	sublabel.position = Vector2(18, 32)
	sublabel.size = Vector2(300, 20)
	sublabel.add_theme_font_size_override("font_size", 10)
	sublabel.add_theme_font_override("font", font)
	sublabel.add_theme_color_override("font_color", Color(0.55, 0.42, 0.22, 0.5))
	container.add_child(sublabel)

	# Separator
	var sep = ColorRect.new()
	sep.size = Vector2(480, 1)
	sep.position = Vector2(2, 72)
	sep.color = Color(0.35, 0.25, 0.1, 0.15)
	container.add_child(sep)

	# Widget area
	if opt["type"] == "slider":
		_create_slider_widget(container, opt, line)
	elif opt["type"] == "toggle":
		_create_toggle_widget(container, opt, line)

	# Fade-in animation
	var t = create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.set_parallel(true)
	t.tween_property(container, "modulate:a", 1.0, 0.7)
	t.tween_property(container, "position:x", pos.x, 0.6)

func _create_slider_widget(container: Control, opt: Dictionary, line: ColorRect):
	var track_bg = ColorRect.new()
	track_bg.size = Vector2(160, 2)
	track_bg.position = Vector2(320, 28)
	track_bg.color = Color(0.35, 0.25, 0.1, 0.4)
	container.add_child(track_bg)

	var track_fill = ColorRect.new()
	track_fill.size = Vector2(160 * opt["value"] / 100.0, 2)
	track_fill.position = Vector2(320, 28)
	track_fill.color = Color(0.78, 0.55, 0.18, 0.9)
	track_fill.name = "Fill"
	container.add_child(track_fill)

	var handle = Label.new()
	handle.text = "◆"
	handle.add_theme_font_size_override("font_size", 10)
	handle.add_theme_color_override("font_color", Color(0.92, 0.80, 0.45, 1.0))
	handle.position = Vector2(320 + 160 * opt["value"] / 100.0 - 8, 18)
	handle.name = "Handle"
	container.add_child(handle)

	var val_label = Label.new()
	val_label.text = str(int(opt["value"])) + "%"
	val_label.position = Vector2(492, 16)
	val_label.size = Vector2(50, 24)
	val_label.add_theme_font_size_override("font_size", 13)
	val_label.add_theme_font_override("font", font)
	val_label.add_theme_color_override("font_color", Color(0.65, 0.50, 0.25, 0.8))
	val_label.name = "ValueLabel"
	container.add_child(val_label)

	# Invisible drag area
	var drag_area = Button.new()
	drag_area.flat = true
	drag_area.position = Vector2(312, 14)
	drag_area.size = Vector2(180, 24)
	var empty = StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus"]:
		drag_area.add_theme_stylebox_override(s, empty)
	container.add_child(drag_area)

	sliders[opt["key"]] = {
		"fill": track_fill,
		"handle": handle,
		"val_label": val_label,
		"opt": opt,
		"dragging": false
	}

	drag_area.button_down.connect(func():
		sliders[opt["key"]]["dragging"] = true
		line.color = Color(0.72, 0.22, 0.92, 1.0)
	)
	drag_area.button_up.connect(func():
		sliders[opt["key"]]["dragging"] = false
		line.color = Color(0.78, 0.55, 0.18, 0.45)
		$ClickSound.play()
	)
	drag_area.mouse_entered.connect(func():
		line.color = Color(0.72, 0.22, 0.92, 0.7)
		if cursor_node:
			cursor_node.add_theme_color_override("font_color", Color(0.7, 0.25, 0.9, 1.0))
	)
	drag_area.mouse_exited.connect(func():
		if not sliders[opt["key"]]["dragging"]:
			line.color = Color(0.78, 0.55, 0.18, 0.45)
		if cursor_node:
			cursor_node.add_theme_color_override("font_color", Color(0.85, 0.65, 0.2, 0.9))
	)

	# Input handling for slider drag
	drag_area.gui_input.connect(func(event):
		if event is InputEventMouseMotion and sliders[opt["key"]]["dragging"]:
			var local_x = clamp(event.position.x, 0.0, 160.0)
			var new_val = local_x / 160.0 * 100.0
			opt["value"] = new_val
			track_fill.size.x = 160.0 * new_val / 100.0
			handle.position.x = 320 + 160.0 * new_val / 100.0 - 8
			val_label.text = str(int(new_val)) + "%"
			_save_setting(opt["key"], new_val)
	)

func _create_toggle_widget(container: Control, opt: Dictionary, line: ColorRect):
	var state = opt["value"]

	var bg_off = ColorRect.new()
	bg_off.size = Vector2(54, 24)
	bg_off.position = Vector2(320, 16)
	bg_off.color = Color(0.15, 0.10, 0.06, 0.8)
	container.add_child(bg_off)

	var bg_on = ColorRect.new()
	bg_on.size = Vector2(54, 24)
	bg_on.position = Vector2(320, 16)
	bg_on.color = Color(0.72, 0.22, 0.92, 0.35)
	bg_on.modulate.a = 1.0 if state else 0.0
	bg_on.name = "BGOn"
	container.add_child(bg_on)

	var knob = Label.new()
	knob.text = "◆"
	knob.add_theme_font_size_override("font_size", 12)
	knob.add_theme_color_override("font_color",
		Color(0.72, 0.22, 0.92, 1.0) if state else Color(0.50, 0.38, 0.18, 0.6))
	knob.position = Vector2(320 + (30 if state else 4), 10)
	knob.name = "Knob"
	container.add_child(knob)

	var state_label = Label.new()
	state_label.text = "OUI" if state else "NON"
	state_label.position = Vector2(386, 16)
	state_label.size = Vector2(60, 24)
	state_label.add_theme_font_size_override("font_size", 11)
	state_label.add_theme_font_override("font", font)
	state_label.add_theme_color_override("font_color",
		Color(0.72, 0.22, 0.92, 0.9) if state else Color(0.45, 0.35, 0.18, 0.6))
	state_label.name = "StateLabel"
	container.add_child(state_label)

	toggle_states[opt["key"]] = {
		"state": state,
		"bg_on": bg_on,
		"knob": knob,
		"state_label": state_label,
		"opt": opt
	}

	var btn = Button.new()
	btn.flat = true
	btn.position = Vector2(0, 0)
	btn.size = Vector2(540, 72)
	var empty = StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(s, empty)
	container.add_child(btn)

	btn.mouse_entered.connect(func():
		line.color = Color(0.72, 0.22, 0.92, 0.7)
		if cursor_node:
			cursor_node.add_theme_color_override("font_color", Color(0.7, 0.25, 0.9, 1.0))
	)
	btn.mouse_exited.connect(func():
		line.color = Color(0.78, 0.55, 0.18, 0.45)
		if cursor_node:
			cursor_node.add_theme_color_override("font_color", Color(0.85, 0.65, 0.2, 0.9))
	)
	btn.pressed.connect(func():
		$ClickSound.play()
		var new_state = not toggle_states[opt["key"]]["state"]
		toggle_states[opt["key"]]["state"] = new_state
		opt["value"] = new_state
		_save_setting(opt["key"], new_state)

		var tw = create_tween()
		tw.set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(knob, "position:x", 320 + (30 if new_state else 4), 0.2)
		tw.tween_property(bg_on, "modulate:a", 1.0 if new_state else 0.0, 0.2)

		var new_col = Color(0.72, 0.22, 0.92, 1.0) if new_state else Color(0.50, 0.38, 0.18, 0.6)
		tw.tween_property(knob, "theme_override_colors/font_color", new_col, 0.2)

		state_label.text = "OUI" if new_state else "NON"
		var lbl_col = Color(0.72, 0.22, 0.92, 0.9) if new_state else Color(0.45, 0.35, 0.18, 0.6)
		state_label.add_theme_color_override("font_color", lbl_col)
	)

func _go_back() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var overlay = ColorRect.new()
	overlay.size = Vector2(1920, 1080)
	overlay.color = Color(0, 0, 0, 0)
	overlay.z_index = 50
	add_child(overlay)
	var t = create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.8)
	await t.finished
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
