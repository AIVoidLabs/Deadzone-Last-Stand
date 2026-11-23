"""Silah amblemleri (10): weapon_<id>.png. Oyun GLB'sindeki (assets/models/weapons/weapons.glb, build_weapons.py)
ölçülerle aynı iskelet; amblem için daha kalın, bevelli, ayrıntılı (vida, şarjör, sargı, kovan) yeniden kurulur.
Oyun GLB'sine dokunulmaz.

Çalıştırma (repo kökünden):
    blender --background --python tools/blender/ui_emblems_weapons.py [-- pistol katana ...]
Çıktı: assets/textures/ui/emblems/weapon_<id>.png (512x512 saydam).
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ui_ink as U  # noqa: E402

T: float = 1.0  # emblem için gövde kalınlığı çarpanı (x ve z); uzunluk (y) değişmez
_count: list = [0]
M: dict = {}


def mats() -> dict:
    return {
        "metal": U.mat("metal", (0.30, 0.31, 0.34), 0.35, 0.5),
        "dark": U.mat("dark", (0.10, 0.10, 0.11), 0.55, 0.2),
        "navy": U.mat("navy", (0.20, 0.26, 0.36), 0.45, 0.35),
        "orange": U.mat("orange", (0.95, 0.5, 0.15), 0.5),
        "wood": U.mat("wood", (0.50, 0.30, 0.15), 0.7),
        "steel": U.mat("steel", (0.58, 0.65, 0.76), 0.25, 0.6),
        "edge": U.mat("edge", (0.90, 0.95, 1.0), 0.2, 0.5),
        "gold": U.mat("gold", (0.85, 0.65, 0.22), 0.3, 0.6),
        "cyan": U.mat("cyan", (0.3, 0.78, 1.0), 0.3, 0.0, emit=(0.3, 0.78, 1.0), emit_strength=3.0),
        "white": U.mat("white", (0.95, 0.97, 1.0), 0.3, 0.0, emit=(0.9, 0.97, 1.0), emit_strength=4.0),
        "yellow": U.mat("yellow", (1.0, 0.78, 0.18), 0.3, 0.0, emit=(1.0, 0.8, 0.2), emit_strength=4.0),
        "ember": U.mat("ember", (1.0, 0.36, 0.06), 0.3, 0.0, emit=(1.0, 0.35, 0.05), emit_strength=3.5),
        "leather": U.mat("leather", (0.28, 0.16, 0.09), 0.8),
        "violet": U.mat("violet", (0.78, 0.30, 0.95), 0.3, 0.0, emit=(0.78, 0.30, 0.95), emit_strength=3.0),
        "olive": U.mat("olive", (0.34, 0.40, 0.22), 0.6, 0.1),
        "brass": U.mat("brass", (0.82, 0.6, 0.2), 0.3, 0.7),
        "red": U.mat("red", (0.7, 0.08, 0.07), 0.5),
        "bone": U.mat("bone", (0.9, 0.86, 0.75), 0.6),
    }


def _n(prefix: str) -> str:
    _count[0] += 1
    return "%s%d" % (prefix, _count[0])


def bx(c: tuple, s: tuple, m: str, rot: tuple = (0, 0, 0), bev: float = 0.003) -> object:
    """Bevelli kutu; merkez ve boyut x/z'de T ile kalınlaşır."""
    return U.box(_n("b"), (c[0] * T, c[1], c[2] * T), (s[0] * T, s[1], s[2] * T), M[m], rot, bevel=bev * T)


def tb(c: tuple, r: float, length: float, m: str, axis: str = "Y", rot: tuple = (0, 0, 0), r2: float = None,
       segs: int = 24, bev: float = 0.0) -> object:
    """Silindir/koni (ekseni boyunca uzunluk); yarıçap T ile büyür (eksen Y ise)."""
    k = T
    return U.cyl(_n("t"), (c[0] * T, c[1], c[2] * T), r * k, length, M[m], axis, rot,
                 None if r2 is None else r2 * k, segs, bev * T)


def ball(c: tuple, r: tuple, m: str, rot: tuple = (0, 0, 0)) -> object:
    return U.sphere(_n("s"), (c[0] * T, c[1], c[2] * T), (r[0] * T, r[1], r[2] * T), M[m], rot)


def ring(c: tuple, major: float, minor: float, m: str, rot: tuple = (90, 0, 0)) -> object:
    """Y ekseni etrafında halka (varsayılan rot ile yüzü Y'ye bakar)."""
    return U.torus(_n("r"), (c[0] * T, c[1], c[2] * T), major * T, minor * T, M[m], rot)


