#weapon.gd
extends Node3D
class_name Weapon

@export var weapon_name: String
@export var stats_boost: StatModifiers
var user : CharacterBody3D
var damage_active := false

func _on_collider_body_entered(
	_body: Node3D
	) -> void:
	# TODO: Connect weapon collision to the damage system.
	# This callback remains because the weapon scene signal uses it.
	pass
