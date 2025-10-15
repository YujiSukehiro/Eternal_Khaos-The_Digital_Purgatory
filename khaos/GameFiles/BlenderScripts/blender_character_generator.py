"""
Blender Character Generator for Godot - Khaos Project
Creates anatomically correct humanoid armature with 55+ bones
Includes basic mesh and automatic weight painting

USAGE:
1. Open Blender (4.0+ recommended)
2. Open Scripting workspace
3. Create new text file
4. Paste this script
5. Click "Run Script" button (or Alt+P)
6. Character will be generated at origin
7. Export as GLTF: File → Export → glTF 2.0 (.glb)

Export Settings:
- Format: glTF Binary (.glb)
- Include: Selected Objects (select armature + mesh)
- Transform: +Y Up (Godot default)
- Data: Mesh, Materials, Skinning, Shape Keys, Armature
"""

import bpy
import math
from mathutils import Vector, Matrix

# Anatomical proportions (1.8 Godot units = 1.8 Blender units)
CHARACTER_HEIGHT = 1.8
HEAD_RADIUS = 0.125  # Sphere radius (0.25 diameter)
TORSO_HEIGHT = 0.7
ARM_LENGTH = 0.9
LEG_LENGTH = 0.9
HAND_LENGTH = 0.2


class CharacterBuilder:
    """Builds a complete rigged humanoid character for Godot"""

    def __init__(self):
        self.armature = None
        self.bones_dict = {}

    def clear_scene(self):
        """Clear existing objects"""
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.object.delete()

    def create_armature(self):
        """Create the main armature object"""
        bpy.ops.object.armature_add(enter_editmode=False, location=(0, 0, 0))
        self.armature = bpy.context.active_object
        self.armature.name = "PlayerArmature"
        self.armature.show_in_front = True  # X-ray mode for visibility

        # Remove default bone
        bpy.ops.object.mode_set(mode='EDIT')
        edit_bones = self.armature.data.edit_bones
        edit_bones.remove(edit_bones[0])

        return self.armature

    def add_bone(self, name, parent_name=None, head_pos=Vector((0, 0, 0)), tail_pos=Vector((0, 0, 0.1)), roll=0):
        """Add a bone to the armature (must be in EDIT mode)"""
        edit_bones = self.armature.data.edit_bones

        bone = edit_bones.new(name)
        bone.head = head_pos
        bone.tail = tail_pos
        bone.roll = roll

        # Set parent
        if parent_name and parent_name in edit_bones:
            bone.parent = edit_bones[parent_name]
            bone.use_connect = False  # Don't auto-connect to parent tail

        self.bones_dict[name] = bone
        return bone

    def build_spine_chain(self):
        """Build the spine from hips to head"""
        # Root/Hips at character center
        root = self.add_bone(
            "Root",
            head_pos=Vector((0, 0, 0.9)),
            tail_pos=Vector((0, 0, 1.05))
        )

        # Spine segments
        spine1 = self.add_bone(
            "Spine_01",
            parent_name="Root",
            head_pos=Vector((0, 0, 1.05)),
            tail_pos=Vector((0, 0, 1.25))
        )

        spine2 = self.add_bone(
            "Spine_02",
            parent_name="Spine_01",
            head_pos=Vector((0, 0, 1.25)),
            tail_pos=Vector((0, 0, 1.45))
        )

        spine3 = self.add_bone(
            "Spine_03",
            parent_name="Spine_02",
            head_pos=Vector((0, 0, 1.45)),
            tail_pos=Vector((0, 0, 1.65))
        )

        # Neck (very short - natural proportions)
        neck = self.add_bone(
            "Neck",
            parent_name="Spine_03",
            head_pos=Vector((0, 0, 1.65)),
            tail_pos=Vector((0, 0, 1.70))
        )

        # Head
        head = self.add_bone(
            "Head",
            parent_name="Neck",
            head_pos=Vector((0, 0, 1.70)),
            tail_pos=Vector((0, 0, 1.95))
        )

    def build_arm_chain(self, side="L"):
        """Build complete arm with hand and fingers - T-pose with arms pointing DOWN"""
        mirror = -1 if side == "L" else 1

        # Shoulder/Clavicle (at shoulder height)
        shoulder = self.add_bone(
            f"Shoulder.{side}",
            parent_name="Spine_03",
            head_pos=Vector((mirror * 0.1, 0, 1.55)),
            tail_pos=Vector((mirror * 0.25, 0, 1.55))
        )

        # Upper Arm (Humerus) - pointing DOWN
        upper_arm = self.add_bone(
            f"UpperArm.{side}",
            parent_name=f"Shoulder.{side}",
            head_pos=Vector((mirror * 0.25, 0, 1.55)),
            tail_pos=Vector((mirror * 0.25, 0, 1.25))  # Straight down
        )

        # Forearm (Radius/Ulna) - continuing down
        forearm = self.add_bone(
            f"ForeArm.{side}",
            parent_name=f"UpperArm.{side}",
            head_pos=Vector((mirror * 0.25, 0, 1.25)),
            tail_pos=Vector((mirror * 0.25, 0, 0.95))  # Straight down
        )

        # Hand - pointing DOWNWARD at character's side (relaxed pose)
        hand = self.add_bone(
            f"Hand.{side}",
            parent_name=f"ForeArm.{side}",
            head_pos=Vector((mirror * 0.25, 0, 0.95)),
            tail_pos=Vector((mirror * 0.25, 0, 0.85))  # Pointing down in -Z direction
        )

        # Fingers (5 fingers, 3 bones each) - pointing downward from hand
        # Fingers extend downward (-Z direction) with slight spread in X
        self.build_finger(f"Hand.{side}", "Thumb", side,
                         start=Vector((mirror * 0.28, 0, 0.87)),
                         direction=Vector((mirror * 0.02, 0, -0.04)))

        self.build_finger(f"Hand.{side}", "Index", side,
                         start=Vector((mirror * 0.27, 0, 0.85)),
                         direction=Vector((0, 0, -0.045)))

        self.build_finger(f"Hand.{side}", "Middle", side,
                         start=Vector((mirror * 0.25, 0, 0.85)),
                         direction=Vector((0, 0, -0.05)))

        self.build_finger(f"Hand.{side}", "Ring", side,
                         start=Vector((mirror * 0.23, 0, 0.85)),
                         direction=Vector((0, 0, -0.045)))

        self.build_finger(f"Hand.{side}", "Pinky", side,
                         start=Vector((mirror * 0.21, 0, 0.85)),
                         direction=Vector((0, 0, -0.04)))

    def build_finger(self, hand_name, finger_name, side, start, direction):
        """Build a 3-bone finger"""
        # Proximal phalanx (first segment)
        bone1 = self.add_bone(
            f"{finger_name}_01.{side}",
            parent_name=hand_name,
            head_pos=start,
            tail_pos=start + direction
        )

        # Middle phalanx
        bone2 = self.add_bone(
            f"{finger_name}_02.{side}",
            parent_name=f"{finger_name}_01.{side}",
            head_pos=start + direction,
            tail_pos=start + direction * 1.9
        )

        # Distal phalanx (tip)
        bone3 = self.add_bone(
            f"{finger_name}_03.{side}",
            parent_name=f"{finger_name}_02.{side}",
            head_pos=start + direction * 1.9,
            tail_pos=start + direction * 2.7
        )

    def build_leg_chain(self, side="L"):
        """Build complete leg with foot"""
        mirror = -1 if side == "L" else 1

        # Upper Leg (Femur)
        upper_leg = self.add_bone(
            f"UpperLeg.{side}",
            parent_name="Root",
            head_pos=Vector((mirror * 0.15, 0, 0.9)),
            tail_pos=Vector((mirror * 0.15, 0, 0.45))
        )

        # Lower Leg (Tibia/Fibula)
        lower_leg = self.add_bone(
            f"LowerLeg.{side}",
            parent_name=f"UpperLeg.{side}",
            head_pos=Vector((mirror * 0.15, 0, 0.45)),
            tail_pos=Vector((mirror * 0.15, 0, 0.05))
        )

        # Foot
        foot = self.add_bone(
            f"Foot.{side}",
            parent_name=f"LowerLeg.{side}",
            head_pos=Vector((mirror * 0.15, 0, 0.05)),
            tail_pos=Vector((mirror * 0.15, 0.15, 0.0))
        )

        # Toes
        toe = self.add_bone(
            f"Toe.{side}",
            parent_name=f"Foot.{side}",
            head_pos=Vector((mirror * 0.15, 0.15, 0.0)),
            tail_pos=Vector((mirror * 0.15, 0.25, 0.0))
        )

    def build_complete_skeleton(self):
        """Build the entire skeleton"""
        bpy.ops.object.mode_set(mode='EDIT')

        print("Building spine...")
        self.build_spine_chain()

        print("Building left arm...")
        self.build_arm_chain("L")

        print("Building right arm...")
        self.build_arm_chain("R")

        print("Building left leg...")
        self.build_leg_chain("L")

        print("Building right leg...")
        self.build_leg_chain("R")

        bpy.ops.object.mode_set(mode='OBJECT')
        print(f"Skeleton complete! Total bones: {len(self.armature.data.bones)}")

    def create_simple_mesh(self):
        """Create a simple humanoid mesh for testing"""
        # Create base mesh from metaball or basic shapes
        # For now, create a simple subdivided cube shaped like a character

        bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.0))
        mesh_obj = bpy.context.active_object
        mesh_obj.name = "PlayerMesh"

        # Scale to match character proportions
        mesh_obj.scale = (0.4, 0.3, 0.9)
        bpy.ops.object.transform_apply(scale=True)

        # Add subdivision for better deformation
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.mesh.subdivide(number_cuts=4)
        bpy.ops.object.mode_set(mode='OBJECT')

        return mesh_obj

    def create_detailed_mesh(self):
        """Create a more detailed segmented humanoid mesh"""
        mesh_parts = []

        # Head (sphere) - positioned at new head height
        bpy.ops.mesh.primitive_uv_sphere_add(radius=HEAD_RADIUS, location=(0, 0, 1.825))
        head_mesh = bpy.context.active_object
        head_mesh.name = "Head_Mesh"
        mesh_parts.append(head_mesh)

        # Pelvis/Hips (cube at root bone position)
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.9))
        pelvis = bpy.context.active_object
        pelvis.name = "Pelvis_Mesh"
        pelvis.scale = (0.35, 0.25, 0.15)
        bpy.ops.object.transform_apply(scale=True)
        mesh_parts.append(pelvis)

        # Torso (cone for ribcage/heart shape - wider at top, narrower at bottom)
        bpy.ops.mesh.primitive_cone_add(
            vertices=8,
            radius1=0.2,  # Bottom radius (narrow at waist)
            radius2=0.32,  # Top radius (wide at shoulders)
            depth=0.6,
            location=(0, 0, 1.35)  # Raised to connect better to neck
        )
        torso = bpy.context.active_object
        torso.name = "Torso_Mesh"
        # Slight forward/back depth
        torso.scale = (1, 0.65, 1)
        bpy.ops.object.transform_apply(scale=True)
        mesh_parts.append(torso)

        # Upper arms (cylinders) - VERTICAL now to match bones pointing down
        for side in ["L", "R"]:
            mirror = -1 if side == "L" else 1
            bpy.ops.mesh.primitive_cylinder_add(
                radius=0.06,
                depth=0.3,
                location=(mirror * 0.25, 0, 1.4)  # Centered on bone
            )
            arm = bpy.context.active_object
            arm.name = f"UpperArm_{side}_Mesh"
            # No rotation needed - cylinders are already vertical (Z-up)
            mesh_parts.append(arm)

        # Forearms - VERTICAL
        for side in ["L", "R"]:
            mirror = -1 if side == "L" else 1
            bpy.ops.mesh.primitive_cylinder_add(
                radius=0.05,
                depth=0.3,
                location=(mirror * 0.25, 0, 1.1)  # Centered on forearm bone
            )
            forearm = bpy.context.active_object
            forearm.name = f"ForeArm_{side}_Mesh"
            # No rotation needed
            mesh_parts.append(forearm)

        # Hands (boxes) - pointing DOWNWARD at character's sides
        for side in ["L", "R"]:
            mirror = -1 if side == "L" else 1
            bpy.ops.mesh.primitive_cube_add(
                size=0.1,
                location=(mirror * 0.25, 0, 0.90)  # At wrist height
            )
            hand = bpy.context.active_object
            hand.name = f"Hand_{side}_Mesh"
            hand.scale = (0.6, 0.4, 1.0)  # Taller in Z (downward direction)
            bpy.ops.object.transform_apply(scale=True)
            mesh_parts.append(hand)

        # Upper legs
        for side in ["L", "R"]:
            mirror = -1 if side == "L" else 1
            bpy.ops.mesh.primitive_cylinder_add(
                radius=0.08,
                depth=0.45,
                location=(mirror * 0.15, 0, 0.675)
            )
            upper_leg = bpy.context.active_object
            upper_leg.name = f"UpperLeg_{side}_Mesh"
            mesh_parts.append(upper_leg)

        # Lower legs
        for side in ["L", "R"]:
            mirror = -1 if side == "L" else 1
            bpy.ops.mesh.primitive_cylinder_add(
                radius=0.06,
                depth=0.4,
                location=(mirror * 0.15, 0, 0.25)
            )
            lower_leg = bpy.context.active_object
            lower_leg.name = f"LowerLeg_{side}_Mesh"
            mesh_parts.append(lower_leg)

        # Feet
        for side in ["L", "R"]:
            mirror = -1 if side == "L" else 1
            bpy.ops.mesh.primitive_cube_add(
                size=0.1,
                location=(mirror * 0.15, 0.08, 0.025)
            )
            foot = bpy.context.active_object
            foot.name = f"Foot_{side}_Mesh"
            foot.scale = (0.8, 2.5, 0.5)
            bpy.ops.object.transform_apply(scale=True)
            mesh_parts.append(foot)

        # Join all mesh parts
        bpy.ops.object.select_all(action='DESELECT')
        for part in mesh_parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = mesh_parts[0]
        bpy.ops.object.join()

        unified_mesh = bpy.context.active_object
        unified_mesh.name = "PlayerMesh"

        # Add subdivision for smoother deformation
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.mesh.subdivide(number_cuts=2)
        bpy.ops.object.mode_set(mode='OBJECT')

        return unified_mesh

    def parent_mesh_to_armature(self, mesh_obj):
        """Parent mesh to armature with automatic weights"""
        # Select mesh and armature
        bpy.ops.object.select_all(action='DESELECT')
        mesh_obj.select_set(True)
        self.armature.select_set(True)
        bpy.context.view_layer.objects.active = self.armature

        # Parent with automatic weights
        bpy.ops.object.parent_set(type='ARMATURE_AUTO')

        print("Mesh parented to armature with automatic weights!")

    def setup_materials(self, mesh_obj):
        """Add basic material to mesh"""
        mat = bpy.data.materials.new(name="PlayerMaterial")
        mat.use_nodes = True

        # Set base color (bluish grey like the original)
        bsdf = mat.node_tree.nodes["Principled BSDF"]
        bsdf.inputs['Base Color'].default_value = (0.3, 0.4, 0.5, 1.0)
        bsdf.inputs['Metallic'].default_value = 0.1
        bsdf.inputs['Roughness'].default_value = 0.8

        # Assign material
        if mesh_obj.data.materials:
            mesh_obj.data.materials[0] = mat
        else:
            mesh_obj.data.materials.append(mat)


