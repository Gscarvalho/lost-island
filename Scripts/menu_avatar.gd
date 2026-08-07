class_name MenuAvatar
extends Node3D

@export var rotation_speed_degrees := 120.0

@onready var rig: Node3D = $Rig
@onready var weapon_preview: Node3D = %WeaponPreview
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var rotation_enabled := false

func sync_loadout(weapon_is_active: bool) -> void:
	weapon_preview.visible = weapon_is_active

	if weapon_is_active:
		animation_player.play("2H_Melee_Idle")
	else:
		animation_player.play("Idle")

func _process(delta: float) -> void:
	if StateManager.current_state != StateManager.State.MENU:
		return

	if not rotation_enabled:
		return

	var rotation_input := Input.get_axis(
		"menu_left",
		"menu_right"
	)

	rig.rotation.y += (
		deg_to_rad(rotation_speed_degrees)
		* rotation_input
		* delta
	)
	
func set_rotation_enabled(enabled: bool) -> void:
	rotation_enabled = enabled
