class_name DamageResolver
extends RefCounted


static func resolve_damage(
	damage_data: DamageData,
	stats: Stats,
	affinity: DamageAffinityProfile = null
) -> DamageResult:
	var result := DamageResult.new()

	if damage_data == null:
		return result

	result.base_damage = (
		damage_data.amount
	)

	result.damage_types = (
		damage_data.damage_types
	)

	var active_types := (
		DamageTypes.get_active_types(
			damage_data.damage_types
		)
	)

	var type_count := (
		active_types.size()
	)

	if type_count <= 0:
		return result

	var damage_per_type := (
		damage_data.amount
		/ float(type_count)
	)

	for damage_type in active_types:
		var defense_value := (
			_get_defense_for_type(
				damage_type,
				stats
			)
		)

		var defended_damage := (
			damage_per_type
			* 100.0
			/ (
				100.0
				+ defense_value
			)
		)

		var affinity_multiplier := (
			_get_affinity_multiplier(
				damage_type,
				affinity
			)
		)

		var type_final_damage := (
			defended_damage
			* affinity_multiplier
		)

		result.type_neutral_damage[
			damage_type
		] = defended_damage

		result.type_final_damage[
			damage_type
		] = type_final_damage

		result.neutral_damage += (
			defended_damage
		)

		result.final_damage += (
			type_final_damage
		)

	result.update_effectiveness()

	return result


## Convenience function for systems that only
## need the final numeric damage.
##
## This also preserves compatibility with the
## old DamageResolver API.
static func calculate_damage(
	damage_data: DamageData,
	stats: Stats,
	affinity: DamageAffinityProfile = null
) -> float:
	return (
		resolve_damage(
			damage_data,
			stats,
			affinity
		)
		.final_damage
	)


static func _get_defense_for_type(
	damage_type: int,
	stats: Stats
) -> float:
	if stats == null:
		return 0.0

	if DamageTypes.is_physical(
		damage_type
	):
		return maxf(
			stats.defense,
			0.0
		)

	return maxf(
		stats.m_defense,
		0.0
	)


static func _get_affinity_multiplier(
	damage_type: int,
	affinity: DamageAffinityProfile
) -> float:
	if affinity == null:
		return 1.0

	return maxf(
		affinity.get_multiplier(
			damage_type
		),
		0.0
	)
