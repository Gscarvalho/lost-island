class_name MenuUI
extends Control

#region Enums
enum MenuPage {
	SETTINGS,
	CHARACTER,
	INVENTORY,
}
#endregion

#region Main Menu References
@onready var screen: ColorRect = $MenuBG
@onready var main: MarginContainer = $Main
@onready var inventory_page: Control = $InventoryPage
@onready var settings_page: Control = $SettingsPage
@onready var avatar_viewport_layer: SubViewportContainer = (
	%AvatarViewportLayer
)
@onready var menu_avatar: MenuAvatar = %MenuAvatar
#endregion

#region Character Page References
@onready var attack_value: RichTextLabel = (
	%ATKValue
)
@onready var defense_value: RichTextLabel = (
	%DEFValue
)
@onready var magic_attack_value: RichTextLabel = (
	%MATKValue
)
@onready var magic_defense_value: RichTextLabel = (
	%MDEFValue
)
@onready var speed_value: RichTextLabel = (
	%SPDValue
)
@onready var mana_fire: VBoxContainer = (
	%ManaFire
)
@onready var mana_water: VBoxContainer = (
	%ManaWater
)
@onready var mana_light: VBoxContainer = (
	%ManaLight
)

@onready var menu_health_bar: TextureProgressBar = (
	%MenuHealthBar
)
@onready var menu_health_label: RichTextLabel = (
	%MenuHealthLabel
)
@onready var menu_stamina_bar: TextureProgressBar = (
	%MenuStaminaBar
)
@onready var menu_stamina_label: RichTextLabel = (
	%MenuStaminaLabel
)
@onready var fire_mana_amount: RichTextLabel = (
	%FireManaAmount
)
@onready var water_mana_amount: RichTextLabel = (
	%WaterManaAmount
)
@onready var light_mana_amount: RichTextLabel = (
	%LightManaAmount
)





#endregion

#region Settings References
@onready var master_volume_slider: HSlider = (
	%MasterVolumeSlider
)
@onready var exit_game_button: TextureButton = (
	%ExitGameButton
)
#endregion

#region Skill Tree References
@onready var skill_tree_bg_icon: TextureRect = (
	$SkillTreeOverlay/HBoxContainer/SkillTreeBGIcon/BGIcon
)
@onready var skill_tree_overlay: Control = (
	$SkillTreeOverlay
)
@onready var skill_tree_bg: TextureRect = (
	$SkillTreeOverlay/SkillTreeBG
)
@onready var skill_tree_title: Label = (
	$SkillTreeOverlay/TitleContainer/SkillTreeTitle
)

@onready var skill_name: RichTextLabel = %SkillName
@onready var skill_power_value: RichTextLabel = %SkillPowerValue
@onready var skill_mana_cost_value: RichTextLabel = %SkillManaCostValue
@onready var skill_range_value: RichTextLabel = %SkillRangeValue
@onready var skill_description: RichTextLabel = %SkillDescription
@onready var action_input: RichTextLabel = %ActionInput

@onready var skill_power_box: Control = %SkillPowerBox
@onready var skill_mana_cost_box: Control = %SkillManaCostBox
@onready var skill_mana_rate_icon: TextureRect = %SkillManaRateIcon
@onready var skill_range_box: Control = %SkillRangeBox
@onready var actions_box: HBoxContainer = %ActionsBox

@onready var skill_points_label: RichTextLabel = (
	%SkillPointsLabel
)

@onready var fire_tree: SkillTree = %FireTree
@onready var water_tree: SkillTree = %WaterTree
#endregion

#region Loadout Popup References
@onready var loadout_popup: Control = %LoadoutPopup
@onready var loadout_skill_name: RichTextLabel = %LoadoutSkillName

@onready var slot_x_button: LoadoutSlotButton = %SlotX
@onready var slot_y_button: LoadoutSlotButton = %SlotY
@onready var slot_b_button: LoadoutSlotButton = %SlotB
@onready var slot_rt_x_button: LoadoutSlotButton = %SlotRTX
@onready var slot_rt_y_button: LoadoutSlotButton = %SlotRTY
@onready var slot_rt_b_button: LoadoutSlotButton = %SlotRTB
#endregion

