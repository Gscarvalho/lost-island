class_name PlayerProgress
extends Resource

signal skill_points_changed(points: int)
signal skill_unlocked(skill_id: StringName)

@export_category("Progression")

@export_range(0, 999, 1)
var skill_points: int = 10

@export var unlocked_skill_ids: Array[StringName] = []

@export var skill_loadout: SkillLoadout

func is_skill_unlocked(skill: Skills) -> bool:
	if not _has_valid_skill_id(skill):
		return false

	return unlocked_skill_ids.has(
		skill.skill_id
	)


func can_unlock_skill(skill: Skills) -> bool:
	if not _has_valid_skill_id(skill):
		return false

	if is_skill_unlocked(skill):
		return false

	return (
		skill_points
		>= skill.unlock_cost
	)


func try_unlock_skill(skill: Skills) -> bool:
	if not can_unlock_skill(skill):
		return false

	skill_points -= skill.unlock_cost

	unlocked_skill_ids.append(
		skill.skill_id
	)

	if skill_loadout != null:
		skill_loadout.auto_assign(skill)

	skill_points_changed.emit(
		skill_points
	)

	skill_unlocked.emit(
		skill.skill_id
	)

	return true


func add_skill_points(amount: int) -> void:
	if amount <= 0:
		return

	skill_points += amount

	skill_points_changed.emit(
		skill_points
	)


func _has_valid_skill_id(skill: Skills) -> bool:
	return (
		skill != null
		and not skill.skill_id.is_empty()
	)
