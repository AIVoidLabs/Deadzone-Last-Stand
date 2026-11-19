"""Yürüyen (sürü) zombi konsepti — Aşama V.5, tamamen Blender (Taha 2026-11-19).

Sıradan bir insanın bozulmuş hali: sivil, işçi, büro çalışanı. İmza duruş: ağırlık sağ bacakta,
sol omuz düşük, kollar yarı kalkık ve öne uzanmaya hazır (kucaklar gibi saldırı), çene sarkık,
kafa düşük omuza yatık. Dilciden farkı: dik gövde (kambur değil), insan kafası, tek parça sarkık çene.

Gövde: iskelet noktaları + skin modifier + voxel remesh (kit). Gövde çeşitleri parametreyle
(boy, genişlik, uzuv kalınlığı, göbek). Kıyafetler gövde yüzeyinden; hangi yüzün hangi uzva ait
olduğu en yakın iskelet parçasından bulunur (kol uzanık pozda z/x eşiği yetmiyor).

Çalıştırma (Blender MCP içinden):
    exec(open(r"<repo>/tools/blender/build_walker.py", encoding="utf-8").read())
Çıktı: build/blender/walker.blend (çeşitler yan yana). Konsept görselleri: render_lineup(),
render_gamecam(), render_close() (exec sonrası aynı ad alanında çağrılır).
Bu adım yalnız konsept: iskelet, animasyon ve GLB yok.
"""
import importlib
import math
import os
import sys

import bpy
from mathutils import Vector, geometry, noise

_HERE = globals().get("__file__", "")
REPO = os.path.abspath(os.path.join(os.path.dirname(_HERE), "..", "..")) if _HERE else ""
if not REPO or not os.path.isdir(os.path.join(REPO, "tools")):
    REPO = r"C:\Users\pekta\projeler\Deadzone-Last-Stand"
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import zombie_kit as kit  # noqa: E402

importlib.reload(kit)
OUT_BLEND = os.path.join(REPO, "build", "blender", "walker.blend")
CONCEPT_DIR = os.path.join(REPO, "docs", "concept")

# Karakter -Y yönüne bakar, Z yukarı, metre. Ortalama gövde (h=1) ~1.75 m.
# Gövde ekseni: (konum, yarıçap). Pelvis sağa (-X) kaymış, omuz hattı sola düşük.
TORSO_POINTS = {
    "pelvis": ((-0.045, 0.020, 0.950), 0.150),
    "belly": ((-0.020, -0.025, 1.080), 0.135),
    "spine": ((-0.010, 0.000, 1.180), 0.140),
    "chest": ((0.010, -0.065, 1.335), 0.160),
    "upchest": ((0.030, -0.095, 1.425), 0.130),
    "neck0": ((0.045, -0.125, 1.500), 0.062),
    "neck1": ((0.055, -0.155, 1.545), 0.055),
}
# Asimetrik duruş: R taşıyan bacak (düz), L geride sürünür (topuk kalkık, parmak ucu yerde).
LIMB_POINTS = {
    "hip_R": ((-0.135, 0.020, 0.960), 0.100), "hip_L": ((0.090, 0.015, 0.885), 0.100),
    "knee_R": ((-0.125, -0.040, 0.515), 0.065), "knee_L": ((0.135, -0.010, 0.480), 0.065),
    "ankle_R": ((-0.120, 0.030, 0.090), 0.045), "ankle_L": ((0.150, 0.170, 0.135), 0.045),
    "heel_R": ((-0.120, 0.070, 0.035), 0.040), "heel_L": ((0.152, 0.215, 0.115), 0.040),
    "ball_R": ((-0.120, -0.080, 0.030), 0.040), "ball_L": ((0.140, 0.085, 0.034), 0.040),
    "toe_R": ((-0.120, -0.150, 0.025), 0.030), "toe_L": ((0.125, 0.020, 0.026), 0.030),
    # kollar: sağ kol göğüs hizasında öne uzanır, sol (düşük omuz) daha aşağıda yarı kalkık
    "shoulder_R": ((-0.180, -0.085, 1.470), 0.080), "shoulder_L": ((0.220, -0.075, 1.330), 0.080),
    "elbow_R": ((-0.320, -0.260, 1.270), 0.055), "elbow_L": ((0.320, -0.180, 1.070), 0.055),
    "wrist_R": ((-0.300, -0.490, 1.300), 0.040), "wrist_L": ((0.330, -0.400, 1.100), 0.040),
    "palm_R": ((-0.280, -0.570, 1.295), 0.046), "palm_L": ((0.315, -0.480, 1.095), 0.046),
}
TORSO_EDGES = [("pelvis", "belly"), ("belly", "spine"), ("spine", "chest"), ("chest", "upchest"),
               ("upchest", "neck0"), ("neck0", "neck1")]
