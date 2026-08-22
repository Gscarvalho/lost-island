class_name EnemySkillLoadout
extends Resource


@export_category("Skills")

@export var skills: Array[Skills] = []


func get_skill(
	index: int
) -> Skills:
	if index < 0:
		return null

	if index >= skills.size():
		return null

	return skills[index]


func get_valid_skills() -> Array[Skills]:
	var valid_skills: Array[Skills] = []

	for skill in skills:
		if skill == null:
			continue

		valid_skills.append(
			skill
		)

	return valid_skills


func get_default_skill() -> Skills:
	for skill in skills:
		if skill != null:
			return skill

	return null


func has_skill(
	skill: Skills
) -> bool:
	if skill == null:
		return false

	return skills.has(
		skill
	)
