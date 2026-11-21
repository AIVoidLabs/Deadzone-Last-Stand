"""Çığlıkçının parçaları (7.3): sıska kas grupları, göğüs kafesi, boyun kirişleri, uzun ince el.

build_screamer.py içe aktarır. Kas yöntemi tank_parts ile aynı (kas grupları ayrı elipsoid, aralarında
voxel remesh sonrası oluk, eklemlerde incelme); fark: kaslar ince ve kuru (kollar ×ARM_K, bacaklar ×LEG_K),
köprücük kemiği ve boyun kirişleri (sternokleidomastoid) ayrı kütle. Göğüs kafesi gövdeye remesh'ten
SONRA kabartma olarak işlenir (rib_relief): kaburgalar arkadan öne aşağı iner, aralar ve göğüs
kemiği oluk; kaburga kemerinin altında karın çöker. Böylece incelme (decimate) sonrası da okunur.
El: uzun parmaklı, yarı açık pençe (thrower_parts.hand_blobs'tan kopya, parmak boyu ayrı çarpan).
tank_parts'tan yalnız salt veri/yardımcı içe aktarılır (dosyası düzenlenmez).
"""
import math

from mathutils import Matrix, Quaternion, Vector

import zombie_kit as kit
import tank_parts as tp

FRONT = Vector((0.0, -1.0, 0.0))
ARM_MUSCLES = {"delt_f", "delt_s", "delt_r", "bicep", "tricep", "brachio", "flexor", "extensor"}
ARM_K = 0.40              # kol kası ölçeği (tank 1.0): sıska, kemik üstünde ip gibi
LEG_K = 0.50              # bacak kası ölçeği
# kas başına ek çarpan: dirsek/diz çevresindeki kütleler balon gibi şişmesin, eklem kemikli okunsun
MUSCLE_TRIM = {"brachio": 0.70, "flexor": 0.85, "extensor": 0.85, "delt_s": 0.80, "delt_f": 0.80,
               "delt_r": 0.80, "vast_med": 0.55, "gastro_l": 0.80, "gastro_m": 0.80, "glute": 0.85}
TORSO_MUSCLES = [         # (ad, A, B, oran, ofset (x dışa, y, z), yarıçap) — sol taraf
    ("trap", "upchest", "shoulder", 0.50, (0.0, 0.030, 0.012), (0.050, 0.036, 0.024)),
    ("pec", "chest", "shoulder", 0.40, (0.0, -0.070, 0.010), (0.060, 0.020, 0.045)),
    ("lat", "spine", "shoulder", 0.45, (0.0, 0.050, -0.040), (0.055, 0.060, 0.120)),
    ("scap", "upchest", "shoulder", 0.55, (0.0, 0.075, -0.040), (0.060, 0.022, 0.065)),
]
NECK_CORDS = 0.013        # boyun kirişi yarıçapı (m)
CLAV_R = 0.014            # köprücük kemiği yarıçapı

# Göğüs kafesi kabartması (dünya, ölçek öncesi): kaburga aralığı, genlik, kemer
RIB_COUNT = 7
RIB_STEP = 0.034          # kaburgalar arası (m, dikey)
RIB_AMP = 0.0085          # kaburga sırtı kabartması (m)
RIB_GROOVE = 0.0050       # kaburga arası çukur (m)
RIB_SLOPE = 0.075         # kaburga yanda göğüs kemiğine göre bu kadar alçak (m)
STERNUM_HALF = 0.020      # göğüs kemiği oluğu yarı genişliği (m)
BELLY_SINK = 0.012        # kaburga kemerinin altında karın çöküşü (m)


def _q(out, front, d):
    return Matrix((out, front, d)).transposed().to_quaternion()


