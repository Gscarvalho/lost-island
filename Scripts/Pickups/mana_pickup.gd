class_name ManaPickup
extends Area3D

@export_category("Mana")

@export var mana_type: Skills.SkillType = (
	Skills.SkillType.Fire
)

@export_range(0.0, 999.0, 0.1)
var mana_amount: float = 1.0

@export var respect_mana_maximum := true


func _ready() -> void:
	body_entered.connect(
		_on_body_entered
	)


func _on_body_entered(
	body: Node3D
) -> void:
	var player := body as Player

	if player == null:
		return

	if mana_type == Skills.SkillType.Physical:
		return

	var character := (
		player.get_node("Character")
		as PlayerCharacter
	)

	if character == null:
		return

	var previous_amount := (
		character.get_mana_amount(
			mana_type
		)
	)

	character.change_mana(
		mana_type,
		mana_amount,
		respect_mana_maximum
	)

	var new_amount := (
		character.get_mana_amount(
			mana_type
		)
	)

	if new_amount <= previous_amount:
		return

	queue_free()
