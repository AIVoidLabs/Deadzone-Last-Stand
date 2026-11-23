"""Eşya amblemleri (12): item_<ItemData id>.png — Çizgi roman mürekkep, güçlü siluet.

Çalıştırma (repo kökünden):
    blender --background --python tools/blender/ui_emblems_items.py [-- armor_plate drum_mag ...]
Çıktı: assets/textures/ui/emblems/item_<id>.png + build/shots/emblems_items_contact.png (kontak).
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ui_ink as U  # noqa: E402

U.WORK_DIR = os.path.join(U.REPO, "build", "blender", "ink_items")  # başka ajanla pasa dosyası çakışmasın

def prism(k: U.Kit, polys: list, thick: float, m: str, c: tuple = (0, 0, 0), rot: tuple = (0, 0, 0)):
    """XZ düzleminde dışbükey çokgenlerden (saat yönü tersi) kalınlıklı levha."""
    verts: list = []
    faces: list = []
    for poly in polys:
        n = len(poly)
        b = len(verts)
        verts += [(x, -thick / 2, z) for x, z in poly]
        verts += [(x, thick / 2, z) for x, z in poly]
        faces.append(tuple(range(b, b + n)))
        faces.append(tuple(range(b + 2 * n - 1, b + n - 1, -1)))
        for i in range(n):
            j = (i + 1) % n
            faces.append((b + i, b + n + i, b + n + j, b + j))
    return k.mesh(verts, faces, m, c, rot)


def link(k: U.Kit, c: tuple, a: float, b: float, minor: float, angle: float, side: bool, m: str, segs: int = 28):
    """Zincir halkası (elips): angle = XZ düzleminde teğet açısı; side=True ise yandan görünür."""
    t = (math.cos(math.radians(angle)), 0.0, math.sin(math.radians(angle)))
    n = (0.0, 1.0, 0.0) if side else (-t[2], 0.0, t[0])
    verts: list = []
    faces: list = []
    ms = 8
    for i in range(segs):
        ph = 2 * math.pi * i / segs
        pu, pv = a * math.cos(ph), b * math.sin(ph)
        # dışa yön (yaklaşık)
        ou, ov = math.cos(ph) / a, math.sin(ph) / b
        ln = math.hypot(ou, ov)
        ou, ov = ou / ln, ov / ln
        for j in range(ms):
            q = 2 * math.pi * j / ms
            r = minor * math.cos(q)
            w = minor * math.sin(q)
            u, v = pu + ou * r, pv + ov * r
            verts.append((c[0] + t[0] * u + n[0] * v + 0 * w, c[1] + t[1] * u + n[1] * v + (w if not side else 0.0),
                          c[2] + t[2] * u + n[2] * v))
    # side=False: halka XZ düzleminde (v = dik yön), kalınlık y; side=True: halka (t, y) düzleminde, kalınlık dik yön
    if side:
        verts = []
        nn = (-t[2], 0.0, t[0])
        for i in range(segs):
            ph = 2 * math.pi * i / segs
            pu, pv = a * math.cos(ph), b * math.sin(ph)
            ou, ov = math.cos(ph) / a, math.sin(ph) / b
            ln = math.hypot(ou, ov)
            ou, ov = ou / ln, ov / ln
            for j in range(ms):
                q = 2 * math.pi * j / ms
                r = minor * math.cos(q)
                w = minor * math.sin(q)
                u, y = pu + ou * r, pv + ov * r
                verts.append((c[0] + t[0] * u + nn[0] * w, c[1] + y, c[2] + t[2] * u + nn[2] * w))
    for i in range(segs):
        i2 = (i + 1) % segs
        for j in range(ms):
            j2 = (j + 1) % ms
            faces.append((i * ms + j, i2 * ms + j, i2 * ms + j2, i * ms + j2))
    return k.mesh(verts, faces, m)


def bullet(k: U.Kit, c: tuple, rot: tuple, sc: float = 1.0, tip: float = 0.55, jacket: str = "copper") -> None:
    """Mermi: gömlek + kovan (taban z=0 merkez, uç +Z). Hepsi group_transform ile yerleşir."""
    before = {o.name for o in U.meshes()}
    case = [(0.0, 0.0), (0.095, 0.0), (0.100, 0.02), (0.084, 0.04), (0.086, 0.32), (0.078, 0.34)]
    jk = [(0.078, 0.34), (0.082, 0.50), (0.074, 0.50 + tip * 0.35), (0.045, 0.50 + tip * 0.75), (0.0, 0.50 + tip)]
    k.lathe(case, (0, 0, 0), "brass", segs=20)
    k.lathe(jk, (0, 0, 0), jacket, segs=20)
    k.ring((0, 0, 0.33), 0.082, 0.010, "dark", rot=(0, 0, 0))
    objs = [o for o in U.meshes() if o.name not in before]
    U.group_transform(objs, c, rot, sc)


def flame(k: U.Kit, base: tuple, rotz: float = 0.0, sc: float = 1.0) -> None:
    prof = [(0.0, 0.0), (0.30, 0.05), (0.40, 0.25), (0.24, 0.5), (0.30, 0.78), (0.14, 1.05), (0.17, 1.3), (0.0, 1.75)]
    for (s, m) in ((1.0, "ember"), (0.72, "yellow"), (0.42, "white")):
        k.lathe([(r * s * sc, z * s * sc) for r, z in prof], base, m, rot=(0, -90 + rotz, 0), segs=14)


def drip(k: U.Kit, pts: list, m: str = "flesh") -> None:
    for (x, y, z, s) in pts:
        k.ball((x, y, z), (s, s, s * 1.5), m)


def extra_mats(k: U.Kit) -> None:
    k.m["bolt"] = U.mat("bolt", (1.0, 0.80, 0.10), 0.35)
    k.m["green"] = U.mat("green", (0.42, 0.72, 0.24), 0.5)
    k.m["serum"] = U.mat("serum", (0.55, 0.95, 0.25), 0.3, 0.0, emit=(0.55, 0.95, 0.25), emit_strength=3.0)



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


def armored_boot(k: U.Kit, heavy: bool) -> None:
    """Büyük, net siluetli bot (yandan, burun hafif aşağı). heavy: zırhlı + topuk iticisi; değilse hafif koşu ayakkabısı."""
    before = {o.name for o in U.meshes()}
    if heavy:
        k.m["leather"] = U.mat("leather2", (0.55, 0.34, 0.18), 0.7)
        k.m["dark"] = U.mat("dark2", (0.22, 0.22, 0.24), 0.55, 0.2)
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
        k.tb((-0.62, 0.0, -0.40), 0.20, 0.34, "metal", axis="X", segs=24, r2=0.26)      # topuk iticisi
        k.tb((-0.80, 0.0, -0.40), 0.27, 0.05, "ember", axis="X", segs=24)
    else:
        k.m["leather"] = U.mat("shoe", (0.90, 0.88, 0.80), 0.6)
        k.blob([((-0.05, 0.0, 0.05), (0.26, 0.20, 0.34), False), ((-0.32, 0.0, -0.28), (0.22, 0.19, 0.20), False),
                ((0.36, 0.0, -0.34), (0.38, 0.20, 0.17), False), ((-0.05, 0.0, 0.50), (0.24, 0.19, 0.34), False),
                ((0.08, 0.0, -0.20), (0.34, 0.19, 0.24), False)], "leather", 0.022)
        k.bx((0.05, 0.0, -0.53), (1.22, 0.38, 0.09), "orange", bev=0.035)
        k.bx((0.05, 0.0, -0.595), (1.22, 0.39, 0.04), "dark", bev=0.01)
        k.bx((0.62, 0.0, -0.36), (0.30, 0.38, 0.10), "orange", rot=(0, 18, 0), bev=0.03)  # burun bandı
        k.tube([(0.55, -0.20, -0.28), (0.15, -0.22, -0.30), (-0.30, -0.21, -0.38)], 0.04, "orange", 1.0, 8)
        for i in range(4):                                                                # bağcıklar
            k.bx((0.20 - i * 0.02, -0.21, 0.04 + i * 0.07), (0.22, 0.03, 0.035), "dark", rot=(0, 20 * (-1) ** i, 0), bev=0.004)
        k.bx((0.0, 0.0, 0.62), (0.56, 0.42, 0.10), "orange", bev=0.02)                  # bilek bandı
        k.bx((-0.24, 0.0, 0.84), (0.10, 0.30, 0.30), "orange", bev=0.02)
        for i in range(3):                                                                # kanat çizgileri
            k.bx((-0.45 - i * 0.2, 0.0, 0.25 + i * 0.12), (0.4, 0.03, 0.035), "bone", bev=0.002)
    objs = [o for o in U.meshes() if o.name not in before]
    U.group_transform(objs, (0, 0, 0), (0, 22, 0), 1.0)


# ------------------------------------------------------------------------------------------ armor_plate

def item_armor_plate(k: U.Kit) -> dict:
    k.bx((0, 0.08, 0), (1.05, 0.12, 1.30), "dark", bev=0.11)
    for sx in (-0.34, 0.34):
        k.bx((sx, 0.12, 0), (0.12, 0.06, 1.46), "leather", bev=0.01)
        k.bx((sx, 0.10, 0.62), (0.18, 0.08, 0.10), "gold", bev=0.01)
    k.bx((0, 0.0, 0), (1.0, 0.12, 1.25), "navy", bev=0.11)
    k.bx((0, -0.07, 0.02), (0.78, 0.06, 1.0), "metal", bev=0.07)
    for i, z in enumerate((0.34, 0.12, -0.10)):
        for sg in (-1, 1):
            k.bx((sg * 0.20, -0.105, z), (0.46, 0.03, 0.10), "bone", rot=(0, sg * 26, 0), bev=0.008)
    for x, z in ((-0.43, 0.55), (0.43, 0.55), (-0.43, -0.55), (0.43, -0.55)):
        k.ball((x, -0.07, z), (0.05, 0.04, 0.05), "steel")
    # mermi izi: ezik mermi + çatlaklar
    k.tb((0.14, -0.108, 0.30), 0.12, 0.03, "dark", axis="Y", segs=10)
    k.ball((0.14, -0.14, 0.30), (0.075, 0.05, 0.075), "copper")
    k.ring((0.14, -0.125, 0.30), 0.12, 0.018, "steel", rot=(90, 0, 0))
    import random
    rnd = random.Random(8)
    for a in range(7):
        ang = rnd.uniform(0, 6.28)
        pts = []
        r = 0.12
        for s in range(4):
            r += rnd.uniform(0.05, 0.09)
            aa = ang + rnd.uniform(-0.3, 0.3)
            pts.append((0.14 + math.cos(aa) * r, -0.112, 0.30 + math.sin(aa) * r))
        k.tube(pts, 0.014, "dark", 0.3, 6)
    drip(k, [(0.14, -0.15, 0.16, 0.03), (0.18, -0.15, 0.06, 0.025), (0.12, -0.15, -0.02, 0.02)])
    return dict(az=-18, el=10, lens=55, roll=4, fill=0.92)


# ------------------------------------------------------------------------------------------ drum_mag

def item_drum_mag(k: U.Kit) -> dict:
    cz = 0.0
    k.tb((0, 0, cz), 0.62, 0.46, "metal", axis="Y", segs=40, bev=0.02)
    for y in (-0.22, 0.22):
        k.ring((0, y, cz), 0.62, 0.035, "steel", rot=(90, 0, 0))
    k.tb((0, -0.25, cz), 0.54, 0.06, "dark", axis="Y", segs=40)
    for i in range(10):
        a = math.radians(i * 36 + 8)
        k.bx((math.cos(a) * 0.38, -0.30, cz + math.sin(a) * 0.38), (0.10, 0.04, 0.22), "orange" if i % 3 == 0 else "dark",
             rot=(0, 90 - math.degrees(a), 0), bev=0.008)
    k.tb((0, -0.31, cz), 0.19, 0.06, "steel", axis="Y", segs=24)
    k.tb((0, -0.35, cz), 0.07, 0.05, "dark", axis="Y", segs=16)
    # besleme boynu + mermiler
    k.bx((0.30, 0.0, 0.70), (0.46, 0.34, 0.26), "metal", rot=(0, -28, 0), bev=0.03)
    k.bx((0.30, -0.18, 0.70), (0.40, 0.02, 0.10), "orange", rot=(0, -28, 0), bev=0.005)
    bullet(k, (0.12, -0.02, 0.84), (0, 14, 0), 1.1, 0.5)
    bullet(k, (0.36, -0.02, 0.80), (0, 18, 0), 1.1, 0.5)
    # bandolyer: tamburdan sarkan mermi kuşağı
    drip(k, [(-0.2, -0.36, -0.66, 0.03), (0.3, -0.36, -0.64, 0.025)])
    return dict(az=-38, el=16, lens=50, roll=-5, fill=0.94)


# ------------------------------------------------------------------------------------------ long_barrel

def item_long_barrel(k: U.Kit) -> dict:
    k.tb((0, 0, 0), 0.14, 2.4, "metal", axis="X", segs=24)
    k.tb((-0.55, 0, 0), 0.24, 0.95, "dark", axis="X", segs=24, bev=0.01)
    for i in range(6):
        k.bx((-0.95 + i * 0.17, -0.185, 0.0), (0.06, 0.03, 0.26), "orange" if i == 2 else "metal", bev=0.005)
    for x in (-1.0, -0.1):
        k.tb((x, 0, 0), 0.205, 0.07, "steel", axis="X", segs=24)
    k.tb((0.55, 0, 0), 0.135, 0.07, "gold", axis="X", segs=24)
    for i in range(7):
        k.tb((0.70 + i * 0.11, 0, 0), 0.15, 0.04, "steel", axis="X", segs=24)
    k.tb((1.38, 0, 0), 0.18, 0.34, "metal", axis="X", segs=24, bev=0.01)
    for i in range(3):
        k.bx((1.34 + i * 0.1, -0.17, 0.0), (0.05, 0.05, 0.30), "dark", bev=0.004)
    k.tb((1.56, 0, 0), 0.19, 0.04, "steel", axis="X", segs=24)
    k.tb((1.585, 0, 0), 0.085, 0.02, "dark", axis="X", segs=16)
    k.ball((1.60, 0, 0), (0.05, 0.05, 0.05), "ember")
    k.bx((1.35, 0, 0.23), (0.05, 0.04, 0.12), "dark", bev=0.005)
    k.bx((-0.1, 0, 0.22), (1.6, 0.14, 0.04), "dark", bev=0.01)
    for i in range(9):
        k.bx((-0.80 + i * 0.2, -0.075, 0.22), (0.02, 0.02, 0.05), "bone", bev=0.002)
    # uzunluk oku
    k.tube([(-1.0, -0.30, -0.50), (1.4, -0.30, -0.50)], 0.03, "bone", 1.0, 6)
    k.tb((-1.10, -0.30, -0.50), 0.09, 0.2, "bone", axis="X", r2=0.0, segs=8)
    k.tb((1.48, -0.30, -0.50), 0.0, 0.2, "bone", axis="X", r2=0.09, segs=8)
    drip(k, [(0.2, -0.12, -0.14, 0.035), (0.9, -0.15, -0.14, 0.03), (0.9, -0.16, -0.25, 0.025)])
    return dict(az=-26, el=16, lens=45, roll=38, fill=0.95)


# ------------------------------------------------------------------------------------------ sharp_rounds

def item_sharp_rounds(k: U.Kit) -> dict:
    for (c, rot, sc) in (((-0.55, 0.12, -0.55), (0, 24, 0), 1.0), ((0.35, 0.10, -0.65), (0, -22, 0), 1.0),
                         ((-0.10, -0.08, -0.60), (0, 3, 0), 1.25)):
        bullet(k, c, rot, sc, 0.95, "steel")
    # kanlı uçlar
    drip(k, [(-0.10, -0.16, 0.45, 0.035), (-0.12, -0.16, 0.25, 0.03), (-0.37, -0.12, 0.15, 0.03), (0.15, -0.14, 0.10, 0.025)])
    for (x, z, s) in ((0.58, 0.55, 0.04), (0.65, 0.4, 0.03), (-0.75, 0.55, 0.03)):
        k.ball((x, 0, z), (s, s, s * 1.4), "flesh")
    for sx in (-1, 1):
        k.bx((sx * 0.08 + (-0.10 if sx < 0 else 0.0), -0.06, 0.95), (0.02, 0.02, 0.18), "white", rot=(0, sx * 20, 0))
    return dict(az=-12, el=8, lens=50, roll=-6, fill=0.92)


# ------------------------------------------------------------------------------------------ energy_drink

def item_energy_drink(k: U.Kit) -> dict:
    """Büyük kutu öne çıkar; şimşek kutunun üstüne ince baskı olarak (kabartma) oturur."""
    k.m["can"] = U.mat("can", (0.78, 0.08, 0.08), 0.25, 0.5)
    prof = [(0.0, -0.80), (0.30, -0.80), (0.36, -0.72), (0.40, -0.62), (0.40, 0.58), (0.36, 0.72), (0.30, 0.80), (0.0, 0.80)]
    k.lathe(prof, (0, 0, 0), "can", segs=40)
    k.tb((0, 0, 0.80), 0.31, 0.04, "steel", axis="Z", segs=32)
    k.ring((0, 0, 0.83), 0.25, 0.02, "metal", rot=(0, 0, 0))
    k.tb((0, 0.0, 0.85), 0.20, 0.03, "dark", axis="Z", segs=24)
    k.bx((-0.03, 0.0, 0.88), (0.26, 0.12, 0.03), "steel", bev=0.01)       # açma halkası
    k.ring((0.10, -0.03, 0.88), 0.07, 0.02, "steel", rot=(0, 0, 0))
    for (z, h) in ((0.62, 0.07), (-0.58, 0.07)):
        k.tb((0, 0, z), 0.405, h, "dark", axis="Z", segs=40)
    k.tb((0, 0, 0.54), 0.405, 0.03, "bone", axis="Z", segs=40)
    k.tb((0, 0, -0.50), 0.405, 0.03, "bone", axis="Z", segs=40)
    # şimşek baskısı (yüzeye yakın, ince)
    prism(k, [[(-0.02, 0.50), (-0.20, -0.02), (0.02, -0.02), (-0.12, -0.46), (0.20, 0.08), (-0.02, 0.08), (0.12, 0.50)]],
          0.025, "bolt", (0.0, -0.405, 0.0))
    for (x, z) in ((-0.22, 0.30), (0.25, -0.30), (-0.25, -0.20)):
        k.ball((x, -0.40, z), (0.018, 0.012, 0.025), "white")               # su damlaları
    k.ball((0.30, -0.38, 0.10), (0.04, 0.03, 0.05), "dark")                 # ezik
    drip(k, [(0.3, -0.36, -0.55, 0.04), (-0.2, -0.38, -0.62, 0.03)])
    return dict(az=-10, el=10, lens=50, roll=-8, fill=0.94)


# ------------------------------------------------------------------------------------------ med_kit

def item_med_kit(k: U.Kit) -> dict:
    k.bx((0, 0, 0), (1.15, 0.46, 0.80), "olive", bev=0.07)
    k.bx((0, -0.235, 0.18), (1.15, 0.02, 0.025), "dark", bev=0.003)
    k.tube([(-0.28, 0, 0.40), (-0.24, 0, 0.62), (0.24, 0, 0.62), (0.28, 0, 0.40)], 0.045, "dark", 1.0, 8)
    k.bx((0, -0.235, -0.06), (0.58, 0.03, 0.54), "bone", bev=0.02)
    k.bx((0, -0.26, -0.06), (0.17, 0.035, 0.50), "green", bev=0.012)
    k.bx((0, -0.26, -0.06), (0.50, 0.035, 0.17), "green", bev=0.012)
    for sx in (-0.42, 0.42):
        k.bx((sx, -0.24, 0.18), (0.10, 0.04, 0.12), "steel", bev=0.01)
        k.bx((sx, -0.265, 0.18), (0.05, 0.02, 0.05), "gold", bev=0.005)
    for sx in (-0.45, 0.45):
        k.bx((sx, -0.01, 0), (0.12, 0.50, 0.84), "leather", bev=0.01)
    for (x, z) in ((-0.50, 0.30), (0.50, 0.30), (-0.50, -0.30), (0.50, -0.30)):
        k.ball((x, -0.26, z), (0.03, 0.03, 0.03), "steel")
    # kan damlaları
    drip(k, [(0.20, -0.27, -0.26, 0.04), (0.24, -0.27, -0.36, 0.03), (-0.34, -0.27, -0.30, 0.03)])
    k.tube([(0.20, -0.27, -0.12), (0.20, -0.27, -0.24)], 0.012, "flesh", 0.6, 6)
    # yırtık sargı
    k.tb((0.68, -0.06, -0.22), 0.14, 0.2, "bone", axis="Y", segs=20)
    k.tb((0.68, -0.06, -0.22), 0.05, 0.22, "dark", axis="Y", segs=10)
    k.tube([(0.62, -0.18, -0.30), (0.40, -0.26, -0.50), (0.10, -0.26, -0.58), (-0.2, -0.24, -0.66)], 0.04, "bone", 0.8, 8)
    drip(k, [(-0.3, -0.27, -0.42, 0.035), (0.0, -0.27, -0.60, 0.03)])
    return dict(az=-14, el=14, lens=55, roll=-4, fill=0.92)


# ------------------------------------------------------------------------------------------ lucky_charm

def item_lucky_charm(k: U.Kit) -> dict:
    n = 13
    for i in range(n):
        x = -0.82 + 1.64 * i / (n - 1)
        z = 0.48 + 0.90 * (x / 0.82) ** 2
        dz = 0.90 * 2 * x / (0.82 ** 2)
        ang = math.degrees(math.atan2(dz, 1.0))
        link(k, (x, 0.0, z), 0.115, 0.065, 0.026, ang, i % 2 == 1, "steel")
    k.ring((0.0, 0.0, 0.30), 0.10, 0.03, "gold", rot=(90, 0, 0))
    bullet(k, (0.0, 0.0, 0.42), (180, 0, 0), 0.95, 0.5, "copper")
    k.ring((0, 0, -0.06), 0.095, 0.022, "flesh", rot=(0, 0, 0))
    k.ring((0, 0, -0.14), 0.095, 0.018, "flesh", rot=(0, 0, 0))
    # diş (azı tılsımı) ip ile asılı
    k.tube([(0.10, 0.0, 0.42), (0.33, -0.04, 0.30), (0.42, -0.04, 0.12)], 0.016, "leather", 1.0, 6)
    k.lathe([(0.0, 0.0), (0.14, 0.02), (0.12, 0.18), (0.07, 0.42), (0.0, 0.52)], (0.45, -0.05, 0.12), "bone",
            rot=(180, 0, -10), segs=14)
    k.ball((0.45, -0.05, 0.14), (0.15, 0.11, 0.07), "bone")
    k.ball((0.45, -0.10, 0.08), (0.04, 0.02, 0.04), "flesh")
    for (x, z, s) in ((-0.1, -0.7, 0.04), (0.5, -0.5, 0.03), (-0.14, -0.85, 0.03)):
        k.ball((x, -0.05, z), (s, s, s * 1.5), "flesh")
    return dict(az=-8, el=10, lens=55, roll=0, fill=0.92)


# ------------------------------------------------------------------------------------------ magnet

def item_magnet(k: U.Kit) -> dict:
    k.tb((0, 0, 0.0), 0.54, 0.50, "metal", axis="Z", segs=36, bev=0.02)
    k.tb((0, 0, 0.30), 0.58, 0.08, "steel", axis="Z", segs=36)
    k.tb((0, 0, -0.32), 0.50, 0.14, "dark", axis="Z", segs=36)
    k.tb((0, 0, -0.40), 0.30, 0.06, "steel", axis="Z", segs=36)
    for z in (-0.18, -0.07, 0.04, 0.15):
        k.ring((0, 0, z), 0.565, 0.055, "copper", rot=(0, 0, 0))
    for i in range(10):
        a = i * 36
        k.bx((math.cos(math.radians(a)) * 0.58, math.sin(math.radians(a)) * 0.58, 0.0), (0.06, 0.06, 0.52), "dark",
             rot=(0, 0, a), bev=0.005)
    k.tb((0, 0, 0.45), 0.09, 0.22, "metal", axis="Z", segs=16)
    k.ring((0, 0, 0.66), 0.16, 0.045, "steel", rot=(90, 0, 0))
    k.tube([(0.55, 0.0, 0.1), (0.88, 0.0, 0.25), (0.96, 0.0, 0.7), (0.7, 0.0, 1.0)], 0.05, "dark", 1.0, 8)
    k.bx((0.52, 0.0, 0.1), (0.12, 0.16, 0.16), "orange", bev=0.01)
    # kaçak çelik: somun, cıvata, mermi, çivi
    for (x, y, z, s) in ((-0.22, -0.28, -0.55, 0.10), (0.18, -0.30, -0.56, 0.085), (0.02, -0.34, -0.70, 0.07)):
        k.tb((x, y, z), s, 0.07, "metal", axis="Z", segs=6, bev=0.004)
        k.tb((x, y, z), s * 0.4, 0.08, "dark", axis="Z", segs=8)
    bullet(k, (-0.38, -0.16, -0.50), (0, 170, 0), 0.5, 0.5, "steel")
    bullet(k, (0.36, -0.10, -0.58), (0, 195, 0), 0.5, 0.5, "steel")
    for (x, z, a) in ((-0.05, -0.55, 12), (0.28, -0.80, 40), (-0.30, -0.74, -30)):
        k.tb((x, -0.35, z), 0.015, 0.36, "edge", axis="Z", rot=(0, a, 0), r2=0.004, segs=6)
    # elektrik ark
    for (x0, x1) in ((-0.25, -0.20), (0.15, 0.20), (0.0, 0.02)):
        k.tube([(x0, -0.30, -0.42), (x0 * 1.2 + 0.05, -0.32, -0.50), (x1 - 0.05, -0.33, -0.56), (x1, -0.32, -0.62)], 0.014,
               "cyan", 1.0, 6)
    return dict(az=-14, el=14, lens=55, roll=-3, fill=0.92)


# ------------------------------------------------------------------------------------------ regen_shot

def item_regen_shot(k: U.Kit) -> dict:
    k.bx((-0.42, 0.04, -0.45), (0.26, 0.28, 0.72), "dark", rot=(0, 16, 0), bev=0.04)
    k.bx((-0.50, -0.10, -0.50), (0.14, 0.02, 0.56), "orange", rot=(0, 16, 0), bev=0.005)
    k.bx((-0.05, 0.05, 0.10), (1.05, 0.30, 0.36), "metal", bev=0.04)
    k.bx((-0.05, -0.115, 0.14), (0.94, 0.02, 0.06), "orange", bev=0.005)
    k.ring((-0.06, -0.02, -0.18), 0.12, 0.02, "dark", rot=(90, 0, 0))
    k.bx((-0.04, -0.02, -0.12), (0.03, 0.04, 0.12), "steel", rot=(0, 15, 0), bev=0.005)
    # ampuller
    for z in (0.50, 0.24):
        k.tb((0.42, -0.19, z), 0.13, 0.80, "serum", axis="X", segs=20)
        for x in (0.10, 0.42, 0.72):
            k.tb((x, -0.19, z), 0.16, 0.05, "steel", axis="X", segs=20)
        k.tb((-0.05, -0.19, z), 0.12, 0.12, "steel", axis="X", segs=16)
        k.tb((-0.14, -0.19, z), 0.06, 0.08, "dark", axis="X", segs=12)
        k.tb((1.30, -0.19, z), 0.03, 0.95, "edge", axis="X", r2=0.005, segs=8)
        k.tb((0.90, -0.19, z), 0.07, 0.08, "steel", axis="X", segs=14)
        k.tb((-0.40, -0.19, z), 0.03, 0.45, "steel", axis="X", segs=8)
        k.ring((-0.66, -0.19, z), 0.10, 0.025, "steel", rot=(0, 90, 0))
    k.bx((0.84, -0.19, 0.37), (0.10, 0.2, 0.46), "metal", bev=0.01)
    for z in (0.42, 0.56, 0.30, 0.18):
        pass
    for (x, z, s) in ((1.42, 0.12, 0.035), (1.58, -0.05, 0.03), (1.30, -0.10, 0.025)):
        k.ball((x, -0.19, z), (s, s, s * 1.5), "serum")
    k.ball((0.22, -0.22, 0.12), (0.06, 0.03, 0.04), "flesh")
    for x in (0.2, 0.34, 0.48):
        k.bx((x, -0.31, 0.37), (0.02, 0.02, 0.5), "dark", bev=0.001)
    drip(k, [(0.35, -0.2, -0.04, 0.03), (0.60, -0.2, -0.12, 0.025)])
    return dict(az=-14, el=10, lens=55, roll=6, fill=0.94)


# ------------------------------------------------------------------------------------------ botlar

def boot(k: U.Kit, shaft_h: float, upper: str, sole: str, trim: str, wide: float = 1.0) -> None:
    k.ball((0.22, 0, -0.02), (0.52, 0.27 * wide, 0.25), upper)
    k.ball((0.56, 0, -0.10), (0.30, 0.23 * wide, 0.17), upper)
    k.tb((-0.12, 0, 0.14 + shaft_h / 2), 0.235 * wide, shaft_h, upper, axis="Z", r2=0.27 * wide, segs=24)
    k.bx((0.22, 0, -0.28), (1.20, 0.50 * wide, 0.09), sole, bev=0.035)
    k.bx((-0.25, 0, -0.40), (0.38, 0.50 * wide, 0.14), sole, bev=0.03)
    k.bx((0.50, 0, -0.34), (0.26, 0.52 * wide, 0.07), "dark", bev=0.02)


def item_dash_boots(k: U.Kit) -> dict:
    armored_boot(k, True)
    for (dz, bend) in ((0.10, 0.25), (-0.16, -0.10)):
        path = [(-0.95 - t * 1.0, -0.10 + dz - t * 0.18 + bend * math.sin(t * math.pi) * 0.7) for t in [i / 13 for i in range(14)]]
        ribbon(k, path, 0.15, 0.02, "ember", y=-0.12)
        ribbon(k, path[:10], 0.07, 0.02, "yellow", y=-0.16)
    return dict(az=-4, el=4, lens=55, roll=0, fill=0.94)


def item_light_boots(k: U.Kit) -> dict:
    armored_boot(k, False)
    return dict(az=-4, el=4, lens=55, roll=0, fill=0.94)


# ------------------------------------------------------------------------------------------ dash_coil

def item_dash_coil(k: U.Kit) -> dict:
    R = 0.62
    segs = 34
    gap = 55.0
    for i in range(segs):
        phi = math.radians(90 + gap / 2 + (360 - gap) * i / (segs - 1))
        x, z = R * math.cos(phi), R * math.sin(phi)
        k.ring((x, 0, z), 0.165, 0.040, "brass", rot=(0, -math.degrees(phi) + 0.0, 0))
    # çekirdek halka (tel altından görünür)
    verts = None
    for i in range(0, 38):
        phi = math.radians(90 + gap / 2 + (360 - gap) * i / 37)
        k.tb((R * math.cos(phi), 0, R * math.sin(phi)), 0.09, 0.12, "dark", axis="Z",
             rot=(0, -math.degrees(phi) + 90 + 90, 0), segs=10)
    # uç terminalleri
    for sg in (-1, 1):
        a = math.radians(90 + sg * gap / 2)
        x, z = R * math.cos(a), R * math.sin(a)
        k.tb((x + sg * 0.0, 0, z + 0.05), 0.07, 0.30, "steel", axis="Z", segs=14)
        k.ball((x, 0, z + 0.24), (0.09, 0.09, 0.09), "metal")
        k.ball((x, 0, z + 0.24), (0.05, 0.05, 0.05), "cyan")
    ax = R * math.cos(math.radians(90 + gap / 2))
    az_ = R * math.sin(math.radians(90 + gap / 2)) + 0.24
    k.tube([(-ax, 0, az_), (-ax * 0.5, 0, az_ + 0.14), (-ax * 0.1, 0, az_ - 0.05), (ax * 0.3, 0, az_ + 0.10), (ax, 0, az_)],
           0.05, "cyan", 1.0, 6)
    k.tube([(-ax, 0, az_), (-ax * 0.3, -0.1, az_ + 0.28), (ax * 0.4, -0.08, az_ + 0.22), (ax, 0, az_)], 0.016, "white", 1.0, 6)
    # taban kelepçesi
    k.bx((0, 0, -R - 0.28), (0.9, 0.34, 0.12), "metal", bev=0.02)
    k.bx((0, 0, -R - 0.12), (0.28, 0.24, 0.22), "dark", bev=0.02)
    return dict(az=-10, el=8, lens=55, roll=0, fill=0.92)


ITEMS: dict = {
    "armor_plate": (item_armor_plate, 201, {}),
    "drum_mag": (item_drum_mag, 202, {}),
    "long_barrel": (item_long_barrel, 203, {}),
    "sharp_rounds": (item_sharp_rounds, 204, {"blood_spots": 6}),
    "energy_drink": (item_energy_drink, 205, {}),
    "med_kit": (item_med_kit, 206, {"blood_spots": 5}),
    "lucky_charm": (item_lucky_charm, 207, {}),
    "magnet": (item_magnet, 208, {}),
    "regen_shot": (item_regen_shot, 209, {}),
    "dash_boots": (item_dash_boots, 210, {}),
    "dash_coil": (item_dash_coil, 211, {}),
    "light_boots": (item_light_boots, 212, {}),
}


def build(sid: str) -> str:
    fn, seed, extra = ITEMS[sid]
    U.reset_scene()
    k = U.Kit(1.0)
    extra_mats(k)
    cfg = fn(k)
    cam = U.fit_camera(U.meshes(), az=cfg["az"], el=cfg["el"], lens=cfg["lens"], fill=cfg["fill"], roll=cfg["roll"])
    U.add_lights(cam)
    return U.make("item_" + sid, seed=seed, **extra)


def main() -> None:
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    for sid in (args or list(ITEMS)):
        print("EMBLEM", build(sid), flush=True)
    U.contact_sheet(["item_" + k for k in ITEMS], os.path.join(U.REPO, "build", "shots", "emblems_items_contact.png"),
                    cols=4, tile=256)


main()
