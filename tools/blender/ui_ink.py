"""Çizgi roman mürekkep amblem hattı (Aşama 9): 3B sahne -> pasalar -> numpy ile afiş çizimi.

Çalıştırma (Blender penceresi açılmaz; canlı Blender'a/MCP'ye dokunmaz):
    blender --background --python tools/blender/ui_emblems_weapons.py
    blender --background --python tools/blender/ui_emblems_stats.py

Akış (her amblem için bir fonksiyon yazılır):
    reset_scene()                       # boş sahne, EEVEE, saydam film
    nesneleri kur: box / cyl / sphere / lathe / tube / torus / import_glb ...
    fit_camera(objs, az, el, lens, fill, roll)   # çerçeveyi doldurur
    add_lights()                        # amber ana ışık + kızıl kenar ışığı
    render_passes()                     # renk, normal, derinlik, nesne kimliği, ışıma
    rgba = ink(passes, seed=..., ...)   # mürekkep görünümü (numpy)
    save_emblem(name, rgba)             # 512x512 PNG, saydam, assets/textures/ui/emblems/
Yardımcılar: contact_sheet(), read_png(), write_png().
"""

import math
import os
import struct
import zlib

import bmesh
import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Euler, Matrix, Quaternion, Vector

REPO: str = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR: str = os.path.join(REPO, "assets", "textures", "ui", "emblems")
WORK_DIR: str = os.path.join(REPO, "build", "blender", "ink")
RENDER_SIZE: int = 1536
FINAL_SIZE: int = 512
SMOOTH_ANGLE: float = 38.0

# UiPalette ile aynı renkler (sRGB 0..1)
def _hex(h: str) -> tuple:
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (1, 3, 5))

INK = _hex("#0B0908")
BONE = _hex("#E9DFCB")
ASH = _hex("#A79B8B")
EMBER = _hex("#FF4A1C")
BLOOD = _hex("#B3121A")
AMBER = _hex("#F08A24")
STEEL = _hex("#3B78B5")
GOLD = _hex("#D9A62E")


def srgb_to_lin(c: tuple) -> tuple:
    return tuple((v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4) for v in c)


# ----------------------------------------------------------------------------- sahne

def reset_scene() -> bpy.types.Scene:
    """Boş sahne: EEVEE, kare çözünürlük, saydam film, Standard görünüm, koyu dünya."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x = RENDER_SIZE
    sc.render.resolution_y = RENDER_SIZE
    sc.render.resolution_percentage = 100
    sc.render.film_transparent = True
    for attr, val in (("view_transform", "Standard"), ("look", "None")):
        try:
            setattr(sc.view_settings, attr, val)
        except (TypeError, ValueError):
            pass
    try:
        sc.eevee.taa_render_samples = 24
    except AttributeError:
        pass
    for attr in ("use_raytracing", "use_shadows"):
        try:
            setattr(sc.eevee, attr, attr == "use_shadows")
        except AttributeError:
            pass
    world = bpy.data.worlds.new("ink_world")
    sc.world = world
    world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (0.05, 0.035, 0.03, 1.0)
    bg.inputs["Strength"].default_value = 1.0
    cam_data = bpy.data.cameras.new("ink_cam")
    cam = bpy.data.objects.new("ink_cam", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam_data.sensor_fit = "AUTO"
    cam_data.clip_start = 0.01
    cam_data.clip_end = 100.0
    return sc


def mat(name: str, color: tuple, rough: float = 0.55, metal: float = 0.0, emit: tuple = None,
        emit_strength: float = 4.0) -> bpy.types.Material:
    """Principled malzeme; color sRGB. emit verilirse ışıyan (parlama + 'ink_emit' özelliği)."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*srgb_to_lin(color), 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if emit is not None:
        lin = srgb_to_lin(emit)
        bsdf.inputs["Emission Color"].default_value = (*lin, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emit_strength
        m["ink_emit"] = list(emit)
    return m


def _finish_obj(obj: bpy.types.Object, m: bpy.types.Material, smooth: bool, bevel: float = 0.0) -> bpy.types.Object:
    if m is not None:
        obj.data.materials.append(m)
    if bevel > 0.0:
        mod = obj.modifiers.new("bev", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        mod.limit_method = "ANGLE"
    if smooth:
        smooth_by_angle(obj)
    return obj


def smooth_by_angle(obj: bpy.types.Object, angle: float = SMOOTH_ANGLE) -> None:
    """Tüm yüzler pürüzsüz, keskin açılı kenarlar sert (yüzey çizgileri doğru yerde çıksın)."""
    if obj.type != "MESH":
        return
    for mod in list(obj.modifiers):
        bpy.context.view_layer.objects.active = obj
        try:
            bpy.ops.object.modifier_apply(modifier=mod.name)
        except RuntimeError:
            pass
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    lim = math.radians(angle)
    for f in bm.faces:
        f.smooth = True
    for e in bm.edges:
        if len(e.link_faces) == 2:
            e.smooth = e.calc_face_angle(0.0) < lim
        else:
            e.smooth = False
    bm.to_mesh(obj.data)
    bm.free()


def _link(obj: bpy.types.Object) -> bpy.types.Object:
    bpy.context.scene.collection.objects.link(obj)
    return obj


def _xf(obj: bpy.types.Object, loc: tuple, rot: tuple, scale: tuple = (1, 1, 1)) -> None:
    obj.location = loc
    obj.rotation_euler = Euler([math.radians(a) for a in rot], "XYZ")
    obj.scale = scale


def box(name: str, center: tuple, size: tuple, m: bpy.types.Material, rot: tuple = (0, 0, 0),
        bevel: float = 0.0, smooth: bool = True) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bm.to_mesh(mesh)
    bm.free()
    obj = _link(bpy.data.objects.new(name, mesh))
    _xf(obj, center, rot, size)
    bpy.context.view_layer.update()
    # ölçek mesh'e işlensin (bevel doğru çalışsın)
    mesh.transform(Matrix.Diagonal((*size, 1.0)))
    obj.scale = (1, 1, 1)
    return _finish_obj(obj, m, smooth, bevel)


def cyl(name: str, center: tuple, radius: float, depth: float, m: bpy.types.Material, axis: str = "Z",
        rot: tuple = (0, 0, 0), radius2: float = None, segs: int = 20, bevel: float = 0.0,
        smooth: bool = True, cap: bool = True) -> bpy.types.Object:
    """Silindir/koni; axis ekseni boyunca uzanır (yerel), sonra rot uygulanır."""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    r2 = radius if radius2 is None else radius2
    bmesh.ops.create_cone(bm, cap_ends=cap, segments=segs, radius1=radius, radius2=r2, depth=depth)
    if axis == "X":
        bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(90), 3, "Y"))
    elif axis == "Y":
        bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(90), 3, "X"))
    bm.to_mesh(mesh)
    bm.free()
    obj = _link(bpy.data.objects.new(name, mesh))
    _xf(obj, center, rot)
    return _finish_obj(obj, m, smooth, bevel)