LIMB_CHAIN = [("hip", "knee"), ("knee", "ankle"), ("ankle", "heel"), ("ankle", "ball"),
              ("ball", "toe"), ("shoulder", "elbow"), ("elbow", "wrist"), ("wrist", "palm")]
# Kıyafet için uzuv sınıfları (parça adı -> sınıf).
PART_CLASS = {
    "pelvis-belly": "hips", "belly-spine": "torso", "spine-chest": "torso",
    "chest-upchest": "torso", "upchest-neck0": "neck", "neck0-neck1": "neck",
    "pelvis-hip": "hips", "upchest-shoulder": "clav", "hip-knee": "thigh", "knee-ankle": "shin",
    "ankle-heel": "foot", "ankle-ball": "foot", "ball-toe": "foot", "shoulder-elbow": "uparm",
    "elbow-wrist": "forearm", "wrist-palm": "hand",
}

# Kafa yerel uzayı: köken boyun üstü, yüz -Y. İnsan kafatası; çene ayrı ve sarkık.
HEAD_BLOBS = (
    [((0.0, 0.010, 0.070), (0.078, 0.092, 0.088), False),     # kafatası
     ((0.0, 0.050, 0.050), (0.064, 0.060, 0.064), False),     # art kafa
     ((0.0, -0.064, 0.086), (0.058, 0.018, 0.013), False),    # kaş çıkıntısı
     ((0.0, -0.066, 0.016), (0.044, 0.042, 0.044), False),    # üst çene / elmacık arası
     ((0.0, -0.104, 0.040), (0.012, 0.018, 0.026), False),    # burun
     ((0.0, 0.020, -0.030), (0.046, 0.046, 0.060), False),    # boyun bağı
     ((0.0, -0.088, -0.018), (0.030, 0.034, 0.020), True)]    # ağız boşluğu
    + kit.mirrored((0.048, -0.058, 0.032), (0.018, 0.026, 0.014))   # elmacık
    + kit.mirrored((0.058, -0.012, -0.002), (0.015, 0.020, 0.024))  # çene menteşesi
    + kit.mirrored((0.080, 0.004, 0.036), (0.007, 0.015, 0.021))    # kulak
    + kit.mirrored((0.032, -0.096, 0.052), (0.023, 0.024, 0.019), True)  # göz çukuru
    + kit.mirrored((0.050, -0.080, -0.004), (0.017, 0.016, 0.017), True)  # çökük yanak
)
JAW_HINGE = Vector((0.0, -0.010, -0.006))
JAW_BLOBS = (kit.mirrored((0.052, -0.004, -0.012), (0.013, 0.019, 0.030))
             + kit.mirrored((0.040, -0.052, -0.046), (0.012, 0.030, 0.016))
             + [((0.0, -0.080, -0.050), (0.030, 0.018, 0.020), False)])
JAW_OPEN_DEG = 30.0       # sarkık çene
JAW_SLACK_DEG = 6.0       # yana kaymış
HEAD_PITCH_DEG = 18.0     # öne düşük
HEAD_ROLL_DEG = 22.0      # düşük omuza (+X) yatık
HEAD_YAW_DEG = -8.0

LINEUP_SPACING = 1.05