#region Runtime State
var player_controller: Player
var character: PlayerCharacter

var current_page: MenuPage = MenuPage.CHARACTER

var active_skill_tree: SkillTree
var last_mana_focus: Control

var skill_tree_open := false

var menu_tween: Tween
var skill_tree_tween: Tween
var page_tween: Tween

var loadout_popup_open := false

var held_loadout_skill: Skills
var held_loadout_source_slot := -1

var last_skill_focus: Control
#endregion

#region Lifecycle
func _ready() -> void:
	_connect_signals()
	_configure_focus_navigation()
	_resolve_player_references()
	_initialize_menu()

func _connect_signals() -> void:
	fire_tree.skill_focused.connect(
		_on_tree_skill_focused
	)

	fire_tree.skill_activated.connect(
		_on_tree_skill_activated
	)

	water_tree.skill_focused.connect(
		_on_tree_skill_focused
	)

	water_tree.skill_activated.connect(
		_on_tree_skill_activated
	)

	mana_fire.focus_entered.connect(
		_on_mana_focused.bind(mana_fire)
	)

	mana_water.focus_entered.connect(
		_on_mana_focused.bind(mana_water)
	)

	mana_light.focus_entered.connect(
		_on_mana_focused.bind(mana_light)
	)

	StateManager.state_changed.connect(
		_toggle_menu
	)

	exit_game_button.pressed.connect(
		_on_exit_game_pressed
	)

	master_volume_slider.value_changed.connect(
		_on_master_volume_changed
	)

	slot_x_button.pressed.connect(
		_on_loadout_slot_pressed.bind(
			SkillLoadout.Slot.X
		)
	)

	slot_y_button.pressed.connect(
		_on_loadout_slot_pressed.bind(
			SkillLoadout.Slot.Y
		)
	)

	slot_b_button.pressed.connect(
		_on_loadout_slot_pressed.bind(
			SkillLoadout.Slot.B
		)
	)

	slot_rt_x_button.pressed.connect(
		_on_loadout_slot_pressed.bind(
			SkillLoadout.Slot.RT_X
		)
	)

	slot_rt_y_button.pressed.connect(
		_on_loadout_slot_pressed.bind(
			SkillLoadout.Slot.RT_Y
		)
	)

	slot_rt_b_button.pressed.connect(
		_on_loadout_slot_pressed.bind(
			SkillLoadout.Slot.RT_B
		)
	)

func _configure_focus_navigation() -> void:
	master_volume_slider.focus_neighbor_bottom = (
		master_volume_slider.get_path_to(
			exit_game_button
		)
	)

	exit_game_button.focus_neighbor_top = (
		exit_game_button.get_path_to(
			master_volume_slider
		)
	)

func _resolve_player_references() -> void:
	player_controller = (
		get_tree().get_first_node_in_group("Player")
		as Player
	)

	character = (
		player_controller.get_node("Character")
		as PlayerCharacter
	)

	player_controller.progression.skill_points_changed.connect(
		_update_skill_points
	)

	character.health_changed.connect(
		_update_health
	)

	character.stamina_changed.connect(
		_update_stamina
	)

func _initialize_menu() -> void:
	_update_skill_points(
		player_controller.progression.skill_points
	)

	_set_stats()

	var menu_is_open := (
		StateManager.current_state
		== StateManager.State.MENU
	)

	visible = menu_is_open

	main.modulate.a = (
		1.0 if menu_is_open else 0.0
	)

	screen.modulate.a = (
		1.0 if menu_is_open else 0.0
	)

	mouse_filter = (
		Control.MOUSE_FILTER_STOP
		if menu_is_open
		else Control.MOUSE_FILTER_IGNORE
	)

	_apply_page_positions()

	if menu_is_open:
		_update_page_focus()
#endregion

