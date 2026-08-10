# player_character.gd
class_name PlayerCharacter
extends Node3D
signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
@onready var attack_state_machine = $AnimationTree.get("parameters/AttackStateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var magic_state_machine = $AnimationTree.get("parameters/MagicStateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var handslot_r: BoneAttachment3D = $Rig/Skeleton3D/handslot_r
@onready var handslot_l: BoneAttachment3D = $Rig/Skeleton3D/handslot_l
@onready var ui = $"../PlayerUI" as UI
@onready var timers = $"../Timers" 
@export var base_stats: Stats

var current_stats: Stats
@export var attacks : Array[Skills]
@export var skill_book: Skillbook
var weapon_active:= true :
	set(value):
		weapon_active = value
		handslot_r.visible = value
		set_weapon()
var current_attack : Skills 
var mana_inventory := [7,7,7]
var mana_types:= [
	Skills.SkillType.Physical,
	Skills.SkillType.Water, 
	Skills.SkillType.Fire, 
	Skills.SkillType.Light,
	]
var current_mana_type : int = 0 :
	set(value):
		current_mana_type = value
		ui.update_slots(mana_types[value])
		if value == 0:
			weapon_active = true
		else:
			weapon_active = false
			
var current_hp := 1.0:
	set(value):
		current_hp = clamp(value, 0.0, base_stats.max_hp)
		ui.update_health(current_hp)
		health_changed.emit(current_hp, base_stats.max_hp)

var current_stamina := 1.0:
	set(value):
		current_stamina = clamp(value, 0.0, 100.0)
		ui.update_stamina(current_stamina)
		stamina_changed.emit(current_stamina, 100.0)

func _ready() -> void:
	current_stats = base_stats.duplicate()
	attacks = attacks.duplicate()

	set_weapon()

	await get_tree().create_timer(0.5).timeout

	current_hp = current_stats.max_hp
	current_stamina = 100.0
func is_action_animation_playing() -> bool:
	var attack_active: bool = $AnimationTree.get(
		"parameters/AttackOneShot/active"
	)

	var magic_active: bool = $AnimationTree.get(
		"parameters/MagicOneShot/active"
	)

	return attack_active or magic_active

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

	var mana_index := _get_mana_index(skill.skill_type)

	if mana_index == -1:
		return false

	return mana_inventory[mana_index] >= skill.skill_cost

func _pay_skill_cost(skill: Skills) -> void:
	if skill.skill_type == Skills.SkillType.Physical:
		current_stamina -= skill.skill_cost
		timers.get_node("StaminaRegenTimer").start()
		return

	var mana_index := _get_mana_index(skill.skill_type)

	if mana_index == -1:
		return

	mana_inventory[mana_index] -= skill.skill_cost
	ui.update_slots(skill.skill_type)

func attack() -> void:
	if current_attack == null:
		return

	if not _can_afford_skill(current_attack):
		if current_attack.skill_type == Skills.SkillType.Physical:
			print("Not enough stamina.")
		else:
			print("No mana.")

		return

	_pay_skill_cost(current_attack)
	_apply_skill_effect(current_attack)
	_play_skill_animation(current_attack)

	print(current_attack.skill_name)

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
			var mana_index := _get_mana_index(
				skill.skill_type
			)

			if mana_index == -1:
				return

			mana_inventory[mana_index] += (
				skill.skill_regen_power
			)

			ui.update_slots(skill.skill_type)

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

func set_weapon() -> void:
	var current_weapon := handslot_r.get_child(0) as Weapon

	current_weapon.user = get_parent()

	# Always rebuild current stats from the character's base values.
	# This prevents equipment bonuses from stacking repeatedly.
	current_stats = base_stats.duplicate()

	if not weapon_active:
		return

	for property in current_stats.get_property_list():
		if not property.usage & PROPERTY_USAGE_STORAGE:
			continue

		if typeof(current_stats.get(property.name)) != TYPE_FLOAT:
			continue

		if property.name not in current_weapon.stats_boost:
			continue

		current_stats.set(
			property.name,
			current_stats.get(property.name)
			+ current_weapon.stats_boost.get(property.name)
		)

func set_move_timescale(value: float) -> void:
	#$AnimationTree.set("parameters/MovementTimeScale/scale", value)
	Engine.time_scale = value
