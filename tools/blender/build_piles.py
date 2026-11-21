"""Karanlık yığın propları (8.1g): çöp yığını, moloz, kum torbası hattı, lastik yığını. Hepsi betikle, low-poly.

blender --background --python tools/blender/build_piles.py -- [ad ...]
Çıktı: assets/models/world/props/<ad>.glb (build_props.py ile aynı malzeme hattı: wreck_body + köşe rengi).
Z yukarı, ölçek metre; seed'li. Yeni yığın = BUILDERS'a bir fonksiyon.
"""
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import wreck_kit as wk  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT = ROOT + "/assets/models/world/props/"

# koyu, kirli renk dizileri (lineer; bina A tonlarıyla uyumlu)
BAG_COLORS = [(0.012, 0.02, 0.014), (0.008, 0.009, 0.008), (0.018, 0.026, 0.016), (0.01, 0.014, 0.012)]
CARDBOARD = [(0.07, 0.05, 0.03), (0.055, 0.04, 0.026)]
CONCRETE = [(0.075, 0.075, 0.08), (0.055, 0.056, 0.06), (0.09, 0.088, 0.085)]
BRICK = [(0.085, 0.032, 0.022), (0.065, 0.026, 0.02)]
SANDBAG = [(0.1, 0.085, 0.055), (0.075, 0.07, 0.045), (0.085, 0.08, 0.06)]
TIRE = [(0.012, 0.012, 0.013), (0.02, 0.02, 0.022)]


def new_part(name: str) -> wk.Part:
    bm = bmesh.new()
    bm.loops.layers.float_color.new("Col")
    return wk.Part(name, bm)


def paint(part: wk.Part, faces, color, rng, var=0.25) -> None:
    lay = part.bm.loops.layers.float_color["Col"]
    k = 1.0 + rng.uniform(-var, var)
    for f in faces:
        up = max(0.0, f.normal.z)
        for lp in f.loops:
            c = [min(1.0, ch * k * (0.8 + 0.35 * up)) for ch in color]
            lp[lay] = (*c, 1.0)


def add_geom(part: wk.Part, build, matrix: Matrix, color, rng, var=0.25) -> list:
    """build(bm) -> geom üretir; matrix ile yerleştirilir, renklenir."""
    before = set(part.bm.faces)
    build(part.bm)
    new = [f for f in part.bm.faces if f not in before]
    verts = {v for f in new for v in f.verts}
    bmesh.ops.transform(part.bm, matrix=matrix, verts=list(verts))
    paint(part, new, color, rng, var)
    return new


def jitter(part: wk.Part, faces, rng, amt: float) -> None:
    for v in {v for f in faces for v in f.verts}:
        v.co += Vector((rng.uniform(-amt, amt), rng.uniform(-amt, amt), rng.uniform(-amt, amt)))


def box(bm) -> None:
    bmesh.ops.create_cube(bm, size=1.0)


def ico(bm) -> None:
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.5)


def xf(loc, rot=(0, 0, 0), scl=(1, 1, 1)) -> Matrix:
    m = Matrix.Translation(Vector(loc)) @ Matrix.Rotation(rot[2], 4, "Z") @ Matrix.Rotation(rot[1], 4, "Y") @ Matrix.Rotation(rot[0], 4, "X")
    return m @ Matrix.Diagonal((*scl, 1.0))


def trash_pile(seed: int, bags: int, boxes: int) -> list:
    rng = random.Random(seed)
    part = new_part("trash")
    placed = []
    for i in range(bags):
        r = 0.25 + 0.55 * (i / max(1, bags - 1)) if i else 0.0
        a = rng.uniform(0, math.tau) + i * 2.4
        x, y = math.cos(a) * r * 0.9, math.sin(a) * r * 0.7
        h = 0.36 + 0.1 * rng.random()
        z = max(0.0, 0.5 - r * 0.45) * 0.55 if i < bags - 1 else 0.0
        if i == 0:
            z = 0.0
        s = (rng.uniform(0.62, 0.8), rng.uniform(0.55, 0.72), h)
        faces = add_geom(part, ico, xf((x, y, s[2] * 0.5 + z), (0, 0, rng.uniform(0, 3))), rng.choice(BAG_COLORS)
                         , rng, 0.3)
        verts = {v for f in faces for v in f.verts}
        c = Vector((x, y, s[2] * 0.5 + z))
        for v in verts:
            d = v.co - c
            v.co = c + Vector((d.x * s[0], d.y * s[1], d.z * s[2]))
        jitter(part, faces, rng, 0.035)
        # düğüm: tepede küçük koni
        add_geom(part, ico, xf((x, y, s[2] + z + 0.02), (0, 0, 0), (0.12, 0.12, 0.14)), rng.choice(BAG_COLORS), rng, 0.2)
        placed.append((x, y, z + s[2]))
    for i in range(boxes):
        a = rng.uniform(0, math.tau)
        x, y = math.cos(a) * rng.uniform(0.5, 0.85), math.sin(a) * rng.uniform(0.4, 0.65)
        s = (rng.uniform(0.45, 0.7), rng.uniform(0.35, 0.55), rng.uniform(0.12, 0.28))
        faces = add_geom(part, box, xf((x, y, s[2] * 0.5), (0, 0, rng.uniform(0, 3.1)), s), rng.choice(CARDBOARD), rng, 0.2)
        jitter(part, faces, rng, 0.02)
    return [part]