#region Menu Visibility
func _toggle_menu(state: StateManager.State) -> void:
	if menu_tween != null:
		menu_tween.kill()

	if state == StateManager.State.MENU:
		visible = true
		mouse_filter = Control.MOUSE_FILTER_STOP
		
		_update_page_focus()
			
		menu_avatar.set_rotation_enabled(
			current_page == MenuPage.CHARACTER
		)

		main.modulate.a = 0.0
		settings_page.modulate.a = 0.0
		inventory_page.modulate.a = 0.0
		avatar_viewport_layer.modulate.a = 0.0
		screen.modulate.a = 0.0
		menu_avatar.sync_loadout(
			character.is_physical_mode()
			and character.has_equipped_weapon()
		)
		_set_stats()

		menu_tween = create_tween()
		menu_tween.set_parallel(true)
		menu_tween.tween_property(
			screen,
			"modulate:a",
			1.0,
			0.1
		)

		menu_tween.tween_property(
			main,
			"modulate:a",
			1.0,
			0.2
		)

		menu_tween.tween_property(
			settings_page,
			"modulate:a",
			1.0,
			0.2
		)

		menu_tween.tween_property(
			inventory_page,
			"modulate:a",
			1.0,
			0.2
		)

		menu_tween.tween_property(
			avatar_viewport_layer,
			"modulate:a",
			1.0,
			0.2
		)
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

		menu_avatar.set_rotation_enabled(
			false
		)

		menu_tween = create_tween()
		menu_tween.set_parallel(true)

		# Page contents disappear slightly before
		# the background finishes fading.
		menu_tween.tween_property(
			main,
			"modulate:a",
			0.0,
			0.08
		)

		menu_tween.tween_property(
			settings_page,
			"modulate:a",
			0.0,
			0.08
		)

		menu_tween.tween_property(
			inventory_page,
			"modulate:a",
			0.0,
			0.08
		)

		menu_tween.tween_property(
			avatar_viewport_layer,
			"modulate:a",
			0.0,
			0.08
		)

		menu_tween.tween_property(
			screen,
			"modulate:a",
			0.0,
			0.12
		)

		menu_tween.finished.connect(
			_finish_hiding_menu
		)

func _finish_hiding_menu() -> void:
	if StateManager.current_state != StateManager.State.MENU:
		visible = false
#endregion

#region Page Navigation
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

func _update_page_focus() -> void:
	var character_active := (
		current_page == MenuPage.CHARACTER
	)

	var settings_active := (
		current_page == MenuPage.SETTINGS
	)

	_set_controls_focus_enabled(
		_get_mana_controls(),
		character_active
	)

	_set_controls_focus_enabled(
		_get_settings_controls(),
		settings_active
	)

	if character_active:
		_clear_mana_focus()

	elif settings_active:
		master_volume_slider.grab_focus()
#endregion

