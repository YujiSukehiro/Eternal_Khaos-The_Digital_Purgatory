"""
Automatic Mesh Fitter for Khaos Project
Reads the skeleton in the scene and automatically generates fitted meshes

USAGE:
1. Make sure your skeleton is in the scene (run skeleton_generator_clean.py first)
2. Adjust bones if needed
3. Run this script (Alt+P)
4. Meshes will be automatically generated and fitted to ALL bones
5. Can re-run anytime to regenerate meshes

This script is SMART - it calculates mesh positions/sizes from actual bone data!
"""

import bpy
import bmesh
import math
from mathutils import Vector, Matrix, Quaternion

class MeshAutoFitter:
    """Automatically generates and fits meshes to skeleton bones"""

    def __init__(self):
        self.armature = None
        self.mesh_parts = []

    def find_armature(self):
        """Find the armature in the scene"""
        for obj in bpy.data.objects:
            if obj.type == 'ARMATURE':
                self.armature = obj
                return True
        return False

    def delete_existing_meshes(self):
        """Delete existing mesh objects (keeps armature)"""
        bpy.ops.object.select_all(action='DESELECT')

        for obj in bpy.data.objects:
            if obj.type == 'MESH':
                obj.select_set(True)

        bpy.ops.object.delete()
        print("  Cleared existing meshes")

    def get_bone_midpoint_and_length(self, bone):
        """Calculate the midpoint and length of a bone in world space"""
        head = self.armature.matrix_world @ bone.head_local
        tail = self.armature.matrix_world @ bone.tail_local

        midpoint = (head + tail) / 2
        length = (tail - head).length
        direction = (tail - head).normalized()

        return midpoint, length, direction, head, tail

    def create_limb_cylinder(self, bone_name, radius=0.06):
        """Create a cylinder mesh for a limb bone"""
        bone = self.armature.data.bones[bone_name]
        midpoint, length, direction, head, tail = self.get_bone_midpoint_and_length(bone)

        # Create cylinder
        bpy.ops.mesh.primitive_cylinder_add(
            radius=radius,
            depth=length,
            location=midpoint
        )

        mesh_obj = bpy.context.active_object
        mesh_obj.name = f"{bone_name}_Mesh"

        # Align cylinder to bone direction
        # Calculate rotation to align cylinder (default Z-up) with bone direction
        z_axis = Vector((0, 0, 1))
        rotation_axis = z_axis.cross(direction)
        if rotation_axis.length > 0.0001:
            rotation_angle = z_axis.angle(direction)
            mesh_obj.rotation_mode = 'AXIS_ANGLE'
            mesh_obj.rotation_axis_angle = (rotation_angle, *rotation_axis.normalized())

        self.mesh_parts.append(mesh_obj)
        return mesh_obj

    def create_head_sphere(self):
        """Create sphere mesh for head"""
        bone = self.armature.data.bones["Head"]
        midpoint, length, _, _, _ = self.get_bone_midpoint_and_length(bone)

        # Head is special - use radius instead of length
        radius = length / 2  # Roughly half the head bone length

        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=radius,
            location=midpoint
        )

        mesh_obj = bpy.context.active_object
        mesh_obj.name = "Head_Mesh"
        self.mesh_parts.append(mesh_obj)
        return mesh_obj

    def create_hand_box(self, bone_name):
        """Create box mesh for hand (palm) - positioned at wrist, extending along bone"""
        bone = self.armature.data.bones[bone_name]
        midpoint, length, direction, head, tail = self.get_bone_midpoint_and_length(bone)

        # Palm positioned closer to finger base (tail of hand bone)
        # Position it 70% down the bone to meet fingers better
        palm_center = head + (direction * length * 0.7)

        # Palm dimensions in LOCAL space (before rotation)
        # Z-axis will align with bone direction after rotation
        # Human palm: LONGER than wide, thin thickness
        palm_width = length * 0.7   # Side-to-side (local X) - medium
        palm_depth = length * 0.4   # Front-to-back thickness (local Y) - thinnest
        palm_length = length * 1.0  # Wrist to fingers (local Z) - longest (reduced from 1.1)

        # Create unit cube at origin
        bpy.ops.mesh.primitive_cube_add(location=(0, 0, 0), size=1.0)
        mesh_obj = bpy.context.active_object
        mesh_obj.name = f"{bone_name}_Mesh"

        # Build transformation matrix: Translate * Rotate * Scale
        # 1. Scale matrix (in local space)
        scale_matrix = Matrix.Diagonal((palm_width, palm_depth, palm_length, 1.0))

        # 2. Rotation matrix (align local Z with bone direction, then twist for fingers)
        z_axis = Vector((0, 0, 1))
        rotation_quat = z_axis.rotation_difference(direction)

        # Add twist around bone axis so palm's wide edge catches all fingers
        # Fingers spread in Y direction, so rotate palm around bone axis
        twist_angle = math.radians(75)  # 105 degree twist (slightly more than 90)
        twist_quat = Quaternion(direction, twist_angle)

        # Combine: first align with bone, then twist around it
        final_quat = twist_quat @ rotation_quat
        rotation_matrix = final_quat.to_matrix().to_4x4()

        # 3. Translation matrix
        translation_matrix = Matrix.Translation(palm_center)

        # Combine transformations (apply right-to-left: scale, then rotate, then translate)
        transform_matrix = translation_matrix @ rotation_matrix @ scale_matrix

        # Apply transformation to mesh vertices directly
        mesh = mesh_obj.data
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bm.transform(transform_matrix)
        bm.to_mesh(mesh)
        bm.free()
        mesh.update()

        self.mesh_parts.append(mesh_obj)
        return mesh_obj

    def create_foot_box(self, bone_name):
        """Create box mesh for foot - positioned at ankle, extending along bone"""
        bone = self.armature.data.bones[bone_name]
        midpoint, length, direction, head, tail = self.get_bone_midpoint_and_length(bone)

        # Foot positioned at ankle (head), extending along bone forward
        foot_center = head + (direction * length * 0.6)

        # Foot dimensions in LOCAL space (before rotation)
        # Z-axis will align with bone direction after rotation
        # Human foot: LONGER than wide, thin height
        foot_width = length * 0.55  # Side-to-side (local X) - medium
        foot_height = length * 0.28 # Top-to-bottom thickness (local Y) - thinnest
        foot_length = length * 0.9  # Heel to toe (local Z) - longest

        # Create unit cube at origin
        bpy.ops.mesh.primitive_cube_add(location=(0, 0, 0), size=1.0)
        mesh_obj = bpy.context.active_object
        mesh_obj.name = f"{bone_name}_Mesh"

        # Build transformation matrix: Translate * Rotate * Scale
        # 1. Scale matrix (in local space)
        scale_matrix = Matrix.Diagonal((foot_width, foot_height, foot_length, 1.0))

        # 2. Rotation matrix (align local Z with bone direction)
        z_axis = Vector((0, 0, 1))
        rotation_quat = z_axis.rotation_difference(direction)
        rotation_matrix = rotation_quat.to_matrix().to_4x4()

        # 3. Translation matrix
        translation_matrix = Matrix.Translation(foot_center)

        # Combine transformations (apply right-to-left: scale, then rotate, then translate)
        transform_matrix = translation_matrix @ rotation_matrix @ scale_matrix

        # Apply transformation to mesh vertices directly
        mesh = mesh_obj.data
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bm.transform(transform_matrix)
        bm.to_mesh(mesh)
        bm.free()
        mesh.update()

        self.mesh_parts.append(mesh_obj)
        return mesh_obj

    def create_torso_cone(self):
        """Create cone-shaped torso from spine bones"""
        # Get spine bone positions
        spine1 = self.armature.data.bones["Spine_01"]
        spine3 = self.armature.data.bones["Spine_03"]

        bottom_pos = self.armature.matrix_world @ spine1.head_local
        top_pos = self.armature.matrix_world @ spine3.tail_local

        midpoint = (bottom_pos + top_pos) / 2
        height = (top_pos - bottom_pos).length

        # Create cone (wider at top for shoulders)
        bpy.ops.mesh.primitive_cone_add(
            vertices=8,
            radius1=0.15,  # Bottom (waist)
            radius2=0.25,  # Top (shoulders)
            depth=height,
            location=midpoint
        )

        mesh_obj = bpy.context.active_object
        mesh_obj.name = "Torso_Mesh"

        # Compress front-to-back
        mesh_obj.scale = (1, 0.65, 1)
        bpy.ops.object.transform_apply(scale=True)

        self.mesh_parts.append(mesh_obj)
        return mesh_obj

    def create_pelvis_box(self):
        """Create rounded pelvis/hips mesh - flat front/back, round sides"""
        root = self.armature.data.bones["Root"]
        midpoint, length, _, _, _ = self.get_bone_midpoint_and_length(root)

        # Use UV sphere for organic pelvis shape
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.15,  # Smaller than before (was 0.18)
            location=midpoint
        )

        mesh_obj = bpy.context.active_object
        mesh_obj.name = "Pelvis_Mesh"
        # Scale: wider (X), very flat front/back (Y), shorter height (Z)
        mesh_obj.scale = (1.3, 0.5, 0.55)  # Flatter Y for flat front/back
        bpy.ops.object.transform_apply(scale=True)

        self.mesh_parts.append(mesh_obj)
        return mesh_obj

    def create_finger_mesh(self, bone_name):
        """Create tiny cylinder for finger bones"""
        bone = self.armature.data.bones[bone_name]
        midpoint, length, direction, head, tail = self.get_bone_midpoint_and_length(bone)

        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.01,  # Very thin for fingers
            depth=length,
            location=midpoint
        )

        mesh_obj = bpy.context.active_object
        mesh_obj.name = f"{bone_name}_Mesh"

        # Align to bone
        z_axis = Vector((0, 0, 1))
        rotation_axis = z_axis.cross(direction)
        if rotation_axis.length > 0.0001:
            rotation_angle = z_axis.angle(direction)
            mesh_obj.rotation_mode = 'AXIS_ANGLE'
            mesh_obj.rotation_axis_angle = (rotation_angle, *rotation_axis.normalized())

        self.mesh_parts.append(mesh_obj)
        return mesh_obj

    def generate_all_meshes(self):
        """Generate meshes for all bones"""
        print("\n  Generating meshes:")

        # Head
        print("    - Head")
        self.create_head_sphere()

        # Torso
        print("    - Torso")
        self.create_torso_cone()

        # Pelvis
        print("    - Pelvis")
        self.create_pelvis_box()

        # Arms - both sides
        for side in [".L", ".R"]:
            print(f"    - Arm{side}")
            self.create_limb_cylinder(f"UpperArm{side}", radius=0.06)
            self.create_limb_cylinder(f"ForeArm{side}", radius=0.05)
            self.create_hand_box(f"Hand{side}")

        # Fingers - both sides
        for side in [".L", ".R"]:
            for finger in ["Thumb", "Index", "Middle", "Ring", "Pinky"]:
                for joint in ["01", "02", "03"]:
                    bone_name = f"{finger}_{joint}{side}"
                    if bone_name in self.armature.data.bones:
                        self.create_finger_mesh(bone_name)

        # Legs - both sides
        for side in [".L", ".R"]:
            print(f"    - Leg{side}")
            self.create_limb_cylinder(f"UpperLeg{side}", radius=0.08)
            self.create_limb_cylinder(f"LowerLeg{side}", radius=0.06)
            self.create_foot_box(f"Foot{side}")
            self.create_limb_cylinder(f"Toe{side}", radius=0.04)

        print(f"  ✓ Generated {len(self.mesh_parts)} mesh segments")

    def join_meshes(self):
        """Join all mesh parts into one unified mesh"""
        if not self.mesh_parts:
            return None

        bpy.ops.object.select_all(action='DESELECT')
        for part in self.mesh_parts:
            part.select_set(True)

        bpy.context.view_layer.objects.active = self.mesh_parts[0]
        bpy.ops.object.join()

        unified_mesh = bpy.context.active_object
        unified_mesh.name = "PlayerMesh"

        # Add subdivision for smoother deformation
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.mesh.subdivide(number_cuts=2)
        bpy.ops.object.mode_set(mode='OBJECT')

        return unified_mesh

    def parent_to_armature(self, mesh_obj):
        """Parent mesh to armature with automatic weights"""
        bpy.ops.object.select_all(action='DESELECT')
        mesh_obj.select_set(True)
        self.armature.select_set(True)
        bpy.context.view_layer.objects.active = self.armature

        # Parent with automatic weights
        bpy.ops.object.parent_set(type='ARMATURE_AUTO')
        print("  ✓ Parented mesh to armature with automatic weights")

    def setup_material(self, mesh_obj):
        """Add basic material"""
        mat = bpy.data.materials.new(name="PlayerMaterial")
        mat.use_nodes = True

        bsdf = mat.node_tree.nodes["Principled BSDF"]
        bsdf.inputs['Base Color'].default_value = (0.3, 0.4, 0.5, 1.0)
        bsdf.inputs['Metallic'].default_value = 0.1
        bsdf.inputs['Roughness'].default_value = 0.8

        if mesh_obj.data.materials:
            mesh_obj.data.materials[0] = mat
        else:
            mesh_obj.data.materials.append(mat)

        print("  ✓ Applied material")

    def generate(self):
        """Main generation function"""
        print("\n" + "=" * 80)
        print("KHAOS AUTO MESH FITTER")
        print("=" * 80)

        print("\n1. Finding armature...")
        if not self.find_armature():
            print("  ERROR: No armature found!")
            print("  Run skeleton_generator_clean.py first!")
            return

        print(f"  ✓ Found armature: {self.armature.name}")
        print(f"  Total bones: {len(self.armature.data.bones)}")

        print("\n2. Clearing existing meshes...")
        self.delete_existing_meshes()

        print("\n3. Generating fitted meshes...")
        self.generate_all_meshes()

        print("\n4. Joining mesh parts...")
        unified_mesh = self.join_meshes()

        print("\n5. Setting up material...")
        self.setup_material(unified_mesh)

        print("\n6. Parenting to armature...")
        self.parent_to_armature(unified_mesh)

        print("\n" + "=" * 80)
        print("MESH AUTO-FIT COMPLETE!")
        print("=" * 80)
        print("\nYour skeleton now has fitted meshes!")
        print("\nNext steps:")
        print("1. Test in Pose Mode - meshes should follow bones")
        print("2. Adjust weight painting if needed")
        print("3. Tweak bones? Re-run this script to regenerate meshes!")
        print("4. Export as .glb when satisfied")
        print("=" * 80 + "\n")


def main():
    """Main execution function"""
    fitter = MeshAutoFitter()
    fitter.generate()


# Run the script
if __name__ == "__main__":
    main()
