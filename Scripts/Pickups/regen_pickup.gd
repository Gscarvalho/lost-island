class_name RegenPickup
extends Area3D

@export_category("Regeneration")

@export var regen_type: Player.RegenType = Player.RegenType.Health

@export_range(0.0, 999.0, 0.1)
var regen_amount: float = 1.0

@export var respect_regen_maximum := true
@onready var blue_crystal_mesh: MeshInstance3D = (
	%BlueCrystal
)
@onready var green_crystal_mesh: MeshInstance3D = (
	%GreenCrystal
)

func _ready() -> void:
	body_entered.connect(
		_on_body_entered
	)
	
	_set_visuals()

func _on_body_entered(
		body: Node3D
	) -> void:
		var player := body as Player

		if player == null:
			return

		var character := (
			player.get_node("Character")
			as PlayerCharacter
		)

		if character == null:
			return

		var previous_amount: float
		var new_amount: float
		
		match regen_type:
			Player.RegenType.Health:
				previous_amount = character.current_hp
				character.current_hp += regen_amount
				new_amount = character.current_hp

			Player.RegenType.Stamina:
				previous_amount = character.current_stamina
				character.current_stamina += regen_amount
				new_amount = character.current_stamina

		if new_amount <= previous_amount:
			return

		queue_free()
		

func _set_visuals() -> void:
	match regen_type:
		Player.RegenType.Health:
			blue_crystal_mesh.visible = false
			green_crystal_mesh.visible = true
		Player.RegenType.Stamina:
			green_crystal_mesh.visible = false
			blue_crystal_mesh.visible = true
	