#region Character Stats
func _set_stats() -> void:
	var final_stats := character.current_stats

	# MenuUI may initialize before PlayerCharacter has built
	# its runtime stats, so fall back to the base values.
	if final_stats == null:
		final_stats = character.base_stats

	_set_stat_display(
		attack_value,
		final_stats.attack,
		character.base_stats.attack
	)

	_set_stat_display(
		defense_value,
		final_stats.defense,
		character.base_stats.defense
	)

	_set_stat_display(
		magic_attack_value,
		final_stats.m_attack,
		character.base_stats.m_attack
	)

	_set_stat_display(
		magic_defense_value,
		final_stats.m_defense,
		character.base_stats.m_defense
	)

	_set_stat_display(
		speed_value,
		final_stats.speed,
		character.base_stats.speed
	)
	
	_update_health(
	character.current_hp,
	final_stats.max_hp
	)

	_update_stamina(
		character.current_stamina,
		100.0
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

func _update_health(
	value: float,
	maximum: float
	) -> void:
	menu_health_label.text = (
		str(value).pad_decimals(0)
		+ "/"
		+ str(maximum).pad_decimals(0)
	)

	var tween := create_tween()

	tween.tween_property(
		menu_health_bar,
		"value",
		value,
		0.5
	)
	
func _update_stamina(
	value: float,
	maximum: float
	) -> void:
	menu_stamina_label.text = (
		str(value).pad_decimals(0)
		+ "/"
		+ str(maximum).pad_decimals(0)
	)

	var tween := create_tween()

	tween.tween_property(
		menu_stamina_bar,
		"value",
		value,
		0.5
	)
#endregion

#region Mana Focus
func _on_mana_focused(
	focused_mana: Control
	) -> void:
	for mana_control in _get_mana_controls():
		_set_mana_focus_visual(
			mana_control,
			mana_control == focused_mana
		)

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
	for mana_control in _get_mana_controls():
		mana_control.release_focus()
		_set_mana_focus_visual(
			mana_control,
			false
		)

func _get_mana_controls() -> Array[Control]:
	return [
		mana_fire,
		mana_water,
		mana_light,
	]


func _get_settings_controls() -> Array[Control]:
	return [
		master_volume_slider,
		exit_game_button,
	]

func _set_controls_focus_enabled(
	controls: Array[Control],
	enabled: bool
	) -> void:
	var focus_mode := (
		Control.FOCUS_ALL
		if enabled
		else Control.FOCUS_NONE
	)

	for control in controls:
		control.focus_mode = focus_mode
#endregion

#region Skill Tree
func _hide_all_skill_trees() -> void:
	fire_tree.visible = false
	water_tree.visible = false

func _get_skill_tree_for_type(
		skill_type: Skills.SkillType
	) -> SkillTree:
		match skill_type:
			Skills.SkillType.Fire:
				return fire_tree
			Skills.SkillType.Water:
				return water_tree
			_:
				return null

func _open_skill_tree(
	skill_type: Skills.SkillType,
	mana_control: Control
) -> bool:
	var tree := _get_skill_tree_for_type(
		skill_type
	)

	if tree == null:
		return false

	_hide_all_skill_trees()

	skill_tree_open = true
	last_mana_focus = mana_control
	active_skill_tree = tree

	skill_name.text = ""
	skill_description.text = (
		"Use D-Pad to select a skill."
	)
	action_input.text = ""

	skill_power_box.modulate.a = 0.0
	skill_mana_cost_box.modulate.a = 0.0
	skill_range_box.modulate.a = 0.0
	actions_box.modulate.a = 0.0

	active_skill_tree.refresh_unlock_states(
		player_controller.progression
	)

	active_skill_tree.visible = true

	_apply_skill_tree_visuals(
		active_skill_tree
	)

	if skill_tree_tween != null:
		skill_tree_tween.kill()

	skill_tree_overlay.visible = true
	skill_tree_overlay.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)
	skill_tree_overlay.modulate.a = 0.0

	_clear_mana_focus()
	menu_avatar.set_rotation_enabled(false)

	skill_tree_tween = create_tween()
	skill_tree_tween.set_trans(
		Tween.TRANS_QUAD
	)
	skill_tree_tween.set_ease(
		Tween.EASE_OUT
	)

	skill_tree_tween.tween_property(
		skill_tree_overlay,
		"modulate:a",
		1.0,
		0.2
	)

	return true

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

	skill_name.text = (
		skill.skill_name.to_upper()
	)

	skill_description.text = (
		skill.skill_description
	)

	_update_skill_action_text(skill)
	_update_skill_stat_text(skill)

	skill_power_box.modulate.a = 1.0
	skill_mana_cost_box.modulate.a = 1.0
	skill_range_box.modulate.a = 1.0
	actions_box.modulate.a = 1.0

func _on_tree_skill_activated(
	skill: Skills
) -> void:
	if skill == null:
		return

	var progression := (
		player_controller.progression
	)

	if progression.is_skill_unlocked(skill):
		_open_loadout_popup(skill)
		return

	if progression.try_unlock_skill(skill):
		active_skill_tree.refresh_unlock_states(
			progression
		)

		_update_skill_action_text(skill)
		_update_skill_stat_text(skill)

		print(
			"Unlocked ",
			skill.skill_name,
			"! Remaining points: ",
			progression.skill_points
		)

	else:
		_update_skill_action_text(skill)

		print(
			"Not enough skill points for ",
			skill.skill_name
		)

