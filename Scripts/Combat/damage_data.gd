class_name DamageData
extends RefCounted

var amount: float = 0.0

var source: Node
var source_skill: Skills
var source_weapon: Weapon
var hurtbox_id: StringName = &""
var hurtbox_multiplier: float = 1.0


func _init(
	damage_amount: float,
	damage_source: Node = null,
	skill: Skills = null,
	weapon: Weapon = null
) -> void:
	amount = maxf(
		damage_amount,
		0.0
	)

	source = damage_source
	source_skill = skill
	source_weapon = weapon
