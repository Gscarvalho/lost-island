#player.gd
class_name Player
extends CharacterBody3D

#region References
@export var progression: PlayerProgress

@onready var camera: Camera3D = (
	%PlayerCamera.get_node(
		"SpringArm3D/CameraMount/ShakePivot/Camera3D"
	)
)

@onready var camera_controller: PlayerCamera = (
	%PlayerCamera
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

@onready var weapon_choice_cooldown_timer: Timer = (
	$Timers/WeaponChoiceCooldownTimer
)

@onready var menu_transition_timer: Timer = (
	$Timers/MenuTransitionTimer
)
#endregion

#region Movement Configuration
var walk_speed: float = 5.5
var run_speed: float = 8.5
var speed_modifier: float = 1.0
var stamina_cost_reduction: float = 1.0

var movement_velocity := Vector2.ZERO

var burst_velocity := Vector3.ZERO
var burst_start_speed := 0.0
var burst_duration := 0.0
var burst_time_left := 0.0
#endregion

#region Jump Configuration
var jump_height: float = 3.5
var jump_time_to_peak: float = 0.4
var jump_time_to_descent: float = 0.3

@onready var jump_velocity: float = (
	(2.0 * jump_height) / jump_time_to_peak
) * -1.0

@onready var jump_gravity: float = (
	(-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
) * -1.0

@onready var fall_gravity: float = (
	(-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)
) * -1.0
#endregion

#region Runtime State
var movement_input := Vector2.ZERO
var is_running := false
var stamina_depleted_delay_active := false

@export_range(0.1, 0.5, 0.01)
var weapon_choice_hold_threshold: float = 0.2

var swap_hold_time: float = 0.0
var swap_press_consumed := false
#endregion

#region Lifecycle
func _enter_tree() -> void:
	if progression != null:
		progression = (
			progression.duplicate(true)
			as PlayerProgress
		)


func _ready() -> void:
	StateManager.state_changed.connect(
		_on_state_changed
	)

	_on_state_changed(
		StateManager.current_state
	)


func _physics_process(delta: float) -> void:
	
	if Input.is_physical_key_pressed(
		KEY_P
	):
		if burst_time_left <= 0.0:
			push_movement_direction(
				18.0,
				0.18
			)
	
	_menu_logic()
	_equip_logic(delta)
	_move_logic(delta)
	_burst_logic(delta)
	_apply_horizontal_velocity()

	_jump_logic(delta)
	
	_aim_logic()
	_update_projectile_aim_point()
	
	character.update_skill_usage_state(
		is_on_floor()
	)
	
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
#endregion

#region Weapon Selection
func _equip_logic(delta: float) -> void:
	if (
		Input.is_action_just_pressed("swap")
		and StateManager.current_state == StateManager.State.PLAY
	):
		swap_hold_time = 0.0
		swap_press_consumed = false

	if (
		Input.is_action_pressed("swap")
		and StateManager.current_state == StateManager.State.PLAY
		and not swap_press_consumed
	):
		swap_hold_time += delta

		var can_open_selector := (
			swap_hold_time
			>= weapon_choice_hold_threshold
			and weapon_choice_cooldown_timer.is_stopped()
		)

		if can_open_selector:
			swap_press_consumed = true
			_open_weapon_choice()

	if Input.is_action_just_released("swap"):
		if StateManager.current_state == StateManager.State.WEAPON:
			_close_weapon_choice()

		elif (
			StateManager.current_state == StateManager.State.PLAY
			and not swap_press_consumed
			and swap_hold_time
			< weapon_choice_hold_threshold
		):
			_toggle_combat_mode()

		swap_hold_time = 0.0
		swap_press_consumed = false

	if StateManager.current_state != StateManager.State.WEAPON:
		return

	var cycle_combat_mode := (
		Input.is_action_just_pressed(
			"menu_left"
		)
		or Input.is_action_just_pressed(
			"menu_right"
		)
	)

	if cycle_combat_mode:
		_toggle_combat_mode()
		
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

func _toggle_combat_mode() -> void:
	match character.combat_mode:
		PlayerCharacter.CombatMode.PHYSICAL:
			character.set_combat_mode(
				PlayerCharacter.CombatMode.ELEMENTAL
			)

		PlayerCharacter.CombatMode.ELEMENTAL:
			character.set_combat_mode(
				PlayerCharacter.CombatMode.PHYSICAL
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
	
	weapon_choice_cooldown_timer.start()

func _on_weapon_choice_timer_timeout() -> void:
	if StateManager.current_state != StateManager.State.WEAPON:
		return

	_close_weapon_choice()
#endregion

#region Combat
func _attacks_logic() -> void:
	if StateManager.current_state != StateManager.State.PLAY:
		return

	var slot := (
		_get_loadout_input_slot()
	)

	if slot == -1:
		return

	var loadout := (
		_get_active_combat_loadout()
	)

	if loadout == null:
		return

	_try_loadout_skill(
		loadout,
		slot
	)

func _try_attack(
	attack_list: Array[Skills],
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

func _get_attack_input_index() -> int:
	var index_offset := (
		2
		if Input.is_action_pressed(
			"loadout_modifier"
		)
		else 0
	)

	if Input.is_action_just_pressed(
			"attack"
		):
		return index_offset

	if Input.is_action_just_pressed(
			"skill"
		):
		return index_offset + 1

	return -1

func _handle_physical_attack() -> void:
	if not character.has_equipped_weapon():
		return

	var attack_index := (
		_get_attack_input_index()
	)

	if attack_index == -1:
		return

	_try_attack(
		character.attacks,
		attack_index
	)

func _get_active_combat_loadout() -> SkillLoadout:
	if character.is_physical_mode():
		return progression.physical_loadout

	return progression.skill_loadout

#func _handle_loadout_skill() -> void:
	#var slot := (
		#_get_loadout_input_slot()
	#)
#
	#if slot == -1:
		#return
#
	#_try_loadout_skill(slot)

func _try_loadout_skill(
		loadout: SkillLoadout,
		slot: int
	) -> void:
		var selected_skill := (
			loadout.get_skill(slot)
		)

		if selected_skill == null:
			print("No skill assigned.")
			return

		if character.is_action_animation_playing():
			if not selected_skill.can_interrupt_actions:
				print("Attack already in progress.")
				return

			character.interrupt_action_animation()

		character.attack(
			selected_skill
		)

func _get_loadout_input_slot() -> int:
	var modifier_active := (
		Input.is_action_pressed(
			"loadout_modifier"
		)
	)

	if Input.is_action_just_pressed("attack"):
		return (
			SkillLoadout.Slot.RT_X
			if modifier_active
			else SkillLoadout.Slot.X
		)

	if Input.is_action_just_pressed("skill"):
		return (
			SkillLoadout.Slot.RT_Y
			if modifier_active
			else SkillLoadout.Slot.Y
		)

	if Input.is_action_just_pressed("combat_b"):
		return (
			SkillLoadout.Slot.RT_B
			if modifier_active
			else SkillLoadout.Slot.B
		)

	return -1

func apply_skill_movement(
		skill: Skills
	) -> void:
		if skill == null:
			return

		var direction := Vector3.ZERO

		match skill.movement_direction:
			Skills.MovementDirection.InputOrFacing:
				direction = get_movement_direction()

			Skills.MovementDirection.Facing:
				direction = get_facing_direction()

			Skills.MovementDirection.None:
				pass

		if (
			direction != Vector3.ZERO
			and skill.movement_speed > 0.0
			and skill.movement_duration > 0.0
		):
			push(
				direction,
				skill.movement_speed,
				skill.movement_duration
			)

		if skill.movement_vertical_speed > 0.0:
			velocity.y = maxf(
				velocity.y,
				skill.movement_vertical_speed
			)
#endregion

#region Aim
func _aim_logic() -> void:
	var should_aim := (
		StateManager.current_state
		== StateManager.State.PLAY
		and Input.is_action_pressed(
			"aim"
		)
	)

	camera_controller.set_aiming(
		should_aim
	)

func _update_projectile_aim_point() -> void:
	var screen_center := (
		get_viewport().get_visible_rect().size
		* 0.5
	)

	var ray_origin := (
		camera.project_ray_origin(
			screen_center
		)
	)

	var ray_direction := (
		camera.project_ray_normal(
			screen_center
		).normalized()
	)

	var ray_end := (
		ray_origin
		+ ray_direction
		* projectile_aim_distance
	)

	var query := (
		PhysicsRayQueryParameters3D.create(
			ray_origin,
			ray_end
		)
	)
	
	query.collide_with_areas = true
	
	query.exclude = [
		get_rid()
	]

	var result := (
		get_world_3d()
		.direct_space_state
		.intersect_ray(query)
	)

	if result.is_empty():
		projectile_aim_point = ray_end
		return

	var hit_position: Vector3 = (
		result["position"]
	)

	var hit_distance := (
		ray_origin.distance_to(
			hit_position
		)
	)

	if (
		hit_distance
		< minimum_projectile_aim_distance
	):
		projectile_aim_point = (
			ray_origin
			+ ray_direction
			* minimum_projectile_aim_distance
		)

		return

	projectile_aim_point = (
		hit_position
	)


func get_projectile_aim_point() -> Vector3:
	return projectile_aim_point
#endregion

#region Aim Configuration
@export_range(1.0, 500.0, 1.0)
var projectile_aim_distance: float = 100.0

var projectile_aim_point := Vector3.ZERO

@export_range(1.0, 50.0, 0.5)
var minimum_projectile_aim_distance: float = 8.0
#endregion

#region Movement
func _move_logic(delta: float) -> void:
	if StateManager.current_state == StateManager.State.MENU:
		velocity = Vector3.ZERO
		return

	if StateManager.current_state != StateManager.State.PLAY:
		return

	movement_input = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	).rotated(
		-camera.global_rotation.y
	)

	var horizontal_velocity := (
		movement_velocity
	)

	if is_on_floor():
		is_running = Input.is_action_pressed("run")

	if movement_input != Vector2.ZERO:
		var move_speed := (
			run_speed
			if is_running
			else walk_speed
		)

		horizontal_velocity += (
			movement_input
			* move_speed
			* delta
			* 10.0
		)

		horizontal_velocity = (
			horizontal_velocity.limit_length(move_speed)
			* speed_modifier
		)

	else:
		horizontal_velocity = horizontal_velocity.move_toward(
			Vector2.ZERO,
			walk_speed * 8.0
		)

	movement_velocity = (
		horizontal_velocity
	)
	
	_update_character_facing(
		delta
	)

func _update_character_facing(
		delta: float
	) -> void:
		var aim_active := (
			Input.is_action_pressed(
				"aim"
			)
		)

		if aim_active:
			var aim_angle := (
				camera.global_rotation.y
				+ PI
			)

			character.rotation.y = (
				rotate_toward(
					character.rotation.y,
					aim_angle,
					10.0 * delta
				)
			)

			return

		if movement_input == Vector2.ZERO:
			return

		var movement_angle := (
			-movement_input.angle()
			+ PI / 2.0
		)

		character.rotation.y = (
			rotate_toward(
				character.rotation.y,
				movement_angle,
				6.0 * delta
			)
		)

func get_facing_direction() -> Vector3:
	var direction := (
		character.global_transform.basis.z
	)

	direction.y = 0.0

	return direction.normalized()

func get_local_movement_direction() -> Vector3:
	var world_direction := (
		get_movement_direction()
	)

	return (
		character.global_transform.basis.inverse()
		* world_direction
	).normalized()

func get_movement_direction() -> Vector3:
	if movement_input == Vector2.ZERO:
		return get_facing_direction()

	return Vector3(
		movement_input.x,
		0.0,
		movement_input.y
	).normalized()

func push_movement_direction(
		speed: float,
		duration: float
	) -> void:
		push(
			get_movement_direction(),
			speed,
			duration
		)

func push(
		direction: Vector3,
		speed: float,
		duration: float
	) -> void:
		var horizontal_direction := Vector3(
			direction.x,
			0.0,
			direction.z
		)

		if horizontal_direction.is_zero_approx():
			return

		if speed <= 0.0:
			return

		if duration <= 0.0:
			return

		burst_start_speed = speed
		burst_duration = duration
		burst_time_left = duration

		burst_velocity = (
			horizontal_direction.normalized()
			* speed
		)

func _burst_logic(
		delta: float
	) -> void:
		if burst_time_left <= 0.0:
			burst_velocity = Vector3.ZERO
			return

		burst_time_left = maxf(
			burst_time_left - delta,
			0.0
		)

		var remaining_ratio := (
			burst_time_left
			/ burst_duration
		)

		var current_speed := (
			burst_start_speed
			* remaining_ratio
		)

		burst_velocity = (
			burst_velocity.normalized()
			* current_speed
		)

func _apply_horizontal_velocity() -> void:
	velocity.x = (
		movement_velocity.x
		+ burst_velocity.x
	)

	velocity.z = (
		movement_velocity.y
		+ burst_velocity.z
	)

func _jump_logic(delta: float) -> void:
	if StateManager.current_state != StateManager.State.PLAY:
		return

	var can_jump := (
		Input.is_action_just_pressed("jump")
		and is_on_floor()
		and character.current_stamina >= 1.0
	)

	if can_jump:
		velocity.y = -jump_velocity
		character.current_stamina -= (
			1.0 * stamina_cost_reduction
		)
		stamina_regen_timer.start()

	var gravity := (
		jump_gravity
		if velocity.y > 0.0
		else fall_gravity
	)

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
func hit(
	_damage: float,
	_attacker: CharacterBody3D
) -> void:
	# TODO: Implement player damage handling.
	pass
#endregion
