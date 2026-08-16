extends Node


var hit_stop_timer: Timer

var hit_stop_active := false
var restore_time_scale := 1.0


func _ready() -> void:
	hit_stop_timer = Timer.new()

	hit_stop_timer.one_shot = true
	hit_stop_timer.ignore_time_scale = true

	add_child(
		hit_stop_timer
	)

	hit_stop_timer.timeout.connect(
		_on_hit_stop_timeout
	)


func apply_impact(
		skill: Skills
	) -> void:
		if skill == null:
			return

		CameraEffects.shake(
			skill.impact_shake_intensity,
			skill.impact_shake_duration
		)

		hit_stop(
			skill.impact_hit_stop_time_scale,
			skill.impact_hit_stop_duration
		)


func hit_stop(
		time_scale: float,
		duration: float
	) -> void:
		if duration <= 0.0:
			return

		var target_time_scale := clampf(
			time_scale,
			0.01,
			1.0
		)

		if not hit_stop_active:
			restore_time_scale = (
				Engine.time_scale
			)

			hit_stop_active = true

		Engine.time_scale = minf(
			Engine.time_scale,
			target_time_scale
		)

		hit_stop_timer.start(
			duration
		)


func _on_hit_stop_timeout() -> void:
	Engine.time_scale = (
		restore_time_scale
	)

	hit_stop_active = false
