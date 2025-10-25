#player.gd
class_name Player
extends CharacterBody3D
@onready var camera = $CameraController/Camera3D
@onready var skin = $Skin

#Movement
var walk_speed := 5.5
var run_speed := 8.5
var movement_input := Vector2.ZERO
var speed_modifier := 1.0

#Jump
var jump_height : float = 3.5
var jump_time_to_peak : float = 0.4
var jump_time_to_descent : float = 0.3

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

#State Toggles
var is_attacking := false
var is_running := false
var is_being_hit := false


func _physics_process(delta: float) -> void:
	_menu_logic()
	if StateManager.current_state == StateManager.State.PLAY:
		_move_logic(delta)
		_jump_logic(delta)
		_attacks_logic()
		_skills_logic()
		move_and_slide()


func _menu_logic() -> void:
	if Input.is_action_just_pressed("menu"):
		if StateManager.current_state == StateManager.State.PLAY:
			StateManager.set_state(StateManager.State.MENU)
		elif StateManager.current_state == StateManager.State.MENU:
			StateManager.set_state(StateManager.State.PLAY)
		elif StateManager.current_state == StateManager.State.TITLE:
			StateManager.set_state(StateManager.State.MENU)
	if Input.is_action_just_pressed("title"):
		if StateManager.current_state == StateManager.State.PLAY:
			StateManager.set_state(StateManager.State.TITLE)
		elif StateManager.current_state == StateManager.State.MENU:
			StateManager.set_state(StateManager.State.TITLE)
		elif StateManager.current_state == StateManager.State.TITLE:
			StateManager.set_state(StateManager.State.PLAY)
		
		#print(StateManager.current_state)

func _attacks_logic() -> void:
	if Input.is_action_just_pressed("attack"):
		skin.current_attack = skin.attacks[0] #in Skill inventory X is first [0]
		skin.attack("X attack")
	if Input.is_action_just_pressed("skill"):
		skin.current_attack = skin.attacks[1] #in Skill inventory Y is first [0]
		skin.attack("Y attack")

func _skills_logic() -> void:
	pass

func _move_logic(delta) -> void:
	movement_input = Input.get_vector("move_left","move_right","move_forward","move_backward").rotated(-camera.global_rotation.y)
	var vel_2d = Vector2(velocity.x,velocity.z)
	if is_on_floor():
		is_running = Input.is_action_pressed("run")
	if movement_input != Vector2.ZERO:
		var speed = run_speed if is_running else walk_speed
		vel_2d += movement_input * speed * delta * 10
		vel_2d = vel_2d.limit_length(speed) * speed_modifier
		velocity.x = vel_2d.x
		velocity.z = vel_2d.y
		var target_angle = -movement_input.angle() + PI/2
		skin.rotation.y = rotate_toward(skin.rotation.y, target_angle, 6.0 * delta)
		#tween.tween_property(skin,"rotation:y", target_angle, 0.3)
	else:
		vel_2d = vel_2d.move_toward(Vector2.ZERO, walk_speed * 8.0)
		velocity.x = vel_2d.x
		velocity.z = vel_2d.y
		#velocity = Vector3.ZERO

func _jump_logic(delta) -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_velocity
	var gravity = jump_gravity if velocity.y > 0.0 else fall_gravity
	velocity.y -= gravity * delta

func hit(damage: float, attacker: CharacterBody3D) -> void:
	pass

func stop_movement(stop_speed: float, start_speed: float) -> void:
	var tween = create_tween()
	tween.tween_property(self,"speed_modifier", 0.0, stop_speed)
	tween.tween_property(self,"speed_modifier", 1.0, start_speed)
	
