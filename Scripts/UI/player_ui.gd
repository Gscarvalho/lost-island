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
#endregion


#region Lifecycle
func _ready() -> void:
	_connect_signals()
	_initialize_display()


func _process(_delta: float) -> void:
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

	var loadout := _get_skill_loadout()

	if loadout != null:
		loadout.loadout_changed.connect(
			_refresh_loadout_hud
		)


func _initialize_display() -> void:
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
func _get_skill_loadout() -> SkillLoadout:
	if player.progression == null:
		return null

	return player.progression.skill_loadout


func _refresh_loadout_hud() -> void:
	var loadout := _get_skill_loadout()

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
		label.text = "--"
		return

	label.text = skill.skill_name
#endregion


#region Weapon Choice Timer
func show_timer_ui(reveal: bool) -> void:
	if reveal:
		circle_timer.max_value = (
			weapon_choice_timer.wait_time
		)

		circle_timer.value = (
			weapon_choice_timer.time_left
		)

	else:
		circle_timer.value = 0.0
#endregion
