extends Control
@onready var screen: TextureRect = $MenuBG
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
@onready var skill_tree_bg: TextureRect = $SkillTreeOverlay/SkillTreeBG
@onready var bg_icon: TextureRect = $SkillTreeOverlay/SkillTreeBGIcon/BGIcon
@onready var skill_tree_overlay: Control = $SkillTreeOverlay
@onready var skill_tree_title: Label = $SkillTreeOverlay/TitleContainer/SkillTreeTitle
@onready var skill_name_r: RichTextLabel = %SkillNameR
@onready var skill_name_l: RichTextLabel = %SkillNameL
@onready var skill_description_r: RichTextLabel = %SkillDescriptionR
@onready var skill_description_l: RichTextLabel = %SkillDescriptionL
@onready var skill_input_r: RichTextLabel = %SkillInputR
@onready var skill_input_l: RichTextLabel = %SkillInputL
@onready var fire_tree: SkillTree = %FireTree
var active_skill_tree: SkillTree





var last_mana_focus: Control
var skill_tree_open := false
var volume_editing := false
var player: PlayerSkin
var menu_tween: Tween
var skill_tree_tween: Tween
enum MenuPage {
	SETTINGS,
	CHARACTER,
	INVENTORY
}

var current_page: MenuPage = MenuPage.CHARACTER
var page_tween: Tween

func _ready() -> void:
	fire_tree.skill_focused.connect(
		_on_tree_skill_focused
	)

	fire_tree.skill_activated.connect(
		_on_tree_skill_activated
	)
	mana_fire.focus_entered.connect(
		_on_mana_focused.bind("Fire")
	)

	mana_water.focus_entered.connect(
		_on_mana_focused.bind("Water")
	)

	mana_light.focus_entered.connect(
		_on_mana_focused.bind("Light")
	)
	
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
	if menu_is_open:
		_update_page_focus()

func _on_mana_focused(mana_name: String) -> void:
	print("Mana focused: ", mana_name)

	_set_mana_focus_visual(mana_fire, mana_name == "Fire")
	_set_mana_focus_visual(mana_water, mana_name == "Water")
	_set_mana_focus_visual(mana_light, mana_name == "Light")
	
func _set_mana_focus_visual(
	mana_control: Control,
	is_focused: bool
	) -> void:
	var mana_bg := mana_control.get_child(0) as Control

	mana_bg.pivot_offset = mana_bg.size / 2.0

	var target_scale := Vector2.ONE

	if is_focused:
		target_scale = Vector2(1.1, 1.1)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		mana_bg,
		"scale",
		target_scale,
		0.12
	)

func _clear_mana_focus() -> void:
	mana_fire.release_focus()
	mana_water.release_focus()
	mana_light.release_focus()

	_set_mana_focus_visual(mana_fire, false)
	_set_mana_focus_visual(mana_water, false)
	_set_mana_focus_visual(mana_light, false)

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

func _open_skill_tree(
	mana_name: String,
	mana_control: Control
	) -> void:
	skill_tree_open = true
	last_mana_focus = mana_control
	active_skill_tree = null
	skill_name_r.text = ""
	skill_description_r.text = ""
	skill_input_r.text = ""

	skill_name_l.text = ""
	skill_description_l.text = ""
	skill_input_l.text = ""
	match mana_name:
		"Fire":
			active_skill_tree = fire_tree
			fire_tree.visible = active_skill_tree == fire_tree
	skill_tree_title.text = mana_name.to_upper() + " SKILL TREE"

	if skill_tree_tween != null:
		skill_tree_tween.kill()

	skill_tree_overlay.visible = true
	skill_tree_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	skill_tree_overlay.modulate.a = 0.0

	mana_fire.release_focus()
	mana_water.release_focus()
	mana_light.release_focus()

	menu_avatar.set_rotation_enabled(false)

	skill_tree_tween = create_tween()
	skill_tree_tween.set_trans(Tween.TRANS_QUAD)
	skill_tree_tween.set_ease(Tween.EASE_OUT)

	skill_tree_tween.tween_property(
		skill_tree_overlay,
		"modulate:a",
		1.0,
		0.2
	)

func _close_skill_tree() -> void:
	if not skill_tree_open:
		return

	skill_tree_open = false

	if skill_tree_tween != null:
		skill_tree_tween.kill()

	skill_tree_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	skill_tree_tween = create_tween()
	skill_tree_tween.set_trans(Tween.TRANS_QUAD)
	skill_tree_tween.set_ease(Tween.EASE_IN)

	skill_tree_tween.tween_property(
		skill_tree_overlay,
		"modulate:a",
		0.0,
		0.15
	)

	await skill_tree_tween.finished

	skill_tree_overlay.visible = false

	if current_page == MenuPage.CHARACTER:
		menu_avatar.set_rotation_enabled(true)

		if last_mana_focus != null:
			last_mana_focus.grab_focus()

