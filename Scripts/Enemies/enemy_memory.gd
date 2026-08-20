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

var has_player_attack_position := false

var last_player_attack_position := (
	Vector3.ZERO
)
#endregion


#region Time
func update_time(
		delta: float
	) -> void:
		if not has_seen_player:
			return

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


func has_been_attacked_by_player() -> bool:
	return (
		player_attack_count > 0
	)
#endregion
