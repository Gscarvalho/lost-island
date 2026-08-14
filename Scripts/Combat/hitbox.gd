class_name Hitbox
extends Area3D

@export_category("Damage")

@export var damage: float = 10.0

var active := false

var already_hit: Array[Hurtbox] = []


func _ready() -> void:
	area_entered.connect(
		_on_area_entered
	)
	
	activate()


func activate() -> void:
	active = true

	already_hit.clear()


func deactivate() -> void:
	active = false


func _on_area_entered(
	area: Area3D
) -> void:
	if not active:
		return

	var hurtbox := area as Hurtbox

	if hurtbox == null:
		return

	if already_hit.has(hurtbox):
		return

	already_hit.append(
		hurtbox
	)

	hurtbox.receive_hit(
		self
	)
