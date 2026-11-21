"""Şehir kiti: bina/prop betiklerinin ortak parçaları (Aşama 8.1c).

Arka planda çalışır: blender --background --python tools/blender/build_city_building.py
Her malzeme için tek ağ nesnesi üretilir (kutular birleştirilir). Z yukarı, ölçek metre.
Cephe koordinatı: u = cephe boyunca, d = cepheden dışarı, z = yükseklik.
"""
import math
import random

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

HALF = 9.5          # 19 m blok
TILE_U = 2.0        # tuğla dokusu metre karşılığı (yatay)
TILE_V = 1.6        # (dikey)

# malzeme paleti: ad -> (taban renk, pürüz, metalik, emisyon rengi, güç)
PALETTE = {
    "brick": ((0.26, 0.13, 0.10), 0.95, 0.0, None, 0.0),
    "concrete": ((0.17, 0.17, 0.16), 0.97, 0.0, None, 0.0),
    "soot": ((0.025, 0.022, 0.02), 0.98, 0.0, None, 0.0),
    "rust": ((0.10, 0.06, 0.045), 0.55, 0.55, None, 0.0),
    "glass": ((0.03, 0.05, 0.07), 0.15, 0.0, None, 0.0),
    "warm": ((0.2, 0.1, 0.03), 0.6, 0.0, (1.0, 0.62, 0.18), 7.0),
    "awning": ((0.2, 0.1, 0.08), 0.95, 0.0, None, 0.0),
    "wood": ((0.13, 0.085, 0.055), 0.95, 0.0, None, 0.0),
}


def reset_scene() -> None:
    for coll in (bpy.data.objects, bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.images, bpy.data.worlds):
        for block in list(coll):
            coll.remove(block)
    bpy.context.scene.unit_settings.system = "METRIC"


def brick_image(size: int = 128) -> bpy.types.Image:
    """Üretilmiş tuğla dokusu (8 sıra, sıra başına 4 tuğla), pakete gömülür."""
    rng = random.Random(7)
    img = bpy.data.images.new("brick_tex", size, size)
    px = [0.0] * (size * size * 4)
    course = size // 8
    brick_w = size // 4
    for cy in range(8):
        off = (brick_w // 2) if cy % 2 else 0
        for bx in range(-1, 5):
            shade = rng.uniform(0.65, 1.15) * (0.45 if rng.random() < 0.14 else 1.0)
            tint = (rng.uniform(-0.02, 0.02), rng.uniform(-0.015, 0.015))
            base = (0.27 * shade + tint[0], 0.135 * shade, 0.105 * shade + tint[1])
            x0 = bx * brick_w + off
            for y in range(cy * course, (cy + 1) * course):
                for x in range(x0, x0 + brick_w):
                    xx = x % size
                    edge = (y - cy * course) < 2 or (x - x0) < 2
                    col = (0.06, 0.055, 0.05) if edge else base
                    i = (y * size + xx) * 4
                    px[i:i + 4] = [col[0], col[1], col[2], 1.0]
    img.pixels = px
    img.pack()
    return img


def awning_image() -> bpy.types.Image:
    """Solmuş koyu kırmızı / yeşil şeritli tente dokusu (0.5 m şerit)."""
    img = bpy.data.images.new("awning_tex", 32, 8)
    px = []
    for _y in range(8):
        for x in range(32):
            red = (x // 8) % 2 == 0
            col = (0.27, 0.07, 0.06) if red else (0.08, 0.16, 0.10)
            px += [col[0], col[1], col[2], 1.0]
    img.pixels = px
    img.pack()
    return img


def make_materials() -> dict:
    mats = {}
    for name, (base, rough, metal, emis, strength) in PALETTE.items():
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        nt = mat.node_tree
        bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
        bsdf.inputs["Base Color"].default_value = (*base, 1.0)
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal
        if emis is not None:
            bsdf.inputs["Emission Color"].default_value = (*emis, 1.0)
            bsdf.inputs["Emission Strength"].default_value = strength
        if name == "brick":
            tex = nt.nodes.new("ShaderNodeTexImage")
            tex.image = brick_image()
            tex.interpolation = "Closest"
            nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        if name == "awning":
            tex = nt.nodes.new("ShaderNodeTexImage")
            tex.image = awning_image()
            tex.interpolation = "Closest"
            nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        mats[name] = mat
    return mats


class Kit:
    def __init__(self) -> None:
        self.bms: dict = {}

    def _bm(self, mat: str):
        if mat not in self.bms:
            self.bms[mat] = bmesh.new()
        return self.bms[mat]

    def _emit(self, mat: str, pts: list) -> None:
        bm = self._bm(mat)
        v = [bm.verts.new(p) for p in pts]
        for f in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
            bm.faces.new([v[i] for i in f])

    @staticmethod
    def fmap(fac: str, u: float, d: float, z: float) -> Vector:
        """Cephe koordinatı -> dünya. X cephesi +X'e, Y cephesi -Y'ye bakar."""
        if fac == "X":
            return Vector((HALF + d, u, z))
        return Vector((u, -(HALF + d), z))

    def fbox(self, fac, mat, u0, u1, d0, d1, z0, z1, tilt=None) -> None:
        c = ((u0 + u1) / 2, (d0 + d1) / 2, (z0 + z1) / 2)
        h = ((u1 - u0) / 2, (d1 - d0) / 2, (z1 - z0) / 2)
        pts = []
        for ix in (-1, 1):
            for iy in (-1, 1):
                for iz in (-1, 1):
                    u, d, z = ix * h[0], iy * h[1], iz * h[2]
                    if tilt:
                        plane, a = tilt
                        ca, sa = math.cos(a), math.sin(a)
                        if plane == "uz":
                            u, z = u * ca - z * sa, u * sa + z * ca
                        else:
                            d, z = d * ca - z * sa, d * sa + z * ca
                    pts.append(self.fmap(fac, c[0] + u, c[1] + d, c[2] + z))
        self._emit(mat, pts)

    def wbox(self, mat, c, s, rot=(0.0, 0.0, 0.0)) -> None:
        m = Euler(rot).to_matrix()
        pts = []
        for ix in (-1, 1):
            for iy in (-1, 1):
                for iz in (-1, 1):
                    pts.append(Vector(c) + m @ Vector((ix * s[0] / 2, iy * s[1] / 2, iz * s[2] / 2)))
        self._emit(mat, pts)

    def box(self, mat, x0, x1, y0, y1, z0, z1) -> None:
        self.wbox(mat, ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), (x1 - x0, y1 - y0, z1 - z0))

    def cyl(self, mat, c, r, h, seg=10, rot=(0.0, 0.0, 0.0)) -> None:
        bm = self._bm(mat)
        m = Matrix.Translation(c) @ Euler(rot).to_matrix().to_4x4()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r, radius2=r, depth=h, matrix=m)

    def finalize(self, mats: dict) -> list:
        objs = []
        for name, bm in self.bms.items():
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
            uv = bm.loops.layers.uv.new("UVMap")
            for f in bm.faces:
                n = f.normal
                ax = max(range(3), key=lambda i: abs(n[i]))
                for loop in f.loops:
                    p = loop.vert.co
                    if ax == 0:
                        h, v = p.y, p.z
                    elif ax == 1:
                        h, v = p.x, p.z
                    else:
                        h, v = p.x, p.y
                    loop[uv].uv = (h / TILE_U, v / TILE_V)
            mesh = bpy.data.meshes.new("building_" + name)
            bm.to_mesh(mesh)
            bm.free()
            mesh.materials.append(mats[name])
            obj = bpy.data.objects.new("building_" + name, mesh)
            bpy.context.collection.objects.link(obj)
            objs.append(obj)
        self.bms = {}
        return objs


