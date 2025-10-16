class_name PlayerController
extends CharacterBody3D

## Enhanced Player Controller with industry-standard controls
## Based on The First Berserker: Khazan and similar action RPGs

# Movement settings
@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var dodge_speed: float = 12.0
@export var acceleration: float = 10.0
@export var friction: float = 10.0
@export var air_friction: float = 3.0
@export var jump_velocity: float = 8.0
@export var gravity_multiplier: float = 1.5
@export var rotation_speed: float = 10.0

# Camera settings
@export_group("Camera")
@export var camera_sensitivity: float = 0.3
@export var camera_vertical_min: float = -60.0
@export var camera_vertical_max: float = 60.0
@export var camera_distance: float = 1.2  # Close camera like First Berserker
@export var camera_height: float = 2.0
@export var camera_side_offset: float = 0.5

# Combat settings
@export_group("Combat")
@export var max_health: float = 100.0
@export var max_stamina: float = 100.0
@export var stamina_regen_rate: float = 20.0
@export var stamina_regen_delay: float = 1.0
@export var dodge_stamina_cost: float = 20.0
@export var sprint_stamina_drain: float = 10.0
@export var light_attack_stamina: float = 10.0
@export var heavy_attack_stamina: float = 20.0

# Dodge settings
@export_group("Dodge")
@export var dodge_duration: float = 0.4
@export var dodge_invulnerability_time: float = 0.25
@export var dodge_cooldown: float = 0.2

# State management
enum PlayerState {
	IDLE,
	MOVING,
	SPRINTING,
	JUMPING,
	FALLING,
	DODGING,
	LIGHT_ATTACK,
	HEAVY_ATTACK,
	PARRYING,
	STUNNED,
	DEAD
}

# Current state
var current_state: PlayerState = PlayerState.IDLE
var previous_state: PlayerState = PlayerState.IDLE

# Stats
var current_health: float
var current_stamina: float
var stamina_regen_timer: float = 0.0

# Movement variables
var input_vector: Vector2 = Vector2.ZERO
var last_movement_direction: Vector3 = Vector3.ZERO
var is_sprinting: bool = false
var can_dodge: bool = true
var dodge_timer: float = 0.0
var dodge_direction: Vector3 = Vector3.ZERO

# Camera variables
var camera_rotation_x: float = 0.0
var camera_rotation_y: float = 0.0
var is_locked_on: bool = false
var lock_on_target: Node3D = null

# Combat variables
var combo_counter: int = 0
var attack_buffer: String = ""
var is_invulnerable: bool = false

# Components
@onready var model: Node3D = $BakedPlayer/FullModel/Skeleton3D  # Rigged character skeleton
@onready var camera_mount: Node3D = $CameraMount
@onready var spring_arm: SpringArm3D = $CameraMount/SpringArm3D
@onready var camera: Camera3D = $CameraMount/SpringArm3D/Camera3D
@onready var state_label: Label3D = null  # Optional - add StateDebugLabel if you want debug info
@onready var animation_player: AnimationPlayer = $BakedPlayer/AnimationPlayer  # Correct path from copied node path
@onready var attack_hitbox: Area3D = null  # Will add weapon/hitbox later

# Physics
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Signals
signal HEALTH_CHANGED(new_health: float, max_health: float)
signal STAMINA_CHANGED(new_stamina: float, max_stamina: float)
signal STATE_CHANGED(new_state: PlayerState, old_state: PlayerState)
signal PLAYER_DIED

func _ready() -> void:
	# Setup input map
	InputManager.setup_input_map()

	# Initialize stats
	current_health = max_health
	current_stamina = max_stamina

	# Set up camera
	if camera:
		camera.current = true
	if spring_arm:
		spring_arm.spring_length = camera_distance

	# Capture mouse for camera control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Connect to state changes for debug
	STATE_CHANGED.connect(_on_state_changed)

	print("Player controller initialized with standard controls")
	print("Controls: WASD/Left Stick - Move, Mouse/Right Stick - Camera")
	print("Space/A - Jump, Ctrl/B - Dodge, Shift/L3 - Sprint, LMB/LB - Light Attack, RMB/RB - Heavy Attack")

func _input(event: InputEvent) -> void:
	# Handle mouse camera control
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_rotation_y -= event.relative.x * camera_sensitivity * 0.01
		camera_rotation_x -= event.relative.y * camera_sensitivity * 0.01
		camera_rotation_x = clamp(camera_rotation_x, deg_to_rad(camera_vertical_min), deg_to_rad(camera_vertical_max))

	# Handle action inputs
	if event.is_action_pressed("pause_menu"):
		_toggle_pause()

	if event.is_action_pressed("target_lock"):
		_toggle_lock_on()

	# Combat inputs
	if not _is_busy():
		if event.is_action_pressed("light_attack"):
			_start_light_attack()
		elif event.is_action_pressed("heavy_attack"):
			_start_heavy_attack()
		elif event.is_action_pressed("dodge") and can_dodge:
			_start_dodge()
		elif event.is_action_pressed("parry"):
			_start_parry()

