class_name VFXCastSound
extends AudioStreamPlayer3D


@export_category("Lifetime")

@export var survive_visual := true


@export_category("Variation")

@export_range(
	0.0,
	0.2,
	0.01
)
var pitch_variation := 0.0


var detached := false


func _ready() -> void:
	if pitch_variation > 0.0:
		pitch_scale *= randf_range(
			1.0 - pitch_variation,
			1.0 + pitch_variation
		)

	finished.connect(
		_on_sound_finished
	)

	if not survive_visual:
		return

	var particles := (
		get_parent()
		as GPUParticles3D
	)

	if particles == null:
		return

	particles.finished.connect(
		_on_visual_finished
	)


func _on_visual_finished() -> void:
	if not survive_visual:
		return

	if not playing:
		return

	var particles := (
		get_parent()
		as GPUParticles3D
	)

	if particles == null:
		return

	var survivor_parent := (
		particles.get_parent()
	)

	if survivor_parent == null:
		return

	reparent(
		survivor_parent,
		true
	)

	detached = true


func _on_sound_finished() -> void:
	if detached:
		queue_free()
