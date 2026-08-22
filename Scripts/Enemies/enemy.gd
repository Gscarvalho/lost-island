class_name Enemy
extends CharacterBody3D


signal health_changed(
	current: float,
	maximum: float
)

signal died

signal player_attack_received(
	player: Node3D
)

#region Data
@export_category("Combat")

@export var stats: Stats
@export var skill_loadout: EnemySkillLoadout

@export_category("Perception")

@export_flags_3d_physics var line_of_sight_mask := 49
@export var target_sight_height := 1.25
@export_range(1.0, 180.0, 1.0)
var view_angle := 220.0

@export_category("Movement")

@export var gravity_scale := 1.0

var gravity_strength := float(
	ProjectSettings.get_setting(
		"physics/3d/default_gravity"
	)
)

@export_category("Hit Reaction")

@export var hit_reaction_duration := 0.25
@export var knockback_deceleration := 18.0

var hit_reaction_left := 0.0
var knockback_velocity := Vector3.ZERO

var hit_source_position := Vector3.ZERO
var has_hit_source_position := false

var current_health := 0.0
var target: Node3D

var memory := EnemyMemory.new()
#endregion


#region References
@onready var visual: Node3D = (
	$Visual
)
@onready var body_hurtbox: Hurtbox = (
	$BodyHurtbox
)
@onready var sight_origin: Marker3D = (
	$Markers/SightOrigin
)
@onready var ui: EnemyUI = (
	$UI
)

var animation_tree: AnimationTree

var movement_state_machine: AnimationNodeStateMachinePlayback

var attack_state_machine: AnimationNodeStateMachinePlayback

#endregion


#region Lifecycle
func _ready() -> void:
	process_physics_priority = 10
	
	if stats != null:
		current_health = stats.max_hp
	
	health_changed.emit(
		current_health,
		get_max_health()
	)
	
	body_hurtbox.damage_receiver = self

	body_hurtbox.hit_received.connect(
		_on_hurtbox_hit_received
	)
	
	_setup_animation()

func _physics_process(
		delta: float
	) -> void:
		_apply_gravity(
			delta
		)

		_update_hit_reaction(
			delta
		)

		move_and_slide()

func _apply_gravity(
		delta: float
	) -> void:
		if is_on_floor():
			if velocity.y < 0.0:
				velocity.y = 0.0

			return

		velocity.y -= (
			gravity_strength
			* gravity_scale
			* delta
		)
#endregion


#region Animation
func _setup_animation() -> void:
	animation_tree = (
		visual.find_child(
			"AnimationTree",
			true,
			false
		) as AnimationTree
	)

	if animation_tree == null:
		return

	animation_tree.active = true

	movement_state_machine = (
		animation_tree.get(
			"parameters/MovementStateMachine/playback"
		)
		as AnimationNodeStateMachinePlayback
	)

	attack_state_machine = (
		animation_tree.get(
			"parameters/AttackStateMachine/playback"
		)
		as AnimationNodeStateMachinePlayback
	)


func play_movement_state(
		state_name: StringName
	) -> void:
		if movement_state_machine == null:
			return

		movement_state_machine.travel(
			state_name
		)

func play_attack_state(
		state_name: StringName
	) -> void:
		if attack_state_machine == null:
			return

		attack_state_machine.travel(
			state_name
		)

func play_skill_animation(
		skill: Skills
	) -> bool:
		if skill == null:
			return false

		if animation_tree == null:
			return false

		if attack_state_machine == null:
			return false

		if skill.animation_state_name.is_empty():
			return false

		attack_state_machine.travel(
			skill.animation_state_name
		)

		animation_tree.set(
			"parameters/AttackOneShot/request",
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)

		return true
#endregion


#region Target
func set_target(
		new_target: Node3D
	) -> void:
		target = new_target


func clear_target() -> void:
	target = null


func has_target() -> bool:
	return (
		is_instance_valid(target)
	)

func has_line_of_sight_to(
		target_node: Node3D
	) -> bool:
		if target_node == null:
			return false

		if sight_origin == null:
			return false

		var sight_start := (
			sight_origin.global_position
		)

		var sight_end := (
			target_node.global_position
			+ Vector3.UP * target_sight_height
		)

		var query := (
			PhysicsRayQueryParameters3D.create(
				sight_start,
				sight_end,
				line_of_sight_mask,
				[get_rid()]
			)
		)

		var result := (
			get_world_3d()
			.direct_space_state
			.intersect_ray(
				query
			)
		)

		if result.is_empty():
			return false

		return (
			result["collider"]
			== target_node
		)

func is_target_in_view(
	target_node: Node3D
) -> bool:
	if target_node == null:
		return false

	if sight_origin == null:
		return false

	var forward := (
		-sight_origin.global_transform.basis.z
	)

	if forward.is_zero_approx():
		return false

	forward = forward.normalized()

	var target_position := (
		target_node.global_position
		+ Vector3.UP * target_sight_height
	)

	var to_target := (
		target_position
		- sight_origin.global_position
	)

	if to_target.is_zero_approx():
		return true

	var target_direction := (
		to_target.normalized()
	)

	var minimum_dot := cos(
		deg_to_rad(
			view_angle * 0.5
		)
	)

	return (
		forward.dot(
			target_direction
		)
		>= minimum_dot
	)

func can_see_target(
		target_node: Node3D
	) -> bool:
		if not is_target_in_view(
			target_node
		):
			return false

		return has_line_of_sight_to(
			target_node
		)
#endregion


#region Memory
func _record_attack_memory(
		damage_data: DamageData
	) -> void:
		if damage_data == null:
			return

		var player := _get_player_from_node(
			damage_data.source_actor
		)

		if player == null:
			return

		memory.remember_player_attack(
			player.global_position
		)

		player_attack_received.emit(
			player
		)


