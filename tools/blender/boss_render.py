"""Boss "Yığın" konsept görselleri (7.4): dizi (önden/yandan/arkadan + asker ölçeği), imza, oyun kamerası,
siluet, yakın. bloater_render.py'den kopyalanıp uyarlandı (paylaşılan dosyalara dokunulmaz).

    blender --background --python tools/blender/boss_render.py [-- lineup signature gamecam silhouette close] [--samples=N]
Çıktılar: docs/concept/boss_v1_{lineup,signature,gamecam,silhouette,close}.png, ara kareler build/shots/.
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
import build_boss as bb  # noqa: E402
import zombie_kit as kit  # noqa: E402

importlib.reload(bb)
CONCEPT_DIR = os.path.join(bb.REPO, "docs", "concept")
SHOTS_DIR = os.path.join(bb.REPO, "build", "shots")
SOLDIER = os.path.join(bb.REPO, "assets", "models", "characters", "soldier.glb")
VERSION = "v1"
SAMPLES = 48
GAMECAM_PITCH = 55.0
GAMECAM_DIST = 30.0


def _out(name):
    return os.path.join(CONCEPT_DIR, f"boss_{VERSION}_{name}.png")


def _shot(name):
    os.makedirs(SHOTS_DIR, exist_ok=True)
    return os.path.join(SHOTS_DIR, f"boss_{name}.png")


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
    result = bpy.data.images.new("boss_combined", w, h, alpha=True)
    result.pixels.foreach_set(canvas.ravel())
    result.filepath_raw = out
    result.file_format = "PNG"
    result.save()
    for img in imgs + [result]:
        bpy.data.images.remove(img)
    return out


def _spread_lights(factor, center=(0.0, 0.0, 0.0), aim_z=2.0):
    for name in ("Key", "Rim", "Fill"):
        obj = bpy.data.objects[name]
        obj.location = obj.location * factor + Vector(center)
        obj.data.energy *= factor ** (1.0 if name == "Rim" else 2.0)
        obj.data.size *= factor
        target = Vector(center) + Vector((0.0, 0.0, aim_z))
        obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def add_soldier(loc, yaw=0.0):
    """Ölçek için asker (soldier.glb, 1.83 m); içe aktarılan nesneler bir köke bağlanır."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=SOLDIER)
    new = [o for o in bpy.data.objects if o not in before]
    root = bpy.data.objects.new("Soldier", None)
    bpy.context.collection.objects.link(root)
    for o in new:
        if o.parent is None:
            o.parent = root
        if o.type == "ARMATURE" and o.animation_data:
            o.animation_data.action = None
    root.location = loc
    root.rotation_euler.z = math.radians(yaw)
    return root


def render_lineup(samples=SAMPLES):
    """Önden, yandan, arkadan; her görüntüde yanında asker (ölçek)."""
    bb.build("neutral", save=False)
    add_soldier((2.0, 0.0, 0.0))
    _spread_lights(2.4, aim_z=1.8)
    _render_settings(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 900, 1000
    scene.camera.data.lens = 40
    soldier = bpy.data.objects["Soldier"]
    paths = []
    for name, eye, sol in (("front", (0.6, -10.5, 2.2), (2.1, 0.0, 0.0)), ("side", (-10.5, -0.4, 2.2), (0.0, -2.2, 0.0)),
                           ("back", (-0.6, 10.5, 2.2), (-2.1, 0.0, 0.0))):
        soldier.location = sol
        soldier.rotation_euler.z = math.radians({"front": 0, "side": -90, "back": 180}[name])
        _aim(scene.camera, eye, (sol[0] * 0.42, sol[1] * 0.42, 1.75))
        paths.append(_render_to(_shot("lineup_" + name)))
    return _side_by_side(paths, _out("lineup"))


def render_signature(samples=SAMPLES):
    """Yer Dövme doruğu (kollar tepede): yandan ve 3/4 önden."""
    bb.build("signature", save=False)
    _spread_lights(1.9, aim_z=2.4)
    _render_settings(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 900, 1100
    scene.camera.data.lens = 40
    _aim(scene.camera, (-10.0, -1.0, 2.6), (0.0, 0.0, 2.4))
    a = _render_to(_shot("sig_side"))
    _aim(scene.camera, (5.5, -8.6, 3.2), (0.0, 0.0, 2.3))
    b = _render_to(_shot("sig_34"))
    return _side_by_side([a, b], _out("signature"))


def build_compare(walkers=((0, -3.2, -1.2, 10), (1, -2.4, 1.8, -15), (3, 3.4, -1.4, -20), (2, 2.6, 2.4, 25)),
                  soldier=(0.6, -3.8, 180.0), boss=(0.0, 0.4, 0.0), pose="neutral"):
    """Oyun kamerası sahnesi: boss + asker + yürüyenler."""
    import build_walker as bw
    importlib.reload(bw)
    kit.reset_scene()
    root = bb.build_variant(0.0, pose)
    root.location = (boss[0], boss[1], 0.0)
    root.rotation_euler.z = math.radians(boss[2])
    for idx, x, y, yaw in walkers:
        w = bw.build_variant(bw.VARIANTS[idx])
        w.location = (x, y, 0.0)
        w.rotation_euler.z = math.radians(yaw)
    if soldier:
        add_soldier((soldier[0], soldier[1], 0.0), soldier[2])
    kit.setup_look()
    _spread_lights(4.0, center=(0.0, 0.4, 0.0), aim_z=0.8)


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
    _gamecam(Vector((0.0, 0.2, 1.0)))
    return _render_to(_out("gamecam"))


def render_silhouette(samples=8):
    """Düz siyah siluet, oyun kamerasından: boss nötr + imza, asker, yürüyen yan yana."""
    import build_walker as bw
    kit.reset_scene()
    for pose, x in (("neutral", -2.6), ("signature", 1.4)):
        root = bb.build_variant(0.0, pose, painted=False)
        root.location.x = x
    w = bw.build_variant(bw.VARIANTS[0])
    w.location = (4.4, 0.0, 0.0)
    add_soldier((5.6, 0.0, 0.0), 180.0)
    kit.setup_look()
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
    _gamecam(Vector((1.4, 0.4, 1.2)), dist=34.0)
    out = _render_to(_out("silhouette"))
    bpy.context.view_layer.material_override = None
    return out


def render_close(samples=64):
    """Kafa + göğüs yarığı (3/4 önden) ve kambur (arkadan yukarıdan) yan yana."""
    root = bb.build("neutral", save=False)
    _spread_lights(1.6, aim_z=2.4)
    _render_settings(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 900, 1000
    bpy.context.view_layer.update()
    head = next(o for o in root.children_recursive if o.name.startswith("Boss_Head"))
    c = head.matrix_world.translation
    scene.camera.data.lens = 45
    _aim(scene.camera, c + Vector((1.4, -3.4, 0.2)), c + Vector((0.0, 0.2, -0.55)))
    a = _render_to(_shot("close_face"))
    _aim(scene.camera, (2.6, 5.6, 6.2), (0.0, 0.3, 2.6))
    for name in ("Key", "Rim"):
        obj = bpy.data.objects[name]
        obj.location.y *= -1.0
        obj.rotation_euler = (Vector((0, 0.3, 2.6)) - obj.location).to_track_quat("-Z", "Y").to_euler()
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
        print("BOSS render", n, "->", fn(samples=SAMPLES) if n != "silhouette" else fn())


if __name__ not in ("boss_render",):
    main()