def tri_count(objs: list) -> int:
    total = 0
    for o in objs:
        o.data.calc_loop_triangles()
        total += len(o.data.loop_triangles)
    return total


# --- görüntü yardımcıları ---

def _engine(scene) -> None:
    for e in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT", "CYCLES"):
        try:
            scene.render.engine = e
            return
        except TypeError:
            continue


def _world(color, strength) -> None:
    w = bpy.data.worlds.new("w")
    w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (*color, 1.0)
    bg.inputs["Strength"].default_value = strength
    bpy.context.scene.world = w


def _light(kind, loc, energy, color, rot=None):
    data = bpy.data.lights.new(kind, kind)
    data.energy = energy
    data.color = color
    if kind == "POINT":
        data.shadow_soft_size = 0.4
    o = bpy.data.objects.new(kind, data)
    o.location = loc
    if rot:
        o.rotation_euler = rot
    bpy.context.collection.objects.link(o)
    return o


def _camera(pos, target, vfov_deg):
    data = bpy.data.cameras.new("cam")
    data.sensor_fit = "VERTICAL"
    data.angle_y = math.radians(vfov_deg)
    o = bpy.data.objects.new("cam", data)
    o.location = pos
    o.rotation_euler = (Vector(target) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    bpy.context.collection.objects.link(o)
    bpy.context.scene.camera = o
    return o


def render_shot(path, mode, pos, target, vfov, size=(1280, 720)) -> None:
    """mode: 'night' (oyun ruh hali) ya da 'day' (nötr)."""
    sc = bpy.context.scene
    _engine(sc)
    sc.render.resolution_x, sc.render.resolution_y = size
    sc.render.filepath = path
    try:
        sc.eevee.taa_render_samples = 24
    except Exception:
        pass
    lights = []
    if mode == "night":
        _world((0.012, 0.02, 0.05), 1.0)
        lights.append(_light("SUN", (0, 0, 20), 3.0, (0.45, 0.55, 1.0), (math.radians(50), 0, math.radians(30))))
        lights.append(_light("POINT", (12.5, -2.0, 3.0), 2500, (1.0, 0.72, 0.28)))
        lights.append(_light("POINT", (4.0, -12.5, 1.8), 2200, (1.0, 0.4, 0.08)))
        lights.append(_light("POINT", (12.5, -12.0, 5.5), 2500, (0.2, 0.9, 0.7)))
    else:
        _world((0.55, 0.6, 0.68), 1.0)
        lights.append(_light("SUN", (0, 0, 20), 3.5, (1.0, 0.95, 0.85), (math.radians(55), 0, math.radians(35))))
    cam = _camera(pos, target, vfov)
    bpy.ops.render.render(write_still=True)
    for o in lights + [cam]:
        bpy.data.objects.remove(o)
