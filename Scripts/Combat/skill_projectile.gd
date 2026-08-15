class_name SkillProjectile
extends Node3D

@export_category("Projectile")

@export var speed: float = 12.0
@export var lifetime: float = 5.0

@onready var hitbox: Hitbox = (
	$Hitbox
)

var direction := Vector3.ZERO


func _ready() -> void:
	hitbox.hit_confirmed.connect(
		_on_hit_confirmed
	)


func setup(
	source: Node,
	skill: Skills,
	damage: float,
	travel_direction: Vector3
) -> void:
	hitbox.configure_attack(
		source,
		skill,
		damage
	)

	direction = (
		travel_direction.normalized()
	)

	if direction == Vector3.ZERO:
		queue_free()
		return

	look_at(
		global_position + direction,
		Vector3.UP
	)

	hitbox.activate()


func _physics_process(
	delta: float
) -> void:
	global_position += (
		direction
		* speed
		* delta
	)

	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()


func _on_hit_confirmed(
	_hurtbox: Hurtbox
) -> void:
	queue_free()
