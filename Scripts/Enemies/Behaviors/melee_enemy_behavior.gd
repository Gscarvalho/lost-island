class_name MeleeEnemyBehavior
extends Node


@export_category("Detection")

@export var detection_range := 12.0
@export var preferred_distance := 1.3


@export_category("Movement")

@export var move_speed := 3.0


var enemy: Enemy


func _ready() -> void:
	enemy = get_parent() as Enemy

	if enemy == null:
		push_error(
			"RangedEnemyBehavior requires an Enemy parent."
		)
		return

	_find_target()


func _physics_process(
		_delta: float
	) -> void:
		if enemy == null:
			return

		if not enemy.has_target():
			_find_target()

			if not enemy.has_target():
				_stop()
				return

		var to_target := (
			enemy.target.global_position
			- enemy.global_position
		)

		to_target.y = 0.0

		var distance := to_target.length()

		if distance > detection_range:
			_stop()
			return

		_face_target()

		if distance <= preferred_distance:
			_stop()
			return

		_move_toward_target(
			to_target
		)


func _find_target() -> void:
	var player := (
		get_tree().get_first_node_in_group(
			"Player"
		) as Node3D
	)

	if player != null:
		enemy.set_target(
			player
		)


func _move_toward_target(
		direction: Vector3
	) -> void:
		if direction.is_zero_approx():
			_stop()
			return

		var move_direction := (
			direction.normalized()
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


func _face_target() -> void:
	if not enemy.has_target():
		return

	var target_position := Vector3(
		enemy.target.global_position.x,
		enemy.global_position.y,
		enemy.target.global_position.z
	)

	enemy.look_at(
		target_position,
		Vector3.UP
	)
