"""Tripo asker modeli -> temiz, 25 kemikli ortak iskelete bağlı oyun modeli.

Çalıştırma (repo kökünden, Blender penceresi açılmaz):
    blender --background --python tools/blender/build_soldier.py

Girdi : assets/models/source/soldier/armored-soldier-3d-model.glb (ham Tripo, git'e girmez)
        assets/models/characters/mannequin.glb (iskelet ve dinlenme pozu kaynağı)
Çıktı : assets/models/characters/soldier.glb
        build/blender/soldier.blend, build/shots/soldier_fit_*.png (eklem yerleşimi kontrolü)

Adımlar: ölçekle -> sadeleştir -> iskeleti eklem noktalarına oturt -> ağırlıkla ->
modeli kütüphanenin dinlenme pozuna (A-poz) getir -> dışa aktar.
"""

import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

REPO: str = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SOURCE: str = os.path.join(REPO, "assets", "models", "source", "soldier", "armored-soldier-3d-model.glb")
SKELETON_SOURCE: str = os.path.join(REPO, "assets", "models", "characters", "mannequin.glb")
OUTPUT: str = os.path.join(REPO, "assets", "models", "characters", "soldier.glb")
BLEND_OUTPUT: str = os.path.join(REPO, "build", "blender", "soldier.blend")
CHECK_PREFIX: str = os.path.join(REPO, "build", "shots", "soldier_fit")

TARGET_HEIGHT: float = 1.83
TARGET_TRIS: int = 6000
TEXTURE_SIZE: int = 1024
MERGE_DISTANCE: float = 0.00001
SMOOTH_ANGLE_DEG: float = 35.0

# Eklem noktaları: ham modelin boyuna oranla (x: sola +, y: öne -, z: yukarı).
# Sol taraf yazılır; sağ taraf x işareti çevrilerek türetilir.
RAW_HEIGHT: float = 0.89
CENTER_JOINTS: dict = {
    "root": (0.0, 0.0, 0.0),
    "pelvis": (0.0, 0.0, 0.47),
    "spine_01": (0.0, 0.0, 0.51),
    "spine_02": (0.0, 0.0, 0.57),
    "spine_03": (0.0, 0.0, 0.63),
    "neck_01": (0.0, 0.0, 0.735),
    "Head": (0.0, 0.0, 0.775),
}
SIDE_JOINTS: dict = {
    "clavicle": (0.03, 0.0, 0.70),
    "upperarm": (0.15, 0.0, 0.69),
    "lowerarm": (0.31, -0.02, 0.635),
    "hand": (0.405, -0.04, 0.60),
    "thigh": (0.085, 0.0, 0.44),
    "calf": (0.13, -0.01, 0.255),
    "foot": (0.17, 0.0, 0.07),
    "ball": (0.175, -0.09, 0.02),
    "ball_leaf": (0.175, -0.13, 0.02),
}
# Yönü çocuğuna bakacak şekilde kurulan kemikler (uzuvlar). Diğerleri kaynak yönünü korur.
AIMED: dict = {"upperarm": "lowerarm", "lowerarm": "hand", "thigh": "calf", "calf": "foot"}
# Ağırlık almayan kemikler.
NO_DEFORM: tuple = ("root", "ball_leaf_l", "ball_leaf_r")
HEAD_BONE_LENGTH: float = 0.2


def log(message: str) -> None:
    print("[build_soldier] " + message)
    sys.stdout.flush()


def activate(obj) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def apply_transforms(obj) -> None:
    activate(obj)
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def import_glb(path: str) -> list:
    before: set = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    return [o for o in bpy.data.objects if o not in before]


def mesh_bounds(mesh) -> tuple:
    points: list = [mesh.matrix_world @ v.co for v in mesh.data.vertices]
    low: Vector = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    high: Vector = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return low, high


def load_soldier_mesh():
    imported: list = import_glb(SOURCE)
    meshes: list = [o for o in imported if o.type == "MESH"]
    for mesh in meshes:
        apply_transforms(mesh)
    for other in [o for o in imported if o.type != "MESH"]:
        bpy.data.objects.remove(other)
    mesh = meshes[0]
    if len(meshes) > 1:
        activate(mesh)
        for other in meshes[1:]:
            other.select_set(True)
        bpy.ops.object.join()
    mesh.name = "Soldier"
    low, high = mesh_bounds(mesh)
    factor: float = TARGET_HEIGHT / (high.z - low.z)
    mesh.location = Vector((-(low.x + high.x) * 0.5, -(low.y + high.y) * 0.5, -low.z)) * factor
    mesh.scale = Vector((factor, factor, factor))
    apply_transforms(mesh)
    return mesh


