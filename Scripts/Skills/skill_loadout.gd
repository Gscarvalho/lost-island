class_name SkillLoadout
extends Resource

signal loadout_changed

enum Slot {
	X,
	Y,
	B,
	LT_X,
	LT_Y,
	LT_B,
}

@export_category("Skill Slots")

@export var x_skill: Skills
@export var y_skill: Skills
@export var b_skill: Skills

@export var lt_x_skill: Skills
@export var lt_y_skill: Skills
@export var lt_b_skill: Skills


func get_skill(slot: int) -> Skills:
	match slot:
		Slot.X:
			return x_skill

		Slot.Y:
			return y_skill

		Slot.B:
			return b_skill

		Slot.LT_X:
			return lt_x_skill

		Slot.LT_Y:
			return lt_y_skill

		Slot.LT_B:
			return lt_b_skill

		_:
			return null


func get_skill_slot(skill: Skills) -> int:
	if skill == null:
		return -1

	if x_skill == skill:
		return Slot.X

	if y_skill == skill:
		return Slot.Y

	if b_skill == skill:
		return Slot.B

	if lt_x_skill == skill:
		return Slot.LT_X

	if lt_y_skill == skill:
		return Slot.LT_Y

	if lt_b_skill == skill:
		return Slot.LT_B

	return -1


func assign_skill(
	skill: Skills,
	slot: int
) -> void:
	if skill == null:
		clear_slot(slot)
		return

	var previous_slot: int = (
		get_skill_slot(skill)
	)

	if previous_slot == slot:
		return

	if previous_slot != -1:
		_set_skill(
			previous_slot,
			null
		)

	_set_skill(
		slot,
		skill
	)

	loadout_changed.emit()


func clear_slot(slot: int) -> void:
	if get_skill(slot) == null:
		return

	_set_skill(
		slot,
		null
	)

	loadout_changed.emit()


func auto_assign(skill: Skills) -> bool:
	if skill == null:
		return false

	if get_skill_slot(skill) != -1:
		return false

	if x_skill == null:
		assign_skill(skill, Slot.X)
		return true

	if y_skill == null:
		assign_skill(skill, Slot.Y)
		return true

	if b_skill == null:
		assign_skill(skill, Slot.B)
		return true

	if lt_x_skill == null:
		assign_skill(skill, Slot.LT_X)
		return true

	if lt_y_skill == null:
		assign_skill(skill, Slot.LT_Y)
		return true

	if lt_b_skill == null:
		assign_skill(skill, Slot.LT_B)
		return true

	return false


func get_slot_name(slot: int) -> String:
	match slot:
		Slot.X:
			return "X"

		Slot.Y:
			return "Y"

		Slot.B:
			return "B"

		Slot.LT_X:
			return "RT + X"

		Slot.LT_Y:
			return "RT + Y"

		Slot.LT_B:
			return "RT + B"

		_:
			return "UNASSIGNED"


func _set_skill(
	slot: int,
	skill: Skills
) -> void:
	match slot:
		Slot.X:
			x_skill = skill

		Slot.Y:
			y_skill = skill

		Slot.B:
			b_skill = skill

		Slot.LT_X:
			lt_x_skill = skill

		Slot.LT_Y:
			lt_y_skill = skill

		Slot.LT_B:
			lt_b_skill = skill
