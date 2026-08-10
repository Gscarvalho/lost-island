@tool
class_name SkillTreeNode
extends TextureButton

#region Signals
signal skill_focused(skill: Skills)
signal skill_activated(skill: Skills)
#endregion

#region Configuration
@export var skill: Skills:
	set(value):
		skill = value
		_refresh()

@export var focused_scale := 1.01
#endregion

#region Refernces
@onready var cost_badge: TextureRect = $VBoxContainer/CostBadge
@onready var cost_label: RichTextLabel = %CostLabel
@onready var skill_name_label: RichTextLabel = %SkillNameLabel
#endregion

#region Runtime State
var focus_tween: Tween
var badge_tween: Tween
var tree_color: Color = Color.WHITE
var is_unlocked := false
#endregion

#region Lifecycle
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
#endregion

#region Skill Data
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


func set_tree_color(color: Color) -> void:
	tree_color = color
#endregion

#region Focus Events
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
#endregion

#region Focus Visuals
func _set_focus_visual(is_focused: bool) -> void:
	if focus_tween != null:
		focus_tween.kill()

	var target_scale := Vector2.ONE

	if is_focused:
		target_scale *= focused_scale
		z_index = 1
	else:
		z_index = 0

	focus_tween = create_tween()
	focus_tween.set_trans(Tween.TRANS_QUAD)
	focus_tween.set_ease(Tween.EASE_OUT)

	focus_tween.tween_property(
		self,
		"scale",
		target_scale,
		0.12
	)

func _fade_cost_badge(target: float) -> void:
	if badge_tween != null:
		badge_tween.kill()

	badge_tween = create_tween()
	badge_tween.set_trans(Tween.TRANS_QUAD)
	badge_tween.set_ease(Tween.EASE_OUT)

	badge_tween.tween_property(
		cost_badge,
		"self_modulate:a",
		target,
		0.2
	)
#endregion

#region Progression Display
func set_unlocked(unlocked: bool) -> void:
	is_unlocked = unlocked

	if is_unlocked:
		cost_badge.visible = false
	else:
		cost_badge.visible = true
#endregion
