extends Control
class_name TitleMenu
@onready var options_box: VBoxContainer = $OptionsBox
@onready var screen: TextureRect = $Screen
@onready var camera: Camera3D = $"../../Camera3D"

func _ready() -> void:
	StateManager.state_changed.connect(_toggle_menu)
	StateManager.set_state(StateManager.State.TITLE)
	
func _toggle_menu(state: StateManager.State) -> void:
	if state == StateManager.State.TITLE:
		var tween = create_tween()
		var tween3 = create_tween()
		tween.tween_property(options_box,"modulate:a",1.0, 0.5)
		tween3.tween_property(screen,"modulate:a", 1.0, 0.3)
		var tween_cam = create_tween()
		tween_cam.tween_property(camera,"position:y",3.5, 4.5)
		var tween_cam2 = create_tween()
		tween_cam2.tween_property(camera,"position:z",3.5, 4.5)
	#else:
	##elif state == StateManager.State.PLAY:
		#var tween = create_tween()
		#var tween3 = create_tween()
		#tween.tween_property(options_box,"modulate:a",0.0, 0.5)
		##tween2.tween_property(options_box,"position:x",1280.0, 0.5)
		#tween3.tween_property(screen,"modulate:a", 0.0, 0.5)
		#await get_tree().create_timer(1).timeout
