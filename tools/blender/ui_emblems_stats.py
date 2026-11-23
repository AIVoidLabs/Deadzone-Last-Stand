"""İstatistik amblemleri (11): stat_<StatData id>.png — bizim dünyamızdan, güçlü siluetli çizgi roman çizimleri.

Çalıştırma (repo kökünden):
    blender --background --python tools/blender/ui_emblems_stats.py [-- max_hp damage ...]
Çıktı: assets/textures/ui/emblems/stat_<id>.png (512x512 saydam) + build/shots/emblems_stats.png (kontak).
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ui_ink as U  # noqa: E402
from mathutils import Vector  # noqa: E402


def aim(obj, direction: tuple, up_axis: str = "Y") -> None:
    """Nesnenin +Z ekseni direction yönüne baksın."""
    obj.rotation_mode = "XYZ"
    obj.rotation_euler = Vector(direction).normalized().to_track_quat("Z", up_axis).to_euler()


def new_objs(before: set) -> list:
    return [o for o in U.meshes() if o.name not in before]


def surf_y(ellipsoids: list, x: float, z: float) -> float:
    """Elipsoid birleşiminin ön (-Y) yüzeyinin y'si (damar/dikiş yerleştirmek için yaklaşık)."""
    best = 0.0
    for (cx, cy, cz), (rx, ry, rz) in ellipsoids:
        t = 1.0 - ((x - cx) / rx) ** 2 - ((z - cz) / rz) ** 2
        if t > 0.0:
            best = min(best, cy - ry * math.sqrt(t))
    return best



def ribbon(k: U.Kit, pts: list, width: float, thick: float, m: str, y: float = 0.0, pointy: float = 0.8) -> object:
    """Yassı, sivri uçlu şerit (kâğıt kesimi alev): XZ düzleminde yol, y'de ince kalınlık."""
    n = len(pts)
    verts: list = []
    faces: list = []
    for i, (x, z) in enumerate(pts):
        a = pts[max(0, i - 1)]
        b = pts[min(n - 1, i + 1)]
        dx, dz = b[0] - a[0], b[1] - a[1]
        ln = math.hypot(dx, dz) or 1.0
        nx, nz = -dz / ln, dx / ln
        t = i / (n - 1)
        w = width * (0.55 + 0.45 * math.sin(math.pi * min(1.0, t * 1.6))) * (1.0 - t) ** pointy
        for (sgn, yy) in ((1, -thick), (-1, -thick), (-1, thick), (1, thick)):
            verts.append((x + nx * w * sgn, y + yy, z + nz * w * sgn))
        if i > 0:
            p, q = (i - 1) * 4, i * 4
            for j in range(4):
                faces.append((p + j, q + j, q + (j + 1) % 4, p + (j + 1) % 4))
    faces += [(0, 1, 2, 3), (4 * n - 1, 4 * n - 2, 4 * n - 3, 4 * n - 4)]
    return k.mesh(verts, faces, m)


# ------------------------------------------------------------------------------------------ max_hp

HEART: list = [((-0.22, 0.0, 0.20), (0.34, 0.30, 0.30)), ((0.20, 0.0, 0.22), (0.32, 0.29, 0.29)),
               ((0.0, 0.0, -0.08), (0.48, 0.34, 0.42)), ((0.02, 0.0, -0.36), (0.26, 0.24, 0.30)),
               ((0.0, 0.0, -0.52), (0.12, 0.12, 0.16))]


