#player.gd
class_name Player
extends CharacterBody3D

#region References
@export var progression: PlayerProgress

@onready var camera: Camera3D = (
	$CameraController/Camera3D
)

@onready var character: PlayerCharacter = (
	$Character
)

@onready var ui: PlayerHUD = (
	$PlayerUI
)

@onready var stamina_regen_timer: Timer = (
	$Timers/StaminaRegenTimer
)

@onready var weapon_choice_timer: Timer = (
	$Timers/WeaponChoiceTimer
)

@onready var menu_delay_timer: Timer = (
	$Timers/MenuDelayTimer
)

@onready var menu_transition_timer: Timer = (
	$Timers/MenuTransitionTimer
)
#endregion

#region Movement Configuration
var walk_speed := 5.5
var run_speed := 8.5
var speed_modifier := 1.0
var stamina_cost_reduction := 1.0
#endregion

#region Jump Configuration
var jump_height : float = 3.5
var jump_time_to_peak : float = 0.4
var jump_time_to_descent : float = 0.3

@onready var jump_velocity : float = (
	(2.0 * jump_height) / jump_time_to_peak
) * -1.0

@onready var jump_gravity : float = (
	(-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
) * -1.0

@onready var fall_gravity : float = (
	(-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)
) * -1.0
#endregion

#region Runtime State
var movement_input := Vector2.ZERO
var is_running := false
var stamina_depleted_delay_active := false
#endregion

#region Lifecycle
func _ready() -> void:
	StateManager.state_changed.connect(_on_state_changed)
	_on_state_changed(StateManager.current_state)

func _physics_process(delta: float) -> void:
	_menu_logic()
	_equip_logic()
	_move_logic(delta)
	_jump_logic(delta)
	_attacks_logic()
	move_and_slide()
#endregion

#region Game State
func _on_state_changed(state: StateManager.State) -> void:
	var should_pause_regen := state != StateManager.State.PLAY

	for node in get_tree().get_nodes_in_group("regen_timers"):
		var regen_timer := node as Timer

		if regen_timer != null:
			regen_timer.paused = should_pause_regen

func _menu_logic() -> void:
	if (
	Input.is_action_just_pressed("menu")
	and menu_transition_timer.is_stopped()
	):
		menu_transition_timer.start()
		if StateManager.current_state == StateManager.State.PLAY:
			StateManager.set_state(StateManager.State.MENU)
		
		elif StateManager.current_state == StateManager.State.TITLE:
			StateManager.set_state(StateManager.State.MENU)			
		
		elif StateManager.current_state == StateManager.State.MENU:
			StateManager.set_state(StateManager.State.PLAY)			
		
		velocity = Vector3.ZERO
		
func _enter_tree() -> void:
	if progression != null:
		progression = (
			progression.duplicate(true)
			as PlayerProgress
		)
#endregion

#region Weapon Selection
func _equip_logic() -> void:
	if (
		Input.is_action_pressed("swap")
		and StateManager.current_state == StateManager.State.PLAY
		and menu_delay_timer.is_stopped()
	):
		_open_weapon_choice()

	elif (
		Input.is_action_just_released("swap")
		and StateManager.current_state == StateManager.State.WEAPON
	):
		_close_weapon_choice()

	if StateManager.current_state != StateManager.State.WEAPON:
		return

	var left := Input.is_action_just_pressed("menu_left")
	var right := Input.is_action_just_pressed("menu_right")

	if left:
		character.current_mana_type = wrapi(
			character.current_mana_type - 1,
			0,
			character.mana_types.size()
		)

	elif right:
		character.current_mana_type = wrapi(
			character.current_mana_type + 1,
			0,
			character.mana_types.size()
		)

func _open_weapon_choice() -> void:
	weapon_choice_timer.start()

	StateManager.set_state(
		StateManager.State.WEAPON
	)

	ui.show_timer_ui(true)
	Engine.time_scale = 0.1

	var tween := create_tween()
	tween.tween_property(
		self,
		"velocity",
		Vector3.ZERO,
		0.3
	)

func _close_weapon_choice() -> void:
	if StateManager.current_state != StateManager.State.WEAPON:
		return

	weapon_choice_timer.stop()

	StateManager.set_state(
		StateManager.State.PLAY
	)

	Engine.time_scale = 1.0
	ui.show_timer_ui(false)

func _on_weapon_choice_timer_timeout() -> void:
	if StateManager.current_state != StateManager.State.WEAPON:
		return

	_close_weapon_choice()
	menu_delay_timer.start()
#endregion

#region Combat
func _attacks_logic() -> void:
	if StateManager.current_state != StateManager.State.PLAY:
		return

	var attack_index := _get_attack_input_index()

	if attack_index == -1:
		return

	var attack_list := _get_current_attack_list()

	if attack_list.is_empty():
		return

	_try_attack(
		attack_list,
		attack_index
	)

func _try_attack(
	attack_list: Array,
	attack_index: int
	) -> void:
	if attack_index >= attack_list.size():
		print("No attack assigned.")
		return

	var selected_attack := (
		attack_list[attack_index] as Skills
	)

	if selected_attack == null:
		print("No attack assigned.")
		return

	if character.is_action_animation_playing():
		print("Attack already in progress.")
		return

	character.attack(selected_attack)

func _get_current_attack_list() -> Array:
	if character.physical_mode_active:
		if not character.has_equipped_weapon():
			return []

		return character.attacks

	return character.skill_book.get_skills_for_type(
		character.get_current_skill_type()
	)

func _get_attack_input_index() -> int:
	var index_offset := (
		2
		if Input.is_action_pressed("aim")
		else 0
	)

	if Input.is_action_just_pressed("attack"):
		return index_offset

	if Input.is_action_just_pressed("skill"):
		return index_offset + 1

	return -1
#endregion

#region Movement
func _move_logic(delta: float) -> void:
	if StateManager.current_state == StateManager.State.PLAY:
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
			character.rotation.y = rotate_toward(character.rotation.y, target_angle, 6.0 * delta)
		else:
			vel_2d = vel_2d.move_toward(Vector2.ZERO, walk_speed * 8.0)
			velocity.x = vel_2d.x
			velocity.z = vel_2d.y
	elif StateManager.current_state == StateManager.State.MENU:
		velocity = Vector3.ZERO

func _jump_logic(delta: float) -> void:
	if StateManager.current_state == StateManager.State.PLAY:
		if Input.is_action_just_pressed("jump") and is_on_floor() and character.current_stamina >= 10:
			velocity.y = -jump_velocity
			character.current_stamina -= 10.0 * stamina_cost_reduction
			stamina_regen_timer.start()
		var gravity = jump_gravity if velocity.y > 0.0 else fall_gravity
		velocity.y -= gravity * delta

func stop_movement(stop_speed: float, start_speed: float) -> void:
	var tween = create_tween()
	tween.tween_property(self,"speed_modifier", 0.0, stop_speed)
	tween.tween_property(self,"speed_modifier", 1.0, start_speed)
#endregion

#region Stamina
func _on_stamina_regen_timer_timeout() -> void:
	if character.current_stamina <= 0.0 and not stamina_depleted_delay_active:
		print("Stamina depleted, delayed regeneration.")
		stamina_depleted_delay_active = true
		stamina_regen_timer.start(3.0)
		return

	character.current_stamina = 100.0
	stamina_depleted_delay_active = false
	stamina_regen_timer.stop()
#endregion

#region Damage
func hit(damage: float, attacker: CharacterBody3D) -> void:
	pass
#endregion
