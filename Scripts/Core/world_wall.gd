class_name WorldWall
extends Node3D

var target

func _on_area_3d_body_entered(body: Node3D) -> void:
	
	if body == null:
		return
	if body is Player:
		target = body as Player
		_debug_player_return_to_zero()
		

func _debug_player_return_to_zero() -> void:
	StateManager.set_state(StateManager.State.WEAPON)
	await get_tree().create_timer(2.0).timeout		
	target.global_position = Vector3.ZERO
	StateManager.set_state(StateManager.State.PLAY)