def stat_max_hp(k: U.Kit) -> dict:
    k.m["flesh"] = U.mat("flesh2", (0.50, 0.05, 0.07), 0.25)
    before = {o.name for o in U.meshes()}
    k.blob([(c, r, False) for c, r in HEART], "flesh", 0.022)
    # kaslı yüzey: tepeden uca inen koyu kas lifleri
    for fx in (-0.36, -0.2, -0.04, 0.12, 0.28):
        pts = []
        for i in range(8):
            t = i / 7
            x = fx * (1 - t * 0.8) - 0.06 * t
            z = 0.42 - t * 0.95
            pts.append((x, surf_y(HEART, x, z) - 0.012, z))
        k.tube(pts, 0.014, "vein", 0.6, 6)
    # sağ/sol kulakçık ve yağ
    k.ball((0.40, -0.02, 0.30), (0.16, 0.15, 0.20), "flesh")
    k.ball((-0.40, -0.04, 0.34), (0.14, 0.13, 0.17), "vein")
    k.ball((0.0, -0.12, 0.50), (0.18, 0.10, 0.07), "fat")
    # aort kavsi + dallar, akciğer atardamarı, ana toplardamar
    k.tube([(-0.02, 0.02, 0.35), (-0.02, 0.0, 0.70), (-0.18, 0.0, 0.92), (-0.42, 0.0, 0.78), (-0.48, 0.0, 0.50)], 0.10, "flesh", 0.8)
    for (x0, z0, x1, z1) in ((-0.10, 0.88, -0.05, 1.15), (-0.20, 0.92, -0.28, 1.12), (-0.30, 0.88, -0.45, 1.05)):
        k.tube([(x0, 0.0, z0), ((x0 + x1) / 2, 0.0, (z0 + z1) / 2 + 0.03), (x1, 0.0, z1)], 0.032, "flesh", 0.7)
    k.tube([(-0.10, -0.12, 0.38), (-0.25, -0.16, 0.68), (-0.5, -0.1, 0.84)], 0.07, "navy", 0.9)
    k.tube([(0.40, 0.0, 0.40), (0.46, 0.02, 0.75), (0.40, 0.0, 1.0)], 0.075, "vein", 0.95)
    for (x0, z0, x1, z1) in ((0.44, 0.90, 0.62, 1.05), (0.42, 0.95, 0.30, 1.12)):
        k.tube([(x0, 0.0, z0), (x1, 0.0, z1)], 0.025, "vein", 0.6)
    # koroner damar ağacı
    for pts in ([(-0.02, 0.38), (-0.10, 0.16), (-0.14, -0.10), (-0.10, -0.32), (-0.04, -0.52)],
                [(0.20, 0.40), (0.26, 0.20), (0.22, -0.04), (0.12, -0.26)],
                [(-0.10, 0.16), (-0.32, 0.20), (-0.46, 0.04)], [(-0.14, -0.10), (-0.36, -0.14), (-0.44, -0.30)],
                [(0.26, 0.20), (0.44, 0.10)], [(0.22, -0.04), (0.38, -0.16)]):
        k.tube([(x, surf_y(HEART, x, z) - 0.012, z) for x, z in pts], 0.020, "navy" if pts[0][0] > 0.1 else "vein", 0.7, 6)
    # dikişli yarık + zımbalar
    p0, p1 = (0.14, 0.12), (-0.02, -0.30)
    n = 9
    path = []
    for i in range(n):
        t = i / (n - 1)
        x, z = p0[0] + (p1[0] - p0[0]) * t, p0[1] + (p1[1] - p0[1]) * t
        path.append((x + 0.012 * math.sin(i * 2.0), surf_y(HEART, x, z) - 0.02, z))
    k.tube(path, 0.028, "dark", 1.0, 8)
    ang = -math.degrees(math.atan2(p1[1] - p0[1], p1[0] - p0[0]))
    for i in range(1, n - 1):
        x, y, z = path[i]
        k.bx((x, y - 0.022, z), (0.20, 0.016, 0.018), "bone", rot=(0, ang + 90 + (6 if i % 2 else -6), 0), bev=0.004)
        if i in (2, 4, 6):
            k.bx((x, y - 0.045, z), (0.16, 0.014, 0.020), "steel", rot=(0, ang + 90, 0), bev=0.004)
            for sgn in (-1, 1):
                dx = math.cos(math.radians(-ang - 90)) * 0.08 * sgn
                dz = -math.sin(math.radians(-ang - 90)) * 0.08 * sgn
                k.bx((x + dx, y - 0.032, z + dz), (0.012, 0.030, 0.012), "steel", bev=0.002)
    for (x, z, s) in ((0.06, -0.50, 1.0), (-0.16, -0.58, 0.7), (0.20, -0.34, 0.55), (-0.30, -0.45, 0.5)):
        k.ball((x, surf_y(HEART, x, z) - 0.02, z - 0.16 * s), (0.04 * s, 0.04 * s, 0.075 * s), "glowred")
    objs = [o for o in U.meshes() if o.name not in before]
    U.group_transform(objs, (0, 0, 0), (0, 22, 0), 1.0)
    return dict(az=-10, el=10, lens=55, roll=0, fill=0.92)

# ------------------------------------------------------------------------------------------ damage

HEAD: list = [((0.0, 0.0, 0.10), (0.44, 0.48, 0.52)), ((0.0, -0.12, -0.36), (0.30, 0.30, 0.22)),
              ((-0.24, -0.20, -0.16), (0.15, 0.15, 0.15)), ((0.24, -0.20, -0.16), (0.15, 0.15, 0.15)),
              ((0.0, -0.32, 0.14), (0.38, 0.14, 0.11))]


def stat_damage(k: U.Kit) -> dict:
    # sağ yarı çürük et, sol yarı kafatası
    k.m["rot"] = U.mat("rot2", (0.40, 0.18, 0.20), 0.5)
    flesh = [(c, r, False) for c, r in HEAD if c[0] >= -0.05]
    flesh += [((0.0, 0.0, 0.10), (0.30, 0.46, 0.50), False), ((0.17, -0.40, 0.04), (0.10, 0.10, 0.10), True),
              ((0.0, -0.46, -0.12), (0.05, 0.08, 0.07), True)]
    k.blob(flesh, "skin", 0.024)
    bone = [((-0.20, 0.0, 0.12), (0.30, 0.47, 0.52), False), ((-0.14, -0.32, 0.14), (0.26, 0.14, 0.11), False),
            ((-0.24, -0.20, -0.14), (0.15, 0.15, 0.15), False), ((-0.17, -0.40, 0.04), (0.11, 0.11, 0.11), True)]
    k.blob(bone, "bone", 0.024)
    # açık çene (aşağı sarkık) + dişler
    k.blob([((0.0, -0.20, -0.62), (0.28, 0.26, 0.14), False), ((-0.18, -0.12, -0.52), (0.1, 0.12, 0.1), False),
            ((0.18, -0.12, -0.52), (0.1, 0.12, 0.1), False)], "rot", 0.024)
    k.bx((0.0, -0.40, -0.42), (0.30, 0.08, 0.16), "dark", bev=0.01)
    for i in range(7):
        x = -0.15 + i * 0.05
        k.bx((x, -0.47, -0.34), (0.036, 0.04, 0.085), "bone", bev=0.006)
        k.bx((x, -0.45, -0.50), (0.034, 0.04, 0.07), "bone", bev=0.006)
        k.bx((x, -0.38, -0.50), (0.034, 0.04, 0.07), "bone", bev=0.006)
    # gözler: sol boş yuva, sağ parlayan
    k.ball((-0.18, -0.45, 0.04), (0.11, 0.07, 0.11), "dark")
    k.ball((0.17, -0.43, 0.04), (0.085, 0.06, 0.085), "dark")
    k.ball((0.17, -0.47, 0.04), (0.05, 0.04, 0.05), "glowred")
    # alında tek kurşun deliği
    hx, hz = 0.0, 0.38
    hy = surf_y(HEAD, hx, hz)
    k.tb((hx, hy - 0.004, hz), 0.085, 0.03, "dark", axis="Y", segs=16)
    k.ring((hx, hy - 0.014, hz), 0.092, 0.024, "glowred", rot=(90, 0, 0))
    for a in (20, 100, 190, 280, 330):
        ra = math.radians(a)
        k.bx((hx + math.cos(ra) * 0.15, hy - 0.016, hz + math.sin(ra) * 0.15), (0.14, 0.008, 0.012), "dark", rot=(0, -a, 0), bev=0.001)
    # arkadan fışkıran kan ve kemik
    for i, (dx, dy, dz, m, s) in enumerate([(0.1, 0.1, 0.2, "bone", 0.06), (0.3, 0.3, 0.45, "glowred", 0.05), (0.5, 0.15, 0.1, "bone", 0.05),
                                           (0.2, 0.5, -0.1, "flesh", 0.06), (0.6, 0.35, 0.35, "flesh", 0.045), (0.0, 0.6, 0.5, "bone", 0.045)]):
        k.bx((0.1 + dx, 0.42 + dy, 0.30 + dz), (s * 2, s * 1.4, s * 1.3), m, rot=(30 * i, 20 * i, 10 * i), bev=0.004)
    for (a, r, ln) in ((0, 0.12, 0.9), (25, 0.08, 0.7), (-25, 0.09, 0.8), (50, 0.06, 0.6)):
        sp = k.lathe([(0.0, 0.0), (r, 0.05), (r * 0.5, ln * 0.6), (0.0, ln)], (0, 0, 0), "flesh", segs=8)
        aim(sp, (0.5 + 0.4 * math.sin(math.radians(a)), 1.0, 0.45 + 0.4 * math.cos(math.radians(a))))
        sp.location = (0.08, 0.42, 0.32)
    # yanda uçan mermi
    sc = 1.5
    for prof, m in (([(0.0, 0.0), (0.085, 0.0), (0.088, 0.14), (0.078, 0.30), (0.05, 0.44), (0.0, 0.52)], "copper"),
                    ([(0.0, -0.30), (0.095, -0.30), (0.100, -0.28), (0.092, -0.20), (0.088, 0.0)], "brass")):
        o = k.lathe([(r * sc, z * sc) for r, z in prof], (0, 0, 0), m, segs=24)
        aim(o, (0.05, 1.0, 0.15))
        o.location = (0.0, 1.25, 0.45)
    for off in (-0.12, 0.0, 0.12):
        k.tube([(off, 0.75, 0.40 + off), (off * 0.8, 1.0, 0.42 + off), (0.0, 1.15, 0.45 + off)], 0.012, "white", 0.2, 6)
    return dict(az=-45, el=8, lens=52, roll=0, fill=0.92)