# Çeşitler. body: h boy, w genişlik, t uzuv kalınlığı, belly göbek, head kafa ölçeği.
# top: tshirt / shirt (uzun kollu) / tank / None; vest: iş yeleği; tie: kravat;
# bottom: pants / shorts (hem: paçanın kesildiği bacak oranı 0 kalça .. 1 bilek);
# shoes: renk ya da None (çıplak ayak); hair: renk ya da None (kel). Renkler doğrusal RGB.
VARIANTS = [
    {"name": "Office", "body": {"h": 1.00, "w": 0.98, "t": 0.95, "belly": 1.0, "head": 1.00},
     "tone": (0.30, 0.32, 0.26), "bruise": (0.24, 0.14, 0.16),
     "top": "shirt", "top_color": (0.62, 0.66, 0.70), "blood": 0.7, "vest": None,
     "tie": (0.30, 0.02, 0.03), "bottom": "pants", "bottom_color": (0.06, 0.06, 0.07), "hem": 0.92,
     "shoes": (0.02, 0.018, 0.016), "hair": (0.035, 0.025, 0.018), "seed": 0.0},
    {"name": "Worker", "body": {"h": 0.98, "w": 1.22, "t": 1.18, "belly": 1.45, "head": 1.05},
     "tone": (0.31, 0.27, 0.22), "bruise": (0.26, 0.10, 0.12),
     "top": "tshirt", "top_color": (0.16, 0.17, 0.18), "blood": 0.4, "vest": (0.85, 0.22, 0.02),
     "tie": None, "bottom": "pants", "bottom_color": (0.05, 0.09, 0.18), "hem": 0.95,
     "shoes": (0.12, 0.06, 0.025), "hair": None, "seed": 3.3},
    {"name": "Skinny", "body": {"h": 1.06, "w": 0.86, "t": 0.98, "belly": 0.85, "head": 0.97},
     "tone": (0.20, 0.23, 0.26), "bruise": (0.18, 0.10, 0.14),
     "top": "tank", "top_color": (0.45, 0.42, 0.34), "blood": 0.9, "vest": None,
     "tie": None, "bottom": "shorts", "bottom_color": (0.20, 0.17, 0.09), "hem": 0.42,
     "shoes": None, "hair": (0.08, 0.075, 0.07), "seed": 7.1},
    {"name": "Civilian", "body": {"h": 0.90, "w": 1.06, "t": 1.05, "belly": 1.1, "head": 1.04},
     "tone": (0.13, 0.10, 0.08), "bruise": (0.12, 0.05, 0.06),
     "top": "tshirt", "top_color": (0.42, 0.04, 0.035), "blood": 0.3, "vest": None,
     "tie": None, "bottom": "pants", "bottom_color": (0.09, 0.14, 0.25), "hem": 0.78,
     "shoes": (0.16, 0.155, 0.14), "hair": (0.05, 0.03, 0.018), "seed": 11.7},
]


# ---------------------------------------------------------------- gövde

def _scaled(p, r, body, limb):
    x, y, z = p
    w, h = body["w"], body["h"]
    rr = r * (body["t"] if limb else w)
    return (Vector((x * w, y * (0.6 + 0.4 * w), z * h)), rr)


def body_points(body):
    """Çeşidin gövde noktaları (dünya, karakter kökü 0'da)."""
    pts = {}
    for n, (p, r) in TORSO_POINTS.items():
        pts[n] = _scaled(p, r, body, False)
    pos, r = pts["belly"]
    pts["belly"] = (pos + Vector((0.0, -0.03 * (body["belly"] - 1.0), 0.0)), r * body["belly"] ** 0.7)
    for n, (p, r) in LIMB_POINTS.items():
        pts[n] = _scaled(p, r, body, True)
    return pts


def _hand(pts, side, t):
    """Kısa, hafif kıvrık dört parmak + başparmak; avuç öne açık (kucaklamaya hazır)."""
    wrist, palm = pts[f"wrist_{side}"][0], pts[f"palm_{side}"][0]
    d = (palm - wrist).normalized()
    across = d.cross(Vector((0.0, 0.0, 1.0))).normalized()
    down = across.cross(d).normalized()
    if down.z > 0.0:
        down = -down
    inward = Vector((-1.0 if palm.x > 0 else 1.0, 0.0, 0.0))
    extra, edges = {}, []
    for i in range(4):
        spread = (i - 1.5) * 0.026 * t
        base = palm + across * spread
        mid = base + d * 0.052 + down * 0.008 + across * spread * 0.5
        tip = mid + d * 0.034 + down * 0.030 + across * spread * 0.3
        extra[f"f{i}a_{side}"] = (mid, 0.0112 * t)
        extra[f"f{i}b_{side}"] = (tip, 0.0085 * t)
        edges += [(f"palm_{side}", f"f{i}a_{side}"), (f"f{i}a_{side}", f"f{i}b_{side}")]
    thumb = palm + d * 0.022 + inward * 0.040 + Vector((0.0, 0.0, 0.016))
    extra[f"th_{side}"] = (thumb + d * 0.028 + inward * 0.006, 0.0105 * t)
    edges.append((f"palm_{side}", f"th_{side}"))
    return extra, edges


