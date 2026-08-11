class_name StatModifiers
extends Resource

@export var max_hp: float = 0.0
@export var attack: float = 0.0
@export var defense: float = 0.0
@export var m_attack: float = 0.0
@export var m_defense: float = 0.0
@export var speed: float = 0.0


func apply_to(stats: Stats) -> void:
	stats.max_hp += max_hp
	stats.attack += attack
	stats.defense += defense
	stats.m_attack += m_attack
	stats.m_defense += m_defense
	stats.speed += speed
