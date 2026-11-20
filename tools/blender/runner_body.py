"""Koşucu (Pençeli) gövdesi (V.5 v2): pozlar, iskelet noktaları, ayak parmakları, kas şekillendirme.

build_runner.py içe aktarır. Karakter -Y'ye bakar, Z yukarı, sol +X, metre. (konum, yarıçap).
"stalk" nötr duruştur ve oyun modelinin dinlenme pozudur: yürüyenden alçak, gövde öne eğik,
uzun kollar diz altına sarkar, dizler bükük. "crouch" imza anıdır (sprinter çıkışı: pençeler yerde,
baş öne uzanmış askere bakar, çene sonuna kadar açık).
Kaslar: skin gövdesi ekseninden, kas grubu başına açısal + boyuna Gauss tümsek (deltoid, biseps,
triseps, önkol, uyluk ön/iç, arka bacak, baldır); aralarında oluk ve eklemlerde incelme kalır.
"""
import math

from mathutils import Vector, geometry

POSES = {
    "stalk": {
        "torso": {"pelvis": ((0.0, 0.070, 0.780), 0.110), "belly": ((0.0, 0.010, 0.885), 0.090),
                  "spine": ((0.0, -0.075, 0.975), 0.100), "chest": ((0.0, -0.185, 1.050), 0.122),
                  "upchest": ((0.0, -0.285, 1.095), 0.102), "neck0": ((0.0, -0.360, 1.110), 0.050),
                  "neck1": ((0.0, -0.425, 1.125), 0.044)},
        "limbs": {
            "hip_R": ((-0.100, 0.070, 0.770), 0.078), "hip_L": ((0.100, 0.070, 0.770), 0.078),
            "knee_R": ((-0.150, -0.170, 0.455), 0.050), "knee_L": ((0.140, -0.090, 0.440), 0.050),
            "ankle_R": ((-0.145, 0.055, 0.105), 0.033), "ankle_L": ((0.140, 0.175, 0.125), 0.033),
            "heel_R": ((-0.145, 0.098, 0.050), 0.030), "heel_L": ((0.140, 0.222, 0.075), 0.030),
            "ball_R": ((-0.150, -0.060, 0.030), 0.032), "ball_L": ((0.145, 0.065, 0.030), 0.032),
            "shoulder_R": ((-0.165, -0.265, 1.080), 0.056), "shoulder_L": ((0.165, -0.265, 1.080), 0.056),
            "elbow_R": ((-0.250, -0.330, 0.745), 0.039), "elbow_L": ((0.255, -0.360, 0.755), 0.039),
            "wrist_R": ((-0.255, -0.430, 0.400), 0.027), "wrist_L": ((0.275, -0.480, 0.415), 0.027),
            "palm_R": ((-0.257, -0.452, 0.322), 0.034), "palm_L": ((0.279, -0.505, 0.338), 0.034)},
        "hands": {"R": {"fdir": None, "cup": (0.0, -1.0, 0.25), "fan": 8.0},
                  "L": {"fdir": None, "cup": (0.0, -1.0, 0.25), "fan": 9.0}},
        "head_off": (0.0, -0.030, 0.000), "head_rot": (-6.0, 4.0, 6.0), "jaw": 18.0,
    },
    "crouch": {
        "torso": {"pelvis": ((0.0, 0.150, 0.500), 0.110), "belly": ((0.0, 0.045, 0.570), 0.090),
                  "spine": ((0.0, -0.065, 0.640), 0.100), "chest": ((0.0, -0.185, 0.705), 0.122),
                  "upchest": ((0.0, -0.285, 0.745), 0.102), "neck0": ((0.0, -0.380, 0.760), 0.050),
                  "neck1": ((0.0, -0.465, 0.762), 0.044)},
        "limbs": {
            "hip_R": ((-0.105, 0.150, 0.500), 0.078), "hip_L": ((0.105, 0.150, 0.500), 0.078),
            "knee_R": ((-0.235, -0.215, 0.420), 0.050), "knee_L": ((0.215, -0.135, 0.270), 0.050),
            "ankle_R": ((-0.200, 0.100, 0.120), 0.033), "ankle_L": ((0.200, 0.250, 0.105), 0.033),
            "heel_R": ((-0.200, 0.150, 0.090), 0.030), "heel_L": ((0.200, 0.300, 0.090), 0.030),
            "ball_R": ((-0.205, -0.010, 0.030), 0.032), "ball_L": ((0.205, 0.140, 0.030), 0.032),
            "shoulder_R": ((-0.170, -0.265, 0.735), 0.056), "shoulder_L": ((0.170, -0.265, 0.735), 0.056),
            "elbow_R": ((-0.320, -0.380, 0.470), 0.039), "elbow_L": ((0.325, -0.350, 0.480), 0.039),
            "wrist_R": ((-0.320, -0.600, 0.175), 0.027), "wrist_L": ((0.350, -0.540, 0.180), 0.027),
            "palm_R": ((-0.325, -0.645, 0.100), 0.033), "palm_L": ((0.365, -0.585, 0.100), 0.033)},
        "hands": {"R": {"fdir": (-0.20, -0.80, -0.55), "cup": (0.0, 0.35, -1.0), "fan": 14.0, "curl": 0.7},
                  "L": {"fdir": (0.25, -0.80, -0.55), "cup": (0.0, 0.35, -1.0), "fan": 14.0, "curl": 0.7}},
        "head_off": (0.0, -0.040, 0.000), "head_rot": (8.0, 0.0, -4.0), "jaw": 40.0,
    },
}
TORSO_EDGES = [("pelvis", "belly"), ("belly", "spine"), ("spine", "chest"), ("chest", "upchest"),
               ("upchest", "neck0"), ("neck0", "neck1")]
