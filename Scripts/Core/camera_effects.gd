extends Node

signal shake_requested(
	intensity: float,
	duration: float
)


func shake(
	intensity: float,
	duration: float
) -> void:
	if intensity <= 0.0:
		return

	if duration <= 0.0:
		return

	shake_requested.emit(
		clampf(
			intensity,
			0.0,
			1.0
		),
		duration
	)