# ------------------------------------------------------------------------------------------ fire_rate

def stat_fire_rate(k: U.Kit) -> dict:
    k.tb((0, 0.30, 0), 0.52, 0.60, "metal", axis="Y", segs=32)
    for i in range(5):
        k.tb((0, 0.04 + i * 0.12, 0), 0.545, 0.03, "dark", axis="Y", segs=32)
    k.tb((0, 0.72, 0), 0.26, 0.20, "steel", axis="Y", segs=24)
    k.bx((0, 0.30, 0.55), (0.40, 0.50, 0.16), "navy", bev=0.02)
    k.tb((0, -0.05, 0), 0.66, 0.06, "steel", axis="Y", segs=32)
    for i in range(6):
        a = math.radians(i * 60 + 10)
        x, z = math.cos(a) * 0.36, math.sin(a) * 0.36
        k.tb((x, -0.50, z), 0.12, 0.85, "metal", axis="Y", segs=16)
        k.tb((x, -0.95, z), 0.125, 0.40, "orange", axis="Y", segs=16)
        k.tb((x, -1.17, z), 0.13, 0.28, "glowred", axis="Y", segs=16)
        k.tb((x, -1.32, z), 0.14, 0.03, "ember", axis="Y", segs=16)
        k.tb((x, -1.34, z), 0.07, 0.01, "dark", axis="Y", segs=12)
    for y, r in ((-0.30, 0.60), (-0.62, 0.60), (-0.88, 0.57)):
        k.tb((0, y, 0), r, 0.08, "steel", axis="Y", segs=32)
        k.tb((0, y, 0), r + 0.015, 0.035, "dark", axis="Y", segs=32)
    k.tb((0, 0.0, 0), 0.14, 1.0, "dark", axis="Y", segs=12)
    # yıldız biçimli namlu alevi
    for i in range(12):
        a = math.radians(i * 30)
        ln = 1.1 if i % 2 == 0 else 0.65
        sp = k.lathe([(0.0, 0.0), (0.10, 0.03), (0.0, ln)], (0, 0, 0), "yellow" if i % 2 == 0 else "ember", segs=6)
        aim(sp, (0.8 * math.cos(a), -0.9, 0.8 * math.sin(a)))
        sp.location = (0, -1.38, 0)
    k.ball((0, -1.42, 0), (0.34, 0.12, 0.34), "yellow")
    k.ball((0, -1.45, 0), (0.18, 0.09, 0.18), "white")
    # sarı parlak kovanlar
    for i, (x, y, z, rx, rz) in enumerate([(0.95, 0.10, 0.95, 20, 30), (1.25, 0.45, 0.45, 70, 10), (0.80, 0.55, 1.45, 110, 40),
                                          (1.45, -0.10, 1.2, 40, 70), (1.15, 0.25, 1.65, 80, 120)]):
        k.tb((x, y, z), 0.10, 0.34, "yellow", axis="Y", rot=(rx, 0, rz), segs=12)
        k.tb((x, y, z), 0.08, 0.08, "dark", axis="Y", rot=(rx, 0, rz), segs=10)
    return dict(az=-62, el=18, lens=45, roll=10, fill=0.93)

# ------------------------------------------------------------------------------------------ range

