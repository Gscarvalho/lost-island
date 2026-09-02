class_name TraversalLink
extends NavigationLink3D


enum TraversalType {
	JUMP,
	CLIMB,
	SWIM
}


@export var traversal_type := TraversalType.JUMP

@export_category("Jump")
@export var jump_arc_height := 1.5
