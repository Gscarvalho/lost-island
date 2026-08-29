# player_character.gd
class_name PlayerCharacter
extends Node3D

enum CombatMode {
	PHYSICAL,
	ELEMENTAL,
}

#region Signals
signal health_changed(
	current: float,
	maximum: float
)

signal stamina_changed(
	current: float,
	maximum: float
)

signal mana_changed(
	skill_type: Skills.SkillType,
	amount: float
)

signal mana_maximum_changed(
	skill_type: Skills.SkillType,
	maximum: float
)

signal combat_mode_changed(
	mode: CombatMode
)
#endregion

#region References
@onready var attack_state_machine = (
	$AnimationTree.get(
		"parameters/AttackStateMachine/playback"
	)
	as AnimationNodeStateMachinePlayback
)
@onready var magic_state_machine = (
	$AnimationTree.get(
		"parameters/MagicStateMachine/playback"
	)
	as AnimationNodeStateMachinePlayback
)
@onready var handslot_r: BoneAttachment3D = (
	$Rig/Skeleton3D/handslot_r
)
@onready var handslot_l: BoneAttachment3D = (
	$Rig/Skeleton3D/handslot_l
)
@onready var stamina_regen_timer: Timer = (
	$"../Timers/StaminaRegenTimer"
)
@onready var skill_vfx_hand_l: BoneAttachment3D = (
	$Rig/Skeleton3D/SkillVFXHandL
)
@onready var skill_vfx_hand_r: BoneAttachment3D = (
	$Rig/Skeleton3D/SkillVFXHandR
)
@onready var skill_vfx_foot_l: BoneAttachment3D = (
	$Rig/Skeleton3D/SkillVFXFootL
)
@onready var skill_vfx_foot_r: BoneAttachment3D = (
	$Rig/Skeleton3D/SkillVFXFootR
)

@onready var projectile_spawn: Marker3D = (
	%ProjectileSpawn
)
@onready var mobility_state_machine = (
	$AnimationTree.get(
		"parameters/MobilityStateMachine/playback"
	)
	as AnimationNodeStateMachinePlayback
)
@onready var player_hurtbox: Hurtbox = (
	$Hurtboxes/PlayerHurtbox
)
#endregion

#region Character Data
@export var base_stats: Stats
@export var damage_affinity: DamageAffinityProfile
@export var attacks: Array[Skills]
@export var skill_book: Skillbook
@export var starting_mana: float

var current_stats: Stats
var pending_projectile_skill: Skills
var pending_projectile_damage := 0.0

var air_used_skill_ids: Array[StringName] = []

var current_action_skill: Skills
var current_action_time := 0.0
#endregion

#region Equipment State
var combat_mode: CombatMode = CombatMode.PHYSICAL


func is_physical_mode() -> bool:
	return (
		combat_mode
		== CombatMode.PHYSICAL
	)


func set_combat_mode(
		mode: CombatMode
	) -> void:
		if combat_mode == mode:
			return

		combat_mode = mode

		handslot_r.visible = (
			is_physical_mode()
		)

		_refresh_equipment_stats()

		combat_mode_changed.emit(
			combat_mode
		)
#endregion

#region Mana
@export_category("Mana")

@export var mana_maximum_enabled := true

@export var mana_maximums: Array[float] = [
	10.0,
	10.0,
	10.0,
]

var mana_inventory: Array[float] = []

func get_mana_amount(
		skill_type: Skills.SkillType
	) -> float:
		var mana_index := _get_mana_index(
			skill_type
		)

		if mana_index == -1:
			return 0.0

		if mana_index >= mana_inventory.size():
			return starting_mana

		return mana_inventory[mana_index]

func get_mana_maximum(
		skill_type: Skills.SkillType
	) -> float:
		var mana_index := _get_mana_index(
			skill_type
		)

		if mana_index == -1:
			return 0.0

		if mana_index >= mana_maximums.size():
			return 0.0

		return mana_maximums[mana_index]

func set_mana_maximum(
	skill_type: Skills.SkillType,
	maximum: float
) -> void:
	var mana_index := _get_mana_index(
		skill_type
	)

	if mana_index == -1:
		return

	if mana_index >= mana_maximums.size():
		return

	mana_maximums[mana_index] = maxf(
		maximum,
		0.0
	)

	mana_maximum_changed.emit(
		skill_type,
		mana_maximums[mana_index]
	)

