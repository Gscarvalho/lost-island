# player_ui.gd
class_name PlayerHUD
extends Control

#region Configuration
@export_category("Loadout Icons")

@export var physical_icon: Texture2D
@export var fire_icon: Texture2D
@export var water_icon: Texture2D
@export var light_icon: Texture2D
#endregion

#region References
@onready var character: PlayerCharacter = (
	get_parent().get_node("Character")
)

@onready var hitpoints: TextureProgressBar = (
	$HBoxContainer/HUD/Hitpoints
)

@onready var stamina: TextureProgressBar = (
	$HBoxContainer/HUD/Stamina
)

@onready var weapon_icon_image: TextureRect = (
	$HBoxContainer/Weapon/Control/WeaponIconImage
)

@onready var mana_slots: HBoxContainer = (
	$HBoxContainer/ManaSlots
)

@onready var circle_timer: TextureProgressBar = (
	$HBoxContainer/Weapon/CircleTimer
)

@onready var weapon_choice_timer: Timer = (
	$"../Timers/WeaponChoiceTimer"
)
#endregion

#region Lifecycle
func _ready() -> void:
	_connect_signals()
	_initialize_display()


func _process(_delta: float) -> void:
	if StateManager.current_state == StateManager.State.WEAPON:
		circle_timer.value = (
			weapon_choice_timer.time_left
		)

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

	character.mana_changed.connect(
		_on_mana_changed
	)

	character.loadout_changed.connect(
		update_slots
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

	update_slots(
		character.get_current_skill_type()
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


func _on_mana_changed(
	skill_type: Skills.SkillType,
	_amount: float
) -> void:
	if (
		skill_type
		!= character.get_current_skill_type()
	):
		return

	update_slots(skill_type)
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

#region Loadout Display
func update_slots(
	value: Skills.SkillType
) -> void:
	match value:
		Skills.SkillType.Physical:
			_hide_mana()

			weapon_icon_image.texture = physical_icon
			weapon_icon_image.modulate = Color.LIGHT_BLUE

		Skills.SkillType.Water:
			_show_mana(
				character.get_mana_amount(
					Skills.SkillType.Water
				),
				Color.DEEP_SKY_BLUE,
				water_icon
			)

		Skills.SkillType.Fire:
			_show_mana(
				character.get_mana_amount(
					Skills.SkillType.Fire
				),
				Color.DARK_ORANGE,
				fire_icon
			)

		Skills.SkillType.Light:
			_show_mana(
				character.get_mana_amount(
					Skills.SkillType.Light
				),
				Color.GOLD,
				light_icon
			)

func _show_mana(
	amount: float,
	color: Color,
	icon: Texture2D
) -> void:
	for child in mana_slots.get_children():
		var slot_icon := (
			child.get_child(0)
			as CanvasItem
		)

		if child.get_index() < amount:
			slot_icon.modulate = color
		else:
			slot_icon.modulate.a = 0.0

	weapon_icon_image.texture = icon
	weapon_icon_image.modulate = color

func _hide_mana() -> void:
	for child in mana_slots.get_children():
		var slot_icon := (
			child.get_child(0)
			as CanvasItem
		)

		slot_icon.modulate.a = 0.0
#endregion

#region Weapon Choice Timer
func show_timer_ui(reveal: bool) -> void:
	if reveal:
		circle_timer.max_value = weapon_choice_timer.wait_time
		circle_timer.value = weapon_choice_timer.time_left
	else:
		circle_timer.value = 0.0
#endregion
