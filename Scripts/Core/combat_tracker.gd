extends Node


signal combat_started
signal combat_ended

signal combatant_count_changed(
	count: int
)


var active_enemy_ids: Dictionary = {}


func register_enemy(
		enemy: Enemy
	) -> void:
		if enemy == null:
			return

		var enemy_id := (
			enemy.get_instance_id()
		)

		if active_enemy_ids.has(
			enemy_id
		):
			return

		var combat_was_empty := (
			active_enemy_ids.is_empty()
		)

		active_enemy_ids[enemy_id] = true

		combatant_count_changed.emit(
			active_enemy_ids.size()
		)

		if combat_was_empty:
			combat_started.emit()


func unregister_enemy(
		enemy: Enemy
	) -> void:
		if enemy == null:
			return

		var enemy_id := (
			enemy.get_instance_id()
		)

		if not active_enemy_ids.has(
			enemy_id
		):
			return

		active_enemy_ids.erase(
			enemy_id
		)

		combatant_count_changed.emit(
			active_enemy_ids.size()
		)

		if active_enemy_ids.is_empty():
			combat_ended.emit()


func is_in_combat() -> bool:
	return not active_enemy_ids.is_empty()


func get_combatant_count() -> int:
	return active_enemy_ids.size()