def sphere(name: str, center: tuple, radius: tuple, m: bpy.types.Material, rot: tuple = (0, 0, 0),
           segs: int = 28, rings: int = 18, smooth: bool = True) -> bpy.types.Object:
    """Elipsoid (radius = (rx, ry, rz))."""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=rings, radius=1.0)
    bmesh.ops.scale(bm, vec=Vector(radius), verts=bm.verts)
    bm.to_mesh(mesh)
    bm.free()
    obj = _link(bpy.data.objects.new(name, mesh))
    _xf(obj, center, rot)
    return _finish_obj(obj, m, smooth)


def torus(name: str, center: tuple, major: float, minor: float, m: bpy.types.Material,
          rot: tuple = (0, 0, 0), segs: int = 32, minor_segs: int = 10) -> bpy.types.Object:
    verts: list = []
    faces: list = []
    for i in range(segs):
        a = 2 * math.pi * i / segs
        for j in range(minor_segs):
            b = 2 * math.pi * j / minor_segs
            r = major + minor * math.cos(b)
            verts.append((r * math.cos(a), r * math.sin(a), minor * math.sin(b)))
    for i in range(segs):
        for j in range(minor_segs):
            a0, a1 = i, (i + 1) % segs
            b0, b1 = j, (j + 1) % minor_segs
            faces.append((a0 * minor_segs + b0, a1 * minor_segs + b0, a1 * minor_segs + b1, a0 * minor_segs + b1))
    return mesh_from(name, verts, faces, center, rot, m)


def mesh_from(name: str, verts: list, faces: list, center: tuple, rot: tuple, m: bpy.types.Material,
              smooth: bool = True) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = _link(bpy.data.objects.new(name, mesh))
    _xf(obj, center, rot)
    return _finish_obj(obj, m, smooth)


def lathe(name: str, profile: list, center: tuple, m: bpy.types.Material, rot: tuple = (0, 0, 0),
          segs: int = 28, smooth: bool = True) -> bpy.types.Object:
    """Dönel yüzey: profile = [(yarıçap, z), ...] alttan üste; yarıçap 0 kapatır. Z ekseni etrafında."""
    verts: list = []
    faces: list = []
    n = len(profile)
    for r, z in profile:
        for i in range(segs):
            a = 2 * math.pi * i / segs
            verts.append((r * math.cos(a), r * math.sin(a), z))
    for k in range(n - 1):
        for i in range(segs):
            i2 = (i + 1) % segs
            a, b, c, d = k * segs + i, k * segs + i2, (k + 1) * segs + i2, (k + 1) * segs + i
            faces.append((a, b, c, d))
    return mesh_from(name, verts, faces, center, rot, m, smooth)


def tube(name: str, points: list, radius: float, m: bpy.types.Material, taper: float = 1.0,
         segs: int = 8, smooth_curve: bool = True) -> bpy.types.Object:
    """Noktalardan geçen borulu eğri (damar, tel, dikiş ipi). taper<1 uca doğru inceltir."""
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "3D"
    cu.bevel_depth = radius
    cu.bevel_resolution = max(1, segs // 4)
    cu.use_fill_caps = True
    sp = cu.splines.new("POLY" if not smooth_curve else "NURBS")
    sp.points.add(len(points) - 1)
    for i, p in enumerate(points):
        sp.points[i].co = (*p, 1.0)
        sp.points[i].radius = 1.0 + (taper - 1.0) * (i / max(1, len(points) - 1))
    if smooth_curve:
        sp.order_u = min(4, len(points))
        sp.use_endpoint_u = True
        sp.resolution_u = 12
    obj = _link(bpy.data.objects.new(name, cu))
    if m is not None:
        cu.materials.append(m)
    bpy.context.view_layer.objects.active = obj
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    obj = bpy.context.view_layer.objects.active
    smooth_by_angle(obj, 50.0)
    return obj


def import_glb(path: str, names: list = None, hide_others: bool = True) -> list:
    """GLB'yi içe aktarır; yalnız names adlı MESH'leri bırakır, dönüştürmeleri işler. Oyun GLB'si değişmez."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    keep: list = []
    for o in new:
        if o.type == "MESH" and (names is None or o.name.split(".")[0] in names):
            keep.append(o)
    if hide_others:
        for o in new:
            if o not in keep and o.type != "ARMATURE":
                bpy.data.objects.remove(o, do_unlink=True)
    return keep


def bake_transforms(obj: bpy.types.Object) -> None:
    """Nesnenin dönüşümünü mesh'e işler (parent'ı bırakır)."""
    bpy.context.view_layer.update()
    mw = obj.matrix_world.copy()
    obj.parent = None
    obj.data.transform(mw)
    obj.matrix_world = Matrix.Identity(4)


def group_transform(objs: list, loc: tuple = (0, 0, 0), rot: tuple = (0, 0, 0), scale: float = 1.0) -> None:
    """Birden çok nesneyi dünya orijini etrafında döndür/ölçekle/taşı (mesh'e işler)."""
    bpy.context.view_layer.update()
    m = Matrix.Translation(loc) @ Euler([math.radians(a) for a in rot], "XYZ").to_matrix().to_4x4() \
        @ Matrix.Scale(scale, 4)
    for o in objs:
        if o.type == "MESH":
            o.data.transform(o.matrix_world)
            o.matrix_world = Matrix.Identity(4)
            o.data.transform(m)


def meshes() -> list:
    return [o for o in bpy.context.scene.objects if o.type == "MESH"]


def sample_points(objs: list, step: int = 1) -> list:
    pts: list = []
    for o in objs:
        mw = o.matrix_world
        pts.extend(mw @ v.co for v in o.data.vertices[::step])
    return pts


# ----------------------------------------------------------------------------- kamera ve ışık

def fit_camera(objs: list, az: float = -35.0, el: float = 18.0, lens: float = 70.0, fill: float = 0.86,
               roll: float = 0.0, shift: tuple = (0.0, 0.0), target: tuple = None) -> bpy.types.Object:
    """Kamerayı (az: yatay açı derece, 0=-Y'den bakar; el: yükseklik) nesne grubunu çerçeveyi dolduracak
    şekilde yerleştirir. roll: görüş ekseni etrafında eğim (uzun silahlar çapraz dolsun). lens küçük = perspektif."""
    sc = bpy.context.scene
    cam = sc.camera
    cam.data.lens = lens
    cam.data.sensor_width = 36.0
    bpy.context.view_layer.update()
    pts = sample_points(objs, 1)
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    center = Vector(target) if target is not None else (lo + hi) * 0.5
    a, e = math.radians(az), math.radians(el)
    to_cam = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e)))
    quat = (-to_cam).to_track_quat("-Z", "Y") @ Quaternion((0, 0, 1), math.radians(roll))
    cam.rotation_mode = "QUATERNION"
    cam.rotation_quaternion = quat
    dist = (hi - lo).length * 1.6
    cam.location = center + to_cam * dist
    fov_t = 18.0 / lens
    for _ in range(40):
        bpy.context.view_layer.update()
        xs: list = []
        ys: list = []
        for p in pts:
            c = world_to_camera_view(sc, cam, p)
            xs.append(c.x)
            ys.append(c.y)
        if os.environ.get('INK_DEBUG'):
            print('FIT', _, round(min(xs), 3), round(max(xs), 3), round(min(ys), 3), round(max(ys), 3), round(dist, 3))
        cx, cy = (min(xs) + max(xs)) * 0.5 - 0.5, (min(ys) + max(ys)) * 0.5 - 0.5
        ext = max(max(xs) - min(xs), max(ys) - min(ys))
        width = 2.0 * dist * fov_t
        right = quat @ Vector((1, 0, 0))
        up = quat @ Vector((0, 1, 0))
        center = center + right * (cx - shift[0]) * width * 0.6 + up * (cy - shift[1]) * width * 0.6
        dist = dist * (ext / fill) ** 0.7
        cam.location = center + to_cam * dist
    bpy.context.view_layer.update()
    return cam


