class_name EnemyUI
extends Node3D


@onready var health_bar: ProgressBar = (
	%HealthBar
)

@onready var damage_label: RichTextLabel = (
	%DamageLabel
)

@onready var enemy: Enemy = (
	get_parent() as Enemy
)


func _ready() -> void:
	if enemy == null:
		push_error(
			"EnemyUI requires an Enemy parent."
		)
		return

	enemy.health_changed.connect(
		_update_health
	)


func _update_health(
	current: float,
	maximum: float
) -> void:
	health_bar.max_value = maximum
	health_bar.value = current


func display_damage(
	amount: float,
	duration: float = 0.5
) -> void:
	var panel := (
		damage_label.get_parent_control()
	)

	damage_label.text = (
		str(amount).pad_decimals(0)
	)

	panel.modulate.a = 1.0

	await (
		get_tree()
		.create_timer(duration)
		.timeout
	)

	panel.modulate.a = 0.0
	damage_label.text = ""