def stat_range(k: U.Kit) -> dict:
    body = [(0.0, -0.80), (0.20, -0.80), (0.26, -0.70), (0.22, -0.55), (0.22, 0.45), (0.27, 0.55), (0.36, 0.80),
            (0.38, 0.92), (0.33, 0.92), (0.33, 0.74), (0.0, 0.74)]
    k.lathe(body, (0, 0, 0), "metal", rot=(90, 0, 0), segs=40)
    k.ring((0, -0.93, 0), 0.355, 0.03, "steel", rot=(90, 0, 0))
    for z in (-0.35, 0.18):
        k.tb((0, z * 0 - z, 0), 0.0, 0.0, "dark") if False else None
    for yy in (0.40, -0.25):
        k.tb((0, yy, 0), 0.265, 0.10, "steel", axis="Y", segs=32)
        k.tb((0, yy, 0), 0.275, 0.03, "dark", axis="Y", segs=32)
    # taretler
    k.tb((0, 0.0, 0.31), 0.085, 0.16, "steel", axis="Z", segs=18)
    k.tb((0, 0.0, 0.40), 0.095, 0.05, "dark", axis="Z", segs=18)
    k.tb((0.31, 0.0, 0.0), 0.085, 0.16, "steel", axis="X", segs=18)
    k.tb((0.40, 0.0, 0.0), 0.095, 0.05, "dark", axis="X", segs=18)
    for i in range(6):
        a = math.radians(i * 60)
        k.bx((math.cos(a) * 0.09, 0.0, 0.40 + math.sin(a) * 0.0), (0.012, 0.012, 0.055), "edge", bev=0.001)
    # göz küresi merceğin içinde
    k.ball((0, -0.62, 0), (0.31, 0.26, 0.31), "bone")
    k.ball((0, -0.83, 0), (0.18, 0.07, 0.18), "glowred")
    k.ball((0, -0.885, 0), (0.06, 0.03, 0.14), "dark")
    for a, ln in ((0.4, 0.34), (1.9, 0.30), (3.3, 0.36), (4.6, 0.28), (5.6, 0.32)):
        pts = [(math.cos(a) * 0.30, -0.62, math.sin(a) * 0.30), (math.cos(a + 0.2) * 0.22, -0.80, math.sin(a + 0.2) * 0.22),
               (math.cos(a + 0.1) * 0.12, -0.84, math.sin(a + 0.1) * 0.12)]
        k.tube(pts, 0.012, "flesh", 0.6, 6)
    # nişangah artı + halka (camın önünde)
    k.ring((0, -0.96, 0), 0.30, 0.012, "dark", rot=(90, 0, 0))
    k.bx((0, -0.96, 0), (0.64, 0.014, 0.014), "dark", bev=0.001)
    k.bx((0, -0.96, 0), (0.014, 0.014, 0.64), "dark", bev=0.001)
    for i in range(1, 4):
        k.bx((0, -1.0, 0.1 * i), (0.07, 0.014, 0.012), "dark", bev=0.001)
        k.bx((0.1 * i, -1.0, 0), (0.012, 0.014, 0.07), "dark", bev=0.001)
    # montaj halkası
    k.bx((0, 0.05, -0.30), (0.20, 0.30, 0.12), "navy", bev=0.01)
    for sx in (-1, 1):
        k.tb((0.07 * sx, 0.05, -0.30), 0.02, 0.05, "steel", axis="Z", segs=8)
    return dict(az=-30, el=14, lens=55, roll=-8, fill=0.92)


# ------------------------------------------------------------------------------------------ move_speed

def stat_move_speed(k: U.Kit) -> dict:
    k.m["leather"] = U.mat("leather2", (0.55, 0.34, 0.18), 0.7)
    k.m["dark"] = U.mat("dark2", (0.22, 0.22, 0.24), 0.55, 0.2)
    before = {o.name for o in U.meshes()}
    k.blob([((-0.05, 0.0, 0.05), (0.26, 0.20, 0.34), False), ((-0.32, 0.0, -0.28), (0.22, 0.19, 0.20), False),
            ((0.36, 0.0, -0.34), (0.38, 0.20, 0.17), False), ((-0.05, 0.0, 0.62), (0.26, 0.20, 0.40), False),
            ((0.08, 0.0, -0.20), (0.34, 0.19, 0.24), False)], "leather", 0.022)
    k.bx((0.05, 0.0, -0.52), (1.20, 0.38, 0.11), "dark", bev=0.03)
    for i in range(7):
        k.bx((-0.5 + i * 0.17, 0.0, -0.595), (0.09, 0.40, 0.07), "metal", bev=0.012)
    k.bx((-0.45, 0.0, -0.40), (0.30, 0.38, 0.17), "metal", bev=0.02)
    k.bx((0.60, 0.0, -0.31), (0.34, 0.37, 0.24), "steel", rot=(0, 18, 0), bev=0.03)
    k.bx((0.38, 0.0, -0.18), (0.40, 0.37, 0.07), "steel", rot=(0, 32, 0), bev=0.02)
    k.bx((0.22, -0.205, -0.05), (0.62, 0.035, 0.20), "steel", rot=(0, 18, 0), bev=0.015)
    k.bx((0.12, 0.0, 0.62), (0.40, 0.42, 0.46), "steel", rot=(0, -6, 0), bev=0.03)
    k.bx((0.12, -0.22, 0.62), (0.34, 0.03, 0.12), "orange", rot=(0, -6, 0), bev=0.006)
    k.bx((-0.20, 0.0, 0.82), (0.16, 0.44, 0.34), "metal", bev=0.02)
    for z in (0.18, 0.50, 0.82):
        k.bx((-0.05, 0.0, z), (0.56, 0.44, 0.07), "leather", bev=0.01)
        k.bx((0.18, -0.225, z), (0.09, 0.03, 0.10), "gold", bev=0.006)
    objs = [o for o in U.meshes() if o.name not in before]
    U.group_transform(objs, (0, 0, 0), (0, 24, 0), 1.0)
    # topuktan geriye 3 kalın turuncu alev şeridi (eğri, sivri)
    for (dz, bend, ym) in ((0.12, 0.30, "ember"), (-0.10, 0.10, "ember"), (-0.34, -0.12, "ember")):
        path = []
        for i in range(14):
            t = i / 13
            path.append((-0.66 - t * 1.25, -0.16 + dz - t * 0.20 + bend * math.sin(t * math.pi) * 0.8))
        ribbon(k, path, 0.15, 0.02, ym, y=-0.12)
        ribbon(k, path[:10], 0.07, 0.02, "yellow", y=-0.16)
    # altta köşeli asfalt parçaları
    for (x, z, r, sg, rx, ry) in ((0.10, -1.12, 0.34, 5, 14, 8), (0.72, -1.22, 0.16, 4, 20, 30), (-0.42, -1.30, 0.14, 5, 25, 60)):
        k.tb((x, -0.05, z), r, 0.14, "dark", axis="Z", rot=(rx, ry, 20), segs=sg, bev=0.01)
        k.tb((x, -0.05, z + 0.075), r * 0.9, 0.025, "metal", axis="Z", rot=(rx, ry, 20), segs=sg)
    return dict(az=-4, el=4, lens=55, roll=0, fill=0.94)

