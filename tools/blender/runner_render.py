"""Koşucu (Pençeli) konsept görselleri (V.5 v2): dizi, imza pozu, oyun kamerası, siluet, yakın.

Arka plan Blender ile (her görsel sahneyi kendi kurar):
    blender --background --python tools/blender/runner_render.py -- all
    blender --background --python tools/blender/runner_render.py -- lineup signature   # seçerek
Seçenekler: lineup, signature, gamecam, silhouette, close, all. Ayrıca --samples=N.
Çıktılar docs/concept/runner_v2_<ad>.png; ara görüntüler build/shots/runner_*.png.
"""
import importlib
import math
import os
import sys

import bpy
from mathutils import Vector

_HERE = globals().get("__file__", "")
sys.path.insert(0, os.path.dirname(os.path.abspath(_HERE)) if _HERE else
                r"C:\Users\pekta\projeler\Deadzone-Last-Stand\tools\blender")
import build_runner as br  # noqa: E402
import zombie_kit as kit  # noqa: E402
import walker_render as wr  # noqa: E402

importlib.reload(br)
CONCEPT_DIR = os.path.join(br.REPO, "docs", "concept")
SHOTS_DIR = os.path.join(br.REPO, "build", "shots")
VERSION = "v2"
SAMPLES = 64


def _out(name):
    return os.path.join(CONCEPT_DIR, f"runner_{VERSION}_{name}.png")


def _shot(name):
    os.makedirs(SHOTS_DIR, exist_ok=True)
    return os.path.join(SHOTS_DIR, f"runner_{name}.png")


def _setup(res, lens, samples=None):
    wr._render_settings(samples or SAMPLES)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.camera.data.lens = lens
    return scene


def _lineup_scene(pose):
    kit.reset_scene()
    n = len(br.VARIANTS)
    for i, v in enumerate(br.VARIANTS):
        br.build_variant(v, pose, (i - (n - 1) / 2) * br.LINEUP_SPACING)
    kit.setup_look()


def render_lineup():
    """Dört çeşit nötr (sinsi) duruşta: önden ve 3/4'ten yan yana (yürüyen dizisiyle aynı açılar)."""
    _lineup_scene("stalk")
    scene = _setup((1100, 1000), 42)
    wr._aim(scene.camera, (0.0, -6.4, 1.20), (0.0, -0.2, 0.75))
    a = wr._render_to(_shot("front"))
    wr._aim(scene.camera, (4.1, -4.8, 1.65), (0.0, -0.2, 0.70))
    b = wr._render_to(_shot("34"))
    return wr._side_by_side([a, b], _out("lineup"))


def render_signature():
    """İmza anı: atılmadan önceki çömelme. Solda dört çeşit 3/4 alçak açı, sağda tek çeşit profil."""
    _lineup_scene("crouch")
    scene = _setup((1100, 1000), 40)
    wr._aim(scene.camera, (3.2, -4.6, 0.95), (0.0, -0.35, 0.45))
    a = wr._render_to(_shot("sig_34"))
    keep = "Runner_" + br.VARIANTS[1]["name"]
    for v in br.VARIANTS:
        if "Runner_" + v["name"] != keep:
            for obj in bpy.data.objects["Runner_" + v["name"]].children_recursive:
                obj.hide_render = True
    c = bpy.data.objects[keep].matrix_world.translation
    scene.camera.data.lens = 50
    wr._aim(scene.camera, (c.x + 2.9, -0.55, 0.70), (c.x, -0.20, 0.45))
    scene.render.resolution_x = 900
    b = wr._render_to(_shot("sig_side"))
    return wr._side_by_side([a, b], _out("signature"))


def render_close():
    """Yakın: çığlık atan kafa (önden-yandan) ve yerdeki pençeler, çömelme pozunda."""
    kit.reset_scene()
    root = br.build_variant(br.VARIANTS[1], "crouch")
    kit.setup_look(target_height=0.6)
    scene = _setup((800, 900), 70, 96)
    head = next(o for o in root.children_recursive if o.name.startswith("Runner_Head"))
    hc = head.matrix_world @ Vector((0.0, -0.035, 0.035))
    face = (head.matrix_world.to_3x3() @ Vector((0.45, -1.0, 0.20))).normalized()
    wr._aim(scene.camera, hc + face * 0.80, hc)
    a = wr._render_to(_shot("close_head"))
    scene.camera.data.lens = 50
    wr._aim(scene.camera, (0.55, -1.55, 0.55), (0.0, -0.62, 0.10))
    b = wr._render_to(_shot("close_claws"))
    return wr._side_by_side([a, b], _out("close"))


