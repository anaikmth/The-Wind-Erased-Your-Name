extends CanvasLayer

var eyelid_top    : ColorRect
var eyelid_bottom : ColorRect
var vignette      : ColorRect
var blur_overlay  : ColorRect

const VP_SIZE := Vector2(1920, 1080)
const HALF := VP_SIZE.y / 2.0

func _ready() -> void:
	layer = 10
	await get_tree().process_frame
	_build()
	_run()

func _build() -> void:
	eyelid_top = _rect(Color(0.02, 0.01, 0.0, 1.0))
	eyelid_top.size = Vector2(VP_SIZE.x, HALF + 2)
	eyelid_top.position = Vector2(0, 0)

	eyelid_bottom = _rect(Color(0.02, 0.01, 0.0, 1.0))
	eyelid_bottom.size = Vector2(VP_SIZE.x, HALF + 2)
	eyelid_bottom.position = Vector2(0, HALF - 2)

	vignette = _rect(Color(0.0, 0.0, 0.0, 0.85))

	blur_overlay = _rect(Color(1.0, 0.97, 0.9, 0.0))

func _rect(color: Color) -> ColorRect:
	var r = ColorRect.new()
	r.size = VP_SIZE
	r.position = Vector2.ZERO
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r

func _run() -> void:
	await get_tree().create_timer(0.8).timeout

	await _flutter(6.0, 0.12, 0.14)
	await get_tree().create_timer(0.5).timeout

	await _flutter(22.0, 0.18, 0.22)
	await get_tree().create_timer(0.7).timeout

	await _flutter(55.0, 0.25, 0.28)
	await get_tree().create_timer(0.4).timeout

	var t = create_tween()
	t.set_parallel(true)
	t.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.tween_property(eyelid_top,    "position:y", -HALF - 2, 5.5)
	t.tween_property(eyelid_bottom, "position:y",  VP_SIZE.y, 5.5)

	var b = create_tween()
	b.set_trans(Tween.TRANS_SINE)
	b.tween_interval(0.3)
	b.tween_property(blur_overlay, "color:a", 0.55, 1.2)
	b.tween_property(blur_overlay, "color:a", 0.0, 3.5)

	var v = create_tween()
	v.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	v.tween_interval(1.2)
	v.tween_property(vignette, "color:a", 0.0, 4.0)

	await t.finished
	await v.finished
	queue_free()

func _flutter(amplitude: float, duration_open: float, duration_close: float) -> void:
	var open = create_tween()
	open.set_parallel(true)
	open.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	open.tween_property(eyelid_top,    "position:y", -amplitude,             duration_open)
	open.tween_property(eyelid_bottom, "position:y",  HALF - 2 + amplitude,  duration_open)
	await open.finished

	var close = create_tween()
	close.set_parallel(true)
	close.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	close.tween_property(eyelid_top,    "position:y", 0.0,       duration_close)
	close.tween_property(eyelid_bottom, "position:y", HALF - 2,  duration_close)
	await close.finished