# ------------------------------------------------------------------------------------------ armor

def pt(u: float, v: float) -> tuple:
    """Göğüs plakası yüzeyi: (u, v) in [-1,1]^2 -> dünya."""
    zt = 0.72 - 0.20 * math.exp(-(u * 2.3) ** 2)
    zb = -0.72 + 0.10 * u * u
    z = zb + (zt - zb) * (v + 1) * 0.5
    w = 0.60 - 0.14 * (1 - v) * 0.5 - 0.04 * (1 - v) * 0.5 * abs(u)
    x = u * w
    y = -0.20 * (1 - u * u) * (1 - 0.25 * v * v) - 0.05 * math.exp(-(u / 0.09) ** 2) + 0.02 * u * u
    return (x, y, z)


def stat_armor(k: U.Kit) -> dict:
    nu, nv = 40, 36
    verts = [pt(-1 + 2 * i / (nu - 1), -1 + 2 * j / (nv - 1)) for j in range(nv) for i in range(nu)]
    faces = [(j * nu + i, j * nu + i + 1, (j + 1) * nu + i + 1, (j + 1) * nu + i) for j in range(nv - 1) for i in range(nu - 1)]
    o = k.mesh(verts, faces, "navy")
    mod = o.modifiers.new("solid", "SOLIDIFY")
    mod.thickness = -0.07
    mod.offset = 1.0
    bev = o.modifiers.new("bev", "BEVEL")
    bev.width = 0.012
    bev.segments = 2
    bev.limit_method = "ANGLE"
    U.smooth_by_angle(o, 50.0)
    # kenar şeridi, perçinler
    rim = []
    for i in range(nu):
        rim.append(pt(-1 + 2 * i / (nu - 1), 1.0))
    for j in range(nv):
        rim.append(pt(1.0, 1 - 2 * j / (nv - 1)))
    outline = [pt(-1 + 2 * i / 24, 0.93) for i in range(25)]
    k.tube([(x, y - 0.03, z - 0.03) for x, y, z in outline], 0.018, "steel", 1.0, 6)
    for (u, v) in ((-0.8, 0.8), (0.8, 0.8), (-0.82, -0.2), (0.82, -0.2), (-0.5, -0.82), (0.5, -0.82), (0.0, 0.55)):
        x, y, z = pt(u, v)
        k.ball((x, y - 0.03, z), (0.032, 0.028, 0.032), "steel")
    # turuncu boya şeridi
    band = [pt(-0.95 + 0.19 * i, -0.45 + 0.07 * i * (1 if i < 5 else 1)) for i in range(11)]
    k.tube([(x, y - 0.012, z) for x, y, z in band], 0.038, "orange", 1.0, 6)
    for v in (0.35, -0.12):
        k.tube([(x, y - 0.014, z) for x, y, z in [pt(-0.96 + 0.08 * i, v) for i in range(25)]], 0.009, "dark", 1.0, 5)
    # mermi izleri + çatlaklar
    import random
    rnd = random.Random(5)
    for (u, v) in ((-0.28, 0.30), (0.34, 0.05), (-0.05, -0.30), (0.52, 0.55), (-0.60, -0.10)):
        cx, cy, cz = pt(u, v)
        k.tb((cx, cy - 0.015, cz), 0.085, 0.03, "dark", axis="Y", segs=7)
        k.ring((cx, cy - 0.030, cz), 0.100, 0.018, "steel", rot=(90, rnd.uniform(0, 40), 0))
        k.ball((cx + 0.01, cy - 0.04, cz - 0.01), (0.050, 0.032, 0.040), "metal", rot=(0, rnd.uniform(0, 90), 0), segs=8)
        for a in range(6):
            ang = rnd.uniform(0, 6.28)
            pts = []
            r = 0.10
            for s in range(5):
                r += rnd.uniform(0.08, 0.18)
                aa = ang + rnd.uniform(-0.35, 0.35)
                du, dv = math.cos(aa) * r, math.sin(aa) * r
                px, py, pz = pt(max(-1, min(1, u + du * 1.4)), max(-1, min(1, v + dv * 1.4)))
                pts.append((px, py - 0.026, pz))
            k.tube(pts, 0.016, "dark", 0.3, 6)
    return dict(az=-24, el=12, lens=55, roll=5, fill=0.92)


# ------------------------------------------------------------------------------------------ luck

