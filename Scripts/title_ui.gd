extends Control
class_name TitleMenu
@onready var options_box: VBoxContainer = $OptionsBox
@onready var screen: TextureRect = $Screen

func _ready() -> void:
	StateManager.state_changed.connect(_toggle_menu)

func _toggle_menu(state: StateManager.State) -> void:
	if state == StateManager.State.TITLE:
		var tween = create_tween()
		var tween2 = create_tween()
		var tween3 = create_tween()
		tween.tween_property(options_box,"modulate:a",1.0, 0.5)
		tween2.tween_property(options_box,"position:x",780.0, 0.5)
		tween3.tween_property(screen,"modulate:a", 1.0, 0.3)
	else:
	#elif state == StateManager.State.PLAY:
		var tween = create_tween()
		var tween2 = create_tween()
		var tween3 = create_tween()
		tween.tween_property(options_box,"modulate:a",0.0, 0.5)
		tween2.tween_property(options_box,"position:x",1280.0, 0.5)
		tween3.tween_property(screen,"modulate:a", 0.0, 0.5)
		#await get_tree().create_timer(1).timeout
