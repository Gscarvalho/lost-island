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
@export var stats: Stats

@export_category("Perception")

@export_flags_3d_physics var line_of_sight_mask := 49
@export var target_sight_height := 1.25

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
var animation_state: AnimationNodeStateMachinePlayback
#endregion


#region Lifecycle
func _ready() -> void:
	if stats != null:
		current_health = stats.max_hp

	body_hurtbox.damage_receiver = self

	body_hurtbox.hit_received.connect(
		_on_hurtbox_hit_received
	)
	
	_setup_animation()
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

	animation_state = (
		animation_tree.get(
			"parameters/StateMachine/playback"
		)
		as AnimationNodeStateMachinePlayback
	)


func play_animation_state(
		state_name: StringName
	) -> void:
		if animation_state == null:
			return

		animation_state.travel(
			state_name
		)
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

#region Damage
func _on_hurtbox_hit_received(
		damage_data: DamageData
	) -> void:
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
		
		ui._display_damage_for_seconds(final_damage)

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
