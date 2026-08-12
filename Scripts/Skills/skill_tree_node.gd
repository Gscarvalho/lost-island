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

#region References
@onready var circle_bg: Panel = $VisualCenter/CircleBG
@onready var cost_label: RichTextLabel = $VisualCenter/CostLabel
@onready var focus_ring: TextureProgressBar = $VisualCenter/FocusRing
@onready var skill_name_label: RichTextLabel = %SkillNameLabel
#endregion

#region Runtime State
var focus_tween: Tween
var ring_tween: Tween
var unlock_tween: Tween
var tree_color: Color = Color.WHITE
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
	
	focus_ring.value = 0.0
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size / 2.0
#endregion

#region Skill Data
func _refresh() -> void:
	texture_normal = null

	if skill == null:
		if cost_label != null:
			cost_label.text = ""

		if skill_name_label != null:
			skill_name_label.text = ""

		return

	if cost_label != null:
		cost_label.text = str(
			skill.unlock_cost
		)

	if skill_name_label != null:
		skill_name_label.text = (
			skill.skill_name
		)


func set_tree_color(color: Color) -> void:
	tree_color = color
#endregion

#region Focus Events
func _on_focus_entered() -> void:
	skill_focused.emit(skill)
	_set_focus_ring(true)
	_set_focus_visual(true)


func _on_focus_exited() -> void:
	_set_focus_ring(false)
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

func _set_focus_ring(is_focused: bool) -> void:
	if ring_tween != null:
		ring_tween.kill()

	var target_value := 0.0

	if is_focused:
		target_value = 100.0

	ring_tween = create_tween()
	ring_tween.set_trans(Tween.TRANS_QUAD)
	ring_tween.set_ease(Tween.EASE_OUT)

	ring_tween.tween_property(
		focus_ring,
		"value",
		target_value,
		0.2
	)
#endregion

#region Progression Display
func set_unlocked(unlocked: bool) -> void:
	cost_label.visible = not unlocked
	set_unlock_visual(unlocked)

func set_unlock_visual(unlocked: bool) -> void:
	if unlock_tween != null:
		unlock_tween.kill()

	var target_scale := Vector2(0.5, 0.5)

	if unlocked:
		target_scale = Vector2(0.65, 0.65)

	unlock_tween = create_tween()
	unlock_tween.set_trans(Tween.TRANS_BACK)
	unlock_tween.set_ease(Tween.EASE_OUT)

	unlock_tween.tween_property(
		circle_bg,
		"scale",
		target_scale,
		0.2
	)
#endregion
