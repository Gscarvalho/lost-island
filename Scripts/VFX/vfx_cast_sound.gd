class_name VFXCastSound
extends AudioStreamPlayer3D


@export_category("Variation")

@export_range(
	0.0,
	0.2,
	0.01
)
var pitch_variation := 0.0

@export_category("Timing")

@export_range(
	0.0,
	2.0,
	0.01
)
var start_delay := 0.0



func _ready() -> void:
	if pitch_variation <= 0.0:
		return

	pitch_scale *= randf_range(
		1.0 - pitch_variation,
		1.0 + pitch_variation
	)

func play_vfx_sound() -> void:
	if start_delay > 0.0:
		await get_tree().create_timer(
			start_delay
		).timeout

	if not is_inside_tree():
		return

	play()
