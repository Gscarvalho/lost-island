#player.gd
extends CharacterBody3D
@onready var camera = $CameraController/Camera3D
@onready var skin = $Skin

#Movement
@export var walk_speed := 5.5
@export var run_speed := 8.5
var movement_input := Vector2.ZERO

#Jump
@export var jump_height : float = 2.25
@export var jump_time_to_peak : float = 0.4
@export var jump_time_to_descent : float = 0.3

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

#State Toggles
var is_attacking := false
var is_running := false
var is_being_hit := false




func _physics_process(delta: float) -> void:
	_move_logic(delta)
	_jump_logic(delta)
	move_and_slide()

func _move_logic(delta) -> void:
	movement_input = Input.get_vector("move_left","move_right","move_forward","move_backward").rotated(-camera.global_rotation.y)
	var vel_2d = Vector2(velocity.x,velocity.z)
	if is_on_floor():
		is_running = Input.is_action_pressed("run")
	if movement_input != Vector2.ZERO:
		skin.get_node("AnimationPlayer").current_animation = "Running_B"
		var speed = run_speed if is_running else walk_speed
		vel_2d += movement_input * speed * delta * 10
		vel_2d = vel_2d.limit_length(speed)
		velocity.x = vel_2d.x
		velocity.z = vel_2d.y
		var target_angle = -movement_input.angle() + PI/2
		skin.rotation.y = target_angle
	else:
		skin.get_node("AnimationPlayer").current_animation = "Idle"
		vel_2d = vel_2d.move_toward(Vector2.ZERO, walk_speed * 8.0 * delta)
		velocity.x = vel_2d.x
		velocity.z = vel_2d.y
		#velocity = Vector3.ZERO
		
	
func _jump_logic(delta) -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_velocity
	var gravity = jump_gravity if velocity.y > 0.0 else fall_gravity
	velocity.y -= gravity * delta
