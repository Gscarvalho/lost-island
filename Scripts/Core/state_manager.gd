extends Node


enum State {
	TITLE,
	PLAY,
	MENU,
	WEAPON,
}


signal state_changed(
	new_state: State
)


var current_state: State = State.PLAY


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(
	event: InputEvent
) -> void:
	if not event.is_action_pressed(
		"menu"
	):
		return

	if (
		event is InputEventKey
		and event.echo
	):
		return

	match current_state:
		State.PLAY:
			set_state(
				State.MENU
			)

		State.TITLE:
			set_state(
				State.MENU
			)

		State.MENU:
			set_state(
				State.PLAY
			)

		_:
			return

	get_viewport().set_input_as_handled()


func set_state(
	new_state: State
) -> void:
	if current_state == new_state:
		return

	current_state = new_state

	get_tree().paused = (
		current_state
		== State.MENU
	)

	state_changed.emit(
		new_state
	)