def screw(c: tuple, r: float, side: float = 1.0) -> None:
    """Yan yüzeyde vida: x ekseninde kısa silindir (başında yarık)."""
    tb(c, r, 0.004, "steel", axis="X", segs=12)
    x = c[0] + 0.0025 * side
    bx((x, c[1], c[2]), (0.002, r * 1.6, 0.0035), "dark", bev=0.0005)


def bolts(xs: float, pts: list, r: float = 0.004) -> None:
    for (y, z) in pts:
        screw((xs, y, z), r, 1.0 if xs > 0 else -1.0)


def parts_pistol() -> None:
    # slide + gövde
    bx((0, -0.045, 0.030), (0.030, 0.190, 0.036), "metal", bev=0.004)
    bx((0, -0.040, 0.000), (0.027, 0.165, 0.026), "navy", bev=0.004)
    bx((0.0, 0.035, -0.052), (0.026, 0.050, 0.100), "dark", rot=(-10, 0, 0), bev=0.004)
    # kabza panelleri + vida + tırtık
    for sd in (1, -1):
        x = 0.0145 * sd
        bx((x, 0.036, -0.052), (0.004, 0.044, 0.092), "wood", rot=(-10, 0, 0), bev=0.001)
        for i in range(6):
            bx((x + 0.0025 * sd, 0.024 + i * 0.0062, -0.052 - i * 0.0), (0.002, 0.0022, 0.08), "dark",
               rot=(-10, 0, 0), bev=0.0004)
        screw((x + 0.002 * sd, 0.042, -0.030), 0.0045, sd)
    # kızak tırtığı (arka)
    for sd in (1, -1):
        for i in range(7):
            bx((0.0155 * sd, 0.012 + i * 0.0085, 0.031), (0.002, 0.0035, 0.030), "dark", bev=0.0005)
        bx((0.016 * sd, -0.07, 0.040), (0.0025, 0.05, 0.016), "dark", bev=0.0005)  # atış penceresi
        bx((0.0165 * sd, -0.06, 0.030), (0.003, 0.100, 0.0085), "orange", bev=0.0006)
    # nişangah, arka nişan, horoz
    bx((0, -0.134, 0.052), (0.007, 0.012, 0.012), "dark", bev=0.001)
    bx((0, 0.043, 0.052), (0.020, 0.012, 0.010), "dark", bev=0.001)
    bx((0, 0.056, 0.040), (0.008, 0.016, 0.014), "metal", rot=(25, 0, 0), bev=0.001)
    # namlu ağzı: delikli
    tb((0, -0.150, 0.030), 0.0105, 0.020, "steel", segs=24)
    tb((0, -0.1605, 0.030), 0.0065, 0.002, "dark", segs=16)
    # tetik korkuluğu + tetik
    bx((0, -0.035, -0.027), (0.008, 0.055, 0.005), "dark", bev=0.001)
    bx((0, -0.060, -0.020), (0.008, 0.005, 0.020), "dark", bev=0.001)
    bx((0, -0.010, -0.027), (0.008, 0.005, 0.030), "dark", rot=(-12, 0, 0), bev=0.001)
    bx((0, -0.013, -0.014), (0.005, 0.005, 0.020), "steel", rot=(18, 0, 0), bev=0.0008)
    # şarjör tabanı
    bx((0.0, 0.043, -0.108), (0.030, 0.052, 0.008), "steel", rot=(-10, 0, 0), bev=0.0015)
    bx((0.0, 0.043, -0.1155), (0.026, 0.044, 0.004), "dark", rot=(-10, 0, 0), bev=0.0008)


