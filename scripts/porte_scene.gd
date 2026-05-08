extends Node2D

@onready var _bg : ColorRect = $CL_Image/ColorRect
@onready var _img : TextureRect = $CL_Image/PorteImage
@onready var _vignette : ColorRect = $CL_Vignette/Vignette
@onready var _black : ColorRect = $CL_Noir/Noir

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var vp := get_viewport().get_visible_rect().size

	_bg.color = Color(0, 0, 0, 1)
	_bg.size = vp * 4
	_bg.position = -vp

	_img.size = Vector2(vp.x, vp.y * 2.0)
	_img.position = Vector2(0, -vp.y * 1.0)
	_img.pivot_offset = Vector2(vp.x / 2.0, vp.y)

	var sm := ShaderMaterial.new()
	sm.shader = _make_vignette_shader()
	_vignette.material = sm
	_vignette.size = vp

	_black.size = vp
	_black.color = Color(0, 0, 0, 1)

	await get_tree().process_frame
	_run()

func _make_vignette_shader() -> Shader:
	var s := Shader.new()
	s.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV - 0.5;
	float vig = smoothstep(0.55, 0.1, length(uv * vec2(1.0, 0.85)));
	COLOR = vec4(0.0, 0.0, 0.0, (1.0 - vig) * 0.6);
}
"""
	return s

func _run() -> void:
	var vp := get_viewport().get_visible_rect().size

	await get_tree().create_timer(0.3).timeout
	var fade := create_tween()
	fade.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade.tween_property(_black, "color:a", 0.0, 2.2)
	await fade.finished

	await get_tree().create_timer(0.8).timeout

	var pan := create_tween()
	pan.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	pan.tween_property(_img, "position:y", 0.0, 7.0)
	pan.parallel().tween_property(_vignette, "modulate:a", 0.35, 6.0)
	await pan.finished

	await get_tree().create_timer(0.5).timeout

	var zoom_out := create_tween()
	zoom_out.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	zoom_out.tween_property(_img, "size", vp, 4.5)
	zoom_out.parallel().tween_property(_img, "position", Vector2.ZERO, 4.5)
	await zoom_out.finished

	await get_tree().create_timer(1.0).timeout
	_show_label()

func _show_label() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 5
	add_child(cl)
	var lbl := Label.new()
	lbl.text = "[ Entrée ]  Continuer"
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.modulate = Color(1, 1, 1, 0)
	lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lbl.position.y -= 40
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.add_child(lbl)
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.tween_property(lbl, "modulate:a", 1.0, 1.2)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		pass
