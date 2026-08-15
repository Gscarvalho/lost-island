# player_ui.gd
class_name PlayerHUD
extends Control

#region References
@onready var player: Player = (
	get_parent() as Player
)

@onready var character: PlayerCharacter = (
	player.get_node("Character")
	as PlayerCharacter
)

@onready var hitpoints: TextureProgressBar = (
	%Hitpoints
)

@onready var stamina: TextureProgressBar = (
	%Stamina
)

@onready var weapon_icon_image: TextureRect = (
	%WeaponIconImage
)

@onready var circle_timer: TextureProgressBar = (
	%CircleTimer
)

@onready var weapon_choice_timer: Timer = (
	$"../Timers/WeaponChoiceTimer"
)

@onready var loadout_name_x: RichTextLabel = (
	%LoadoutNameX
)

@onready var loadout_name_y: RichTextLabel = (
	%LoadoutNameY
)

@onready var loadout_name_b: RichTextLabel = (
	%LoadoutNameB
)

@onready var loadout_name_lt_x: RichTextLabel = (
	%LoadoutNameLTX
)

@onready var loadout_name_lt_y: RichTextLabel = (
	%LoadoutNameLTY
)

@onready var loadout_name_lt_b: RichTextLabel = (
	%LoadoutNameLTB
)

@onready var inputs: VBoxContainer = (
	%Inputs
)

@onready var inputs_lt: VBoxContainer = (
	%InputsRT
)
@onready var timer_indicator: MarginContainer = (
	%TimerIndicator
)
@onready var water_mana: Panel = (
	%WaterMana
)
@onready var water_mana_amount: RichTextLabel = (
	%WaterManaAmount
)
@onready var light_mana: Panel = (
	%LightMana
)
@onready var light_mana_amount: RichTextLabel = (
	%LightManaAmount
)
@onready var fire_mana: Panel = (
	%FireMana
)
@onready var fire_mana_amount: RichTextLabel = (
	%FireManaAmount
)



#endregion

#region Runtime State
var timer_tween: Tween
#endregion

#region Lifecycle
func _ready() -> void:
	_connect_signals()
	_initialize_display()


func _process(_delta: float) -> void:
	_update_input_layer()

	if StateManager.current_state != StateManager.State.WEAPON:
		return

	circle_timer.value = (
		weapon_choice_timer.time_left
	)
#endregion


#region Setup
func _connect_signals() -> void:
	StateManager.state_changed.connect(
		_on_state_changed
	)

	character.health_changed.connect(
		_on_health_changed
	)

	character.stamina_changed.connect(
		_on_stamina_changed
	)

	character.combat_mode_changed.connect(
		_on_combat_mode_changed
	)
	
	character.mana_changed.connect(
		_on_mana_changed
	)

	var elemental_loadout := (
		player.progression.skill_loadout
	)

	if elemental_loadout != null:
		elemental_loadout.loadout_changed.connect(
			_refresh_loadout_hud
		)

	var physical_loadout := (
		player.progression.physical_loadout
	)

	if physical_loadout != null:
		physical_loadout.loadout_changed.connect(
			_refresh_loadout_hud
		)


func _initialize_display() -> void:
	timer_indicator.visible = false
	timer_indicator.modulate.a = 0.0
	
	_on_state_changed(
		StateManager.current_state
	)

	update_health(
		character.current_hp
	)

	update_stamina(
		character.current_stamina
	)

	_refresh_loadout_hud()
	
	_update_mana_display(
		Skills.SkillType.Water,
		character.get_mana_amount(
			Skills.SkillType.Water
		)
	)

	_update_mana_display(
		Skills.SkillType.Light,
		character.get_mana_amount(
			Skills.SkillType.Light
		)
	)

	_update_mana_display(
		Skills.SkillType.Fire,
		character.get_mana_amount(
			Skills.SkillType.Fire
		)
	)
#endregion