GAMECAM_RUNNERS = [  # (çeşit, poz, x, y, yön derece)
    (0, "stalk", -1.6, 0.2, 10), (1, "crouch", -0.3, -0.4, -10), (2, "stalk", 1.0, 0.4, 18),
    (3, "stalk", 2.1, -0.3, -6), (2, "crouch", -1.1, 1.7, 14), (3, "crouch", 0.6, 1.9, -12),
]


def _place(root, x, y, yaw):
    root.location = (x, y, 0.0)
    root.rotation_euler = (0.0, 0.0, math.radians(yaw))


def build_gamecam(silhouette=False):
    """Koşucu grubu + karşılaştırma için iki yürüyen ve bir dilci (oyun kamerası ölçeği)."""
    import build_walker as bw
    import build_dilci as dilci
    kit.reset_scene()
    layout = GAMECAM_RUNNERS if not silhouette else [(0, "stalk", -1.0, 0.0, 0), (1, "crouch", 0.0, 0.0, 0)]
    for idx, pose, x, y, yaw in layout:
        _place(br.build_variant(br.VARIANTS[idx], pose, prefix=f"Runner_{pose}_"), x, y, yaw)
    walkers = [(0, 3.3, 1.2, -8), (3, 3.0, -0.6, 12)] if not silhouette else [(0, 1.1, 0.0, 0)]
    for idx, x, y, yaw in walkers:
        _place(bw.build_variant(bw.VARIANTS[idx]), x, y, yaw)
    droot, _ = dilci.build_variant(dilci.VARIANTS[1], 0.0, with_tongue=True)
    _place(droot, *((-3.0, 1.1, 15) if not silhouette else (2.3, 0.0, 0)))
    kit.setup_look()
    for light in ("Key", "Rim", "Fill"):
        obj = bpy.data.objects[light]
        obj.location = obj.location * 3.0 + Vector((0.4, 0.6, 0.0))
        obj.data.energy *= 9.0
        obj.data.size *= 3.0
        obj.rotation_euler = (Vector((0.4, 0.6, 0.6)) - obj.location).to_track_quat("-Z", "Y").to_euler()


def _gamecam(scene, target, distance=17.0):
    pitch = math.radians(55.0)
    wr._aim(scene.camera, target + Vector((0.0, -math.cos(pitch), math.sin(pitch))) * distance, target)


def render_gamecam():
    build_gamecam()
    scene = _setup((1400, 900), 85)
    _gamecam(scene, Vector((0.2, 0.6, 0.6)))
    return wr._render_to(_out("gamecam"))


def render_silhouette():
    """Oyun kamerasından düz siyah siluet: koşucu (nötr, çömelik), yürüyen, dilci."""
    build_gamecam(silhouette=True)
    scene = _setup((1400, 700), 85, 16)
    black, _ = kit.material("M_Black", (0.0, 0.0, 0.0), rough=1.0)
    bsdf = next(n for n in black.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Specular IOR Level"].default_value = 0.0
    scene.view_layers[0].material_override = black
    bpy.data.objects["Ground"].hide_render = True
    bg = next(n for n in scene.world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    bg.inputs["Strength"].default_value = 1.0
    scene.view_settings.view_transform = "Standard"
    _gamecam(scene, Vector((0.65, 0.0, 0.55)), 13.5)
    return wr._render_to(_out("silhouette"))


RENDERS = {"lineup": render_lineup, "signature": render_signature, "close": render_close,
           "gamecam": render_gamecam, "silhouette": render_silhouette}


def main(argv):
    global SAMPLES
    args = argv[argv.index("--") + 1:] if "--" in argv else ["all"]
    for a in args:
        if a.startswith("--samples="):
            SAMPLES = int(a.split("=")[1])
    names = [a for a in args if not a.startswith("--")]
    if "all" in names:
        names = list(RENDERS)
    for n in names:
        print("RUNNER render:", n, RENDERS[n]())


if __name__ != "runner_render":
    main(sys.argv)
