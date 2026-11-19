"""Yürüyen zombi konsept görselleri (V.5 v2.1): dizi, oyun kamerası, yakın, yüzler.

build_walker.py exec edildikten sonra (sahne kurulu):
    import walker_render as wr; wr.render_all()
render_gamecam sahneyi kendi kurar (sürü + karşılaştırma için bir dilci), bu yüzden en sonda çalışır.
"""
import importlib
import math
import os

import bpy
from mathutils import Vector

import build_walker as bw
import zombie_kit as kit

importlib.reload(bw)
CONCEPT_DIR = os.path.join(bw.REPO, "docs", "concept")
SHOTS_DIR = os.path.join(bw.REPO, "build", "shots")
VERSION = "v21"


def _out(name):
    return os.path.join(CONCEPT_DIR, f"walker_{VERSION}_{name}.png")


def _aim(cam, eye, target):
    cam.location = eye
    cam.rotation_euler = (Vector(target) - Vector(eye)).to_track_quat("-Z", "Y").to_euler()


def _render_settings(samples=64):
    scene = bpy.context.scene
    try:
        scene.render.engine = "CYCLES"
        scene.cycles.samples = samples
        scene.cycles.use_denoising = True
    except (TypeError, AttributeError) as err:
        print("engine:", err)
    scene.render.image_settings.file_format = "PNG"


