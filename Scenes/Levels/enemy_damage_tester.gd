extends Node3D

@onready var hitbox: Hitbox = (
	$Hitbox
)


func _ready() -> void:
	hitbox.configure_attack(
		self,
		null,
		25.0
	)

	hitbox.activate()
