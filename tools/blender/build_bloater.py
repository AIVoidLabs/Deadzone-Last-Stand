"""Patlayıcı (bloater, "Şişko") zombi — 7.3, tamamen Blender (arka plan örneği).

İmza (s73_design): yaklaşınca durur, şişer, kabarcıklar parlar ve titrer, patlar. Oyuncuya kararı:
mesafeyi korumak ya da onu sürünün yanında vurup patlamayı silaha çevirmek.
Siluet: neredeyse küre gövde (dev göbek + sırt yağı), ince ama kaslı kol ve bacaklar (kollar küreden dışa
açık), gövdeye gömük küçük kafa. Gövdede turuncu-sarı parlayan kabarcık kümeleri (üstte ve önde yoğun,
oyun kamerasından okunur), gergin kıyafet göbekte boylamasına yarılmış.
v2 ortak düzeltmeleri baştan: kendi kafası (bloater_head), tanımlı kas grupları + ince eklemler
(bloater_parts, tank kas listesi küçültülmüş), çıplak ayakta parmaklar, kumaş gibi kıyafet (bloater_clothes).

Gövde: iskelet noktaları + skin modifier + kas/yağ kütleleri, voxel remesh ile kaynar (zombie_kit).
Pozlar veri: "neutral" ve "signature" (patlamadan hemen önce: şişmiş, kollar dışa itilmiş, kafa geride).

Çalıştırma (arka plan):
    blender --background --python tools/blender/bloater_render.py      (konsept görselleri)
    blender --background --python tools/blender/bloater_game.py        (GLB + klipler)
Yalnız dizi blend'i:  blender --background --python tools/blender/build_bloater.py
Çıktı: build/blender/bloater.blend
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
import bloater_parts as bp  # noqa: E402
import bloater_head as bh  # noqa: E402
import bloater_clothes as bc  # noqa: E402

for _m in (kit, wh, bp, bh, bc):
    importlib.reload(_m)
OUT_BLEND = os.path.join(REPO, "build", "blender", "bloater.blend")

# Karakter -Y yönüne bakar, Z yukarı, metre. Boy ~1.75 m (EnemyData height). Gövde noktaları küre gövdenin
# omurgası; asıl hacmi bloater_parts.masses verir.
TORSO_POINTS = {
    "pelvis": ((0.0, 0.03, 0.92), 0.16),
    "belly": ((0.0, -0.05, 1.10), 0.28),
    "spine": ((0.0, 0.03, 1.18), 0.28),
    "chest": ((0.0, 0.0, 1.32), 0.24),
    "upchest": ((0.0, -0.01, 1.46), 0.16),
    "neck0": ((0.0, -0.05, 1.55), 0.095),
    "neck1": ((0.0, -0.09, 1.62), 0.080),
}
# Sol (+X) taraf; sağ aynalanır. İnce uzuvlar; kollar göbeğin dışından sarkar, dizler hafif dışa (paytak).
SIDE_POSES = {
    "neutral": {
        "hip": ((0.15, 0.03, 0.90), 0.085), "knee": ((0.23, -0.05, 0.50), 0.052),
        "ankle": ((0.20, 0.03, 0.10), 0.042), "heel": ((0.20, 0.08, 0.05), 0.038),
        "ball": ((0.21, -0.09, 0.045), 0.036), "toe": ((0.21, -0.13, 0.04), 0.028),
        "shoulder": ((0.36, 0.03, 1.42), 0.080), "elbow": ((0.60, 0.07, 1.14), 0.050),
        "wrist": ((0.66, -0.03, 0.88), 0.038), "fist": ((0.67, -0.06, 0.77), 0.0),
    },
    # patlamadan önce: geniş duruş, dizler kırık; kollar şişen gövdeyle dışa-yukarı itilmiş, eller açık
    "signature": {
        "hip": ((0.15, 0.03, 0.88), 0.085), "knee": ((0.27, -0.10, 0.50), 0.050),
        "ankle": ((0.27, -0.02, 0.10), 0.042), "heel": ((0.27, 0.03, 0.05), 0.038),
        "ball": ((0.28, -0.14, 0.045), 0.036), "toe": ((0.28, -0.18, 0.04), 0.028),
        "shoulder": ((0.37, 0.03, 1.46), 0.080), "elbow": ((0.66, 0.06, 1.40), 0.050),
        "wrist": ((0.88, -0.04, 1.32), 0.038), "fist": ((0.96, -0.06, 1.30), 0.0),
    },
}
POSE_LEAN = {"neutral": 0.0, "signature": -10.0}
POSE_HEAD = {"neutral": (6.0, 18.0), "signature": (-22.0, 34.0)}
POSE_BELLY = {"neutral": 1.0, "signature": 1.20}
POSE_GLOW = {"neutral": 1.0, "signature": 3.0}    # imzada kabarcıklar parlar
UPPER = {"shoulder", "elbow", "wrist", "fist"}
LEGS = ("hip", "knee", "ankle", "heel", "ball", "toe", "pelvis")
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
LINEUP_SPACING = 1.5
VOXEL = 0.010

# Çeşitler. body: s genel ölçek, w genişlik, t kol kalınlığı, legs bacak, belly göbek, head kafa ölçeği.
# top: jacket / tank / None; apron: renk ya da None; bottom: pants/shorts ya da None; hem: >1 ise baldıra
# iner (1 + baldır oranı), <1 ise uylukta biter; shoes: renk ya da None (çıplak, parmaklı). Renkler doğrusal.
VARIANTS = [
    {"name": "Chef", "body": {"s": 0.97, "w": 1.0, "t": 1.0, "legs": 1.0, "belly": 1.0, "head": 1.22},
     "tone": (0.21, 0.24, 0.16), "bruise": (0.20, 0.08, 0.10),
     "top": "jacket", "top_color": (0.74, 0.72, 0.66), "blood": 0.5, "holes": 0.15,
     "apron": (0.40, 0.34, 0.24), "bottom": "pants", "hem": 1.92, "bottom_color": (0.035, 0.035, 0.04),
     "shoes": (0.05, 0.05, 0.05), "belt": None, "cap": None,
     "hair": (0.05, 0.035, 0.02), "hair_style": "sparse", "blisters": 1.0, "seed": 2.1},
    {"name": "Trucker", "body": {"s": 0.96, "w": 1.04, "t": 1.05, "legs": 1.0, "belly": 1.04, "head": 1.24},
     "tone": (0.23, 0.23, 0.15), "bruise": (0.19, 0.07, 0.09),
     "top": "tank", "top_color": (0.72, 0.70, 0.60), "blood": 0.7, "holes": 0.2,
     "apron": None, "bottom": "pants", "hem": 1.95, "bottom_color": (0.05, 0.08, 0.16),
     "shoes": (0.10, 0.06, 0.03), "belt": (0.04, 0.025, 0.015), "cap": (0.35, 0.06, 0.04),
     "hair": (0.03, 0.025, 0.02), "hair_style": "sparse", "blisters": 1.0, "seed": 5.7},
    {"name": "Bare", "body": {"s": 0.96, "w": 0.98, "t": 0.95, "legs": 1.0, "belly": 1.06, "head": 1.20},
     "tone": (0.19, 0.22, 0.16), "bruise": (0.22, 0.08, 0.11),
     "top": None, "top_color": None, "blood": 0.0, "apron": None,
     "bottom": "shorts", "hem": 0.38, "bottom_color": (0.12, 0.11, 0.09),
     "shoes": None, "belt": None, "cap": None,
     "hair": (0.02, 0.02, 0.02), "hair_style": "bald", "blisters": 1.3, "seed": 9.4},
]


# ---------------------------------------------------------------- gövde

def body_points(body, pose="neutral"):
    """Çeşidin ve pozun gövde noktaları (çeşit ölçeğinden önce, kök 0'da; eğilmeden önce)."""
    w, t = body["w"], body["t"]
    pts = {n: (Vector(p), r * w) for n, (p, r) in TORSO_POINTS.items()}
    for n, (p, r) in SIDE_POSES[pose].items():
        k = t if n in UPPER else body.get("legs", 1.0)
        for side, sx in (("L", 1.0), ("R", -1.0)):
            x = p[0] * (w if n in UPPER or n == "hip" else 1.0 + (w - 1.0) * 0.6)
            pts[f"{n}_{side}"] = (Vector((x * sx, p[1], p[2])), r * k)
    return pts


def lean_matrix(pts, pose):
    pivot = pts["pelvis"][0]
    rot = Matrix.Rotation(math.radians(POSE_LEAN[pose]), 4, "X")
    return Matrix.Translation(pivot) @ rot @ Matrix.Translation(-pivot)


def apply_lean(pts, blobs, pose):
    if not POSE_LEAN[pose]:
        return pts, blobs
    m = lean_matrix(pts, pose)
    q = m.to_quaternion()
    out = {n: ((m @ p) if n.split("_")[0] not in LEGS else p, r) for n, (p, r) in pts.items()}
    pelvis_z = pts["pelvis"][0].z
    new_blobs = []
    for c, radii, rot, neg in blobs:
        upper = c[2] > pelvis_z + 0.05
        new_blobs.append((tuple(m @ Vector(c)) if upper else c, radii, (q @ rot) if upper else rot, neg))
    return out, new_blobs


def build_body(v, mat, pose):
    body = dict(v["body"])
    body["belly"] *= POSE_BELLY[pose]
    pts = body_points(body, pose)
    blobs = bp.masses(pts, body, body_points(body, "neutral"))
    pts, blobs = apply_lean(pts, blobs, pose)
    edges = list(TORSO_EDGES)
    for side in ("L", "R"):
        edges += [(f"{a}_{side}", f"{b}_{side}") for a, b in LIMB_CHAIN]
        edges += [("pelvis", f"hip_{side}"), ("upchest", f"shoulder_{side}")]
    skin_pts = {n: (tuple(p), r) for n, (p, r) in pts.items() if not n.startswith("fist")}
    obj = kit.skin_object("Bloater_Body", skin_pts, edges, mat)
    bp.add_blobs(obj, blobs)
    kit.organic_pass(obj, voxel=VOXEL, lump=0.005)
    segments = []
    for a, b in edges:
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


GUT_CLASS = 1.12          # göbek küresinin bu katı içindeki yüzey gövde sayılır (kol/uyluk değil)


def gut_sphere(v, pts, pose="neutral"):
    """Küre gövdenin merkezi ve yarıçapı (kıyafet sınıfı ve kabarcıklar için)."""
    g = v["body"]["belly"] * POSE_BELLY[pose]
    return pts["belly"][0] + Vector((0.0, -0.05, 0.02)), 0.40 * g * v["body"]["w"]


def stretch_marks(body, pts, seed):
    """Göbekte gerilme çatlakları: yatay ince oluklar (köşe normali boyunca içe)."""
    gut = pts["belly"][0]
    for vert in body.data.vertices:
        c = vert.co - gut
        if c.length > 0.47 or c.z < -0.30:
            continue
        band = math.sin(c.z * 120.0 + 3.0 * math.sin(c.x * 9.0 + seed))
        if band > 0.93:
            vert.co -= vert.normal * 0.0025


# ---------------------------------------------------------------- çeşit

def build_extremities(v, pts, skin):
    out = []
    for side, sx in (("L", 1.0), ("R", -1.0)):
        out.append(bp.build_hand("Bloater_Hand_" + side, pts[f"wrist_{side}"][0], pts[f"fist_{side}"][0],
                                 sx, v["body"]["t"] * 1.25, skin))
        if not v["shoes"]:
            out.append(bp.build_toes("Bloater_Toes_" + side, pts[f"ball_{side}"][0], pts[f"toe_{side}"][0],
                                     sx, v["body"].get("legs", 1.0), skin, v["seed"]))
    return out


def build_variant(v, offset_x=0.0, pose="neutral"):
    before = set(bpy.data.objects)
    suffix = "_" + v["name"]
    skin = kit.skin_material("M_Bloater_Skin" + suffix, v["tone"], v["bruise"])
    tooth_mat, _ = kit.material("M_Bloater_Teeth" + suffix, bh.TOOTH_COLOR, rough=0.5)
    blister_mat = bp.blister_material("M_Bloater_Blister" + suffix, POSE_GLOW[pose])
    rash_mat = bp.rash_material("M_Bloater_Rash" + suffix)
    style = wh.HAIR_STYLES.get(v["hair_style"])
    hair_mat = wh.hair_material("M_Bloater_Hair" + suffix, v["hair"], style["rough"]) if style else None
    body_obj, segments, pts = build_body(v, skin, pose)
    stretch_marks(body_obj, pts, v["seed"])
    cache = {}
    gut_c, gut_r = gut_sphere(v, pts, pose)

    def part(co):
        key = (round(co.x, 3), round(co.y, 3), round(co.z, 3))
        if key not in cache:
            cache[key] = classify(co, segments)
            if cache[key][0] not in ("neck",) and (co - gut_c).length < gut_r * GUT_CLASS:
                low = pts["pelvis"][0].z + 0.10
                cache[key] = ("hips" if co.z < low else "torso", 0.5)
        return cache[key]
    center = pts["belly"][0].lerp(pts["chest"][0], 0.35)
    spots = bp.blister_spots(body_obj, center, v["seed"], v.get("blisters", 1.0))
    build_extremities(v, pts, skin)
    bc.build_clothes(body_obj, part, pts, spots, v, suffix)
    if v["shoes"]:
        bc.build_shoes(body_obj, pts, part, v, suffix, 1.05)
    bp.build_blisters(spots, blister_mat, rash_mat, suffix)
    pitch, jaw = POSE_HEAD[pose]
    head = bh.build_head(v, skin, tooth_mat, hair_mat if not v.get("cap") else None, blister_mat,
                         pts["neck1"][0], pitch + POSE_LEAN[pose] * 0.5, jaw)
    if v.get("cap"):
        bc.build_cap(head, v["body"]["head"], v["cap"], suffix)
    created = list(set(bpy.data.objects) - before)
    for obj in created:
        obj.name = obj.name.replace("Walker_", "Bloater_").replace("Tank_", "Bloater_")
    root = bpy.data.objects.new(f"Bloater_{v['name']}_{pose}", None)
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
        print("BLOATER", v["name"], pose, "tris:", face_count(root))
        roots.append(root)
    kit.setup_look(target_height=1.3)
    if save:
        os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    return roots


if __name__ not in ("build_bloater",):
    build()
