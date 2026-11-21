"""Boss "Yığın" (boss_heap) parçaları (7.4): gövde kütleleri, gömülü yüz/kol kabartmaları, kemik topuz,
üç parmaklı pençe, fil ayağı parmakları, göğüs yarığı ve parlayan kalp.

build_boss.py içe aktarır. Birimler "yapı birimi": model insan ölçüsünde kurulur, kök BUILD_SCALE (2.0)
ile büyütülür (3.6 m). Kas yöntemi tank_parts ile aynı (LIMB_MUSCLES uzuv çerçevesinde, yana göre ölçek);
gövde kütleleri ve kambur burada. Kabartmalar (ölü bedenlerin yüzleri ve kolları) gövde yüzeyine ışın
atılarak konur, yarı gömülür ve voxel remesh ile gövdeye kaynar (Brotato tarzı okunur kütle, ince detay
değil). Topuz ve pençe ayrı ağdır (oyun modelinde hand_l / hand_r + claw_r kemiğine bağlanır).
"""
import math
import random

from mathutils import Matrix, Quaternion, Vector

import bloater_parts as bp
import tank_parts as tp
import zombie_kit as kit

FRONT = Vector((0.0, -1.0, 0.0))
UP = Vector((0.0, 0.0, 1.0))
IDENT = Matrix.Identity(3).to_quaternion()
TORSO_C = Vector((0.0, 0.06, 1.12))          # kabartma ışınlarının merkezi
# Kol kası ölçeği yana göre (sağ pençe kolu daha iri: üstten asimetrik)
ARM_K = {"L": 1.50, "R": 1.68}
LEG_K = 1.55
SKIP = {"glute", "sole"}

# Gövde kütleleri: (merkez, yarıçap (x, y, z)). Kambur sağa yığılı ve sırtta (asimetrik siluet).
BODY_MASSES = [
    ((0.0, 0.03, 1.14), (0.44, 0.34, 0.32)),      # göğüs kafesi
    ((0.0, -0.05, 0.82), (0.37, 0.31, 0.30)),     # karın
    ((0.0, 0.04, 0.62), (0.31, 0.25, 0.19)),      # leğen
    ((0.06, 0.26, 1.48), (0.44, 0.36, 0.32)),     # kambur ana kütle
    ((-0.24, 0.20, 1.56), (0.30, 0.28, 0.26)),    # kambur sağ tepe (en yüksek nokta)
    ((0.24, 0.34, 1.54), (0.22, 0.22, 0.19)),     # kambur sol tepe
    ((0.02, 0.40, 1.18), (0.30, 0.20, 0.26)),     # sırt yığını
    ((0.34, 0.08, 1.40), (0.24, 0.24, 0.18)),     # sol trapez
    ((-0.36, 0.06, 1.44), (0.27, 0.26, 0.21)),    # sağ trapez (iri)
    ((0.22, -0.24, 1.16), (0.22, 0.12, 0.17)),    # sol göğüs
    ((-0.22, -0.24, 1.18), (0.23, 0.13, 0.18)),   # sağ göğüs
    ((0.33, 0.02, 0.92), (0.16, 0.22, 0.24)),     # sol böğür
    ((-0.33, 0.02, 0.94), (0.17, 0.22, 0.25)),    # sağ böğür
]

