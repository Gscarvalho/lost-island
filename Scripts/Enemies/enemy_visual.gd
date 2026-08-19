class_name EnemyVisual
extends Node3D


var enemy: Enemy


func _ready() -> void:
	enemy = get_parent() as Enemy

	if enemy == null:
		push_error(
			"EnemyVisual requires an Enemy parent."
		)


func start_weapon_damage_window() -> void:
	if enemy == null:
		return

	enemy.start_weapon_damage_window()


func end_weapon_damage_window() -> void:
	if enemy == null:
		return

	enemy.end_weapon_damage_window()