def parts_shotgun() -> None:
    tb((0, -0.360, 0.040), 0.014, 0.600, "metal", axis="Y", segs=24)
    tb((0, -0.300, 0.012), 0.013, 0.440, "dark", axis="Y", segs=24)
    for y in (-0.62, -0.50, -0.40):
        tb((0, y, 0.040), 0.0175, 0.014, "steel", axis="Y", segs=24)
        tb((0, y, 0.012), 0.0165, 0.014, "steel", axis="Y", segs=24)
    tb((0, -0.665, 0.040), 0.0165, 0.012, "orange", axis="Y")
    tb((0, -0.6725, 0.040), 0.0095, 0.004, "dark", axis="Y", segs=16)
    bx((0, -0.655, 0.058), (0.006, 0.014, 0.014), "dark", bev=0.001)
    # pompa kabzası (tırtıklı)
    bx((0, -0.300, 0.020), (0.044, 0.170, 0.048), "wood", bev=0.006)
    for i in range(9):
        bx((0, -0.374 + i * 0.019, 0.020), (0.046, 0.006, 0.050), "dark", bev=0.001)
    bx((0, -0.035, 0.025), (0.042, 0.190, 0.072), "navy", bev=0.005)
    for sd in (1, -1):
        bx((0.0215 * sd, -0.05, 0.034), (0.003, 0.070, 0.016), "dark", bev=0.001)  # yükleme penceresi
        bx((0.0215 * sd, -0.04, 0.012), (0.003, 0.120, 0.010), "orange", bev=0.001)
        screw((0.0225 * sd, 0.025, 0.040), 0.005, sd)
        screw((0.0225 * sd, -0.12, 0.030), 0.005, sd)
    bx((0, -0.010, -0.030), (0.012, 0.075, 0.006), "dark", bev=0.001)
    bx((0, -0.038, -0.020), (0.012, 0.006, 0.024), "dark", bev=0.001)
    bx((0, -0.012, -0.015), (0.006, 0.006, 0.026), "steel", rot=(15, 0, 0), bev=0.001)
    bx((0, 0.110, 0.005), (0.038, 0.130, 0.058), "wood", bev=0.006)
    bx((0, 0.240, -0.022), (0.042, 0.150, 0.090), "wood", rot=(-8, 0, 0), bev=0.008)
    bx((0, 0.322, -0.026), (0.044, 0.014, 0.095), "dark", rot=(-8, 0, 0), bev=0.002)
    # fişek kemeri (dipçik yanı)
    for i in range(4):
        y = 0.185 + i * 0.026
        tb((0.0225, y, -0.015), 0.0085, 0.060, "red", axis="Z", rot=(0, 0, 0), segs=14)
        tb((0.0225, y, -0.043), 0.0092, 0.012, "brass", axis="Z", segs=14)
        bx((0.0215, y, -0.0), (0.004, 0.003, 0.003), "dark")
    bx((0.0225, 0.24, -0.040), (0.004, 0.130, 0.006), "leather", bev=0.001)
    ring((0.0, 0.26, -0.070), 0.012, 0.0025, "steel", rot=(0, 0, 0))


def parts_smg() -> None:
    bx((0, -0.030, 0.010), (0.034, 0.250, 0.050), "metal", bev=0.005)
    bx((0, -0.150, 0.020), (0.030, 0.110, 0.036), "navy", bev=0.004)
    for i in range(5):
        for sd in (1, -1):
            tb((0.0155 * sd, -0.115 - i * 0.018, 0.020), 0.0055, 0.004, "dark", axis="X", segs=14)
    tb((0, -0.215, 0.020), 0.011, 0.070, "dark", axis="Y", segs=20)
    tb((0, -0.255, 0.020), 0.0135, 0.014, "steel", axis="Y", segs=20)
    tb((0, -0.2625, 0.020), 0.007, 0.003, "dark", axis="Y", segs=14)
    # uzun şarjör, hafif eğik
    bx((0.0, -0.002, -0.082), (0.024, 0.045, 0.100), "dark", rot=(0, 0, 0), bev=0.003)
    bx((0.0, 0.004, -0.150), (0.024, 0.045, 0.060), "dark", rot=(-9, 0, 0), bev=0.003)
    bx((0.0, 0.009, -0.186), (0.027, 0.050, 0.010), "steel", rot=(-9, 0, 0), bev=0.0015)
    for i in range(4):
        bx((0.0125, 0.0, -0.06 - i * 0.026), (0.002, 0.036, 0.004), "orange", bev=0.0003)
        bx((-0.0125, 0.0, -0.06 - i * 0.026), (0.002, 0.036, 0.004), "orange", bev=0.0003)
    bx((0.0, 0.068, -0.045), (0.026, 0.040, 0.085), "dark", rot=(-14, 0, 0), bev=0.004)
    for i in range(5):
        for sd in (1, -1):
            bx((0.0138 * sd, 0.062 + i * 0.0045, -0.046), (0.002, 0.002, 0.07), "metal", rot=(-14, 0, 0), bev=0.0003)
    bx((0, -0.080, -0.030), (0.020, 0.018, 0.034), "dark", bev=0.003)  # ön tutamak kökü
    # tel dipçik
    for sd in (1, -1):
        tb((0.010 * sd, 0.200, 0.014), 0.0035, 0.150, "steel", axis="Y", segs=10)
        tb((0.010 * sd, 0.200, -0.020), 0.0035, 0.150, "steel", axis="Y", segs=10)
    bx((0, 0.282, -0.003), (0.026, 0.010, 0.060), "dark", bev=0.002)
    bx((0, 0.123, -0.003), (0.028, 0.012, 0.050), "metal", bev=0.002)
    # nişangah, kol
    bx((0, -0.050, 0.050), (0.010, 0.050, 0.014), "orange", bev=0.002)
    bx((0, -0.225, 0.046), (0.006, 0.010, 0.020), "dark", bev=0.001)
    bx((0, 0.085, 0.052), (0.020, 0.012, 0.018), "dark", bev=0.001)
    bx((0.025, 0.020, 0.026), (0.018, 0.020, 0.010), "steel", bev=0.002)  # sürgü kolu
    for sd in (1, -1):
        bx((0.0175 * sd, -0.050, 0.020), (0.003, 0.120, 0.010), "orange", bev=0.0008)
        screw((0.0175 * sd, 0.060, 0.026), 0.0045, sd)
        screw((0.0175 * sd, 0.100, 0.0), 0.0045, sd)
    bx((0, -0.015, -0.030), (0.008, 0.050, 0.005), "dark", bev=0.001)