def add_lights(cam: bpy.types.Object = None, key: tuple = (1.0, 0.88, 0.72), rim: tuple = (1.0, 0.28, 0.10),
               fill: tuple = (0.35, 0.45, 0.65), key_energy: float = 4.2, rim_energy: float = 5.0,
               fill_energy: float = 0.7, key_side: float = -1.0) -> None:
    """Kamera eksenine göre: amber ana ışık (üst sol), kızıl kenar ışığı (arka sağ), soluk mavi dolgu."""
    cam = cam or bpy.context.scene.camera
    q = cam.rotation_quaternion
    right, up, back = q @ Vector((1, 0, 0)), q @ Vector((0, 1, 0)), q @ Vector((0, 0, 1))

    def sun(name: str, pos_dir: Vector, color: tuple, energy: float, angle: float) -> None:
        ld = bpy.data.lights.new(name, "SUN")
        ld.color = srgb_to_lin(color)
        ld.energy = energy
        ld.angle = math.radians(angle)
        lo = _link(bpy.data.objects.new(name, ld))
        lo.rotation_mode = "QUATERNION"
        lo.rotation_quaternion = (-pos_dir).to_track_quat("-Z", "Y")

    sun("key", (right * key_side * 0.8 + up * 0.9 + back * 0.9).normalized(), key, key_energy, 12.0)
    sun("rim", (right * -key_side * 1.0 + up * 0.5 - back * 1.1).normalized(), rim, rim_energy, 8.0)
    sun("fill", (right * -key_side * 0.6 + up * -0.2 + back * 1.0).normalized(), fill, fill_energy, 25.0)


# ----------------------------------------------------------------------------- paslar

def _new_mat(name: str, color_fn) -> bpy.types.Material:
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    color_fn(nt, em)
    return m


def _mat_flat(rgb: tuple) -> bpy.types.Material:
    def fn(nt, em):
        em.inputs["Color"].default_value = (*rgb, 1.0)
    return _new_mat("flat", fn)


def _mat_normal() -> bpy.types.Material:
    def fn(nt, em):
        g = nt.nodes.new("ShaderNodeNewGeometry")
        vt = nt.nodes.new("ShaderNodeVectorTransform")
        vt.vector_type = "NORMAL"
        vt.convert_from = "WORLD"
        vt.convert_to = "CAMERA"
        ma = nt.nodes.new("ShaderNodeVectorMath")
        ma.operation = "MULTIPLY_ADD"
        ma.inputs[1].default_value = (0.5, 0.5, 0.5)
        ma.inputs[2].default_value = (0.5, 0.5, 0.5)
        nt.links.new(g.outputs["Normal"], vt.inputs["Vector"])
        nt.links.new(vt.outputs["Vector"], ma.inputs[0])
        nt.links.new(ma.outputs["Vector"], em.inputs["Color"])
    return _new_mat("normal", fn)


def _mat_depth() -> bpy.types.Material:
    def fn(nt, em):
        cd = nt.nodes.new("ShaderNodeCameraData")
        comb = nt.nodes.new("ShaderNodeCombineXYZ")
        for s in ("X", "Y", "Z"):
            nt.links.new(cd.outputs["View Z Depth"], comb.inputs[s])
        nt.links.new(comb.outputs["Vector"], em.inputs["Color"])
    return _new_mat("depth", fn)


def _obj_emit(o: bpy.types.Object) -> tuple:
    for m in o.data.materials:
        if m is not None and "ink_emit" in m:
            return tuple(srgb_to_lin(tuple(m["ink_emit"])))
    return (0.0, 0.0, 0.0)


def _render_exr(path: str) -> np.ndarray:
    sc = bpy.context.scene
    sc.render.filepath = path
    sc.render.image_settings.file_format = "OPEN_EXR"
    sc.render.image_settings.color_depth = "32"
    sc.render.image_settings.color_mode = "RGBA"
    bpy.ops.render.render(write_still=True)
    img = bpy.data.images.load(path)
    img.colorspace_settings.name = "Non-Color"
    h, w = img.size[1], img.size[0]
    buf = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(buf)
    bpy.data.images.remove(img)
    return buf.reshape(h, w, 4)


def render_passes(samples_color: int = 24) -> dict:
    """Dönen sözlük: color(lineer RGBA), normal(0..1 kamera uzayı), depth, id, emit(lineer RGB), alpha."""
    os.makedirs(WORK_DIR, exist_ok=True)
    sc = bpy.context.scene
    objs = meshes()
    originals = {o: list(o.data.materials) for o in objs}
    emits = {o: _obj_emit(o) for o in objs}  # özgün malzemeler değişmeden önce oku
    out: dict = {}

    def swap(fn) -> None:
        for i, o in enumerate(objs):
            nm_ = fn(i, o)  # önce hesapla: temizlenince özgün malzeme (ink_emit) kaybolur
            o.data.materials.clear()
            o.data.materials.append(nm_)

    def restore() -> None:
        for o, ms in originals.items():
            o.data.materials.clear()
            for m in ms:
                o.data.materials.append(m)

    def path(n: str) -> str:
        return os.path.join(WORK_DIR, n + ".exr")

    sc.render.filter_size = 1.2
    try:
        sc.eevee.taa_render_samples = samples_color
    except AttributeError:
        pass
    c = _render_exr(path("color"))
    out["color"] = c
    out["alpha"] = c[..., 3].copy()
    sc.render.filter_size = 0.0
    try:
        sc.eevee.taa_render_samples = 1
    except AttributeError:
        pass
    nm, dm = _mat_normal(), _mat_depth()
    swap(lambda i, o: nm)
    out["normal"] = _render_exr(path("normal"))[..., :3]
    swap(lambda i, o: dm)
    out["depth"] = _render_exr(path("depth"))[..., 0]
    rng = np.random.default_rng(7)
    ids = rng.permutation(len(objs)) + 1
    swap(lambda i, o: _mat_flat((ids[i] / (len(objs) + 1.0),) * 3))
    out["id"] = _render_exr(path("id"))[..., 0]
    try:
        sc.eevee.taa_render_samples = 8
    except AttributeError:
        pass
    sc.render.filter_size = 1.5
    swap(lambda i, o: _mat_flat(emits[o]))
    out["emit"] = _render_exr(path("emit"))[..., :3]
    restore()
    return out