def die(k: U.Kit, c: tuple, rot: tuple, top: int, front: int, side: int) -> None:
    before = {o.name for o in U.meshes()}
    k.bx((0, 0, 0), (0.62, 0.62, 0.62), "bone", bev=0.085)
    pats = {1: [(0, 0)], 2: [(-0.15, -0.15), (0.15, 0.15)], 3: [(-0.17, -0.17), (0, 0), (0.17, 0.17)],
            4: [(-0.16, -0.16), (0.16, -0.16), (-0.16, 0.16), (0.16, 0.16)],
            5: [(-0.16, -0.16), (0.16, -0.16), (0, 0), (-0.16, 0.16), (0.16, 0.16)],
            6: [(-0.16, -0.17), (0.16, -0.17), (-0.16, 0), (0.16, 0), (-0.16, 0.17), (0.16, 0.17)]}
    s = 0.31
    for (px, pz) in pats[top]:
        k.ball((px, pz, s), (0.075, 0.075, 0.03), "dark")
        k.ring((px, pz, s - 0.002), 0.078, 0.012, "rot", rot=(0, 0, 0))
    for (px, pz) in pats[front]:
        k.ball((px, -s, pz), (0.075, 0.03, 0.075), "dark")
        k.ring((px, -s - 0.002, pz), 0.078, 0.012, "rot", rot=(90, 0, 0))
    for (px, pz) in pats[side]:
        k.ball((s, px, pz), (0.03, 0.075, 0.075), "dark")
        k.ring((s - 0.002, px, pz), 0.078, 0.012, "rot", rot=(0, 90, 0))
    objs = [o for o in U.meshes() if o.name not in before]
    U.group_transform(objs, c, rot, 1.0)


def stat_luck(k: U.Kit) -> dict:
    die(k, (-0.38, 0.0, -0.18), (22, 12, -28), 5, 3, 2)
    die(k, (0.42, -0.05, 0.28), (-12, -18, 30), 6, 1, 4)
    for (x, z, r) in ((0.05, -0.62, 0.05), (0.18, -0.70, 0.035), (-0.3, -0.75, 0.04)):
        k.ball((x, -0.1, z), (r, r, r * 1.3), "flesh")
    return dict(az=-10, el=14, lens=50, roll=0, fill=0.92)


# ------------------------------------------------------------------------------------------ hp_regen

def stat_hp_regen(k: U.Kit) -> dict:
    before = {o.name for o in U.meshes()}
    k.tb((0, 0, -0.55), 0.20, 0.5, "dark", axis="Z", segs=28)  # tutamak
    for z in (-0.72, -0.62, -0.52, -0.42, -0.35):
        k.tb((0, 0, z), 0.215, 0.03, "metal", axis="Z", segs=28)
    k.bx((0, -0.20, -0.55), (0.12, 0.03, 0.26), "bone", bev=0.005)  # artı işareti
    k.bx((0, -0.20, -0.55), (0.26, 0.03, 0.10), "bone", bev=0.005)
    k.tb((0, 0, -0.84), 0.12, 0.14, "orange", axis="Z", segs=24)  # kapak/düğme
    k.tb((0, 0, -0.93), 0.09, 0.06, "steel", axis="Z", segs=20)
    # şeffaf namlu yerine kafes + parlayan sıvı
    k.tb((0, 0, 0.12), 0.155, 0.62, "glowred", axis="Z", segs=28)
    for a in range(0, 360, 60):
        ra = math.radians(a)
        k.tb((math.cos(ra) * 0.185, math.sin(ra) * 0.185, 0.12), 0.018, 0.66, "steel", axis="Z", segs=8)
    for z in (-0.17, 0.02, 0.22, 0.41):
        k.tb((0, 0, z), 0.20, 0.04, "steel", axis="Z", segs=28)
    for z in (0.05, 0.16, 0.27):
        k.bx((0.0, -0.20, z), (0.04, 0.02, 0.05), "dark", bev=0.003)
    k.tb((0, 0, 0.52), 0.215, 0.08, "metal", axis="Z", segs=28)
    k.tb((0, 0, 0.68), 0.10, 0.28, "steel", axis="Z", segs=20, r2=0.07)
    k.tb((0, 0, 0.95), 0.025, 0.42, "edge", axis="Z", segs=12, r2=0.008)  # iğne
    k.ball((0.0, 0.0, 1.20), (0.020, 0.020, 0.020), "glowred")
    objs = [o for o in U.meshes() if o.name not in before]
    U.group_transform(objs, (0, 0, 0), (0, 0, 0), 1.0)
    # damlalar
    for (x, z, s) in ((0.12, 1.10, 0.05), (0.18, 0.92, 0.035), (-0.14, 1.05, 0.03)):
        k.ball((x, 0, z), (s, s, s * 1.5), "glowred")
    k.lathe([(0.0, 0.0), (0.03, 0.02), (0.015, 0.09), (0.0, 0.13)], (0.12, 0, 1.0), "glowred", segs=12)
    return dict(az=-30, el=12, lens=55, roll=-40, fill=0.92)


# ------------------------------------------------------------------------------------------ pickup_range

def horseshoe(k: U.Kit) -> None:
    R, w, t = 0.55, 0.20, 0.20
    path = [(-R, 0.55)] + [(-R, 0.55 - i * 0.065) for i in range(1, 9)]
    path = [(-R, 0.55 - i * 0.07) for i in range(10)]
    arc = [(-R * math.cos(math.pi * i / 16), -0.1 - R * math.sin(math.pi * i / 16)) for i in range(1, 16)]
    arc = [(-R * math.cos(math.radians(a)), -0.1 - R * math.sin(math.radians(a))) for a in range(0, 181, 12)]
    path = [(-R, 0.55 - i * 0.07) for i in range(10)] + arc[1:-1] + [(R, 0.55 - (9 - i) * 0.07) for i in range(10)]
    n = len(path)
    verts: list = []
    for i, (x, z) in enumerate(path):
        if i == 0:
            dx, dz = path[1][0] - x, path[1][1] - z
        elif i == n - 1:
            dx, dz = x - path[i - 1][0], z - path[i - 1][1]
        else:
            dx, dz = path[i + 1][0] - path[i - 1][0], path[i + 1][1] - path[i - 1][1]
        ln = math.hypot(dx, dz)
        nx, nz = -dz / ln, dx / ln
        for (a, b) in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
            verts.append((x + nx * w * 0.5 * a, b * t * 0.5, z + nz * w * 0.5 * a))
    def band(i0: int, i1: int, m: str) -> None:
        vs, fs = [], []
        for i in range(i0, i1 + 1):
            for q in range(4):
                vs.append(verts[i * 4 + q])
        for i in range(i1 - i0):
            for q in range(4):
                fs.append((i * 4 + q, (i + 1) * 4 + q, (i + 1) * 4 + (q + 1) % 4, i * 4 + (q + 1) % 4))
        fs += [(0, 1, 2, 3), (len(vs) - 1, len(vs) - 2, len(vs) - 3, len(vs) - 4)]
        o = k.mesh(vs, fs, m)
        mod = o.modifiers.new("bev", "BEVEL")
        mod.width = 0.012
        mod.segments = 2
        mod.limit_method = "ANGLE"
        U.smooth_by_angle(o, 40.0)
    band(2, n - 3, "red")
    band(0, 2, "steel")
    band(n - 3, n - 1, "steel")