def parts_plasma() -> None:
    bx((0, -0.020, 0.020), (0.052, 0.340, 0.062), "navy", bev=0.006)
    bx((0, 0.0, 0.058), (0.040, 0.220, 0.016), "metal", bev=0.004)
    tb((0, -0.310, 0.030), 0.016, 0.230, "metal", axis="Y", segs=24)
    for y in (-0.225, -0.300, -0.375, -0.425):
        tb((0, y, 0.030), 0.028, 0.026, "cyan", axis="Y", segs=24)
        tb((0, y - 0.016, 0.030), 0.030, 0.006, "dark", axis="Y", segs=24)
    tb((0, -0.445, 0.030), 0.012, 0.014, "white", axis="Y", segs=20)
    tb((0, -0.455, 0.030), 0.009, 0.004, "dark", axis="Y", segs=16)
    # cam pencere + çekirdek şeridi
    bx((0, -0.090, 0.0545), (0.030, 0.170, 0.008), "cyan", bev=0.002)
    bx((0, -0.090, 0.050), (0.036, 0.184, 0.004), "dark", bev=0.001)
    for i in range(6):
        bx((0.0, -0.016 - i * 0.026, 0.080), (0.010, 0.008, 0.040 - i * 0.003), "cyan", bev=0.001)
    # soğutma yüzgeçleri + kablo
    for sd in (1, -1):
        for i in range(5):
            bx((0.0265 * sd, -0.12 + i * 0.024, 0.028), (0.003, 0.012, 0.050), "dark", bev=0.001)
        bx((0.0265 * sd, -0.030, 0.020), (0.003, 0.200, 0.010), "orange", bev=0.001)
        screw((0.0275 * sd, 0.12, 0.030), 0.005, sd)
        screw((0.0275 * sd, 0.12, 0.002), 0.005, sd)
    U.tube(_n("cab"), [(0.02 * T, 0.07, -0.01), (0.03 * T, 0.0, -0.05), (0.04 * T, -0.15, -0.035), (0.03 * T, -0.24, 0.0),
                       (0.02 * T, -0.30, 0.012)], 0.004 * T, M["dark"], segs=8)
    bx((0, 0.080, -0.050), (0.030, 0.050, 0.100), "dark", rot=(-8, 0, 0), bev=0.004)
    bx((0, 0.200, 0.000), (0.046, 0.150, 0.062), "navy", bev=0.006)
    bx((0, 0.282, 0.0), (0.048, 0.014, 0.066), "dark", bev=0.002)
    bx((0, -0.010, -0.035), (0.010, 0.060, 0.005), "dark", bev=0.001)
    # üst dürbün
    tb((0, 0.050, 0.095), 0.011, 0.100, "dark", axis="Y", segs=16)
    tb((0, 0.0, 0.095), 0.014, 0.010, "cyan", axis="Y", segs=16)


