#player.gd
class_name Player
extends CharacterBody3D
@onready var camera = $CameraController/Camera3D
@onready var skin = $Skin as PlayerSkin

#Movement
var walk_speed := 5.5
var run_speed := 8.5
var movement_input := Vector2.ZERO
var speed_modifier := 1.0
var stamina_cost_reduction := 1.0

#Jump
var jump_height : float = 3.5
var jump_time_to_peak : float = 0.4
var jump_time_to_descent : float = 0.3

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

#State Toggles
var is_attacking := false
var is_running := false
var is_being_hit := false


func _physics_process(delta: float) -> void:
	#print($Timers/MenuDelayTimer.time_left)
	_menu_logic()
	_equip_logic()
	_move_logic(delta)
	_jump_logic(delta)
	_attacks_logic()
	_skills_logic()
	move_and_slide()

func _equip_logic() -> void:
	if Input.is_action_pressed("swap") and StateManager.current_state == StateManager.State.PLAY and not $Timers/MenuDelayTimer.time_left:
		$Timers/WeaponChoiceTimer.start()
		StateManager.set_state(StateManager.State.WEAPON)
	elif Input.is_action_just_released("swap") and StateManager.current_state == StateManager.State.WEAPON:
		_close_weapon_choice()
	if StateManager.current_state == StateManager.State.WEAPON:
		skin.ui.show_timer_ui(true)
		skin.set_move_timescale(0.1)
		var tween = create_tween()
		tween. tween_property(self, "velocity", Vector3.ZERO, 0.3)
		var left = Input.is_action_just_pressed("menu_left")
		var right = Input.is_action_just_pressed("menu_right")
		if left:
			skin.current_mana_type = wrapi(skin.current_mana_type - 1, 0, skin.mana_types.size())
		elif right:
			skin.current_mana_type = wrapi(skin.current_mana_type + 1, 0, skin.mana_types.size())


func _close_weapon_choice() -> void:
	StateManager.set_state(StateManager.State.PLAY)
	skin.set_move_timescale(1)
	skin.ui.show_timer_ui(false)
	
func _on_weapon_choice_timer_timeout() -> void:
	_close_weapon_choice()
	$Timers/MenuDelayTimer.start()

func _on_stamina_regen_timer_timeout() -> void:
	if skin.current_stamina <= 0.0:# and $Timers/StaminaRegenTimer.time_left:
		print("Stamina depleted, delayed regeneration.")
		await get_tree().create_timer(3.0).timeout
	skin.current_stamina = 100.0
	$Timers/StaminaRegenTimer.stop()

func _menu_logic() -> void:
	if Input.is_action_just_pressed("menu") and not StateManager.current_state == StateManager.State.WEAPON:
		if StateManager.current_state == StateManager.State.PLAY:
			StateManager.set_state(StateManager.State.MENU)
			skin.ui.modulate.a = 0.0
		elif StateManager.current_state == StateManager.State.TITLE:
			StateManager.set_state(StateManager.State.MENU)
			skin.ui.modulate.a = 0.0
		elif StateManager.current_state == StateManager.State.MENU:
			StateManager.set_state(StateManager.State.PLAY)
			skin.ui.modulate.a = 1.0
		velocity = Vector3.ZERO
	#if Input.is_action_just_pressed("title") and not StateManager.current_state == StateManager.State.WEAPON:
		#if StateManager.current_state == StateManager.State.PLAY:
			#StateManager.set_state(StateManager.State.TITLE)
			#skin.ui.modulate.a = 0.0
		#elif StateManager.current_state == StateManager.State.MENU:
			#StateManager.set_state(StateManager.State.TITLE)
			#skin.ui.modulate.a = 0.0
		#elif StateManager.current_state == StateManager.State.TITLE:
			#StateManager.set_state(StateManager.State.PLAY)
			#skin.ui.modulate.a = 1.0
		#velocity = Vector3.ZERO
		
		#print(StateManager.current_state)

