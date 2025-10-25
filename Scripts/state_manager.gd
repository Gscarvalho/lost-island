#state_manager.gd
extends Node

enum State { TITLE, PLAY, MENU, WEAPON }

@onready var menus = get_tree().get_first_node_in_group("Menu")

signal state_changed(new_state)
var current_state: State = State.PLAY

func set_state(new_state: State) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(new_state)
