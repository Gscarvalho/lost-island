class_name EnemySkillOption
extends Resource


@export_category("Skill")

@export var skill: Skills


@export_category("Priority")

@export_range(0.0, 5.0, 0.05)
var base_priority := 1.0

@export_range(-1.0, 1.0, 0.05)
var hit_pressure_response := 0.0

@export_category("Distance")

@export_range(0.0, 100.0, 0.1)
var use_distance_min := 0.0

@export_range(0.0, 100.0, 0.1)
var preferred_distance_min := 0.0

@export_range(0.0, 100.0, 0.1)
var preferred_distance_max := 2.0

@export_range(0.0, 100.0, 0.1)
var use_distance_max := 3.0


func get_range_score(
	distance: float
) -> float:
	var minimum := minf(
		use_distance_min,
		use_distance_max
	)

	var maximum := maxf(
		use_distance_min,
		use_distance_max
	)

	var preferred_minimum := clampf(
		preferred_distance_min,
		minimum,
		maximum
	)

	var preferred_maximum := clampf(
		preferred_distance_max,
		preferred_minimum,
		maximum
	)

	if distance < minimum:
		return 0.0

	if distance > maximum:
		return 0.0

	if (
		distance >= preferred_minimum
		and distance <= preferred_maximum
	):
		return 1.0

	if distance < preferred_minimum:
		if preferred_minimum <= minimum:
			return 1.0

		return inverse_lerp(
			minimum,
			preferred_minimum,
			distance
		)

	if preferred_maximum >= maximum:
		return 1.0

	return (
		1.0
		- inverse_lerp(
			preferred_maximum,
			maximum,
			distance
		)
	)