func _physics_process(delta: float) -> void:
	# Get input
	input_vector = InputManager.get_movement_vector()
	is_sprinting = Input.is_action_pressed("sprint") and input_vector.length() > 0.1

	# Handle gravity
	if not is_on_floor():
		velocity.y -= gravity * gravity_multiplier * delta
		if velocity.y < 0 and current_state != PlayerState.FALLING and current_state != PlayerState.DODGING:
			_change_state(PlayerState.FALLING)
	elif current_state == PlayerState.FALLING:
		_change_state(PlayerState.IDLE)

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not _is_busy():
		velocity.y = jump_velocity
		_change_state(PlayerState.JUMPING)

	# Process based on current state
	match current_state:
		PlayerState.IDLE:
			_process_idle(delta)
		PlayerState.MOVING:
			_process_moving(delta)
		PlayerState.SPRINTING:
			_process_sprinting(delta)
		PlayerState.JUMPING:
			_process_jumping(delta)
		PlayerState.FALLING:
			_process_falling(delta)
		PlayerState.DODGING:
			_process_dodging(delta)
		PlayerState.LIGHT_ATTACK:
			_process_light_attack(delta)
		PlayerState.HEAVY_ATTACK:
			_process_heavy_attack(delta)
		PlayerState.PARRYING:
			_process_parrying(delta)
		PlayerState.STUNNED:
			_process_stunned(delta)
		PlayerState.DEAD:
			_process_dead(delta)

	# Apply movement
	move_and_slide()

	# Update camera
	_update_camera(delta)

	# Handle stamina regeneration
	_process_stamina_regen(delta)

	# Update dodge cooldown
	if not can_dodge:
		dodge_timer -= delta
		if dodge_timer <= 0:
			can_dodge = true

	# Update debug label
	if state_label:
		state_label.text = PlayerState.keys()[current_state] + "\nHP: %d/%d\nST: %d/%d" % [current_health, max_health, current_stamina, max_stamina]

func _process_idle(delta: float) -> void:
	# Apply friction
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	velocity.z = move_toward(velocity.z, 0, friction * delta)

	# Check for state transitions
	if input_vector.length() > 0.1:
		if is_sprinting and current_stamina > 0:
			_change_state(PlayerState.SPRINTING)
		else:
			_change_state(PlayerState.MOVING)

func _process_moving(delta: float) -> void:
	var direction = _get_movement_direction()

	if direction.length() > 0:
		# Accelerate
		velocity.x = move_toward(velocity.x, direction.x * walk_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * walk_speed, acceleration * delta)

		# Rotate model to face movement direction
		_rotate_to_movement(direction, delta)
		last_movement_direction = direction
	else:
		# Apply friction
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
		_change_state(PlayerState.IDLE)

	# Check for sprint
	if is_sprinting and current_stamina > 0:
		_change_state(PlayerState.SPRINTING)

func _process_sprinting(delta: float) -> void:
	if not is_sprinting or current_stamina <= 0 or input_vector.length() < 0.1:
		_change_state(PlayerState.MOVING if input_vector.length() > 0.1 else PlayerState.IDLE)
		return

	var direction = _get_movement_direction()

	if direction.length() > 0:
		# Sprint movement
		velocity.x = move_toward(velocity.x, direction.x * sprint_speed, acceleration * 1.5 * delta)
		velocity.z = move_toward(velocity.z, direction.z * sprint_speed, acceleration * 1.5 * delta)

		# Rotate to movement
		_rotate_to_movement(direction, delta)
		last_movement_direction = direction

		# Drain stamina
		use_stamina(sprint_stamina_drain * delta)

func _process_jumping(delta: float) -> void:
	# Air control
	_apply_air_movement(delta)

	if velocity.y <= 0:
		_change_state(PlayerState.FALLING)

func _process_falling(delta: float) -> void:
	# Air control
	_apply_air_movement(delta)

func _process_dodging(delta: float) -> void:
	# Apply dodge movement
	velocity.x = dodge_direction.x * dodge_speed
	velocity.z = dodge_direction.z * dodge_speed

	# Handle invulnerability
	dodge_timer -= delta
	if dodge_timer <= (dodge_duration - dodge_invulnerability_time):
		is_invulnerable = false

	if dodge_timer <= 0:
		_change_state(PlayerState.IDLE)
		can_dodge = false
		dodge_timer = dodge_cooldown