# Kabartmalar: (ad, yön (TORSO_C'den), tür, ölçek, teğet (kol yönü / yüz üstü), dışarı çıkma 0..1)
RELIEFS = [
    ("face_hump", (0.30, 0.45, 0.85), "face", 1.55, (0.0, -0.3, 1.0), 0.0),
    ("face_hump_r", (-0.65, 0.30, 0.75), "face", 1.35, (-0.3, 0.0, 1.0), 0.0),
    ("face_belly", (-0.42, -0.88, -0.40), "face", 1.45, (0.0, 0.0, 1.0), 0.0),
    ("face_back", (0.25, 0.95, -0.05), "face", 1.45, (0.0, 0.0, 1.0), 0.0),
    ("face_flank", (0.92, -0.25, -0.30), "face", 1.25, (0.0, 0.0, 1.0), 0.0),
    ("face_shoulder", (-0.55, -0.45, 0.70), "face", 1.10, (0.0, 0.0, 1.0), 0.0),
    ("arm_reach", (0.10, 0.60, 0.80), "arm", 1.6, (0.9, 0.5, -0.3), 0.20),
    ("arm_reach_r", (-0.50, 0.70, 0.55), "arm", 1.45, (-0.6, 0.7, -0.2), 0.25),
    ("arm_flank", (0.85, 0.40, 0.15), "arm", 1.25, (0.10, -0.35, -1.0), 0.10),
    ("arm_belly", (0.80, -0.45, -0.65), "arm", 1.15, (0.2, -0.3, -1.0), 0.10),
    ("face_hump_back", (-0.20, 0.80, 0.60), "face", 1.40, (0.0, 0.4, 1.0), 0.0),
    ("face_back_l", (0.65, 0.65, 0.35), "face", 1.30, (0.0, 0.0, 1.0), 0.0),
    ("face_back_r", (-0.75, 0.50, 0.15), "face", 1.30, (0.0, 0.0, 1.0), 0.0),
    ("arm_back", (-0.35, 0.92, 0.05), "arm", 1.20, (-0.2, 0.2, -1.0), 0.15),
]

# Göğüs yarığı (kalp): üst ve alt uç (yapı birimi, ön yüzeyde x-z), en geniş yarım genişlik, derinlik
SLIT_TOP = Vector((0.08, 0.0, 1.10))       # kafanın altından başlar: üstten kameradan görünsün
SLIT_BOT = Vector((-0.06, 0.0, 0.60))
SLIT_W = 0.080
SLIT_DEPTH = 0.075
SLIT_LIP = 0.020


def _q(out, front, d):
    return Matrix((out, front, d)).transposed().to_quaternion()


def masses(pts, rest_pts=None):
    """Uzuv kasları (tank_parts listesi, yana göre ölçek) + gövde kütleleri: metaball girdileri."""
    blobs = []
    rest_pts = rest_pts or pts
    for name, a, b, f, off, radii in tp.LIMB_MUSCLES:
        if name in SKIP:
            continue
        for side, sx in (("L", 1.0), ("R", -1.0)):
            k = LEG_K if name in tp.LEG_NAMES else ARM_K[side]
            pa, pb = pts[f"{a}_{side}"][0], pts[f"{b}_{side}"][0]
            rest = rest_pts[f"{b}_{side}"][0] - rest_pts[f"{a}_{side}"][0]
            out, front, d = tp.limb_frame(pa, pb, sx, rest)
            c = pa.lerp(pb, f) + out * off[0] * k + front * off[1] * k
            blobs.append((tuple(c), tuple(r * k for r in radii), tp._frame_quat(out, front, d), False))
    for c, r in BODY_MASSES:
        blobs.append((c, r, IDENT, False))
    return blobs


# ---------------------------------------------------------------- kabartmalar

def surface_hit(body, direction):
    """Gövdenin dışından merkeze ışın: (nokta, normal) dünya uzayında."""
    d = Vector(direction).normalized()
    inv = body.matrix_world.inverted()
    origin = inv @ (TORSO_C + d * 3.0)
    hit, loc, nrm, _i = body.ray_cast(origin, inv.to_3x3() @ -d)
    if not hit:
        return None, None
    return body.matrix_world @ loc, (body.matrix_world.to_3x3() @ nrm).normalized()


def _face_frame(n, up_hint):
    up = Vector(up_hint)
    up = (up - n * up.dot(n))
    if up.length < 1e-3:
        up = FRONT - n * FRONT.dot(n)
    up.normalize()
    across = up.cross(n).normalized()
    return across, n, up          # (x yana, y yüzün baktığı yön, z yukarı)


