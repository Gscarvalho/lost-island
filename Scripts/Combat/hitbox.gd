class_name Hitbox
extends Area3D

@export_category("Damage")

@export var damage: float = 10.0

var active := false

var source_skill: Skills
var source_node: Node

var already_hit: Array[Node] = []


func _ready() -> void:
	area_entered.connect(
		_on_area_entered
	)


func configure_attack(
	source: Node,
	skill: Skills,
	damage_amount: float
) -> void:
	source_node = source
	source_skill = skill

	damage = maxf(
		damage_amount,
		0.0
	)

func create_damage_data() -> DamageData:
	var weapon := source_node as Weapon

	return DamageData.new(
		damage,
		source_node,
		source_skill,
		weapon
	)


func activate() -> void:
	active = true
	already_hit.clear()

	# Catch Hurtboxes that were already overlapping
	# when the damage window opened.
	for area in get_overlapping_areas():
		_try_hit(area)


func deactivate() -> void:
	active = false


func _on_area_entered(
	area: Area3D
) -> void:
	_try_hit(area)


func _try_hit(
	area: Area3D
) -> void:
	if not active:
		return

	var hurtbox := area as Hurtbox

	if hurtbox == null:
		return

	var damage_receiver := (
		hurtbox.get_damage_receiver()
	)

	if already_hit.has(
		damage_receiver
	):
		return

	already_hit.append(
		damage_receiver
	)

	hurtbox.receive_hit(
		self
	)
