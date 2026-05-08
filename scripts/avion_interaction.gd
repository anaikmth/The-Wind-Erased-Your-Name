extends Node2D

@onready var zone           : Area2D      = $ZoneInteraction
@onready var dialogue_layer : CanvasLayer = $DialogueLayer
@onready var dialogue_drawer              = $DialogueLayer/DialogueDrawer
@onready var marker : Node2D = $InteractionMarker

var player_in_range  := false
var dialogue_active  := false
var already_talked   := false  

var _hint_label : Label
var _player : CharacterBody2D
var font = FontFile

signal avion_dialogue_done

func _ready() -> void:
	add_to_group("interactable")
	font = load("res://assets (photos, musiques...)/IMFellEnglish-Regular.ttf")
	dialogue_drawer.hide()
	dialogue_layer.layer = 10
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	dialogue_drawer.dialogue_ended.connect(_on_dialogue_ended)
	_build_hint_label()

func show_interaction_marker(visible: bool) -> void:
	if already_talked:
		return
	if visible:
		marker.show_marker()
	else:
		marker.hide_marker()

func _build_hint_label() -> void:
	_hint_label = Label.new()
	_hint_label.text = "[E]  Examiner"
	_hint_label.add_theme_font_override("font", load("res://assets (photos, musiques...)/IMFellEnglish-Regular.ttf"))
	_hint_label.add_theme_font_size_override("font_size", 15)
	_hint_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	_hint_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_hint_label.position = Vector2(-48, -64)
	add_child(_hint_label)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player = body
	player_in_range = true
	if not already_talked:
		_show_hint(true)

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_in_range = false
	_show_hint(false)

func _show_hint(visible: bool) -> void:
	var target_alpha := 1.0 if visible else 0.0
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.tween_property(_hint_label, "modulate:a", target_alpha, 0.3)

func _input(event: InputEvent) -> void:
	if dialogue_active and event.is_action_pressed("ui_accept"):
		dialogue_drawer.next()
		return
	if player_in_range and not dialogue_active and not already_talked:
		if event.is_action_pressed("interact"): 
			_start_dialogue()

func _start_dialogue() -> void:
	dialogue_active = true
	_show_hint(false)
	if _player and _player.has_method("set_movement_locked"):
		_player.set_movement_locked(true)
	dialogue_layer.layer = 20
	dialogue_drawer.mouse_filter = Control.MOUSE_FILTER_STOP 
	dialogue_drawer.show()
	dialogue_drawer._animate_in()
	dialogue_drawer.start("avion")

func _on_dialogue_ended() -> void:
	dialogue_active = false
	already_talked  = true
	var t := create_tween()
	t.tween_property(dialogue_drawer, "modulate:a", 0.0, 0.8)
	await t.finished
	dialogue_drawer.hide()
	dialogue_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	dialogue_drawer.modulate.a = 1.0
	if _player and _player.has_method("set_movement_locked"):
		_player.set_movement_locked(false)
	avion_dialogue_done.emit()