func _get_player_from_node(
		node: Node
	) -> Node3D:
		var current_node := node

		while current_node != null:
			if current_node.is_in_group(
				"Player"
			):
				return current_node as Node3D

			current_node = (
				current_node.get_parent()
			)

		return null
#endregion


#region Hit Reaction
func _start_hit_reaction(
		damage_data: DamageData
	) -> void:
		if damage_data == null:
			return

		var source_node := (
			_get_damage_source_3d(
				damage_data
			)
		)

		if source_node == null:
			return

		hit_source_position = (
			source_node.global_position
		)

		has_hit_source_position = true

		_face_hit_source()

		var away_direction := (
			global_position
			- hit_source_position
		)

		away_direction.y = 0.0

		if (
			away_direction.length_squared()
			<= 0.0001
		):
			return

		var strength := maxf(
			damage_data.knockback_strength,
			0.0
		)

		if strength <= 0.0:
			return

		knockback_velocity = (
			away_direction.normalized()
			* strength
		)

		hit_reaction_left = (
			hit_reaction_duration
		)


func _update_hit_reaction(
		delta: float
	) -> void:
		if not is_in_hit_reaction():
			return

		_face_hit_source()

		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z

		knockback_velocity = (
			knockback_velocity.move_toward(
				Vector3.ZERO,
				knockback_deceleration
				* delta
			)
		)

		hit_reaction_left = maxf(
			hit_reaction_left - delta,
			0.0
		)

		if hit_reaction_left > 0.0:
			return

		knockback_velocity = Vector3.ZERO

		velocity.x = 0.0
		velocity.z = 0.0

		has_hit_source_position = false


func _face_hit_source() -> void:
		if not has_hit_source_position:
			return

		var direction := (
			hit_source_position
			- global_position
		)

		direction.y = 0.0

		if (
			direction.length_squared()
			<= 0.0001
		):
			return

		rotation.y = atan2(
			-direction.x,
			-direction.z
		)


func _get_damage_source_3d(
		damage_data: DamageData
	) -> Node3D:
		var actor := (
			damage_data.source_actor
			as Node3D
		)

		if actor != null:
			return actor

		return (
			damage_data.source
			as Node3D
		)


func is_in_hit_reaction() -> bool:
		return (
			hit_reaction_left > 0.0
		)
#endregion


#region Damage
func _on_hurtbox_hit_received(
		damage_data: DamageData
	) -> void:
		_start_hit_reaction(
			damage_data
		)
		
		_record_attack_memory(
			damage_data
		)
		
		var final_damage := (
			calculate_received_damage(
				damage_data
			)
		)

		take_damage(
			final_damage
		)
		
		ui.display_damage(
			final_damage
		)

func take_damage(
		damage: float
	) -> void:
		if damage <= 0.0:
			return

		current_health = maxf(
			current_health - damage,
			0.0
		)

		health_changed.emit(
			current_health,
			get_max_health()
		)

		print(
			"Enemy HP: ",
			current_health
		)

		if current_health <= 0.0:
			die()

func calculate_received_damage(
		damage_data: DamageData
	) -> float:
		if damage_data == null:
			return 0.0

		if stats == null:
			return damage_data.amount

		var defense_value := 0.0

		match damage_data.damage_type:
			DamageData.DamageType.PHYSICAL:
				defense_value = stats.defense

			_:
				defense_value = stats.m_defense

		defense_value = maxf(
			defense_value,
			0.0
		)

		return (
			damage_data.amount
			* 100.0
			/ (100.0 + defense_value)
		)

func get_max_health() -> float:
	if stats == null:
		return 0.0

	return stats.max_hp

func die() -> void:
	died.emit()

	queue_free()
#endregion


#region Weapons
func get_equipped_weapons() -> Array[Weapon]:
	var weapons: Array[Weapon] = []

	if visual == null:
		return weapons

	var found_nodes := visual.find_children(
		"*",
		"",
		true,
		false
	)

	for node in found_nodes:
		var weapon := node as Weapon

		if weapon == null:
			continue

		weapons.append(
			weapon
		)

	return weapons

func prepare_weapon_attack(
		skill: Skills
	) -> void:
		if skill == null:
			return

		var damage := calculate_skill_damage(
			skill
		)

		for weapon in get_equipped_weapons():
			weapon.user = self

			weapon.prepare_attack(
				skill,
				damage
			)

func calculate_skill_damage(
		skill: Skills
	) -> float:
		if skill == null:
			return 0.0

		if stats == null:
			return skill.skill_power

		var offensive_stat: float

		if (
			skill.skill_type
			== Skills.SkillType.Physical
		):
			offensive_stat = stats.attack
		else:
			offensive_stat = stats.m_attack

		var stat_multiplier := (
			1.0
			+ offensive_stat / 100.0
		)

		return (
			skill.skill_power
			* stat_multiplier
		)

func start_weapon_damage_window() -> void:
	for weapon in get_equipped_weapons():
		weapon.start_damage_window()

func end_weapon_damage_window() -> void:
	for weapon in get_equipped_weapons():
		weapon.end_damage_window()
#endregion


#region Skills
func get_loadout_skills() -> Array[Skills]:
	if skill_loadout == null:
		return []

	return skill_loadout.get_valid_skills()


func get_loadout_skill(
	index: int
) -> Skills:
	if skill_loadout == null:
		return null

	return skill_loadout.get_skill(
		index
	)


func get_default_skill() -> Skills:
	if skill_loadout == null:
		return null

	return skill_loadout.get_default_skill()
#endregion
