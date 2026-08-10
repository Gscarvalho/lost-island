# player_ui.gd
class_name UI
extends Control


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

@onready var info: RichTextLabel = (
	$HBoxContainer/HUD/Hitpoints/Info
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

@export var icons: Array[Texture2D]

#endregion

#region Lifecycle
func _ready() -> void:
	StateManager.state_changed.connect(
		_on_state_changed
	)

	_on_state_changed(
		StateManager.current_state
	)


func _process(_delta: float) -> void:
	if StateManager.current_state == StateManager.State.WEAPON:
		circle_timer.value = weapon_choice_timer.time_left
#endregion

#region State
func _on_state_changed(state: StateManager.State) -> void:
	visible = state != StateManager.State.MENU
#endregion

#region Resource Bars
func update_health(value: float) -> void:
	var tween = create_tween()
	tween.tween_property(hitpoints,"value",value, 0.4)

func update_stamina(value: float) -> void:
	var tween = create_tween()
	tween.tween_property(stamina,"value",value, 0.4)
#endregion

#region Loadout Display
func update_slots(value: Skills.SkillType) -> void:
	match value:
		Skills.SkillType.Physical:
			_hide_mana()

			weapon_icon_image.texture = icons[0]
			weapon_icon_image.modulate = Color.LIGHT_BLUE

		Skills.SkillType.Water:
			_show_mana(
				character.mana_inventory[0],
				Color.DEEP_SKY_BLUE,
				icons[2]
			)

		Skills.SkillType.Fire:
			_show_mana(
				character.mana_inventory[1],
				Color.DARK_ORANGE,
				icons[1]
			)

		Skills.SkillType.Light:
			_show_mana(
				character.mana_inventory[2],
				Color.GOLD,
				icons[3]
			)

func _show_mana(
	amount: int,
	color: Color,
	icon: Texture2D
	) -> void:
	for child in mana_slots.get_children():
		var slot_icon := child.get_child(0) as CanvasItem

		if child.get_index() < amount:
			slot_icon.modulate = color
		else:
			slot_icon.modulate.a = 0.0

	weapon_icon_image.texture = icon
	weapon_icon_image.modulate = color

func _hide_mana() -> void:
	for child in mana_slots.get_children():
		child.get_child(0).modulate.a = 0.0
#endregion

#region Weapon Choice Timer
func show_timer_ui(reveal: bool) -> void:
	if reveal:
		circle_timer.max_value = weapon_choice_timer.wait_time
		circle_timer.value = weapon_choice_timer.time_left
	else:
		circle_timer.value = 0.0
#endregion
