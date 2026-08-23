class_name MeleeEnemyBehavior
extends Node


@export_category("Detection")

@export var detection_range := 12.0
@export var preferred_distance := 1.3

@export var memory_duration := 4.0

@export var look_around_duration := 8.0


@export_category("Movement")

@export var move_speed := 3.0
@export var turn_speed := 8.0


var enemy: Enemy
var navigation_agent: NavigationAgent3D

var investigating_player_attack := false

func _ready() -> void:
	enemy = get_parent() as Enemy

	if enemy == null:
		push_error(
			"MeleeEnemyBehavior requires an Enemy parent."
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

		enemy.memory.update_time(
			delta
		)

		if not enemy.has_target():
			_find_target()

			if enemy.has_target():
				investigating_player_attack = false

			elif investigating_player_attack:
				_investigate_player_attack(
					delta
				)

				return

			else:
				_stop()
				return

		var can_see_target := (
			enemy.can_see_target(
				enemy.target
			)
		)

		if can_see_target:
			enemy.memory.remember_player_seen(
				enemy.target.global_position
			)

		elif (
			enemy.memory.time_since_player_seen
			> memory_duration
		):
			enemy.clear_target()

			_stop()

			return

		if can_see_target:
			_handle_visible_target(
				delta
			)

			return

		_follow_last_seen_position(
			delta
		)
		


func _find_target() -> void:
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

	var distance := (
		to_player.length()
	)

	if distance > detection_range:
		return

	if not enemy.can_see_target(
		player
	):
		return

	enemy.set_target(
		player
	)

	enemy.memory.remember_player_seen(
		player.global_position
	)

	investigating_player_attack = false

func _on_player_attack_received(
		player: Node3D
	) -> void:
		if player == null:
			return

		if enemy.can_see_target(
			player
		):
			enemy.set_target(
				player
			)

			enemy.memory.remember_player_seen(
				player.global_position
			)

			investigating_player_attack = false

			return

		investigating_player_attack = true

func _investigate_player_attack(
		delta: float
	) -> void:
		if not enemy.memory.has_player_attack_position:
			investigating_player_attack = false

			_stop()

			return

		var attack_position := (
			enemy.memory.last_player_attack_position
		)

		var distance := (
			enemy.global_position.distance_to(
				attack_position
			)
		)

		if distance <= 0.75:
			investigating_player_attack = false

			_stop()

			return

		_move_toward_position(
			attack_position,
			delta
		)

func _handle_visible_target(
		delta: float
	) -> void:
		if not enemy.has_target():
			return

		var to_target := (
			enemy.target.global_position
			- enemy.global_position
		)

		to_target.y = 0.0

		var distance := (
			to_target.length()
		)

		if distance <= preferred_distance:
			_stop()

			_face_target(
				delta
			)

			_attack()

			return

		_move_toward_position(
			enemy.target.global_position,
			delta
		)


func _follow_last_seen_position(
		delta: float
	) -> void:
		if not enemy.memory.has_seen_player:
			_stop()
			return

		_move_toward_position(
			enemy.memory.last_seen_player_position,
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

		enemy.play_movement_state(
			&"Move"
		)


func _look_around() -> void:
	var sight_orgin = enemy.sight_origin as Marker3D
	var tween = create_tween()
	
	tween.tween_property(
			sight_orgin,
			"rotation_degrees",
			360,
			look_around_duration
		)
	
	enemy.play_movement_state(
		&"Look_Around"
	)

func _stop() -> void:
	enemy.velocity.x = 0.0
	enemy.velocity.z = 0.0

	enemy.play_movement_state(
		&"Idle"
	)


func _attack() -> void:
	var selected_skill := (
		enemy.get_default_skill()
	)

	if selected_skill == null:
		return

	if not enemy.is_skill_ready(
		selected_skill
	):
		return

	enemy.prepare_weapon_attack(
		selected_skill
	)

	if not enemy.play_skill_animation(
		selected_skill
	):
		return

	enemy.commit_skill_use(
		selected_skill
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
