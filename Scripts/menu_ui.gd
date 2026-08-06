extends Control
@onready var screen: TextureRect = $Screen
@onready var main: MarginContainer = $Main
@onready var stats: VBoxContainer = $Main/Seperator/Stats
@onready var current: VBoxContainer = $Main/Seperator/Player/Current
@onready var mana: VBoxContainer = $Main/Seperator/Mana
var player: PlayerSkin

func _ready() -> void:
	StateManager.state_changed.connect(_toggle_menu)

	player = get_tree().get_first_node_in_group("Player").get_child(0) as PlayerSkin
	player.health_changed.connect(_update_health)
	player.stamina_changed.connect(_update_stamina)

	_set_stats()
	
func _set_stat_display(
	label: RichTextLabel,
	final_value: float,
	normal_value: float
) -> void:
	var bonus := final_value - normal_value
	var final_text := str(final_value).pad_decimals(0)

	if bonus > 0.0:
		label.text = (
			final_text
			+ " (+"
			+ str(bonus).pad_decimals(0)
			+ ")"
		)
	elif bonus < 0.0:
		label.text = (
			final_text
			+ " ("
			+ str(bonus).pad_decimals(0)
			+ ")"
		)
	else:
		label.text = final_text
	
func _update_health(value: float, maximum: float) -> void:
	current.get_child(0).get_child(0).text = (
		str(value).pad_decimals(0)
		+ "/"
		+ str(maximum).pad_decimals(0)
	)

	var tween = create_tween()
	tween.tween_property(current.get_child(0), "value", value, 0.5)


func _update_stamina(value: float, maximum: float) -> void:
	current.get_child(1).get_child(0).text = (
		str(value).pad_decimals(0)
		+ "/"
		+ str(maximum).pad_decimals(0)
	)

	var tween = create_tween()
	tween.tween_property(current.get_child(1), "value", value, 0.5)

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
	#stats.get_child(1).get_child(1).get_child(0).text = str(player.base_stats.attack).pad_decimals(0)
	#stats.get_child(2).get_child(1).get_child(0).text = str(player.base_stats.defense).pad_decimals(0)
	#stats.get_child(3).get_child(1).get_child(0).text = str(player.base_stats.m_attack).pad_decimals(0)
	#stats.get_child(4).get_child(1).get_child(0).text = str(player.base_stats.m_defense).pad_decimals(0)
	#stats.get_child(5).get_child(1).get_child(0).text = str(player.base_stats.speed).pad_decimals(0)
	var normal_stats := player.stats_without_weapon

	if normal_stats == null:
		normal_stats = player.base_stats

	_set_stat_display(
		stats.get_child(1).get_child(1).get_child(0) as RichTextLabel,
		player.base_stats.attack,
		normal_stats.attack
	)

	_set_stat_display(
		stats.get_child(2).get_child(1).get_child(0) as RichTextLabel,
		player.base_stats.defense,
		normal_stats.defense
	)

	_set_stat_display(
		stats.get_child(3).get_child(1).get_child(0) as RichTextLabel,
		player.base_stats.m_attack,
		normal_stats.m_attack
	)

	_set_stat_display(
		stats.get_child(4).get_child(1).get_child(0) as RichTextLabel,
		player.base_stats.m_defense,
		normal_stats.m_defense
	)

	_set_stat_display(
		stats.get_child(5).get_child(1).get_child(0) as RichTextLabel,
		player.base_stats.speed,
		normal_stats.speed
	)
	
	
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
	
	
