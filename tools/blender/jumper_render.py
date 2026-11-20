"""Zıplayan zombi konsept görselleri (V.5 v2): dizi, imza pozu, yakın, oyun kamerası (+ siluet).

Arka planda çalıştırılır (sahneyi kendisi kurar):
    blender --background --python tools/blender/jumper_render.py -- [lineup signature close gamecam silhouette] [--samples=N]
Argüman verilmezse lineup, signature, close, gamecam. Çıktılar docs/concept/jumper_v2_*.png (v1 görselleri
git'teki v1 betiğinden), ara görseller build/shots/.
walker_render'ın kamera / birleştirme yardımcılarını kullanır (o dosya değişmez).
"""
import importlib
import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(globals().get("__file__", "")))
                if globals().get("__file__") else r"C:\Users\pekta\projeler\Deadzone-Last-Stand\tools\blender")
import build_jumper as bj  # noqa: E402
import zombie_kit as kit  # noqa: E402
import walker_render as wr  # noqa: E402

importlib.reload(bj)
CONCEPT_DIR = os.path.join(bj.REPO, "docs", "concept")
SHOTS_DIR = os.path.join(bj.REPO, "build", "shots")
VERSION = "v2"
SIGNATURE_VARIANT = 0      # Shorts (kaslar açıkta)
SAMPLES = 48


def _out(name):
    return os.path.join(CONCEPT_DIR, f"jumper_{VERSION}_{name}.png")


def _shot(name):
    os.makedirs(SHOTS_DIR, exist_ok=True)
    return os.path.join(SHOTS_DIR, f"jumper_{name}.png")


def render_lineup():
    """Dört çeşit nötr hazır duruşta: önden ve 3/4'ten."""
    bj.build()
    wr._render_settings(SAMPLES)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 1100, 900
    scene.camera.data.lens = 42
    wr._aim(scene.camera, (0.0, -6.4, 1.15), (0.0, -0.2, 0.70))
    a = wr._render_to(_shot("front"))
    wr._aim(scene.camera, (4.2, -4.8, 1.75), (0.0, -0.2, 0.68))
    b = wr._render_to(_shot("34"))
    return wr._side_by_side([a, b], _out("lineup"))


def _single(pose, variant=SIGNATURE_VARIANT):
    kit.reset_scene()
    root = bj.build_variant(bj.VARIANTS[variant], 0.0, pose)
    kit.setup_look(target_height=0.6)
    return root


def render_signature():
    """İmza: sıçramadan önceki derin çömelme; yandan (yay) ve 3/4 önden."""
    _single("crouch")
    wr._render_settings(SAMPLES)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 900, 900
    scene.camera.data.lens = 50
    wr._aim(scene.camera, (-3.6, -0.10, 0.75), (0.0, 0.02, 0.45))
    a = wr._render_to(_shot("sig_side"))
    wr._aim(scene.camera, (2.2, -2.9, 1.45), (0.0, -0.05, 0.45))
    b = wr._render_to(_shot("sig_34"))
    return wr._side_by_side([a, b], _out("signature"))


def render_close():
    """Yakın: çömelik pozda kafa, kambur sırt ve uyluk kütlesi (alçak 3/4)."""
    _single("crouch")
    wr._render_settings(SAMPLES + 32)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 1000, 1000
    scene.camera.data.lens = 55
    wr._aim(scene.camera, (1.05, -1.75, 0.95), (0.05, -0.15, 0.60))
    return wr._render_to(_out("close"))


GAMECAM_LAYOUT = [  # (çeşit, x, y, yön derece, poz) — zıplayan grubu + bir çömelen
    (0, -1.8, 0.5, 10, "stand"), (1, -0.4, -0.2, -15, "stand"), (2, 1.0, 0.6, 18, "stand"),
    (2, -1.0, 1.9, -8, "stand"), (0, 0.6, 2.1, 12, "crouch"),
]
WALKERS = [(0, 2.3, -0.1, -10), (2, 2.6, 1.8, 15)]


