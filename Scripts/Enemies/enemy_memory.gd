class_name EnemyMemory
extends RefCounted

#region Player Knowledge
var has_known_player_position := false

var last_known_player_position := (
	Vector3.ZERO
)
#endregion

#region Player Sighting
var has_seen_player := false

var last_seen_player_position := (
	Vector3.ZERO
)

var time_since_player_seen := 0.0
#endregion


#region Player Combat
var player_attack_count := 0

var hit_pressure := 0.0

var hit_pressure_gain := 0.35
var hit_pressure_decay_per_second := 0.20

var skill_use_counts: Dictionary = {}

var skill_total_final_damage: Dictionary = {}

var has_player_attack_position := false

var last_player_attack_position := (
	Vector3.ZERO
)
#endregion


#region Time
func update_time(
		delta: float
	) -> void:
		hit_pressure = maxf(
			hit_pressure
			- hit_pressure_decay_per_second
			* delta,
			0.0
		)

		if has_seen_player:
			time_since_player_seen += delta
#endregion


#region Sighting
func remember_player_seen(
		position: Vector3
	) -> void:
		has_seen_player = true

		last_seen_player_position = (
			position
		)
		has_known_player_position = true

		last_known_player_position = (
			position
		)
		time_since_player_seen = 0.0
#endregion


#region Combat
func remember_player_attack(
		position: Vector3
	) -> void:
		player_attack_count += 1
		
		hit_pressure = clampf(
			hit_pressure + hit_pressure_gain,
			0.0,
			1.0
		)

		has_player_attack_position = true

		last_player_attack_position = (
			position
		)

		has_known_player_position = true

		last_known_player_position = (
			position
		)

		print(
			"Player hit count: ",
			player_attack_count
		)

func remember_skill_used(
		skill: Skills
	) -> void:
		if skill == null:
			return

		skill_use_counts[skill] = (
			get_skill_use_count(
				skill
			)
			+ 1
		)


func remember_skill_final_damage(
		skill: Skills,
		final_damage: float
	) -> void:
		if skill == null:
			return

		var damage := maxf(
			final_damage,
			0.0
		)

		skill_total_final_damage[skill] = (
			get_skill_total_final_damage(
				skill
			)
			+ damage
		)


func get_skill_use_count(
		skill: Skills
	) -> int:
		if skill == null:
			return 0

		if not skill_use_counts.has(
			skill
		):
			return 0

		return int(
			skill_use_counts[skill]
		)


func get_skill_total_final_damage(
		skill: Skills
	) -> float:
		if skill == null:
			return 0.0

		if not skill_total_final_damage.has(
			skill
		):
			return 0.0

		return float(
			skill_total_final_damage[skill]
		)


func get_skill_average_final_damage(
		skill: Skills
	) -> float:
		var uses := get_skill_use_count(
			skill
		)

		if uses <= 0:
			return 0.0

		return (
			get_skill_total_final_damage(
				skill
			)
			/ float(uses)
		)

func has_been_attacked_by_player() -> bool:
	return (
		player_attack_count > 0
	)
#endregion
