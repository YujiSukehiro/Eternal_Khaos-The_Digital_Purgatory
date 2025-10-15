"""
Skeleton Analysis Script for Khaos Project
Extracts bone positions from an existing armature in the scene

USAGE:
1. Open Blender with your character model loaded (Untitled.glb)
2. Make sure the armature is in the scene
3. Open Scripting workspace
4. Load this script
5. Run it (Alt+P)
6. Copy the entire console output
7. Paste it back to Claude for generator script updates

This script reads the ACTUAL bone positions from your manually adjusted skeleton.
"""

import bpy
from mathutils import Vector

def analyze_armature():
    """Analyze the armature in the scene and print all bone data"""

    print("\n" + "=" * 80)
    print("KHAOS SKELETON ANALYSIS")
    print("=" * 80)

    # Find the armature
    armature = None
    for obj in bpy.data.objects:
        if obj.type == 'ARMATURE':
            armature = obj
            break

    if not armature:
        print("ERROR: No armature found in the scene!")
        print("Make sure you have imported your .glb file with the armature.")
        return

    print(f"\nFound armature: {armature.name}")
    print(f"Total bones: {len(armature.data.bones)}")

    # Switch to object mode to read bone data
    bpy.ops.object.mode_set(mode='OBJECT')

    # Group bones by type for easier reading
    bone_groups = {
        'Spine': [],
        'Head': [],
        'Arms_L': [],
        'Arms_R': [],
        'Fingers_L': [],
        'Fingers_R': [],
        'Legs_L': [],
        'Legs_R': [],
        'Other': []
    }

    # Categorize bones
    for bone in armature.data.bones:
        name = bone.name

        if 'Root' in name or 'Spine' in name or 'Neck' in name:
            bone_groups['Spine'].append(bone)
        elif 'Head' in name:
            bone_groups['Head'].append(bone)
        elif ('Shoulder' in name or 'Arm' in name or 'Hand' in name) and '.L' in name:
            bone_groups['Arms_L'].append(bone)
        elif ('Shoulder' in name or 'Arm' in name or 'Hand' in name) and '.R' in name:
            bone_groups['Arms_R'].append(bone)
        elif ('Thumb' in name or 'Index' in name or 'Middle' in name or 'Ring' in name or 'Pinky' in name) and '.L' in name:
            bone_groups['Fingers_L'].append(bone)
        elif ('Thumb' in name or 'Index' in name or 'Middle' in name or 'Ring' in name or 'Pinky' in name) and '.R' in name:
            bone_groups['Fingers_R'].append(bone)
        elif ('Leg' in name or 'Foot' in name or 'Toe' in name) and '.L' in name:
            bone_groups['Legs_L'].append(bone)
        elif ('Leg' in name or 'Foot' in name or 'Toe' in name) and '.R' in name:
            bone_groups['Legs_R'].append(bone)
        else:
            bone_groups['Other'].append(bone)

    # Print bones by group
    print("\n" + "-" * 80)
    print("BONE POSITIONS (World Space)")
    print("-" * 80)

    for group_name, bones in bone_groups.items():
        if not bones:
            continue

        print(f"\n### {group_name} ###")
        for bone in bones:
            # Get world space positions
            head = armature.matrix_world @ bone.head_local
            tail = armature.matrix_world @ bone.tail_local

            print(f"\n  {bone.name}:")
            print(f"    Head: ({head.x:.4f}, {head.y:.4f}, {head.z:.4f})")
            print(f"    Tail: ({tail.x:.4f}, {tail.y:.4f}, {tail.z:.4f})")

            if bone.parent:
                print(f"    Parent: {bone.parent.name}")

    # Print Python code format for easy copy/paste
    print("\n" + "=" * 80)
    print("PYTHON CODE FORMAT (for generator script)")
    print("=" * 80)

    print("\n# Copy these bone definitions into your skeleton generator:")
    print("\ndef build_extracted_skeleton(self):")
    print("    \"\"\"Build skeleton from extracted bone data\"\"\"")

    for group_name, bones in bone_groups.items():
        if not bones:
            continue

        print(f"\n    # {group_name}")
        for bone in bones:
            head = armature.matrix_world @ bone.head_local
            tail = armature.matrix_world @ bone.tail_local
            parent = f'"{bone.parent.name}"' if bone.parent else 'None'

            print(f"    self.add_bone(")
            print(f"        \"{bone.name}\",")
            print(f"        parent_name={parent},")
            print(f"        head_pos=Vector(({head.x:.4f}, {head.y:.4f}, {head.z:.4f})),")
            print(f"        tail_pos=Vector(({tail.x:.4f}, {tail.y:.4f}, {tail.z:.4f}))")
            print(f"    )")

    print("\n" + "=" * 80)
    print("ANALYSIS COMPLETE!")
    print("=" * 80)
    print("\nNext steps:")
    print("1. Copy the PYTHON CODE FORMAT section above")
    print("2. Paste it to Claude")
    print("3. Claude will update the generator script with these exact positions")
    print("=" * 80 + "\n")


# Run the analysis
if __name__ == "__main__":
    analyze_armature()
