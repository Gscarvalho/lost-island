class_name SkillTree
extends Control

signal skill_focused(skill: Skills)
signal skill_activated(skill: Skills)

@export var default_skill_node: SkillTreeNode

var skill_nodes: Array[SkillTreeNode] = []


func _ready() -> void:
	_collect_skill_nodes(self)


func _collect_skill_nodes(parent: Node) -> void:
	for child in parent.get_children():
		if child is SkillTreeNode:
			skill_nodes.append(child)

			child.skill_focused.connect(
				_on_skill_focused
			)

			child.skill_activated.connect(
				_on_skill_activated
			)

		_collect_skill_nodes(child)


func _on_skill_focused(skill: Skills) -> void:
	skill_focused.emit(skill)


func _on_skill_activated(skill: Skills) -> void:
	skill_activated.emit(skill)


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