func _apply_skill_tree_visuals(tree: SkillTree) -> void:
	if tree == null:
		return

	skill_tree_title.text = (
		tree.tree_name.to_upper()
		+ " SKILL TREE"
	)

	skill_tree_bg_icon.texture = tree.background_icon
	skill_tree_bg_icon.self_modulate = tree.tree_color
	skill_tree_bg.self_modulate = (
		tree.tree_color
	)

	#skill_name.add_theme_color_override(
		#"default_color",
		#tree.tree_color
	#)

	var power_bg := (
		skill_power_value.get_parent_control()
		as TextureRect
	)

	var mana_bg := (
		skill_mana_cost_value.get_parent_control().get_parent_control()
		as TextureRect
	)

	var range_bg := (
		skill_range_value.get_parent_control()
		as TextureRect
	)

	power_bg.self_modulate = tree.tree_color
	mana_bg.self_modulate = tree.tree_color
	range_bg.self_modulate = tree.tree_color

func _update_skill_points(points: int) -> void:
	skill_points_label.text = (
		"SKILL POINTS: "
		+ str(points)
	)

func _update_skill_action_text(
	skill: Skills
) -> void:
	var progression := (
		player_controller.progression
	)

	if progression.is_skill_unlocked(skill):
		action_input.text = "EQUIP"
	else:
		action_input.text = "UNLOCK"

func _update_skill_stat_text(
	skill: Skills
) -> void:
	var progression := (
		player_controller.progression
	)

	if not progression.is_skill_unlocked(skill):
		skill_power_value.text = "LOCKED"
		skill_mana_cost_value.text = "LOCKED"
		skill_range_value.text = "LOCKED"
		
		skill_mana_rate_icon.visible = false
		return

	skill_power_value.text = (
		str(skill.skill_power).pad_decimals(0)
	)

	skill_mana_cost_value.text = (
		str(skill.skill_cost).pad_decimals(0)
	)

	skill_mana_rate_icon.visible = (
		skill.cost_type
		== Skills.CostType.PerSecond
	)

	skill_range_value.text = (
		_get_range_text(
			skill.skill_range
		)
	)

func _get_range_text(
	range_type: Skills.RangeType
) -> String:
	return (
		Skills.RangeType.keys()[
			range_type
		].to_upper()
		+ "-RANGE"
	)
#endregion

#region Loadout Popup
func _open_loadout_popup(
		skill: Skills
	) -> void:
		if skill == null:
			return

		var loadout := (
			player_controller
			.progression
			.skill_loadout
		)

		if loadout == null:
			return

		last_skill_focus = (
			get_viewport()
			.gui_get_focus_owner()
			as Control
		)

		loadout_popup_open = true
		loadout_popup.visible = true

		var current_slot := (
			loadout.get_skill_slot(
				skill
			)
		)

		if current_slot == -1:
			# The skill could not be auto-equipped,
			# usually because all six slots were full.
			# Open the editor already holding it.
			held_loadout_skill = skill
			held_loadout_source_slot = -1

		else:
			# It was already auto-equipped.
			# Open directly into normal editing mode.
			held_loadout_skill = null
			held_loadout_source_slot = -1

		_refresh_loadout_popup()

		if current_slot != -1:
			var current_button := (
				_get_loadout_button(
					current_slot
				)
			)

			if current_button != null:
				current_button.grab_focus()
				return

		slot_x_button.grab_focus()


func _close_loadout_popup() -> void:
	if not loadout_popup_open:
		return

	loadout_popup_open = false
	loadout_popup.visible = false

	held_loadout_skill = null
	held_loadout_source_slot = -1

	if (
		last_skill_focus != null
		and is_instance_valid(
			last_skill_focus
		)
	):
		last_skill_focus.grab_focus()