def build_body(v, mat):
    body = v["body"]
    pts = body_points(body)
    edges = list(TORSO_EDGES)
    for side in ("L", "R"):
        edges += [(f"{a}_{side}", f"{b}_{side}") for a, b in LIMB_CHAIN]
        edges += [("pelvis", f"hip_{side}"), ("upchest", f"shoulder_{side}")]
        extra, e = _hand(pts, side, body["t"])
        pts.update(extra)
        edges += e
    skin_pts = {n: (tuple(p), r) for n, (p, r) in pts.items()}
    obj = kit.skin_object("Walker_Body", skin_pts, edges, mat)
    kit.organic_pass(obj, voxel=0.008)
    segments = []
    for a, b in edges:
        key = f"{a.split('_')[0]}-{b.split('_')[0]}"
        if key in PART_CLASS:
            segments.append((PART_CLASS[key], pts[a][0], pts[b][0]))
    return obj, segments, pts


def classify(co, segments):
    """Noktanın en yakın iskelet parçası: (sınıf, parça boyunca 0..1)."""
    best, best_d = ("torso", 0.0), 1e9
    for cls, a, b in segments:
        closest, t = geometry.intersect_point_line(co, a, b)
        t = min(max(t, 0.0), 1.0)
        d = (co - a.lerp(b, t)).length
        if d < best_d:
            best, best_d = (cls, t), d
    return best


# ---------------------------------------------------------------- kafa

def build_head(v, mat, tooth_mat, eye_mat, hair_mat, pts):
    s = v["body"]["head"]
    blobs = [(tuple(Vector(c) * s), tuple(r_ * s for r_ in r), neg) for c, r, neg in HEAD_BLOBS]
    head = kit.metaball_mesh("Walker_Head", blobs, mat)
    # saç: kafa kökteyken yüzeyinden (kel çeşitte yok)
    if hair_mat is not None:
        def keep_hair(co):
            co = co / s
            n = 0.012 * noise.noise(co * 40.0 + Vector((v["seed"], 0.0, 0.0)))
            if abs(co.x) > 0.068 and co.z < 0.080:  # kulak çevresi açık
                return False
            if co.y < -0.040:  # alın saç çizgisi
                return co.z > 0.105 + n
            return co.z > 0.025 + n
        hair = kit.garment(head, "Walker_Hair", keep_hair, hair_mat, offset=0.003 * s,
                           thickness=0.005 * s, holes=0.25, hole_scale=45.0, seed=v["seed"])
        hair.parent = head
    for i in range(6):
        a = math.radians(-50 + i * 20)
        pos = Vector((0.030 * math.sin(a), -0.080 - 0.022 * math.cos(a), -0.008)) * s
        tooth = kit.primitive("Walker_ToothU", "cone", pos, radius1=0.0055 * s, depth=0.013 * s)
        tooth.rotation_euler = (math.radians(180), 0.0, 0.0)
        tooth.data.materials.append(tooth_mat)
        tooth.parent = head
    for sx in (1.0, -1.0):
        eye = kit.primitive("Walker_Eye", "sphere", Vector((0.031 * sx, -0.073, 0.050)) * s,
                            segments=12, rings=8, radius=0.0072 * s)
        eye.data.materials.append(eye_mat)
        eye.parent = head
    # koyu ağız içi: sarkık çenenin açtığı boşluk karanlık okunsun
    mouth_mat, _ = kit.material("M_Walker_Mouth_" + v["name"], (0.012, 0.003, 0.003), rough=0.8)
    mouth = kit.metaball_mesh("Walker_Mouth", [((0.0, -0.050, -0.030), (0.032, 0.030, 0.034), False)],
                              mouth_mat, resolution=0.004)
    for vert in mouth.data.vertices:
        vert.co *= s
    mouth.parent = head
    build_jaw(head, s, mat, tooth_mat)
    neck = pts["neck1"][0]
    head.location = neck + Vector((0.006, -0.022, 0.030)) * v["body"]["h"]
    head.rotation_euler = (math.radians(HEAD_PITCH_DEG), math.radians(HEAD_ROLL_DEG),
                           math.radians(HEAD_YAW_DEG))
    return head