LIMB_CHAIN = [("hip", "knee"), ("knee", "ankle"), ("ankle", "heel"), ("ankle", "ball"),
              ("shoulder", "elbow"), ("elbow", "wrist"), ("wrist", "palm")]
PART_CLASS = {
    "pelvis-belly": "hips", "belly-spine": "torso_lo", "spine-chest": "torso_mid",
    "chest-upchest": "torso_hi", "upchest-neck0": "neck", "neck0-neck1": "neck",
    "pelvis-hip": "pelvis", "upchest-shoulder": "clav", "hip-knee": "thigh", "knee-ankle": "shin",
    "ankle-heel": "foot", "ankle-ball": "foot", "ball-toe": "foot", "shoulder-elbow": "uparm",
    "elbow-wrist": "forearm", "wrist-palm": "hand",
}
# Ayak parmakları: (iç..dış yanal kayma m, ileri boy m, kök yarıçapı). Başparmak ayrı, diğerleri grup.
TOES = ((0.016, 0.050, 0.0115), (-0.006, 0.044, 0.0095), (-0.024, 0.034, 0.0085))
# Kas: sınıf -> [(t merkez, t genişlik, açı (0 ön, 90 dış, 180 arka, -90 iç), açısal genişlik, genlik m)]
MUSCLES = {
    "uparm": [(0.12, 0.13, 90.0, 80.0, 0.0105), (0.10, 0.10, 0.0, 60.0, 0.006),    # deltoid
              (0.50, 0.17, 0.0, 45.0, 0.0085), (0.52, 0.19, 180.0, 55.0, 0.0075),   # biseps, triseps
              (0.97, 0.06, 0.0, 180.0, -0.0040)],                                   # dirsek incelmesi
    "forearm": [(0.20, 0.14, 40.0, 60.0, 0.0080), (0.24, 0.14, -60.0, 50.0, 0.0055),
                (0.95, 0.08, 0.0, 180.0, -0.0030)],
    "thigh": [(0.48, 0.22, 10.0, 55.0, 0.0110), (0.30, 0.18, -80.0, 45.0, 0.0075),  # ön uyluk, iç
              (0.52, 0.22, 180.0, 55.0, 0.0065), (0.95, 0.05, 0.0, 180.0, -0.0040)],
    "shin": [(0.28, 0.14, 180.0, 50.0, 0.0125), (0.30, 0.12, 150.0, 40.0, 0.0050),  # baldır
             (0.05, 0.05, 0.0, 180.0, -0.0030), (0.92, 0.08, 0.0, 180.0, -0.0035)],
    "clav": [(0.85, 0.20, 0.0, 70.0, 0.0050)],
}
LIMB_BASE = -0.0020      # uzuv kabuğu biraz içe: kas grupları ayrışsın


