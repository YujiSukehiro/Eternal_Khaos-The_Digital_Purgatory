class_name SkeletonBuilder
extends Node

## Utility class for building anatomically correct humanoid Skeleton3D
## Generates 55-bone skeleton with proper hierarchy and proportions

# Anatomical proportions (based on 1.8 unit tall character)
const CHARACTER_HEIGHT: float = 1.8
const HEAD_SIZE: float = 0.25
const TORSO_HEIGHT: float = 0.7
const ARM_LENGTH: float = 0.9
const LEG_LENGTH: float = 0.9
const HAND_LENGTH: float = 0.2
const FOOT_LENGTH: float = 0.25

# Bone indices (stored for reference)
var bone_indices: Dictionary = {}

## Creates a complete humanoid skeleton with proper bone hierarchy
## Returns the configured Skeleton3D node
static func create_humanoid_skeleton() -> Skeleton3D:
	var skeleton := Skeleton3D.new()
	skeleton.name = "Skeleton3D"

	var builder := SkeletonBuilder.new()
	builder._build_skeleton(skeleton)

	return skeleton

## Internal method to build the full bone hierarchy
func _build_skeleton(skeleton: Skeleton3D) -> void:
	# Root bone (Hips) at character center
	var root_idx := _add_bone(skeleton, "Root", -1, Vector3(0, 0.9, 0))
	bone_indices["Root"] = root_idx

	# Spine chain (3 bones from hips to shoulders)
	var spine1_idx := _add_bone(skeleton, "Spine_01", root_idx, Vector3(0, 0.15, 0))
	var spine2_idx := _add_bone(skeleton, "Spine_02", spine1_idx, Vector3(0, 0.2, 0))
	var spine3_idx := _add_bone(skeleton, "Spine_03", spine2_idx, Vector3(0, 0.2, 0))
	bone_indices["Spine_01"] = spine1_idx
	bone_indices["Spine_02"] = spine2_idx
	bone_indices["Spine_03"] = spine3_idx

	# Neck and head
	var neck_idx := _add_bone(skeleton, "Neck", spine3_idx, Vector3(0, 0.15, 0))
	var head_idx := _add_bone(skeleton, "Head", neck_idx, Vector3(0, 0.15, 0))
	bone_indices["Neck"] = neck_idx
	bone_indices["Head"] = head_idx

	# Left arm chain
	_build_arm_chain(skeleton, spine3_idx, "L", Vector3(-0.25, 0.1, 0))

	# Right arm chain
	_build_arm_chain(skeleton, spine3_idx, "R", Vector3(0.25, 0.1, 0))

	# Left leg chain
	_build_leg_chain(skeleton, root_idx, "L", Vector3(-0.15, 0, 0))

	# Right leg chain
	_build_leg_chain(skeleton, root_idx, "R", Vector3(0.15, 0, 0))

	# Finalize skeleton
	skeleton.reset_bone_poses()
	print("Skeleton built successfully with %d bones" % skeleton.get_bone_count())

## Builds a complete arm with hand and 5 fingers
func _build_arm_chain(skeleton: Skeleton3D, parent_idx: int, side: String, offset: Vector3) -> void:
	# Shoulder
	var shoulder_idx := _add_bone(skeleton, "Shoulder_" + side, parent_idx, offset)
	bone_indices["Shoulder_" + side] = shoulder_idx

	# Upper arm (humerus)
	var upper_arm_offset := Vector3(-0.15 if side == "L" else 0.15, -0.05, 0)
	var upper_arm_idx := _add_bone(skeleton, "UpperArm_" + side, shoulder_idx, upper_arm_offset)
	bone_indices["UpperArm_" + side] = upper_arm_idx

	# Forearm (radius/ulna)
	var forearm_idx := _add_bone(skeleton, "ForeArm_" + side, upper_arm_idx, Vector3(-0.15 if side == "L" else 0.15, -0.25, 0))
	bone_indices["ForeArm_" + side] = forearm_idx

	# Hand
	var hand_idx := _add_bone(skeleton, "Hand_" + side, forearm_idx, Vector3(-0.1 if side == "L" else 0.1, -0.15, 0))
	bone_indices["Hand_" + side] = hand_idx

	# Fingers (5 fingers, 3 joints each)
	_build_finger(skeleton, hand_idx, "Thumb", side, Vector3(-0.03 if side == "L" else 0.03, -0.04, 0.02), 45.0)
	_build_finger(skeleton, hand_idx, "Index", side, Vector3(-0.06 if side == "L" else 0.06, -0.08, 0.01), 0.0)
	_build_finger(skeleton, hand_idx, "Middle", side, Vector3(-0.06 if side == "L" else 0.06, -0.09, 0), 0.0)
	_build_finger(skeleton, hand_idx, "Ring", side, Vector3(-0.06 if side == "L" else 0.06, -0.08, -0.01), 0.0)
	_build_finger(skeleton, hand_idx, "Pinky", side, Vector3(-0.05 if side == "L" else 0.05, -0.07, -0.02), 0.0)

