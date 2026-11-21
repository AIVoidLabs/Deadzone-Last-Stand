"""Çığlıkçı zombi ("Çağıran", `screamer`) konsepti — 7.3, tamamen Blender (arka plan örneği).

İmza: UZUN VE İNCE (1.95 m, yürüyenden ~20 cm uzun), UZUN BOYUN (kirişleri görünür), dar omuzlar,
görünen göğüs kafesi, çökük karın, uzun kemikli kollar ve parmaklar. Çenesi aşırı açılır: yanak
zarları yırtılıp gerilir (screamer_head ağız torbası). İmza anı: baş geriye atılır, göğüs şişer, kollar
yana açılır, çene sonuna dek düşer; ağız öne-yukarı (oyun kamerasına) bakar.
Oyuncuya kararı: kalabalık büyümeden onu bul, öncelikli hedef yap.
v2 ortak düzeltmeleri baştan: kendi kafası (screamer_head), tanımlı (kuru) kas grupları + ince eklemler,
kaburga kabartması (screamer_parts), çıplak ayakta parmaklar, kumaş gibi kıyafet (screamer_clothes).

Gövde: iskelet noktaları + skin modifier + kas kütleleri, voxel remesh ile kaynar (zombie_kit).
El ve ayak parmakları ayrı ağ. Pozlar: "neutral" ve "signature" (çığlık tepe anı).

Çalıştırma (arka plan):
    blender --background --python tools/blender/screamer_render.py     (konsept görselleri)
Yalnız dizi blend'i:  blender --background --python tools/blender/build_screamer.py
Çıktı: build/blender/screamer.blend. Oyun modeli: screamer_game.py.
"""
import importlib
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector, geometry

_HERE = globals().get("__file__", "")
REPO = os.path.abspath(os.path.join(os.path.dirname(_HERE), "..", "..")) if _HERE else ""
if not REPO or not os.path.isdir(os.path.join(REPO, "tools")):
    REPO = r"C:\Users\pekta\projeler\Deadzone-Last-Stand"
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import zombie_kit as kit  # noqa: E402
import walker_head as wh  # noqa: E402
import tank_parts as tp  # noqa: E402
import screamer_parts as sp  # noqa: E402
import screamer_head as sh  # noqa: E402
import screamer_clothes as sc  # noqa: E402

for _m in (kit, wh, tp, sp, sh, sc):
    importlib.reload(_m)
OUT_BLEND = os.path.join(REPO, "build", "blender", "screamer.blend")

# Karakter -Y'ye bakar, Z yukarı, metre. Dik ama göğüs çökük, boyun öne uzanır.
TORSO_POINTS = {
    "pelvis": ((0.0, 0.03, 1.07), 0.125),
    "belly": ((0.0, 0.040, 1.23), 0.098),
    "spine": ((0.0, 0.045, 1.37), 0.116),
    "chest": ((0.0, 0.030, 1.49), 0.124),
    "upchest": ((0.0, 0.000, 1.585), 0.090),
    "neck0": ((0.0, -0.035, 1.630), 0.046),
    "neck1": ((0.0, -0.165, 1.790), 0.041),
}
# Sol (+X) taraf; sağ aynalanır. "tip": el yönü (bilekten parmaklara).
SIDE_POINTS = {
    "shoulder": ((0.150, -0.030, 1.528), 0.047), "elbow": ((0.196, 0.010, 1.190), 0.034),
    "wrist": ((0.202, -0.080, 0.878), 0.026), "tip": ((0.198, -0.105, 0.776), 0.0),
    "hip": ((0.090, 0.030, 1.035), 0.075), "knee": ((0.105, -0.045, 0.570), 0.046),
    "ankle": ((0.112, 0.030, 0.100), 0.036), "heel": ((0.112, 0.075, 0.048), 0.032),
    "ball": ((0.118, -0.090, 0.040), 0.032), "toe": ((0.118, -0.140, 0.030), 0.025),
}
ARMS = ("shoulder", "elbow", "wrist", "tip")
LEGS = ("hip", "knee", "ankle", "heel", "ball", "toe")
TORSO_EDGES = [("pelvis", "belly"), ("belly", "spine"), ("spine", "chest"), ("chest", "upchest"),
               ("upchest", "neck0"), ("neck0", "neck1")]
