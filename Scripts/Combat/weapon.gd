class_name Weapon
extends Node3D

@export var weapon_name: String = ""
@export var stats_boost: StatModifiers

@onready var hitbox: Hitbox = (
	$Hitbox
)

var user: CharacterBody3D


func prepare_attack(
	skill: Skills,
	damage: float
) -> void:
	if skill == null:
		return

	hitbox.deactivate()

	hitbox.configure_attack(
		self,
		skill,
		damage
	)

func start_damage_window() -> void:
	hitbox.activate()


func end_damage_window() -> void:
	hitbox.deactivate()
