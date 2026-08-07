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
@onready var menu_avatar: MenuAvatar = %MenuAvatar
@onready var inventory_page: Control = $InventoryPage
@onready var settings_page: Control = $SettingsPage
@onready var avatar_viewport_layer: SubViewportContainer = $AvatarViewportLayer
@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var exit_game_button: TextureButton = %ExitGameButton
@onready var mana_fire: VBoxContainer = %ManaFire
@onready var mana_water: VBoxContainer = %ManaWater
@onready var mana_light: VBoxContainer = %ManaLight
var volume_editing := false
var player: PlayerSkin
var menu_tween: Tween
enum MenuPage {
	SETTINGS,
	CHARACTER,
	INVENTORY
}

var current_page: MenuPage = MenuPage.CHARACTER
var page_tween: Tween

func _ready() -> void:
	StateManager.state_changed.connect(_toggle_menu)
	exit_game_button.pressed.connect(_on_exit_game_pressed)
	master_volume_slider.value_changed.connect(
		_on_master_volume_changed
	)
	
	master_volume_slider.focus_neighbor_bottom = (
	master_volume_slider.get_path_to(exit_game_button)
	)
	exit_game_button.focus_neighbor_top = (
		exit_game_button.get_path_to(master_volume_slider)
	)
	
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
	_apply_page_positions()
	
	
func _on_exit_game_pressed() -> void:
	get_tree().quit()

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
	if current_page == MenuPage.SETTINGS:
		volume_editing = false
		master_volume_slider.grab_focus()
	elif current_page == MenuPage.CHARACTER:
		mana_fire.grab_focus()
	
	if menu_tween != null:
		menu_tween.kill()

	if state == StateManager.State.MENU:
		visible = true
		mouse_filter = Control.MOUSE_FILTER_STOP

		main.modulate.a = 0.0
		screen.modulate.a = 0.0
		menu_avatar.sync_loadout(player.weapon_active)
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

func _change_page(new_page: MenuPage) -> void:
	if current_page == new_page:
		return

	if page_tween != null:
		page_tween.kill()

	current_page = new_page
	
	volume_editing = false

	if current_page == MenuPage.SETTINGS:
		master_volume_slider.grab_focus()
	elif current_page == MenuPage.CHARACTER:
		mana_fire.grab_focus()
	else:
		mana_fire.release_focus()
		mana_water.release_focus()
		mana_light.release_focus()
		master_volume_slider.release_focus()
		exit_game_button.release_focus()

	var screen_height := get_viewport_rect().size.y
	var page_offset := _get_page_offset(screen_height)

	page_tween = create_tween()
	page_tween.set_parallel(true)
	page_tween.set_trans(Tween.TRANS_QUAD)
	page_tween.set_ease(Tween.EASE_IN_OUT)

	page_tween.tween_property(
		settings_page,
		"position:y",
		-screen_height + page_offset,
		0.35
	)

	page_tween.tween_property(
		main,
		"position:y",
		page_offset,
		0.35
	)

	page_tween.tween_property(
		avatar_viewport_layer,
		"position:y",
		page_offset,
		0.35
	)

	page_tween.tween_property(
		inventory_page,
		"position:y",
		screen_height + page_offset,
		0.35
	)

func _apply_page_positions() -> void:
	var screen_height := get_viewport_rect().size.y
	var page_offset := _get_page_offset(screen_height)

	settings_page.position.y = -screen_height + page_offset
	main.position.y = page_offset
	avatar_viewport_layer.position.y = page_offset
	inventory_page.position.y = screen_height + page_offset

func _get_page_offset(screen_height: float) -> float:
	match current_page:
		MenuPage.SETTINGS:
			return screen_height

		MenuPage.INVENTORY:
			return -screen_height

		_:
			return 0.0

func _unhandled_input(event: InputEvent) -> void:
	if StateManager.current_state != StateManager.State.MENU:
		return

	if page_tween != null and page_tween.is_running():
		return

	if event.is_action_pressed("ui_page_up"):
		match current_page:
			MenuPage.INVENTORY:
				_change_page(MenuPage.CHARACTER)

			MenuPage.CHARACTER:
				_change_page(MenuPage.SETTINGS)

		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_page_down"):
		match current_page:
			MenuPage.CHARACTER:
				_change_page(MenuPage.INVENTORY)
				
			MenuPage.SETTINGS:
				_change_page(MenuPage.CHARACTER)

		get_viewport().set_input_as_handled()

func _on_master_volume_changed(value: float) -> void:
	var master_bus := AudioServer.get_bus_index("Master")

	if value <= 0.0:
		AudioServer.set_bus_mute(master_bus, true)
		return

	AudioServer.set_bus_mute(master_bus, false)

	var volume_db := linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(master_bus, volume_db)

func _input(event: InputEvent) -> void:
	if StateManager.current_state != StateManager.State.MENU:
		return

	if current_page != MenuPage.SETTINGS:
		return

	if page_tween != null and page_tween.is_running():
		return
	if mana_fire.has_focus():
		print("focused")
		var mana_level = mana_fire.get_child(1) as RichTextLabel
		mana_level.visible = true
		
	if master_volume_slider.has_focus():
		if event.is_action_pressed("ui_accept"):
			volume_editing = not volume_editing
			get_viewport().set_input_as_handled()
			return

		if volume_editing:
			# Left and right pass through to the HSlider.
			# Up and down stay locked until A is pressed again.
			if (
				event.is_action_pressed("ui_up")
				or event.is_action_pressed("ui_down")
			):
				get_viewport().set_input_as_handled()

			return

		# Prevent Left/Right from changing volume before A is pressed.
		if (
			event.is_action_pressed("ui_left")
			or event.is_action_pressed("ui_right")
		):
			get_viewport().set_input_as_handled()
			return

	if (
		exit_game_button.has_focus()
		and event.is_action_pressed("ui_page_down")
	):
		_change_page(MenuPage.CHARACTER)
		get_viewport().set_input_as_handled()