# ----------------------------------------------------------------------------- numpy yardımcıları

def smoothstep(a: float, b: float, x: np.ndarray) -> np.ndarray:
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def box_blur(a: np.ndarray, r: int, passes: int = 2) -> np.ndarray:
    """Ayrık kutu bulanıklığı (cumsum), 2B ya da 3B dizi; passes=2 ~ gauss."""
    if r <= 0:
        return a
    out = a.astype(np.float64)
    for _ in range(passes):
        for axis in (0, 1):
            pad = [(0, 0)] * out.ndim
            pad[axis] = (r + 1, r)
            p = np.pad(out, pad, mode="edge")
            cs = np.cumsum(p, axis=axis)
            n = out.shape[axis]
            hi = np.take(cs, np.arange(2 * r + 1, 2 * r + 1 + n), axis=axis)
            lo = np.take(cs, np.arange(0, n), axis=axis)
            out = (hi - lo) / (2 * r + 1)
    return out.astype(np.float32)


def dilate(m: np.ndarray, r: int) -> np.ndarray:
    """Maksimum süzgeci (kare pencere, yarıçap r) - ayrık."""
    if r <= 0:
        return m
    out = m
    for axis in (0, 1):
        pad = [(0, 0)] * out.ndim
        pad[axis] = (r, r)
        p = np.pad(out, pad, mode="edge")
        n = out.shape[axis]
        acc = np.take(p, np.arange(0, n), axis=axis)
        for k in range(1, 2 * r + 1):
            acc = np.maximum(acc, np.take(p, np.arange(k, k + n), axis=axis))
        out = acc
    return out


def erode(m: np.ndarray, r: int) -> np.ndarray:
    return 1.0 - dilate(1.0 - m, r)


def value_noise(h: int, w: int, cell: int, rng: np.random.Generator, octaves: int = 3) -> np.ndarray:
    """0..1 fraktal değer gürültüsü (bilineer, ayrık)."""
    total = np.zeros((h, w), np.float32)
    amp, norm = 1.0, 0.0
    for o in range(octaves):
        c = max(2, cell >> o)
        gh, gw = h // c + 3, w // c + 3
        g = rng.random((gh, gw)).astype(np.float32)
        ys = np.arange(h) / c
        xs = np.arange(w) / c
        y0, x0 = ys.astype(int), xs.astype(int)
        fy, fx = (ys - y0).astype(np.float32), (xs - x0).astype(np.float32)
        fy = fy * fy * (3 - 2 * fy)
        fx = fx * fx * (3 - 2 * fx)
        rows = g[y0] * (1 - fy)[:, None] + g[y0 + 1] * fy[:, None]
        cols = rows[:, x0] * (1 - fx)[None, :] + rows[:, x0 + 1] * fx[None, :]
        total += cols * amp
        norm += amp
        amp *= 0.5
    return total / norm


def streak_noise(h: int, w: int, length: int, angle_deg: float, rng: np.random.Generator,
                 width: int = 1) -> np.ndarray:
    """Fırça darbesi dokusu: açı yönünde uzamış gürültü (0..1, kontrastı açılmış)."""
    size = int(math.hypot(h, w)) + 8
    base = rng.random((size, size)).astype(np.float32)
    base = box_blur(base, 0, 1) if width <= 1 else box_blur(base[:, :], width, 1)
    base = box_blur(np.ascontiguousarray(base), 0, 1)
    # tek eksen bulanıklık (satır boyunca)
    r = max(1, length)
    p = np.pad(base.astype(np.float64), ((0, 0), (r + 1, r)), mode="edge")
    cs = np.cumsum(p, axis=1)
    base = ((cs[:, 2 * r + 1:2 * r + 1 + size] - cs[:, :size]) / (2 * r + 1)).astype(np.float32)
    lo, hi = np.percentile(base, 5), np.percentile(base, 95)
    base = np.clip((base - lo) / max(hi - lo, 1e-6), 0, 1)
    th = math.radians(angle_deg)
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    cx, cy = w * 0.5, h * 0.5
    u = (xx - cx) * math.cos(th) + (yy - cy) * math.sin(th) + size * 0.5
    v = -(xx - cx) * math.sin(th) + (yy - cy) * math.cos(th) + size * 0.5
    return base[np.clip(v.astype(int), 0, size - 1), np.clip(u.astype(int), 0, size - 1)]


def warp(arrs: dict, amp: float, rng: np.random.Generator) -> dict:
    """Tüm paslara aynı küçük titrek kaydırma (çizgiler elle çizilmiş gibi dalgalansın)."""
    any_arr = next(iter(arrs.values()))
    h, w = any_arr.shape[:2]
    dx = (value_noise(h, w, 96, rng, 2) - 0.5) * 2.0 * amp + (value_noise(h, w, 26, rng, 1) - 0.5) * amp * 0.8
    dy = (value_noise(h, w, 96, rng, 2) - 0.5) * 2.0 * amp + (value_noise(h, w, 26, rng, 1) - 0.5) * amp * 0.8
    yy, xx = np.mgrid[0:h, 0:w]
    xi = np.clip((xx + dx).astype(int), 0, w - 1)
    yi = np.clip((yy + dy).astype(int), 0, h - 1)
    return {k: v[yi, xi] for k, v in arrs.items()}


def edge_strength(a: np.ndarray, d: int = 2) -> np.ndarray:
    """Komşu farklarının en büyüğü (çok kanallı dizi için kanallarda toplanır)."""
    def diff(x: np.ndarray, y: np.ndarray) -> np.ndarray:
        dd = np.abs(x - y)
        return dd.sum(axis=2) if dd.ndim == 3 else dd
    e = np.zeros(a.shape[:2], np.float32)
    e[:, d:] = np.maximum(e[:, d:], diff(a[:, d:], a[:, :-d]))
    e[:, :-d] = np.maximum(e[:, :-d], diff(a[:, d:], a[:, :-d]))
    e[d:, :] = np.maximum(e[d:, :], diff(a[d:, :], a[:-d, :]))
    e[:-d, :] = np.maximum(e[:-d, :], diff(a[d:, :], a[:-d, :]))
    return e


