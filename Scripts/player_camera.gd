extends Node3D
@export var horizontal_acceration := 2.0
@export var vertical_acceration := 1.0
@export var min_limit_x := -1.0
@export var max_limit_x := 1.0
var look_direction := Vector2.ZERO

func _process(delta: float) -> void:
	look_direction = Input.get_vector("look_left","look_right","look_up","look_down")
	rotate_from_vector2(look_direction * delta * Vector2(horizontal_acceration,vertical_acceration))

func rotate_from_vector2(v: Vector2) -> void:
	if v.length() == 0: return
	rotation.y -= v.x
	rotation.x -= v.y
	rotation.x = clamp(rotation.x,min_limit_x,max_limit_x)
