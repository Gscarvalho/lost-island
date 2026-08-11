class_name MenuAvatar
extends Node3D

@export var rotation_speed_degrees: float = 120.0

@onready var rig: Node3D = $Rig
@onready var weapon_preview: Node3D = %WeaponPreview
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var rotation_enabled: bool = false


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


func sync_loadout(show_weapon: bool) -> void:
	weapon_preview.visible = show_weapon

	if show_weapon:
		animation_player.play(
			"2H_Melee_Idle"
		)
	else:
		animation_player.play(
			"Idle"
		)


func set_rotation_enabled(enabled: bool) -> void:
	rotation_enabled = enabled