def stat_pickup_range(k: U.Kit) -> dict:
    horseshoe(k)
    for sx in (-1, 1):
        for z in (0.15, 0.24, 0.33):
            k.ring((0.55 * sx, 0, z), 0.135, 0.032, "copper", rot=(0, 0, 0))
        k.bx((0.55 * sx, -0.115, 0.33), (0.20, 0.02, 0.02), "dark", bev=0.002)
    # kristaller (altı köşe, çift sivri)
    prof = [(0.0, -0.20), (0.09, -0.06), (0.10, 0.10), (0.0, 0.30)]
    spots = [(-0.55, -0.05, 0.78, 8, 0), (-0.40, 0.05, 1.08, 30, 20), (-0.72, -0.1, 1.0, -25, 10),
             (0.55, 0.0, 0.76, -6, 0), (0.42, -0.05, 1.12, -30, 25), (0.70, 0.1, 0.98, 20, -15),
             (0.0, -0.1, 1.15, 5, 40), (0.05, 0.05, 0.9, -15, 20)]
    for (x, y, z, rx, rz) in spots:
        k.lathe(prof, (x, y, z), "crystal", rot=(rx, 0, rz), segs=6)
    # elektrik / çekim izleri
    for (x0, z0, x1, z1) in ((-0.40, 1.0, -0.55, 0.70), (0.42, 1.02, 0.55, 0.70), (0.0, 1.05, -0.3, 0.95),
                             (0.0, 1.05, 0.3, 0.95), (-0.72, 0.95, -0.58, 0.72)):
        pts = []
        for i in range(6):
            t = i / 5
            pts.append((x0 + (x1 - x0) * t + 0.05 * math.sin(i * 2.7), -0.12, z0 + (z1 - z0) * t + 0.03 * math.cos(i * 3.1)))
        k.tube(pts, 0.012, "white", 0.7, 5)
    return dict(az=-10, el=16, lens=55, roll=0, fill=0.92)


# ------------------------------------------------------------------------------------------ dash_cooldown

def stat_dash_cooldown(k: U.Kit) -> dict:
    before = {o.name for o in U.meshes()}
    k.ring((0, 0, 0.0), 0.56, 0.085, "steel", rot=(0, 0, 0))
    k.tb((0, 0, -0.06), 0.62, 0.12, "metal", axis="Z", segs=48)
    k.tb((0, 0, 0.0), 0.50, 0.04, "bone", axis="Z", segs=48)
    k.tb((0.10, -0.02, 0.025), 0.30, 0.03, "ember", axis="Z", segs=3, rot=(0, 0, 0))  # kırmızı bölge işareti
    for i in range(12):
        a = math.radians(i * 30)
        big = i % 3 == 0
        k.bx((math.cos(a) * 0.43, math.sin(a) * 0.43, 0.035), (0.05 if big else 0.025, 0.11 if big else 0.07, 0.025), "dark",
             rot=(0, 0, math.degrees(a) - 90), bev=0.004)
    # kırık kısım: dişli görünür
    k.tb((0.17, -0.17, 0.02), 0.22, 0.05, "dark", axis="Z", segs=24)
    k.tb((0.17, -0.17, 0.05), 0.15, 0.04, "brass", axis="Z", segs=14)
    for i in range(10):
        a = math.radians(i * 36)
        k.bx((0.17 + math.cos(a) * 0.17, -0.17 + math.sin(a) * 0.17, 0.05), (0.05, 0.07, 0.04), "brass", rot=(0, 0, math.degrees(a) - 90), bev=0.004)
    k.tb((0.17, -0.17, 0.075), 0.04, 0.04, "dark", axis="Z", segs=10)
    # akrep ve yelkovan; saniye ibresi kırık
    k.bx((-0.08, 0.14, 0.05), (0.06, 0.34, 0.03), "dark", rot=(0, 0, 30), bev=0.004)
    k.bx((-0.20, 0.06, 0.06), (0.05, 0.42, 0.03), "glowred", rot=(0, 0, 62), bev=0.004)
    k.tb((0, 0, 0.07), 0.055, 0.05, "steel", axis="Z", segs=16)
    # taç ve düğmeler
    k.tb((0, 0.70, -0.04), 0.10, 0.22, "steel", axis="Y", segs=20)
    k.tb((0, 0.84, -0.04), 0.14, 0.10, "metal", axis="Y", segs=20)
    for i in range(8):
        a = math.radians(i * 45)
        k.bx((math.cos(a) * 0.14, 0.84, -0.04 + math.sin(a) * 0.14), (0.02, 0.10, 0.02), "dark", rot=(0, 0, 0), bev=0.002)
    k.ring((0, 0.97, -0.04), 0.12, 0.025, "steel", rot=(0, 90, 0))
    for sgn in (-1, 1):
        k.tb((0.46 * sgn, 0.46, -0.04), 0.05, 0.14, "steel", axis="Y", segs=14, rot=(0, 0, -45 * sgn))
    # cam kırıkları: bezelde keskin kama
    for i, a in enumerate((20, 70, 110, 150, 205, 250, 300, 340)):
        ra = math.radians(a)
        k.lathe([(0.0, 0.0), (0.06 + (i % 3) * 0.02, 0.0), (0.0, 0.30 + (i % 4) * 0.08)], (math.cos(ra) * 0.5, math.sin(ra) * 0.5, 0.03), "edge",
                rot=(-20 * math.sin(ra), 20 * math.cos(ra), 0), segs=3)
    # çatlaklar
    import random
    rnd = random.Random(3)
    for a in range(0, 360, 50):
        ang = math.radians(a + rnd.uniform(-10, 10))
        pts = [(0.0, 0.0, 0.045)]
        r = 0.0
        for s in range(4):
            r += rnd.uniform(0.07, 0.12)
            aa = ang + rnd.uniform(-0.3, 0.3)
            pts.append((math.cos(aa) * r, math.sin(aa) * r, 0.045))
        k.tube(pts, 0.008, "dark", 0.3, 5)
    objs = [o for o in U.meshes() if o.name not in before]
    U.group_transform(objs, (0, 0, 0), (90, 0, 0), 1.0)  # yüz -Y'ye baksın
    for (x, z, s) in ((0.25, -0.75, 0.04), (0.18, -0.9, 0.03), (0.32, -0.95, 0.03), (0.12, -0.78, 0.025)):
        k.ball((x, -0.2, z), (s, s, s), "gold")
    return dict(az=-22, el=12, lens=55, roll=-10, fill=0.92)


