extends Node2D

var _tween : Tween

func _ready() -> void:
	modulate.a = 0.0
	_pulse()

func _pulse() -> void:
	_tween = create_tween().set_loops()
	_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)
	_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)

func show_marker() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	await _tween.finished
	_pulse()

func hide_marker() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.2)
