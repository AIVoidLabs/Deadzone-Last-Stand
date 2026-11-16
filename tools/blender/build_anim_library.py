"""Quaternius Universal Animation Library -> oyun iskeleti (25 kemik) + seçilen klipler.

Çalıştırma (repo kökünden, Blender penceresi açılmaz):
    blender --background --python tools/blender/build_anim_library.py

Girdi  : assets/models/source/animations/UAL1|UAL2/... (ham paketler, git'e girmez)
Çıktı  : assets/models/anim/ual1.glb, ual2.glb   -> Godot'da AnimationLibrary
         assets/models/characters/mannequin.glb  -> deneme mankeni (klipsiz)
         build/blender/ual1.blend, ual2.blend    -> Blender'da elle bakmak için (git'e girmez)
"""

import os
import sys

import bpy

REPO: str = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SOURCE_DIR: str = os.path.join(REPO, "assets", "models", "source", "animations")
ANIM_DIR: str = os.path.join(REPO, "assets", "models", "anim")
CHARACTER_DIR: str = os.path.join(REPO, "assets", "models", "characters")
BLEND_DIR: str = os.path.join(REPO, "build", "blender")

# Kök hareketsiz dosyalar kullanılır; oyun hareketi kodla yürütür.
PACKS: dict = {
    "ual1": {
        "path": os.path.join("UAL1", "Universal Animation Library[Standard]", "Unreal-Godot", "UAL1_Standard.glb"),
        "clips": [
            "Idle_Loop", "Walk_Loop", "Jog_Fwd_Loop", "Sprint_Loop", "Roll",
            "Hit_Chest", "Hit_Head", "Death01",
            "Crouch_Idle_Loop", "Crouch_Fwd_Loop", "Punch_Cross", "Punch_Jab", "Push_Loop",
        ],
    },
    "ual2": {
        "path": os.path.join("UAL2", "Universal Animation Library 2[Standard]", "Unreal-Godot", "UAL2_Standard.glb"),
        "clips": [
            "Zombie_Idle_Loop", "Zombie_Walk_Fwd_Loop", "Zombie_Scratch",
            "Hit_Knockback", "LayToIdle", "Melee_Hook", "Melee_Hook_Rec",
            "Slide_Start", "Slide_Loop", "Slide_Exit", "Shield_Dash", "OverhandThrow",
        ],
    },
}

# Oyun iskeletinde olmayan kemikler: parmaklar. Ağırlıkları ele aktarılır.
FINGER_PREFIXES: tuple = ("index_", "middle_", "pinky_", "ring_", "thumb_")
MANNEQUIN_TARGET_TRIS: int = 2500


def log(message: str) -> None:
    print("[build_anim_library] " + message)
    sys.stdout.flush()


def is_finger(bone_name: str) -> bool:
    return bone_name.startswith(FINGER_PREFIXES)


def load_pack(relative_path: str) -> tuple:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    full_path: str = os.path.join(SOURCE_DIR, relative_path)
    if not os.path.isfile(full_path):
        raise FileNotFoundError("Ham paket yok: " + full_path)
    bpy.ops.import_scene.gltf(filepath=full_path)
    armature = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    meshes: list = [o for o in bpy.data.objects if o.type == "MESH"]
    return armature, meshes


def keep_clips(armature, clips: list) -> None:
    """Listede olmayan klipleri NLA'dan ve dosyadan çıkarır."""
    wanted: set = set(clips)
    found: set = set()
    anim = armature.animation_data
    anim.action = None
    for track in list(anim.nla_tracks):
        names: set = {s.action.name for s in track.strips if s.action is not None}
        if names & wanted:
            found |= names & wanted
        else:
            anim.nla_tracks.remove(track)
    for action in list(bpy.data.actions):
        if action.name not in wanted:
            bpy.data.actions.remove(action)
    missing: set = wanted - found
    if missing:
        raise RuntimeError("Pakette bulunamayan klipler: " + ", ".join(sorted(missing)))


def drop_all_clips(armature) -> None:
    anim = armature.animation_data
    if anim is not None:
        anim.action = None
        for track in list(anim.nla_tracks):
            anim.nla_tracks.remove(track)
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)


def merge_finger_weights(mesh) -> None:
    """Parmak ağırlıklarını aynı taraftaki el kemiğine ekler, parmak gruplarını siler."""
    groups = mesh.vertex_groups
    for side in ("_l", "_r"):
        hand = groups.get("hand" + side)
        fingers: dict = {g.index: g for g in groups if is_finger(g.name) and g.name.endswith(side)}
        if hand is None or not fingers:
            continue
        for vertex in mesh.data.vertices:
            extra: float = sum(e.weight for e in vertex.groups if e.group in fingers)
            if extra > 0.0:
                hand.add([vertex.index], extra, "ADD")
    for group in [g for g in groups if is_finger(g.name)]:
        groups.remove(group)


def strip_finger_bones(armature) -> int:
    bpy.ops.object.select_all(action="DESELECT")
    armature.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.mode_set(mode="EDIT")
    edit_bones = armature.data.edit_bones
    for bone in [b for b in edit_bones if is_finger(b.name)]:
        edit_bones.remove(bone)
    bpy.ops.object.mode_set(mode="OBJECT")
    return len(armature.data.bones)


def decimate(mesh, target_tris: int) -> int:
    mesh.data.calc_loop_triangles()
    current: int = len(mesh.data.loop_triangles)
    if current > target_tris:
        modifier = mesh.modifiers.new("Decimate", "DECIMATE")
        modifier.ratio = target_tris / current
        bpy.ops.object.select_all(action="DESELECT")
        mesh.select_set(True)
        bpy.context.view_layer.objects.active = mesh
        bpy.ops.object.modifier_move_to_index(modifier=modifier.name, index=0)
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    mesh.data.calc_loop_triangles()
    return len(mesh.data.loop_triangles)


def export_glb(path: str, with_animations: bool) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_animations=with_animations,
        export_animation_mode="ACTIONS",
        export_skins=True,
        export_yup=True,
    )
    log("yazıldı: %s (%.0f KB)" % (os.path.relpath(path, REPO), os.path.getsize(path) / 1024.0))


def save_blend(name: str) -> None:
    """İnceleme kopyası: Blender'da File > Open ile açılır, klipler Action listesinde."""
    os.makedirs(BLEND_DIR, exist_ok=True)
    path: str = os.path.join(BLEND_DIR, name + ".blend")
    bpy.ops.wm.save_as_mainfile(filepath=path)
    log("yazıldı: " + os.path.relpath(path, REPO))


def prepare(pack: dict) -> tuple:
    armature, meshes = load_pack(pack["path"])
    for mesh in meshes:
        merge_finger_weights(mesh)
    bones: int = strip_finger_bones(armature)
    tris: int = sum(decimate(mesh, MANNEQUIN_TARGET_TRIS) for mesh in meshes)
    log("iskelet %d kemik, manken %d üçgen" % (bones, tris))
    return armature, meshes


def main() -> None:
    for name, pack in PACKS.items():
        armature, _meshes = prepare(pack)
        keep_clips(armature, pack["clips"])
        export_glb(os.path.join(ANIM_DIR, name + ".glb"), True)
        save_blend(name)
    armature, _meshes = prepare(PACKS["ual1"])
    drop_all_clips(armature)
    export_glb(os.path.join(CHARACTER_DIR, "mannequin.glb"), False)
    log("bitti")


main()
