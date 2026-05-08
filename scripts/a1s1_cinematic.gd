extends Node2D

@onready var dialogue_drawer = $DialogueLayer/DialogueDrawer

var scene_phase := "intro"
var _black_layer : CanvasLayer
var _black_rect : ColorRect
var _music : AudioStreamPlayer
var _flash_running := false

func _ready():
	dialogue_drawer.hide()
	_start_sequence()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	if scene_phase != "dialogue":
		return
	if event.is_action_pressed("ui_accept"):
		dialogue_drawer.next()

func _start_sequence():
	_black_layer = CanvasLayer.new()
	_black_layer.layer = 50
	add_child(_black_layer)

	_black_rect = ColorRect.new()
	_black_rect.color = Color(0, 0, 0, 1)
	_black_rect.size = Vector2(3840, 2160)
	_black_rect.position = Vector2(-960, -540)
	_black_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black_layer.add_child(_black_rect)

	scene_phase = "intro"
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	var t = create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_black_rect, "modulate:a", 0.0, 3.0)
	await t.finished

	scene_phase = "dialogue"
	dialogue_drawer.show()
	dialogue_drawer._animate_in()
	dialogue_drawer.start("a1s1")

	_music = AudioStreamPlayer.new()
	add_child(_music)
	_music.stream = load("res://assets (photos, musiques...)/Tiger King.mp3")
	_music.volume_db = -90
	_music.play()
	var tm = create_tween()
	tm.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tm.tween_property(_music, "volume_db", -10.0, 3.0)

func _flash_effect(duration: float) -> void:
	var flash_layer = CanvasLayer.new()
	flash_layer.layer = 60
	add_child(flash_layer)

	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.size = Vector2(3840, 2160)
	flash.position = Vector2(-960, -540)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(flash)

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	_flash_running = true
	var elapsed = 0.0

	while elapsed < duration and _flash_running:
		var progress = elapsed / duration

		var nb = 1
		if rng.randf() < lerp(0.05, 0.4, progress):
			nb = 2

		for i in range(nb):
			var peak = rng.randf_range(0.08, lerp(0.4, 1.0, progress))

			var t_in = rng.randf_range(0.04, 0.18)
			var tf1 = create_tween()
			tf1.set_trans(Tween.TRANS_SINE)
			tf1.tween_property(flash, "color:a", peak, t_in)
			await tf1.finished

			if rng.randf() < 0.3:
				await get_tree().create_timer(rng.randf_range(0.0, 0.08)).timeout

			var t_out = rng.randf_range(0.08, 0.5)
			var tf2 = create_tween()
			tf2.set_trans(Tween.TRANS_SINE)
			tf2.tween_property(flash, "color:a", 0.0, t_out)
			await tf2.finished

			if i == 0 and nb == 2:
				await get_tree().create_timer(rng.randf_range(0.05, 0.2)).timeout

		var wait = rng.randf_range(
			lerp(0.8, 0.05, progress),
			lerp(3.0, 0.8, progress)
		)
		await get_tree().create_timer(wait).timeout
		elapsed += wait

	flash_layer.queue_free()

func _on_dialogue_drawer_dialogue_ended():
	scene_phase = "end"

	var t = create_tween()
	t.tween_property(dialogue_drawer, "modulate:a", 0.0, 1.0)
	await t.finished
	dialogue_drawer.hide()

	if is_instance_valid(_music) and _music.playing:
		var tm = create_tween()
		tm.set_trans(Tween.TRANS_SINE)
		tm.tween_property(_music, "volume_db", -80.0, 1.5)
		await tm.finished
		_music.stop()

	_black_rect.modulate.a = 0.0
	var fade_black = create_tween()
	fade_black.set_trans(Tween.TRANS_SINE)
	fade_black.tween_property(_black_rect, "modulate:a", 1.0, 1.5)
	await fade_black.finished

	var son_crash = AudioStreamPlayer.new()
	add_child(son_crash)
	son_crash.stream = load("res://assets (photos, musiques...)/crash.mp3")
	son_crash.volume_db = -80.0
	son_crash.play()
	var tc = create_tween()
	tc.tween_property(son_crash, "volume_db", 0.0, 1.5)

	var son_foule = AudioStreamPlayer.new()
	add_child(son_foule)
	son_foule.stream = load("res://assets (photos, musiques...)/foule panique.mp3")
	son_foule.volume_db = -80.0
	son_foule.play()
	var tf = create_tween()
	tf.tween_property(son_foule, "volume_db", 0.0, 1.5)

	_flash_effect(20.0)

	await get_tree().create_timer(20.0).timeout

	_flash_running = false
	get_tree().change_scene_to_file("res://scenes/map_debut.tscn")