def stamp_discs(mask: np.ndarray, centers: list, radii: list, noise: np.ndarray, rough: float = 0.4) -> None:
    """Düzensiz kenarlı yuvarlak lekeleri mask'e (max) işler."""
    h, w = mask.shape
    for (cx, cy), r in zip(centers, radii):
        r0 = int(r * (1 + rough) + 2)
        x0, x1, y0, y1 = max(0, int(cx) - r0), min(w, int(cx) + r0 + 1), max(0, int(cy) - r0), min(h, int(cy) + r0 + 1)
        if x1 <= x0 or y1 <= y0:
            continue
        yy, xx = np.mgrid[y0:y1, x0:x1]
        d = np.hypot(xx - cx, yy - cy) / max(r, 1e-3)
        n = noise[y0:y1, x0:x1]
        v = 1.0 - smoothstep(0.85, 1.05, d + (n - 0.5) * rough * 1.6)
        mask[y0:y1, x0:x1] = np.maximum(mask[y0:y1, x0:x1], v)


def stamp_lines(mask: np.ndarray, rng: np.random.Generator, count: int, region: np.ndarray, length: tuple,
                thick: float, angle_range: tuple = (0, 180)) -> None:
    """Çizik: bölge içinde rastgele kısa doğru parçaları."""
    h, w = mask.shape
    ys, xs = np.nonzero(region > 0.5)
    if len(ys) == 0:
        return
    for _ in range(count):
        k = rng.integers(0, len(ys))
        cx, cy = xs[k], ys[k]
        ang = math.radians(rng.uniform(*angle_range))
        ln = rng.uniform(*length)
        n = int(ln)
        for s in np.linspace(-0.5, 0.5, n):
            px, py = int(cx + math.cos(ang) * ln * s), int(cy + math.sin(ang) * ln * s)
            t = max(1, int(thick * (1.0 - abs(s) * 1.4)))
            if 0 <= px < w and 0 <= py < h:
                mask[max(0, py - t):py + t + 1, max(0, px - t):px + t + 1] = 1.0


# ----------------------------------------------------------------------------- mürekkep

def lin_to_srgb(c: np.ndarray) -> np.ndarray:
    c = np.clip(c, 0.0, None)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(c, 1 / 2.4) - 0.055)


