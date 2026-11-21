"""Bina A: köşe blok konsepti (8.1c, ikinci tur). Çalıştırma (repo kökünden):
    blender --background --python tools/blender/build_city_building.py
Çıktı: assets/models/world/building_a.glb + build/shots/building_a_{game,day}.png
Orijin: gövde ayak izinin merkezi, zemin z=0. Blender +X ve -Y cepheleri sokağa bakar;
glTF/Godot'ta bunlar +X ve +Z olur. Yanık/çökmüş köşe iki sokak cephesinin birleştiği iç köşededir.
"""
import math
import os
import random
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import city_kit as ck  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT = os.path.join(ROOT, "assets", "models", "world", "building_a.glb")
SHOTS = os.path.join(ROOT, "build", "shots")
H = 11.0
HALF = ck.HALF
GROUND_H = 4.2
CUT = 4.5            # çöken köşe: x > CUT ve y < -CUT
LOW = 6.9            # çöküntü tabanı yüksekliği
WIN_U = (-7.2, -3.6, 0.0, 3.6, 7.2)
WIN_Z = (5.1, 8.5)
WIN_W, WIN_H = 1.6, 1.8
WINDOWS = {
    "X": {"F2": ["broken", "lit", "boarded", "dark", "broken"], "F3": [None, "boarded", "dark", "dark", "broken"]},
    "Y": {"F2": ["boarded", "dark", "dark", "lit", "broken"], "F3": ["dark", "broken", "boarded", "dark", None]},
}
BAYS = {"X": ["broken", "shutter", "boarded"], "Y": ["shutter", "broken", "open"]}
BAY_U = (-6.0, 0.0, 6.0)
HOLE = (0.0, 3.2, 1.0, 4.2)   # çatıdaki göçük (x0, x1, y0, y1)
rng = random.Random(11)


def split_a(k: ck.Kit, mat: str, z0: float, z1: float, hole_floor: float = None) -> None:
    """A bölgesi (y > -CUT) çatı deliğiyle parçalı: hole_floor verilirse delik tabanı."""
    hx0, hx1, hy0, hy1 = HOLE
    k.box(mat, -HALF, hx0, -CUT, HALF, z0, z1)
    k.box(mat, hx1, HALF, -CUT, HALF, z0, z1)
    k.box(mat, hx0, hx1, -CUT, hy0, z0, z1)
    k.box(mat, hx0, hx1, hy1, HALF, z0, z1)
    if hole_floor is not None:
        k.box("soot", hx0, hx1, hy0, hy1, z0, hole_floor)


def body(k: ck.Kit) -> None:
    split_a(k, "brick", 0, H)
    k.box("brick", HOLE[0], HOLE[1], HOLE[2], HOLE[3], 0, H - 2.6)   # delik tabanı H-2.6
    k.box("brick", -HALF, CUT, -HALF, -CUT, 0, H)
    # çökmüş iç köşe: LOW'a kadar dolu, üstünde düzensiz yanık kolonlar
    k.box("brick", CUT, HALF, -HALF, -CUT, 0, LOW)
    n = 3
    step = (HALF - CUT) / n
    heights = [8.9, 7.4, 8.1, 7.1, 9.4, 7.7, 7.2, 8.6, 7.3]
    i = 0
    for ix in range(n):
        for iy in range(n):
            x0 = CUT + ix * step
            y1 = -CUT - iy * step
            hh = heights[i]
            i += 1
            k.box("brick", x0, x0 + step, y1 - step, y1, LOW, hh)
            k.box("soot", x0 - 0.02, x0 + step + 0.02, y1 - step - 0.02, y1 + 0.02, hh, hh + 0.08)
    # kararmış kesit yüzleri (tuğla kesitleri yanık)
    k.box("soot", CUT, CUT + 0.05, -HALF, -CUT, LOW, 8.7)
    k.box("soot", CUT, HALF, -CUT - 0.05, -CUT, LOW, 8.7)
    k.box("soot", CUT - 0.01, CUT + 0.05, -HALF, -7.5, 8.7, 10.9)


