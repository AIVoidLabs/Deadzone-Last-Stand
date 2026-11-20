"""Zıplayan v2 kas kütleleri: her kas, iskelet parçasına yönlendirilmiş ayrı bir elipsoit.

build_jumper.py içe aktarır. Kaslar ayrı metaball nesneleri olarak kurulur; gövdeyle birleşip voxel
remesh'ten geçince kesiştikleri yerde oluk kalır (kas grupları arasında ayrım; tek balon değil).
Parça çerçevesi: d = a→b, front = (0,-1,0)'ın d'ye dik bileşeni (karakterin önü), out = yana (sol +X).
Satır: (ad, a, b, t, (önden, dışa) ofset m, (boyuna, ön, yan) yarıçap m). a/b'de "*" taraf ekidir.
"""
from mathutils import Matrix, Vector

import zombie_kit as kit

FRONT_REF = Vector((0.0, -1.0, 0.0))

# Bacak: ön uyluk (quadriceps) üç kütle + iç uyluk (adduktor) + arka (hamstring) + kalça; diz kapağı;
# baldırda iki gastroknemius başı (yukarıda, kısa) + kaval önü; aşil kirişi kas değil, ince bilek.
LEG = [
    ("glute", "pelvis", "hip_*", 0.60, (-0.055, 0.010), (0.060, 0.045, 0.070)),
    ("rectus", "hip_*", "knee_*", 0.44, (0.068, 0.006), (0.175, 0.068, 0.062)),
    ("vlat", "hip_*", "knee_*", 0.50, (0.028, 0.070), (0.185, 0.070, 0.072)),
    ("vmed", "hip_*", "knee_*", 0.72, (0.040, -0.038), (0.095, 0.054, 0.052)),
    ("adduct", "hip_*", "knee_*", 0.30, (-0.004, -0.064), (0.160, 0.064, 0.060)),
    ("hams", "hip_*", "knee_*", 0.52, (-0.052, 0.012), (0.165, 0.054, 0.060)),
    ("gast_l", "knee_*", "ankle_*", 0.24, (-0.054, 0.026), (0.120, 0.058, 0.046)),
    ("gast_m", "knee_*", "ankle_*", 0.21, (-0.054, -0.026), (0.125, 0.060, 0.048)),
    ("tibant", "knee_*", "ankle_*", 0.36, (0.026, 0.022), (0.140, 0.024, 0.026)),
]
# Kol: deltoid, biseps, triseps, önkol (brakioradialis + fleksör) — dirsekte incelir.
ARM = [
    ("delt", "shoulder_*", "elbow_*", 0.10, (0.000, 0.022), (0.080, 0.056, 0.050)),
    ("bicep", "shoulder_*", "elbow_*", 0.52, (0.030, 0.002), (0.095, 0.033, 0.033)),
    ("tricep", "shoulder_*", "elbow_*", 0.42, (-0.030, 0.004), (0.110, 0.037, 0.037)),
    ("brach", "elbow_*", "wrist_*", 0.24, (0.012, 0.018), (0.090, 0.038, 0.040)),
    ("flexor", "elbow_*", "wrist_*", 0.30, (-0.012, -0.010), (0.095, 0.034, 0.036)),
]
# Gövde (taraf başına aynalı): göğüs, trapez (kambur sırtın tepesi), sırt (lat), kürek, karın yanı.
TORSO = [
    ("pec", "spine", "upchest", 0.72, (0.070, 0.065), (0.060, 0.034, 0.062)),
    ("trap", "upchest", "neck1", 0.15, (-0.045, 0.060), (0.070, 0.040, 0.060)),
    ("lat", "belly", "upchest", 0.55, (-0.035, 0.095), (0.120, 0.045, 0.040)),
    ("scap", "spine", "upchest", 0.80, (-0.075, 0.070), (0.065, 0.025, 0.050)),
    ("oblique", "pelvis", "spine", 0.55, (0.010, 0.090), (0.075, 0.040, 0.035)),
    ("abs", "pelvis", "spine", 0.70, (0.075, 0.032), (0.075, 0.028, 0.032)),
]


def _frame(a: Vector, b: Vector, sx: float):
    d = (b - a).normalized()
    front = FRONT_REF - d * FRONT_REF.dot(d)
    if front.length < 1e-4:
        front = Vector((0.0, 0.0, 1.0)) - d * d.z
    front.normalize()
    out = d.cross(front)
    rot = Matrix((d, front, out)).transposed().to_quaternion()   # yerel x=boy, y=ön, z=yan
    side_out = out if out.x * sx >= 0.0 else -out
    return d, front, side_out, rot


def _rows(pts, rows, sx, side, k_len, k_rad):
    blobs = []
    for _name, a, b, t, (f_off, o_off), radii in rows:
        pa, pb = pts[a.replace("*", side)][0], pts[b.replace("*", side)][0]
        if "*" not in a:      # gövde parçası: eksen ortada, yan ofset tarafa
            pa, pb = pa.copy(), pb.copy()
        d, front, out, rot = _frame(pa, pb, sx)
        c = pa.lerp(pb, t) + front * f_off * k_rad + out * o_off * k_rad
        r = (radii[0] * k_len, radii[1] * k_rad, radii[2] * k_rad)
        blobs.append((c, r, rot))
    return blobs


def build(pts, body, mat, merged=False):
    """Kas nesneleri (birleştirilip remesh edilecek). body: leg/arm/t/w çarpanları.
    merged=True: hepsi TEK metaball — alanlar kaynaşır, oluk kalmaz, yüzey biraz şişer. Kumaşın
    kesileceği örtü gövdesi için (kas tepelerini örter, olukları köprüler)."""
    blobs = []
    for side, sx in (("L", 1.0), ("R", -1.0)):
        groups = [(LEG, body["t"] * body["leg"]), (ARM, body["t"] * body["arm"]), (TORSO, body["w"])]
        for rows, k in groups:
            blobs += [(tuple(c), r, rot, False) for c, r, rot in _rows(pts, rows, sx, side, 1.0, k)]
    if merged:
        return [kit.metaball_oriented("Jumper_Drape", blobs, mat, resolution=0.008, smooth=0)]
    return [kit.metaball_oriented("Jumper_Muscle", [b], mat, resolution=0.006, smooth=0) for b in blobs]
