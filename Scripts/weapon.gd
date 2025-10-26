#weapon.gd
extends Node3D
class_name Weapon

@export var weapon_name: String
@export var stats_boost: Stats
var user : CharacterBody3D
var damage_active := false



func _on_collider_body_entered(body: Node3D) -> void:
	if 'hit' in body:
		#body.hit()
		pass