FACE_BLOBS = [   # (yerel merkez, yarıçap, negatif) — yüz ileri +y, birim insan yüzü
    ((0.0, -0.02, 0.0), (0.075, 0.070, 0.088), False),     # kafatası
    ((0.0, 0.050, 0.030), (0.066, 0.022, 0.020), False),   # kaş kemeri
    ((0.040, 0.045, -0.012), (0.026, 0.026, 0.024), False),
    ((-0.040, 0.045, -0.012), (0.026, 0.026, 0.024), False),   # elmacıklar
    ((0.0, 0.068, 0.004), (0.013, 0.018, 0.022), False),   # burun
    ((0.0, 0.035, -0.062), (0.052, 0.036, 0.030), False),  # çene
    ((0.028, 0.068, 0.014), (0.019, 0.022, 0.016), True),
    ((-0.028, 0.068, 0.014), (0.019, 0.022, 0.016), True),  # göz çukurları
    ((0.0, 0.074, -0.040), (0.030, 0.030, 0.024), True),   # çığlık atan ağız
]


def face_relief(p, n, scale, up_hint):
    across, fwd, up = _face_frame(n, up_hint)
    q = _q(across, fwd, up)
    base = p - n * 0.012 * scale
    out = []
    for c, r, neg in FACE_BLOBS:
        wc = base + (across * c[0] + fwd * c[1] + up * c[2]) * scale
        out.append((tuple(wc), tuple(x * scale for x in r), q, neg))
    return out


def arm_relief(p, n, scale, tangent, lift, sx=1.0):
    """Yarı gömülü kol: omuz gövdeye batık, dirsek ve el dışarı (lift) ya da yüzeye yatık."""
    t = Vector(tangent)
    t = (t - n * t.dot(n)).normalized()
    d = (t * (1.0 - lift) + n * lift).normalized()
    sh = p - n * 0.04 * scale
    el = sh + (d * 0.17 + n * 0.035) * scale
    wr = el + (d * 0.15 + n * (0.02 + 0.04 * lift)) * scale
    tip = wr + (d * 0.10 + n * 0.01) * scale
    out = []
    for a, b, r0, r1 in ((sh, el, 0.070, 0.058), (el, wr, 0.058, 0.046)):
        ax = (b - a).normalized()
        across = ax.cross(n).normalized() if abs(ax.dot(n)) < 0.95 else ax.cross(UP).normalized()
        q = _q(across, ax.cross(across).normalized(), ax)
        for i in range(4):
            f = i / 3.0
            r = (r0 + (r1 - r0) * f) * scale
            out.append((tuple(a.lerp(b, f)), (r, r * 0.92, r * 1.25), q, False))
    out.append((tuple(el), (0.055 * scale, 0.055 * scale, 0.055 * scale), IDENT, False))   # dirsek
    out += bp.hand_blobs(wr, tip, sx, scale * 1.7)
    return out


def relief_blobs(body):
    """Tüm kabartmalar: (blob listesi, [(ad, merkez, yarıçap, tür)]) — renk bölgeleri için merkezler."""
    blobs, info = [], []
    for name, direction, kind, scale, tangent, lift in RELIEFS:
        p, n = surface_hit(body, direction)
        if p is None:
            continue
        if kind == "face":
            blobs += face_relief(p, n, scale, tangent)
            info.append((name, p + n * 0.02 * scale, 0.11 * scale, kind))
        else:
            sx = 1.0 if direction[0] >= 0.0 else -1.0
            blobs += arm_relief(p, n, scale, tangent, lift, sx)
            info.append((name, p + n * 0.05, 0.30 * scale, kind))
    return blobs, info


# ---------------------------------------------------------------- göğüs yarığı

