class_name Weapon
extends Node3D


@export var weapon_name: String = ""
@export var stats_boost: StatModifiers

@onready var hitbox: Hitbox = (
	$Hitbox
)

var user: CharacterBody3D
var damage_active: bool = false


func _on_collider_body_entered(
	_body: Node3D
) -> void:
	# TODO: Connect weapon collision to the damage system.
	# The weapon scene currently connects its body_entered signal here.
	pass

func _activate() -> void:
	hitbox.activate()

func _deactivate() -> void:
	hitbox.activate()
