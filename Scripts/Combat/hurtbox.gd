class_name Hurtbox
extends Area3D

signal hit_received(
	hitbox: Hitbox
)


func receive_hit(
	hitbox: Hitbox
) -> void:
	if hitbox == null:
		return

	hit_received.emit(
		hitbox
	)