def build_jaw(head, s, mat, tooth_mat):
    """Tek parça, menteşeden sarkık ve hafif yana kaymış alt çene."""
    blobs = [(tuple(Vector(c) * s), tuple(r_ * s for r_ in r), neg) for c, r, neg in JAW_BLOBS]
    jaw = kit.metaball_mesh("Walker_Jaw", blobs, mat, resolution=0.003)
    for i in range(5):
        a = math.radians(-44 + i * 22)
        pos = Vector((0.028 * math.sin(a), -0.072 - 0.010 * math.cos(a), -0.034)) * s
        tooth = kit.primitive("Walker_ToothL", "cone", pos, radius1=0.005 * s, depth=0.011 * s)
        tooth.data.materials.append(tooth_mat)
        tooth.parent = jaw
    jaw.parent = head
    jaw.location = JAW_HINGE * s
    jaw.rotation_euler = (math.radians(JAW_OPEN_DEG), math.radians(JAW_SLACK_DEG), 0.0)


# ---------------------------------------------------------------- kıyafet

def _noisy(co, amp=0.12, scale=12.0, seed=0.0):
    return amp * noise.noise(co * scale + Vector((seed, 0.0, 0.0)))


def build_clothes(body_obj, segments, v, suffix):
    h, seed = v["body"]["h"], v["seed"]
    cache = {}

    def part(co):
        key = (round(co.x, 4), round(co.y, 4), round(co.z, 4))
        if key not in cache:
            cache[key] = classify(co, segments)
        return cache[key]

    top = v["top"]
    if top:
        sleeve = {"tshirt": ("uparm", 0.55), "shirt": ("forearm", 0.80), "tank": (None, 0.0)}[top]

        def keep_top(co):
            cls, t = part(co)
            if cls in ("torso", "hips"):
                return True
            if cls == "clav":
                return top != "tank" or t < 0.45
            if top == "tank" or sleeve[0] is None:
                return False
            if cls == "uparm":
                return sleeve[0] == "forearm" or t < sleeve[1] + _noisy(co, seed=seed)
            if cls == "forearm" and sleeve[0] == "forearm":
                return t < sleeve[1] + _noisy(co, seed=seed)
            return False
        mat = kit.cloth_material("M_Walker_Top" + suffix, v["top_color"], blood=v["blood"])
        kit.garment(body_obj, "Walker_Top", keep_top, mat, offset=0.010,
                    hems=[(2, 0.93 * h, 1.0, 0.035, 9.0)], holes=0.30, seed=seed)
    if v["vest"]:
        def keep_vest(co):
            cls, _t = part(co)
            if cls == "clav":
                return _t < 0.55
            if cls not in ("torso", "hips"):
                return False
            vneck = co.y < -0.05 and abs(co.x) < max(0.0, (co.z - 1.22 * h)) * 0.55
            return not vneck
        mat = kit.cloth_material("M_Walker_Vest" + suffix, v["vest"], blood=0.3)
        kit.garment(body_obj, "Walker_Vest", keep_vest, mat, offset=0.024, thickness=0.006,
                    hems=[(2, 0.98 * h, 1.0, 0.025, 8.0)], holes=0.15, seed=seed + 2.0)
    if v["tie"]:
        def keep_tie(co):
            cls, _t = part(co)
            return cls == "torso" and co.y < -0.05 and abs(co.x - 0.005) < 0.022 + 0.01 * (1.46 * h - co.z) \
                and co.z < 1.47 * h
        mat = kit.cloth_material("M_Walker_Tie" + suffix, v["tie"])
        kit.garment(body_obj, "Walker_Tie", keep_tie, mat, offset=0.017, thickness=0.004,
                    hems=[(2, 1.13 * h, 1.0, 0.02, 10.0)], seed=seed + 4.0)
    hem = v["hem"]

    def keep_bottom(co):
        cls, t = part(co)
        if cls == "hips":
            return co.z < 1.03 * h
        if cls == "torso":
            return co.z < 1.03 * h
        if cls == "thigh":
            return hem >= 0.5 or t < hem * 2.0 + _noisy(co, 0.10, seed=seed)
        if cls == "shin":
            return hem > 0.5 and t < (hem - 0.5) * 2.0 + _noisy(co, 0.06, seed=seed)
        return False
    mat = kit.cloth_material("M_Walker_Bottom" + suffix, v["bottom_color"], stain=(0.05, 0.04, 0.03))
    kit.garment(body_obj, "Walker_Bottom", keep_bottom, mat, offset=0.008, holes=0.22, seed=seed + 1.0)
    if v["shoes"]:
        def keep_shoe(co):
            cls, t = part(co)
            return cls == "foot" or (cls == "shin" and t > 0.90)
        mat, _ = kit.material("M_Walker_Shoes" + suffix, v["shoes"], rough=0.55)
        kit.garment(body_obj, "Walker_Shoes", keep_shoe, mat, offset=0.012, thickness=0.010)