def parts_gravity() -> None:
    tb((0, -0.050, 0.020), 0.034, 0.200, "metal", axis="Y", segs=24)
    for y in (-0.01, -0.07):
        tb((0, y, 0.020), 0.037, 0.012, "dark", axis="Y", segs=24)
    tb((0, -0.120, 0.020), 0.042, 0.030, "violet", axis="Y", segs=24)
    # tabak: konik huni
    tb((0, -0.200, 0.020), 0.075, 0.075, "navy", axis="Y", r2=0.038, segs=28)
    tb((0, -0.2425, 0.020), 0.0785, 0.010, "steel", axis="Y", segs=28)
    tb((0, -0.2475, 0.020), 0.066, 0.006, "dark", axis="Y", segs=28)
    ball((0, -0.236, 0.020), (0.046, 0.030, 0.046), "violet")
    ball((0, -0.232, 0.020), (0.022, 0.018, 0.022), "white")
    for k0 in range(4):
        pts = []
        for i in range(14):
            t = i / 13
            a = math.radians(k0 * 90 + t * 420)
            r = 0.068 * (1 - t) + 0.012
            pts.append((math.cos(a) * r * T, -0.247 + t * 0.012, 0.020 * T + math.sin(a) * r * T))
        U.tube(_n("sw"), pts, 0.0072 * T, M["violet"], 0.5, 6, False)
    for k in range(6):
        a = math.radians(k * 60 + 15)
        x, z = math.cos(a) * 0.066, math.sin(a) * 0.066 + 0.020
        tb((x, -0.2455, z), 0.0055, 0.010, "steel", axis="Y", segs=6)
    bx((0, 0.070, 0.020), (0.052, 0.090, 0.056), "navy", bev=0.006)
    bx((0, 0.082, -0.050), (0.030, 0.050, 0.100), "dark", rot=(-8, 0, 0), bev=0.004)
    for i in range(5):
        bx((0, -0.015 - i * 0.026, 0.066), (0.008, 0.012, 0.030 - i * 0.003), "violet", bev=0.0015)
    for sd in (1, -1):
        bx((0.036 * sd, -0.07, 0.02), (0.003, 0.14, 0.010), "orange", bev=0.001)
        screw((0.0385 * sd, 0.09, 0.040), 0.005, sd)
        screw((0.0385 * sd, 0.09, 0.000), 0.005, sd)
    U.tube(_n("cab"), [(0.035 * T, 0.06, 0.0), (0.05 * T, -0.02, -0.03), (0.055 * T, -0.12, -0.015),
                       (0.045 * T, -0.17, 0.02)], 0.0045 * T, M["dark"], segs=8)
    bx((0, 0.015, -0.035), (0.010, 0.050, 0.005), "dark", bev=0.001)


def parts_grenade() -> None:
    tb((0, -0.220, 0.030), 0.040, 0.360, "olive", axis="Y", segs=28)
    for y in (-0.395, -0.320, -0.120, -0.060):
        tb((0, y, 0.030), 0.044, 0.016, "dark", axis="Y", segs=28)
    tb((0, -0.250, 0.030), 0.0445, 0.012, "orange", axis="Y", segs=28)
    tb((0, -0.200, 0.030), 0.0445, 0.012, "orange", axis="Y", segs=28)
    tb((0, -0.4075, 0.030), 0.048, 0.016, "metal", axis="Y", segs=28)
    tb((0, -0.4165, 0.030), 0.031, 0.002, "dark", axis="Y", segs=24)
    # namludan görünen bomba kafası
    U.lathe(_n("gr"), [(0.0, 0.0), (0.012, 0.0), (0.026, -0.016), (0.030, -0.034), (0.030, -0.050)],
            (0, -0.405 * 1.0, 0.030 * T), M["brass"], rot=(90, 0, 0), segs=24)
    tb((0, 0.0, 0.030), 0.050, 0.100, "metal", axis="Y", segs=24)  # tambur
    for k in range(6):
        a = math.radians(k * 60)
        tb((math.cos(a) * 0.036, 0.0, 0.030 + math.sin(a) * 0.036), 0.011, 0.105, "dark", axis="Y", segs=12)
    bx((0.0, 0.075, 0.0), (0.054, 0.150, 0.064), "navy", bev=0.006)
    bx((0, 0.062, -0.060), (0.030, 0.052, 0.100), "dark", rot=(-8, 0, 0), bev=0.004)
    bx((0, 0.205, 0.0), (0.042, 0.150, 0.072), "olive", bev=0.006)
    bx((0, 0.285, 0.0), (0.044, 0.014, 0.076), "dark", bev=0.002)
    bx((0, -0.100, 0.092), (0.010, 0.070, 0.036), "orange", bev=0.002)
    for i in range(4):
        bx((0, -0.080 - i * 0.016, 0.116 + i * 0.002), (0.012, 0.004, 0.012), "dark", bev=0.0008)
    # sarı-siyah uyarı çizgileri
    for i in range(5):
        bx((0.0, -0.285 + i * 0.012, 0.0735 + 0.0), (0.030, 0.006, 0.003), "yellow", bev=0.0006)
    for sd in (1, -1):
        screw((0.0335 * sd, 0.08, 0.020), 0.006, sd)
        screw((0.0335 * sd, 0.12, -0.010), 0.006, sd)
    bx((0, -0.005, -0.040), (0.010, 0.060, 0.005), "dark", bev=0.001)
    ring((0.0, 0.25, -0.050), 0.014, 0.0028, "steel", rot=(0, 0, 0))