func _on_tree_skill_focused(skill: Skills) -> void:
	if skill == null:
		return

	skill_name_r.text = skill.skill_name.to_upper()
	skill_description_r.text = skill.skill_description
	skill_input_r.text = "INPUT: UNASSIGNED"

func _on_tree_skill_activated(skill: Skills) -> void:
	if skill == null:
		return

	print(
		"Selected: ",
		skill.skill_name,
		" | Unlock cost: ",
		skill.unlock_cost
	)

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
		
		if current_page == MenuPage.SETTINGS:
			volume_editing = false
			master_volume_slider.grab_focus()
			
		elif current_page == MenuPage.CHARACTER:
			_clear_mana_focus()
			
		menu_avatar.set_rotation_enabled(
			current_page == MenuPage.CHARACTER
		)

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
		menu_avatar.set_rotation_enabled(false)
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
	#mana.get_child(0).get_child(1).text = "" #make Mana Levels
	#mana.get_child(1).get_child(1).text = "" #make Mana Levels
	#mana.get_child(2).get_child(1).text = "" #make Mana Levels
	
		#a.text = player.base_stats.get_property_list().

func _change_page(new_page: MenuPage) -> void:
	if current_page == new_page:
		return

	if page_tween != null:
		page_tween.kill()

	current_page = new_page
	_update_page_focus()
	menu_avatar.set_rotation_enabled(
	current_page == MenuPage.CHARACTER
	)
	
	volume_editing = false

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
	if skill_tree_open:
		return
	if page_tween != null and page_tween.is_running():
		return

	if current_page == MenuPage.CHARACTER:
		var mana_has_focus := (
			mana_fire.has_focus()
			or mana_water.has_focus()
			or mana_light.has_focus()
		)

		if not mana_has_focus:
			if event.is_action_pressed("ui_down"):
				mana_fire.grab_focus()
				get_viewport().set_input_as_handled()
				return

			elif event.is_action_pressed("ui_up"):
				mana_light.grab_focus()
				get_viewport().set_input_as_handled()
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
	if skill_tree_open:
		if event.is_action_pressed("ui_cancel"):
			_close_skill_tree()
			get_viewport().set_input_as_handled()
			return

		if active_skill_tree != null:
			if not active_skill_tree.has_skill_focus():
				var directional_input := (
					event.is_action_pressed("ui_up")
					or event.is_action_pressed("ui_down")
					or event.is_action_pressed("ui_left")
					or event.is_action_pressed("ui_right")
				)

				if directional_input:
					active_skill_tree.grab_default_focus()
					get_viewport().set_input_as_handled()
					return

		return

	if current_page == MenuPage.CHARACTER and not skill_tree_open:
		if event.is_action_pressed("ui_accept"):
			if mana_fire.has_focus():
				_open_skill_tree("Fire", mana_fire)
				get_viewport().set_input_as_handled()
				return

			if mana_water.has_focus():
				_open_skill_tree("Water", mana_water)
				get_viewport().set_input_as_handled()
				return

			if mana_light.has_focus():
				_open_skill_tree("Light", mana_light)
				get_viewport().set_input_as_handled()
				return

	if current_page != MenuPage.SETTINGS:
		return

	if page_tween != null and page_tween.is_running():
		return
		
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

func _update_page_focus() -> void:
	var character_active := current_page == MenuPage.CHARACTER
	var settings_active := current_page == MenuPage.SETTINGS

	mana_fire.focus_mode = (
		Control.FOCUS_ALL
		if character_active
		else Control.FOCUS_NONE
	)

	mana_water.focus_mode = (
		Control.FOCUS_ALL
		if character_active
		else Control.FOCUS_NONE
	)

	mana_light.focus_mode = (
		Control.FOCUS_ALL
		if character_active
		else Control.FOCUS_NONE
	)

	master_volume_slider.focus_mode = (
		Control.FOCUS_ALL
		if settings_active
		else Control.FOCUS_NONE
	)

	exit_game_button.focus_mode = (
		Control.FOCUS_ALL
		if settings_active
		else Control.FOCUS_NONE
	)

	if character_active:
		_clear_mana_focus()

	elif settings_active:
		master_volume_slider.grab_focus()
