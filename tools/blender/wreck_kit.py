"""Yıpratma kiti: hazır (Kenney / Taha) modelleri terk edilmiş, yıkık şehir görünümüne getirir.

Arka planda çalışır (build_props.py içinden). Z yukarı, ölçek metre.
Renk köşe başına (face-corner) 'Col' özniteliğine pişirilir; doku atılır, GLB tek tek malzeme + COLOR_0 taşır.
Hepsi seed'li; aynı betik aynı sonucu verir.
"""
import colorsys
import math
import random

import bmesh
import bpy
from mathutils import Matrix, Vector

# ortak malzeme tanımları (ad -> taban renk, pürüz, metalik)
MATS = {
    "wreck_body": ((1, 1, 1), 0.88, 0.0),     # köşe rengi çarpılır
    "wreck_glass": ((0.012, 0.02, 0.03), 0.12, 0.1),
    "wreck_inside": ((0.008, 0.007, 0.007), 1.0, 0.0),
}


def smoothstep(a: float, b: float, x: float) -> float:
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def _h(ix: int, iy: int, iz: int, seed: int) -> float:
    n = (ix * 374761393 + iy * 668265263 + iz * 2147483647 + seed * 1274126177) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0


def vnoise(p: Vector, seed: int) -> float:
    """3B değer gürültüsü 0..1."""
    x, y, z = p.x, p.y, p.z
    ix, iy, iz = math.floor(x), math.floor(y), math.floor(z)
    fx, fy, fz = x - ix, y - iy, z - iz
    fx, fy, fz = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy), fz * fz * (3 - 2 * fz)
    out = 0.0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                w = (fx if dx else 1 - fx) * (fy if dy else 1 - fy) * (fz if dz else 1 - fz)
                out += w * _h(ix + dx, iy + dy, iz + dz, seed)
    return out


def make_materials() -> dict:
    mats = {}
    for name, (base, rough, metal) in MATS.items():
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        nt = mat.node_tree
        bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
        bsdf.inputs["Base Color"].default_value = (*base, 1.0)
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal
        if name == "wreck_body":
            vc = nt.nodes.new("ShaderNodeVertexColor")
            vc.layer_name = "Col"
            nt.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
        mat.use_backface_culling = True
        mats[name] = mat
    return mats


def reset_scene() -> None:
    for coll in (bpy.data.objects, bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.images, bpy.data.worlds):
        for block in list(coll):
            coll.remove(block)
    bpy.context.scene.unit_settings.system = "METRIC"


class Part:
    """Dünya koordinatlı bir ağ parçası (bmesh) ve köşe renkleri."""

    def __init__(self, name: str, bm: bmesh.types.BMesh) -> None:
        self.name = name
        self.bm = bm

    def center(self) -> Vector:
        lo, hi = self.bounds()
        return (lo + hi) / 2

    def bounds(self):
        co = [v.co for v in self.bm.verts]
        return (Vector((min(c.x for c in co), min(c.y for c in co), min(c.z for c in co))),
                Vector((max(c.x for c in co), max(c.y for c in co), max(c.z for c in co))))