func _attacks_logic() -> void:
	if StateManager.current_state == StateManager.State.PLAY and skin.weapon_active: #Physical attackes
		if not Input.is_action_pressed("aim"): 
			if Input.is_action_just_pressed("attack"):
				if skin.attacks[0]:
					skin.current_attack = skin.attacks[0] #in Skill inventory X is first [0]
					skin.attack()
				else:
					print("No attack assigned.")
			if Input.is_action_just_pressed("skill"):
				if skin.attacks[1]:
					skin.current_attack = skin.attacks[1] #in Skill inventory Y is [1]
					skin.attack()
				else:
					print("No attack assigned.")
		elif Input.is_action_pressed("aim"): #Aimmed Physical attackes
			if Input.is_action_just_pressed("attack"):
				if skin.attacks[2]:
					skin.current_attack = skin.attacks[2] #in Skill inventory LT+X is [2]
					skin.attack()
				else:
					print("No attack assigned.")
			elif Input.is_action_just_pressed("skill"):
				if skin.attacks[3]:
					skin.current_attack = skin.attacks[3] #in Skill inventory LT+Y is [3]
					skin.attack()
				else:
					print("No attack assigned.")
	elif StateManager.current_state == StateManager.State.PLAY and not skin.weapon_active: #Mana attackes
		if skin.current_mana_type == 1: #WATER
			if not Input.is_action_pressed("aim"): 
				if Input.is_action_just_pressed("attack"):
					if skin.skill_book.water_skills[0]:
						skin.current_attack = skin.skill_book.water_skills[0] #in Water Skill inventory X is first [0]
						skin.attack()
					else:
						print("No attack assigned.")
				if Input.is_action_just_pressed("skill"):
					if skin.skill_book.water_skills[1]:
						skin.current_attack = skin.skill_book.water_skills[1] #in Water Skill inventory Y is [1]
						skin.attack()
					else:
						print("No attack assigned.")
			elif Input.is_action_pressed("aim"): #Aimmed mana attackes
				if Input.is_action_just_pressed("attack"):
					if skin.skill_book.water_skills[2]:
						skin.current_attack = skin.skill_book.water_skills[2] #in Water Skill inventory LT+X is [2]
						skin.attack()
					else:
						print("No attack assigned.")
				elif Input.is_action_just_pressed("skill"):
					if skin.skill_book.water_skills[3]:
						skin.current_attack = skin.skill_book.water_skills[3] #in Water Skill inventory LT+Y is [3]
						skin.attack()
					else:
						print("No attack assigned.")

		if skin.current_mana_type == 2: #FIRE
			if not Input.is_action_pressed("aim"): 
				if Input.is_action_just_pressed("attack"):
					if skin.skill_book.fire_skills[0]:
						skin.current_attack = skin.skill_book.fire_skills[0] #in Water Skill inventory X is first [0]
						skin.attack()
					else:
						print("No attack assigned.")
				if Input.is_action_just_pressed("skill"):
					if skin.skill_book.fire_skills[1]:
						skin.current_attack = skin.skill_book.fire_skills[1] #in Water Skill inventory Y is [1]
						skin.attack()
					else:
						print("No attack assigned.")
			elif Input.is_action_pressed("aim"): #Aimmed mana attackes
				if Input.is_action_just_pressed("attack"):
					if skin.skill_book.fire_skills[2]:
						skin.current_attack = skin.skill_book.fire_skills[2] #in Water Skill inventory LT+X is [2]
						skin.attack()
					else:
						print("No attack assigned.")
				elif Input.is_action_just_pressed("skill"):
					if skin.skill_book.fire_skills[3]:
						skin.current_attack = skin.skill_book.fire_skills[3] #in Water Skill inventory LT+Y is [3]
						skin.attack()
					else:
						print("No attack assigned.")

		if skin.current_mana_type == 3: #LIGHT
			if not Input.is_action_pressed("aim"): 
				if Input.is_action_just_pressed("attack"):
					if skin.skill_book.light_skills[0]:
						skin.current_attack = skin.skill_book.light_skills[0] #in Water Skill inventory X is first [0]
						skin.attack()
					else:
						print("No attack assigned.")
				if Input.is_action_just_pressed("skill"):
					if skin.skill_book.light_skills[1]:
						skin.current_attack = skin.skill_book.light_skills[1] #in Water Skill inventory Y is [1]
						skin.attack()
					else:
						print("No attack assigned.")
			elif Input.is_action_pressed("aim"): #Aimmed mana attackes
				if Input.is_action_just_pressed("attack"):
					if skin.skill_book.light_skills[2]:
						skin.current_attack = skin.skill_book.light_skills[2] #in Water Skill inventory LT+X is [2]
						skin.attack()
					else:
						print("No attack assigned.")
				elif Input.is_action_just_pressed("skill"):
					if skin.skill_book.light_skills[3]:
						skin.current_attack = skin.skill_book.light_skills[3] #in Water Skill inventory LT+Y is [3]
						skin.attack()
					else:
						print("No attack assigned.")


func _skills_logic() -> void:
	pass

func _move_logic(delta) -> void:
	if StateManager.current_state == StateManager.State.PLAY:
		movement_input = Input.get_vector("move_left","move_right","move_forward","move_backward").rotated(-camera.global_rotation.y)
		var vel_2d = Vector2(velocity.x,velocity.z)
		if is_on_floor():
			is_running = Input.is_action_pressed("run")
		if movement_input != Vector2.ZERO:
			var speed = run_speed if is_running else walk_speed
			vel_2d += movement_input * speed * delta * 10
			vel_2d = vel_2d.limit_length(speed) * speed_modifier
			velocity.x = vel_2d.x
			velocity.z = vel_2d.y
			var target_angle = -movement_input.angle() + PI/2
			skin.rotation.y = rotate_toward(skin.rotation.y, target_angle, 6.0 * delta)
			#tween.tween_property(skin,"rotation:y", target_angle, 0.3)
		else:
			vel_2d = vel_2d.move_toward(Vector2.ZERO, walk_speed * 8.0)
			velocity.x = vel_2d.x
			velocity.z = vel_2d.y
	elif StateManager.current_state == StateManager.State.MENU:
		velocity = Vector3.ZERO

func _jump_logic(delta) -> void:
	if StateManager.current_state == StateManager.State.PLAY:
		if Input.is_action_just_pressed("jump") and is_on_floor() and skin.current_stamina >= 10:
			velocity.y = -jump_velocity
			skin.current_stamina -= 10.0 * stamina_cost_reduction
			$Timers/StaminaRegenTimer.start()
		var gravity = jump_gravity if velocity.y > 0.0 else fall_gravity
		velocity.y -= gravity * delta

func hit(damage: float, attacker: CharacterBody3D) -> void:
	pass

func stop_movement(stop_speed: float, start_speed: float) -> void:
	var tween = create_tween()
	tween.tween_property(self,"speed_modifier", 0.0, stop_speed)
	tween.tween_property(self,"speed_modifier", 1.0, start_speed)
