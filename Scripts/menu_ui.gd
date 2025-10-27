extends Control
@onready var screen: TextureRect = $Screen
@onready var main: HBoxContainer = $Main
@onready var stats_ui: VBoxContainer = $Main/Stats

func _ready() -> void:
	StateManager.state_changed.connect(_toggle_menu)
	_set_stats()

func _toggle_menu(state: StateManager.State) -> void:
	if state == StateManager.State.MENU:
		#var tween1 = create_tween()
		#tween1.tween_property(main,"const", 0, 0.5)
		var tween2 = create_tween()
		tween2.tween_property(main,"modulate:a", 1.0, 0.3)
		var tween3 = create_tween()
		tween3.tween_property(screen,"modulate:a", 1.0, 0.1)
	else:
	#elif state == StateManager.State.PLAY:
		#var tween1 = create_tween()
		#tween1.tween_property(main,"position:x", 1280, 0.5)
		var tween2 = create_tween()
		tween2.tween_property(main,"modulate:a", 0.0, 0.1)
		var tween3 = create_tween()
		tween3.tween_property(screen,"modulate:a", 0.0, 0.1)
		

func _set_stats() -> void:
	var player = get_tree().get_first_node_in_group('Player').get_node("Skin") as PlayerSkin
	stats_ui.get_child(1).get_child(1).get_child(0).text = str(player.base_stats.attack).pad_decimals(0)
	stats_ui.get_child(2).get_child(1).get_child(0).text = str(player.base_stats.defense).pad_decimals(0)
	stats_ui.get_child(3).get_child(1).get_child(0).text = str(player.base_stats.m_attack).pad_decimals(0)
	stats_ui.get_child(4).get_child(1).get_child(0).text = str(player.base_stats.m_defense).pad_decimals(0)
	stats_ui.get_child(5).get_child(1).get_child(0).text = str(player.base_stats.speed).pad_decimals(0)
		#a.text = player.base_stats.get_property_list().
	
	