func _refresh_loadout_popup() -> void:
	if held_loadout_skill != null:
		loadout_skill_name.text = (
			held_loadout_skill
			.skill_name
			.to_upper()
		)
	else:
		loadout_skill_name.text = (
			"EDIT LOADOUT"
		)

	_update_loadout_button(
		slot_x_button,
		SkillLoadout.Slot.X
	)

	_update_loadout_button(
		slot_y_button,
		SkillLoadout.Slot.Y
	)

	_update_loadout_button(
		slot_b_button,
		SkillLoadout.Slot.B
	)

	_update_loadout_button(
		slot_rt_x_button,
		SkillLoadout.Slot.RT_X
	)

	_update_loadout_button(
		slot_rt_y_button,
		SkillLoadout.Slot.RT_Y
	)

	_update_loadout_button(
		slot_rt_b_button,
		SkillLoadout.Slot.RT_B
	)


func _update_loadout_button(
		button: LoadoutSlotButton,
		slot: int
	) -> void:
		var loadout := (
			player_controller
			.progression
			.skill_loadout
		)

		var assigned_skill := (
			loadout.get_skill(
				slot
			)
		)

		button.set_skill_display(
			assigned_skill,
			(
				held_loadout_skill != null
				and assigned_skill
				== held_loadout_skill
			)
		)


func _on_loadout_slot_pressed(
		slot: int
	) -> void:
		var loadout := (
			player_controller
			.progression
			.skill_loadout
		)

		if loadout == null:
			return

		# Nothing is currently being moved.
		# Pick up the skill in this slot.
		if held_loadout_skill == null:
			var slot_skill := (
				loadout.get_skill(
					slot
				)
			)

			if slot_skill == null:
				return

			held_loadout_skill = (
				slot_skill
			)

			held_loadout_source_slot = (
				slot
			)

			_refresh_loadout_popup()
			return

		# The held skill already belongs to the
		# loadout, so move/swap its two slots.
		if held_loadout_source_slot != -1:
			loadout.move_or_swap_slots(
				held_loadout_source_slot,
				slot
			)

			held_loadout_skill = null
			held_loadout_source_slot = -1

			_refresh_loadout_popup()
			return

		# The held skill is not currently equipped.
		# This happens when auto-equip found no
		# available empty slot.
		var displaced_skill := (
			loadout.get_skill(
				slot
			)
		)

		loadout.assign_skill(
			held_loadout_skill,
			slot
		)

		# Empty destination:
		# placement is complete.
		if displaced_skill == null:
			held_loadout_skill = null
			held_loadout_source_slot = -1

		# Occupied destination:
		# equip the new skill and pick up the
		# displaced one instead.
		else:
			held_loadout_skill = (
				displaced_skill
			)

			held_loadout_source_slot = -1

		_refresh_loadout_popup()


func _get_loadout_button(
		slot: int
	) -> LoadoutSlotButton:
		match slot:
			SkillLoadout.Slot.X:
				return slot_x_button

			SkillLoadout.Slot.Y:
				return slot_y_button

			SkillLoadout.Slot.B:
				return slot_b_button

			SkillLoadout.Slot.RT_X:
				return slot_rt_x_button

			SkillLoadout.Slot.RT_Y:
				return slot_rt_y_button

			SkillLoadout.Slot.RT_B:
				return slot_rt_b_button

			_:
				return null
#endregion

#region Settings
func _on_master_volume_changed(value: float) -> void:
	var master_bus := AudioServer.get_bus_index("Master")

	if value <= 0.0:
		AudioServer.set_bus_mute(master_bus, true)
		return

	AudioServer.set_bus_mute(master_bus, false)

	var volume_db := linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(master_bus, volume_db)

func _on_exit_game_pressed() -> void:
	if OS.is_debug_build():
		print("Exit disabled in debug build.")
		return

	get_tree().quit()
#endregion

