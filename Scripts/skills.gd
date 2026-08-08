#skills.gd
class_name Skills
extends Resource
enum SkillType {
	Physical, Fire, Water, Light
}
enum RegenType {
	None, Health, Stamina, Mana
}
# Skill Identity
@export var skill_id: StringName
@export var skill_name: String
@export_multiline var skill_description: String
@export var skill_icon: Texture2D

# Skill Tree
@export var unlock_cost: int = 1

# Future progression support.
# We will NOT enforce prerequisites in the demo.
@export var prerequisite_ids: Array[StringName] = []

# Gameplay
@export var skill_power: float
@export var skill_anim_name: String
#Mana
@export var skill_type: SkillType
@export var skill_cost: float
@export var skill_regen_type: RegenType
@export var skill_regen_power: float
