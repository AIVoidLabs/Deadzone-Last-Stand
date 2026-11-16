"""Bir modeli (.glb ya da .blend) ölçer ve önden / yandan / arkadan görüntüler.

Çalıştırma (repo kökünden):
    blender --background --python tools/blender/inspect_model.py -- <model> <çıktı_önek>
Örnek:
    blender --background --python tools/blender/inspect_model.py -- assets/models/source/soldier/x.glb build/shots/soldier_raw
Çıktı: <çıktı_önek>_front.png, _side.png, _back.png ve stdout'ta ölçüler.
"""

import math
import os
import sys

import bpy
from mathutils import Vector

VIEWS: dict = {"front": 0.0, "side": 90.0, "back": 180.0}
RESOLUTION: tuple = (700, 900)
CAMERA_MARGIN: float = 1.15
CAMERA_DISTANCE: float = 20.0


def log(message: str) -> None:
    print("[inspect_model] " + message)
    sys.stdout.flush()


def load(path: str) -> None:
    if path.lower().endswith(".blend"):
        bpy.ops.wm.open_mainfile(filepath=path)
    else:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=path)


def world_bounds(meshes: list) -> tuple:
    low: Vector = Vector((math.inf, math.inf, math.inf))
    high: Vector = Vector((-math.inf, -math.inf, -math.inf))
    for mesh in meshes:
        for corner in mesh.bound_box:
            point: Vector = mesh.matrix_world @ Vector(corner)
            low = Vector(map(min, low, point))
            high = Vector(map(max, high, point))
    return low, high


def report(meshes: list) -> None:
    for mesh in meshes:
        mesh.data.calc_loop_triangles()
        materials: list = [m.name for m in mesh.data.materials if m is not None]
        log("mesh %s: %d köşe, %d üçgen, malzeme %s" % (
            mesh.name, len(mesh.data.vertices), len(mesh.data.loop_triangles), materials))
    for image in bpy.data.images:
        log("doku %s: %dx%d" % (image.name, image.size[0], image.size[1]))
    for armature in [o for o in bpy.data.objects if o.type == "ARMATURE"]:
        log("iskelet %s: %d kemik" % (armature.name, len(armature.data.bones)))


def setup_render(scene) -> None:
    for engine in ("BLENDER_WORKBENCH", "BLENDER_WORKBENCH_NEXT"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    scene.render.resolution_x, scene.render.resolution_y = RESOLUTION
    scene.render.film_transparent = False
    shading = scene.display.shading
    shading.light = "STUDIO"
    shading.color_type = "TEXTURE"
    shading.show_cavity = True


def render_views(scene, low: Vector, high: Vector, prefix: str) -> None:
    center: Vector = (low + high) * 0.5
    size: Vector = high - low
    camera_data = bpy.data.cameras.new("InspectCamera")
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = max(size.z, size.x * RESOLUTION[1] / RESOLUTION[0], size.y * RESOLUTION[1] / RESOLUTION[0]) * CAMERA_MARGIN
    camera = bpy.data.objects.new("InspectCamera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    for name, angle_deg in VIEWS.items():
        angle: float = math.radians(angle_deg)
        # Blender'da karakter -Y'ye bakar; ön görünüm kamerası -Y tarafında durur.
        offset: Vector = Vector((math.sin(angle), -math.cos(angle), 0.0)) * CAMERA_DISTANCE
        camera.location = center + offset
        camera.rotation_euler = (math.radians(90.0), 0.0, angle)
        scene.render.filepath = "%s_%s.png" % (prefix, name)
        bpy.ops.render.render(write_still=True)
        log("yazıldı: " + scene.render.filepath)


def main() -> None:
    args: list = sys.argv[sys.argv.index("--") + 1:]
    model_path: str = os.path.abspath(args[0])
    prefix: str = os.path.abspath(args[1])
    os.makedirs(os.path.dirname(prefix), exist_ok=True)
    load(model_path)
    meshes: list = [o for o in bpy.data.objects if o.type == "MESH"]
    report(meshes)
    low, high = world_bounds(meshes)
    size: Vector = high - low
    log("boyut (m): genişlik X %.3f, derinlik Y %.3f, yükseklik Z %.3f" % (size.x, size.y, size.z))
    log("alt sınır Z %.3f, merkez X %.3f Y %.3f" % (low.z, (low.x + high.x) * 0.5, (low.y + high.y) * 0.5))
    scene = bpy.context.scene
    setup_render(scene)
    render_views(scene, low, high, prefix)


main()
