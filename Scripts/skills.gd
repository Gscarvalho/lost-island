#skills.gd
class_name Skills
extends Resource
enum SkillType {
	Attack, Heal
}

@export var skill_name: String
@export var skill_anim_name: String
@export var skill_type: SkillType
@export var skill_power: float
