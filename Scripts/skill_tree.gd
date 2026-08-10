class_name SkillTree
extends Control

#region Signals
signal skill_focused(skill: Skills)
signal skill_activated(skill: Skills)
#endregion

#region Configuration
@export var default_skill_node: SkillTreeNode

@export_category("Tree Identity")
@export var tree_name: String = ""
@export var tree_color: Color = Color.WHITE
@export var background_icon: Texture2D
#endregion

#region Runtime State
var skill_nodes: Array[SkillTreeNode] = []
#endregion

#region Lifecycle
func _ready() -> void:
	_collect_skill_nodes(self)
#endregion

#region Node Registration
func _collect_skill_nodes(parent: Node) -> void:
	for child in parent.get_children():
		if child is SkillTreeNode:
			skill_nodes.append(child)
			
			child.set_tree_color(tree_color)
			
			child.skill_focused.connect(
				_on_skill_focused
			)

			child.skill_activated.connect(
				_on_skill_activated
			)

		_collect_skill_nodes(child)
#endregion

#region Skill Events
func _on_skill_focused(skill: Skills) -> void:
	skill_focused.emit(skill)

func _on_skill_activated(skill: Skills) -> void:
	skill_activated.emit(skill)
#endregion

#region Focus Management
func has_skill_focus() -> bool:
	for node in skill_nodes:
		if node.has_focus():
			return true

	return false

func clear_skill_focus() -> void:
	for node in skill_nodes:
		node.release_focus()

func grab_default_focus() -> void:
	if default_skill_node != null:
		default_skill_node.grab_focus()
#endregion

#region Progression Display
func refresh_unlock_states(
	progression: PlayerProgress
	) -> void:
	for node in skill_nodes:
		if node.skill == null:
			continue

		node.set_unlocked(
			progression.is_skill_unlocked(node.skill)
		)
#endregion
