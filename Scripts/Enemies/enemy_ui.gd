class_name EnemyUI
extends Node3D

signal health_changed(
	current: float,
	maximum: float
)

@onready var health_bar: TextureProgressBar = (
	%HealthBar
)
@onready var damage_label: RichTextLabel = (
	%DamageLabel
)
@onready var enemy: Enemy = (
	self.get_parent_node_3d() as Enemy
)

func _ready() -> void:
	
	health_changed.connect(
		_update_ui
	)

	_update_ui(
		enemy.current_health,
		enemy.get_max_health()
	)

func _update_ui(
		current: float,
		maximum: float
	) -> void:
		health_bar.value = current
		health_bar.max_value = maximum

func _display_damage_for_seconds(
		amount: float,
		duration: float = 0.5
	) -> void: 
		var panel = damage_label.get_parent_control()
		damage_label.text = str(amount).pad_decimals(0)
		panel.modulate.a = 1
		await get_tree().create_timer(duration).timeout
		panel.modulate.a = 0
		damage_label.text = ""