def simplify(mesh) -> None:
    data = bmesh.new()
    data.from_mesh(mesh.data)
    bmesh.ops.remove_doubles(data, verts=data.verts, dist=MERGE_DISTANCE)
    data.to_mesh(mesh.data)
    data.free()
    mesh.data.calc_loop_triangles()
    before: int = len(mesh.data.loop_triangles)
    activate(mesh)
    modifier = mesh.modifiers.new("Decimate", "DECIMATE")
    modifier.ratio = min(1.0, TARGET_TRIS / before)
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    try:
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(SMOOTH_ANGLE_DEG))
    except (AttributeError, RuntimeError):
        bpy.ops.object.shade_flat()
    mesh.data.calc_loop_triangles()
    log("üçgen: %d -> %d" % (before, len(mesh.data.loop_triangles)))


def upstream_image_node(socket):
    """Soketi besleyen ilk doku düğümü (araya giren karışım düğümlerini atlar)."""
    pending: list = [link.from_node for link in socket.links]
    while pending:
        node = pending.pop(0)
        if node.type == "TEX_IMAGE":
            return node
        for node_input in node.inputs:
            pending.extend(link.from_node for link in node_input.links)
    return None


def simplify_material(mesh) -> None:
    """Yalnız renk dokusu kalır (küçültülmüş); normal ve pürüz haritaları atılır."""
    for material in [m for m in mesh.data.materials if m is not None and m.node_tree is not None]:
        tree = material.node_tree
        shader = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
        output = next(n for n in tree.nodes if n.type == "OUTPUT_MATERIAL")
        color_node = upstream_image_node(shader.inputs["Base Color"])
        for node in [n for n in tree.nodes if n not in (shader, output, color_node)]:
            tree.nodes.remove(node)
        shader.inputs["Roughness"].default_value = 0.8
        shader.inputs["Metallic"].default_value = 0.0
        if color_node is None:
            raise RuntimeError("Renk dokusu bulunamadı: " + material.name)
        tree.links.new(color_node.outputs["Color"], shader.inputs["Base Color"])
        color_node.image.scale(TEXTURE_SIZE, TEXTURE_SIZE)
        # PNG: Godot, Blender'ın yazdığı JPEG'i çözemiyor (içe aktarımda doku boş kalıyor).
        color_node.image.file_format = "PNG"
        color_node.image.name = "albedo"
        color_node.image.pack()
        material.name = "SoldierMaterial"


def load_skeleton():
    imported: list = import_glb(SKELETON_SOURCE)
    armature = next(o for o in imported if o.type == "ARMATURE")
    apply_transforms(armature)
    for other in [o for o in imported if o != armature]:
        bpy.data.objects.remove(other)
    armature.name = "Armature"
    return armature


def joint_table(left_sign: float) -> dict:
    scale: float = TARGET_HEIGHT / RAW_HEIGHT
    joints: dict = {name: Vector(p) * scale for name, p in CENTER_JOINTS.items()}
    for name, p in SIDE_JOINTS.items():
        joints[name + "_l"] = Vector((p[0] * left_sign, p[1], p[2])) * scale
        joints[name + "_r"] = Vector((-p[0] * left_sign, p[1], p[2])) * scale
    return joints


def fit_skeleton(armature) -> dict:
    """Kemikleri askerin eklemlerine taşır. Dönüş: kaynak (kütüphane) kemik yönleri."""
    reference: dict = {b.name: b.matrix_local.to_3x3() for b in armature.data.bones}
    left_sign: float = 1.0 if armature.data.bones["upperarm_l"].head_local.x > 0.0 else -1.0
    joints: dict = joint_table(left_sign)
    activate(armature)
    bpy.ops.object.mode_set(mode="EDIT")
    edit_bones = armature.data.edit_bones
    for bone in edit_bones:
        bone.use_connect = False
    for bone in edit_bones:
        head: Vector = joints[bone.name]
        rotation: Matrix = reference[bone.name].copy()
        length: float = bone.length
        part, _, side = bone.name.rpartition("_")
        if part in AIMED:
            direction: Vector = joints["%s_%s" % (AIMED[part], side)] - head
            length = direction.length
            source_axis: Vector = rotation @ Vector((0.0, 1.0, 0.0))
            rotation = source_axis.rotation_difference(direction.normalized()).to_matrix() @ rotation
        elif bone.name == "Head":
            length = HEAD_BONE_LENGTH
        bone.matrix = Matrix.Translation(head) @ rotation.to_4x4()
        bone.length = length
    bpy.ops.object.mode_set(mode="OBJECT")
    for name in NO_DEFORM:
        armature.data.bones[name].use_deform = False
    return reference


