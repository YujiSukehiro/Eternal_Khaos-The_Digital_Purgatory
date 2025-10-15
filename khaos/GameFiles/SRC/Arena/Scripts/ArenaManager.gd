class_name ArenaManager
extends Node3D

## Arena Manager - Handles arena-specific logic like hazards, spawn points, and boundaries

# Spawn point references
@export var player_spawn_point: Marker3D
@export var boss_spawn_point: Marker3D
@export var arena_bounds: Vector2 = Vector2(40, 40)  # Width and depth of arena

# Arena state
var is_combat_active: bool = false
var arena_phase: int = 1

# Signals for arena events
signal COMBAT_STARTED
signal COMBAT_ENDED
signal PHASE_CHANGED(new_phase: int)

func _ready() -> void:
	_setup_spawn_points()
	print("Arena initialized - Size: ", arena_bounds)

func _setup_spawn_points() -> void:
	# Find spawn points if not assigned
	if not player_spawn_point:
		player_spawn_point = $SpawnPoints/PlayerSpawn
	if not boss_spawn_point:
		boss_spawn_point = $SpawnPoints/BossSpawn

## Get the player spawn position
func get_player_spawn_position() -> Vector3:
	if player_spawn_point:
		return player_spawn_point.global_position
	return Vector3.ZERO

## Get the boss spawn position
func get_boss_spawn_position() -> Vector3:
	if boss_spawn_point:
		return boss_spawn_point.global_position
	return Vector3(0, 1, -10)

## Start combat in the arena
func start_combat() -> void:
	if not is_combat_active:
		is_combat_active = true
		arena_phase = 1
		COMBAT_STARTED.emit()
		print("Combat started in arena")

## End combat in the arena
func end_combat(victory: bool = false) -> void:
	if is_combat_active:
		is_combat_active = false
		COMBAT_ENDED.emit()
		print("Combat ended - Victory: ", victory)

## Change arena phase (for boss phases or environmental changes)
func set_arena_phase(phase: int) -> void:
	if arena_phase != phase:
		arena_phase = phase
		PHASE_CHANGED.emit(phase)
		_apply_phase_changes(phase)

func _apply_phase_changes(phase: int) -> void:
	# This is where we'd add environmental changes based on boss phases
	match phase:
		1:
			print("Arena Phase 1 - Normal")
		2:
			print("Arena Phase 2 - Increased danger")
			# Could add hazards, change lighting, etc.
		3:
			print("Arena Phase 3 - Final phase")
			# Maximum danger, environmental effects

## Check if a position is within arena bounds
func is_position_in_bounds(pos: Vector3) -> bool:
	var half_width = arena_bounds.x / 2.0
	var half_depth = arena_bounds.y / 2.0
	return abs(pos.x) <= half_width and abs(pos.z) <= half_depth

## Get the closest point within bounds from a given position
func clamp_to_bounds(pos: Vector3) -> Vector3:
	var half_width = arena_bounds.x / 2.0
	var half_depth = arena_bounds.y / 2.0
	pos.x = clamp(pos.x, -half_width, half_width)
	pos.z = clamp(pos.z, -half_depth, half_depth)
	return pos

## Get distance from position to nearest arena edge
func get_distance_to_edge(pos: Vector3) -> float:
	var half_width = arena_bounds.x / 2.0
	var half_depth = arena_bounds.y / 2.0

	var dist_to_x_edge = half_width - abs(pos.x)
	var dist_to_z_edge = half_depth - abs(pos.z)

	return min(dist_to_x_edge, dist_to_z_edge)