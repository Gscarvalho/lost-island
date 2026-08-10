# player_character.gd
class_name PlayerCharacter
extends Node3D

#region Signals
signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
#endregion

#region References
@onready var attack_state_machine = $AnimationTree.get("parameters/AttackStateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var magic_state_machine = $AnimationTree.get("parameters/MagicStateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var handslot_r: BoneAttachment3D = $Rig/Skeleton3D/handslot_r
@onready var handslot_l: BoneAttachment3D = $Rig/Skeleton3D/handslot_l
@onready var ui: PlayerHUD = (
	$"../PlayerUI"
)
@onready var stamina_regen_timer: Timer = (
	$"../Timers/StaminaRegenTimer"
)
#endregion

#region Character Data
@export var base_stats: Stats
@export var attacks : Array[Skills]
@export var skill_book: Skillbook

var current_stats: Stats
#endregion

#region Equipment State
var physical_mode_active:= true :
	set(value):
		physical_mode_active = value
		handslot_r.visible = value
		set_weapon()
#endregion

#region Combat State

#endregion

#region Mana
var mana_inventory: Array[float] = [
	7.0,
	7.0,
	7.0
]

func get_mana_amount(
	skill_type: Skills.SkillType
) -> float:
	var mana_index := _get_mana_index(skill_type)

	if mana_index == -1:
		return 0.0

	return mana_inventory[mana_index]

func change_mana(
	skill_type: Skills.SkillType,
	amount: float
) -> void:
	var mana_index := _get_mana_index(skill_type)

	if mana_index == -1:
		return

	mana_inventory[mana_index] = maxf(
		mana_inventory[mana_index] + amount,
		0.0
	)

	ui.update_slots(skill_type)

var mana_types:= [
	Skills.SkillType.Physical,
	Skills.SkillType.Water, 
	Skills.SkillType.Fire, 
	Skills.SkillType.Light,
]

var current_mana_type: int = 0:
	set(value):
		current_mana_type = value

		ui.update_slots(
			mana_types[value]
		)

		physical_mode_active = value == 0
#endregion

#region Vital Resources
var current_hp := 1.0:
	set(value):
		current_hp = clamp(
			value,
			0.0,
			current_stats.max_hp
			if current_stats != null
			else base_stats.max_hp
		)

		ui.update_health(current_hp)

		var max_hp := (
			current_stats.max_hp
			if current_stats != null
			else base_stats.max_hp
		)

		health_changed.emit(current_hp, max_hp)

var current_stamina := 1.0:
	set(value):
		current_stamina = clamp(value, 0.0, 100.0)
		ui.update_stamina(current_stamina)
		stamina_changed.emit(current_stamina, 100.0)
#endregion

#region Lifecycle
func _ready() -> void:
	current_stats = base_stats.duplicate()
	attacks = attacks.duplicate()

	set_weapon()

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

func get_current_skill_type() -> Skills.SkillType:
	return mana_types[current_mana_type]
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
func set_weapon() -> void:
	# Runtime stats are always rebuilt from base values so
	# equipment bonuses can never stack across loadout changes.
	current_stats = base_stats.duplicate()

	var current_weapon := get_equipped_weapon()

	if (
		current_weapon != null
		and physical_mode_active
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
	if ui.is_node_ready():
		current_hp = current_hp

func get_equipped_weapon() -> Weapon:
	if handslot_r.get_child_count() == 0:
		return null

	return handslot_r.get_child(0) as Weapon

func has_equipped_weapon() -> bool:
	return get_equipped_weapon() != null
#endregion

#region Time Scale
func set_move_timescale(value: float) -> void:
	Engine.time_scale = value
#endregion