LIMB_CHAIN = [("hip", "knee"), ("knee", "ankle"), ("ankle", "heel"), ("ankle", "ball"),
              ("ball", "toe"), ("shoulder", "elbow"), ("elbow", "wrist")]
PART_CLASS = {
    "pelvis-belly": "hips", "belly-spine": "torso", "spine-chest": "torso", "chest-upchest": "torso",
    "upchest-neck0": "neck", "neck0-neck1": "neck", "pelvis-hip": "hips", "upchest-shoulder": "clav",
    "hip-knee": "thigh", "knee-ankle": "shin", "ankle-heel": "foot", "ankle-ball": "foot", "ball-toe": "foot",
    "shoulder-elbow": "uparm", "elbow-wrist": "forearm",
}
# İmza (çığlık tepe anı): gövde geriye yatar (göğüs şişer), boyun geriye kırılır, kollar yana açılır.
SIG_LEAN = -13.0          # gövde pelvis çevresinde geriye (derece)
SIG_NECK = -24.0          # boyun neck0 çevresinde ayrıca geriye (derece)
SIG_ARMS = {"elbow": (0.45, 0.13, 1.40), "wrist": (0.73, 0.14, 1.51), "tip": (0.82, 0.13, 1.55)}
SIG_LEGS = {"knee": (0.135, -0.07, 0.56), "ankle": (0.16, -0.02, 0.10), "heel": (0.16, 0.025, 0.048),
            "ball": (0.17, -0.14, 0.040), "toe": (0.17, -0.19, 0.030)}
SIG_DROP = 0.02
CHEST_SWELL = 1.10        # imzada göğüs kafesi yarıçapı çarpanı
POSE_HEAD = {"neutral": (-14.0, sh.JAW_REST_DEG), "signature": (-30.0, sh.JAW_SCREAM_DEG)}  # (eğim, çene)
HAND_SCALE = 0.95
HAND_CURL = {"neutral": 0.65, "signature": 0.10}
LINEUP_SPACING = 1.2
VOXEL = 0.0075

# Çeşitler. body: s ölçek, w gövde genişliği, arm kol kası, legs bacak kası, head kafa ölçeği.
# top: gown / nurse / None; bottom: pants / None; hem paça (shin 0..1); shoes renk ya da None (yalın ayak).
VARIANTS = [
    {"name": "Gown", "body": {"s": 1.0, "w": 1.0, "arm": 1.0, "legs": 1.0, "head": 1.0},
     "tone": (0.24, 0.25, 0.21), "bruise": (0.12, 0.08, 0.12), "bruise_band": (0.48, 0.70),
     "top": "gown", "top_color": (0.16, 0.32, 0.33), "blood": 0.55, "holes": 0.22,
     "bottom": None, "hem": 0.0, "shoes": None, "hair": (0.05, 0.045, 0.04), "hair_style": "fringe",
     "band": True, "seed": 3.3},
    {"name": "Nurse", "body": {"s": 0.985, "w": 0.97, "arm": 0.95, "legs": 0.97, "head": 0.98},
     "tone": (0.26, 0.24, 0.21), "bruise": (0.14, 0.07, 0.09), "bruise_band": (0.50, 0.72),
     "top": "nurse", "top_color": (0.55, 0.58, 0.62), "blood": 0.55, "holes": 0.25,
     "bottom": None, "hem": 0.0, "shoes": (0.40, 0.40, 0.38), "hair": (0.07, 0.04, 0.02),
     "hair_style": "long", "band": False, "seed": 6.1},
    {"name": "Bare", "body": {"s": 1.01, "w": 0.98, "arm": 1.05, "legs": 1.0, "head": 1.01},
     "tone": (0.20, 0.22, 0.19), "bruise": (0.10, 0.06, 0.09), "bruise_band": (0.46, 0.68),
     "top": None, "top_color": None, "blood": 0.0, "holes": 0.0,
     "bottom": "pants", "bottom_color": (0.10, 0.09, 0.075), "hem": 0.55, "shoes": None,
     "hair": (0.03, 0.03, 0.03), "hair_style": "bald", "band": False, "seed": 9.7},
]


