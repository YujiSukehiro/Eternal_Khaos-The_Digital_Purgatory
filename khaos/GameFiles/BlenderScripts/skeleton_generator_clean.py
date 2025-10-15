"""
Clean Skeleton Generator for Khaos Project
Generates ONLY the armature/bones based on extracted data from your custom skeleton

USAGE:
1. Open Blender (4.0+ recommended)
2. Open Scripting workspace
3. Load this script
4. Click "Run Script" button (or Alt+P)
5. Skeleton will be generated at origin
6. NO MESH - bones only for fast iteration

This uses your exact bone positions from the manual adjustments you made.
"""

import bpy
from mathutils import Vector

class SkeletonGenerator:
    """Generates skeleton with exact bone positions"""

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

    def build_extracted_skeleton(self):
        """Build skeleton from extracted bone data"""

        # Spine
        self.add_bone(
            "Root",
            parent_name=None,
            head_pos=Vector((0.0000, 0.0000, 0.9000)),
            tail_pos=Vector((0.0000, 0.0000, 1.0500))
        )
        self.add_bone(
            "Spine_01",
            parent_name="Root",
            head_pos=Vector((0.0000, 0.0000, 1.0500)),
            tail_pos=Vector((0.0000, 0.0000, 1.2500))
        )
        self.add_bone(
            "Spine_02",
            parent_name="Spine_01",
            head_pos=Vector((0.0000, 0.0000, 1.2500)),
            tail_pos=Vector((0.0000, 0.0000, 1.4500))
        )
        self.add_bone(
            "Spine_03",
            parent_name="Spine_02",
            head_pos=Vector((0.0000, 0.0000, 1.4500)),
            tail_pos=Vector((0.0000, 0.0000, 1.6500))
        )
        self.add_bone(
            "Neck",
            parent_name="Spine_03",
            head_pos=Vector((0.0000, 0.0000, 1.6500)),
            tail_pos=Vector((0.0000, 0.0000, 1.7000))
        )

        # Head
        self.add_bone(
            "Head",
            parent_name="Neck",
            head_pos=Vector((0.0000, 0.0000, 1.7000)),
            tail_pos=Vector((0.0000, 0.0000, 1.9500))
        )

        # Arms_L
        self.add_bone(
            "Shoulder.L",
            parent_name="Spine_03",
            head_pos=Vector((-0.1000, 0.0000, 1.6132)),
            tail_pos=Vector((-0.2541, 0.0072, 1.6121))
        )
        self.add_bone(
            "UpperArm.L",
            parent_name="Shoulder.L",
            head_pos=Vector((-0.2541, 0.0072, 1.6121)),
            tail_pos=Vector((-0.2693, 0.0041, 1.3125))
        )
        self.add_bone(
            "ForeArm.L",
            parent_name="UpperArm.L",
            head_pos=Vector((-0.2693, 0.0041, 1.3125)),
            tail_pos=Vector((-0.2870, -0.0024, 1.0131))
        )
        self.add_bone(
            "Hand.L",
            parent_name="ForeArm.L",
            head_pos=Vector((-0.2870, -0.0024, 1.0131)),
            tail_pos=Vector((-0.2921, -0.0034, 0.9132))
        )

        # Arms_R
        self.add_bone(
            "Shoulder.R",
            parent_name="Spine_03",
            head_pos=Vector((0.1000, 0.0000, 1.6132)),
            tail_pos=Vector((0.2579, 0.0109, 1.6095))
        )
        self.add_bone(
            "UpperArm.R",
            parent_name="Shoulder.R",
            head_pos=Vector((0.2585, 0.0084, 1.6096)),
            tail_pos=Vector((0.2895, 0.0034, 1.3112))
        )
        self.add_bone(
            "ForeArm.R",
            parent_name="UpperArm.R",
            head_pos=Vector((0.2895, 0.0034, 1.3112)),
            tail_pos=Vector((0.3206, -0.0017, 1.0129))
        )
        self.add_bone(
            "Hand.R",
            parent_name="ForeArm.R",
            head_pos=Vector((0.3206, -0.0017, 1.0129)),
            tail_pos=Vector((0.3310, -0.0034, 0.9134))
        )

        # Fingers_L
        self.add_bone(
            "Thumb_01.L",
            parent_name="Hand.L",
            head_pos=Vector((-0.2982, 0.0259, 0.9333)),
            tail_pos=Vector((-0.3050, 0.0449, 0.8934))
        )
        self.add_bone(
            "Thumb_02.L",
            parent_name="Thumb_01.L",
            head_pos=Vector((-0.3050, 0.0449, 0.8934)),
            tail_pos=Vector((-0.3111, 0.0620, 0.8575))
        )
        self.add_bone(
            "Thumb_03.L",
            parent_name="Thumb_02.L",
            head_pos=Vector((-0.3111, 0.0620, 0.8575)),
            tail_pos=Vector((-0.3166, 0.0772, 0.8255))
        )
        self.add_bone(
            "Index_01.L",
            parent_name="Hand.L",
            head_pos=Vector((-0.2968, 0.0160, 0.9133)),
            tail_pos=Vector((-0.2991, 0.0155, 0.8683))
        )
        self.add_bone(
            "Index_02.L",
            parent_name="Index_01.L",
            head_pos=Vector((-0.2991, 0.0155, 0.8683)),
            tail_pos=Vector((-0.3012, 0.0151, 0.8279))
        )
        self.add_bone(
            "Index_03.L",
            parent_name="Index_02.L",
            head_pos=Vector((-0.3012, 0.0151, 0.8279)),
            tail_pos=Vector((-0.3030, 0.0147, 0.7919))
        )
        self.add_bone(
            "Middle_01.L",
            parent_name="Hand.L",
            head_pos=Vector((-0.2921, -0.0034, 0.9132)),
            tail_pos=Vector((-0.2946, -0.0039, 0.8633))
        )
        self.add_bone(
            "Middle_02.L",
            parent_name="Middle_01.L",
            head_pos=Vector((-0.2946, -0.0039, 0.8633)),
            tail_pos=Vector((-0.2969, -0.0044, 0.8184))
        )
        self.add_bone(
            "Middle_03.L",
            parent_name="Middle_02.L",
            head_pos=Vector((-0.2969, -0.0044, 0.8184)),
            tail_pos=Vector((-0.2989, -0.0048, 0.7784))
        )
        self.add_bone(
            "Ring_01.L",
            parent_name="Hand.L",
            head_pos=Vector((-0.2873, -0.0229, 0.9132)),
            tail_pos=Vector((-0.2896, -0.0233, 0.8683))
        )
        self.add_bone(
            "Ring_02.L",
            parent_name="Ring_01.L",
            head_pos=Vector((-0.2896, -0.0233, 0.8683)),
            tail_pos=Vector((-0.2916, -0.0237, 0.8278))
        )
        self.add_bone(
            "Ring_03.L",
            parent_name="Ring_02.L",
            head_pos=Vector((-0.2916, -0.0237, 0.8278)),
            tail_pos=Vector((-0.2934, -0.0241, 0.7919))
        )
        self.add_bone(
            "Pinky_01.L",
            parent_name="Hand.L",
            head_pos=Vector((-0.2825, -0.0423, 0.9132)),
            tail_pos=Vector((-0.2845, -0.0427, 0.8732))
        )
        self.add_bone(
            "Pinky_02.L",
            parent_name="Pinky_01.L",
            head_pos=Vector((-0.2845, -0.0427, 0.8732)),
            tail_pos=Vector((-0.2864, -0.0431, 0.8373))
        )
        self.add_bone(
            "Pinky_03.L",
            parent_name="Pinky_02.L",
            head_pos=Vector((-0.2864, -0.0431, 0.8373)),
            tail_pos=Vector((-0.2880, -0.0434, 0.8053))
        )

        # Fingers_R
        self.add_bone(
            "Thumb_01.R",
            parent_name="Hand.R",
            head_pos=Vector((0.3223, 0.0270, 0.9321)),
            tail_pos=Vector((0.3221, 0.0463, 0.8915))
        )
        self.add_bone(
            "Thumb_02.R",
            parent_name="Thumb_01.R",
            head_pos=Vector((0.3221, 0.0463, 0.8915)),
            tail_pos=Vector((0.3219, 0.0637, 0.8550))
        )
        self.add_bone(
            "Thumb_03.R",
            parent_name="Thumb_02.R",
            head_pos=Vector((0.3219, 0.0637, 0.8550)),
            tail_pos=Vector((0.3217, 0.0792, 0.8225))
        )
        self.add_bone(
            "Index_01.R",
            parent_name="Hand.R",
            head_pos=Vector((0.3266, 0.0166, 0.9126)),
            tail_pos=Vector((0.3313, 0.0159, 0.8679))
        )
        self.add_bone(
            "Index_02.R",
            parent_name="Index_01.R",
            head_pos=Vector((0.3313, 0.0159, 0.8679)),
            tail_pos=Vector((0.3355, 0.0152, 0.8276))
        )
        self.add_bone(
            "Index_03.R",
            parent_name="Index_02.R",
            head_pos=Vector((0.3355, 0.0152, 0.8276)),
            tail_pos=Vector((0.3377, 0.0139, 0.7916))
        )
        self.add_bone(
            "Middle_01.R",
            parent_name="Hand.R",
            head_pos=Vector((0.3310, -0.0034, 0.9134)),
            tail_pos=Vector((0.3362, -0.0042, 0.8637))
        )
        self.add_bone(
            "Middle_02.R",
            parent_name="Middle_01.R",
            head_pos=Vector((0.3362, -0.0042, 0.8637)),
            tail_pos=Vector((0.3408, -0.0050, 0.8189))
        )
        self.add_bone(
            "Middle_03.R",
            parent_name="Middle_02.R",
            head_pos=Vector((0.3408, -0.0050, 0.8189)),
            tail_pos=Vector((0.3450, -0.0056, 0.7792))
        )
        self.add_bone(
            "Ring_01.R",
            parent_name="Hand.R",
            head_pos=Vector((0.3354, -0.0234, 0.9142)),
            tail_pos=Vector((0.3400, -0.0241, 0.8695))
        )
        self.add_bone(
            "Ring_02.R",
            parent_name="Ring_01.R",
            head_pos=Vector((0.3400, -0.0241, 0.8695)),
            tail_pos=Vector((0.3442, -0.0248, 0.8292))
        )
        self.add_bone(
            "Ring_03.R",
            parent_name="Ring_02.R",
            head_pos=Vector((0.3442, -0.0248, 0.8292)),
            tail_pos=Vector((0.3480, -0.0254, 0.7934))
        )
        self.add_bone(
            "Pinky_01.R",
            parent_name="Hand.R",
            head_pos=Vector((0.3398, -0.0434, 0.9150)),
            tail_pos=Vector((0.3439, -0.0441, 0.8752))
        )
        self.add_bone(
            "Pinky_02.R",
            parent_name="Pinky_01.R",
            head_pos=Vector((0.3439, -0.0441, 0.8752)),
            tail_pos=Vector((0.3515, -0.0428, 0.8398))
        )
        self.add_bone(
            "Pinky_03.R",
            parent_name="Pinky_02.R",
            head_pos=Vector((0.3476, -0.0447, 0.8394)),
            tail_pos=Vector((0.3510, -0.0452, 0.8076))
        )

        # Legs_L
        self.add_bone(
            "UpperLeg.L",
            parent_name="Root",
            head_pos=Vector((-0.1500, 0.0000, 0.9000)),
            tail_pos=Vector((-0.1500, 0.0000, 0.4500))
        )
        self.add_bone(
            "LowerLeg.L",
            parent_name="UpperLeg.L",
            head_pos=Vector((-0.1500, 0.0000, 0.4500)),
            tail_pos=Vector((-0.1500, 0.0000, 0.0500))
        )
        self.add_bone(
            "Foot.L",
            parent_name="LowerLeg.L",
            head_pos=Vector((-0.1500, 0.0000, 0.0500)),
            tail_pos=Vector((-0.1500, 0.1500, 0.0000))
        )
        self.add_bone(
            "Toe.L",
            parent_name="Foot.L",
            head_pos=Vector((-0.1500, 0.1500, 0.0000)),
            tail_pos=Vector((-0.1500, 0.2500, 0.0000))
        )

        # Legs_R
        self.add_bone(
            "UpperLeg.R",
            parent_name="Root",
            head_pos=Vector((0.1500, 0.0000, 0.9000)),
            tail_pos=Vector((0.1500, 0.0000, 0.4500))
        )
        self.add_bone(
            "LowerLeg.R",
            parent_name="UpperLeg.R",
            head_pos=Vector((0.1500, 0.0000, 0.4500)),
            tail_pos=Vector((0.1500, 0.0000, 0.0500))
        )
        self.add_bone(
            "Foot.R",
            parent_name="LowerLeg.R",
            head_pos=Vector((0.1500, 0.0000, 0.0500)),
            tail_pos=Vector((0.1500, 0.1500, 0.0000))
        )
        self.add_bone(
            "Toe.R",
            parent_name="Foot.R",
            head_pos=Vector((0.1500, 0.1500, 0.0000)),
            tail_pos=Vector((0.1500, 0.2500, 0.0000))
        )

    def generate(self):
        """Main generation function"""
        print("\n" + "=" * 80)
        print("KHAOS CLEAN SKELETON GENERATOR")
        print("=" * 80)

        print("\n1. Clearing scene...")
        self.clear_scene()

        print("\n2. Creating armature...")
        self.create_armature()

        print("\n3. Building skeleton from extracted data...")
        bpy.ops.object.mode_set(mode='EDIT')
        self.build_extracted_skeleton()
        bpy.ops.object.mode_set(mode='OBJECT')

        print(f"\n✓ Skeleton complete! Total bones: {len(self.armature.data.bones)}")

        print("\n" + "=" * 80)
        print("SKELETON GENERATION COMPLETE!")
        print("=" * 80)
        print("\nNext steps:")
        print("1. Adjust bones if needed in Edit Mode")
        print("2. Run mesh_auto_fit.py to generate meshes")
        print("3. Export as .glb when satisfied")
        print("=" * 80 + "\n")


def main():
    """Main execution function"""
    generator = SkeletonGenerator()
    generator.generate()


# Run the script
if __name__ == "__main__":
    main()
