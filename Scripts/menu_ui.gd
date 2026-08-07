extends Control
@onready var screen: TextureRect = $Screen
@onready var main: MarginContainer = $Main
@onready var stats: VBoxContainer = $Main/Seperator/Stats
@onready var current: VBoxContainer = $Main/Seperator/Player/Current
@onready var mana: VBoxContainer = $Main/Seperator/Mana
@onready var attack_value: RichTextLabel = %ATKValue
@onready var defense_value: RichTextLabel = %DEFValue
@onready var magic_attack_value: RichTextLabel = %MATKValue
@onready var magic_defense_value: RichTextLabel = %MDEFValue
@onready var speed_value: RichTextLabel = %SPDValue
var player: PlayerSkin
var menu_tween: Tween

func _ready() -> void:
	StateManager.state_changed.connect(_toggle_menu)

	player = get_tree().get_first_node_in_group("Player").get_child(0) as PlayerSkin
	player.health_changed.connect(_update_health)
	player.stamina_changed.connect(_update_stamina)

	_set_stats()
	var menu_is_open := StateManager.current_state == StateManager.State.MENU

	visible = menu_is_open
	main.modulate.a = 1.0 if menu_is_open else 0.0
	screen.modulate.a = 1.0 if menu_is_open else 0.0
	mouse_filter = (
		Control.MOUSE_FILTER_STOP
		if menu_is_open
		else Control.MOUSE_FILTER_IGNORE
	)
	
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
	if menu_tween != null:
		menu_tween.kill()

	if state == StateManager.State.MENU:
		visible = true
		mouse_filter = Control.MOUSE_FILTER_STOP

		main.modulate.a = 0.0
		screen.modulate.a = 0.0

		_set_stats()

		menu_tween = create_tween()
		menu_tween.set_parallel(true)
		menu_tween.tween_property(screen, "modulate:a", 1.0, 0.1)
		menu_tween.tween_property(main, "modulate:a", 1.0, 0.3)

	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

		menu_tween = create_tween()
		menu_tween.set_parallel(true)
		menu_tween.tween_property(main, "modulate:a", 0.0, 0.1)
		menu_tween.tween_property(screen, "modulate:a", 0.0, 0.1)
		menu_tween.finished.connect(_finish_hiding_menu)


func _finish_hiding_menu() -> void:
	if StateManager.current_state != StateManager.State.MENU:
		visible = false

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
		attack_value,
		player.base_stats.attack,
		normal_stats.attack
	)

	_set_stat_display(
		defense_value,
		player.base_stats.defense,
		normal_stats.defense
	)

	_set_stat_display(
		magic_attack_value,
		player.base_stats.m_attack,
		normal_stats.m_attack
	)

	_set_stat_display(
		magic_defense_value,
		player.base_stats.m_defense,
		normal_stats.m_defense
	)

	_set_stat_display(
		speed_value,
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
	
	