# ---------------------------------------------------------------- noktalar

def body_points(body, pose="neutral"):
    """Çeşidin ve pozun gövde noktaları {ad: (Vector, yarıçap)} (çeşit ölçeğinden önce, kök 0'da)."""
    w = body["w"]
    pts = {n: (Vector(p), r * w) for n, (p, r) in TORSO_POINTS.items()}
    for n, (p, r) in SIDE_POINTS.items():
        k = body.get("arm", 1.0) if n in ARMS else body.get("legs", 1.0)
        for side, sx in (("L", 1.0), ("R", -1.0)):
            x = p[0] * (w if n in ARMS else 1.0)
            pts[f"{n}_{side}"] = (Vector((x * sx, p[1], p[2])), r * k)
    if pose == "signature":
        _signature(pts)
    return pts


def _rot_about(pivot, deg):
    return Matrix.Translation(pivot) @ Matrix.Rotation(math.radians(deg), 4, "X") @ Matrix.Translation(-pivot)


def _signature(pts):
    pivot = pts["pelvis"][0].copy()
    m = Matrix.Translation(Vector((0, 0, -SIG_DROP))) @ _rot_about(pivot, SIG_LEAN)
    for n, (p, r) in list(pts.items()):
        base = n.split("_")[0]
        if base in LEGS and base != "hip":
            continue
        pts[n] = ((p - Vector((0, 0, SIG_DROP))) if base == "hip" else m @ p, r)
    for n in ("chest", "upchest"):
        p, r = pts[n]
        pts[n] = (p, r * CHEST_SWELL)
    neck = _rot_about(pts["neck0"][0].copy(), SIG_NECK)
    pts["neck1"] = (neck @ pts["neck1"][0], pts["neck1"][1])
    for n, p in SIG_ARMS.items():
        for side, sx in (("L", 1.0), ("R", -1.0)):
            q = m @ Vector((p[0] * sx, p[1], p[2] + SIG_DROP))
            pts[f"{n}_{side}"] = (q, pts[f"{n}_{side}"][1])
    for n, p in SIG_LEGS.items():
        for side, sx in (("L", 1.0), ("R", -1.0)):
            pts[f"{n}_{side}"] = (Vector((p[0] * sx, p[1], p[2])), pts[f"{n}_{side}"][1])


def edges():
    out = list(TORSO_EDGES)
    for side in ("L", "R"):
        out += [(f"{a}_{side}", f"{b}_{side}") for a, b in LIMB_CHAIN]
        out += [("pelvis", f"hip_{side}"), ("upchest", f"shoulder_{side}")]
    return out


# ---------------------------------------------------------------- gövde

def build_body(v, mat, pose):
    body = v["body"]
    pts = body_points(body, pose)
    blobs = sp.masses(pts, body, body_points(body, "neutral"))
    eds = edges()
    skin_pts = {n: (tuple(p), r) for n, (p, r) in pts.items() if not n.startswith("tip")}
    obj = kit.skin_object("Screamer_Body", skin_pts, eds, mat)
    tp.add_blobs(obj, blobs, resolution=0.007)
    kit.organic_pass(obj, voxel=VOXEL, lump=0.004)
    segments = []
    for a, b in eds:
        key = f"{a.split('_')[0]}-{b.split('_')[0]}"
        if key in PART_CLASS:
            segments.append((PART_CLASS[key], pts[a][0], pts[b][0]))
    return obj, segments, pts