def slit_coords(co):
    """Ön yüzeyde yarık çizgisine göre (t 0..1 boyunca, d yana uzaklık, w o yerdeki yarım genişlik)."""
    a, b = SLIT_TOP, SLIT_BOT
    ab = Vector((b.x - a.x, 0.0, b.z - a.z))
    ap = Vector((co.x - a.x, 0.0, co.z - a.z))
    t = ap.dot(ab) / ab.length_squared
    tc = min(max(t, 0.0), 1.0)
    d = (ap - ab * tc).length
    w = SLIT_W * max(math.sin(math.pi * tc), 0.0) ** 0.7
    return t, d, w


def carve_slit(body):
    """Yarığı gövdeye oyar: içte çukur, kenarda kabarık dudak (köşe normali boyunca)."""
    mw = body.matrix_world
    inv3 = mw.to_3x3()
    for v in body.data.vertices:
        co = mw @ v.co
        n = (inv3 @ v.normal).normalized()
        if co.y > -0.10 or n.y > -0.35:
            continue
        t, d, w = slit_coords(co)
        if not (0.0 <= t <= 1.0) or w <= 0.004:
            continue
        if d < w:
            v.co -= v.normal * SLIT_DEPTH * (1.0 - (d / w) ** 2) * (0.6 + 0.4 * math.sin(math.pi * t))
        elif d < w * 1.9:
            v.co += v.normal * SLIT_LIP * math.sin(math.pi * (d - w) / (0.9 * w))


def front_point(body, x, z):
    inv = body.matrix_world.inverted()
    hit, loc, _n, _i = body.ray_cast(inv @ Vector((x, -2.0, z)), inv.to_3x3() @ Vector((0.0, 1.0, 0.0)))
    return body.matrix_world @ loc if hit else Vector((x, -0.35, z))


def build_core(body, mat):
    """Yarığın dibindeki parlayan kalp: yarık boyunca dizili şiş kütleler (köşe rengi alfası 0)."""
    blobs = []
    for i in range(7):
        f = i / 6.0
        a = SLIT_TOP.lerp(SLIT_BOT, 0.08 + 0.84 * f)
        p = front_point(body, a.x, a.z) + Vector((0.0, SLIT_DEPTH * 0.55, 0.0))
        r = SLIT_W * (0.55 + 0.35 * math.sin(math.pi * f))
        blobs.append((tuple(p), (r, r * 0.7, r * 1.3), IDENT, False))
    return kit.metaball_oriented("Boss_Core", blobs, mat, resolution=0.010, smooth=2)


# ---------------------------------------------------------------- topuz ve pençe

def _hand_frame(wrist, fist, sx):
    d = (fist - wrist).normalized()
    out = Vector((sx, 0.0, 0.0))
    out = (out - d * out.dot(d)).normalized()
    front = d.cross(out).normalized()
    if front.dot(FRONT) < 0.0:
        front = -front
    return d, out, front


def mace_blobs(wrist, fist, sx):
    """Kemik topuz: bileğe kaynamış kalın kemik sap + düğümlü baş (kemik yumrular, kaynamış kafatası)."""
    d, out, front = _hand_frame(wrist, fist, sx)
    q = _q(out, front, d)
    blobs = []
    for i in range(5):                       # sap: düğümlü uyluk kemiği
        f = i / 4.0
        r = 0.078 + 0.012 * math.sin(f * 7.0)
        blobs.append((tuple(wrist + d * (0.02 + 0.18 * f)), (r, r, 0.070), q, False))
    h = wrist + d * 0.28
    blobs.append((tuple(h), (0.16, 0.15, 0.17), q, False))
    rng = random.Random(7)
    for i in range(6):                       # baş yumruları
        ang = i * math.tau / 6 + 0.4
        o = (out * math.cos(ang) + front * math.sin(ang)) * 0.12 + d * rng.uniform(-0.05, 0.07)
        r = rng.uniform(0.075, 0.095)
        blobs.append((tuple(h + o), (r, r, r * 1.1), q, False))
    sk = h + front * 0.11 + d * 0.02          # kaynamış kafatası (öne bakar)
    blobs += [(tuple(sk), (0.060, 0.055, 0.065), q, False),
              (tuple(sk + front * 0.045 + out * 0.022 - d * 0.012), (0.016, 0.016, 0.014), q, True),
              (tuple(sk + front * 0.045 - out * 0.022 - d * 0.012), (0.016, 0.016, 0.014), q, True)]
    return blobs, h, d, out, front