def roof(k: ck.Kit) -> None:
    top = H
    hx0, hx1, hy0, hy1 = HOLE
    # çatı kaplaması: delikli A + B
    k.box("concrete", -HALF, hx0, -CUT, HALF, top, top + 0.12)
    k.box("concrete", hx1, HALF, -CUT, HALF, top, top + 0.12)
    k.box("concrete", hx0, hx1, -CUT, hy0, top, top + 0.12)
    k.box("concrete", hx0, hx1, hy1, HALF, top, top + 0.12)
    k.box("concrete", -HALF, CUT, -HALF, -CUT, top, top + 0.12)
    # delik: iç kararmış, taban derinde
    k.box("soot", hx0, hx1, hy0, hy1, H - 2.6, H - 2.5)
    # delik kenarında sarkan beton parçaları
    k.wbox("concrete", (hx0 + 0.5, hy0 + 0.3, top - 0.35), (1.3, 0.8, 0.12), (0.5, 0.05, 0.2))
    k.wbox("concrete", (hx1 - 0.4, hy1 - 0.4, top - 0.6), (1.1, 0.9, 0.12), (-0.4, 0.5, 0.7))
    k.wbox("rust", (hx0 + 1.5, hy0 + 1.6, top - 0.8), (0.07, 0.07, 1.8), (0.4, 0.3, 0.0))   # çıplak donatı
    # çatı tahtaları: delik üstünde ve dağınık
    k.wbox("wood", ((hx0 + hx1) / 2, hy0 + 1.0, top + 0.17), (3.6, 0.3, 0.06), (0.0, 0.0, 0.12))
    k.wbox("wood", ((hx0 + hx1) / 2 + 0.2, hy0 + 2.0, top + 0.17), (3.4, 0.28, 0.06), (0.0, 0.04, -0.2))
    k.wbox("wood", (5.8, 3.0, top + 0.16), (2.6, 0.26, 0.06), (0.0, 0.0, 0.7))
    k.wbox("wood", (-3.0, 0.5, top + 0.35), (2.4, 0.26, 0.06), (0.0, 0.5, 0.3))
    # parapet (iç köşe çöküntüsüne kadar, boşluklu)
    ph = 0.95
    segs = [(-HALF, -2.5, -HALF, -HALF + 0.4), (1.2, CUT, -HALF, -HALF + 0.4),
            (HALF - 0.4, HALF, -CUT, 1.2), (HALF - 0.4, HALF, 3.0, HALF),
            (-HALF, -HALF + 0.4, -HALF, HALF), (-HALF, HALF, HALF - 0.4, HALF)]
    for x0, x1, y0, y1 in segs:
        k.box("brick", x0, x1, y0, y1, top, top + ph)
        k.box("concrete", x0 - 0.06, x1 + 0.06, y0 - 0.06, y1 + 0.06, top + ph, top + ph + 0.12)
    k.wbox("brick", (-1.3, -HALF + 0.2, top + 0.45), (1.0, 0.4, 0.5), (0.05, 0.1, 0.2))
    k.wbox("concrete", (-0.4, -HALF + 1.6, top + 0.2), (0.9, 0.5, 0.35), (0.0, 0.2, 0.6))
    # klima kutuları; biri devrik
    for cx, cy, sx, sy in ((-6.0, -5.5, 2.0, 1.3), (-2.5, -6.5, 1.6, 1.2)):
        k.box("concrete", cx - sx / 2, cx + sx / 2, cy - sy / 2, cy + sy / 2, top + 0.12, top + 1.2)
        k.cyl("soot", (cx, cy, top + 1.24), min(sx, sy) * 0.38, 0.06, 8)
        k.box("rust", cx - sx / 2 - 0.1, cx + sx / 2 + 0.1, cy - sy / 2 - 0.1, cy + sy / 2 + 0.1, top + 0.12, top + 0.3)
    k.wbox("concrete", (3.3, -5.4, top + 0.7), (1.8, 1.2, 1.1), (0.0, 1.35, 0.35))   # devrilmiş klima
    k.cyl("soot", (4.1, -4.6, top + 0.2), 0.45, 0.06, 8, (0.0, 0.0, 0.0))
    k.box("rust", 2.4, 4.4, -6.2, -4.6, top + 0.12, top + 0.28)                         # eski taban
    # su deposu
    tx, ty = -5.5, 5.5
    for lx, ly in ((-0.9, -0.9), (0.9, -0.9), (-0.9, 0.9), (0.9, 0.9)):
        k.box("rust", tx + lx - 0.1, tx + lx + 0.1, ty + ly - 0.1, ty + ly + 0.1, top + 0.12, top + 1.9)
    k.cyl("wood", (tx, ty, top + 3.0), 1.35, 2.2, 10)
    k.cyl("rust", (tx, ty, top + 2.5), 1.4, 0.14, 10)
    k.cyl("rust", (tx, ty, top + 3.5), 1.4, 0.14, 10)
    k.cyl("soot", (tx, ty, top + 4.15), 1.0, 0.2, 10)
    # bacalar ve çıkış kulesi
    for bx, by, hh in ((-1.5, 6.5, 3.0), (6.0, 6.2, 2.3)):
        k.box("brick", bx - 0.5, bx + 0.5, by - 0.5, by + 0.5, top + 0.12, top + hh)
        k.box("concrete", bx - 0.65, bx + 0.65, by - 0.65, by + 0.65, top + hh, top + hh + 0.2)
    k.box("concrete", -8.0, -5.4, -1.0, 1.4, top + 0.12, top + 2.6)
    k.box("soot", -8.1, -5.3, -1.1, 1.5, top + 2.6, top + 2.75)
    k.box("rust", -6.1, -5.3, -0.3, 0.7, top + 0.12, top + 2.0)
    # dağınık enkaz
    for _ in range(16):
        x = rng.uniform(-8.5, 8.5)
        y = rng.uniform(-8.0, 8.5)
        if HOLE[0] - 0.5 < x < HOLE[1] + 0.5 and HOLE[2] - 0.5 < y < HOLE[3] + 0.5:
            continue
        s = rng.uniform(0.25, 0.7)
        k.wbox(rng.choice(["soot", "brick", "concrete", "brick"]), (x, y, top + 0.12 + s * 0.25),
               (s, s * rng.uniform(0.6, 1.2), s * 0.5), (rng.uniform(-.3, .3), rng.uniform(-.3, .3), rng.uniform(0, 3)))
    # kir ve su lekeleri: koyu yamalar + hafif parlak su birikintileri (kademeli yükseklik, z-çakışma yok)
    patches = [(-3.0, 3.0, 4.0, 3.0, "soot"), (6.0, 1.0, 3.0, 2.4, "soot"), (-6.5, -2.5, 3.0, 2.0, "soot"),
               (2.0, -1.5, 2.6, 1.8, "soot"), (-1.0, 8.0, 4.0, 1.4, "soot"), (7.0, -2.0, 2.0, 2.2, "soot"),
               (-6.0, 8.0, 2.0, 1.6, "soot"), (0.5, 6.0, 1.6, 1.4, "soot")]
    for i, (cx, cy, sx, sy, mat) in enumerate(patches):
        k.wbox(mat, (cx, cy, top + 0.125 + i * 0.006), (sx, sy, 0.01), (0, 0, rng.uniform(0, 3)))
    puddles = [(-4.0, 3.3, 2.0, 1.0), (6.3, 1.4, 1.5, 0.8), (-6.5, -2.4, 1.8, 0.9), (2.2, -1.2, 1.2, 0.8), (-0.6, 8.0, 1.8, 0.6)]
    for i, (cx, cy, sx, sy) in enumerate(puddles):
        k.wbox("glass", (cx, cy, top + 0.14 + i * 0.006), (sx, sy, 0.01), (0, 0, rng.uniform(0, 3)))


