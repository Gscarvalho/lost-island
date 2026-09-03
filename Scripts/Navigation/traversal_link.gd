class_name TraversalLink
extends NavigationLink3D


enum TraversalType {
	JUMP,
	CLIMB,
	SWIM
}

const BASE_NAVIGATION_LAYER := 1 << 0
const JUMP_NAVIGATION_LAYER := 1 << 1
const CLIMB_NAVIGATION_LAYER := 1 << 2
const SWIM_NAVIGATION_LAYER := 1 << 3

@export var traversal_type := TraversalType.JUMP

@export_category("Jump")
@export var jump_arc_height := 1.5

func _ready() -> void:
	navigation_layers = (
		get_traversal_navigation_layer()
	)


func get_traversal_navigation_layer() -> int:
	match traversal_type:
		TraversalType.JUMP:
			return JUMP_NAVIGATION_LAYER

		TraversalType.CLIMB:
			return CLIMB_NAVIGATION_LAYER

		TraversalType.SWIM:
			return SWIM_NAVIGATION_LAYER

	return 0
