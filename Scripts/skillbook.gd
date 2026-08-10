# skillbook.gd
class_name Skillbook
extends Resource

#region Element Skill Slots
@export var water_skills: Array[Skills]
@export var fire_skills: Array[Skills]
@export var light_skills: Array[Skills]
#endregion

#region Future Elements
@export var dark_skills: Array[Skills]
@export var ice_skills: Array[Skills]
#endregion

func get_skills_for_type(
	skill_type: Skills.SkillType
) -> Array[Skills]:
	match skill_type:
		Skills.SkillType.Water:
			return water_skills

		Skills.SkillType.Fire:
			return fire_skills

		Skills.SkillType.Light:
			return light_skills

		_:
			return []
