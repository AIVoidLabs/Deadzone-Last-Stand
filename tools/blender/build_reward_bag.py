"""Ödül çantası (11.6): kristal dolu, ağzı iple bağlı bez çanta. Para ve XP türü aynı model; kristal rengi oyunda tint.

Blender MCP ile çalıştırılır ya da: blender --background --python tools/blender/build_reward_bag.py -- [--export]
Çıktı: assets/models/props/reward_bag.glb. Malzemeler: BagCloth, BagRope, BagTint (kristaller; oyunda tür rengi bu yüzeye, BagVisual).
"""
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Vector, Matrix

try:
    ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
except NameError:
    ROOT = r"C:/Users/pekta/projeler/Deadzone-Last-Stand"
OUT = ROOT + "/assets/models/props/reward_bag.glb"
COL = "COL_RewardBag"
SEED = 7

# Profil: (z, yarıçap) — dipte basık, karında şişkin, boyunda daralan, ağızda açılan.
PROFILE = [(0.0, 0.0), (0.02, 0.17), (0.07, 0.25), (0.16, 0.29), (0.26, 0.28), (0.34, 0.22),
           (0.40, 0.12), (0.43, 0.10), (0.47, 0.17), (0.52, 0.23)]
SEGMENTS = 18
CLOTH = (0.22, 0.15, 0.08)  # doğrusal renk: koyu kanvas
ROPE = (0.40, 0.28, 0.12)
CRYSTAL = (1.0, 0.5, 0.08)  # para türü önizleme rengi (oyunda tint)
CRYSTALS = [  # (açı derece, eğim derece, uzunluk, kalınlık, merkezden uzaklık); üstten kamerada küme okunur
    (0, 6, 0.36, 0.07, 0.02), (60, 30, 0.28, 0.06, 0.09), (120, 24, 0.30, 0.062, 0.08),
    (180, 34, 0.26, 0.055, 0.10), (240, 26, 0.29, 0.06, 0.09), (300, 32, 0.25, 0.055, 0.10),
    (30, 48, 0.20, 0.045, 0.14), (210, 50, 0.19, 0.045, 0.14),
]


def clear():
    col = bpy.data.collections.get(COL)
    if col:
        for o in list(col.objects):
            bpy.data.objects.remove(o, do_unlink=True)
    else:
        col = bpy.data.collections.new(COL)
        bpy.context.scene.collection.children.link(col)
    return col


def mat(name, color, emit=0.0, rough=0.85):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Roughness"].default_value = rough
    if emit > 0.0:
        b.inputs["Emission Color"].default_value = (*color, 1.0)
        b.inputs["Emission Strength"].default_value = emit
    return m


def link(col, name, me, m):
    o = bpy.data.objects.new(name, me)
    col.objects.link(o)
    me.materials.append(m)
    return o


def sack(col, rng):
    bm = bmesh.new()
    rings = []
    for i, (z, r) in enumerate(PROFILE):
        ring = []
        for s in range(SEGMENTS):
            a = s / SEGMENTS * math.tau
            fold = 1.0 + 0.05 * math.sin(a * 5 + i * 1.7) + 0.03 * math.sin(a * 3 - i) + rng.uniform(-0.03, 0.03)
            if i == len(PROFILE) - 1:
                fold += 0.12 * math.sin(a * 7)  # ağız fırfırı
            zz = z + (0.02 * math.sin(a * 6) if i >= len(PROFILE) - 2 else 0.0)
            ring.append(bm.verts.new((math.cos(a) * r * fold, math.sin(a) * r * fold, zz)) if r > 0 else None)
        rings.append(ring)
    bottom = bm.verts.new((0, 0, 0))
    r1 = rings[1]
    for s in range(SEGMENTS):
        bm.faces.new((bottom, r1[(s + 1) % SEGMENTS], r1[s]))
    for i in range(1, len(rings) - 1):
        a_, b_ = rings[i], rings[i + 1]
        for s in range(SEGMENTS):
            n = (s + 1) % SEGMENTS
            bm.faces.new((a_[s], a_[n], b_[n], b_[s]))
    me = bpy.data.meshes.new("bag_sack")
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    o = link(col, "bag_sack", me, mat("BagCloth", CLOTH))
    sol = o.modifiers.new("thick", "SOLIDIFY")
    sol.thickness = 0.015
    sub = o.modifiers.new("smooth", "SUBSURF")
    sub.levels = 1
    sub.render_levels = 1
    for p in me.polygons:
        p.use_smooth = True
    return o


def rope(col):
    bpy.ops.mesh.primitive_torus_add(major_radius=0.115, minor_radius=0.022, major_segments=20, minor_segments=6,
                                     location=(0, 0, 0.415))
    o = bpy.context.active_object
    for c in o.users_collection:
        c.objects.unlink(o)
    col.objects.link(o)
    o.name = "bag_rope"
    o.data.materials.append(mat("BagRope", ROPE))
    # sarkan ip ucu
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.016, depth=0.16, location=(0.12, 0.03, 0.36),
                                        rotation=(0.2, 0.5, 0))
    t = bpy.context.active_object
    for c in t.users_collection:
        c.objects.unlink(t)
    col.objects.link(t)
    t.name = "bag_rope_tail"
    t.data.materials.append(mat("BagRope", ROPE))
    for ob in (o, t):
        for p in ob.data.polygons:
            p.use_smooth = True
    return [o, t]


def belly_strap(col):
    """Karnı saran kayış: yukarıdan bakınca siluete çizgi verir."""
    bpy.ops.mesh.primitive_torus_add(major_radius=0.30, minor_radius=0.02, major_segments=24, minor_segments=4,
                                     location=(0, 0, 0.21))
    o = bpy.context.active_object
    for c in o.users_collection:
        c.objects.unlink(o)
    col.objects.link(o)
    o.name = "bag_strap"
    o.data.materials.append(mat("BagRope", ROPE))
    return o


def crystal(col, i, ang, tilt, length, thick, off):
    bm = bmesh.new()
    sides = 6
    base, mid = [], []
    for s in range(sides):
        a = s / sides * math.tau
        base.append(bm.verts.new((math.cos(a) * thick * 0.8, math.sin(a) * thick * 0.8, 0)))
        mid.append(bm.verts.new((math.cos(a) * thick, math.sin(a) * thick, length * 0.65)))
    tip = bm.verts.new((0, 0, length))
    bm.faces.new(list(reversed(base)))
    for s in range(sides):
        n = (s + 1) % sides
        bm.faces.new((base[s], base[n], mid[n], mid[s]))
        bm.faces.new((mid[s], mid[n], tip))
    me = bpy.data.meshes.new(f"bag_crystal_{i}")
    bm.to_mesh(me)
    bm.free()
    o = link(col, f"bag_crystal_{i}", me, mat("BagTint", CRYSTAL, emit=1.8, rough=0.2))
    a = math.radians(ang)
    o.location = (math.cos(a) * off, math.sin(a) * off, 0.36)
    o.rotation_euler = (0, math.radians(tilt), a)
    return o


def build():
    rng = random.Random(SEED)
    col = clear()
    parts = [sack(col, rng)] + rope(col) + [belly_strap(col)]
    parts += [crystal(col, i, *c) for i, c in enumerate(CRYSTALS)]
    return col, parts


def export(parts):
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_apply=True)


if __name__ == "__main__":
    _col, _parts = build()
    if "--export" in sys.argv:
        export(_parts)
