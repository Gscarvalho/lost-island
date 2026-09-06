class_name Weapon
extends Node3D

@export_category("Identity")
@export var weapon_name: String = ""
@export var stats_boost: StatModifiers

@onready var hitbox: Hitbox = (
	$Hitbox
)
@onready var hit_sound: AudioStreamPlayer3D = (
	$HitSound
)

var user: Node

func _ready() -> void:
	hitbox.hit_confirmed.connect(
		_on_hit_confirmed
	)

func prepare_attack(
		skill: Skills,
		damage: float
	) -> void:
		if skill == null:
			return

		hitbox.deactivate()

		hitbox.configure_attack(
			self,
			skill,
			damage,
			user
		)

func _on_hit_confirmed(
		_hurtbox: Hurtbox
	) -> void:
		hit_sound.play()
		
		CombatEffects.apply_impact(
			hitbox.source_skill
		)

func start_damage_window() -> void:
	hitbox.activate()

func end_damage_window() -> void:
	hitbox.deactivate()
