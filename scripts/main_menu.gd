extends Node2D

var music: AudioStreamPlayer
var font: FontFile
var buttons = []
var title_label: RichTextLabel
var cursor_node: Label
var cursor_angle: float = 0.0

var buttons_data = [
	{"text": "Jouer", "subtitle": "entrer dans la tempête"},
	{"text": "Options", "subtitle": "configurer le destin"},
	{"text": "Quitter", "subtitle": "fuir le vent"},
]

func _ready() -> void:
	font = load("res://assets (photos, musiques...)/IMFellEnglish-Regular.ttf")
	_setup_music()
	_setup_particles()
	_setup_intro_fade() 
	_setup_vignette()
	_setup_title()
	_setup_buttons()
	_setup_cursor()
	_setup_click_sound()
	
func _setup_click_sound() -> void:
	var click = AudioStreamPlayer.new()
	click.stream = load("res://assets (photos, musiques...)/interaction.mp3")
	click.volume_db = -5.0
	click.name = "ClickSound"
	add_child(click)

func _process(delta):
	if cursor_node:
		cursor_node.position = get_viewport().get_mouse_position() - Vector2(14, 14)
		cursor_angle += delta * 40.0
		cursor_node.rotation_degrees = cursor_angle

func _setup_cursor():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	cursor_node = Label.new()
	cursor_node.text = "✦"
	cursor_node.add_theme_font_size_override("font_size", 18)
	cursor_node.add_theme_color_override("font_color", Color(0.85, 0.65, 0.2, 0.9))
	cursor_node.z_index = 100
	add_child(cursor_node)

func _setup_music():
	music = AudioStreamPlayer.new()
	add_child(music)
	music.stream = load("res://assets (photos, musiques...)/The_Unmarked_Envelope.mp3")
	music.volume_db = -10
	music.play()
	var t = create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(music, "volume_db", -50.0, 4.0)
	music.finished.connect(_on_music_finished)

func _on_music_finished():
	var t = create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.tween_property(music, "volume_db", -80.0, 2.0)
	await t.finished
	music.play()
	var t2 = create_tween()
	t2.set_trans(Tween.TRANS_SINE)
	t2.tween_property(music, "volume_db", -50.0, 2.0)

func _setup_particles():
	var particles = $SandParticles
	particles.amount = 80
	particles.lifetime = 6.0
	particles.position = Vector2(960, 540)
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(960, 540, 1)
	mat.direction = Vector3(-1, 0.1, 0)
	mat.spread = 5.0
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 90.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.1
	mat.scale_max = 0.4
	mat.color = Color(0.78, 0.53, 0.27, 0.5)
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in range(16):
		for y in range(16):
			var dist = Vector2(x - 8, y - 8).length()
			var alpha = clamp(1.0 - dist / 8.0, 0.0, 1.0)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	particles.texture = ImageTexture.create_from_image(image)
	particles.process_material = mat
	particles.emitting = true

func _setup_intro_fade() -> void:
	var vp_size = Vector2(1920, 1080)

	var dark_overlay = ColorRect.new()
	dark_overlay.size = vp_size
	dark_overlay.color = Color(0, 0, 0, 0.0)
	dark_overlay.z_index = 1
	add_child(dark_overlay)

	var t_dark = create_tween()
	t_dark.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t_dark.tween_property(dark_overlay, "color", Color(0, 0, 0, 0.72), 3.5)

	var intro_black = ColorRect.new()
	intro_black.size = vp_size
	intro_black.color = Color(0.0, 0.0, 0.0, 1.0)
	intro_black.z_index = 3 
	add_child(intro_black)

	await get_tree().process_frame

	var t_intro = create_tween()
	t_intro.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t_intro.tween_property(intro_black, "modulate:a", 0.0, 3.2)
	t_intro.tween_callback(intro_black.queue_free)

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
	var title_chars = "THE WIND ERASED YOUR NAME"
	title_label = RichTextLabel.new()
	title_label.bbcode_enabled = true
	title_label.position = Vector2(0, 120)
	title_label.size = Vector2(1920, 200)
	title_label.add_theme_font_size_override("normal_font_size", 58)
	title_label.add_theme_font_override("normal_font", font)
	title_label.add_theme_font_override("bold_font", font)
	title_label.modulate.a = 0.0
	title_label.z_index = 10
	add_child(title_label)
	title_label.text = "[center][color=#c8a84b]" + title_chars + "[/color][/center]"
	title_label.visible_characters = 0

	await get_tree().create_timer(0.8).timeout
	var fade = create_tween()
	fade.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade.tween_property(title_label, "modulate:a", 1.0, 1.5)

	var reveal = create_tween()
	reveal.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	reveal.tween_property(title_label, "visible_characters", title_chars.length(), 2.5)

	await get_tree().create_timer(2.5).timeout
	var sub = RichTextLabel.new()
	sub.bbcode_enabled = true
	sub.position = Vector2(0, 222)
	sub.size = Vector2(1920, 60)
	sub.add_theme_font_size_override("normal_font_size", 14)
	sub.add_theme_font_override("normal_font", font)
	sub.modulate.a = 0.0
	sub.z_index = 10
	add_child(sub)
	sub.text = "[center][color=#7a5c2e]Le Bataclan Est Mérité[/color][/center]"
	var t = create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(sub, "modulate:a", 1.0, 2.0)

	await get_tree().create_timer(1.0).timeout
	var pulse = create_tween()
	pulse.set_loops(999)
	pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(title_label, "modulate:a", 0.75, 3.5)
	pulse.tween_property(title_label, "modulate:a", 1.0, 3.5)