## Builds a single finger with 3 joints
func _build_finger(skeleton: Skeleton3D, hand_idx: int, name: String, side: String, start_offset: Vector3, angle: float) -> void:
	# Proximal phalanx (first joint, longest)
	var joint1_idx := _add_bone(skeleton, name + "_01_" + side, hand_idx, start_offset)
	bone_indices[name + "_01_" + side] = joint1_idx

	# Middle phalanx (second joint)
	var dir := Vector3(-1 if side == "L" else 1, 0, 0)
	var joint2_idx := _add_bone(skeleton, name + "_02_" + side, joint1_idx, dir * 0.04)
	bone_indices[name + "_02_" + side] = joint2_idx

	# Distal phalanx (third joint, tip)
	var joint3_idx := _add_bone(skeleton, name + "_03_" + side, joint2_idx, dir * 0.035)
	bone_indices[name + "_03_" + side] = joint3_idx

## Builds a complete leg with foot and toes
func _build_leg_chain(skeleton: Skeleton3D, parent_idx: int, side: String, offset: Vector3) -> void:
	# Upper leg (femur)
	var upper_leg_idx := _add_bone(skeleton, "UpperLeg_" + side, parent_idx, offset)
	bone_indices["UpperLeg_" + side] = upper_leg_idx

	# Lower leg (tibia/fibula)
	var lower_leg_idx := _add_bone(skeleton, "LowerLeg_" + side, upper_leg_idx, Vector3(0, -0.45, 0))
	bone_indices["LowerLeg_" + side] = lower_leg_idx

	# Foot
	var foot_idx := _add_bone(skeleton, "Foot_" + side, lower_leg_idx, Vector3(0, -0.45, 0))
	bone_indices["Foot_" + side] = foot_idx

	# Toes
	var toe_idx := _add_bone(skeleton, "Toe_" + side, foot_idx, Vector3(0, 0, 0.15))
	bone_indices["Toe_" + side] = toe_idx

## Adds a bone to the skeleton and returns its index
func _add_bone(skeleton: Skeleton3D, bone_name: String, parent_idx: int, rest_position: Vector3) -> int:
	var bone_idx := skeleton.get_bone_count()
	skeleton.add_bone(bone_name)

	# Set parent relationship
	if parent_idx >= 0:
		skeleton.set_bone_parent(bone_idx, parent_idx)

	# Set rest pose (T-pose)
	var rest_transform := Transform3D(Basis.IDENTITY, rest_position)
	skeleton.set_bone_rest(bone_idx, rest_transform)

	return bone_idx

## Helper to get bone index by name
static func get_bone_idx(skeleton: Skeleton3D, bone_name: String) -> int:
	return skeleton.find_bone(bone_name)

## Creates a simple segmented mesh for a bone
static func create_bone_mesh_segment(bone_name: String, length: float, thickness: float, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = bone_name + "_Mesh"

	# Create capsule mesh for limbs, box for other parts
	var mesh: Mesh
	if "Leg" in bone_name or "Arm" in bone_name or "Spine" in bone_name:
		var capsule := CapsuleMesh.new()
		capsule.radius = thickness
		capsule.height = length
		mesh = capsule
	elif "Hand" in bone_name or "Foot" in bone_name:
		var box := BoxMesh.new()
		box.size = Vector3(thickness * 2, thickness, length)
		mesh = box
	elif "Finger" in bone_name or "Thumb" in bone_name or "Toe" in bone_name:
		var capsule := CapsuleMesh.new()
		capsule.radius = thickness * 0.5
		capsule.height = length
		mesh = capsule
	elif "Head" in bone_name:
		var sphere := SphereMesh.new()
		sphere.radius = thickness
		sphere.height = thickness * 2
		mesh = sphere
	else:
		var box := BoxMesh.new()
		box.size = Vector3(thickness, length, thickness)
		mesh = box

	# Apply material
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.1
	material.roughness = 0.8
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material

	return mesh_instance

## Attaches mesh segments to skeleton bones using BoneAttachment3D
static func attach_mesh_to_bone(skeleton: Skeleton3D, bone_name: String, mesh: MeshInstance3D, offset: Vector3 = Vector3.ZERO) -> BoneAttachment3D:
	var bone_attachment := BoneAttachment3D.new()
	bone_attachment.name = bone_name + "_Attachment"
	bone_attachment.bone_name = bone_name

	# Add mesh as child with offset
	mesh.position = offset
	bone_attachment.add_child(mesh)

	# Add attachment to skeleton
	skeleton.add_child(bone_attachment)

	return bone_attachment
