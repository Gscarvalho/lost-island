class_name EnemySkillLoadout
extends Resource


@export_category("Skill Options")

## All skills this enemy is allowed to choose from.
##
## Each entry is an EnemySkillOption containing:
## - the actual Skills resource,
## - its base preference,
## - pressure response,
## - and usable/preferred distances.
##
## The array order does NOT determine priority.
## The priority system scores all valid ready options.
@export var options: Array[EnemySkillOption] = []


func get_option(
	index: int
) -> EnemySkillOption:
	if index < 0:
		return null

	if index >= options.size():
		return null

	return options[index]


func get_valid_options() -> Array[EnemySkillOption]:
	var valid_options: Array[EnemySkillOption] = []

	for option in options:
		if option == null:
			continue

		if option.skill == null:
			continue

		valid_options.append(
			option
		)

	return valid_options


func get_skill(
	index: int
) -> Skills:
	var option := get_option(
		index
	)

	if option == null:
		return null

	return option.skill


func get_valid_skills() -> Array[Skills]:
	var valid_skills: Array[Skills] = []

	for option in get_valid_options():
		valid_skills.append(
			option.skill
		)

	return valid_skills


func get_default_skill() -> Skills:
	for option in get_valid_options():
		return option.skill

	return null


func has_skill(
	skill: Skills
) -> bool:
	if skill == null:
		return false

	for option in get_valid_options():
		if option.skill == skill:
			return true

	return false
