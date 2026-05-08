extends CharacterBody2D

@export var walk_speed = 120.0
@export var run_speed  = 200.0

var current_dir      = "down"
var _movement_locked := false

@onready var anim = $AnimatedSprite2D

func _ready():
	add_to_group("player")
	anim.scale       = Vector2(3.0, 3.0)
	anim.position    = Vector2(0, 0)
	anim.speed_scale = 1.0
	anim.play("AFK")

func _physics_process(_delta):
	player_movement()

func set_movement_locked(locked: bool) -> void:
	_movement_locked = locked
	if locked:
		velocity = Vector2.ZERO
		play_anim(0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		var show : bool = event.pressed
		get_tree().call_group("interactable", "show_interaction_marker", show)

func player_movement():
	if _movement_locked:
		move_and_slide()
		return
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var speed     = run_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed
	if direction != Vector2.ZERO:
		velocity = direction * speed
		update_direction_logic(direction)
		play_anim(1)
		anim.speed_scale = 1.5 if speed == run_speed else 1.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 5)
		play_anim(0)
		anim.speed_scale = 1.0
	move_and_slide()

func update_direction_logic(dir):
	if abs(dir.x) > abs(dir.y):
		current_dir = "right" if dir.x > 0 else "left"
	else:
		current_dir = "down" if dir.y > 0 else "up"

func play_anim(movement):
	match current_dir:
		"right":
			anim.flip_h = false
			anim.play("marche vers droite" if movement == 1 else "AFK_droit")
		"left":
			anim.flip_h = false
			anim.play("marche vers gauche" if movement == 1 else "AFK_gauche")
		"down":
			anim.play("marche vers nous" if movement == 1 else "AFK")
		"up":
			anim.play("marche vers eux" if movement == 1 else "AFK_haut")
