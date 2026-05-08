extends Node2D

var _transition_unlocked := false
var _transitioning       := false

var avion           : Node2D = null
var zone_transition : Area2D = null
var player          : CharacterBody2D = null


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_connect_nodes()


func _connect_nodes() -> void:
	if has_node("Personnage"):
		player = $Personnage
	elif has_node("Player"):
		player = $Player
	elif has_node("CharacterBody2D"):   
		player = $CharacterBody2Dr

	if has_node("Avion"):
		avion = $Avion
		if avion.has_signal("avion_dialogue_done"):
			avion.avion_dialogue_done.connect(_on_avion_dialogue_done)
	else:
		push_warning("map_debut : noeud 'Avion' introuvable. Ajoute-le dans la scene.")
		_transition_unlocked = true

	if has_node("ZoneTransition"):
		zone_transition = $ZoneTransition
		zone_transition.body_entered.connect(_on_zone_transition_entered)
		zone_transition.monitoring  = _transition_unlocked
		zone_transition.monitorable = _transition_unlocked
	else:
		push_warning("map_debut : noeud 'ZoneTransition' introuvable. Ajoute un Area2D a l'endroit de la fleche.")


func _on_avion_dialogue_done() -> void:
	_transition_unlocked = true
	if zone_transition != null:
		zone_transition.monitoring  = true
		zone_transition.monitorable = true


func _on_zone_transition_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if _transitioning:
		return
	_transitioning = true

	if player != null:
		player.set_movement_locked(true)

	await _fade_to_black(1.2)
	get_tree().change_scene_to_file("res://scenes/PorteScene.tscn")


func _fade_to_black(duration: float) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 99
	add_child(cl)

	var rect := ColorRect.new()
	rect.color        = Color(0, 0, 0, 0)
	rect.size         = Vector2(3840, 2160)
	rect.position     = Vector2(-960, -540)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(rect)

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.tween_property(rect, "color:a", 1.0, duration)
	await t.finished
