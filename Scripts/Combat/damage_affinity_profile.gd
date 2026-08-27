class_name DamageAffinityProfile
extends Resource


@export_category("Damage Multipliers")

## 1.0 = normal damage.
## Below 1.0 = resistance.
## Above 1.0 = weakness.
## 0.0 = immunity.
@export_range(0.0, 3.0, 0.05)
var physical := 1.0

@export_range(0.0, 3.0, 0.05)
var fire := 1.0

@export_range(0.0, 3.0, 0.05)
var water := 1.0

@export_range(0.0, 3.0, 0.05)
var light := 1.0

@export_range(0.0, 3.0, 0.05)
var snow := 1.0

@export_range(0.0, 3.0, 0.05)
var lightning := 1.0

@export_range(0.0, 3.0, 0.05)
var plant := 1.0

@export_range(0.0, 3.0, 0.05)
var dark := 1.0


func get_multiplier(
	damage_type: int
) -> float:
	match damage_type:
		DamageTypes.Type.PHYSICAL:
			return physical

		DamageTypes.Type.FIRE:
			return fire

		DamageTypes.Type.WATER:
			return water

		DamageTypes.Type.LIGHT:
			return light

		DamageTypes.Type.SNOW:
			return snow

		DamageTypes.Type.LIGHTNING:
			return lightning

		DamageTypes.Type.PLANT:
			return plant

		DamageTypes.Type.DARK:
			return dark

		_:
			return 1.0