def bind(mesh, armature) -> None:
    activate(mesh)
    armature.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    unweighted: int = sum(1 for v in mesh.data.vertices if not v.groups)
    log("ağırlıksız köşe: %d / %d" % (unweighted, len(mesh.data.vertices)))
    if unweighted > len(mesh.data.vertices) // 100:
        raise RuntimeError("Otomatik ağırlık başarısız; model kapalı/tek parça olmayabilir.")


def match_rest_pose(mesh, armature, reference: dict) -> None:
    """Kemikleri kütüphanenin dinlenme yönlerine çevirir ve bunu yeni dinlenme pozu yapar."""
    activate(armature)
    bpy.ops.object.mode_set(mode="POSE")
    ordered: list = sorted(armature.pose.bones, key=lambda b: len(b.parent_recursive))
    for pose_bone in ordered:
        pose_bone.matrix = Matrix.Translation(pose_bone.matrix.to_translation()) @ reference[pose_bone.name].to_4x4()
        bpy.context.view_layer.update()
    bpy.ops.object.mode_set(mode="OBJECT")
    activate(mesh)
    modifier = next(m for m in mesh.modifiers if m.type == "ARMATURE")
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    activate(armature)
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.armature_apply(selected=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    mesh.modifiers.new("Armature", "ARMATURE").object = armature


def ground(mesh, armature) -> None:
    """Poz değişince ayaklar yerden ayrılabilir; tabanı yeniden z=0'a oturtur."""
    low, high = mesh_bounds(mesh)
    for obj in (armature, mesh):
        obj.location.z -= low.z
    bpy.context.view_layer.update()
    activate(armature)
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
    activate(mesh)
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
    log("boy: %.3f m (taban düzeltmesi %.3f)" % (high.z - low.z, -low.z))


def render_check(mesh, armature, suffix: str) -> None:
    """Eklemleri kırmızı küre olarak, modeli yarı saydam çizer."""
    scene = bpy.context.scene
    markers: list = []
    for bone in armature.data.bones:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.03, location=armature.matrix_world @ bone.head_local, segments=8, ring_count=6)
        marker = bpy.context.active_object
        marker.color = (1.0, 0.1, 0.1, 1.0)
        markers.append(marker)
    mesh.color = (0.6, 0.7, 0.9, 1.0)
    for engine in ("BLENDER_WORKBENCH", "BLENDER_WORKBENCH_NEXT"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    scene.render.resolution_x, scene.render.resolution_y = 800, 800
    scene.display.shading.color_type = "OBJECT"
    scene.display.shading.show_xray = True
    scene.display.shading.xray_alpha = 0.35
    camera_data = bpy.data.cameras.new("CheckCamera")
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 2.4
    camera = bpy.data.objects.new("CheckCamera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    for view, angle_deg in (("front", 0.0), ("side", 90.0)):
        angle: float = math.radians(angle_deg)
        camera.location = Vector((math.sin(angle) * 10.0, -math.cos(angle) * 10.0, TARGET_HEIGHT * 0.5))
        camera.rotation_euler = (math.radians(90.0), 0.0, angle)
        scene.render.filepath = "%s_%s_%s.png" % (CHECK_PREFIX, suffix, view)
        bpy.ops.render.render(write_still=True)
    for obj in markers + [camera]:
        bpy.data.objects.remove(obj)
    scene.display.shading.show_xray = False


def export(mesh, armature) -> None:
    os.makedirs(os.path.dirname(BLEND_OUTPUT), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUTPUT)
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    armature.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=OUTPUT,
        export_format="GLB",
        use_selection=True,
        export_animations=False,
        export_skins=True,
        export_yup=True,
        export_image_format="AUTO",
    )
    log("yazıldı: %s (%.0f KB)" % (os.path.relpath(OUTPUT, REPO), os.path.getsize(OUTPUT) / 1024.0))


def main() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mesh = load_soldier_mesh()
    simplify(mesh)
    simplify_material(mesh)
    armature = load_skeleton()
    reference: dict = fit_skeleton(armature)
    render_check(mesh, armature, "joints")
    bind(mesh, armature)
    match_rest_pose(mesh, armature, reference)
    ground(mesh, armature)
    render_check(mesh, armature, "rest")
    export(mesh, armature)
    log("bitti")


main()
