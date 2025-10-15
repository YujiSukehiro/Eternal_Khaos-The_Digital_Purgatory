class_name Player
extends CharacterBody3D

## Player Controller - Handles movement, combat, and player state

# Movement parameters (will be data-driven later)
@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var acceleration: float = 10.0
@export var friction: float = 10.0
@export var jump_velocity: float = 8.0
@export var gravity_multiplier: float = 1.5

# Combat parameters
@export_group("Combat")
@export var max_health: float = 100.0
@export var max_stamina: float = 100.0
@export var stamina_regen_rate: float = 20.0
@export var stamina_regen_delay: float = 1.0

# State management
enum PlayerState {
	IDLE,
	MOVING,
	SPRINTING,
	JUMPING,
	FALLING,
	DODGING,
	ATTACKING,
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

# Components
@onready var camera_mount: Node3D = $CameraMount
@onready var spring_arm: SpringArm3D = $CameraMount/SpringArm3D
@onready var camera: Camera3D = $CameraMount/SpringArm3D/Camera3D
@onready var model: Node3D = $Model
@onready var state_label: Label3D = $StateDebugLabel

# Input variables
var input_vector: Vector2 = Vector2.ZERO
var is_sprinting: bool = false
var is_jumping: bool = false

# Physics
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Signals
signal HEALTH_CHANGED(new_health: float, max_health: float)
signal STAMINA_CHANGED(new_stamina: float, max_stamina: float)
signal STATE_CHANGED(new_state: PlayerState, old_state: PlayerState)
signal PLAYER_DIED

func _ready() -> void:
	# Initialize stats
	current_health = max_health
	current_stamina = max_stamina

	# Set up camera
	if camera:
		camera.current = true

	# Connect to state changes for debug
	STATE_CHANGED.connect(_on_state_changed)

	print("Player initialized - Health: ", current_health, " Stamina: ", current_stamina)

func _physics_process(delta: float) -> void:
	# Handle gravity
	if not is_on_floor():
		velocity.y -= gravity * gravity_multiplier * delta
		if velocity.y < 0 and current_state != PlayerState.FALLING:
			_change_state(PlayerState.FALLING)
	elif current_state == PlayerState.FALLING:
		_change_state(PlayerState.IDLE)

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
		PlayerState.ATTACKING:
			_process_attacking(delta)
		PlayerState.PARRYING:
			_process_parrying(delta)
		PlayerState.STUNNED:
			_process_stunned(delta)
		PlayerState.DEAD:
			_process_dead(delta)

	# Apply movement
	move_and_slide()

	# Handle stamina regeneration
	_process_stamina_regen(delta)

	# Update debug label
	if state_label:
		state_label.text = PlayerState.keys()[current_state]

func _input(event: InputEvent) -> void:
	# We'll implement input handling in the next step
	pass

func _process_idle(delta: float) -> void:
	# Apply friction
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	velocity.z = move_toward(velocity.z, 0, friction * delta)

	# Check for state transitions
	if input_vector.length() > 0.1:
		_change_state(PlayerState.MOVING)

func _process_moving(delta: float) -> void:
	# Basic movement for now - will be enhanced with proper input
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	velocity.z = move_toward(velocity.z, 0, friction * delta)

	if input_vector.length() < 0.1:
		_change_state(PlayerState.IDLE)

func _process_sprinting(delta: float) -> void:
	# Sprint movement - will be implemented with input
	pass

func _process_jumping(delta: float) -> void:
	# Jump handling
	if velocity.y <= 0:
		_change_state(PlayerState.FALLING)

func _process_falling(delta: float) -> void:
	# Air control while falling
	pass

func _process_dodging(delta: float) -> void:
	# Dodge mechanics - to be implemented
	pass

func _process_attacking(delta: float) -> void:
	# Attack mechanics - to be implemented
	pass

func _process_parrying(delta: float) -> void:
	# Parry mechanics - to be implemented
	pass

func _process_stunned(delta: float) -> void:
	# Stunned state - no input allowed
	velocity.x = move_toward(velocity.x, 0, friction * 2 * delta)
	velocity.z = move_toward(velocity.z, 0, friction * 2 * delta)

func _process_dead(delta: float) -> void:
	# Death state
	velocity = Vector3.ZERO

func _process_stamina_regen(delta: float) -> void:
	if current_stamina < max_stamina:
		if stamina_regen_timer > 0:
			stamina_regen_timer -= delta
		else:
			current_stamina = min(current_stamina + stamina_regen_rate * delta, max_stamina)
			STAMINA_CHANGED.emit(current_stamina, max_stamina)

func _change_state(new_state: PlayerState) -> void:
	if current_state == new_state:
		return

	previous_state = current_state
	current_state = new_state
	STATE_CHANGED.emit(current_state, previous_state)

func _on_state_changed(new_state: PlayerState, old_state: PlayerState) -> void:
	print("Player state changed from ", PlayerState.keys()[old_state], " to ", PlayerState.keys()[new_state])

## Public methods for external systems

func take_damage(amount: float) -> void:
	if current_state == PlayerState.DEAD:
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

func get_forward_vector() -> Vector3:
	return -model.transform.basis.z if model else -transform.basis.z

func get_right_vector() -> Vector3:
	return model.transform.basis.x if model else transform.basis.x