def _render_to(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def _side_by_side(paths, out):
    import numpy as np
    imgs = [bpy.data.images.load(p, check_existing=False) for p in paths]
    w = sum(i.size[0] for i in imgs)
    h = max(i.size[1] for i in imgs)
    canvas = np.zeros((h, w, 4), dtype=np.float32)
    x = 0
    for img in imgs:
        iw, ih = img.size
        px = np.empty(iw * ih * 4, dtype=np.float32)
        img.pixels.foreach_get(px)
        canvas[:ih, x:x + iw] = px.reshape(ih, iw, 4)
        x += iw
    result = bpy.data.images.new("walker_combined", w, h, alpha=True)
    result.pixels.foreach_set(canvas.ravel())
    result.filepath_raw = out
    result.file_format = "PNG"
    result.save()
    for img in imgs + [result]:
        bpy.data.images.remove(img)
    return out


def render_lineup(samples=64):
    """Tüm çeşitler: önden ve 3/4'ten, yan yana tek görsel (v1 ile aynı açılar)."""
    _render_settings(samples)
    scene = bpy.context.scene
    os.makedirs(SHOTS_DIR, exist_ok=True)
    scene.render.resolution_x, scene.render.resolution_y = 1100, 1000
    scene.camera.data.lens = 42
    _aim(scene.camera, (0.0, -6.0, 1.30), (0.0, -0.2, 0.90))
    a = _render_to(os.path.join(SHOTS_DIR, "walker_front.png"))
    _aim(scene.camera, (3.9, -4.6, 1.75), (0.0, -0.2, 0.88))
    b = _render_to(os.path.join(SHOTS_DIR, "walker_34.png"))
    return _side_by_side([a, b], _out("lineup"))


def render_close(name="Office", samples=96):
    """Bir çeşidin yakın görüntüsü (bel üstü, 3/4; v1 ile aynı açı)."""
    _render_settings(samples)
    scene = bpy.context.scene
    c = bpy.data.objects["Walker_" + name].matrix_world.translation
    scene.render.resolution_x, scene.render.resolution_y = 1000, 1100
    scene.camera.data.lens = 60
    _aim(scene.camera, (c.x + 0.75, -1.85, 1.62), (c.x, -0.28, 1.36))
    return _render_to(_out("close"))


def _head_of(root):
    return next(o for o in root.children_recursive if o.name.startswith("Walker_Head"))


def render_faces(samples=96):
    """Dört çeşidin kafası yakından, yan yana (hafif yukarıdan 3/4: saç ve yüz birlikte)."""
    _render_settings(samples)
    scene = bpy.context.scene
    os.makedirs(SHOTS_DIR, exist_ok=True)
    scene.render.resolution_x, scene.render.resolution_y = 600, 700
    scene.camera.data.lens = 70
    paths = []
    for v in bw.VARIANTS:
        head = _head_of(bpy.data.objects["Walker_" + v["name"]])
        c = head.matrix_world @ Vector((0.0, -0.03, 0.045))
        face = (head.matrix_world.to_3x3() @ Vector((0.35, -1.0, 0.45))).normalized()
        _aim(scene.camera, c + face * 0.85, c)
        paths.append(_render_to(os.path.join(SHOTS_DIR, f"walker_face_{v['name']}.png")))
    return _side_by_side(paths, _out("faces"))


GAMECAM_LAYOUT = [  # (çeşit indeksi, x, y, yön derece) — sürü: dağınık, oyuncuya (-Y) doğru
    (0, -1.6, 0.4, 8), (1, -0.4, -0.3, -12), (2, 0.9, 0.5, 20), (3, 2.0, -0.2, -5),
    (3, -2.4, 1.8, 15), (0, -0.9, 1.6, -20), (1, 0.6, 2.0, 5), (2, 1.8, 1.4, -15),
]


def build_gamecam(with_dilci=True):
    """Oyun kamerasına benzer sahne: dağınık yürüyen grubu + karşılaştırma için bir dilci."""
    kit.reset_scene()
    for coll in list(bpy.data.collections):
        if coll.name.startswith("C_Walker_"):
            bpy.data.collections.remove(coll)
    roots = [bw.build_variant(v) for v in bw.VARIANTS]
    for idx, x, y, yaw in GAMECAM_LAYOUT:
        dup = bpy.data.objects.new(roots[idx].name + "_g", None)
        bpy.context.collection.objects.link(dup)
        dup.instance_type = "COLLECTION"
        dup.location = (x, y, 0.0)
        dup.rotation_euler = (0.0, 0.0, math.radians(yaw))
        dup.instance_collection = _variant_collection(roots[idx])
    if with_dilci:
        import build_dilci as dilci
        importlib.reload(dilci)
        droot, _ = dilci.build_variant(dilci.VARIANTS[1], 3.4, with_tongue=True)
        droot.location.y = 1.0
        droot.rotation_euler.z = math.radians(-20)
    kit.setup_look()
    for light in ("Key", "Rim", "Fill"):
        obj = bpy.data.objects[light]
        obj.location = obj.location * 3.0 + Vector((0.4, 0.6, 0.0))
        obj.data.energy *= 9.0
        obj.data.size *= 3.0
        obj.rotation_euler = (Vector((0.4, 0.6, 0.6)) - obj.location).to_track_quat("-Z", "Y").to_euler()


def _variant_collection(root):
    coll = bpy.data.collections.get("C_" + root.name)
    if coll is None:
        coll = bpy.data.collections.new("C_" + root.name)
        bpy.context.scene.collection.children.link(coll)
        for obj in [root] + list(root.children_recursive):
            for c in list(obj.users_collection):
                c.objects.unlink(obj)
            coll.objects.link(obj)
        root.location = (0.0, 0.0, 0.0)
        coll.hide_render = False
        bpy.context.view_layer.layer_collection.children[coll.name].exclude = True
    return coll


def render_gamecam(samples=64):
    """~55° aşağı bakan, uzak, dar açılı kamera (oyunda ~17 m)."""
    build_gamecam()
    _render_settings(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 1400, 900
    cam = scene.camera
    cam.data.lens = 85
    pitch = math.radians(55.0)
    target = Vector((0.5, 0.9, 0.7))
    _aim(cam, target + Vector((0.0, -math.cos(pitch), math.sin(pitch))) * 17.0, target)
    return _render_to(_out("gamecam"))


def render_all():
    """Kurulu dizi sahnesinden dizi, yakın ve yüzler; sonra oyun kamerası sahnesi."""
    out = [render_lineup(), render_close(), render_faces(), render_gamecam()]
    print("WALKER renders:", out)
    return out
