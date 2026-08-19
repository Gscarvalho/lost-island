class_name MeleeEnemyBehavior
extends Node


@export_category("Detection")

@export var detection_range := 12.0
@export var preferred_distance := 1.3


@export_category("Movement")

@export var move_speed := 3.0
@export var turn_speed := 8.0

@export_category("Attack")

@export var attack_skill: Skills
@export var attack_cooldown := 1.0


var enemy: Enemy
var navigation_agent: NavigationAgent3D

var attack_cooldown_left := 0.0


func _ready() -> void:
	enemy = get_parent() as Enemy

	if enemy == null:
		push_error(
			"MeleeEnemyBehavior requires an Enemy parent."
		)
		return

	navigation_agent = (
		enemy.get_node_or_null(
			"NavigationAgent3D"
		) as NavigationAgent3D
	)

	if navigation_agent == null:
		push_error(
			"MeleeEnemyBehavior requires a NavigationAgent3D."
		)
		return

	_find_target()


func _physics_process(
	delta: float
) -> void:
	if enemy == null:
		return

	if navigation_agent == null:
		return

	_update_attack_cooldown(
		delta
	)

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

	if distance <= preferred_distance:
		_stop()

		_face_target(
			delta
		)

		if attack_cooldown_left <= 0.0:
			_attack()

		return

	_move_toward_target(
		delta
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
		delta: float
	) -> void:
		if not enemy.has_target():
			_stop()
			return

		navigation_agent.target_position = (
			enemy.target.global_position
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


func _attack() -> void:
	if attack_skill == null:
		return

	enemy.prepare_weapon_attack(
		attack_skill
	)

	enemy.play_animation_state(
		&"Attack_Melee"
	)

	attack_cooldown_left = (
		attack_cooldown
	)


func _update_attack_cooldown(
		delta: float
	) -> void:
		attack_cooldown_left = maxf(
			attack_cooldown_left - delta,
			0.0
		)


func _face_target(
		delta: float
	) -> void:
		if not enemy.has_target():
			return

		_face_position(
			enemy.target.global_position,
			delta
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