def blade(name: str, y0: float, y1: float, width: float, thick: float, curve: float, m: str,
          edge_side: float = -1.0, tip: float = 0.10, back_thick: float = 0.0, segs: int = 36) -> object:
    """Eğri kılıç/bıçak ağzı: ağız tarafı keskin takoz kesiti; y0->y1 (y1 uca doğru, genelde negatif)."""
    verts: list = []
    faces: list = []
    L = abs(y1 - y0)
    for i in range(segs + 1):
        s = i / segs
        y = y0 + (y1 - y0) * s
        wv = width * (1.0 if s < 1.0 - tip else max(0.04, (1.0 - s) / tip))
        off = curve * s * s
        ex = off + edge_side * wv * 0.5
        bxp = off - edge_side * wv * 0.5
        verts += [(ex, y, 0.0), (bxp, y, thick), (bxp, y, -thick)]
        if i > 0:
            a = (i - 1) * 3
            b = i * 3
            faces += [(a, b, b + 1, a + 1), (a + 1, b + 1, b + 2, a + 2), (a + 2, b + 2, b, a)]
    n = segs * 3
    faces += [(0, 1, 2), (n, n + 2, n + 1)]
    return U.mesh_from(_n(name), [(v[0] * T, v[1], v[2] * T) for v in verts], faces, (0, 0, 0), (0, 0, 0), M[m])


def parts_knife() -> None:
    blade("bl", -0.002, -0.275, 0.034, 0.005, 0.0, "steel", tip=0.22)
    blade("edge", -0.004, -0.272, 0.010, 0.0062, 0.0, "edge", edge_side=-1.0, tip=0.22)
    bx((0.0, -0.140, 0.0), (0.004, 0.170, 0.0065), "dark", bev=0.0006)  # kan oluğu
    for i in range(7):  # sırt dişleri
        bx((0.017 * T, -0.030 - i * 0.012, 0.0), (0.0035, 0.006, 0.010), "dark", rot=(0, 0, 0), bev=0.0006)
    bx((0, 0.000, 0.0), (0.076, 0.016, 0.030), "metal", bev=0.003)
    bx((0, 0.062, 0.0), (0.030, 0.125, 0.034), "leather", bev=0.005)
    for i in range(7):
        bx((0, 0.015 + i * 0.016, 0.0), (0.034, 0.005, 0.038), "dark", bev=0.001)
    tb((0, 0.130, 0.0), 0.021, 0.020, "metal", axis="Y", segs=24)
    ring((0, 0.150, 0.0), 0.010, 0.003, "steel", rot=(90, 0, 0))
    for sd in (1, -1):
        screw((0.0, 0.0, 0.016 * sd), 0.005)


def hamon(y0: float, y1: float, width: float, thick: float, curve: float) -> None:
    """Hamon: ağız boyunca dalgalı parlak çizgi (üst yüzeyde ince şerit)."""
    segs = 90
    verts, faces = [], []
    for i in range(segs + 1):
        s = i / segs
        y = y0 + (y1 - y0) * s
        wv = width * (1.0 if s < 0.93 else max(0.04, (1.0 - s) / 0.07))
        ex = curve * s * s - wv * 0.5
        hw = (0.011 + 0.006 * math.sin(s * 70.0) + 0.004 * math.sin(s * 23.0)) * (1.0 if s < 0.93 else 0.3)
        z = (thick + 0.0007) * T
        verts += [(ex * T + 0.002 * T, y, z), ((ex + hw) * T + 0.002 * T, y, z)]
        if i > 0:
            a, b = (i - 1) * 2, i * 2
            faces.append((a, a + 1, b + 1, b))
    U.mesh_from(_n("hm"), verts, faces, (0, 0, 0), (0, 0, 0), M["edge"])