# ---------------------------------------------------------------- çeşit

def build_variant(v, offset_x=0.0):
    before = set(bpy.data.objects)
    suffix = "_" + v["name"]
    skin = kit.skin_material("M_Walker_Skin" + suffix, v["tone"], v["bruise"])
    tooth_mat, _ = kit.material("M_Walker_Teeth" + suffix, (0.45, 0.40, 0.28), rough=0.4)
    eye_mat, _ = kit.material("M_Walker_Eye" + suffix, (0.30, 0.29, 0.19), rough=0.15,
                              emission=(0.75, 0.80, 0.55), strength=0.08)
    hair_mat = kit.cloth_material("M_Walker_Hair" + suffix, v["hair"], stain=v["hair"]) if v["hair"] else None
    body_obj, segments, pts = build_body(v, skin)
    build_clothes(body_obj, segments, v, suffix)
    build_head(v, skin, tooth_mat, eye_mat, hair_mat, pts)
    created = list(set(bpy.data.objects) - before)
    root = bpy.data.objects.new("Walker_" + v["name"], None)
    bpy.context.collection.objects.link(root)
    for obj in created:
        if obj.parent is None:
            obj.parent = root
    root.location.x = offset_x
    return root


def face_count(root):
    total = 0
    for obj in [root] + list(root.children_recursive):
        if obj.type == "MESH":
            total += sum(len(p.vertices) - 2 for p in obj.data.polygons)
    return total


def build() -> None:
    kit.reset_scene()
    count = len(VARIANTS)
    for i, v in enumerate(VARIANTS):
        root = build_variant(v, (i - (count - 1) / 2) * LINEUP_SPACING)
        print("WALKER", v["name"], "tris:", face_count(root))
    kit.setup_look()
    _front_camera()
    os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    print("WALKER built, variants:", count)


# ---------------------------------------------------------------- konsept görselleri

def _aim(cam, eye, target):
    cam.location = eye
    cam.rotation_euler = (Vector(target) - Vector(eye)).to_track_quat("-Z", "Y").to_euler()


def _front_camera():
    scene = bpy.context.scene
    _aim(scene.camera, (0.0, -6.2, 1.25), (0.0, -0.2, 0.92))
    scene.camera.data.lens = 50
    scene.render.resolution_x, scene.render.resolution_y = 1400, 1100


def _render_settings(samples=64):
    scene = bpy.context.scene
    try:
        scene.render.engine = "CYCLES"
        scene.cycles.samples = samples
        scene.cycles.use_denoising = True
    except (TypeError, AttributeError) as err:
        print("engine:", err)
    scene.render.image_settings.file_format = "PNG"


