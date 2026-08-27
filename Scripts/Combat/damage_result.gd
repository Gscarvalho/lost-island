class_name DamageResult
extends RefCounted


enum Effectiveness {
	NORMAL,
	WEAK,
	RESIST,
	IMMUNE,
}


## Raw damage entering the resolver.
var base_damage := 0.0

## Damage after Defense / M.Defense,
## but BEFORE weaknesses and resistances.
##
## In other words:
## "What would this attack have dealt
## if every affinity were 1.0?"
var neutral_damage := 0.0

## Actual damage after defense AND affinities.
var final_damage := 0.0


## Combined effectiveness of the complete attack.
var effectiveness := Effectiveness.NORMAL

## Weighted relationship between:
##
## final_damage / neutral_damage
##
## Examples:
## 1.50 = effectively 50% stronger
## 0.50 = effectively 50% resisted
## 1.00 = neutral
var effectiveness_multiplier := 1.0


## Damage types involved in this attack.
var damage_types: int = (
	DamageTypes.Type.PHYSICAL
)


## Per-type damage after defense,
## before affinity.
##
## Key:
## DamageTypes.Type
##
## Value:
## float damage
var type_neutral_damage: Dictionary = {}


## Per-type damage after defense
## AND affinity.
var type_final_damage: Dictionary = {}


func update_effectiveness() -> void:
	final_damage = maxf(
		final_damage,
		0.0
	)

	neutral_damage = maxf(
		neutral_damage,
		0.0
	)

	if neutral_damage <= 0.0001:
		effectiveness_multiplier = 1.0
		effectiveness = (
			Effectiveness.NORMAL
		)

		return

	effectiveness_multiplier = (
		final_damage
		/ neutral_damage
	)

	if final_damage <= 0.0001:
		effectiveness = (
			Effectiveness.IMMUNE
		)

		return

	if effectiveness_multiplier > 1.001:
		effectiveness = (
			Effectiveness.WEAK
		)

		return

	if effectiveness_multiplier < 0.999:
		effectiveness = (
			Effectiveness.RESIST
		)

		return

	effectiveness = (
		Effectiveness.NORMAL
	)


func get_effectiveness_name() -> String:
	match effectiveness:
		Effectiveness.WEAK:
			return "WEAK"

		Effectiveness.RESIST:
			return "RESIST"

		Effectiveness.IMMUNE:
			return "IMMUNE"

		_:
			return "NORMAL"