def ink(p: dict, seed: int = 1, bands: tuple = (0.17, 0.42, 0.72), levels: tuple = (0.07, 0.30, 0.62, 1.0),
        line_gain: float = 1.0, hatch: float = 1.0, grime: float = 1.0, blood: float = 1.0,
        contour: float = 1.0, rim: float = 1.0, glow: float = 1.0, saturation: float = 1.12,
        blood_spots: int = 3, shadow_tint: tuple = (0.12, 0.05, 0.08), warp_amp: float = 3.0,
        tone: tuple = (1.0, 0.98, 0.94), halo: float = 0.0, halo_color: tuple = (0.25, 0.55, 1.0),
        soft_emit: bool = False) -> np.ndarray:
    """Pasaları çizgi roman afiş çizimine çevirir. Döner: (h, w, 4) float32 sRGB düz (premultiplied DEĞİL) RGBA."""
    rng = np.random.default_rng(seed)
    h, w = p["alpha"].shape
    scale = w / 1536.0
    sw = lambda v: max(1, int(round(v * scale)))

    arrs = warp({"c": p["color"][..., :3], "a": p["alpha"], "n": p["normal"], "d": p["depth"], "i": p["id"],
                 "e": p["emit"]}, warp_amp * scale, rng)
    col_lin, alpha, nrm, depth, oid, emit = arrs["c"], arrs["a"], arrs["n"], arrs["d"], arrs["i"], arrs["e"]
    obj = (alpha > 0.5).astype(np.float32)
    objm = box_blur(obj, sw(1), 1)

    # --- bantlı gölge: parlaklık gürültüyle bozulup 4 banda kesilir
    csrgb = lin_to_srgb(col_lin)
    lum = csrgb @ np.array([0.30, 0.55, 0.15], np.float32)
    inside = obj > 0.5
    em_pre = np.clip(emit.max(axis=2) * 3.0, 0, 1)
    body_px = inside & (em_pre < 0.3)
    ref = np.percentile(lum[body_px], 97) if body_px.any() else 1.0
    ln = np.clip(lum / max(ref, 1e-3), 0, 1.4)
    brush = streak_noise(h, w, sw(40), -35.0, rng, 2)
    fbm = value_noise(h, w, sw(70), rng, 3)
    # ışık yönü (sol-üst) gradyanı + boşluk (cavity) koyulaşması: düz yüzeyler de bantlara bölünsün
    yy_, xx_ = np.mgrid[0:h, 0:w].astype(np.float32)
    if inside.any():
        ys_i, xs_i = np.nonzero(inside)
        x0_, x1_, y0_, y1_ = xs_i.min(), xs_i.max(), ys_i.min(), ys_i.max()
        gx = (xx_ - x0_) / max(x1_ - x0_, 1)
        gy = 1.0 - (yy_ - y0_) / max(y1_ - y0_, 1)
        lgrad = np.clip(gx * 0.55 - gy * 0.55, -1, 1)
        ln = ln * (1.0 - 0.20 * lgrad)
    dep_n = np.where(inside, (depth - depth[inside].min()) / max(np.ptp(depth[inside]), 1e-4), 0.0) if inside.any() else depth
    cav = np.clip((dep_n - box_blur(dep_n, sw(16), 2)) * 9.0, 0.0, 0.32) * obj
    ln = ln - cav
    ln = ln + (fbm - 0.5) * 0.22 + (brush - 0.5) * 0.04
    band = np.zeros(ln.shape, np.int32)
    for t in bands:
        band += (ln > t).astype(np.int32)
    lv = np.array(levels, np.float32)[band]
    chroma = csrgb / np.maximum(lum[..., None], 0.04)
    chroma = np.clip(chroma, 0.0, 3.0)
    mean = chroma.mean(axis=2, keepdims=True)
    chroma = mean + (chroma - mean) * saturation
    rgb = chroma * lv[..., None]
    mx = rgb.max(axis=2, keepdims=True)
    rgb = rgb / np.maximum(1.0, mx / 0.97)
    rgb = rgb * np.array(tone, np.float32)
    shade = (band == 0)
    rgb = np.where(shade[..., None], rgb * 0.55 + np.array(shadow_tint, np.float32) * 0.9, rgb)

    # --- kir / lekelenme: düşük frekans leke + yüksek frekans benek
    mott = value_noise(h, w, sw(34), rng, 3)
    spec = value_noise(h, w, sw(5), rng, 2)
    dirt = np.clip((smoothstep(0.55, 0.85, mott) * 0.55 + smoothstep(0.72, 0.9, spec) * 0.5) * grime, 0, 1)
    rgb = rgb * (1.0 - dirt[..., None] * 0.32 * obj[..., None])
    rgb = rgb * (0.97 + 0.06 * brush[..., None])

    # --- ışıma (emit) nesneleri: banttan bağımsız, canlı çekirdek
    em_mask = np.clip(emit.max(axis=2) * 3.0, 0, 1)
    if em_mask.max() > 0.01:
        em_col = lin_to_srgb(emit / np.maximum(emit.max(axis=2, keepdims=True), 1e-4))
        facing = np.clip(nrm[..., 2] * 2 - 1, 0, 1)
        hot = em_col * (0.88 + 0.2 * facing[..., None])
        core = smoothstep(0.25, 0.65, facing)[..., None] * 0.85
        hot = hot * (1 - core) + np.array([1.0, 0.97, 0.88], np.float32) * core
        rgb = rgb * (1 - em_mask[..., None]) + hot * em_mask[..., None]

    # --- sıcak kenar ışığı: bakış açısına dik yüzeylerde, ışık yönü (sağ-arka) tarafında
    facing = np.clip(nrm[..., 2] * 2 - 1, 0, 1)
    nx, ny = nrm[..., 0] * 2 - 1, nrm[..., 1] * 2 - 1
    side = np.clip(nx * 0.8 + ny * 0.5, 0, 1)
    rim_m = smoothstep(0.55, 0.12, facing) * smoothstep(0.1, 0.5, side) * obj * rim
    rim_m = rim_m * (0.6 + 0.4 * brush)
    rgb = rgb * (1 - rim_m[..., None] * 0.85) + np.array([1.0, 0.55, 0.2], np.float32) * rim_m[..., None] * 0.85

    # --- tarama çizgileri (gölge tarafında)
    ang = math.radians(48)
    ph = ((np.arange(w)[None, :] * math.cos(ang) + np.arange(h)[:, None] * math.sin(ang)) / (sw(13))
          + (value_noise(h, w, sw(90), rng, 1) - 0.5) * 1.2)
    fr = ph - np.floor(ph)
    dark_amt = np.clip((bands[1] - ln) / bands[1], 0, 1)
    thick_h = 0.12 + 0.45 * dark_amt
    hatch_a = (np.abs(fr - 0.5) * 2 < thick_h).astype(np.float32) * smoothstep(0.0, 0.25, dark_amt)
    hatch_a = hatch_a * (band <= 1) * obj * (em_mask < 0.3) * hatch
    ph2 = ((np.arange(w)[None, :] * math.cos(-ang) + np.arange(h)[:, None] * math.sin(-ang)) / (sw(11))
           + (value_noise(h, w, sw(50), rng, 2) - 0.5) * 2.0)
    fr2 = ph2 - np.floor(ph2)
    cross = (np.abs(fr2 - 0.5) * 2 < 0.2 + 0.4 * dark_amt).astype(np.float32) * (band == 0) * (dark_amt > 0.6) * obj * hatch
    hatch_a = np.maximum(hatch_a * (0.55 + 0.45 * brush), cross * 0.8)
    rgb = rgb * (1 - hatch_a[..., None] * 0.9) + np.array(INK, np.float32) * hatch_a[..., None] * 0.9

    # --- iç çizgiler: normal + derinlik + kimlik kenarları, değişken kalınlık
    nrm_s = box_blur(nrm, 1, 1)
    en = edge_strength(nrm_s, sw(2))
    dn = depth.copy()
    dn[obj < 0.5] = np.nan
    if inside.any():
        dmin, dmax = np.nanmin(dn), np.nanmax(dn)
    else:
        dmin, dmax = 0.0, 1.0
    dnn = np.where(inside, (depth - dmin) / max(dmax - dmin, 1e-4), 0.0).astype(np.float32)
    ed = edge_strength(dnn, sw(2))
    ei = (edge_strength(oid, sw(2)) > 1e-3).astype(np.float32)
    ed_line = smoothstep(0.035, 0.09, ed)
    en_line = smoothstep(0.28, 0.6, en)
    strong = np.clip(np.maximum(ei, ed_line), 0, 1)
    soft = np.maximum(en_line * 0.9, strong)
    thin = dilate((soft > 0.5).astype(np.float32), sw(2))
    thick = dilate((strong > 0.5).astype(np.float32), sw(5))
    swell = smoothstep(0.45, 0.65, value_noise(h, w, sw(120), rng, 2))
    lines = np.maximum(thin, thick * (0.55 + 0.45 * swell))
    lines = lines * (obj > 0.5) * np.clip(line_gain, 0, 1.5)
    # kuru fırça kopuklukları
    lines = lines * smoothstep(0.18, 0.5, streak_noise(h, w, sw(30), 20.0, rng, 1) * 0.65 + 0.35 * brush + 0.2)
    lines = np.clip(lines, 0, 1)

    # --- siluet konturu (kalın, titrek)
    big = box_blur(obj, sw(18), 2)
    wob = value_noise(h, w, sw(40), rng, 3)
    thr = 0.015 + 0.06 * wob
    outline = ((big > thr) & (obj < 0.5)).astype(np.float32)
    outline = np.maximum(outline, ((objm > 0.5) & (objm < 0.98)).astype(np.float32))
    outline = outline * (0.5 + 0.5 * smoothstep(0.1, 0.4, brush + 0.25)) * contour
    outline = box_blur(outline, 1, 1)

    # --- çizik ve kan sıçraması
    scr = np.zeros((h, w), np.float32)
    stamp_lines(scr, rng, int(30 * grime), obj * (em_mask < 0.3), (sw(40), sw(160)), sw(1.2), (0, 180))
    rgb = rgb * (1 - scr[..., None] * 0.55) + np.array(ASH, np.float32) * scr[..., None] * 0.35 * (1 - lines[..., None])

    bl = np.zeros((h, w), np.float32)
    if blood > 0 and inside.any():
        ys, xs = np.nonzero(inside)
        bn = value_noise(h, w, sw(14), rng, 3)
        cs, rs = [], []
        for _ in range(blood_spots):
            k = rng.integers(0, len(ys))
            cx, cy = float(xs[k]), float(ys[k])
            r = rng.uniform(26, 70) * scale * blood
            cs.append((cx, cy)); rs.append(r)
            for _ in range(int(rng.integers(8, 20))):
                a = rng.uniform(0, 2 * math.pi)
                dd = r * rng.uniform(1.2, 3.4)
                cs.append((cx + math.cos(a) * dd, cy + math.sin(a) * dd))
                rs.append(r * rng.uniform(0.05, 0.22))
        stamp_discs(bl, cs, rs, bn, 0.5)
        bl = bl * (np.maximum(objm, box_blur(obj, sw(10), 1)) > 0.3) * (em_mask < 0.3)
        blood_col = np.array(BLOOD, np.float32) * (0.75 + 0.5 * mott[..., None])
        hi = smoothstep(0.55, 0.75, value_noise(h, w, sw(9), rng, 2))[..., None] * 0.35
        blood_col = np.clip(blood_col + np.array([0.5, 0.1, 0.1], np.float32) * hi, 0, 1)
        rgb = rgb * (1 - bl[..., None] * 0.92) + blood_col * bl[..., None] * 0.92
        edge_bl = (dilate(bl, sw(2)) - bl) > 0.5
        lines = np.maximum(lines, edge_bl.astype(np.float32) * 0.8 * (bl.max() > 0))

    # soft_emit: ışıyan nesnelerde mürekkep çizgisi/kontur yok (yalnız kabza gibi katı parçalarda)
    if os.environ.get('INK_DEBUG'):
        print('EMDBG', float(em_mask.max()), float(emit.max()), soft_emit, halo)
    if soft_emit and em_mask.max() > 0.01:
        keep = 1.0 - np.clip(dilate((em_mask > 0.3).astype(np.float32), sw(18)), 0, 1)
        lines = lines * keep
        outline = outline * keep
    # --- birleştirme
    ink_col = np.array(INK, np.float32)
    line_all = np.clip(np.maximum(lines, outline), 0, 1)
    obj_cov = np.maximum(objm, bl)
    a_out = np.maximum(obj_cov, outline)
    pre = rgb * obj_cov[..., None]
    pre = pre * (1 - line_all[..., None]) + ink_col * line_all[..., None]
    # ışıma: bulanık, nesnenin dışına taşar
    if em_mask.max() > 0.01 and glow > 0:
        gl = box_blur(emit, sw(26), 2)
        gl_a = np.clip(gl.max(axis=2) * 4.0 * glow, 0, 0.9)
        gl_col = lin_to_srgb(gl / np.maximum(gl.max(axis=2, keepdims=True), 1e-4))
        pre_g = gl_col * gl_a[..., None]
        pre = pre + pre_g * (1 - a_out[..., None])
        a_out = a_out + gl_a * (1 - a_out)
    if halo > 0 and em_mask.max() > 0.01:
        hm = box_blur(dilate((em_mask > 0.3).astype(np.float32), sw(6)), sw(80), 2)
        halo_a = np.clip(hm * 2.2 * halo, 0, 0.7) * (1 - a_out)
        hc = np.array(halo_color, np.float32)
        pre = pre + hc * halo_a[..., None]
        a_out = a_out + halo_a
    a_final = np.clip(a_out, 0, 1)
    straight = np.where(a_final[..., None] > 1e-4, pre / np.maximum(a_final[..., None], 1e-4), 0.0)
    return np.dstack([np.clip(straight, 0, 1), a_final]).astype(np.float32)


