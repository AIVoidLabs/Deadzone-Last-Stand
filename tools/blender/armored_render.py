"""Zırhlı zombi konsept görselleri (7.3 v1): dizi, imza pozu, oyun kamerası, siluet, yakın.

    blender --background --python tools/blender/armored_render.py [-- lineup signature gamecam silhouette close] [--samples=N]
Çıktılar: docs/concept/armored_v1_{lineup,signature,gamecam,silhouette,close}.png, ara kareler build/shots/.
İmza pozu oyun iskeletiyle kurulur (armored_game + attack klibinin vuruş karesi): konsept ağının malzemeleri
korunur (keep_materials), böylece görülen poz oyundaki klibin kendisidir.
tank_render.py'den uyarlandı (_side_by_side, ışık yayma, oyun kamerası açısı aynı).
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
import build_armored as ba  # noqa: E402
import zombie_kit as kit  # noqa: E402
import tank_render as tr  # noqa: E402

importlib.reload(ba)
CONCEPT_DIR = os.path.join(ba.REPO, "docs", "concept")
SHOTS_DIR = os.path.join(ba.REPO, "build", "shots")
VERSION = "v1"
SAMPLES = 64


def _out(name):
    return os.path.join(CONCEPT_DIR, f"armored_{VERSION}_{name}.png")


def _shot(name):
    os.makedirs(SHOTS_DIR, exist_ok=True)
    return os.path.join(SHOTS_DIR, f"armored_{name}.png")


def render_lineup(samples=SAMPLES):
    ba.build("neutral", save=False)
    tr._spread_lights(2.2)
    tr._render_settings(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 1200, 1000
    scene.camera.data.lens = 40
    tr._aim(scene.camera, (0.0, -7.6, 1.8), (0.0, 0.0, 1.1))
    a = tr._render_to(_shot("front"))
    tr._aim(scene.camera, (5.0, -5.8, 2.6), (0.0, 0.0, 1.05))
    b = tr._render_to(_shot("34"))
    return tr._side_by_side([a, b], _out("lineup"))


def posed_variant(name, clip, t, x=0.0, y=0.0, yaw=0.0):
    """Oyun iskeletine bağlı konsept ağı (malzemeler korunur), klibin t anında."""
    import armored_game as agm
    importlib.reload(agm)
    v = next(x_ for x_ in ba.VARIANTS if x_["name"] == name)
    arm, _mesh = agm.build_variant_game(v, None, keep_materials=True)
    import armored_anims as an
    importlib.reload(an)
    an.build_all(arm)
    arm.animation_data.action = bpy.data.actions[clip]
    bpy.context.scene.frame_set(round(t * 30))
    arm.location = (x, y, 0.0)
    arm.rotation_euler.z = math.radians(yaw)
    return arm


def render_signature(samples=SAMPLES, name="Riot"):
    """Kalkan darbesinin vuruş anı: yandan ve 3/4 önden."""
    import armored_anims as an
    kit.reset_scene()
    posed_variant(name, "attack", an.HIT_TIME)
    kit.setup_look(target_height=1.2)
    tr._spread_lights(1.4, aim_z=1.2)
    tr._render_settings(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 900, 1000
    scene.camera.data.lens = 45
    tr._aim(scene.camera, (-5.4, -0.9, 1.6), (0.0, -0.4, 1.0))
    a = tr._render_to(_shot("sig_side"))
    tr._aim(scene.camera, (2.6, -4.8, 1.9), (0.0, -0.3, 1.05))
    b = tr._render_to(_shot("sig_34"))
    return tr._side_by_side([a, b], _out("signature"))


def build_compare(armored=(("Riot", -0.6, 0.5, -10), ("Swat", 2.4, -0.4, 25), ("Guard", 0.6, -1.6, 160)),
                  walkers=((0, -2.6, -0.8, 8), (1, 1.2, 1.4, -12), (3, -1.8, 2.0, 20)), dilci=(4.2, 1.4)):
    import build_walker as bw
    importlib.reload(bw)
    kit.reset_scene()
    for name, x, y, yaw in armored:
        v = next(t for t in ba.VARIANTS if t["name"] == name)
        root = ba.build_variant(v)
        root.location = (x, y, 0.0)
        root.rotation_euler.z = math.radians(yaw)
    for idx, x, y, yaw in walkers:
        root = bw.build_variant(bw.VARIANTS[idx])
        root.location = (x, y, 0.0)
        root.rotation_euler.z = math.radians(yaw)
    if dilci:
        import build_dilci as dc
        importlib.reload(dc)
        droot, _ = dc.build_variant(dc.VARIANTS[1], dilci[0], with_tongue=True)
        droot.location.y = dilci[1]
        droot.rotation_euler.z = math.radians(-20)
    kit.setup_look()
    tr._spread_lights(3.0, center=(0.4, 0.6, 0.0), aim_z=0.6)


def render_gamecam(samples=SAMPLES):
    build_compare()
    tr._render_settings(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 1400, 900
    tr._gamecam(Vector((0.8, 0.3, 0.8)))
    return tr._render_to(_out("gamecam"))


def render_silhouette(samples=8):
    """Düz siyah siluet, oyun kamerasından: zırhlı (önden, yandan), yürüyen, dilci."""
    build_compare(armored=(("Riot", -2.0, 0.0, 0), ("Riot", 0.2, 0.0, 70)), walkers=((0, 2.2, 0.0, 0),),
                  dilci=(3.8, 0.0))
    tr._render_settings(samples)
    scene = bpy.context.scene
    black = bpy.data.materials.new("M_Black")
    black.use_nodes = True
    bsdf = next(n for n in black.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (0.0, 0.0, 0.0, 1.0)
    bsdf.inputs["Roughness"].default_value = 1.0
    bsdf.inputs["Specular IOR Level"].default_value = 0.0
    bpy.context.view_layer.material_override = black
    bpy.data.objects["Ground"].hide_render = True
    bg = next(n for n in scene.world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    for n in ("Key", "Rim", "Fill"):
        bpy.data.objects[n].hide_render = True
    scene.render.resolution_x, scene.render.resolution_y = 1400, 700
    scene.view_settings.view_transform = "Standard"
    tr._gamecam(Vector((0.85, 0.0, 0.9)), dist=19.0)
    out = tr._render_to(_out("silhouette"))
    bpy.context.view_layer.material_override = None
    return out


def render_close(samples=96, name="Riot"):
    """Kask + çürük yüz (3/4 önden) ve kalkan (önden yukarıdan) yan yana."""
    kit.reset_scene()
    v = next(x for x in ba.VARIANTS if x["name"] == name)
    root = ba.build_variant(v)
    kit.setup_look(target_height=1.6)
    tr._render_settings(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 900, 1000
    bpy.context.view_layer.update()
    head = next(o for o in root.children_recursive if o.name.startswith("Armored_Head"))
    c = head.matrix_world @ Vector((0.0, -0.03, 0.04))
    scene.camera.data.lens = 70
    tr._aim(scene.camera, c + Vector((-0.55, -1.5, 0.12)), c + Vector((0.0, 0.0, -0.02)))
    a = tr._render_to(_shot("close_face"))
    scene.camera.data.lens = 50
    tr._aim(scene.camera, (0.9, -2.6, 2.4), (0.05, -0.3, 1.15))
    b = tr._render_to(_shot("close_shield"))
    return tr._side_by_side([a, b], _out("close"))


RENDERS = {"lineup": render_lineup, "signature": render_signature, "gamecam": render_gamecam,
           "silhouette": render_silhouette, "close": render_close}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    global SAMPLES
    for a in argv:
        if a.startswith("--samples="):
            SAMPLES = int(a.split("=")[1])
    names = [a for a in argv if a in RENDERS] or list(RENDERS)
    for n in names:
        fn = RENDERS[n]
        print("ARMORED render", n, "->", fn(samples=SAMPLES) if n != "silhouette" else fn())


if __name__ not in ("armored_render",):
    main()