func _setup_buttons():
	await get_tree().create_timer(2.8).timeout

	var GROUP_Y = 510.0
	var BUTTON_H = 72.0 
	var GAP = 8.0

	for i in range(buttons_data.size()):
		await get_tree().create_timer(0.18 * i).timeout
		var y = GROUP_Y + i * (BUTTON_H + GAP)
		_create_button(buttons_data[i], i, y)

func _create_button(data: Dictionary, index: int, y_pos: float):
	var container = Control.new()
	container.size = Vector2(480, 72)
	container.position = Vector2(90.0, y_pos)
	container.modulate.a = 0.0
	container.z_index = 10
	add_child(container)
	buttons.append(container)

	var line = ColorRect.new()
	line.size = Vector2(2, 44)
	line.position = Vector2(0, 14)
	line.color = Color(0.78, 0.55, 0.18, 0.6)
	container.add_child(line)

	var bg = ColorRect.new()
	bg.size = Vector2(420, 72)
	bg.position = Vector2(0, 0)
	bg.color = Color(0.0, 0.0, 0.0, 0.0)
	bg.name = "BG"
	container.add_child(bg)

	var label = Label.new()
	label.text = data["text"]
	label.position = Vector2(20, 4)
	label.size = Vector2(400, 40)
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_font_override("font", font)
	label.add_theme_color_override("font_color", Color(0.92, 0.80, 0.45, 1.0))
	container.add_child(label)

	var sub = Label.new()
	sub.text = data["subtitle"]
	sub.position = Vector2(22, 42)
	sub.size = Vector2(400, 24)
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_font_override("font", font)
	sub.add_theme_color_override("font_color", Color(0.55, 0.42, 0.22, 0.55))
	container.add_child(sub)

	if index < buttons_data.size() - 1:
		var sep = ColorRect.new()
		sep.size = Vector2(340, 1)
		sep.position = Vector2(2, 72)
		sep.color = Color(0.35, 0.25, 0.1, 0.2)
		container.add_child(sep)

	var btn = Button.new()
	btn.flat = true
	btn.size = Vector2(480, 72)
	var empty = StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(s, empty)
	container.add_child(btn)

	var t = create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.set_parallel(true)
	t.tween_property(container, "modulate:a", 1.0, 0.9)
	t.tween_property(container, "position:x", 135.0, 0.8)

	btn.mouse_entered.connect(_on_hover.bind(container, label, line, bg))
	btn.mouse_exited.connect(_on_unhover.bind(container, label, line, bg))
	btn.pressed.connect(_on_pressed.bind(index))

func _on_hover(container: Control, label: Label, line: ColorRect, bg: ColorRect):
	var t = create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.set_parallel(true)
	t.tween_property(container, "position:x", 162.0, 0.25)
	t.tween_property(label, "theme_override_colors/font_color", Color(1.0, 0.95, 0.65, 1.0), 0.25)
	t.tween_property(line, "color", Color(0.72, 0.22, 0.92, 1.0), 0.25)
	t.tween_property(line, "size:y", 54.0, 0.25)
	t.tween_property(bg, "color", Color(0.72, 0.22, 0.92, 0.07), 0.25)
	if cursor_node:
		cursor_node.add_theme_color_override("font_color", Color(0.7, 0.25, 0.9, 1.0))

func _on_unhover(container: Control, label: Label, line: ColorRect, bg: ColorRect):
	var t = create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.set_parallel(true)
	t.tween_property(container, "position:x", 135.0, 0.3)
	t.tween_property(label, "theme_override_colors/font_color", Color(0.92, 0.80, 0.45, 1.0), 0.3)
	t.tween_property(line, "color", Color(0.78, 0.55, 0.18, 0.6), 0.3)
	t.tween_property(line, "size:y", 44.0, 0.3)
	t.tween_property(bg, "color", Color(0.0, 0.0, 0.0, 0.0), 0.3)
	if cursor_node:
		cursor_node.add_theme_color_override("font_color", Color(0.85, 0.65, 0.2, 0.9))

func _on_pressed(index: int) -> void:
	$ClickSound.play()
	match index:
		0: _transition_to_game()
		1: _transition_to_options()
		2: get_tree().quit()

func _transition_to_game():
	for btn_container in buttons:
		btn_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var overlay = ColorRect.new()
	overlay.size = Vector2(1920, 1080)
	overlay.color = Color(0, 0, 0, 0)
	overlay.z_index = 50
	add_child(overlay)
	var t = create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_property(overlay, "color", Color(0, 0, 0, 1), 1.5)
	await t.finished
	get_tree().change_scene_to_file("res://scenes/a1s1_cinematic.tscn")

func _transition_to_options() -> void:
	for btn_container in buttons:
		btn_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var overlay = ColorRect.new()
	overlay.size = Vector2(1920, 1080)
	overlay.color = Color(0, 0, 0, 0)
	overlay.z_index = 50
	add_child(overlay)
	var t = create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.8)
	await t.finished
	get_tree().change_scene_to_file("res://scenes/options_menu.tscn")
