class_name Boss
extends CharacterBody3D

## Basic Boss - Enemy with health that can be damaged by player attacks

# Boss stats
@export_group("Stats")
@export var max_health: float = 500.0
@export var defense: float = 5.0
@export var poise_max: float = 100.0
@export var poise_recovery_rate: float = 10.0

# Visual settings
@export_group("Visual")
@export var hit_flash_duration: float = 0.1
@export var death_fade_duration: float = 1.5

# Current stats
var current_health: float
var current_poise: float
var is_staggered: bool = false
var is_dead: bool = false

# Components
@onready var model: Node3D = $Model
@onready var health_bar: ProgressBar = $HealthBarViewport/SubViewport/HealthBar
@onready var health_label: Label = $HealthBarViewport/SubViewport/HealthBar/HealthLabel
@onready var hitbox: Area3D = $Hitbox
@onready var mesh_instance: MeshInstance3D = $Model/MeshInstance3D

# Materials
var original_material: Material
var hit_material: Material

# Signals
signal BOSS_DAMAGED(damage: float, current_hp: float, max_hp: float)
signal BOSS_STAGGERED
signal BOSS_DIED
signal PHASE_CHANGED(phase: int)

# Phase management
var current_phase: int = 1
var phase_2_threshold: float = 0.6  # Enter phase 2 at 60% health
var phase_3_threshold: float = 0.3  # Enter phase 3 at 30% health

func _ready() -> void:
	# Initialize health
	current_health = max_health
	current_poise = poise_max

	# Setup materials
	if mesh_instance and mesh_instance.mesh:
		original_material = mesh_instance.material_override
		_create_hit_material()

	# Setup hitbox
	if hitbox:
		hitbox.area_entered.connect(_on_hitbox_area_entered)
		hitbox.body_entered.connect(_on_hitbox_body_entered)

	# Update UI
	_update_health_bar()

	print("Boss spawned with ", max_health, " HP")

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Poise recovery
	if not is_staggered and current_poise < poise_max:
		current_poise = min(current_poise + poise_recovery_rate * delta, poise_max)

	# Apply gravity
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	move_and_slide()

func take_damage(amount: float, poise_damage: float = 10.0) -> void:
	if is_dead:
		return

	# Apply defense
	var actual_damage = max(1, amount - defense)
	current_health = max(0, current_health - actual_damage)

	# Apply poise damage
	current_poise = max(0, current_poise - poise_damage)
	if current_poise <= 0 and not is_staggered:
		_enter_stagger()

	# Visual feedback
	_flash_hit()
	_show_damage_number(actual_damage)

	# Update health bar
	_update_health_bar()

	# Emit signal
	BOSS_DAMAGED.emit(actual_damage, current_health, max_health)

	# Check phase transitions
	_check_phase_transition()

	# Check death
	if current_health <= 0:
		_die()

	print("Boss took ", actual_damage, " damage. HP: ", current_health, "/", max_health)

func _enter_stagger() -> void:
	is_staggered = true
	BOSS_STAGGERED.emit()
	print("Boss STAGGERED!")

	# Stagger duration
	await get_tree().create_timer(2.0).timeout

	# Recover from stagger
	is_staggered = false
	current_poise = poise_max * 0.5  # Recover to half poise
	print("Boss recovered from stagger")

func _check_phase_transition() -> void:
	var health_percentage = current_health / max_health

	if current_phase == 1 and health_percentage <= phase_2_threshold:
		current_phase = 2
		PHASE_CHANGED.emit(2)
		print("Boss entered PHASE 2!")
		_flash_phase_change()
	elif current_phase == 2 and health_percentage <= phase_3_threshold:
		current_phase = 3
		PHASE_CHANGED.emit(3)
		print("Boss entered PHASE 3!")
		_flash_phase_change()

func _die() -> void:
	if is_dead:
		return

	is_dead = true
	BOSS_DIED.emit()
	print("Boss DEFEATED!")

	# Disable collision
	if hitbox:
		hitbox.monitoring = false
		hitbox.monitorable = false

	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	# Death animation (fade out)
	var tween = create_tween()
	tween.set_parallel(true)

	if model:
		tween.tween_property(model, "scale", Vector3(1.2, 0.5, 1.2), death_fade_duration)
		tween.tween_property(model, "modulate:a", 0.0, death_fade_duration)

	await tween.finished
	queue_free()

func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

		# Color based on health percentage
		var health_percent = current_health / max_health
		if health_percent > 0.6:
			health_bar.modulate = Color.GREEN
		elif health_percent > 0.3:
			health_bar.modulate = Color.YELLOW
		else:
			health_bar.modulate = Color.RED

	if health_label:
		health_label.text = "%d / %d" % [current_health, max_health]

func _create_hit_material() -> void:
	# Create a white flash material for hit feedback
	hit_material = StandardMaterial3D.new()
	hit_material.albedo_color = Color(1, 1, 1, 1)
	hit_material.emission_enabled = true
	hit_material.emission = Color(1, 0.8, 0.8)
	hit_material.emission_energy_multiplier = 2.0

func _flash_hit() -> void:
	if not mesh_instance:
		return

	# Flash white
	mesh_instance.material_override = hit_material

	await get_tree().create_timer(hit_flash_duration).timeout

	# Return to original
	mesh_instance.material_override = original_material

func _flash_phase_change() -> void:
	if not model:
		return

	# Red flash for phase change
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(model, "modulate", Color(2, 0.5, 0.5), 0.2)
	tween.tween_property(model, "modulate", Color.WHITE, 0.2)

func _show_damage_number(damage: float) -> void:
	# Create floating damage text
	var damage_label = Label3D.new()
	damage_label.text = str(int(damage))
	damage_label.font_size = 64
	damage_label.modulate = Color(1, 0.8, 0)
	damage_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	damage_label.position = Vector3(randf_range(-0.5, 0.5), 2, 0)

	add_child(damage_label)

	# Animate floating up and fading
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "position:y", damage_label.position.y + 2, 1.0)
	tween.tween_property(damage_label, "modulate:a", 0.0, 1.0)

	await tween.finished
	damage_label.queue_free()

func _on_hitbox_area_entered(area: Area3D) -> void:
	# Check if it's a player attack
	if area.is_in_group("player_attack") or area.name == "AttackHitbox":
		# Light attack does 20 damage, heavy does 40
		var damage = 20.0
		var poise_damage = 15.0
		# Check if it's a heavy attack based on parent node or stored data
		if area.has_meta("is_heavy_attack"):
			damage = 40.0
			poise_damage = 30.0

		take_damage(damage, poise_damage)

func _on_hitbox_body_entered(_body: Node3D) -> void:
	# Additional check for body collisions if needed
	pass