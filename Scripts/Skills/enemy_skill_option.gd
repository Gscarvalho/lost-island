class_name EnemySkillOption
extends Resource


@export_category("Skill")

## The Skills resource this option represents.
## The Enemy must also have a matching animation state for this skill.
@export var skill: Skills


@export_category("Priority")

## The skill's natural preference for this specific enemy.
## Higher values make this skill more likely to win when multiple skills
## are otherwise similarly useful.
##
## This value is multiplied by Base Priority Weight in the
## EnemySkillPriorityProfile.
@export_range(0.0, 5.0, 0.05)
var base_priority := 1.0


## Controls how this skill reacts to recent incoming hit pressure.
##
##  1.0 = strongly prefers this skill while being pressured.
##  0.0 = pressure does not affect this skill.
## -1.0 = actively avoids this skill while being pressured.
##
## This response is multiplied by the enemy's current Hit Pressure
## and Hit Pressure Weight.
@export_range(-1.0, 1.0, 0.05)
var hit_pressure_response := 0.0


@export_category("Distance")

## Closest distance where this skill is considered usable.
## Outside the usable range the skill receives a Range Score of 0
## and cannot be selected.
@export_range(0.0, 100.0, 0.1)
var use_distance_min := 0.0


## Beginning of the skill's ideal distance range.
## Between Preferred Min and Preferred Max the Range Score is 1.0.
@export_range(0.0, 100.0, 0.1)
var preferred_distance_min := 0.0


## End of the skill's ideal distance range.
## Between Preferred Min and Preferred Max the Range Score is 1.0.
@export_range(0.0, 100.0, 0.1)
var preferred_distance_max := 2.0


## Farthest distance where this skill is considered usable.
## Past this distance the skill receives a Range Score of 0
## and cannot be selected.
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