func change_mana(
	skill_type: Skills.SkillType,
	amount: float,
	respect_maximum := true
) -> void:
	var mana_index := _get_mana_index(
		skill_type
	)

	if mana_index == -1:
		return

	if mana_index >= mana_inventory.size():
		return

	var current_amount := (
		mana_inventory[mana_index]
	)

	var new_amount := maxf(
		current_amount + amount,
		0.0
	)

	var should_limit_gain := (
		amount > 0.0
		and mana_maximum_enabled
		and respect_maximum
	)

	if should_limit_gain:
		var maximum := get_mana_maximum(
			skill_type
		)

		if current_amount >= maximum:
			return

		new_amount = minf(
			new_amount,
			maximum
		)

	if is_equal_approx(
		current_amount,
		new_amount
	):
		return

	mana_inventory[mana_index] = (
		new_amount
	)

	mana_changed.emit(
		skill_type,
		new_amount
	)
#endregion

#region Vital Resources
var current_hp := 1.0:
	set(value):
		var max_hp := (
			current_stats.max_hp
			if current_stats != null
			else base_stats.max_hp
		)

		current_hp = clamp(
			value,
			0.0,
			max_hp
		)

		health_changed.emit(
			current_hp,
			max_hp
		)

var current_stamina := 1.0:
	set(value):
		current_stamina = clamp(
			value,
			0.0,
			100.0
		)

		stamina_changed.emit(
			current_stamina,
			100.0
		)
#endregion

#region Lifecycle
func _ready() -> void:
	mana_inventory = [
		starting_mana,
		starting_mana,
		starting_mana
	]
	
	player_hurtbox.hit_received.connect(
		_on_hurtbox_hit_received
	)
	current_stats = base_stats.duplicate()
	attacks = attacks.duplicate()
	handslot_r.visible = (
		is_physical_mode()
	)
	_refresh_equipment_stats()

	await get_tree().create_timer(0.5).timeout

	current_hp = current_stats.max_hp
	current_stamina = 100.0

func _process(
		delta: float
	) -> void:
		if current_action_skill == null:
			return

		if not is_action_animation_playing():
			return

		current_action_time += delta
#endregion

#region Action State
func is_action_animation_playing() -> bool:
	var attack_active: bool = $AnimationTree.get(
		"parameters/AttackOneShot/active"
	)

	var magic_active: bool = $AnimationTree.get(
		"parameters/MagicOneShot/active"
	)

	var mobility_active: bool = $AnimationTree.get(
		"parameters/MobilityOneShot/active"
	)

	return (
		attack_active
		or magic_active
		or mobility_active
	)

func can_interrupt_with(
		next_skill: Skills
	) -> bool:
		if next_skill == null:
			return false

		if not next_skill.can_interrupt_actions:
			return false

		if current_action_skill == null:
			return true

		var speed_stat := 0.0

		if current_stats != null:
			speed_stat = maxf(
				current_stats.speed,
				0.0
			)

		var speed_multiplier := (
			1.0
			+ speed_stat / 100.0
		)

		var required_time := (
			current_action_skill.interrupt_lock_time
			/ speed_multiplier
		)

		required_time = maxf(
			required_time,
			current_action_skill.interrupt_lock_floor
		)

		required_time = maxf(
			required_time,
			next_skill.interrupt_requirement
		)

		return (
			current_action_time
			>= required_time
		)
#endregion

#region Resource Costs
func _get_mana_index(skill_type: Skills.SkillType) -> int:
	match skill_type:
		Skills.SkillType.Water:
			return 0
		Skills.SkillType.Fire:
			return 1
		Skills.SkillType.Light:
			return 2
		_:
			return -1

func _can_afford_skill(skill: Skills) -> bool:
	if skill.skill_type == Skills.SkillType.Physical:
		return current_stamina >= skill.skill_cost

	return (
		get_mana_amount(skill.skill_type)
		>= skill.skill_cost
	)

func _pay_skill_cost(skill: Skills) -> void:
	if skill.skill_type == Skills.SkillType.Physical:
		current_stamina -= skill.skill_cost
		stamina_regen_timer.start()
		return

	change_mana(
		skill.skill_type,
		-skill.skill_cost
	)
#endregion

#region Skill Effects
func _apply_skill_effect(skill: Skills) -> void:
	match skill.skill_regen_type:
		Player.RegenType.Health:
			current_hp += (
				current_stats.max_hp
				* skill.skill_regen_power
				/ 100.0
			)

		Player.RegenType.Stamina:
			current_stamina += skill.skill_regen_power

		Player.RegenType.Mana:
			change_mana(
				skill.skill_type,
				skill.skill_regen_power
			)

func _play_skill_vfx(
		skill: Skills
	) -> void:
	if skill.activation_vfx_scene == null:
		return

	match skill.activation_vfx_attachment:
		Skills.VFXAttachment.Hands:
			_spawn_skill_vfx(
				skill.activation_vfx_scene,
				skill_vfx_hand_l
			)

			_spawn_skill_vfx(
				skill.activation_vfx_scene,
				skill_vfx_hand_r
			)

		Skills.VFXAttachment.Feet:
			_spawn_skill_vfx(
				skill.activation_vfx_scene,
				skill_vfx_foot_l
			)

			_spawn_skill_vfx(
				skill.activation_vfx_scene,
				skill_vfx_foot_r
			)

		Skills.VFXAttachment.Root:
			_spawn_skill_vfx(
				skill.activation_vfx_scene,
				self
			)

