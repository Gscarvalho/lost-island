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

enum CostType {
	PerUse,
	PerSecond
}
enum RangeType {
	Low,
	Mid,
	High
}
enum AirUseRule {
	Disabled,
	OncePerAirtime,
	Unlimited,
}
enum MovementDirection {
	None,
	InputOrFacing,
	Facing,
}
enum AnimationChannel {
	Automatic,
	Mobility,
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
@export var skill_type: SkillType
@export var skill_range: RangeType
@export var skill_cost: float
@export var cost_type: CostType = CostType.PerUse

@export_category("Animation")
@export var animation_state_name: StringName
@export var animation_channel: AnimationChannel = (
	AnimationChannel.Automatic
)

@export var directional_animation := false

@export var animation_forward: StringName
@export var animation_back: StringName
@export var animation_left: StringName
@export var animation_right: StringName
#endregion

#region Regeneration
@export_category("Regeneration")

@export var skill_regen_type: Player.RegenType
@export var skill_regen_power: float
#endregion

#region Movement
@export_category("Movement")

@export var movement_direction: MovementDirection = (
	MovementDirection.None
)

@export var movement_speed: float = 0.0

@export var movement_duration: float = 0.0

@export var movement_vertical_speed: float = 0.0
#endregion

#region Usage
@export_category("Usage")

@export var can_use_on_ground := true
@export var air_use_rule: AirUseRule = (
	AirUseRule.Unlimited
)
@export_category("Interrupt")
@export var can_interrupt_actions := false

@export_range(0.0, 2.0, 0.01)
var interrupt_lock_time := 0.25

@export_range(0.0, 2.0, 0.01)
var interrupt_lock_floor := 0.05

@export_range(0.0, 2.0, 0.01)
var interrupt_requirement := 0.0
#endregion


#region Impact
@export_category("Impact")

@export_range(0.0, 1.0, 0.05)
var impact_shake_intensity := 0.0

@export_range(0.0, 1.0, 0.01)
var impact_shake_duration := 0.0

@export_range(0.0, 0.25, 0.005)
var impact_hit_stop_duration := 0.0

@export_range(0.01, 1.0, 0.01)
var impact_hit_stop_time_scale := 0.05

@export_range(0.0, 30.0, 0.1)
var impact_knockback_strength := 5.0
#endregion