def _render_to(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def _side_by_side(paths, out):
    import numpy as np
    imgs = [bpy.data.images.load(p, check_existing=False) for p in paths]
    w = sum(i.size[0] for i in imgs)
    h = max(i.size[1] for i in imgs)
    canvas = np.zeros((h, w, 4), dtype=np.float32)
    x = 0
    for img in imgs:
        iw, ih = img.size
        px = np.empty(iw * ih * 4, dtype=np.float32)
        img.pixels.foreach_get(px)
        canvas[:ih, x:x + iw] = px.reshape(ih, iw, 4)
        x += iw
    result = bpy.data.images.new("walker_combined", w, h, alpha=True)
    result.pixels.foreach_set(canvas.ravel())
    result.filepath_raw = out
    result.file_format = "PNG"
    result.save()
    for img in imgs + [result]:
        bpy.data.images.remove(img)
    return out


def render_lineup(samples=64):
    """Tüm çeşitler: önden ve 3/4'ten, yan yana tek görsel."""
    _render_settings(samples)
    scene = bpy.context.scene
    tmp = os.path.join(REPO, "build", "shots")
    os.makedirs(tmp, exist_ok=True)
    scene.render.resolution_x, scene.render.resolution_y = 1100, 1000
    scene.camera.data.lens = 42
    _aim(scene.camera, (0.0, -6.0, 1.30), (0.0, -0.2, 0.90))
    a = _render_to(os.path.join(tmp, "walker_front.png"))
    _aim(scene.camera, (3.9, -4.6, 1.75), (0.0, -0.2, 0.88))
    b = _render_to(os.path.join(tmp, "walker_34.png"))
    return _side_by_side([a, b], os.path.join(CONCEPT_DIR, "walker_v1_lineup.png"))


def render_close(name="Office", samples=96):
    """Bir çeşidin yakın görüntüsü (bel üstü, 3/4)."""
    _render_settings(samples)
    scene = bpy.context.scene
    root = bpy.data.objects["Walker_" + name]
    c = root.matrix_world.translation
    scene.render.resolution_x, scene.render.resolution_y = 1000, 1100
    scene.camera.data.lens = 60
    _aim(scene.camera, (c.x + 0.75, -1.85, 1.62), (c.x, -0.28, 1.36))
    return _render_to(os.path.join(CONCEPT_DIR, "walker_v1_close.png"))


GAMECAM_LAYOUT = [  # (çeşit indeksi, x, y, yön derece) — sürü: dağınık, oyuncuya (-Y) doğru
    (0, -1.6, 0.4, 8), (1, -0.4, -0.3, -12), (2, 0.9, 0.5, 20), (3, 2.0, -0.2, -5),
    (3, -2.4, 1.8, 15), (0, -0.9, 1.6, -20), (1, 0.6, 2.0, 5), (2, 1.8, 1.4, -15),
]


def build_gamecam(with_dilci=True):
    """Oyun kamerasına benzer sahne: dağınık yürüyen grubu + karşılaştırma için bir dilci."""
    kit.reset_scene()
    for coll in list(bpy.data.collections):
        if coll.name.startswith("C_Walker_"):
            bpy.data.collections.remove(coll)
    roots = [build_variant(v) for v in VARIANTS]
    for root in roots:
        root.location = (0.0, 0.0, -50.0)  # şablonlar görünmez yerde
    for idx, x, y, yaw in GAMECAM_LAYOUT:
        src = roots[idx]
        dup = bpy.data.objects.new(src.name + "_g", None)
        bpy.context.collection.objects.link(dup)
        dup.instance_type = "COLLECTION"
        dup.location = (x, y, 0.0)
        dup.rotation_euler = (0.0, 0.0, math.radians(yaw))
        dup.instance_collection = _variant_collection(src)
    if with_dilci:
        import build_dilci as dilci
        importlib.reload(dilci)
        droot, _ = dilci.build_variant(dilci.VARIANTS[1], 3.4, with_tongue=True)
        droot.location.y = 1.0
        droot.rotation_euler.z = math.radians(-20)
    kit.setup_look()
    for light in ("Key", "Rim", "Fill"):
        obj = bpy.data.objects[light]
        obj.location = obj.location * 3.0 + Vector((0.4, 0.6, 0.0))
        obj.data.energy *= 9.0
        obj.data.size *= 3.0
        obj.rotation_euler = (Vector((0.4, 0.6, 0.6)) - obj.location).to_track_quat("-Z", "Y").to_euler()


def _variant_collection(root):
    coll = bpy.data.collections.get("C_" + root.name)
    if coll is None:
        coll = bpy.data.collections.new("C_" + root.name)
        bpy.context.scene.collection.children.link(coll)
        for obj in [root] + list(root.children_recursive):
            for c in list(obj.users_collection):
                c.objects.unlink(obj)
            coll.objects.link(obj)
        root.location = (0.0, 0.0, 0.0)
        coll.hide_render = False
        bpy.context.view_layer.layer_collection.children[coll.name].exclude = True
    return coll


def render_gamecam(samples=64):
    """~55° aşağı bakan, uzak, dar açılı kamera (oyunda ~17 m)."""
    _render_settings(samples)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 1400, 900
    cam = scene.camera
    cam.data.lens = 85
    pitch = math.radians(55.0)
    dist = 17.0
    target = Vector((0.5, 0.9, 0.7))
    _aim(cam, target + Vector((0.0, -math.cos(pitch), math.sin(pitch))) * dist, target)
    return _render_to(os.path.join(CONCEPT_DIR, "walker_v1_gamecam.png"))


# Modül olarak içe aktarılınca kurulum çalışmaz; exec ile çalıştırınca çalışır.
if __name__ != "build_walker":
    build()