def bands(k: ck.Kit) -> None:
    for fac in "XY":
        a, b = (-HALF, HALF)
        k.fbox(fac, "concrete", a, b, 0, 0.22, GROUND_H - 0.1, GROUND_H + 0.25)
        k.fbox(fac, "concrete", a, b, 0, 0.14, 7.55, 7.75)
        k.fbox(fac, "concrete", a, b, 0, 0.18, 0, 0.5)
    # üst korniş yalnız çökmemiş kısımda
    k.fbox("X", "concrete", -CUT, HALF, 0, 0.4, H - 0.4, H)
    k.fbox("Y", "concrete", -HALF, CUT, 0, 0.4, H - 0.4, H)


def streak(k: ck.Kit, fac: str, u: float, z0: float, length: float, width: float) -> None:
    z1 = min(z0 + length, H - 0.45)
    if z1 - z0 < 0.4:
        return
    mid = z0 + (z1 - z0) * 0.55
    k.fbox(fac, "soot", u - width / 2, u + width / 2, 0, 0.03, z0, mid)
    k.fbox(fac, "soot", u - width * 0.3, u + width * 0.3, 0, 0.03, mid, z1)


def window(k: ck.Kit, fac: str, u: float, z: float, state: str) -> None:
    w, h = WIN_W, WIN_H
    k.fbox(fac, "concrete", u - w / 2 - 0.18, u + w / 2 + 0.18, 0, 0.32, z - 0.18, z)
    k.fbox(fac, "concrete", u - w / 2 - 0.15, u + w / 2 + 0.15, 0, 0.2, z + h, z + h + 0.2)
    k.fbox(fac, "concrete", u - w / 2 - 0.15, u - w / 2, 0, 0.12, z, z + h)
    k.fbox(fac, "concrete", u + w / 2, u + w / 2 + 0.15, 0, 0.12, z, z + h)
    if state == "lit":
        k.fbox(fac, "warm", u - w / 2, u + w / 2, 0, 0.08, z, z + h)
        k.fbox(fac, "soot", u - w / 2, u + w / 2, 0.08, 0.1, z + h * 0.62, z + h)
    elif state == "dark":
        k.fbox(fac, "glass", u - w / 2, u + w / 2, 0, 0.08, z, z + h)
        k.fbox(fac, "concrete", u - 0.04, u + 0.04, 0.08, 0.12, z, z + h)
    elif state == "boarded":
        k.fbox(fac, "soot", u - w / 2, u + w / 2, 0, 0.08, z, z + h)
        for zz in (z + 0.1, z + 0.7, z + 1.3):
            k.fbox(fac, "wood", u - w / 2 - 0.1, u + w / 2 + 0.1, 0.1, 0.2, zz, zz + 0.38,
                   tilt=("uz", math.radians(rng.uniform(-6, 6))))
    elif state == "broken":
        k.fbox(fac, "soot", u - w / 2, u + w / 2, 0, 0.08, z, z + h)
        k.fbox(fac, "glass", u - w / 2, u - w / 2 + 0.45, 0.08, 0.1, z + h - 0.7, z + h, tilt=("uz", math.radians(20)))
        k.fbox(fac, "glass", u + w / 2 - 0.4, u + w / 2, 0.08, 0.1, z, z + 0.4, tilt=("uz", math.radians(-30)))
    # pencere üstünden yukarı uzanan is izi (kırık/yanan pencerelerde uzun) ve sövenin altına akıntı
    long = state in ("broken", "lit")
    streak(k, fac, u + rng.uniform(-0.15, 0.15), z + h + 0.2, rng.uniform(2.2, 3.4) if long else rng.uniform(1.0, 2.2),
           rng.uniform(1.1, 1.8) if long else rng.uniform(0.6, 1.1))
    if rng.random() < 0.7:
        streak(k, fac, u + rng.uniform(-0.5, 0.5), z - rng.uniform(1.1, 1.9), 1.6, 0.35)