# ------------------------------------------------------------------------------------------ dash_distance

def stat_dash_distance(k: U.Kit) -> dict:
    k.m["steel"] = U.mat("steel2", (0.66, 0.72, 0.82), 0.3, 0.4)
    k.m["navy"] = U.mat("navy2", (0.34, 0.42, 0.56), 0.45, 0.2)
    # sırt roketi: zırhlı plaka + iki silindir + nozul + katmanlı alev
    k.bx((0.0, 0.10, 0.0), (1.00, 0.22, 1.30), "navy", bev=0.04)
    k.bx((0.0, 0.10, 0.62), (1.00, 0.24, 0.10), "metal", bev=0.02)
    for sx in (-1, 1):
        x = 0.38 * sx
        k.tb((x, -0.20, 0.0), 0.28, 1.35, "steel", axis="Z", segs=32)
        for z in (0.45, -0.05, -0.50):
            k.tb((x, -0.20, z), 0.295, 0.14, "orange", axis="Z", segs=32)
        k.tb((x, -0.20, 0.72), 0.30, 0.08, "dark", axis="Z", segs=32)
        k.ball((x, -0.20, 0.78), (0.24, 0.24, 0.12), "metal")
        k.tb((x, -0.20, -0.80), 0.24, 0.30, "metal", axis="Z", segs=32, r2=0.32)
        k.tb((x, -0.20, -0.96), 0.33, 0.05, "ember", axis="Z", segs=32)
        k.tb((x, -0.20, -0.98), 0.20, 0.03, "dark", axis="Z", segs=24)
        for z in (0.2, -0.3):
            k.bx((x, -0.49, z), (0.10, 0.02, 0.10), "gold", bev=0.004)
    for sx in (-1, 1):
        k.bx((0.18 * sx, -0.20, 0.0), (0.08, 0.50, 1.15), "leather", bev=0.01)
    k.bx((0.0, -0.46, 0.15), (0.34, 0.04, 0.12), "dark", bev=0.006)
    for (xx, ph) in ((-0.38, 0.0), (0.38, 1.8)):
        for (wd, ln, m, yo) in ((0.26, 1.7, "ember", 0.0), (0.17, 1.3, "yellow", -0.03), (0.08, 0.85, "white", -0.06)):
            path = []
            for i in range(16):
                t = i / 15
                path.append((xx + 0.09 * math.sin(t * 7.0 + ph) * (0.4 + t), -1.02 - t * ln))
            ribbon(k, path, wd, 0.015, m, y=-0.20 + yo, pointy=0.7)
    return dict(az=-18, el=6, lens=55, roll=0, fill=0.93)


STATS: dict = {
    "max_hp": (stat_max_hp, 101, {}),
    "damage": (stat_damage, 102, {}),
    "fire_rate": (stat_fire_rate, 103, {}),
    "range": (stat_range, 104, {}),
    "move_speed": (stat_move_speed, 105, {"levels": (0.12, 0.38, 0.70, 1.0), "hatch": 0.6}),
    "armor": (stat_armor, 106, {}),
    "luck": (stat_luck, 107, {"blood_spots": 8}),
    "hp_regen": (stat_hp_regen, 108, {}),
    "pickup_range": (stat_pickup_range, 109, {}),
    "dash_cooldown": (stat_dash_cooldown, 110, {}),
    "dash_distance": (stat_dash_distance, 111, {"levels": (0.12, 0.38, 0.70, 1.0), "hatch": 0.6}),
}


def build(sid: str) -> str:
    fn, seed, extra = STATS[sid]
    U.reset_scene()
    k = U.Kit(1.0)
    cfg = fn(k)
    cam = U.fit_camera(U.meshes(), az=cfg["az"], el=cfg["el"], lens=cfg["lens"], fill=cfg["fill"], roll=cfg["roll"])
    U.add_lights(cam)
    return U.make("stat_" + sid, seed=seed, **extra)


def main() -> None:
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    for sid in (args or list(STATS)):
        print("EMBLEM", build(sid), flush=True)
    U.contact_sheet(["stat_" + k for k in STATS], os.path.join(U.REPO, "build", "shots", "emblems_stats.png"), cols=4, tile=256)


main()
