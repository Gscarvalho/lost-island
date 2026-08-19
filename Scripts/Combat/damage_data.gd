class_name DamageData
extends RefCounted

enum DamageType {
	PHYSICAL,
	FIRE,
	WATER,
	LIGHT,
}

var amount: float = 0.0

var source: Node
var source_actor: Node
var source_skill: Skills
var source_weapon: Weapon
var hurtbox_id: StringName = &""
var hurtbox_multiplier: float = 1.0
var damage_type: DamageType = (
	DamageType.PHYSICAL
)


func _init(
		damage_amount: float,
		type: DamageType,
		damage_source: Node = null,
		skill: Skills = null,
		weapon: Weapon = null,
		actor: Node = null
	) -> void:
		amount = maxf(
			damage_amount,
			0.0
		)

		damage_type = type

		source = damage_source

		source_actor = (
			actor
			if actor != null
			else damage_source
		)

		source_skill = skill
		source_weapon = weapon
