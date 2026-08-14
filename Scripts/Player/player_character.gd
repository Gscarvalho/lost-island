# player_character.gd
class_name PlayerCharacter
extends Node3D

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

enum CombatMode {
	PHYSICAL,
	ELEMENTAL,
}

signal combat_mode_changed(
	mode: CombatMode
)
#endregion

#region References
@onready var attack_state_machine = (
	$AnimationTree.get("parameters/AttackStateMachine/playback")
	as AnimationNodeStateMachinePlayback
)
@onready var magic_state_machine = (
	$AnimationTree.get("parameters/MagicStateMachine/playback")
	as AnimationNodeStateMachinePlayback
)
@onready var handslot_r: BoneAttachment3D = (
	$Rig/Skeleton3D/handslot_r
)
@onready var stamina_regen_timer: Timer = (
	$"../Timers/StaminaRegenTimer"
)
#endregion

#region Character Data
@export var base_stats: Stats
@export var attacks: Array[Skills]
@export var skill_book: Skillbook

var current_stats: Stats
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

var mana_inventory: Array[float] = [
	7.0,
	7.0,
	7.0,
]

func get_mana_amount(
	skill_type: Skills.SkillType
) -> float:
	var mana_index := _get_mana_index(
		skill_type
	)

	if mana_index == -1:
		return 0.0

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
	current_stats = base_stats.duplicate()
	attacks = attacks.duplicate()
	handslot_r.visible = (
		is_physical_mode()
	)
	_refresh_equipment_stats()

	await get_tree().create_timer(0.5).timeout

	current_hp = current_stats.max_hp
	current_stamina = 100.0
#endregion

#region Action State
func is_action_animation_playing() -> bool:
	var attack_active: bool = $AnimationTree.get(
		"parameters/AttackOneShot/active"
	)

	var magic_active: bool = $AnimationTree.get(
		"parameters/MagicOneShot/active"
	)

	return attack_active or magic_active
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
		Skills.RegenType.Health:
			current_hp += (
				current_stats.max_hp
				* skill.skill_regen_power
				/ 100.0
			)

		Skills.RegenType.Stamina:
			current_stamina += skill.skill_regen_power

		Skills.RegenType.Mana:
			change_mana(
				skill.skill_type,
				skill.skill_regen_power
			)
#endregion

#region Combat Execution
func attack(skill: Skills) -> void:
	if skill == null:
		return

	if not _can_afford_skill(skill):
		if skill.skill_type == Skills.SkillType.Physical:
			print("Not enough stamina.")
		else:
			print("No mana.")

		return

	_pay_skill_cost(skill)
	_apply_skill_effect(skill)
	_play_skill_animation(skill)

	print(skill.skill_name)

func _play_skill_animation(skill: Skills) -> void:
	if skill.skill_type == Skills.SkillType.Physical:
		attack_state_machine.travel(
			skill.skill_anim_name
		)

		$AnimationTree.set(
			"parameters/AttackOneShot/request",
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)

	else:
		magic_state_machine.travel(
			skill.skill_anim_name
		)

		$AnimationTree.set(
			"parameters/MagicOneShot/request",
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
		current_weapon.user = (
			get_parent() as CharacterBody3D
		)

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