def parts_katana() -> None:
    blade("bl", -0.005, -0.960, 0.044, 0.0045, 0.075, "steel", tip=0.07)
    blade("edge", -0.008, -0.955, 0.013, 0.0055, 0.075, "edge", tip=0.07)
    hamon(-0.012, -0.95, 0.044, 0.0045, 0.075)
    # tsuba (siper): yuvarlak plaka
    tb((0, -0.010, 0.0), 0.052, 0.014, "gold", axis="Y", segs=32)
    tb((0, -0.010, 0.0), 0.040, 0.018, "dark", axis="Y", segs=32)
    tb((0, -0.010, 0.0), 0.012, 0.020, "gold", axis="Y", segs=16)
    for k in range(6):
        a = math.radians(k * 60)
        tb((math.cos(a) * 0.046, -0.010, math.sin(a) * 0.046), 0.0045, 0.020, "dark", axis="Y", segs=8)
    # sap: sargı çaprazları
    tb((0, 0.105, 0.0), 0.017, 0.205, "dark", axis="Y", segs=20)
    for i in range(11):
        for s in (1, -1):
            bx((0.0, 0.015 + i * 0.0185, 0.0), (0.0355, 0.010, 0.0355), "navy", rot=(0, 0, 40 * s), bev=0.002)
    tb((0, 0.205, 0.0), 0.021, 0.020, "gold", axis="Y", segs=24)
    tb((0, 0.2, 0.0), 0.0255, 0.008, "gold", axis="Y", segs=24)
    tb((0, 0.018, 0.0), 0.0245, 0.016, "gold", axis="Y", segs=24)
    ring((0.0, 0.222, 0.0), 0.012, 0.003, "orange", rot=(90, 0, 0))


def parts_lightsaber() -> None:
    tb((0, 0.150, 0.0), 0.024, 0.360, "metal", axis="Y", segs=28)
    for i in range(9):  # tırtıklı tutuş
        tb((0, 0.060 + i * 0.026, 0.0), 0.0285, 0.012, "dark", axis="Y", segs=28)
    for y in (0.250, 0.290):
        tb((0, y, 0.0), 0.030, 0.014, "steel", axis="Y", segs=28)
    tb((0, 0.318, 0.0), 0.034, 0.040, "metal", axis="Y", segs=28)  # kabza başı
    ball((0, 0.340, 0.0), (0.030, 0.018, 0.030), "steel")
    ring((0.0, 0.352, 0.0), 0.016, 0.004, "gold", rot=(90, 0, 0))
    bx((0.0, 0.200, 0.026), (0.020, 0.050, 0.010), "ember", bev=0.002)
    bx((0.0, 0.140, 0.026), (0.012, 0.012, 0.008), "steel", bev=0.001)
    for sd in (1, -1):
        bx((0.026 * sd, 0.185, 0.0), (0.004, 0.090, 0.012), "gold", bev=0.001)
        screw((0.0265 * sd, 0.112, 0.012), 0.005, sd)
    U.tube(_n("wire"), [(0.0, 0.01, 0.026 * T), (0.02 * T, 0.05, 0.034 * T), (0.0, 0.09, 0.026 * T)], 0.004 * T, M["dark"], 1.0, 6)
    tb((0, 0.000, 0.0), 0.034, 0.060, "steel", axis="Y", segs=28)  # yayıcı
    tb((0, -0.036, 0.0), 0.038, 0.014, "gold", axis="Y", segs=28)
    for k0 in range(4):
        a = math.radians(k0 * 90 + 45)
        bx((math.cos(a) * 0.036, -0.05, math.sin(a) * 0.036), (0.008, 0.030, 0.008), "steel", rot=(0, 0, 0), bev=0.001)
    # ince, uzun bıçak: çap kabzanın ~%55'i
    tb((0, -0.60, 0.0), 0.017, 1.12, "white", axis="Y", segs=20)
    ball((0, -1.16, 0.0), (0.017, 0.017, 0.017), "white")


def flame_strip(name: str, y0: float, y1: float, width: float, thick: float, phase: float, m: str,
                freq: float) -> object:
    """Alev dili: kenarı testere dişi gibi dalgalı, ucu sivri, ince elmas kesitli şerit."""
    segs = 70
    verts: list = []
    faces: list = []
    for i in range(segs + 1):
        s = i / segs
        y = y0 + (y1 - y0) * s
        taper = (1.0 - 0.45 * s) * (1.0 if s < 0.88 else max(0.03, (1.0 - s) / 0.12))
        tri = abs(((s * freq + phase) % 1.0) * 2.0 - 1.0)
        hw = width * 0.5 * taper * (0.62 + 0.38 * tri)
        verts += [(-hw * T, y, 0.0), (0.0, y, thick * T), (hw * T, y, 0.0), (0.0, y, -thick * T)]
        if i > 0:
            a, b = (i - 1) * 4, i * 4
            for k in range(4):
                faces.append((a + k, b + k, b + (k + 1) % 4, a + (k + 1) % 4))
    n = segs * 4
    faces += [(0, 1, 2, 3), (n + 3, n + 2, n + 1, n)]
    return U.mesh_from(_n(name), verts, faces, (0, 0, 0), (0, 0, 0), M[m])