def windows(k: ck.Kit) -> None:
    for fac in "XY":
        for fl, z in zip(("F2", "F3"), WIN_Z):
            for u, state in zip(WIN_U, WINDOWS[fac][fl]):
                if state:
                    window(k, fac, u, z, state)
        # kemerlerde ek dikey kir izleri
        for u in (-9.0, -5.4, -1.8, 1.8, 5.4, 9.0):
            if rng.random() < 0.7:
                streak(k, fac, u, rng.uniform(4.4, 6.5), rng.uniform(2.0, 4.0), rng.uniform(0.4, 0.9))
    # yanık iç köşe: iki cephede büyük kararma
    for fac, us in (("X", (-9.1, -5.2)), ("Y", (9.1, 5.2))):
        for u in us:
            streak(k, fac, u, 4.4, 2.8, 1.1)
            streak(k, fac, u + 0.3, 3.3, 3.8, 0.5)


def storefront(k: ck.Kit) -> None:
    for fac in "XY":
        for p0, p1 in ((-9.5, -8.5), (-3.5, -2.5), (2.5, 3.5), (8.5, 9.5)):
            k.fbox(fac, "brick", p0, p1, 0, 0.26, 0.5, 3.45)
            k.fbox(fac, "concrete", p0 - 0.06, p1 + 0.06, 0, 0.32, 3.45, 3.6)
        for u, state in zip(BAY_U, BAYS[fac]):
            a, b = u - 2.3, u + 2.3
            k.fbox(fac, "concrete", u - 2.5, u + 2.5, 0, 0.22, 3.2, 3.45)
            k.fbox(fac, "soot", a, b, 0, 0.06, 0.5, 3.2)
            if state == "broken":
                k.fbox(fac, "glass", a, a + 1.3, 0.06, 0.09, 1.6, 3.2)
                k.fbox(fac, "glass", b - 1.1, b, 0.06, 0.09, 2.3, 3.2, tilt=("uz", math.radians(8)))
                k.fbox(fac, "glass", a + 1.2, a + 1.9, 0.06, 0.09, 0.6, 1.1, tilt=("uz", math.radians(-35)))
                k.fbox(fac, "glass", u - 0.5, u + 0.5, 0.06, 0.09, 0.5, 0.9, tilt=("uz", math.radians(25)))
                k.fbox(fac, "concrete", u - 0.05, u + 0.05, 0.06, 0.12, 0.5, 3.2)
            elif state == "shutter":
                k.fbox(fac, "rust", a, b, 0.04, 0.12, 1.45, 3.2)
                for r in range(7):
                    zz = 1.5 + r * 0.25
                    k.fbox(fac, "rust", a - 0.05, b + 0.05, 0.12, 0.18, zz, zz + 0.1)
                k.fbox(fac, "rust", a, b, 0.0, 0.2, 1.3, 1.45)
                k.fbox(fac, "glass", a, b, 0.06, 0.09, 0.5, 1.3)
            elif state == "boarded":
                for i in range(5):
                    zz = 0.6 + i * 0.55
                    k.fbox(fac, "wood", a - 0.1, b + 0.1, 0.07, 0.17, zz, zz + 0.42,
                           tilt=("uz", math.radians(rng.uniform(-3, 3))))
            elif state == "open":
                k.fbox(fac, "glass", a, a + 0.8, 0.06, 0.09, 2.2, 3.2, tilt=("uz", math.radians(-12)))
                k.fbox(fac, "glass", b - 0.6, b, 0.06, 0.09, 0.5, 0.9, tilt=("uz", math.radians(30)))
    # tabela kutuları (yazısız); Y'dekinin bir ucu düşmüş
    k.fbox("X", "concrete", -2.4, 2.4, 0, 0.5, 3.62, 4.2)
    k.fbox("X", "soot", -2.2, 2.2, 0.5, 0.54, 3.72, 4.1)
    k.fbox("Y", "concrete", 3.6, 8.4, 0, 0.5, 3.62, 4.2, tilt=("uz", math.radians(-7)))
    k.fbox("Y", "soot", 3.8, 8.2, 0.5, 0.54, 3.72, 4.1, tilt=("uz", math.radians(-7)))
    # tenteler: solmuş şeritli; biri yırtık ve sarkık
    k.fbox("X", "awning", -8.3, -3.7, 0.0, 1.9, 3.1, 3.2, tilt=("dz", math.radians(-20)))
    k.fbox("X", "awning", 3.7, 6.4, 0.0, 1.9, 3.1, 3.2, tilt=("dz", math.radians(-30)))
    k.fbox("X", "awning", 6.5, 8.3, 0.0, 1.5, 1.3, 1.38, tilt=("dz", math.radians(-70)))      # yırtık sarkan parça
    k.fbox("Y", "awning", -2.3, 2.3, 0.0, 1.9, 3.1, 3.2, tilt=("dz", math.radians(-22)))
    k.fbox("Y", "awning", -8.0, -4.2, 0.0, 1.9, 3.1, 3.2, tilt=("dz", math.radians(-16)))


