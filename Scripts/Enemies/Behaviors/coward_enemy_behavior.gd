class_name CowardEnemyBehavior
extends Node


@export_category("Detection")

@export var detection_range := 10.0
@export var memory_duration := 5.0


@export_category("Fleeing")

@export var desired_safe_distance := 8.0
@export var flee_step_distance := 8.0


@export_category("Movement")

@export var move_speed := 4.0
@export var turn_speed := 3.0


var enemy: Enemy
var navigation_agent: NavigationAgent3D

var threat_memory_left := 0.0


func _ready() -> void:
	enemy = get_parent() as Enemy

	if enemy == null:
		push_error(
			"CowardEnemyBehavior requires an Enemy parent."
		)
		return

	enemy.player_attack_received.connect(
		_on_player_attack_received
	)

	navigation_agent = (
		enemy.get_node_or_null(
			"NavigationAgent3D"
		) as NavigationAgent3D
	)

	if navigation_agent == null:
		push_error(
			"CowardEnemyBehavior requires a NavigationAgent3D."
		)
		return


func _physics_process(
	delta: float
) -> void:
	if enemy == null:
		return

	if navigation_agent == null:
		return

	enemy.memory.update_time(
		delta
	)

	if not enemy.has_target():
		_find_threat()

		if not enemy.has_target():
			_stop()
			return

	var can_see_target := (
		enemy.has_line_of_sight_to(
			enemy.target
		)
	)

	if can_see_target:
		enemy.memory.remember_player_seen(
			enemy.target.global_position
		)

		threat_memory_left = (
			memory_duration
		)

	else:
		threat_memory_left = maxf(
			threat_memory_left - delta,
			0.0
		)

		if threat_memory_left <= 0.0:
			enemy.clear_target()

			_stop()
			return

	if not enemy.memory.has_known_player_position:
		_stop()
		return

	_flee_from_position(
		enemy.memory.last_known_player_position,
		delta
	)


func _find_threat() -> void:
	var player := (
		get_tree().get_first_node_in_group(
			"Player"
		) as Node3D
	)

	if player == null:
		return

	var to_player := (
		player.global_position
		- enemy.global_position
	)

	to_player.y = 0.0

	if to_player.length() > detection_range:
		return

	if not enemy.has_line_of_sight_to(
		player
	):
		return

	enemy.set_target(
		player
	)

	enemy.memory.remember_player_seen(
		player.global_position
	)

	threat_memory_left = (
		memory_duration
	)


func _on_player_attack_received(
	player: Node3D
) -> void:
	if player == null:
		return

	enemy.set_target(
		player
	)

	threat_memory_left = (
		memory_duration
	)


func _flee_from_position(
	threat_position: Vector3,
	delta: float
) -> void:
	var away_direction := (
		enemy.global_position
		- threat_position
	)

	away_direction.y = 0.0

	if away_direction.is_zero_approx():
		_stop()
		return

	var distance_from_threat := (
		away_direction.length()
	)

	if (
		distance_from_threat
		>= desired_safe_distance
	):
		_stop()
		return

	var flee_direction := (
		away_direction.normalized()
	)

	var flee_target := (
		enemy.global_position
		+ flee_direction
		* flee_step_distance
	)

	_move_toward_position(
		flee_target,
		delta
	)


func _move_toward_position(
	target_position: Vector3,
	delta: float
) -> void:
	navigation_agent.target_position = (
		target_position
	)

	if navigation_agent.is_navigation_finished():
		_stop()
		return

	var next_path_position := (
		navigation_agent.get_next_path_position()
	)

	var direction := (
		next_path_position
		- enemy.global_position
	)

	direction.y = 0.0

	if direction.is_zero_approx():
		_stop()
		return

	var move_direction := (
		direction.normalized()
	)

	_face_position(
		next_path_position,
		delta
	)

	enemy.velocity.x = (
		move_direction.x
		* move_speed
	)

	enemy.velocity.z = (
		move_direction.z
		* move_speed
	)

	enemy.play_animation_state(
		&"Move"
	)

	enemy.move_and_slide()


func _stop() -> void:
	enemy.velocity.x = 0.0
	enemy.velocity.z = 0.0

	enemy.play_animation_state(
		&"Idle"
	)


func _face_position(
	world_position: Vector3,
	delta: float
) -> void:
	var direction := (
		world_position
		- enemy.global_position
	)

	direction.y = 0.0

	if direction.length_squared() <= 0.0001:
		return

	var target_yaw := atan2(
		-direction.x,
		-direction.z
	)

	var current_rotation := (
		enemy.rotation
	)

	current_rotation.y = rotate_toward(
		current_rotation.y,
		target_yaw,
		turn_speed * delta
	)

	enemy.rotation = (
		current_rotation
	)