# ----------------------------------------------------------------------------- çıktı

def downscale(rgba: np.ndarray, size: int = FINAL_SIZE) -> np.ndarray:
    """Alan ortalaması (premultiplied) ile küçültür."""
    h = rgba.shape[0]
    f = h // size
    a = rgba[..., 3:4]
    pre = np.concatenate([rgba[..., :3] * a, a], axis=2)
    pre = pre[:size * f, :size * f].reshape(size, f, size, f, 4).mean(axis=(1, 3))
    al = pre[..., 3:4]
    rgb = np.where(al > 1e-4, pre[..., :3] / np.maximum(al, 1e-4), 0.0)
    return np.concatenate([rgb, al], axis=2)


def write_png(path: str, rgba: np.ndarray) -> None:
    """Sıkıştırılmış 8 bit RGBA PNG (sRGB, düz alfa). rgba (h,w,4) float 0..1, ÜST satır önce."""
    u8 = np.clip(rgba * 255.0 + 0.5, 0, 255).astype(np.uint8)
    h, w = u8.shape[:2]
    raw = np.concatenate([np.zeros((h, 1), np.uint8), u8.reshape(h, w * 4)], axis=1).tobytes()

    def chunk(tag: bytes, data: bytes) -> bytes:
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) \
        + chunk(b"sRGB", b"\x00") + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as fh:
        fh.write(png)


def read_png(path: str) -> np.ndarray:
    """write_png çıktısını (süzgeç 0, 8 bit RGBA) float RGBA olarak okur."""
    with open(path, "rb") as fh:
        data = fh.read()
    pos, idat, w, h = 8, b"", 0, 0
    while pos < len(data):
        n = struct.unpack(">I", data[pos:pos + 4])[0]
        tag = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + n]
        if tag == b"IHDR":
            w, h = struct.unpack(">II", body[:8])
        elif tag == b"IDAT":
            idat += body
        pos += 12 + n
    raw = np.frombuffer(zlib.decompress(idat), np.uint8).reshape(h, w * 4 + 1)
    return raw[:, 1:].reshape(h, w, 4).astype(np.float32) / 255.0


def save_emblem(name: str, rgba_hi: np.ndarray, out_dir: str = OUT_DIR) -> str:
    """Büyük görüntüyü 512'ye indirip emblems/<name>.png olarak yazar (Blender yönü: alt satır önce -> çevrilir)."""
    small = downscale(rgba_hi, FINAL_SIZE)[::-1]
    path = os.path.join(out_dir, name + ".png")
    write_png(path, small)
    return path


def make(name: str, seed: int = 1, **ink_args) -> str:
    """Sahne hazırken: pasaları al, mürekkeple, kaydet."""
    passes = render_passes()
    rgba = ink(passes, seed=seed, **ink_args)
    return save_emblem(name, rgba)


def contact_sheet(names: list, out_path: str, cols: int = 4, tile: int = 256,
                  bg_top: tuple = (0.42, 0.09, 0.07), bg_bottom: tuple = (0.17, 0.03, 0.03),
                  src_dir: str = OUT_DIR) -> None:
    """Amblemleri koyu kırmızı zemin üstünde cols x N tablo yapar (tile px; küçük boy için tile=96)."""
    rows = (len(names) + cols - 1) // cols
    H, W = rows * tile, cols * tile
    t = np.linspace(0, 1, H, dtype=np.float32)[:, None, None]
    bg = np.array(bg_top, np.float32) * (1 - t) + np.array(bg_bottom, np.float32) * t
    sheet = np.broadcast_to(bg, (H, W, 3)).copy()
    f = FINAL_SIZE // tile
    for i, n in enumerate(names):
        path = os.path.join(src_dir, n + ".png")
        if not os.path.exists(path):
            continue
        im = read_png(path)
        if f > 1 and FINAL_SIZE % tile == 0:
            a = im[..., 3:4]
            pre = np.concatenate([im[..., :3] * a, a], axis=2).reshape(tile, f, tile, f, 4).mean(axis=(1, 3))
        else:
            sub = FINAL_SIZE / tile
            idx = (np.arange(tile) * sub).astype(int)
            pre = np.concatenate([im[..., :3] * im[..., 3:4], im[..., 3:4]], axis=2)[idx][:, idx]
        r, c = divmod(i, cols)
        y0, x0 = r * tile, c * tile
        reg = sheet[y0:y0 + tile, x0:x0 + tile]
        sheet[y0:y0 + tile, x0:x0 + tile] = pre[..., :3] + reg * (1 - pre[..., 3:4])
    write_png(out_path, np.dstack([sheet, np.ones((H, W, 1), np.float32)])[::-1][::-1])


