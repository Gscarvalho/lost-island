class_name PlayerProgress
extends Resource

signal skill_points_changed(points: int)
signal skill_unlocked(skill_id: StringName)

@export var skill_points: int = 10
@export var unlocked_skill_ids: Array[StringName] = []


func is_skill_unlocked(skill: Skills) -> bool:
	if skill == null:
		return false

	return unlocked_skill_ids.has(skill.skill_id)


func can_unlock_skill(skill: Skills) -> bool:
	if skill == null:
		return false

	if is_skill_unlocked(skill):
		return false

	return skill_points >= skill.unlock_cost


func try_unlock_skill(skill: Skills) -> bool:
	if not can_unlock_skill(skill):
		return false

	skill_points -= skill.unlock_cost
	unlocked_skill_ids.append(skill.skill_id)

	skill_points_changed.emit(skill_points)
	skill_unlocked.emit(skill.skill_id)

	return true