def parts_flame() -> None:
    tb((0, 0.100, 0.0), 0.021, 0.205, "leather", axis="Y", segs=24)
    for i in range(10):
        tb((0, 0.010 + i * 0.020, 0.0), 0.0235, 0.007, "dark", axis="Y", segs=24)
    tb((0, 0.210, 0.0), 0.027, 0.022, "gold", axis="Y", segs=24)
    ball((0, 0.226, 0.0), (0.022, 0.012, 0.022), "gold")
    bx((0.0, -0.012, 0.0), (0.150, 0.020, 0.040), "gold", bev=0.004)
    for sd in (1, -1):
        bx((0.070 * sd, -0.030, 0.0), (0.030, 0.062, 0.030), "gold", rot=(0, 0, 12 * sd), bev=0.004)
        bx((0.095 * sd, -0.066, 0.0), (0.014, 0.060, 0.026), "gold", rot=(0, 0, 18 * sd), bev=0.003)
        ball((0.0, -0.014, 0.0), (0.0, 0.0, 0.0), "gold") if False else None
    tb((0, -0.020, 0.0), 0.022, 0.030, "ember", axis="Y", segs=20)
    # alev ağzı: dalgalı kenarlı üç katman (kor, sarı, beyaz çekirdek)
    flame_strip("f1", -0.04, -1.0, 0.115, 0.016, 0.0, "ember", 7.0)
    flame_strip("f2", -0.06, -0.92, 0.075, 0.020, 1.3, "yellow", 9.0)
    flame_strip("f3", -0.08, -0.80, 0.030, 0.022, 0.4, "white", 5.0)
    for i, (sx, sy) in enumerate([(0.07, -0.25), (-0.085, -0.45), (0.09, -0.62), (-0.06, -0.78), (0.05, -0.93)]):
        bx((sx, sy, 0.01), (0.012, 0.016, 0.012), "yellow" if i % 2 else "ember", rot=(30 * i, 20, 45), bev=0.001)


WEAPONS: dict = {
    # id: (fonksiyon, T, az, el, lens, roll, fill, shift, tohum, ink argümanları)
    "pistol": (parts_pistol, 2.0, -66, 18, 50, 0, 0.88, (0, 0), 11, {}),
    "shotgun": (parts_shotgun, 2.4, -75, 16, 46, 30, 0.9, (0, 0), 12, {}),
    "smg": (parts_smg, 2.0, -70, 16, 48, 10, 0.88, (0, 0), 13, {}),
    "plasma_rifle": (parts_plasma, 2.0, -68, 18, 48, 12, 0.9, (0, 0), 14, {}),
    "gravity_gun": (parts_gravity, 1.8, -50, 18, 46, 0, 0.88, (0, 0), 15, {}),
    "grenade_launcher": (parts_grenade, 1.8, -62, 18, 48, 6, 0.9, (0, 0), 16, {}),
    "knife": (parts_knife, 3.6, -55, 60, 56, 40, 0.9, (0, 0), 17, {}),
    "katana": (parts_katana, 2.6, -55, 62, 50, 38, 0.92, (0, 0), 18, {}),
    "lightsaber": (parts_lightsaber, 2.6, -72, 10, 52, 230, 0.88, (0, 0), 19, {"glow": 1.0, "rim": 0.1, "halo": 1.6, "soft_emit": True, "levels": (0.14, 0.40, 0.72, 1.0), "hatch": 0.6}),
    "flame_sword": (parts_flame, 3.2, -55, 62, 50, 38, 0.92, (0, 0), 20, {}),
}


def build(wid: str) -> str:
    global T, M
    fn, t, az, el, lens, roll, fill, shift, seed, extra = WEAPONS[wid]
    U.reset_scene()
    T = t
    M = mats()
    fn()
    objs = U.meshes()
    cam = U.fit_camera(objs, az=az, el=el, lens=lens, fill=fill, roll=roll, shift=shift)
    U.add_lights(cam)
    args = {"blood_spots": 2, "blood": 0.85}
    args.update(extra)
    return U.make("weapon_" + wid, seed=seed, **args)


def main() -> None:
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ids = args or list(WEAPONS)
    for wid in ids:
        print("EMBLEM", build(wid), flush=True)
    names = ["weapon_" + k for k in WEAPONS]
    U.contact_sheet(names, os.path.join(U.REPO, "build", "shots", "emblems_weapons.png"), cols=4, tile=256)


main()