def classify(co, segments):
    best, best_d = ("torso", 0.0), 1e9
    for cls, a, b in segments:
        _c, t = geometry.intersect_point_line(co, a, b)
        t = min(max(t, 0.0), 1.0)
        d = (co - a.lerp(b, t)).length
        if d < best_d:
            best, best_d = (cls, t), d
    return best


def build_extremities(v, pts, skin, pose):
    out = []
    for side, sx in (("L", 1.0), ("R", -1.0)):
        out.append(sp.build_hand("Screamer_Hand_" + side, pts[f"wrist_{side}"][0], pts[f"tip_{side}"][0],
                                 sx, HAND_SCALE * v["body"].get("arm", 1.0), skin, HAND_CURL[pose]))
        if not v["shoes"]:
            out.append(tp.build_toes("Screamer_Toes_" + side, pts[f"ball_{side}"][0], pts[f"toe_{side}"][0],
                                     sx, 0.66, skin, v["seed"]))
    return out


def skin_for(v, name):
    mat = kit.skin_material(name, v["tone"], v["bruise"])
    ramp = next(n for n in mat.node_tree.nodes if n.type == "VALTORGB")
    ramp.color_ramp.elements[0].position, ramp.color_ramp.elements[1].position = v["bruise_band"]
    return mat


def build_variant(v, offset_x=0.0, pose="neutral"):
    before = set(bpy.data.objects)
    suffix = "_" + v["name"]
    skin = skin_for(v, "M_Screamer_Skin" + suffix)
    tooth_mat, _ = kit.material("M_Screamer_Teeth" + suffix, sh.TOOTH_COLOR, rough=0.5)
    style = wh.HAIR_STYLES.get(v["hair_style"])
    hair_mat = wh.hair_material("M_Screamer_Hair" + suffix, v["hair"], style["rough"]) if style else None
    body_obj, segments, pts = build_body(v, skin, pose)
    cache = {}

    def part(co):
        key = (round(co.x, 3), round(co.y, 3), round(co.z, 3))
        if key not in cache:
            cache[key] = classify(co, segments)
        return cache[key]
    sp.rib_relief(body_obj, pts, part)
    build_extremities(v, pts, skin, pose)
    sc.build_clothes(body_obj, part, pts, v, suffix)
    if v["shoes"]:
        sc.build_shoes(body_obj, pts, part, v, suffix)
    pitch, jaw = POSE_HEAD[pose]
    tilt = (SIG_LEAN + SIG_NECK) if pose == "signature" else 0.0
    sh.build_head(v, skin, tooth_mat, hair_mat, pts["neck1"][0], pitch + tilt * 0.4, jaw)
    created = list(set(bpy.data.objects) - before)
    for obj in created:
        obj.name = obj.name.replace("Walker_", "Screamer_").replace("Tank_", "Screamer_")
    root = bpy.data.objects.new(f"Screamer_{v['name']}_{pose}", None)
    bpy.context.collection.objects.link(root)
    for obj in created:
        if obj.parent is None:
            obj.parent = root
    root.scale = (v["body"]["s"],) * 3
    root.location.x = offset_x
    return root


def face_count(root):
    return sum(sum(len(p.vertices) - 2 for p in o.data.polygons)
               for o in [root] + list(root.children_recursive) if o.type == "MESH")


def build(pose="neutral", save=True):
    kit.reset_scene()
    count = len(VARIANTS)
    roots = []
    for i, v in enumerate(VARIANTS):
        root = build_variant(v, (i - (count - 1) / 2) * LINEUP_SPACING, pose)
        print("SCREAMER", v["name"], pose, "tris:", face_count(root))
        roots.append(root)
    kit.setup_look(target_height=1.4)
    if save:
        os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    return roots


if __name__ not in ("build_screamer",):
    build()