def main():
    """Main execution function"""
    print("=" * 50)
    print("KHAOS CHARACTER GENERATOR")
    print("=" * 50)

    builder = CharacterBuilder()

    print("\n1. Clearing scene...")
    builder.clear_scene()

    print("\n2. Creating armature...")
    builder.create_armature()

    print("\n3. Building skeleton...")
    builder.build_complete_skeleton()

    print("\n4. Creating mesh...")
    mesh = builder.create_detailed_mesh()  # Use create_simple_mesh() for simpler version

    print("\n5. Setting up materials...")
    builder.setup_materials(mesh)

    print("\n6. Parenting mesh to armature...")
    builder.parent_mesh_to_armature(mesh)

    print("\n" + "=" * 50)
    print("CHARACTER GENERATION COMPLETE!")
    print("=" * 50)
    print(f"\nTotal Bones: {len(builder.armature.data.bones)}")
    print("\nNext Steps:")
    print("1. Test the rig: Select armature → Pose Mode → Rotate bones")
    print("2. Adjust weights if needed: Select mesh → Weight Paint mode")
    print("3. Export: File → Export → glTF 2.0 (.glb)")
    print("   - Format: glTF Binary (.glb)")
    print("   - Include: Mesh + Armature + Skinning")
    print("   - Transform: +Y Up")
    print("\n4. Import to Godot: Drag .glb file into project")
    print("=" * 50)


# Run the script
if __name__ == "__main__":
    main()
