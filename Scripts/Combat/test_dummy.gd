class_name TestDummy
extends Node3D

signal health_changed(
	current: float,
	maximum: float
)

@export_category("Stats")

@export var stats: Stats
@export var maximum_health: float = 100.0

@onready var head_hurtbox: Hurtbox = (
	$HeadHurtbox
)
@onready var body_hurtbox: Hurtbox = (
	$BodyHurtbox
)
@onready var legs_hurtbox: Hurtbox = (
	$LegsHurtbox
)
@onready var health_bar: TextureProgressBar = (
	%HealthBar
)
@onready var damage_label: RichTextLabel = (
	%DamageLabel
)
var current_health: float

func _ready() -> void:
	current_health = maximum_health

	head_hurtbox.hit_received.connect(
		_on_hurtbox_hit_received
	)
	
	body_hurtbox.hit_received.connect(
		_on_hurtbox_hit_received
	)
	legs_hurtbox.hit_received.connect(
		_on_hurtbox_hit_received
	)

	health_changed.connect(
		_update_ui
	)
	
	_update_ui(
		current_health,
		maximum_health
	)
	
	_display_damage_for_seconds(0,0.01)

func _update_ui(
		current: float,
		maximum: float
	) -> void:
		health_bar.value = current
		health_bar.max_value = maximum

func _on_hurtbox_hit_received(
		damage_data: DamageData
	) -> void:
		var final_damage := (
			calculate_received_damage(
				damage_data
			)
		)

		take_damage(
			final_damage
		)
		
		_display_damage_for_seconds(final_damage)

func take_damage(
		damage: float
	) -> void:
		if damage <= 0.0:
			return

		current_health = maxf(
			current_health - damage,
			0.0
		)

		health_changed.emit(
			current_health,
			maximum_health
		)

func calculate_received_damage(
		damage_data: DamageData
	) -> float:
		if damage_data == null:
			return 0.0

		if stats == null:
			return damage_data.amount

		var defense_value := 0.0

		match damage_data.damage_type:
			DamageData.DamageType.PHYSICAL:
				defense_value = stats.defense

			_:
				defense_value = stats.m_defense

		defense_value = maxf(
			defense_value,
			0.0
		)

		return (
			damage_data.amount
			* 100.0
			/ (100.0 + defense_value)
		)

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
