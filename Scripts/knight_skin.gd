#knight_skin.gd
class_name PlayerSkin
extends Node3D
@onready var attack_state_machine = $AnimationTree.get("parameters/AttackStateMachine/playback")
@export var base_stats: Stats
var current_attack : Skills 

@export var attacks : Array[Skills]

func _ready() -> void:
	base_stats = base_stats.duplicate()
	attacks = attacks.duplicate()

func attack(type: String) -> void:
	if type == "X attack":
		attack_state_machine.travel(current_attack.skill_anim_name)
		$AnimationTree.set("parameters/AttackOneShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	elif type == "Y attack":
		attack_state_machine.travel(current_attack.skill_anim_name)
		$AnimationTree.set("parameters/AttackOneShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
