class_name EnemySkillPriorityProfile
extends Resource


@export_category("Priority Weights")

## How strongly this enemy cares about each skill option's Base Priority.
##
## 0 = completely ignore Base Priority.
## Higher values make the enemy's predefined skill preferences matter more.
@export_range(0.0, 5.0, 0.05)
var base_priority_weight := 1.0


## How strongly this enemy cares about being at a skill's preferred range.
##
## 0 = distance still determines whether a skill is usable,
## but distance quality does not affect its final score.
##
## Higher values strongly favor skills being used from ideal distances.
@export_range(0.0, 5.0, 0.05)
var range_fit_weight := 2.0


## How strongly this enemy reacts to recent incoming attacks.
##
## This multiplies each EnemySkillOption's Hit Pressure Response.
##
## 0 = this enemy ignores pressure when choosing skills.
## Higher values make pressure-oriented skills change priority more strongly.
@export_range(0.0, 5.0, 0.05)
var hit_pressure_weight := 1.5


## How strongly this enemy values skills that have actually dealt
## high final damage to the current target during this fight.
##
## Final damage is measured after the target's defenses.
##
## 0 = enemy does not adapt based on observed damage.
## Higher values make successful skills increasingly attractive.
@export_range(0.0, 5.0, 0.05)
var observed_damage_weight := 1.0