def fire_escape(k: ck.Kit) -> None:
    fac = "X"
    u0, u1 = 2.2, 5.0
    for z in (4.6, 8.0):
        k.fbox(fac, "rust", u0, u1, 0.0, 1.5, z, z + 0.1)
        k.fbox(fac, "rust", u0, u1, 1.4, 1.5, z + 0.9, z + 1.0)
        for pu in (u0, (u0 + u1) / 2, u1):
            k.fbox(fac, "rust", pu - 0.04, pu + 0.04, 1.42, 1.48, z + 0.1, z + 0.95)
        k.fbox(fac, "rust", u0, u0 + 0.08, 0.0, 1.5, z + 0.9, z + 1.0)
        k.fbox(fac, "rust", u1 - 0.08, u1, 0.0, 1.5, z + 0.9, z + 1.0)

    def stair(ua, za, ub, zb):
        n = 7
        ang = math.atan2(zb - za, ub - ua)
        for i in range(n):
            t = (i + 0.5) / n
            cu = ua + (ub - ua) * t
            cz = za + (zb - za) * t
            k.fbox(fac, "rust", cu - 0.2, cu + 0.2, 0.3, 1.1, cz - 0.03, cz + 0.03)
        mu, mz = (ua + ub) / 2, (za + zb) / 2
        ln = math.hypot(ub - ua, zb - za) / 2
        for d in (0.3, 1.1):
            k.fbox(fac, "rust", mu - ln, mu + ln, d - 0.04, d + 0.04, mz + 0.9, mz + 0.98, tilt=("uz", ang))
            k.fbox(fac, "rust", mu - ln, mu + ln, d - 0.04, d + 0.04, mz - 0.1, mz, tilt=("uz", ang))
    stair(u1, 8.0, 7.4, 4.7)
    stair(u0, 4.6, -0.3, 0.5)
    k.fbox(fac, "rust", 4.9, 5.0, 0.0, 0.1, 8.0, 11.0)


