class_name DamageTypes
extends RefCounted


enum Type {
	PHYSICAL = 1 << 0,
	FIRE = 1 << 1,
	WATER = 1 << 2,
	LIGHT = 1 << 3,
	SNOW = 1 << 4,
	LIGHTNING = 1 << 5,
	PLANT = 1 << 6,
	DARK = 1 << 7,
}


const ALL_TYPES: Array[int] = [
	Type.PHYSICAL,
	Type.FIRE,
	Type.WATER,
	Type.LIGHT,
	Type.SNOW,
	Type.LIGHTNING,
	Type.PLANT,
	Type.DARK,
]


static func get_active_types(
	damage_type_mask: int
) -> Array[int]:
	var active_types: Array[int] = []

	for damage_type in ALL_TYPES:
		if (
			damage_type_mask
			& damage_type
		) != 0:
			active_types.append(
				damage_type
			)

	# Safety fallback so malformed damage
	# can never become typeless.
	if active_types.is_empty():
		active_types.append(
			Type.PHYSICAL
		)

	return active_types


static func is_physical(
	damage_type: int
) -> bool:
	return (
		damage_type
		== Type.PHYSICAL
	)
