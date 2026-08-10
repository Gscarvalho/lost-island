class_name StatModifiers
extends Resource


@export var max_hp := 0.0
@export var attack := 0.0
@export var defense := 0.0
@export var m_attack := 0.0
@export var m_defense := 0.0
@export var speed := 0.0

func apply_to(stats: Stats) -> void:
	stats.max_hp += max_hp
	stats.attack += attack
	stats.defense += defense
	stats.m_attack += m_attack
	stats.m_defense += m_defense
	stats.speed += speed
