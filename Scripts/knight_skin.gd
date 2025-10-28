#knight_skin.gd
class_name PlayerSkin
extends Node3D
@onready var attack_state_machine = $AnimationTree.get("parameters/AttackStateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var magic_state_machine = $AnimationTree.get("parameters/MagicStateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var handslot_r: BoneAttachment3D = $Rig/Skeleton3D/handslot_r
@onready var handslot_l: BoneAttachment3D = $Rig/Skeleton3D/handslot_l
@onready var ui = $"../PlayerUI" as UI
@onready var timers = $"../Timers" 
@export var base_stats: Stats
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
		current_hp = value
		current_hp = clamp(current_hp, 0.0, base_stats.max_hp)
		ui.update_health(value)
var current_stamina := 1.0:
	set(value):
		current_stamina = value
		ui.update_stamina(value)

func _ready() -> void:
	base_stats = base_stats.duplicate()
	attacks = attacks.duplicate()
	set_weapon()
	await get_tree().create_timer(0.5).timeout
	current_hp = base_stats.max_hp
	current_stamina = 100.0
	
func attack() -> void:
	if current_attack.skill_regen_type != Skills.RegenType.None:
		if current_attack.skill_regen_type == Skills.RegenType.Health:
			current_hp += base_stats.max_hp * (current_attack.skill_regen_power/100)
			print("Healed ",str(current_attack.skill_regen_power).pad_decimals(0),"%!")
		elif current_attack.skill_regen_type == Skills.RegenType.Stamina:
			current_stamina += current_attack.skill_regen_power
			print("Regenerated ",str(current_attack.skill_regen_power).pad_decimals(0)," stamina!")
		elif current_attack.skill_regen_type == Skills.RegenType.Mana:
			if current_attack.skill_type == Skills.SkillType.Water:
				mana_inventory[0] += current_attack.skill_regen_power
				print("Regenerated ",str(current_attack.skill_regen_power).pad_decimals(0)," of water mana!")
			elif current_attack.skill_type == Skills.SkillType.Fire:
				mana_inventory[1] += current_attack.skill_regen_power
				print("Regenerated ",str(current_attack.skill_regen_power).pad_decimals(0)," of fire mana!")
			elif current_attack.skill_type == Skills.SkillType.Light:
				mana_inventory[2] += current_attack.skill_regen_power
				print("Regenerated ",str(current_attack.skill_regen_power).pad_decimals(0)," of light mana!")

	if current_attack.skill_type == Skills.SkillType.Physical and current_stamina >= current_attack.skill_cost:
		attack_state_machine.travel(current_attack.skill_anim_name)
		$AnimationTree.set("parameters/AttackOneShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		current_stamina -= current_attack.skill_cost
		timers.get_node("StaminaRegenTimer").start()
		
	elif current_attack.skill_type != Skills.SkillType.Physical:
		if current_attack.skill_type == Skills.SkillType.Water and mana_inventory[0] >= current_attack.skill_cost:
			mana_inventory[0] -= current_attack.skill_cost
		elif current_attack.skill_type == Skills.SkillType.Fire and mana_inventory[1] >= current_attack.skill_cost:
			mana_inventory[1] -= current_attack.skill_cost
		elif current_attack.skill_type == Skills.SkillType.Light and mana_inventory[2] >= current_attack.skill_cost:
			mana_inventory[2] -= current_attack.skill_cost
		else:
			print("no mana")
		magic_state_machine.travel(current_attack.skill_anim_name)
		$AnimationTree.set("parameters/MagicOneShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		print(current_attack.skill_name)
	
	else:
		print("no mana")
		return

func set_weapon() -> void:
	var current_weapon = handslot_r.get_child(0) as Weapon
	current_weapon.user = self.get_parent()
	var original_stats = base_stats.duplicate()
	if weapon_active:
		for prop in base_stats.get_property_list():
			if prop.usage & PROPERTY_USAGE_STORAGE and typeof(base_stats.get(prop.name)) == TYPE_FLOAT:
				if prop.name in current_weapon.stats_boost:
					base_stats.set(prop.name, base_stats.get(prop.name) + current_weapon.stats_boost.get(prop.name))
	else:
		base_stats = original_stats
		#for prop in base_stats.get_property_list():
			#if prop.usage & PROPERTY_USAGE_STORAGE and typeof(base_stats.get(prop.name)) == TYPE_FLOAT:
				#if prop.name in current_weapon.stats_boost:
					#base_stats.set(prop.name, base_stats.get(prop.name) - current_weapon.stats_boost.get(prop.name))
		

func set_move_timescale(value: float) -> void:
	$AnimationTree.set("parameters/MovementTimeScale/scale", value)
