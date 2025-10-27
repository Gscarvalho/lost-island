extends Control
@onready var screen: TextureRect = $Screen
@onready var main: HBoxContainer = $Main
@onready var stats: VBoxContainer = $Main/Stats
@onready var current: VBoxContainer = $Main/Player/Current
@onready var mana: VBoxContainer = $Main/Mana

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
		_set_stats()
	else:
	#elif state == StateManager.State.PLAY:
		#var tween1 = create_tween()
		#tween1.tween_property(main,"position:x", 1280, 0.5)
		var tween2 = create_tween()
		tween2.tween_property(main,"modulate:a", 0.0, 0.1)
		var tween3 = create_tween()
		tween3.tween_property(screen,"modulate:a", 0.0, 0.1)
		

func _set_stats() -> void:
	var player = get_tree().get_first_node_in_group('Player').get_child(0) as PlayerSkin
	stats.get_child(1).get_child(1).get_child(0).text = str(player.base_stats.attack).pad_decimals(0)
	stats.get_child(2).get_child(1).get_child(0).text = str(player.base_stats.defense).pad_decimals(0)
	stats.get_child(3).get_child(1).get_child(0).text = str(player.base_stats.m_attack).pad_decimals(0)
	stats.get_child(4).get_child(1).get_child(0).text = str(player.base_stats.m_defense).pad_decimals(0)
	stats.get_child(5).get_child(1).get_child(0).text = str(player.base_stats.speed).pad_decimals(0)
	current.get_child(0).get_child(0).text = str(player.current_hp).pad_decimals(0) + "/" + str(player.base_stats.max_hp).pad_decimals(0)
	var tween = create_tween()
	tween.tween_property(current.get_child(0),"value", player.current_hp, 0.5)
	current.get_child(1).get_child(0).text = str(player.current_stamina).pad_decimals(0) + "/100"
	var tween2 = create_tween()
	tween2.tween_property(current.get_child(1),"value", player.current_stamina, 0.5)
	mana.get_child(0).get_child(1).text = "" #make Mana Levels
	mana.get_child(1).get_child(1).text = "" #make Mana Levels
	mana.get_child(2).get_child(1).text = "" #make Mana Levels
	
		#a.text = player.base_stats.get_property_list().
	
	
