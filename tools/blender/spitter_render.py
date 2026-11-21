"""Tükürücü (spitter) konsept görselleri (7.3 v1, v2 düzeltmeleri baştan): dizi, imza, oyun kamerası, siluet, yakın.
tank_render.py'den kopyalanıp uyarlandı.

Arka planda tümü (her görüntü kendi sahnesini kurar):
    blender --background --python tools/blender/spitter_render.py [-- lineup signature gamecam silhouette close] [--samples=N]
Çıktılar: docs/concept/spitter_v1_{lineup,signature,gamecam,silhouette,close}.png, ara kareler build/shots/.
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
import build_spitter as bt  # noqa: E402
import zombie_kit as kit  # noqa: E402

importlib.reload(bt)
CONCEPT_DIR = os.path.join(bt.REPO, "docs", "concept")
SHOTS_DIR = os.path.join(bt.REPO, "build", "shots")
VERSION = "v1"
SAMPLES = 64
GAMECAM_PITCH = 55.0
GAMECAM_DIST = 17.0


def _out(name):
    return os.path.join(CONCEPT_DIR, f"spitter_{VERSION}_{name}.png")


def _shot(name):
    os.makedirs(SHOTS_DIR, exist_ok=True)
    return os.path.join(SHOTS_DIR, f"spitter_{name}.png")


def _aim(cam, eye, target):
    cam.location = eye
    cam.rotation_euler = (Vector(target) - Vector(eye)).to_track_quat("-Z", "Y").to_euler()


def _render_settings(samples):
    scene = bpy.context.scene
    try:
        scene.render.engine = "CYCLES"
        scene.cycles.samples = samples
        scene.cycles.use_denoising = True
        prefs = bpy.context.preferences.addons["cycles"].preferences
        for kind in ("OPTIX", "CUDA"):
            try:
                prefs.compute_device_type = kind
                prefs.get_devices()
                for d in prefs.devices:
                    d.use = True
                scene.cycles.device = "GPU"
                break
            except (TypeError, ValueError):
                continue
    except (TypeError, AttributeError, KeyError) as err:
        print("engine:", err)
    scene.render.image_settings.file_format = "PNG"


def _render_to(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def _side_by_side(paths, out):
    """walker_render._side_by_side kopyası (paylaşılan dosyaya dokunmamak için)."""
    import numpy as np
    imgs = [bpy.data.images.load(p, check_existing=False) for p in paths]
    w, h = sum(i.size[0] for i in imgs), max(i.size[1] for i in imgs)
    canvas = np.zeros((h, w, 4), dtype=np.float32)
    x = 0
    for img in imgs:
        iw, ih = img.size
        px = np.empty(iw * ih * 4, dtype=np.float32)
        img.pixels.foreach_get(px)
        canvas[:ih, x:x + iw] = px.reshape(ih, iw, 4)
        x += iw
    result = bpy.data.images.new("spitter_combined", w, h, alpha=True)
    result.pixels.foreach_set(canvas.ravel())
    result.filepath_raw = out
    result.file_format = "PNG"
    result.save()
    for img in imgs + [result]:
        bpy.data.images.remove(img)
    return out


def _spread_lights(factor, center=(0.0, 0.0, 0.0), aim_z=1.4):
    for name in ("Key", "Rim", "Fill"):
        obj = bpy.data.objects[name]
        obj.location = obj.location * factor + Vector(center)
        obj.data.energy *= factor * factor
        obj.data.size *= factor
        target = Vector(center) + Vector((0.0, 0.0, aim_z))
        obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def render_lineup(samples=SAMPLES):
    """Üç çeşit nötr duruşta: önden ve 3/4'ten."""
    bt.build("neutral")
    _spread_lights(2.2)
    _render_settings(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 1300, 1000
    scene.camera.data.lens = 62
    _aim(scene.camera, (0.0, -8.6, 1.9), (0.0, 0.0, 0.9))
    a = _render_to(_shot("front"))
    _aim(scene.camera, (5.6, -6.6, 2.8), (0.0, 0.0, 0.85))
    b = _render_to(_shot("34"))
    return _side_by_side([a, b], _out("lineup"))


def render_signature(samples=SAMPLES, name="Worker"):
    """Bırakıştan hemen önceki an (geriye kasılmış, gırtlak en şiş): yandan ve 3/4 önden."""
    kit.reset_scene()
    v = next(x for x in bt.VARIANTS if x["name"] == name)
    bt.build_variant(v, 0.0, "signature")
    kit.setup_look(target_height=1.6)
    _spread_lights(1.4, aim_z=1.6)
    _render_settings(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 900, 1100
    scene.camera.data.lens = 85
    _aim(scene.camera, (-5.6, -0.6, 1.6), (0.0, -0.05, 1.0))
    a = _render_to(_shot("sig_side"))
    _aim(scene.camera, (2.9, -4.7, 1.9), (0.0, -0.1, 1.0))
    b = _render_to(_shot("sig_34"))
    return _side_by_side([a, b], _out("signature"))


def build_compare(tanks=(("Worker", "neutral", -0.4, 0.6, -10), ("Suit", "signature", 2.6, -0.2, 15)),
                  walkers=((0, -2.4, -0.6, 8), (1, 1.0, -1.4, -12), (3, -1.6, 1.9, 20)), dilci=(4.2, 1.4)):
    """Oyun kamerası sahnesi: tükürücüler + karşılaştırma için yürüyenler ve bir dilci."""
    import build_walker as bw
    importlib.reload(bw)
    kit.reset_scene()
    for name, pose, x, y, yaw in tanks:
        v = next(t for t in bt.VARIANTS if t["name"] == name)
        root = bt.build_variant(v, 0.0, pose)
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
    _spread_lights(3.0, center=(0.4, 0.6, 0.0), aim_z=0.6)


def _gamecam(target, dist=GAMECAM_DIST):
    cam = bpy.context.scene.camera
    cam.data.lens = 85
    pitch = math.radians(GAMECAM_PITCH)
    _aim(cam, Vector(target) + Vector((0.0, -math.cos(pitch), math.sin(pitch))) * dist, target)


def render_gamecam(samples=SAMPLES):
    build_compare()
    _render_settings(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 1400, 900
    _gamecam(Vector((0.8, 0.4, 0.8)))
    return _render_to(_out("gamecam"))


def render_silhouette(samples=8):
    """Düz siyah siluet, oyun kamerasından: tükürücü (nötr, imza), yürüyen, dilci yan yana."""
    build_compare(tanks=(("Worker", "neutral", -1.9, 0.0, 0), ("Worker", "signature", 0.3, 0.0, 0)),
                  walkers=((0, 2.2, 0.0, 0),), dilci=(3.6, 0.0))
    _render_settings(samples)
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
    for name in ("Key", "Rim", "Fill"):
        bpy.data.objects[name].hide_render = True
    scene.render.resolution_x, scene.render.resolution_y = 1400, 700
    try:
        scene.view_settings.view_transform = "Standard"
    except TypeError as err:
        print("view transform:", err)
    _gamecam(Vector((0.85, 0.0, 0.9)), dist=19.0)
    out = _render_to(_out("silhouette"))
    bpy.context.view_layer.material_override = None
    return out


def render_close(samples=96, name="Worker"):
    """Kafa + gırtlak kesesi (3/4 önden) ve kambur kabarcıkları (arkadan yukarıdan) yan yana."""
    kit.reset_scene()
    v = next(x for x in bt.VARIANTS if x["name"] == name)
    root = bt.build_variant(v, 0.0, "neutral")
    kit.setup_look(target_height=1.8)
    _render_settings(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 900, 1000
    bpy.context.view_layer.update()
    head = next(o for o in root.children_recursive if o.name.startswith("Spitter_Head"))
    c = head.matrix_world @ Vector((0.0, -0.03, 0.03))
    scene.camera.data.lens = 60
    _aim(scene.camera, c + Vector((0.75, -1.75, 0.30)), c + Vector((0.0, 0.10, -0.05)))
    a = _render_to(_shot("close_face"))
    _aim(scene.camera, (1.2, 2.2, 3.0), (0.0, 0.15, 1.75))
    for name_l in ("Key", "Rim"):
        obj = bpy.data.objects[name_l]
        obj.location.y *= -1.0
        obj.rotation_euler = (Vector((0, 0.2, 1.8)) - obj.location).to_track_quat("-Z", "Y").to_euler()
    b = _render_to(_shot("close_back"))
    return _side_by_side([a, b], _out("close"))


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
        print("SPITTER render", n, "->", fn(samples=SAMPLES) if n not in ("silhouette",) else fn())
    bpy.ops.wm.save_as_mainfile(filepath=bt.OUT_BLEND)


if __name__ not in ("spitter_render",):
    main()