def rubble(k: ck.Kit) -> None:
    # iç köşedeki çöküntüden kaldırıma düşen moloz (kaldırım d <= 2.5, taşma yok)
    for fac, u_lo, u_hi in (("X", -9.2, -3.6), ("Y", 3.6, 9.2)):
        for _ in range(26):
            u = rng.uniform(u_lo, u_hi)
            d = rng.uniform(0.35, 2.4)
            hh = max(0.0, 0.7 - d * 0.22)
            c = ck.Kit.fmap(fac, u, d, 0.09 + hh * rng.random())
            s = rng.uniform(0.22, 0.5)
            mat = rng.choice(["brick", "brick", "brick", "concrete", "soot"])
            k.wbox(mat, c, (s, s * 0.5, s * 0.45),
                   (rng.uniform(-.5, .5), rng.uniform(-.5, .5), rng.uniform(0, 6.28)))
        mid = (u_lo + u_hi) / 2
        k.fbox(fac, "soot", mid - 2.5, mid + 2.5, 0.4, 1.9, 0.0, 0.04)
        k.fbox(fac, "concrete", mid - 1.0, mid + 1.0, 0.5, 1.5, 0.07, 0.5, tilt=("dz", math.radians(14)))
    # köşede iri düşmüş kolon parçası
    k.wbox("brick", ck.Kit.fmap("X", -7.0, 1.3, 0.35), (1.4, 0.9, 0.7), (0.1, 0.0, 0.5))
    k.wbox("brick", ck.Kit.fmap("Y", 7.0, 1.2, 0.35), (1.2, 0.8, 0.7), (0.0, 0.1, -0.4))