def build_mace(name, wrist, fist, sx, mat, spike_mat):
    blobs, h, d, out, front = mace_blobs(wrist, fist, sx)
    obj = kit.metaball_oriented(name, blobs, mat, resolution=0.010, smooth=2)
    spikes = []
    for i, (ang, tilt, ln) in enumerate(((0.3, 0.45, 0.22), (1.3, 0.15, 0.20), (2.3, 0.55, 0.24), (3.3, 0.25, 0.19),
                                         (4.3, 0.5, 0.23), (5.3, 0.1, 0.20), (0.8, 0.75, 0.18), (3.9, 0.7, 0.18),
                                         (2.0, 0.85, 0.17))):
        dirv = (out * math.cos(ang) + front * math.sin(ang)) * (1.0 - tilt) + d * tilt
        dirv.normalize()
        cone = kit.primitive(f"Boss_Spike", "cone", h + dirv * (0.15 + ln * 0.42),
                             radius1=0.048, depth=ln, segments=6)
        cone.rotation_mode = "QUATERNION"
        cone.rotation_quaternion = UP.rotation_difference(dirv)
        cone.data.materials.append(spike_mat)
        spikes.append(cone)
    return obj, spikes


def claw_points(wrist, fist, sx):
    """Üç uzun parmak: (eklem noktaları listesi) — öne doğru kıvrık, yelpaze gibi açık."""
    d, out, front = _hand_frame(wrist, fist, sx)
    palm = wrist + d * 0.08
    fingers = []
    for i, spread in enumerate((-1.0, 0.0, 1.0)):
        sp = out * spread * 0.075
        fan = out * spread * 0.045
        k0 = palm + d * 0.08 + sp
        k1 = k0 + d * 0.15 + front * 0.025 + fan
        k2 = k1 + d * 0.13 + front * 0.06 + fan
        k3 = k2 + d * 0.06 + front * 0.09 + fan * 0.5
        fingers.append((k0, k1, k2, k3))
    return palm, fingers, d, out, front


def build_claw(name, wrist, fist, sx, mat, talon_mat):
    palm, fingers, d, out, front = claw_points(wrist, fist, sx)
    q = _q(out, front, d)
    blobs = [(tuple(palm), (0.10, 0.07, 0.10), q, False),
             (tuple(palm + d * 0.06), (0.11, 0.065, 0.06), q, False)]
    for chain in fingers:
        for (a, b), r in zip(zip(chain[:-1], chain[1:]), (0.050, 0.042, 0.034)):
            for f in (0.0, 0.5, 1.0):
                blobs.append((tuple(a.lerp(b, f)), (r, r, r * 1.2), q, False))
    obj = kit.metaball_oriented(name, blobs, mat, resolution=0.008, smooth=2)
    talons = []
    for chain in fingers:
        dirv = (chain[3] - chain[2]).normalized()
        cone = kit.primitive("Boss_Talon", "cone", chain[3] + dirv * 0.06, radius1=0.034, depth=0.15, segments=6)
        cone.rotation_mode = "QUATERNION"
        cone.rotation_quaternion = UP.rotation_difference(dirv)
        cone.data.materials.append(talon_mat)
        talons.append(cone)
    return obj, talons


def build_toes(name, ball, toe, sx, mat, seed):
    rng = random.Random(int(seed * 100) + (1 if sx > 0 else 2))
    blobs = tp.toe_blobs(ball, toe, sx, 1.75, rng)
    return kit.metaball_oriented(name, blobs, mat, resolution=0.006, smooth=2)