def rubble_pile() -> list:
    rng = random.Random(41)
    part = new_part("rubble")
    for i in range(16):
        r = rng.uniform(0.0, 1.0) ** 0.8 * 1.25
        a = rng.uniform(0, math.tau)
        x, y = math.cos(a) * r, math.sin(a) * r * 0.75
        peak = max(0.0, 1.0 - r / 1.35)
        z0 = peak * 0.55
        s = (rng.uniform(0.28, 0.6), rng.uniform(0.25, 0.5), rng.uniform(0.18, 0.4))
        col = rng.choice(BRICK + CONCRETE + CONCRETE)
        faces = add_geom(part, box, xf((x, y, z0 + s[2] * 0.5), (rng.uniform(-0.5, 0.5), rng.uniform(-0.5, 0.5), rng.uniform(0, 3)), s), col, rng, 0.3)
        jitter(part, faces, rng, 0.05)
    for i in range(3):   # çıkık paslı donatı çubukları
        a = rng.uniform(0, math.tau)
        add_geom(part, box, xf((math.cos(a) * 0.3, math.sin(a) * 0.25, 0.65), (rng.uniform(-0.7, 0.7), rng.uniform(-0.7, 0.7), a), (0.04, 0.04, 0.9)),
                 (0.09, 0.04, 0.02), rng, 0.2)
    return [part]


def sandbag_wall() -> list:
    rng = random.Random(53)
    part = new_part("sandbags")
    length, courses = 3.6, 3
    bag_l, bag_w, bag_h = 0.6, 0.42, 0.27
    for c in range(courses):
        n = int(length / bag_l) - (c % 2)
        x0 = -length / 2 + bag_l / 2 + (0.5 * bag_l if c % 2 else 0.0) + (0.0 if c % 2 else 0.0)
        for i in range(n):
            x = x0 + i * bag_l + rng.uniform(-0.02, 0.02)
            if c == courses - 1 and rng.random() < 0.3:
                continue   # üst sıra eksik torbalar: yıkık görünüm
            s = (bag_l * rng.uniform(0.92, 1.02), bag_w * rng.uniform(0.92, 1.05), bag_h * rng.uniform(0.9, 1.1))
            faces = add_geom(part, box, xf((x, rng.uniform(-0.02, 0.02), bag_h * (c + 0.5)), (0, 0, rng.uniform(-0.06, 0.06)), s),
                             rng.choice(SANDBAG), rng, 0.2)
            # yumuşat: üst köşeleri içeri al (torba görünümü)
            for v in {v for f in faces for v in f.verts}:
                if v.co.z > bag_h * (c + 0.5):
                    v.co.x *= 0.9
                    v.co.y *= 0.88
            jitter(part, faces, rng, 0.012)
    return [part]


def tire_stack() -> list:
    rng = random.Random(61)
    part = new_part("tires")

    def tire(bm) -> None:
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=12, radius1=0.36, radius2=0.36, depth=0.22)

    for i in range(4):
        faces = add_geom(part, tire, xf((rng.uniform(-0.04, 0.04), rng.uniform(-0.04, 0.04), 0.11 + i * 0.22), (0, 0, rng.uniform(0, 3))),
                         rng.choice(TIRE), rng, 0.3)
        for f in faces:
            if f.normal.z > 0.9 or f.normal.z < -0.9:   # kapak: içe göçük (jant boşluğu)
                for v in f.verts:
                    v.co.x *= 0.62
                    v.co.y *= 0.62
    return [part]


BUILDERS = {
    "trash_pile_a": lambda: trash_pile(5, 6, 2),
    "trash_pile_b": lambda: trash_pile(9, 4, 3),
    "rubble_pile": rubble_pile,
    "sandbag_wall": sandbag_wall,
    "tire_stack": tire_stack,
}


def main() -> None:
    names = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    os.makedirs(OUT, exist_ok=True)
    for name, fn in BUILDERS.items():
        if names and name not in names:
            continue
        wk.reset_scene()
        parts = fn()
        lo = min(p.bounds()[0].z for p in parts)
        for part in parts:
            for v in part.bm.verts:
                v.co.z -= lo
        wk.write_glb(parts, OUT + name + ".glb", {0: "wreck_body"})
        los = [min(p.bounds()[0][i] for p in parts) for i in range(3)]
        his = [max(p.bounds()[1][i] for p in parts) for i in range(3)]
        print("PROP", name, "tris", wk.count_tris(parts), "size_xyz", [round(his[i] - los[i], 2) for i in range(3)])


main()