def _place(root, x, y, yaw):
    dup = bpy.data.objects.new(root.name + "_g", None)
    bpy.context.collection.objects.link(dup)
    dup.instance_type = "COLLECTION"
    dup.location = (x, y, 0.0)
    dup.rotation_euler = (0.0, 0.0, math.radians(yaw))
    dup.instance_collection = wr._variant_collection(root)


def _gamecam_lights():
    for light in ("Key", "Rim", "Fill"):
        obj = bpy.data.objects[light]
        obj.location = obj.location * 3.0 + Vector((0.4, 0.6, 0.0))
        obj.data.energy *= 9.0
        obj.data.size *= 3.0
        obj.rotation_euler = (Vector((0.4, 0.6, 0.6)) - obj.location).to_track_quat("-Z", "Y").to_euler()


def _gamecam(cam, target, dist=17.0):
    cam.data.lens = 85
    pitch = math.radians(55.0)
    wr._aim(cam, target + Vector((0.0, -math.cos(pitch), math.sin(pitch))) * dist, target)


def _clear_collections():
    kit.reset_scene()
    for coll in list(bpy.data.collections):
        if coll.name.startswith("C_"):
            bpy.data.collections.remove(coll)


def render_gamecam():
    """Oyun kamerası (~55°, 17 m, 85 mm): zıplayan grubu + ölçek için iki yürüyen."""
    _clear_collections()
    roots = {}
    for idx, x, y, yaw, pose in GAMECAM_LAYOUT:
        key = (idx, pose)
        if key not in roots:
            roots[key] = bj.build_variant(bj.VARIANTS[idx], 0.0, pose)
        _place(roots[key], x, y, yaw)
    for idx, x, y, yaw in WALKERS:
        _place(wr.bw.build_variant(wr.bw.VARIANTS[idx]), x, y, yaw)
    kit.setup_look()
    _gamecam_lights()
    wr._render_settings(SAMPLES)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 1400, 900
    _gamecam(scene.camera, Vector((0.4, 0.9, 0.6)))
    return wr._render_to(_out("gamecam"))


def render_silhouette():
    """Oyun kamerasından düz siyah siluet: zıplayan (hazır + çömelik), yürüyen, dilci."""
    _clear_collections()
    import build_dilci as dilci
    importlib.reload(dilci)
    bj.build_variant(bj.VARIANTS[0], -1.8, "stand")
    bj.build_variant(bj.VARIANTS[0], -0.55, "crouch")
    wr.bw.build_variant(wr.bw.VARIANTS[0], 0.75)
    dilci.build_variant(dilci.VARIANTS[1], 2.0, with_tongue=True)
    kit.setup_look()
    bpy.data.objects.remove(bpy.data.objects["Ground"])
    scene = bpy.context.scene
    bg = next(n for n in scene.world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    black, bsdf = kit.material("M_Silhouette", (0.0, 0.0, 0.0), rough=1.0)
    bsdf.inputs["Specular IOR Level"].default_value = 0.0
    scene.view_layers[0].material_override = black
    wr._render_settings(16)
    try:
        scene.view_settings.view_transform = "Standard"
    except TypeError as err:
        print("view transform:", err)
    scene.render.resolution_x, scene.render.resolution_y = 1400, 700
    _gamecam(scene.camera, Vector((0.1, 0.0, 0.6)), dist=13.0)
    out = wr._render_to(_out("silhouette"))
    scene.view_layers[0].material_override = None
    return out


STEPS = {"lineup": render_lineup, "signature": render_signature, "close": render_close,
         "gamecam": render_gamecam, "silhouette": render_silhouette}


def main(argv):
    global SAMPLES
    args = argv[argv.index("--") + 1:] if "--" in argv else []
    for a in args:
        if a.startswith("--samples="):
            SAMPLES = int(a.split("=")[1])
    names = [a for a in args if a in STEPS] or ["lineup", "signature", "close", "gamecam"]
    for name in names:
        print("JUMPER render:", name, STEPS[name]())


if __name__ == "__main__":
    main(sys.argv)
