class_name EnemySkillPriorityProfile
extends Resource


@export_category("Priority Weights")

@export_range(0.0, 5.0, 0.05)
var base_priority_weight := 1.0

@export_range(0.0, 5.0, 0.05)
var range_fit_weight := 2.0

@export_range(0.0, 5.0, 0.05)
var hit_pressure_weight := 1.5

@export_range(0.0, 5.0, 0.05)
var observed_damage_weight := 1.0
