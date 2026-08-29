class_name VFXInstance
extends Node3D


@export_category("Playback")

@export var play_on_ready := false

@export var auto_free := false


var pending_components := 0
var started := false


func _ready() -> void:
	if play_on_ready:
		call_deferred(
			"play"
		)


func play() -> void:
	if started:
		return

	started = true
	pending_components = 0

	var descendants := find_children(
		"*",
		"",
		true,
		false
	)

	for descendant in descendants:
		var particles := (
			descendant
			as GPUParticles3D
		)

		if particles != null:
			_start_particles(
				particles
			)

			continue

		var sound := (
			descendant
			as AudioStreamPlayer3D
		)

		if sound != null:
			_start_sound(
				sound
			)

	if (
		auto_free
		and pending_components == 0
	):
		call_deferred(
			"queue_free"
		)


func _start_particles(
		particles: GPUParticles3D
	) -> void:
	if auto_free:
		if particles.one_shot:
			pending_components += 1

			particles.finished.connect(
				_on_component_finished,
				CONNECT_ONE_SHOT
			)

		else:
			push_warning(
				"Auto-free VFX contains "
				+ "non-one-shot particles."
			)

			auto_free = false

	particles.restart()


func _start_sound(
		sound: AudioStreamPlayer3D
	) -> void:
	if sound.stream == null:
		return

	if auto_free:
		pending_components += 1

		sound.finished.connect(
			_on_component_finished,
			CONNECT_ONE_SHOT
		)

	var cast_sound := (
		sound as VFXCastSound
	)

	if cast_sound != null:
		cast_sound.play_vfx_sound()
	else:
		sound.play()


func _on_component_finished() -> void:
	pending_components = maxi(
		pending_components - 1,
		0
	)

	if (
		auto_free
		and pending_components == 0
	):
		queue_free()