func _spawn_skill_vfx(
		vfx_scene: PackedScene,
		parent: Node3D
	) -> void:
	var effect := (
		vfx_scene.instantiate()
		as GPUParticles3D
	)

	if effect == null:
		return

	parent.add_child(
		effect
	)

	effect.finished.connect(
		func() -> void:
			effect.call_deferred(
				"queue_free"
			)
	)

	effect.restart()

func _apply_skill_movement(
		skill: Skills
	) -> void:
		var player := (
			get_parent() as Player
		)

		if player == null:
			return

		player.apply_skill_movement(
			skill
		)

func update_skill_usage_state(
		is_grounded: bool
	) -> void:
		if is_grounded:
			air_used_skill_ids.clear()

func _can_use_skill_here(
		skill: Skills
	) -> bool:
		var player := (
			get_parent() as Player
		)

		if player == null:
			return true

		if player.is_on_floor():
			return skill.can_use_on_ground

		match skill.air_use_rule:
			Skills.AirUseRule.Disabled:
				return false

			Skills.AirUseRule.OncePerAirtime:
				return not air_used_skill_ids.has(
					skill.skill_id
				)

			Skills.AirUseRule.Unlimited:
				return true

		return true

func _record_air_skill_use(
		skill: Skills
	) -> void:
		var player := (
			get_parent() as Player
		)

		if player == null:
			return

		if player.is_on_floor():
			return

		if (
			skill.air_use_rule
			!= Skills.AirUseRule.OncePerAirtime
		):
			return

		if air_used_skill_ids.has(
			skill.skill_id
		):
			return

		air_used_skill_ids.append(
			skill.skill_id
		)
#endregion

#region Combat Execution
func attack(skill: Skills) -> void:
	if skill == null:
		return
	if not _can_use_skill_here(skill):
		print(
			"Skill cannot be used here."
		)
		return
	if not _can_afford_skill(skill):
		if skill.skill_type == Skills.SkillType.Physical:
			print("Not enough stamina.")
		else:
			print("No mana.")

		return

	if (
		skill.skill_type
		== Skills.SkillType.Physical
		and skill.skill_power > 0.0
	):
		var weapon := get_equipped_weapon()

		if weapon != null:
			var damage := (
				calculate_skill_damage(
					skill
				)
			)

			weapon.prepare_attack(
				skill,
				damage
			)

	else:
		if skill.projectile_scene != null:
			pending_projectile_skill = (
				skill
			)

			pending_projectile_damage = (
				calculate_skill_damage(
					skill
				)
			)
	current_action_skill = skill
	current_action_time = 0.0
	
	_pay_skill_cost(skill)
	_apply_skill_effect(skill)
	_apply_skill_movement(skill)
	_play_skill_vfx(skill)
	_record_air_skill_use(skill)
	_play_skill_animation(skill)

	print(skill.skill_name)

func _play_skill_animation(
		skill: Skills
	) -> void:
		if (
			skill.animation_channel
			== Skills.AnimationChannel.Mobility
		):
			_play_mobility_animation(
				skill
			)

			return

		if skill.animation_state_name.is_empty():
			return

		if skill.skill_type == Skills.SkillType.Physical:
			attack_state_machine.travel(
				skill.animation_state_name
			)

			$AnimationTree.set(
				"parameters/AttackOneShot/request",
				AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
			)

		else:
			magic_state_machine.travel(
				skill.animation_state_name
			)

			$AnimationTree.set(
				"parameters/MagicOneShot/request",
				AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
			)

func _play_mobility_animation(
		skill: Skills
	) -> void:
		var animation_name := StringName(
			skill.animation_state_name
		)

		if skill.directional_animation:
			animation_name = (
				_get_directional_animation(
					skill
				)
			)

		if animation_name.is_empty():
			return

		mobility_state_machine.travel(
			animation_name
		)

		$AnimationTree.set(
			"parameters/MobilityOneShot/request",
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)

func _get_directional_animation(
		skill: Skills
	) -> StringName:
		var player := (
			get_parent() as Player
		)

		if player == null:
			return skill.animation_forward

		var local_direction := (
			player.get_local_movement_direction()
		)

		if (
			absf(local_direction.x)
			> absf(local_direction.z)
		):
			if local_direction.x > 0.0:
				return skill.animation_right

			return skill.animation_left

		if local_direction.z < 0.0:
			return skill.animation_back

		return skill.animation_forward

