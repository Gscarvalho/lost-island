class_name TestDummy
extends Node3D

signal health_changed(
	current: float,
	maximum: float
)

@export_category("Health")

@export var maximum_health: float = 100.0

@onready var hurtbox: Hurtbox = (
	$Hurtbox
)
@onready var dummy_health: TextureProgressBar = (
	$Sprite3D/SubViewport/dummy_health
)
var current_health: float

func _ready() -> void:
	current_health = maximum_health

	hurtbox.hit_received.connect(
		_on_hurtbox_hit_received
	)

	health_changed.connect(
		_update_ui
	)
	
	_update_ui(
		current_health,
		maximum_health
	)

func _update_ui(
	current: float,
	maximum: float
) -> void:
	dummy_health.value = current
	dummy_health.max_value = maximum

func _on_hurtbox_hit_received(
	hitbox: Hitbox
) -> void:
	take_damage(
		hitbox.damage
	)


func take_damage(
	damage: float
) -> void:
	if damage <= 0.0:
		return

	current_health = maxf(
		current_health - damage,
		0.0
	)

	health_changed.emit(
		current_health,
		maximum_health
	)

	print(
		"Dummy HP: ",
		current_health,
		"/",
		maximum_health
	)