# ----------------------------------------------------------------------------- ortak parça kütüphanesi (Kit)

def std_mats() -> dict:
    """Standart malzemeler (sRGB renkler). Işıyanlar (emit) 'ink_emit' özelliğiyle parlar."""
    return {
        "metal": mat("metal", (0.30, 0.31, 0.34), 0.35, 0.5),
        "dark": mat("dark", (0.10, 0.10, 0.11), 0.55, 0.2),
        "navy": mat("navy", (0.20, 0.26, 0.36), 0.45, 0.35),
        "orange": mat("orange", (0.95, 0.5, 0.15), 0.5),
        "wood": mat("wood", (0.50, 0.30, 0.15), 0.7),
        "steel": mat("steel", (0.58, 0.65, 0.76), 0.25, 0.6),
        "edge": mat("edge", (0.90, 0.95, 1.0), 0.2, 0.5),
        "gold": mat("gold", (0.85, 0.65, 0.22), 0.3, 0.6),
        "brass": mat("brass", (0.82, 0.6, 0.2), 0.3, 0.7),
        "copper": mat("copper", (0.78, 0.38, 0.18), 0.3, 0.7),
        "leather": mat("leather", (0.28, 0.16, 0.09), 0.8),
        "olive": mat("olive", (0.34, 0.40, 0.22), 0.6, 0.1),
        "red": mat("red", (0.70, 0.08, 0.07), 0.5),
        "bone": mat("bone", (0.90, 0.86, 0.75), 0.6),
        "flesh": mat("flesh", (0.62, 0.07, 0.09), 0.3),
        "vein": mat("vein", (0.34, 0.05, 0.14), 0.35),
        "fat": mat("fat", (0.85, 0.58, 0.25), 0.5),
        "skin": mat("skin", (0.40, 0.45, 0.33), 0.6),
        "rot": mat("rot", (0.30, 0.22, 0.24), 0.6),
        "dust": mat("dust", (0.46, 0.44, 0.43), 0.9),
        "cyan": mat("cyan", (0.3, 0.78, 1.0), 0.3, 0.0, emit=(0.3, 0.78, 1.0), emit_strength=3.0),
        "white": mat("white", (0.95, 0.97, 1.0), 0.3, 0.0, emit=(0.9, 0.97, 1.0), emit_strength=4.0),
        "yellow": mat("yellow", (1.0, 0.78, 0.18), 0.3, 0.0, emit=(1.0, 0.8, 0.2), emit_strength=4.0),
        "ember": mat("ember", (1.0, 0.36, 0.06), 0.3, 0.0, emit=(1.0, 0.35, 0.05), emit_strength=3.5),
        "glowred": mat("glowred", (1.0, 0.12, 0.10), 0.3, 0.0, emit=(1.0, 0.10, 0.08), emit_strength=3.5),
        "violet": mat("violet", (0.78, 0.30, 0.95), 0.3, 0.0, emit=(0.78, 0.30, 0.95), emit_strength=3.0),
        "crystal": mat("crystal", (0.35, 0.85, 0.95), 0.2, 0.0, emit=(0.35, 0.85, 0.95), emit_strength=2.2),
    }


def blob(name: str, elems: list, m: bpy.types.Material, res: float = 0.03, smooth_iter: int = 2) -> bpy.types.Object:
    """Metaball birleşimi -> pürüzsüz organik ağ. elems: [(merkez, (rx, ry, rz), negatif_mi)]."""
    surface = 0.57
    mb = bpy.data.metaballs.new(name + "_mb")
    mb.resolution = res
    mb.render_resolution = res
    for center, radii, negative in elems:
        el = mb.elements.new(type="ELLIPSOID")
        el.co = center
        r = max(radii) / surface
        el.radius = r
        el.size_x, el.size_y, el.size_z = (q / (surface * r) for q in radii)
        el.use_negative = negative
        el.stiffness = 3.0 if negative else 1.8
    tmp = bpy.data.objects.new(name + "_tmp", mb)
    bpy.context.scene.collection.objects.link(tmp)
    bpy.context.view_layer.update()
    mesh = bpy.data.meshes.new_from_object(tmp.evaluated_get(bpy.context.evaluated_depsgraph_get()))
    bpy.data.objects.remove(tmp)
    bpy.data.metaballs.remove(mb)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(m)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


class Kit:
    """Parça kurucu: self.m malzemeler; her çağrı sahneye bir nesne ekler. t: x/z kalınlık çarpanı."""

    def __init__(self, t: float = 1.0) -> None:
        self.t = t
        self.m = std_mats()
        self._n = 0

    def _name(self, p: str) -> str:
        self._n += 1
        return "%s%d" % (p, self._n)

    def bx(self, c: tuple, s: tuple, m: str, rot: tuple = (0, 0, 0), bev: float = 0.003) -> bpy.types.Object:
        t = self.t
        return box(self._name("b"), (c[0] * t, c[1], c[2] * t), (s[0] * t, s[1], s[2] * t), self.m[m], rot,
                   bevel=bev * t)

    def tb(self, c: tuple, r: float, length: float, m: str, axis: str = "Y", rot: tuple = (0, 0, 0),
           r2: float = None, segs: int = 24, bev: float = 0.0) -> bpy.types.Object:
        t = self.t
        return cyl(self._name("t"), (c[0] * t, c[1], c[2] * t), r * t, length, self.m[m], axis, rot,
                   None if r2 is None else r2 * t, segs, bev * t)

    def ball(self, c: tuple, r: tuple, m: str, rot: tuple = (0, 0, 0), segs: int = 24) -> bpy.types.Object:
        t = self.t
        return sphere(self._name("s"), (c[0] * t, c[1], c[2] * t), (r[0] * t, r[1], r[2] * t), self.m[m], rot,
                      segs, max(8, segs * 2 // 3))

    def ring(self, c: tuple, major: float, minor: float, m: str, rot: tuple = (90, 0, 0)) -> bpy.types.Object:
        t = self.t
        return torus(self._name("r"), (c[0] * t, c[1], c[2] * t), major * t, minor * t, self.m[m], rot)

    def lathe(self, profile: list, c: tuple, m: str, rot: tuple = (0, 0, 0), segs: int = 28) -> bpy.types.Object:
        return lathe(self._name("l"), profile, c, self.m[m], rot, segs)

    def tube(self, pts: list, r: float, m: str, taper: float = 1.0, segs: int = 8) -> bpy.types.Object:
        return tube(self._name("w"), pts, r, self.m[m], taper, segs)

    def blob(self, elems: list, m: str, res: float = 0.03) -> bpy.types.Object:
        return blob(self._name("o"), elems, self.m[m], res)

    def mesh(self, verts: list, faces: list, m: str, c: tuple = (0, 0, 0), rot: tuple = (0, 0, 0)) -> bpy.types.Object:
        return mesh_from(self._name("m"), verts, faces, c, rot, self.m[m])
