class_name EnemyVisual
extends Node3D


var enemy: Enemy
var projectile_spawn: Marker3D

func _ready() -> void:
	enemy = get_parent() as Enemy

	if enemy == null:
		push_error(
			"EnemyVisual requires an Enemy parent."
		)
	
	projectile_spawn = (
		find_child(
			"ProjectileSpawn",
			true,
			false
		) as Marker3D
	)


func start_weapon_damage_window() -> void:
	if enemy == null:
		return

	enemy.start_weapon_damage_window()


func end_weapon_damage_window() -> void:
	if enemy == null:
		return

	enemy.end_weapon_damage_window()

func release_projectile() -> void:
	if enemy == null:
		return

	if projectile_spawn == null:
		return

	enemy.release_projectile(
		projectile_spawn.global_transform
	)