#region Signal Handlers
func _on_state_changed(
	state: StateManager.State
) -> void:
	visible = (
		state != StateManager.State.MENU
	)


func _on_health_changed(
	value: float,
	_maximum: float
) -> void:
	update_health(value)


func _on_stamina_changed(
	value: float,
	_maximum: float
) -> void:
	update_stamina(value)

func _on_combat_mode_changed(
	_mode: PlayerCharacter.CombatMode
) -> void:
	_refresh_loadout_hud()
#endregion


#region Resource Bars
func update_health(value: float) -> void:
	var tween := create_tween()

	tween.tween_property(
		hitpoints,
		"value",
		value,
		0.4
	)


func update_stamina(value: float) -> void:
	var tween := create_tween()

	tween.tween_property(
		stamina,
		"value",
		value,
		0.4
	)
#endregion


#region Loadout HUD
func _get_active_loadout() -> SkillLoadout:
	if player.progression == null:
		return null

	if character.is_physical_mode():
		return player.progression.physical_loadout

	return player.progression.skill_loadout


func _refresh_loadout_hud() -> void:
	var loadout := _get_active_loadout()

	if loadout == null:
		return

	_set_loadout_name(
		loadout_name_x,
		loadout.get_skill(
			SkillLoadout.Slot.X
		)
	)

	_set_loadout_name(
		loadout_name_y,
		loadout.get_skill(
			SkillLoadout.Slot.Y
		)
	)

	_set_loadout_name(
		loadout_name_b,
		loadout.get_skill(
			SkillLoadout.Slot.B
		)
	)

	_set_loadout_name(
		loadout_name_lt_x,
		loadout.get_skill(
			SkillLoadout.Slot.LT_X
		)
	)

	_set_loadout_name(
		loadout_name_lt_y,
		loadout.get_skill(
			SkillLoadout.Slot.LT_Y
		)
	)

	_set_loadout_name(
		loadout_name_lt_b,
		loadout.get_skill(
			SkillLoadout.Slot.LT_B
		)
	)


func _set_loadout_name(
	label: RichTextLabel,
	skill: Skills
) -> void:
	if skill == null:
		label.text = "  --"
		return

	label.text = " " + skill.skill_name

func _update_input_layer() -> void:
	var lt_active := (
		StateManager.current_state
		== StateManager.State.PLAY
		and Input.is_action_pressed(
			"loadout_modifier"
		)
	)

	inputs.visible = not lt_active
	inputs_lt.visible = lt_active
#endregion

#region Mana HUD
func _on_mana_changed(
	skill_type: Skills.SkillType,
	amount: float
) -> void:
	_update_mana_display(
		skill_type,
		amount
	)


func _update_mana_display(
	skill_type: Skills.SkillType,
	amount: float
) -> void:
	var amount_text := (
		str(amount).pad_decimals(0)
	)

	match skill_type:
		Skills.SkillType.Water:
			water_mana_amount.text = (
				amount_text
			)

		Skills.SkillType.Light:
			light_mana_amount.text = (
				amount_text
			)

		Skills.SkillType.Fire:
			fire_mana_amount.text = (
				amount_text
			)
#endregion

#region Weapon Choice Timer
func show_timer_ui(reveal: bool) -> void:
	if timer_tween != null:
		timer_tween.kill()

	if reveal:
		circle_timer.max_value = (
			weapon_choice_timer.wait_time
		)

		circle_timer.value = (
			weapon_choice_timer.time_left
		)

		timer_indicator.visible = true
		timer_indicator.modulate.a = 0.0

		timer_tween = create_tween()

		timer_tween.tween_property(
			timer_indicator,
			"modulate:a",
			1.0,
			0.03
		)

		return

	timer_tween = create_tween()

	timer_tween.tween_property(
		timer_indicator,
		"modulate:a",
		0.0,
		0.03
	)

	timer_tween.tween_callback(
		_hide_timer_indicator
	)

func _hide_timer_indicator() -> void:
	timer_indicator.visible = false
#endregion