func _process_light_attack(delta: float) -> void:
	# Light attack animation would play here
	# For now, just return to idle after a short time
	velocity.x = move_toward(velocity.x, 0, friction * 2 * delta)
	velocity.z = move_toward(velocity.z, 0, friction * 2 * delta)

func _process_heavy_attack(delta: float) -> void:
	# Heavy attack animation would play here
	velocity.x = move_toward(velocity.x, 0, friction * 3 * delta)
	velocity.z = move_toward(velocity.z, 0, friction * 3 * delta)

func _process_parrying(delta: float) -> void:
	# Parry stance
	velocity.x = move_toward(velocity.x, 0, friction * 2 * delta)
	velocity.z = move_toward(velocity.z, 0, friction * 2 * delta)

	if not Input.is_action_pressed("parry"):
		_change_state(PlayerState.IDLE)

func _process_stunned(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, friction * 2 * delta)
	velocity.z = move_toward(velocity.z, 0, friction * 2 * delta)

func _process_dead(delta: float) -> void:
	velocity = Vector3.ZERO

func _process_stamina_regen(delta: float) -> void:
	if current_stamina < max_stamina:
		if stamina_regen_timer > 0:
			stamina_regen_timer -= delta
		else:
			current_stamina = min(current_stamina + stamina_regen_rate * delta, max_stamina)
			STAMINA_CHANGED.emit(current_stamina, max_stamina)

func _update_camera(delta: float) -> void:
	if not camera_mount:
		return

	# Apply camera rotation
	camera_mount.rotation.y = camera_rotation_y
	if spring_arm:
		spring_arm.rotation.x = camera_rotation_x

	# Handle gamepad camera input (with much higher sensitivity multiplier)
	var camera_input = InputManager.get_camera_vector()
	if camera_input.length() > 0.1:
		# Multiply by 10 for gamepad - gamepad needs higher sensitivity than mouse
		camera_rotation_y -= camera_input.x * camera_sensitivity * delta * 10.0
		camera_rotation_x -= camera_input.y * camera_sensitivity * delta * 10.0
		camera_rotation_x = clamp(camera_rotation_x, deg_to_rad(camera_vertical_min), deg_to_rad(camera_vertical_max))

func _get_movement_direction() -> Vector3:
	if input_vector.length() < 0.1:
		return Vector3.ZERO

	var cam_transform = camera.global_transform if camera else global_transform
	var forward = -cam_transform.basis.z
	var right = cam_transform.basis.x

	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()

	return (forward * -input_vector.y + right * input_vector.x).normalized()

func _rotate_to_movement(direction: Vector3, delta: float) -> void:
	if model and direction.length() > 0:
		# Add PI (180 degrees) to flip character forward
		var target_rotation = atan2(direction.x, direction.z) + PI
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation, rotation_speed * delta)

func _apply_air_movement(delta: float) -> void:
	var direction = _get_movement_direction()
	if direction.length() > 0:
		velocity.x = move_toward(velocity.x, direction.x * walk_speed * 0.5, air_friction * delta)
		velocity.z = move_toward(velocity.z, direction.z * walk_speed * 0.5, air_friction * delta)

func _start_dodge() -> void:
	if not use_stamina(dodge_stamina_cost):
		return

	var direction = _get_movement_direction()
	if direction.length() < 0.1:
		direction = last_movement_direction

	if direction.length() < 0.1:
		# Get forward direction from model (accounting for 180° rotation)
		direction = -model.transform.basis.z if model else -transform.basis.z

	dodge_direction = direction.normalized()
	dodge_timer = dodge_duration
	is_invulnerable = true
	_change_state(PlayerState.DODGING)

func _start_light_attack() -> void:
	if not use_stamina(light_attack_stamina):
		return
	_change_state(PlayerState.LIGHT_ATTACK)
	combo_counter += 1

	# Play light attack animation
	if animation_player and animation_player.has_animation("light_attack"):
		animation_player.play("light_attack")
		# Wait for animation to finish
		await animation_player.animation_finished
		if current_state == PlayerState.LIGHT_ATTACK:
			_change_state(PlayerState.IDLE)
			# Reset combo after a delay
			await get_tree().create_timer(0.5).timeout
			combo_counter = 0
	else:
		# Fallback if no animation
		await get_tree().create_timer(0.4).timeout
		if current_state == PlayerState.LIGHT_ATTACK:
			_change_state(PlayerState.IDLE)

