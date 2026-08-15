#skills.gd
class_name Skills
extends Resource

#region Enums
enum SkillType {
	Physical,
	Fire,
	Water,
	Light
}
enum RegenType {
	None,
	Health,
	Stamina,
	Mana
}
enum CostType {
	PerUse,
	PerSecond
}
enum RangeType {
	Low,
	Mid,
	High
}
#endregion

#region Identity
@export_category("Identity")

@export var skill_id: StringName
@export var skill_name: String
@export_multiline var skill_description: String
@export var skill_icon: Texture2D

@export_category("Delivery")

@export var projectile_scene: PackedScene
#endregion

#region Progression
@export_category("Progression")

@export_range(0, 999, 1)
var unlock_cost: int = 1

# Reserved for future skill-tree progression.
# Prerequisites are intentionally not enforced in the demo.
@export var prerequisite_ids: Array[StringName] = []
#endregion

#region Gameplay
@export_category("Gameplay")

@export var skill_power: float
@export var skill_anim_name: String
@export var skill_type: SkillType
@export var skill_range: RangeType
@export var skill_cost: float
@export var cost_type: CostType = CostType.PerUse
#endregion

#region Regeneration
@export_category("Regeneration")

@export var skill_regen_type: RegenType
@export var skill_regen_power: float
#endregion
