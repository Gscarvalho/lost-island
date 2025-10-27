#player_ui.gd
extends Control
class_name UI
@onready var skin: PlayerSkin = get_parent().get_node("Skin")
@onready var hitpoints: TextureProgressBar = $HBoxContainer/HUD/Hitpoints
@onready var stamina: TextureProgressBar = $HBoxContainer/HUD/Stamina
@onready var info: RichTextLabel = $HBoxContainer/HUD/Hitpoints/Info
@onready var weapon_icon_image: TextureRect = $HBoxContainer/Weapon/Control/WeaponIconImage
@onready var mana_slots: HBoxContainer = $HBoxContainer/ManaSlots
@export var icons: Array[Texture2D]
@onready var circle_timer: TextureProgressBar = $HBoxContainer/Weapon/CircleTimer

func update_health(value: float) -> void:
	var tween = create_tween()
	tween.tween_property(hitpoints,"value",value, 0.4)

func update_stamina(value: float) -> void:
	var tween = create_tween()
	tween.tween_property(stamina,"value",value, 0.4)

func update_slots(value: Skills.SkillType) -> void:
	if value == Skills.SkillType.Physical:
		for child in mana_slots.get_children():
			child.get_child(0).modulate.a = 0
		weapon_icon_image.texture = icons[0]
		weapon_icon_image.modulate = Color.LIGHT_BLUE
				
	elif value == Skills.SkillType.Water:
		for child in mana_slots.get_children():
			if child.get_index() < skin.mana_inventory[0]:
				child.get_child(0).modulate = Color.DEEP_SKY_BLUE
			else:
				child.get_child(0).modulate.a = 0	
		weapon_icon_image.texture = icons[2]
		weapon_icon_image.modulate = Color.DEEP_SKY_BLUE
		
	elif value == Skills.SkillType.Fire:
		for child in mana_slots.get_children():
			if child.get_index() < skin.mana_inventory[1]:
				child.get_child(0).modulate = Color.DARK_ORANGE
			else:
				child.get_child(0).modulate.a = 0
		weapon_icon_image.texture = icons[1]
		weapon_icon_image.modulate = Color.DARK_ORANGE
		
	elif value == Skills.SkillType.Light:
		for child in mana_slots.get_children():
			if child.get_index() < skin.mana_inventory[2]:
				child.get_child(0).modulate = Color.GOLD
			else:
				child.get_child(0).modulate.a = 0	
		weapon_icon_image.texture = icons[3]
		weapon_icon_image.modulate = Color.GOLD
		
func show_timer_ui(reveal: bool) -> void:
	var t: Timer = get_parent().get_node("Timers/WeaponChoiceTimer")
	if reveal:
		circle_timer.value = t.time_left
	else:
		circle_timer.value = 0

	
