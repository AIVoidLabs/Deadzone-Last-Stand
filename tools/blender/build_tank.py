"""Tank zombi konsepti — Aşama V.5, tamamen Blender (arka plan örneği). v1.

İmza (K5, Taha onaylı): iri yapılı, sırtında kemik plakalar; iki eliyle yere çekiç gibi vurur.
Oyuncuya kararı: hazırlık sırasında mesafe açmak. Siluet: devasa omuz/sırt kütlesi, kamburdan
çıkan kemik plaka sırası (yukarıdan V deseni), dev önkol ve yumruklar, kısa kalın bacaklar,
omuzların arasına gömülü küçük kafa. Kambur yürüyenden ~1.15 kat, plakalarla ~1.35 kat\nyüksek; ~2 kat geniş (yukarıdan kapladığı alan ~1.6 kat).

Gövde: iskelet noktaları + skin modifier, üstüne kas kütleleri ve yumruk metaball'ları,
hepsi voxel remesh ile kaynar (zombie_kit). Plakalar ve kafa: tank_parts.py.
Kıyafet: tank_clothes.py. Görseller: tank_render.py. Pozlar veri: "neutral" ve "signature"
(vuruştan hemen önce: eller kenetli başın üstünde, gövde geriye gerilmiş).

Çalıştırma (arka plan):
    blender --background --python tools/blender/tank_render.py
Yalnız dizi blend'i:  blender --background --python tools/blender/build_tank.py
Çıktı: build/blender/tank.blend. Bu adım yalnız konsept: iskelet, animasyon ve GLB yok.
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
import tank_clothes as tc  # noqa: E402

for _m in (kit, wh, tp, tc):
    importlib.reload(_m)
OUT_BLEND = os.path.join(REPO, "build", "blender", "tank.blend")

# Karakter -Y yönüne bakar, Z yukarı, metre. Kambur: kafa omuz hattının altında, önde.
TORSO_POINTS = {
    "pelvis": ((0.0, 0.06, 1.00), 0.23),
    "belly": ((0.0, -0.06, 1.20), 0.25),
    "spine": ((0.0, 0.06, 1.42), 0.26),
    "chest": ((0.0, -0.04, 1.64), 0.30),
    "upchest": ((0.0, -0.13, 1.80), 0.22),
    "hump": ((0.0, 0.15, 1.95), 0.29),
    "neck0": ((0.0, -0.26, 1.76), 0.15),
    "neck1": ((0.0, -0.35, 1.76), 0.12),
}
# Sol (+X) taraf; sağ aynalanır. Kısa kalın bacak, uzun ağır kol (yumruk diz hizasında).
SIDE_POSES = {
    "neutral": {
        "hip": ((0.21, 0.06, 0.96), 0.17), "knee": ((0.31, -0.06, 0.54), 0.14),
        "ankle": ((0.32, 0.04, 0.13), 0.10), "heel": ((0.32, 0.11, 0.075), 0.075),
        "ball": ((0.33, -0.12, 0.065), 0.07), "toe": ((0.33, -0.22, 0.05), 0.05),
        "shoulder": ((0.45, -0.05, 1.80), 0.19), "elbow": ((0.56, 0.02, 1.36), 0.145),
        "wrist": ((0.57, -0.20, 0.93), 0.13), "fist": ((0.57, -0.26, 0.78), 0.12),
    },
    # vuruş öncesi: geniş duruş, dizler kırık; kollar başın üstünde, yumruklar kenetli
    "signature": {
        "hip": ((0.21, 0.06, 0.94), 0.17), "knee": ((0.38, -0.16, 0.54), 0.14),
        "ankle": ((0.40, -0.10, 0.13), 0.10), "heel": ((0.40, -0.03, 0.075), 0.075),
        "ball": ((0.42, -0.26, 0.065), 0.07), "toe": ((0.43, -0.36, 0.05), 0.05),
        "shoulder": ((0.46, -0.02, 1.84), 0.19), "elbow": ((0.60, -0.02, 2.28), 0.13),
        "wrist": ((0.22, -0.04, 2.60), 0.12), "fist": ((0.09, -0.04, 2.66), 0.12),
    },
}
POSE_LEAN = {"neutral": 0.0, "signature": -16.0}   # gövde pelvis çevresinde geriye (derece)
POSE_HEAD = {"neutral": (-4.0, 26.0), "signature": (-30.0, 42.0)}  # (kafa eğimi, çene açıklığı)
LEFT_FOOT_BACK = {"neutral": 0.0, "signature": 0.34}  # imzada sağ ayak geride (m)
UPPER = {"shoulder", "elbow", "wrist", "fist"}
TORSO_EDGES = [("pelvis", "belly"), ("belly", "spine"), ("spine", "chest"), ("chest", "upchest"),
               ("upchest", "neck0"), ("neck0", "neck1"), ("chest", "hump")]
LIMB_CHAIN = [("hip", "knee"), ("knee", "ankle"), ("ankle", "heel"), ("ankle", "ball"),
              ("ball", "toe"), ("shoulder", "elbow"), ("elbow", "wrist"), ("wrist", "fist")]
PART_CLASS = {
    "pelvis-belly": "hips", "belly-spine": "torso", "spine-chest": "torso", "chest-upchest": "torso",
    "chest-hump": "hump", "upchest-neck0": "neck", "neck0-neck1": "neck", "pelvis-hip": "hips",
    "upchest-shoulder": "clav", "hip-knee": "thigh", "knee-ankle": "shin", "ankle-heel": "foot",
    "ankle-ball": "foot", "ball-toe": "foot", "shoulder-elbow": "uparm", "elbow-wrist": "forearm",
    "wrist-fist": "hand",
}
LINEUP_SPACING = 1.75
VOXEL = 0.011
BRUISE_BAND = (0.50, 0.68)   # ten alacası: morluk yalnız lekelerde (pembe genel ton yok)

# Çeşitler. body: s genel ölçek, w genişlik, t kol/kas kalınlığı, legs bacak kalınlığı,
# belly göbek, head kafa ölçeği (küçük = gömülü). top: coverall / shirt / tank / None,
# sleeve: none / torn / short; bottom: pants ya da None (coverall'da üst zaten iner); hem: paça (shin 0..1);
# shoes: renk ya da None (çıplak ayak); belt: renk ya da None; plates: plaka ölçeği. Renkler doğrusal.
VARIANTS = [
    {"name": "Overall", "body": {"s": 0.92, "w": 1.00, "t": 1.00, "legs": 1.0, "belly": 1.0, "head": 1.18},
     "tone": (0.27, 0.29, 0.23), "bruise": (0.10, 0.08, 0.11),
     "top": "coverall", "sleeve": "none", "top_color": (0.10, 0.16, 0.10), "blood": 0.5, "holes": 0.35,
     "bottom": None, "hem": 0.80, "shoes": (0.07, 0.045, 0.025), "belt": None,
     "hair": (0.04, 0.03, 0.02), "hair_style": "fringe", "plates": 1.0, "seed": 1.3},
    {"name": "Guard", "body": {"s": 0.90, "w": 1.04, "t": 1.02, "legs": 1.0, "belly": 1.1, "head": 1.15},
     "tone": (0.24, 0.26, 0.22), "bruise": (0.10, 0.08, 0.13), "bruise_band": (0.52, 0.70),
     "top": "shirt", "sleeve": "short", "top_color": (0.30, 0.38, 0.50), "blood": 0.6, "holes": 0.25,
     "bottom": "pants", "hem": 0.95, "shoes": (0.015, 0.014, 0.013), "belt": (0.02, 0.02, 0.02),
     "hair": (0.03, 0.025, 0.02), "hair_style": "short", "plates": 0.95, "seed": 4.6},
    {"name": "Heavy", "body": {"s": 0.88, "w": 1.12, "t": 0.96, "legs": 1.12, "belly": 1.55, "head": 1.17},
     "tone": (0.30, 0.27, 0.22), "bruise": (0.12, 0.08, 0.09),
     "top": "tank", "sleeve": "none", "top_color": (0.55, 0.52, 0.44), "blood": 0.9, "holes": 0.3,
     "bottom": "pants", "hem": 0.55, "shoes": None, "belt": None,
     "hair": (0.03, 0.03, 0.03), "hair_style": "bald", "plates": 0.9, "seed": 8.2},
    {"name": "Bare", "body": {"s": 0.95, "w": 0.98, "t": 1.08, "legs": 1.0, "belly": 0.9, "head": 1.14},
     "tone": (0.19, 0.21, 0.19), "bruise": (0.08, 0.06, 0.09),
     "top": None, "top_color": None, "blood": 0.0,
     "bottom": "pants", "hem": 0.70, "bottom_color": (0.08, 0.10, 0.14), "shoes": None, "belt": None,
     "hair": (0.02, 0.02, 0.02), "hair_style": "bald", "plates": 1.2, "seed": 12.9},
]
for _v in VARIANTS:
    _v.setdefault("bottom_color", (0.09, 0.08, 0.07) if _v["name"] != "Guard" else (0.03, 0.04, 0.07))


# ---------------------------------------------------------------- gövde

def body_points(body, pose="neutral"):
    """Çeşidin ve pozun gövde noktaları (çeşit ölçeğinden önce, kök 0'da)."""
    w, t = body["w"], body["t"]
    pts = {}
    for n, (p, r) in TORSO_POINTS.items():
        pts[n] = (Vector((p[0], p[1], p[2])), r * w)
    pos, r = pts["belly"]
    pts["belly"] = (pos + Vector((0.0, -0.05 * (body["belly"] - 1.0), 0.0)), r * body["belly"] ** 0.6)
    for n, (p, r) in SIDE_POSES[pose].items():
        k = t if n in UPPER else body.get("legs", 1.0)
        for side, sx in (("L", 1.0), ("R", -1.0)):
            x = p[0] * (w if n in UPPER or n == "hip" else 1.0 + (w - 1.0) * 0.6)
            back = LEFT_FOOT_BACK[pose] if side == "R" and n in ("knee", "ankle", "heel", "ball", "toe") else 0.0
            pts[f"{n}_{side}"] = (Vector((x * sx, p[1] + back * (0.6 if n == "knee" else 1.0), p[2])), r * k)
    return pts


def lean_matrix(pts, pose):
    """Gövdeyi pelvis çevresinde geriye yatıran dönüşüm (bacaklar sabit)."""
    pivot = pts["pelvis"][0]
    rot = Matrix.Rotation(math.radians(POSE_LEAN[pose]), 4, "X")
    return Matrix.Translation(pivot) @ rot @ Matrix.Translation(-pivot)


def apply_lean(pts, blobs, pose):
    if not POSE_LEAN[pose]:
        return pts, blobs
    m = lean_matrix(pts, pose)
    q = m.to_quaternion()
    legs = ("hip", "knee", "ankle", "heel", "ball", "toe", "pelvis")
    out = {n: ((m @ p) if n.split("_")[0] not in legs else p, r) for n, (p, r) in pts.items()}
    pelvis_z = pts["pelvis"][0].z
    new_blobs = []
    for c, radii, rot, neg in blobs:
        upper = c[2] > pelvis_z + 0.05
        new_blobs.append((tuple(m @ Vector(c)) if upper else c, radii, (q @ rot) if upper else rot, neg))
    return out, new_blobs


def build_body(v, mat, pose):
    body = v["body"]
    pts = body_points(body, pose)
    blobs = tp.masses(pts, body)
    for side in ("L", "R"):
        blobs += tp.fist_blobs(pts, side, body["t"])
        if not v["shoes"]:
            blobs += tp.toe_blobs(pts, side)
    pts, blobs = apply_lean(pts, blobs, pose)
    edges = list(TORSO_EDGES)
    for side in ("L", "R"):
        edges += [(f"{a}_{side}", f"{b}_{side}") for a, b in LIMB_CHAIN]
        edges += [("pelvis", f"hip_{side}"), ("upchest", f"shoulder_{side}")]
    obj = kit.skin_object("Tank_Body", {n: (tuple(p), r) for n, (p, r) in pts.items()}, edges, mat)
    tp.add_blobs(obj, blobs)
    kit.organic_pass(obj, voxel=VOXEL, lump=0.008)
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


# ---------------------------------------------------------------- çeşit

def skin_for(v, name):
    mat = kit.skin_material(name, v["tone"], v["bruise"])
    ramp = next(n for n in mat.node_tree.nodes if n.type == "VALTORGB")  # morluk yalnız lekelerde
    ramp.color_ramp.elements[0].position, ramp.color_ramp.elements[1].position = \
        v.get("bruise_band", BRUISE_BAND)
    return mat


def build_variant(v, offset_x=0.0, pose="neutral"):
    before = set(bpy.data.objects)
    suffix = "_" + v["name"]
    rng = tp.rng_for(v)
    skin = skin_for(v, "M_Tank_Skin" + suffix)
    tooth_mat, _ = kit.material("M_Tank_Teeth" + suffix, (0.42, 0.37, 0.26), rough=0.4)
    style = wh.HAIR_STYLES.get(v["hair_style"])
    hair_mat = wh.hair_material("M_Tank_Hair" + suffix, v["hair"], style["rough"]) if style else None
    body_obj, segments, pts = build_body(v, skin, pose)
    cache = {}

    def part(co):
        key = (round(co.x, 4), round(co.y, 4), round(co.z, 4))
        if key not in cache:
            cache[key] = classify(co, segments)
        return cache[key]
    spots = tp.plate_spots(body_obj, pts, math.radians(POSE_LEAN[pose]))
    tc.build_clothes(body_obj, part, pts, spots, v, suffix)
    if v["shoes"]:
        tc.build_shoes(body_obj, pts, part, v, suffix, 1.75)
    bone = tp.bone_material("M_Tank_Bone" + suffix)
    wound = tp.wound_material("M_Tank_Wound" + suffix)
    for spot in spots:
        tp.build_plate(spot, bone, wound, rng, v.get("plates", 1.0))
    pitch, jaw = POSE_HEAD[pose]
    neck = pts["neck1"][0]
    tp.build_head(v, skin, tooth_mat, hair_mat, neck, pitch + POSE_LEAN[pose] * 0.5, jaw)
    created = list(set(bpy.data.objects) - before)
    for obj in created:
        obj.name = obj.name.replace("Walker_", "Tank_")
    root = bpy.data.objects.new(f"Tank_{v['name']}_{pose}", None)
    bpy.context.collection.objects.link(root)
    for obj in created:
        if obj.parent is None:
            obj.parent = root
    root.scale = (v["body"]["s"],) * 3
    root.location.x = offset_x
    return root


def face_count(root):
    total = 0
    for obj in [root] + list(root.children_recursive):
        if obj.type == "MESH":
            total += sum(len(p.vertices) - 2 for p in obj.data.polygons)
    return total


def build(pose="neutral", save=True):
    kit.reset_scene()
    count = len(VARIANTS)
    roots = []
    for i, v in enumerate(VARIANTS):
        root = build_variant(v, (i - (count - 1) / 2) * LINEUP_SPACING, pose)
        print("TANK", v["name"], pose, "tris:", face_count(root))
        roots.append(root)
    kit.setup_look(target_height=1.5)
    if save:
        os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    return roots


# Modül olarak içe aktarılınca kurulum çalışmaz; doğrudan çalıştırınca çalışır.
if __name__ not in ("build_tank",):
    build()