def street_clutter(k: ck.Kit) -> None:
    # çöp torbaları
    for fac, u0, cnt in (("X", -1.8, 5), ("Y", -6.6, 4), ("X", 8.2, 3), ("Y", 1.8, 4)):
        for _ in range(cnt):
            u = u0 + rng.uniform(-0.8, 0.8)
            d = rng.uniform(0.5, 1.6)
            s = rng.uniform(0.4, 0.65)
            k.wbox("soot", ck.Kit.fmap(fac, u, d, s * 0.4), (s, s * 0.85, s * 0.8),
                   (rng.uniform(-.2, .2), rng.uniform(-.2, .2), rng.uniform(0, 6.28)))
    # devrik yanmış çöp kutusu
    k.cyl("rust", ck.Kit.fmap("X", -1.6, 2.1, 0.4), 0.38, 0.95, 8, (0.0, 1.5708, 0.4))
    k.wbox("soot", ck.Kit.fmap("X", -1.6, 2.1, 0.02), (1.3, 0.9, 0.04))
    # yanmış sandık ve tahta yığını
    for i in range(4):
        k.wbox(rng.choice(["soot", "wood"]), ck.Kit.fmap("Y", -2.4 + i * 0.55, 1.7 + rng.uniform(-0.2, 0.3), 0.25 + 0.2 * (i % 2)),
               (0.6, 0.6, 0.5), (0, 0, rng.uniform(0, 3)))
    # düşmüş tabela: yazısız, yaslanmış
    k.fbox("Y", "concrete", -2.2, 0.8, 0.9, 1.4, 0.1, 1.0, tilt=("dz", math.radians(55)))
    k.fbox("Y", "soot", -2.0, 0.6, 0.78, 0.82, 0.25, 0.85, tilt=("dz", math.radians(55)))


def main() -> None:
    ck.reset_scene()
    mats = ck.make_materials()
    k = ck.Kit()
    body(k)
    bands(k)
    roof(k)
    storefront(k)
    windows(k)
    fire_escape(k)
    rubble(k)
    street_clutter(k)
    objs = k.finalize(mats)
    print("[building_a] üçgen:", ck.tri_count(objs), "malzeme:", len(mats))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    os.makedirs(SHOTS, exist_ok=True)
    for o in bpy.data.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_yup=True,
                              export_apply=True, export_image_format="AUTO", export_animations=False)
    tgt = (4.5, -4.5, 1.0)
    c60 = 24 * math.cos(math.radians(60)) * 0.7071
    pos = (tgt[0] + c60, tgt[1] - c60, tgt[2] + 24 * math.sin(math.radians(60)))
    ck.render_shot(os.path.join(SHOTS, "building_a_game.png"), "night", pos, tgt, 50)
    ck.render_shot(os.path.join(SHOTS, "building_a_day.png"), "day", (30, -30, 18), (0, 0, 5), 38, (1100, 800))


main()
