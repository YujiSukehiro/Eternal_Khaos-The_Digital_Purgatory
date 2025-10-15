class_name InputManager
extends Node

## Input Manager - Defines and manages all input mappings for the game
## Based on industry-standard action RPG controls (Dark Souls, Elden Ring, The First Berserker: Khazan)

# Standard Action RPG Control Scheme (Modified):
#
# LEFT STICK - Movement
# RIGHT STICK - Camera
#
# FACE BUTTONS:
# A/X (PS: X) - Jump
# B/Circle (PS: Circle) - Dodge/Roll
# X/Square (PS: Square) - Use Item
# Y/Triangle (PS: Triangle) - Interact
#
# SHOULDERS:
# LB/L1 - Light Attack
# RB/R1 - Heavy Attack
# LT/L2 - Parry/Block (hold)
# RT/R2 - Special Attack/Skill
#
# STICK CLICKS:
# L3 - Sprint (hold) / Target Lock Toggle
# R3 - Camera Reset
#
# D-PAD:
# Up - Cycle Items Up
# Down - Cycle Items Down
# Left - Cycle Weapons Left
# Right - Cycle Weapons Right
#
# MENU:
# Start/Options - Pause Menu
# Select/Touchpad - Map/Status

static func setup_input_map() -> void:
	# Clear existing actions to ensure clean setup
	_clear_existing_actions()

	# Movement (Left Stick + WASD)
	_add_action("move_forward", [
		_key(KEY_W),
		_joy_axis(JOY_AXIS_LEFT_Y, -1.0)
	])

	_add_action("move_back", [
		_key(KEY_S),
		_joy_axis(JOY_AXIS_LEFT_Y, 1.0)
	])

	_add_action("move_left", [
		_key(KEY_A),
		_joy_axis(JOY_AXIS_LEFT_X, -1.0)
	])

	_add_action("move_right", [
		_key(KEY_D),
		_joy_axis(JOY_AXIS_LEFT_X, 1.0)
	])

	# Camera (Right Stick + Mouse)
	_add_action("camera_up", [
		_joy_axis(JOY_AXIS_RIGHT_Y, -1.0)
	])

	_add_action("camera_down", [
		_joy_axis(JOY_AXIS_RIGHT_Y, 1.0)
	])

	_add_action("camera_left", [
		_joy_axis(JOY_AXIS_RIGHT_X, -1.0)
	])

	_add_action("camera_right", [
		_joy_axis(JOY_AXIS_RIGHT_X, 1.0)
	])

	# Combat Actions
	_add_action("light_attack", [
		_mouse_button(MOUSE_BUTTON_LEFT),
		_key(KEY_J),
		_joy_button(JOY_BUTTON_LEFT_SHOULDER)  # LB/L1
	])

	_add_action("heavy_attack", [
		_mouse_button(MOUSE_BUTTON_RIGHT),
		_key(KEY_K),
		_joy_button(JOY_BUTTON_RIGHT_SHOULDER)  # RB/R1
	])

	_add_action("parry", [
		_key(KEY_F),
		_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.5)  # LT/L2
	])

	_add_action("special_attack", [
		_key(KEY_E),
		_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.5)  # RT/R2
	])

	# Movement Actions
	_add_action("jump", [
		_key(KEY_SPACE),
		_joy_button(JOY_BUTTON_A)  # A/X button for jump
	])

	_add_action("dodge", [
		_key(KEY_CTRL),
		_joy_button(JOY_BUTTON_B)  # B/Circle button for dodge
	])

	_add_action("sprint", [
		_key(KEY_SHIFT),
		_joy_button(JOY_BUTTON_LEFT_STICK)  # L3
	])

	# Targeting
	_add_action("target_lock", [
		_key(KEY_Q),
		_mouse_button(MOUSE_BUTTON_MIDDLE),
		_joy_button(JOY_BUTTON_LEFT_STICK)  # L3 toggle
	])

	_add_action("camera_reset", [
		_key(KEY_R),
		_joy_button(JOY_BUTTON_RIGHT_STICK)  # R3
	])

	# Interaction
	_add_action("interact", [
		_key(KEY_E),
		_joy_button(JOY_BUTTON_Y)  # Y/Triangle for interact (since B is now dodge)
	])

	_add_action("use_item", [
		_key(KEY_X),
		_joy_button(JOY_BUTTON_X)  # X/Square
	])

	# Weapon/Item Management
	_add_action("switch_weapon", [
		_key(KEY_TAB),
		_joy_button(JOY_BUTTON_DPAD_RIGHT)  # D-pad right for weapon switch
	])

	_add_action("item_up", [
		_key(KEY_1),
		_joy_button(JOY_BUTTON_DPAD_UP)
	])

	_add_action("item_down", [
		_key(KEY_2),
		_joy_button(JOY_BUTTON_DPAD_DOWN)
	])

	_add_action("weapon_left", [
		_key(KEY_3),
		_joy_button(JOY_BUTTON_DPAD_LEFT)
	])

	_add_action("weapon_right", [
		_key(KEY_4),
		_joy_button(JOY_BUTTON_DPAD_RIGHT)
	])

	# Menu
	_add_action("pause_menu", [
		_key(KEY_ESCAPE),
		_joy_button(JOY_BUTTON_START)
	])

	_add_action("status_menu", [
		_key(KEY_I),
		_joy_button(JOY_BUTTON_BACK)  # Select/Touchpad
	])

	# Debug
	_add_action("debug_menu", [
		_key(KEY_F1)
	])

	print("Input map configured with standard action RPG controls")

static func _clear_existing_actions() -> void:
	var actions = [
		"move_forward", "move_back", "move_left", "move_right",
		"camera_up", "camera_down", "camera_left", "camera_right",
		"light_attack", "heavy_attack", "parry", "special_attack",
		"dodge", "sprint", "jump", "target_lock", "camera_reset",
		"interact", "use_item", "switch_weapon",
		"item_up", "item_down", "weapon_left", "weapon_right",
		"pause_menu", "status_menu", "debug_menu"
	]

	for action in actions:
		if InputMap.has_action(action):
			InputMap.erase_action(action)

static func _add_action(action_name: String, events: Array) -> void:
	InputMap.add_action(action_name)
	for event in events:
		InputMap.action_add_event(action_name, event)

static func _key(keycode: int) -> InputEventKey:
	var event = InputEventKey.new()
	event.keycode = keycode
	return event

static func _mouse_button(button: int) -> InputEventMouseButton:
	var event = InputEventMouseButton.new()
	event.button_index = button
	return event

static func _joy_button(button: int) -> InputEventJoypadButton:
	var event = InputEventJoypadButton.new()
	event.button_index = button
	return event

static func _joy_axis(axis: int, value: float) -> InputEventJoypadMotion:
	var event = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event

## Get movement input as a Vector2
static func get_movement_vector() -> Vector2:
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_forward", "move_back")
	return input_vector.normalized() if input_vector.length() > 1.0 else input_vector

## Get camera input as a Vector2
static func get_camera_vector() -> Vector2:
	var camera_vector = Vector2.ZERO
	camera_vector.x = Input.get_axis("camera_left", "camera_right")
	camera_vector.y = Input.get_axis("camera_up", "camera_down")
	return camera_vector