#skills.gd
class_name Skills
extends Resource
enum SkillType {
	Physical, Fire, Water, Light
}
enum RegenType {
	None, Health, Stamina, Mana
}

#skill Basics
@export var skill_name: String
@export var skill_power: float
@export var skill_anim_name: String
#Mana
@export var skill_type: SkillType
@export var skill_cost: float
@export var skill_regen_type: RegenType
@export var skill_regen_power: float