def body_points(pose, body):
    w, h, t = body["w"], body["h"], body["t"]
    pts = {}
    for n, ((x, y, z), r) in POSES[pose]["torso"].items():
        pts[n] = (Vector((x * w, y, z * h)), r * w)
    for n, ((x, y, z), r) in POSES[pose]["limbs"].items():
        pts[n] = (Vector((x * w, y, z * h)), r * t)
    for s in ("L", "R"):     # parmak eklemi yere değsin (boy ölçeği ayağı havaya kaldırmasın)
        p, r = pts[f"ball_{s}"]
        pts[f"ball_{s}"] = (Vector((p.x, p.y, POSES[pose]["limbs"][f"ball_{s}"][0][2])), r)
    return pts


def toes(pts, side, t):
    """Ayak parmağı düğümleri (topuk ve parmak ekleminin önünde üç ayrı parmak grubu)."""
    ankle, ball = pts[f"ankle_{side}"][0], pts[f"ball_{side}"][0]
    fwd = Vector((ball.x - ankle.x, ball.y - ankle.y, 0.0)).normalized()
    inward = Vector((-1.0 if ball.x > 0 else 1.0, 0.0, 0.0))
    extra, edges = {}, []
    for i, (lat, length, rad) in enumerate(TOES):
        base = ball + inward * lat + fwd * 0.004
        mid = base + fwd * length * 0.55 + Vector((0.0, 0.0, -0.004))
        tip = base + fwd * length + Vector((0.0, 0.0, -0.010))
        for k, (p, r) in enumerate(((mid, rad * t), (tip, rad * 0.8 * t))):
            extra[f"toe{i}{k}_{side}"] = (Vector((p.x, p.y, max(p.z, r * 0.9))), r)
        edges += [(f"ball_{side}", f"toe{i}0_{side}"), (f"toe{i}0_{side}", f"toe{i}1_{side}")]
    return extra, edges


def segment_class(a, b):
    key = f"{a.split('_')[0]}-{b.split('_')[0]}"
    if key in PART_CLASS:
        return PART_CLASS[key]
    if a.startswith("ball") or a.startswith("toe"):
        return "foot"
    return "hand" if a[0] in "fpt" and b[0] in "ft" else None


def classify(co, segments):
    """Noktanın en yakın iskelet parçası: (sınıf, parça boyunca 0..1, eksenden dışa birim yön)."""
    best, best_d = None, 1e9
    for cls, a, b in segments:
        _c, t = geometry.intersect_point_line(co, a, b)
        t = min(max(t, 0.0), 1.0)
        d = co - a.lerp(b, t)
        if d.length < best_d:
            best, best_d = (cls, t, d, a, b), d.length
    cls, t, d, a, b = best
    return cls, t, (d.normalized() if d.length > 1e-6 else Vector((0.0, 0.0, 1.0))), a, b


def _angle(radial, a, b):
    """Radyal yönün ön (-Y) ve dış (+|x|) yöne göre açısı (derece)."""
    axis = (b - a).normalized()
    front = Vector((0.0, -1.0, 0.0))
    front = front - axis * front.dot(axis)
    if front.length < 0.2:
        front = Vector((0.0, 0.0, 1.0)) - axis * axis.z
    front.normalize()
    out = Vector((1.0 if (a.x + b.x) > 0 else -1.0, 0.0, 0.0))
    out = out - axis * out.dot(axis) - front * out.dot(front)
    if out.length < 1e-4:
        out = axis.cross(front)
    out.normalize()
    return math.degrees(math.atan2(radial.dot(out), radial.dot(front)))


def shape_body(obj, segments, v):
    """Kas grupları + eklem incelmesi + (çıplak gövdede) kaburga dalgası; köşeleri eksenden iter."""
    for vert in obj.data.vertices:
        cls, t, radial, a, b = classify(vert.co, segments)
        push = 0.0
        if cls in MUSCLES:
            ang = _angle(radial, a, b)
            push = LIMB_BASE if cls != "clav" else 0.0
            for tc, tw, ac, aw, amp in MUSCLES[cls]:
                da = (ang - ac + 180.0) % 360.0 - 180.0
                push += amp * math.exp(-((t - tc) / tw) ** 2) * math.exp(-(da / aw) ** 2)
        elif v.get("ribs") and cls in ("torso_mid", "torso_lo") and radial.y < 0.3:
            phase = t + 0.25 * max(0.0, -radial.y) + (0.0 if cls == "torso_mid" else -1.0)
            fade = min(1.0, abs(radial.x) * 2.2 + 0.1)
            push = fade * (0.0034 * math.sin(phase * math.pi * 3.0) ** 2 - 0.0017)
        if push:
            vert.co = vert.co + radial * push
