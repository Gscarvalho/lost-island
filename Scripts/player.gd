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
var stamina_depleted_delay_active := false

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

func _ready() -> void:
	StateManager.state_changed.connect(_on_state_changed)
	_on_state_changed(StateManager.current_state)

func _on_state_changed(state: StateManager.State) -> void:
	var should_pause_regen := state != StateManager.State.PLAY

	for node in get_tree().get_nodes_in_group("regen_timers"):
		var regen_timer := node as Timer

		if regen_timer != null:
			regen_timer.paused = should_pause_regen

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
		_open_weapon_choice()
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

func _open_weapon_choice() -> void:
	$Timers/WeaponChoiceTimer.start()
	StateManager.set_state(StateManager.State.WEAPON)

func _close_weapon_choice() -> void:
	if StateManager.current_state != StateManager.State.WEAPON:
		return

	$Timers/WeaponChoiceTimer.stop()
	StateManager.set_state(StateManager.State.PLAY)
	skin.set_move_timescale(1.0)
	skin.ui.show_timer_ui(false)
	
func _on_weapon_choice_timer_timeout() -> void:
	if StateManager.current_state != StateManager.State.WEAPON:
		return

	_close_weapon_choice()
	$Timers/MenuDelayTimer.start()

func _on_stamina_regen_timer_timeout() -> void:
	if skin.current_stamina <= 0.0 and not stamina_depleted_delay_active:
		print("Stamina depleted, delayed regeneration.")
		stamina_depleted_delay_active = true
		$Timers/StaminaRegenTimer.start(3.0)
		return

	skin.current_stamina = 100.0
	stamina_depleted_delay_active = false
	$Timers/StaminaRegenTimer.stop()

func _menu_logic() -> void:
	if (
	Input.is_action_just_pressed("menu")
	and $Timers/MenuTransitionTimer.is_stopped()
	):
		$Timers/MenuTransitionTimer.start()
		if StateManager.current_state == StateManager.State.PLAY:
			StateManager.set_state(StateManager.State.MENU)
		
		elif StateManager.current_state == StateManager.State.TITLE:
			StateManager.set_state(StateManager.State.MENU)			
		
		elif StateManager.current_state == StateManager.State.MENU:
			StateManager.set_state(StateManager.State.PLAY)			
		
		velocity = Vector3.ZERO

func _try_attack(attack_list: Array, attack_index: int) -> void:
	if attack_index >= attack_list.size():
		print("No attack assigned.")
		return
	var selected_attack = attack_list[attack_index]
	if selected_attack == null:
		print("No attack assigned.")
		return
	if skin.is_action_animation_playing():
		print("Attack already in progress.")
		return
	skin.current_attack = selected_attack
	skin.attack()

func _get_current_magic_skills() -> Array:
	match skin.current_mana_type:
		1:
			return skin.skill_book.water_skills
		2:
			return skin.skill_book.fire_skills
		3:
			return skin.skill_book.light_skills
		_:
			return []

func _attacks_logic() -> void:
	if StateManager.current_state == StateManager.State.PLAY and skin.weapon_active: #Physical attackes
		if not Input.is_action_pressed("aim"): 
			if Input.is_action_just_pressed("attack"):
				_try_attack(skin.attacks, 0)
			if Input.is_action_just_pressed("skill"):
				_try_attack(skin.attacks, 1)
		else:
			if Input.is_action_just_pressed("attack"):
				_try_attack(skin.attacks, 2)
			elif Input.is_action_just_pressed("skill"):
				_try_attack(skin.attacks, 3)
	elif StateManager.current_state == StateManager.State.PLAY and not skin.weapon_active:
		var magic_skills := _get_current_magic_skills()

		if not Input.is_action_pressed("aim"):
			if Input.is_action_just_pressed("attack"):
				_try_attack(magic_skills, 0)

			elif Input.is_action_just_pressed("skill"):
				_try_attack(magic_skills, 1)

		else:
			if Input.is_action_just_pressed("attack"):
				_try_attack(magic_skills, 2)

			elif Input.is_action_just_pressed("skill"):
				_try_attack(magic_skills, 3)

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