func _start_heavy_attack() -> void:
	if not use_stamina(heavy_attack_stamina):
		return
	_change_state(PlayerState.HEAVY_ATTACK)

	# Play heavy attack animation
	if animation_player and animation_player.has_animation("Swing_heavy"):
		animation_player.play("Swing_heavy")
		# Wait for animation to finish
		await animation_player.animation_finished
		if current_state == PlayerState.HEAVY_ATTACK:
			_change_state(PlayerState.IDLE)
	elif animation_player and animation_player.has_animation("heavy_attack"):
		animation_player.play("heavy_attack")
		# Wait for animation to finish
		await animation_player.animation_finished
		if current_state == PlayerState.HEAVY_ATTACK:
			_change_state(PlayerState.IDLE)
	else:
		# Fallback if no animation
		await get_tree().create_timer(0.8).timeout
		if current_state == PlayerState.HEAVY_ATTACK:
			_change_state(PlayerState.IDLE)

func _start_parry() -> void:
	_change_state(PlayerState.PARRYING)

func _toggle_lock_on() -> void:
	is_locked_on = !is_locked_on
	# Lock-on logic would go here
	print("Target lock: ", "ON" if is_locked_on else "OFF")

func _toggle_pause() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _is_busy() -> bool:
	return current_state in [
		PlayerState.DODGING,
		PlayerState.LIGHT_ATTACK,
		PlayerState.HEAVY_ATTACK,
		PlayerState.PARRYING,
		PlayerState.STUNNED,
		PlayerState.DEAD
	]

func _change_state(new_state: PlayerState) -> void:
	if current_state == new_state:
		return

	previous_state = current_state
	current_state = new_state
	STATE_CHANGED.emit(current_state, previous_state)

func _on_state_changed(new_state: PlayerState, old_state: PlayerState) -> void:
	print("State: ", PlayerState.keys()[old_state], " -> ", PlayerState.keys()[new_state])

	# Play animations based on state
	if animation_player:
		match new_state:
			PlayerState.IDLE:
				if animation_player.has_animation("Stand"):
					animation_player.play("Stand")
				elif animation_player.has_animation("Idle"):
					animation_player.play("Idle")
				elif animation_player.has_animation("idle"):
					animation_player.play("idle")
				else:
					animation_player.stop()
			PlayerState.MOVING:
				if animation_player.has_animation("Walk"):
					animation_player.play("Walk")
				elif animation_player.has_animation("walk"):
					animation_player.play("walk")
			PlayerState.SPRINTING:
				if animation_player.has_animation("Run"):
					animation_player.play("Run")
				elif animation_player.has_animation("run"):
					animation_player.play("run")
				elif animation_player.has_animation("Walk"):
					# Use Walk animation but speed it up
					animation_player.play("Walk")
					animation_player.speed_scale = 1.5
				elif animation_player.has_animation("walk"):
					# Use walk animation but speed it up
					animation_player.play("walk")
					animation_player.speed_scale = 1.5
			PlayerState.JUMPING:
				if animation_player.has_animation("jump"):
					animation_player.play("jump")
			PlayerState.FALLING:
				if animation_player.has_animation("fall"):
					animation_player.play("fall")
			PlayerState.DODGING:
				if animation_player.has_animation("dodge"):
					animation_player.play("dodge")

		# Reset speed scale when not sprinting
		if new_state != PlayerState.SPRINTING:
			animation_player.speed_scale = 1.0

# Public methods
func take_damage(amount: float) -> void:
	if is_invulnerable or current_state == PlayerState.DEAD:
		return

	current_health = max(0, current_health - amount)
	HEALTH_CHANGED.emit(current_health, max_health)

	if current_health <= 0:
		_change_state(PlayerState.DEAD)
		PLAYER_DIED.emit()

func use_stamina(amount: float) -> bool:
	if current_stamina >= amount:
		current_stamina -= amount
		stamina_regen_timer = stamina_regen_delay
		STAMINA_CHANGED.emit(current_stamina, max_stamina)
		return true
	return false

func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	HEALTH_CHANGED.emit(current_health, max_health)

# Animation callbacks
func _on_attack_hit_start() -> void:
	# Enable hitbox during the active frames of the attack
	if attack_hitbox:
		attack_hitbox.monitoring = true
		# Tag the attack type based on current state
		if current_state == PlayerState.HEAVY_ATTACK:
			attack_hitbox.set_meta("is_heavy_attack", true)
			attack_hitbox.set_meta("damage", 40.0)
		else:
			attack_hitbox.set_meta("is_heavy_attack", false)
			attack_hitbox.set_meta("damage", 20.0)

		# Add to player attack group
		if not attack_hitbox.is_in_group("player_attack"):
			attack_hitbox.add_to_group("player_attack")

		print("Attack hitbox activated - Heavy: ", attack_hitbox.get_meta("is_heavy_attack", false))

func _on_attack_hit_end() -> void:
	# Disable hitbox after the active frames
	if attack_hitbox:
		attack_hitbox.monitoring = false
		print("Attack hitbox deactivated")