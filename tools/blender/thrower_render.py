"""Taş fırlatan konsept görselleri (7.3): dizi, imza pozu, oyun kamerası, siluet, yakın.

Arka planda tümü (her görüntü kendi sahnesini kurar):
    blender --background --python tools/blender/thrower_render.py [-- lineup signature gamecam silhouette close] [--samples=N]
Çıktılar: docs/concept/thrower_v1_{lineup,signature,gamecam,silhouette,close}.png, ara kareler build/shots/.
Yöntem tank_render.py ile aynı (yardımcılar kopyalandı; paylaşılan dosyaya dokunulmaz).
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
import build_thrower as bt  # noqa: E402
import zombie_kit as kit  # noqa: E402

importlib.reload(bt)
CONCEPT_DIR = os.path.join(bt.REPO, "docs", "concept")
SHOTS_DIR = os.path.join(bt.REPO, "build", "shots")
VERSION = "v1"
SAMPLES = 64
GAMECAM_PITCH = 55.0
GAMECAM_DIST = 17.0


def _out(name):
    return os.path.join(CONCEPT_DIR, f"thrower_{VERSION}_{name}.png")


def _shot(name):
    os.makedirs(SHOTS_DIR, exist_ok=True)
    return os.path.join(SHOTS_DIR, f"thrower_{name}.png")


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


def side_by_side(paths, out):
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
    result = bpy.data.images.new("thrower_combined", w, h, alpha=True)
    result.pixels.foreach_set(canvas.ravel())
    result.filepath_raw = out
    result.file_format = "PNG"
    result.save()
    for img in imgs + [result]:
        bpy.data.images.remove(img)
    return out


def _spread_lights(factor, center=(0.0, 0.0, 0.0), aim_z=1.3):
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
    _spread_lights(2.0)
    _render_settings(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 1200, 1000
    scene.camera.data.lens = 40
    _aim(scene.camera, (0.0, -7.4, 1.7), (0.0, 0.0, 1.05))
    a = _render_to(_shot("front"))
    _aim(scene.camera, (-4.8, -5.8, 2.5), (0.0, 0.0, 1.0))
    b = _render_to(_shot("34"))
    return side_by_side([a, b], _out("lineup"))


def render_signature(samples=SAMPLES, name="Vest"):
    """Bırakıştan hemen önceki an: yandan (sağdan) ve 3/4 önden."""
    kit.reset_scene()
    v = next(x for x in bt.VARIANTS if x["name"] == name)
    bt.build_variant(v, 0.0, "signature")
    kit.setup_look(target_height=1.5)
    _spread_lights(1.4, aim_z=1.5)
    _render_settings(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 900, 1100
    scene.camera.data.lens = 42
    _aim(scene.camera, (-5.6, -0.4, 1.7), (0.0, 0.0, 1.35))
    a = _render_to(_shot("sig_side"))
    _aim(scene.camera, (-2.6, -4.8, 1.9), (0.0, 0.0, 1.35))
    b = _render_to(_shot("sig_34"))
    return side_by_side([a, b], _out("signature"))


def build_compare(throwers=(("Vest", "neutral", -0.6, 0.5, -10), ("Flannel", "signature", 2.4, -0.3, 20)),
                  walkers=((0, -2.6, -0.6, 8), (1, 0.9, -1.4, -12), (3, -1.8, 1.9, 20)), dilci=(4.2, 1.4)):
    """Oyun kamerası sahnesi: taş fırlatanlar + karşılaştırma için yürüyenler ve bir dilci."""
    import build_walker as bw
    importlib.reload(bw)
    kit.reset_scene()
    for name, pose, x, y, yaw in throwers:
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
    _gamecam(Vector((0.7, 0.4, 0.8)))
    return _render_to(_out("gamecam"))


def render_silhouette(samples=8):
    """Düz siyah siluet, oyun kamerasından: taş fırlatan (nötr, imza), yürüyen, dilci yan yana."""
    build_compare(throwers=(("Vest", "neutral", -1.9, 0.0, 0), ("Vest", "signature", 0.3, 0.0, 0)),
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


def render_close(samples=96, name="Vest"):
    """Kafa (3/4 önden) ve dev el + kol (yandan aşağıdan) yan yana."""
    kit.reset_scene()
    v = next(x for x in bt.VARIANTS if x["name"] == name)
    root = bt.build_variant(v, 0.0, "neutral")
    kit.setup_look(target_height=1.5)
    _render_settings(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 900, 1000
    bpy.context.view_layer.update()
    head = next(o for o in root.children_recursive if o.name.startswith("Thrower_Head"))
    c = head.matrix_world @ Vector((0.0, -0.03, 0.03))
    scene.camera.data.lens = 60
    _aim(scene.camera, c + Vector((-0.45, -1.05, 0.12)), c + Vector((0.0, 0.0, -0.06)))
    a = _render_to(_shot("close_face"))
    scene.camera.data.lens = 45
    _aim(scene.camera, (-1.9, -1.6, 1.1), (-0.40, 0.0, 0.85))
    b = _render_to(_shot("close_arm"))
    return side_by_side([a, b], _out("close"))


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
        print("THROWER render", n, "->", fn(samples=SAMPLES) if n != "silhouette" else fn())
    bpy.ops.wm.save_as_mainfile(filepath=bt.OUT_BLEND)


if __name__ not in ("thrower_render",):
    main()
