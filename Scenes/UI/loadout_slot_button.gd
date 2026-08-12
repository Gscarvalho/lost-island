class_name LoadoutSlotButton
extends Button

@export_category("Input Icons")
@export var primary_input_icon: Texture2D
@export var secondary_input_icon: Texture2D

@export_category("Current Indicator")
@export var active_indicator_color: Color = Color.ORANGE
@export var inactive_indicator_color: Color = Color(1, 1, 1, 0.18)

@onready var primary_icon: TextureRect = %PrimaryIcon
@onready var secondary_icon: TextureRect = %SecondaryIcon
@onready var skill_name_label: RichTextLabel = %SkillName
@onready var current_indicator: Panel = %CurrentIndicator


func _ready() -> void:
	_refresh_input_icons()


func set_skill_display(
	skill: Skills,
	is_current: bool
) -> void:
	if skill == null:
		skill_name_label.text = "--"
	else:
		skill_name_label.text = skill.skill_name.to_upper()

	current_indicator.modulate = (
		active_indicator_color
		if is_current
		else inactive_indicator_color
	)


func _refresh_input_icons() -> void:
	primary_icon.texture = primary_input_icon
	secondary_icon.texture = secondary_input_icon

	var has_secondary := (
		secondary_input_icon != null
	)

	secondary_icon.visible = has_secondary