def masses(pts, body, rest_pts=None):
    """Kas kütleleri: [(merkez, yarıçaplar, dönüş, negatif)]."""
    blobs = []
    rest_pts = rest_pts or pts
    arm_k, leg_k = ARM_K * body.get("arm", 1.0), LEG_K * body.get("legs", 1.0)
    for name, a, b, f, off, radii in tp.LIMB_MUSCLES:
        k = (arm_k if name in ARM_MUSCLES else leg_k) * MUSCLE_TRIM.get(name, 1.0)
        for side, sx in (("L", 1.0), ("R", -1.0)):
            pa, pb = pts[f"{a}_{side}"][0], pts[f"{b}_{side}"][0]
            rest = rest_pts[f"{b}_{side}"][0] - rest_pts[f"{a}_{side}"][0]
            out, front, d = tp.limb_frame(pa, pb, sx, rest)
            c = pa.lerp(pb, f) + out * off[0] * k + front * off[1] * k
            # uzun kemikte kas boyu kısalmasın: boyuna yarıçap uzuv boyuyla orantılı
            seg = (pb - pa).length
            radii_k = (radii[0] * k, radii[1] * k, radii[2] * max(k, 0.55) * seg / 0.44)
            blobs.append((tuple(c), radii_k, _q(out, front, d), False))
    w = body["w"]
    for name, a, b, f, off, radii in TORSO_MUSCLES:
        for side, sx in (("L", 1.0), ("R", -1.0)):
            pa = pts[a if a in pts else f"{a}_{side}"][0]
            pb = pts[b if b in pts else f"{b}_{side}"][0]
            c = pa.lerp(pb, f) + Vector((off[0] * sx, off[1], off[2]))
            blobs.append((tuple(c), tuple(r * w for r in radii), Quaternion(), False))
    blobs += neck_cords(pts)
    blobs += clavicles(pts)
    return blobs


def _bar(a, b, r, steps=5):
    """İki nokta arasında ince çubuk (köprücük, kiriş): sıralı elipsoidler."""
    d = (b - a)
    q = d.to_track_quat("Z", "Y")
    ln = d.length / steps
    return [(tuple(a.lerp(b, (i + 0.5) / steps)), (r, r, ln * 0.75), q, False) for i in range(steps)]


def neck_cords(pts):
    """Sternokleidomastoid: kulak arkasından göğüs kemiği başına iki kiriş (uzun boyunu çizgiyle okutur)."""
    top, base = pts["neck1"][0], pts["upchest"][0]
    out = []
    for sx in (1.0, -1.0):
        a = top + Vector((0.040 * sx, 0.010, 0.010))
        b = base + Vector((0.016 * sx, -0.085, 0.010))
        out += _bar(a, b, NECK_CORDS, 6)
    return out


def clavicles(pts):
    base = pts["upchest"][0]
    out = []
    for side, sx in (("L", 1.0), ("R", -1.0)):
        sh = pts["shoulder_" + side][0]
        a = base + Vector((0.020 * sx, -0.090, 0.010))
        b = sh + Vector((-0.010 * sx, -0.030, 0.030))
        out += _bar(a, b, CLAV_R, 5)
    return out


def rib_field(co, pts):
    """Göğüs kafesi alanı (ölçek öncesi dünya noktası): normal boyunca kabartma (m; + sırt, - oluk).
    Kaburga göğüs kemiğinde yüksek, yanda en alçak, arkaya doğru yeniden yükselir (ters V);
    alttakiler önde kısalır (kaburga kemeri); kemerin altında karın çöker. Arka 115° dışarıda."""
    chest, belly = pts["chest"][0], pts["belly"][0]
    top = chest.z + 0.070
    rel = co - Vector((0.0, chest.y, 0.0))
    ang = abs(math.atan2(rel.x, -rel.y))        # 0 = tam ön, pi = arka
    if ang > 2.0:
        return 0.0
    drop = RIB_SLOPE * math.sin(min(ang, math.pi * 0.5)) ** 1.2
    u = (top - drop - co.z) / RIB_STEP
    reach = RIB_COUNT - 0.5 - 3.2 * max(0.0, math.cos(ang)) ** 2
    if -0.3 < u < reach:
        ridge = 0.5 + 0.5 * math.cos(u * math.tau)
        fade = min(1.0, (u + 0.3) / 0.5) * min(1.0, (reach - u) / 0.6) * min(1.0, (2.0 - ang) / 0.5)
        amp = RIB_AMP * (0.75 + 0.25 * math.sin(ang * 1.7))
        disp = (amp * ridge ** 3 - RIB_GROOVE * (1.0 - ridge) ** 2) * fade
        if abs(rel.x) < STERNUM_HALF and ang < 0.6:
            disp = disp * abs(rel.x) / STERNUM_HALF - 0.003 * (1.0 - abs(rel.x) / STERNUM_HALF)
        return disp
    if u >= reach and ang < 1.3 and co.z > belly.z - 0.08:
        k = min(1.0, (u - reach) / 0.8) * min(1.0, (co.z - belly.z + 0.08) / 0.06) * math.cos(ang)
        return -BELLY_SINK * k
    return 0.0


