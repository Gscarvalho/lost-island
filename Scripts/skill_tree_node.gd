@tool
class_name SkillTreeNode
extends TextureButton

signal skill_focused(skill: Skills)
signal skill_activated(skill: Skills)

@export var skill: Skills:
	set(value):
		skill = value
		_refresh()

@export var focused_scale := 1.01

@onready var cost_badge: TextureRect = $VBoxContainer/CostBadge
@onready var cost_label: RichTextLabel = %CostLabel
@onready var skill_name_label: RichTextLabel = %SkillNameLabel

var tree_color: Color = Color.WHITE
var is_unlocked := false

func set_tree_color(color: Color) -> void:
	tree_color = color

func _ready() -> void:
	_refresh()

	if Engine.is_editor_hint():
		return

	focus_mode = Control.FOCUS_ALL

	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	mouse_entered.connect(grab_focus)
	pressed.connect(_on_pressed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size / 2.0


func _refresh() -> void:
	if skill == null:
		texture_normal = null

		if cost_label != null:
			cost_label.text = ""

		return

	texture_normal = null
	#texture_normal = skill.skill_icon

	if cost_label != null:
		cost_label.text = str(skill.unlock_cost)
		skill_name_label.text = skill.skill_name


func _on_focus_entered() -> void:
	skill_focused.emit(skill)
	_fade_cost_badge(0)
	cost_label.add_theme_color_override("default_color", tree_color)
	_set_focus_visual(true)


func _on_focus_exited() -> void:
	_fade_cost_badge(1)
	cost_label.add_theme_color_override("default_color", Color.WHITE)
	_set_focus_visual(false)


func _on_pressed() -> void:
	skill_activated.emit(skill)


func _set_focus_visual(is_focused: bool) -> void:
	var target_scale := Vector2.ONE

	if is_focused:
		target_scale *= focused_scale
		z_index = 1
	else:
		z_index = 0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		self,
		"scale",
		target_scale,
		0.12
	)

func _fade_cost_badge(target: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(
		cost_badge,
		"self_modulate:a",
		target,
		0.2
	)

func set_unlocked(unlocked: bool) -> void:
	is_unlocked = unlocked

	if is_unlocked:
		cost_badge.visible = false
	else:
		cost_badge.visible = true
