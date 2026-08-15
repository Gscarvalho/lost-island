class_name PlayerCamera
extends Node3D

@export_category("Aim Camera")

@export var aim_spring_length := 3.5
@export var aim_horizontal_offset := 0.75
@export var aim_fov := 60.0
@export var aim_transition_time := 0.2

@onready var spring_arm: SpringArm3D = (
	$SpringArm3D
)

@onready var camera: Camera3D = (
	$SpringArm3D/Camera3D
)

var normal_spring_length: float
var normal_horizontal_offset: float
var normal_fov: float

var is_aiming := false
var aim_tween: Tween

@export var horizontal_acceration := 2.0
@export var vertical_acceration := 1.0
@export var min_limit_x := -1.0
@export var max_limit_x := 1.0
var look_direction := Vector2.ZERO


func _ready() -> void:
	normal_spring_length = (
		spring_arm.spring_length
	)

	normal_horizontal_offset = (
		camera.h_offset
	)

	normal_fov = camera.fov

func _process(delta: float) -> void:
	if StateManager.current_state == StateManager.State.PLAY or StateManager.current_state == StateManager.State.WEAPON:
		look_direction = Input.get_vector("look_left","look_right","look_up","look_down")
		rotate_from_vector2(look_direction * delta * Vector2(horizontal_acceration,vertical_acceration))

func rotate_from_vector2(
	v: Vector2
) -> void:
	if v.length() == 0:
		return

	rotation.y -= v.x
	rotation.x -= v.y

	rotation.x = clamp(
		rotation.x,
		min_limit_x,
		max_limit_x
	)


func set_aiming(
	aiming: bool
) -> void:
	if is_aiming == aiming:
		return

	is_aiming = aiming

	if aim_tween != null:
		aim_tween.kill()

	var target_length := (
		aim_spring_length
		if aiming
		else normal_spring_length
	)

	var target_offset := (
		aim_horizontal_offset
		if aiming
		else normal_horizontal_offset
	)

	var target_fov := (
		aim_fov
		if aiming
		else normal_fov
	)

	aim_tween = create_tween()

	aim_tween.set_parallel(true)

	aim_tween.tween_property(
		spring_arm,
		"spring_length",
		target_length,
		aim_transition_time
	)

	aim_tween.tween_property(
		camera,
		"h_offset",
		target_offset,
		aim_transition_time
	)

	aim_tween.tween_property(
		camera,
		"fov",
		target_fov,
		aim_transition_time
	)