#region Input
func _input(event: InputEvent) -> void:
	if StateManager.current_state != StateManager.State.MENU:
		return
		
	if loadout_popup_open:
		if event.is_action_pressed(
			"ui_cancel"
		):
			if held_loadout_skill != null:
				held_loadout_skill = null
				held_loadout_source_slot = -1

				_refresh_loadout_popup()
			else:
				_close_loadout_popup()

			get_viewport().set_input_as_handled()

		return
		
	if skill_tree_open:
		_handle_skill_tree_input(event)
		return
		
	if event.is_action_pressed("ui_cancel"):
		StateManager.set_state(
			StateManager.State.PLAY
		)
		
		get_viewport().set_input_as_handled()
		return
		
	if current_page == MenuPage.CHARACTER:
		if event.is_action_pressed("ui_accept"):
			_open_focused_skill_tree()
		
		return
		
	if current_page == MenuPage.SETTINGS:
		_handle_settings_boundary_input(event)

func _is_directional_input(
	event: InputEvent
	) -> bool:
	return (
		event.is_action_pressed("ui_up")
		or event.is_action_pressed("ui_down")
		or event.is_action_pressed("ui_left")
		or event.is_action_pressed("ui_right")
	)

func _handle_skill_tree_input(
	event: InputEvent
	) -> bool:
	if event.is_action_pressed("ui_cancel"):
		_close_skill_tree()
		get_viewport().set_input_as_handled()
		return true

	if active_skill_tree == null:
		return false

	if active_skill_tree.has_skill_focus():
		return false

	if not _is_directional_input(event):
		return false

	active_skill_tree.grab_default_focus()
	get_viewport().set_input_as_handled()

	return true

func _open_focused_skill_tree() -> bool:
	var opened := false

	if mana_fire.has_focus():
		opened = _open_skill_tree(
			Skills.SkillType.Fire,
			mana_fire
		)

	elif mana_water.has_focus():
		opened = _open_skill_tree(
			Skills.SkillType.Water,
			mana_water
		)

	elif mana_light.has_focus():
		opened = _open_skill_tree(
			Skills.SkillType.Light,
			mana_light
		)

	if not opened:
		return false

	get_viewport().set_input_as_handled()
	return true

func _handle_settings_boundary_input(
	event: InputEvent
	) -> bool:
	if (
		exit_game_button.has_focus()
		and event.is_action_pressed("ui_page_down")
	):
		_change_page(MenuPage.CHARACTER)
		get_viewport().set_input_as_handled()
		return true

	return false


func _unhandled_input(event: InputEvent) -> void:
	if StateManager.current_state != StateManager.State.MENU:
		return

	if skill_tree_open:
		return

	if page_tween != null and page_tween.is_running():
		return

	if _handle_character_focus_entry(event):
		return

	_handle_page_navigation(event)

func _mana_has_focus() -> bool:
	return (
		mana_fire.has_focus()
		or mana_water.has_focus()
		or mana_light.has_focus()
	)

func _handle_character_focus_entry(
	event: InputEvent
	) -> bool:
	if current_page != MenuPage.CHARACTER:
		return false

	if _mana_has_focus():
		return false

	if event.is_action_pressed("ui_down"):
		mana_fire.grab_focus()

	elif event.is_action_pressed("ui_up"):
		mana_light.grab_focus()

	else:
		return false

	get_viewport().set_input_as_handled()
	return true

func _handle_page_navigation(
	event: InputEvent
	) -> bool:
	var new_page := current_page

	if event.is_action_pressed("ui_page_up"):
		match current_page:
			MenuPage.INVENTORY:
				new_page = MenuPage.CHARACTER

			MenuPage.CHARACTER:
				new_page = MenuPage.SETTINGS

	elif event.is_action_pressed("ui_page_down"):
		match current_page:
			MenuPage.SETTINGS:
				new_page = MenuPage.CHARACTER

			MenuPage.CHARACTER:
				new_page = MenuPage.INVENTORY

	else:
		return false

	if new_page == current_page:
		return false

	_change_page(new_page)
	get_viewport().set_input_as_handled()

	return true
#endregion
