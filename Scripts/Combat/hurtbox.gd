class_name Hurtbox
extends Area3D

signal hit_received(
	damage_data: DamageData
)

@export_category("Hurtbox")

@export var hurtbox_id: StringName = &"body"

@export_range(0.0, 10.0, 0.05)
var damage_multiplier: float = 1.0

@export var damage_receiver: Node


func get_damage_receiver() -> Node:
	if damage_receiver != null:
		return damage_receiver

	return self


func receive_hit(
		hitbox: Hitbox
	) -> void:
		if hitbox == null:
			return

		var damage_data := (
			hitbox.create_damage_data()
		)

		damage_data.hurtbox_id = (
			hurtbox_id
		)

		damage_data.hurtbox_multiplier = (
			damage_multiplier
		)

		damage_data.amount *= (
			damage_multiplier
		)

		hit_received.emit(
			damage_data
		)