def rib_relief(obj, pts, part):
    """Gövde ağına (remesh sonrası) rib_field kabartması; yalnız gövde/kalça sınıfındaki köşeler."""
    mw = obj.matrix_world
    inv = mw.inverted()
    for v in obj.data.vertices:
        co = mw @ v.co
        if part(co)[0] not in ("torso", "hips"):
            continue
        disp = rib_field(co, pts)
        if disp:
            n = (mw.to_3x3() @ v.normal).normalized()
            v.co = inv @ (co + n * disp)


# ---------------------------------------------------------------- el (thrower_parts'tan kopya + uzun parmak)

FINGERS = ((1.00, 0.92), (1.08, 1.00), (1.02, 0.97), (0.86, 0.86))   # (uzunluk, kalınlık) işaret→serçe
PHALANX = (0.060, 0.042, 0.032)
CURL = (22.0, 34.0, 30.0)
FINGER_LEN = 1.35         # çığlıkçının parmakları uzun ve kemikli


def hand_frame(wrist, tip, sx):
    d = (tip - wrist).normalized()
    back = Vector((sx, 0.0, 0.0))
    back = (back - d * back.dot(d)).normalized()
    across = d.cross(back).normalized()
    return across, back, d


def hand_blobs(wrist, tip, sx, s, curl=0.6, flen=FINGER_LEN):
    across, back, d = hand_frame(wrist, tip, sx)
    q = _q(across, back, d)
    blobs = [(tuple(wrist + d * 0.080 * s), (0.064 * s, 0.030 * s, 0.066 * s), q, False),
             (tuple(wrist + d * 0.030 * s - back * 0.006 * s), (0.050 * s, 0.032 * s, 0.040 * s), q, False)]
    for i, (lf, tf) in enumerate(FINGERS):
        o = (i - 1.5) * 0.031 * s
        base = wrist + d * (0.140 - 0.012 * abs(i - 1.2)) * s + across * o
        blobs.append((tuple(base + back * 0.012 * s), (0.016 * s * tf, 0.016 * s * tf, 0.016 * s * tf), q, False))
        p, dirv, ang = base, d.copy(), 0.0
        for k, ln in enumerate(PHALANX):
            ang += math.radians(CURL[k] * curl)
            dirv = (d * math.cos(ang) - back * math.sin(ang)).normalized()
            ln *= s * lf * flen
            r = (0.0135, 0.0120, 0.0105)[k] * s * tf
            mid = p + dirv * ln * 0.5
            qq = _q(across, dirv.cross(across).normalized(), dirv)
            blobs.append((tuple(mid), (r, r * 0.92, ln * 0.60), qq, False))
            p = p + dirv * ln
            if k < 2:   # boğum (kemikli eklem)
                blobs.append((tuple(p), (r * 1.18, r * 1.12, r * 1.0), qq, False))
    thumb_side = across if across.dot(FRONT) > 0.0 else -across
    t0 = wrist + d * 0.050 * s + thumb_side * 0.046 * s - back * 0.016 * s
    tdir = (d * 0.75 + thumb_side * 0.25 - back * 0.55 * curl).normalized()
    qt = _q(thumb_side, tdir.cross(thumb_side).normalized(), tdir)
    blobs.append((tuple(t0), (0.020 * s, 0.019 * s, 0.032 * s), qt, False))
    blobs.append((tuple(t0 + tdir * 0.050 * s), (0.014 * s, 0.013 * s, 0.026 * s), qt, False))
    blobs.append((tuple(t0 + tdir * 0.092 * s), (0.012 * s, 0.011 * s, 0.020 * s), qt, False))
    return blobs


def build_hand(name, wrist, tip, sx, s, mat, curl=0.6):
    return kit.metaball_oriented(name, hand_blobs(wrist, tip, sx, s, curl), mat, resolution=0.0040, smooth=2)