func interrupt_action_animation() -> void:
	$AnimationTree.set(
		"parameters/AttackOneShot/request",
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT
	)

	$AnimationTree.set(
		"parameters/MagicOneShot/request",
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT
	)
	
	$AnimationTree.set(
		"parameters/MobilityOneShot/request",
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT
	)

	end_weapon_damage_window()

	pending_projectile_skill = null
	pending_projectile_damage = 0.0

func start_weapon_damage_window() -> void:
	var weapon := get_equipped_weapon()

	if weapon == null:
		return

	weapon.start_damage_window()

func end_weapon_damage_window() -> void:
	var weapon := get_equipped_weapon()

	if weapon == null:
		return

	weapon.end_damage_window()

func release_projectile() -> void:
	if pending_projectile_skill == null:
		return

	if (
		pending_projectile_skill.projectile_scene
		== null
	):
		return

	var projectile := (
		pending_projectile_skill.projectile_scene.instantiate()
		as SkillProjectile
	)

	if projectile == null:
		return

	get_tree().current_scene.add_child(
		projectile
	)

	projectile.global_transform = (
		projectile_spawn.global_transform
	)

	var player := (
		get_parent() as Player
	)

	if player == null:
		return

	var travel_direction := (
		player.get_projectile_aim_point()
		- projectile_spawn.global_position
	).normalized()
	
	projectile.setup(
		self,
		pending_projectile_skill,
		pending_projectile_damage,
		travel_direction
	)

	pending_projectile_skill = null
	pending_projectile_damage = 0.0

func play_hit_reaction() -> void:
	interrupt_action_animation()

	current_action_skill = null
	current_action_time = 0.0

	attack_state_machine.travel(
		&"Hit"
	)

	$AnimationTree.set(
		"parameters/AttackOneShot/request",
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	)
#endregion

#region Equipment
func _refresh_equipment_stats() -> void:
	# Runtime stats are always rebuilt from base values so
	# equipment bonuses can never stack across loadout changes.
	current_stats = base_stats.duplicate()

	var current_weapon := get_equipped_weapon()

	if (
		current_weapon != null
		and is_physical_mode()
	):
		current_weapon.user = self

		if current_weapon.stats_boost != null:
			current_weapon.stats_boost.apply_to(
				current_stats
			)

	# Reapply HP through its setter so removing equipment that
	# lowers max HP cannot leave current HP above the new maximum.
	current_hp = current_hp

func get_equipped_weapon() -> Weapon:
	if handslot_r.get_child_count() == 0:
		return null

	return handslot_r.get_child(0) as Weapon

func has_equipped_weapon() -> bool:
	return get_equipped_weapon() != null
#endregion

#region Outgoing Damage Calculation
func calculate_skill_damage(
	skill: Skills
) -> float:
	if skill == null:
		return 0.0

	var offensive_stat: float

	if skill.skill_type == Skills.SkillType.Physical:
		offensive_stat = current_stats.attack
	else:
		offensive_stat = current_stats.m_attack

	var stat_multiplier := (
		1.0
		+ offensive_stat / 100.0
	)

	return (
		skill.skill_power
		* stat_multiplier
	)
#endregion

#region Incoming Damage
func _on_hurtbox_hit_received(
		damage_data: DamageData
	) -> void:
		var final_damage := (
			calculate_received_damage(
				damage_data
			)
		)

		take_damage(
			final_damage
		)

		play_hit_reaction()

		_apply_knockback(
			damage_data
		)

		_report_damage_result(
			damage_data,
			final_damage
		)

func _apply_knockback(
		damage_data: DamageData
	) -> void:
		var player := (
			get_parent() as Player
		)

		if player == null:
			return

		player.apply_knockback_from_damage(
			damage_data
		)

func _report_damage_result(
		damage_data: DamageData,
		final_damage: float
	) -> void:
		if damage_data == null:
			return

		if damage_data.source_actor == null:
			return

		if damage_data.source_skill == null:
			return

		if not is_instance_valid(
			damage_data.source_actor
		):
			return

		if not damage_data.source_actor.has_method(
			&"record_skill_damage_result"
		):
			return

		damage_data.source_actor.call(
			&"record_skill_damage_result",
			damage_data.source_skill,
			final_damage
		)

func take_damage(
		damage: float
	) -> void:
		if damage <= 0.0:
			return

		current_hp -= damage

func calculate_received_damage_result(
		damage_data: DamageData
	) -> DamageResult:
		return DamageResolver.resolve_damage(
			damage_data,
			current_stats,
			damage_affinity
		)

func calculate_received_damage(
		damage_data: DamageData
	) -> float:
		return (
			calculate_received_damage_result(
				damage_data
			)
			.final_damage
		)
#endregion