def import_parts(path: str) -> list:
    """GLB içe al; her ağ nesnesi dünya koordinatlı bir Part'a, renkler (dokudan/malzemeden) köşelere."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    bpy.context.view_layer.update()
    parts = []
    for ob in new:
        if ob.type != "MESH":
            continue
        me = ob.data
        pixels = {}
        sizes = {}
        slot_base = []
        for slot in ob.material_slots:
            mat = slot.material
            img = None
            base = (0.5, 0.5, 0.5)
            if mat and mat.node_tree:
                for n in mat.node_tree.nodes:
                    if n.type == "TEX_IMAGE" and n.image:
                        img = n.image
                    if n.type == "BSDF_PRINCIPLED":
                        base = tuple(n.inputs["Base Color"].default_value)[:3]
            if img is not None and img.name not in pixels:
                pixels[img.name] = list(img.pixels)
                sizes[img.name] = tuple(img.size)
            slot_base.append((img.name if img else None, base))
        bm = bmesh.new()
        bm.from_mesh(me)
        uv = bm.loops.layers.uv.active
        col = bm.loops.layers.float_color.new("Col")
        bmesh.ops.transform(bm, matrix=ob.matrix_world, verts=bm.verts)
        for f in bm.faces:
            imgname, base = slot_base[min(f.material_index, len(slot_base) - 1)] if slot_base else (None, (0.5,) * 3)
            for lp in f.loops:
                if imgname and uv:
                    w, h = sizes[imgname]
                    u, v = lp[uv].uv
                    x = min(w - 1, max(0, int(u * w)))
                    y = min(h - 1, max(0, int(v * h)))
                    i = (y * w + x) * 4
                    c = pixels[imgname][i:i + 3]
                else:
                    c = base
                lp[col] = (c[0], c[1], c[2], 1.0)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
        parts.append(Part(ob.name, bm))
    for ob in new:
        bpy.data.objects.remove(ob)
    return parts


def face_color(f, layer) -> tuple:
    r = g = b = 0.0
    for lp in f.loops:
        c = lp[layer]
        r += c[0]
        g += c[1]
        b += c[2]
    n = len(f.loops)
    return (r / n, g / n, b / n)


def faded(c, sat: float, val: float) -> tuple:
    h, s, v = colorsys.rgb_to_hsv(*c)
    return colorsys.hsv_to_rgb(h, s * sat, v * val)


def mix(a, b, t: float) -> tuple:
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))


DIRT = (0.05, 0.04, 0.032)
RUST = (0.17, 0.075, 0.032)
SOOT = (0.018, 0.017, 0.016)


def weather_corner(c, p: Vector, low_ref: float, low_span: float, seed: int, cfg: dict, hot=None, up: float = 0.0) -> tuple:
    """Tek köşe rengini yıprat: soldur, kir (alt kenar, kemerler), pas lekesi."""
    out = faded(c, cfg["sat"], cfg["val"])
    if cfg.get("burned"):
        out = mix(SOOT, faded(c, 0.2, 0.1), 0.15)
    n1 = vnoise(p * 2.2, seed)
    out = tuple(max(0.0, ch * (0.8 + 0.4 * n1)) for ch in out)
    low = 1.0 - smoothstep(low_ref, low_ref + low_span, p.z)
    near = hot if hot is not None else 0.0
    dirt_w = min(1.0, (0.2 + low * 0.85 + near * 0.8 + 0.6 * max(0.0, up)) * (0.55 + 0.9 * vnoise(p * 3.1, seed + 3)))
    rust_n = smoothstep(0.52, 0.72, vnoise(p * 3.8, seed + 7))
    rust_w = min(1.0, rust_n * (0.25 + 0.75 * max(low, near)) * cfg["rust"])
    out = mix(out, DIRT, dirt_w * 0.75)
    out = mix(out, RUST if not cfg.get("burned") else (0.045, 0.022, 0.012), rust_w * (1.0 if not cfg.get("burned") else 0.5))
    return out


def dent(parts: list, center: Vector, direction: Vector, radius: float, depth: float) -> None:
    """Konum tabanlı çökme: aynı konumdaki köşeler aynı kayar, ağ yırtılmaz."""
    d = direction.normalized()
    for part in parts:
        for v in part.bm.verts:
            dist = (v.co - center).length
            if dist < radius:
                k = 1.0 - (dist / radius) ** 2
                v.co += d * (depth * k * k)


def count_tris(parts: list) -> int:
    return sum(len(f.verts) - 2 for p in parts for f in p.bm.faces)


def write_glb(parts: list, path: str, mat_names: dict) -> None:
    """parts -> tek nesne, malzeme dizini face.material_index ile; GLB yaz. mat_names: indeks -> ad."""
    mats = make_materials()
    bm = bmesh.new()
    col = bm.loops.layers.float_color.new("Col")
    for part in parts:
        src = part.bm.loops.layers.float_color["Col"]
        mp = {}
        for v in part.bm.verts:
            mp[v] = bm.verts.new(v.co)
        for f in part.bm.faces:
            nf = bm.faces.new([mp[v] for v in f.verts])
            nf.material_index = f.material_index
            for a, b in zip(f.loops, nf.loops):
                b[col] = a[src]
    me = bpy.data.meshes.new("prop")
    bm.normal_update()
    bm.to_mesh(me)
    for i in sorted(mat_names):
        me.materials.append(mats[mat_names[i]])
    me.polygons.foreach_set("use_smooth", [False] * len(me.polygons))
    ob = bpy.data.objects.new(path.rsplit("/", 1)[-1][:-4], me)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    kw = dict(filepath=path, export_format="GLB", use_selection=True, export_apply=True, export_yup=True)
    try:
        bpy.ops.export_scene.gltf(export_vertex_color="MATERIAL", **kw)
    except TypeError:
        bpy.ops.export_scene.gltf(**kw)
    bpy.data.objects.remove(ob)
