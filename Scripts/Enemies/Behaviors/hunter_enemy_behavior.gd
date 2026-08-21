class_name HunterEnemyBehavior
extends Node


@export_category("Detection")

@export var detection_range := 12.0
@export var preferred_distance := 1.3

@export var look_around_duration := 5.0
@export var look_around_pitch := 25.0

@export var last_seen_arrival_distance := 0.75
@export_category("Idle")

@export var idle_time_min := 2.0
@export var idle_time_max := 5.0

@export var wander_radius := 6.0
@export var wander_arrival_distance := 0.75

@export_range(0.0, 1.0, 0.05)
var idle_look_around_chance := 0.25

@export_category("Movement")

@export var move_speed := 3.0
@export var turn_speed := 8.0


@export_category("Attack")

@export var attack_skill: Skills
@export var attack_cooldown := 1.0


var enemy: Enemy
var navigation_agent: NavigationAgent3D

var attack_cooldown_left := 0.0
var investigating_player_attack := false
var is_looking_around := false
var look_around_elapsed := 0.0

var wander_center := Vector3.ZERO
var wander_target := Vector3.ZERO

var is_wandering := false
var idle_time_left := 0.0

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
	wander_center = (
		enemy.global_position
	)

	_reset_idle_timer()


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

		_update_attack_cooldown(
			delta
		)
		
		if enemy.is_in_hit_reaction():
			return
		
		if is_looking_around:
			_update_look_around(
				delta
			)

			return
		
		if not enemy.has_target():
			_find_target()

			if enemy.has_target():
				investigating_player_attack = false

				_cancel_idle_activity()

			elif investigating_player_attack:
				_cancel_idle_activity()

				_investigate_player_attack(
					delta
				)

				return

			else:
				_update_idle_wander(
					delta
				)

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
	
	_cancel_idle_activity()

func _on_player_attack_received(
		player: Node3D
	) -> void:
		if player == null:
			return
		
		_cancel_idle_activity()
		
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

		enemy.clear_target()

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

		if distance <= last_seen_arrival_distance:
			investigating_player_attack = false

			_start_look_around()

			return

		var navigation_finished := (
			_move_toward_position(
				attack_position,
				delta
			)
		)

		if navigation_finished:
			investigating_player_attack = false

			_start_look_around()

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

			if attack_cooldown_left <= 0.0:
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
		enemy.clear_target()

		_stop()
		return

	var last_seen_position := (
		enemy.memory.last_seen_player_position
	)

	var to_last_seen := (
		last_seen_position
		- enemy.global_position
	)

	to_last_seen.y = 0.0

	if (
		to_last_seen.length()
		<= last_seen_arrival_distance
	):
		_start_look_around()
		return

	var navigation_finished := (
		_move_toward_position(
			last_seen_position,
			delta
		)
	)

	if navigation_finished:
		_start_look_around()


func _update_idle_wander(
	delta: float
) -> void:
	if is_wandering:
		_update_wandering(
			delta
		)

		return

	_stop()

	idle_time_left = maxf(
		idle_time_left - delta,
		0.0
	)

	if idle_time_left > 0.0:
		return

	if (
		randf()
		<= idle_look_around_chance
	):
		_start_look_around()
		return

	if _choose_wander_target():
		is_wandering = true
		return

	_reset_idle_timer()


func _update_wandering(
	delta: float
) -> void:
	var to_target := (
		wander_target
		- enemy.global_position
	)

	to_target.y = 0.0

	if (
		to_target.length()
		<= wander_arrival_distance
	):
		_finish_wandering()
		return

	var navigation_finished := (
		_move_toward_position(
			wander_target,
			delta
		)
	)

	if navigation_finished:
		_finish_wandering()


func _choose_wander_target() -> bool:
	var navigation_map := (
		navigation_agent.get_navigation_map()
	)

	if not navigation_map.is_valid():
		return false

	for attempt in 6:
		var angle := randf_range(
			0.0,
			TAU
		)

		var distance := randf_range(
			2.0,
			wander_radius
		)

		var offset := Vector3(
			cos(angle),
			0.0,
			sin(angle)
		) * distance

		var candidate := (
			wander_center
			+ offset
		)

		var navigation_point := (
			NavigationServer3D
			.map_get_closest_point(
				navigation_map,
				candidate
			)
		)

		var to_point := (
			navigation_point
			- enemy.global_position
		)

		to_point.y = 0.0

		if to_point.length() < 1.0:
			continue

		wander_target = (
			navigation_point
		)

		return true

	return false


func _finish_wandering() -> void:
	is_wandering = false

	_stop()

	_reset_idle_timer()


func _reset_idle_timer() -> void:
	var minimum := minf(
		idle_time_min,
		idle_time_max
	)

	var maximum := maxf(
		idle_time_min,
		idle_time_max
	)

	idle_time_left = randf_range(
		minimum,
		maximum
	)


func _cancel_idle_activity() -> void:
	is_wandering = false

func _move_toward_position(
	target_position: Vector3,
	delta: float
) -> bool:
	navigation_agent.target_position = (
		target_position
	)

	if navigation_agent.is_navigation_finished():
		_stop()
		return true

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
		return false

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

	return false


func _start_look_around() -> void:
	if is_looking_around:
		return

	is_looking_around = true
	look_around_elapsed = 0.0

	enemy.clear_target()

	enemy.velocity.x = 0.0
	enemy.velocity.z = 0.0

	enemy.sight_origin.rotation = (
		Vector3.ZERO
	)

	enemy.play_animation_state(
		&"Look_Around"
	)


func _update_look_around(
	delta: float
) -> void:
	look_around_elapsed += delta

	var progress := clampf(
		look_around_elapsed
		/ look_around_duration,
		0.0,
		1.0
	)

	var yaw := (
		progress
		* TAU
	)

	var pitch := deg_to_rad(
		sin(
			progress
			* TAU
			* 2.0
		)
		* look_around_pitch
	)

	enemy.sight_origin.rotation = Vector3(
		pitch,
		yaw,
		0.0
	)

	_find_target()

	if enemy.has_target():
		_finish_look_around_with_target()
		return

	if progress >= 1.0:
		_finish_look_around_without_target()


func _finish_look_around_with_target() -> void:
	var sight_yaw := (
		enemy.sight_origin.rotation.y
	)

	enemy.rotate_y(
		sight_yaw
	)

	enemy.sight_origin.rotation = (
		Vector3.ZERO
	)

	is_looking_around = false
	look_around_elapsed = 0.0


func _finish_look_around_without_target() -> void:
	enemy.sight_origin.rotation = (
		Vector3.ZERO
	)

	is_looking_around = false
	look_around_elapsed = 0.0

	_stop()
	
	_reset_idle_timer()


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
