"""Tank zombi konsepti — Aşama V.5, tamamen Blender (arka plan örneği). v2.

İmza (K5, Taha onaylı): iri yapılı, sırtında kemik plakalar; iki eliyle yere çekiç gibi vurur.
Oyuncuya kararı: hazırlık (0.9 sn) sırasında mesafe açmak. Siluet: dev omuz/sırt kütlesi, kambur,
kamburdan kafanın arkasına yükselen kemik plaka tacı, dev önkol ve yumruklar, kısa kalın bacaklar.
v2 düzeltmeleri (v1 eleştirisi): kendi kafası (tank_head), tanımlı kas grupları ve ince eklemler
(tank_parts), kalın pahlı üst üste binen kemik plakalar + et-kemik geçişi (tank_plates), boyun/trapez
geçişi (kafa ensesi trapeze bağlanır), çıplak ayakta parmaklar, kumaş gibi kıyafet (tank_clothes),
irilik %10 küçük (genişlik yürüyenin ~1.8 katı), imzada iki yumruk başın üstünde kenetli.

Gövde: iskelet noktaları + skin modifier + kas kütleleri, voxel remesh ile kaynar (zombie_kit).
Yumruk ve ayak parmakları ayrı ağ. Pozlar veri: "neutral" ve "signature" (vuruştan hemen önce).

Çalıştırma (arka plan):
    blender --background --python tools/blender/tank_render.py
Yalnız dizi blend'i:  blender --background --python tools/blender/build_tank.py
Çıktı: build/blender/tank.blend. Oyun modeli: tank_game.py.
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
import tank_plates as tpl  # noqa: E402
import tank_head as th  # noqa: E402
import tank_clothes as tc  # noqa: E402

for _m in (kit, wh, tp, tpl, th, tc):
    importlib.reload(_m)
OUT_BLEND = os.path.join(REPO, "build", "blender", "tank.blend")

# Karakter -Y yönüne bakar, Z yukarı, metre. Kambur; boyun öne-yukarı uzanır, kafa omuz hattının önünde.
TORSO_POINTS = {
    "pelvis": ((0.0, 0.06, 1.00), 0.22),
    "belly": ((0.0, -0.05, 1.20), 0.23),
    "spine": ((0.0, 0.06, 1.42), 0.24),
    "chest": ((0.0, -0.04, 1.63), 0.27),
    "upchest": ((0.0, -0.12, 1.79), 0.20),
    "hump": ((0.0, 0.13, 1.89), 0.24),
    "neck0": ((0.0, -0.21, 1.85), 0.15),
    "neck1": ((0.0, -0.30, 1.91), 0.12),
}
# Sol (+X) taraf; sağ aynalanır. Eklemlerde ince yarıçap (kas kütleleri hacmi verir).
SIDE_POSES = {
    "neutral": {
        "hip": ((0.20, 0.06, 0.96), 0.15), "knee": ((0.29, -0.06, 0.54), 0.105),
        "ankle": ((0.30, 0.04, 0.13), 0.075), "heel": ((0.30, 0.11, 0.07), 0.065),
        "ball": ((0.31, -0.10, 0.06), 0.06), "toe": ((0.31, -0.15, 0.05), 0.045),
        "shoulder": ((0.45, -0.05, 1.78), 0.16), "elbow": ((0.56, 0.02, 1.34), 0.105),
        "wrist": ((0.57, -0.18, 0.94), 0.085), "fist": ((0.57, -0.24, 0.82), 0.0),
    },
    # vuruş öncesi: geniş duruş, dizler kırık; yumruklar başın üstünde kenetli, gövde geriye gerilmiş
    "signature": {
        "hip": ((0.20, 0.06, 0.94), 0.15), "knee": ((0.36, -0.16, 0.54), 0.105),
        "ankle": ((0.38, -0.10, 0.13), 0.075), "heel": ((0.38, -0.03, 0.07), 0.065),
        "ball": ((0.39, -0.24, 0.06), 0.06), "toe": ((0.39, -0.29, 0.05), 0.045),
        "shoulder": ((0.46, -0.02, 1.82), 0.16), "elbow": ((0.56, -0.02, 2.22), 0.105),
        "wrist": ((0.22, -0.02, 2.50), 0.085), "fist": ((0.085, -0.02, 2.55), 0.0),
    },
}
POSE_LEAN = {"neutral": 0.0, "signature": -20.0}   # gövde pelvis çevresinde geriye (derece)
POSE_HEAD = {"neutral": (-14.0, 16.0), "signature": (-26.0, 34.0)}  # (kafa eğimi, çene açıklığı)
RIGHT_FOOT_BACK = {"neutral": 0.0, "signature": 0.34}  # imzada sağ ayak geride (m)
HAND_SCALE = 1.25
UPPER = {"shoulder", "elbow", "wrist", "fist"}
LEGS = ("hip", "knee", "ankle", "heel", "ball", "toe", "pelvis")
TORSO_EDGES = [("pelvis", "belly"), ("belly", "spine"), ("spine", "chest"), ("chest", "upchest"),
               ("upchest", "neck0"), ("neck0", "neck1"), ("chest", "hump"), ("hump", "neck1")]
LIMB_CHAIN = [("hip", "knee"), ("knee", "ankle"), ("ankle", "heel"), ("ankle", "ball"),
              ("ball", "toe"), ("shoulder", "elbow"), ("elbow", "wrist")]
PART_CLASS = {
    "pelvis-belly": "hips", "belly-spine": "torso", "spine-chest": "torso", "chest-upchest": "torso",
    "chest-hump": "hump", "hump-neck1": "hump", "upchest-neck0": "neck", "neck0-neck1": "neck",
    "pelvis-hip": "hips", "upchest-shoulder": "clav", "hip-knee": "thigh", "knee-ankle": "shin",
    "ankle-heel": "foot", "ankle-ball": "foot", "ball-toe": "foot", "shoulder-elbow": "uparm",
    "elbow-wrist": "forearm",
}
LINEUP_SPACING = 1.6
VOXEL = 0.010
BRUISE_BAND = (0.50, 0.68)

# Çeşitler. body: s genel ölçek (v1'in 0.9 katı), w genişlik, t kol/kas kalınlığı, legs bacak, belly göbek,
# head kafa ölçeği. top: coverall / shirt / tank / None, sleeve: none / torn / short; bottom: pants ya da None;
# hem: paça (shin 0..1); shoes: renk ya da None (çıplak ayak, parmaklı); belt: renk ya da None. Renkler doğrusal.
VARIANTS = [
    {"name": "Overall", "body": {"s": 0.83, "w": 1.00, "t": 1.00, "legs": 1.0, "belly": 1.0, "head": 1.32},
     "tone": (0.25, 0.27, 0.21), "bruise": (0.10, 0.08, 0.11),
     "top": "coverall", "sleeve": "none", "top_color": (0.10, 0.15, 0.09), "blood": 0.5, "holes": 0.25,
     "bottom": None, "hem": 0.82, "shoes": (0.07, 0.045, 0.025), "belt": None,
     "hair": (0.04, 0.03, 0.02), "hair_style": "fringe", "plates": 1.0, "seed": 1.3},
    {"name": "Guard", "body": {"s": 0.81, "w": 1.04, "t": 1.02, "legs": 1.0, "belly": 1.1, "head": 1.30},
     "tone": (0.23, 0.25, 0.21), "bruise": (0.10, 0.08, 0.13), "bruise_band": (0.52, 0.70),
     "top": "shirt", "sleeve": "short", "top_color": (0.26, 0.33, 0.44), "blood": 0.6, "holes": 0.2,
     "bottom": "pants", "hem": 0.95, "shoes": (0.015, 0.014, 0.013), "belt": (0.02, 0.02, 0.02),
     "hair": (0.03, 0.025, 0.02), "hair_style": "short", "plates": 0.95, "seed": 4.6},
    {"name": "Heavy", "body": {"s": 0.79, "w": 1.12, "t": 0.96, "legs": 1.12, "belly": 1.55, "head": 1.31},
     "tone": (0.29, 0.26, 0.21), "bruise": (0.12, 0.08, 0.09),
     "top": "tank", "sleeve": "none", "top_color": (0.50, 0.47, 0.39), "blood": 0.9, "holes": 0.25,
     "bottom": "pants", "hem": 0.55, "shoes": None, "belt": None,
     "hair": (0.03, 0.03, 0.03), "hair_style": "bald", "plates": 0.9, "seed": 8.2},
    {"name": "Bare", "body": {"s": 0.855, "w": 0.98, "t": 1.08, "legs": 1.0, "belly": 0.9, "head": 1.28},
     "tone": (0.19, 0.21, 0.19), "bruise": (0.08, 0.06, 0.09),
     "top": None, "top_color": None, "blood": 0.0,
     "bottom": "pants", "hem": 0.70, "bottom_color": (0.08, 0.10, 0.14), "shoes": None, "belt": None,
     "hair": (0.02, 0.02, 0.02), "hair_style": "bald", "plates": 1.15, "seed": 12.9},
]
for _v in VARIANTS:
    _v.setdefault("bottom_color", (0.09, 0.08, 0.07) if _v["name"] != "Guard" else (0.03, 0.04, 0.07))


# ---------------------------------------------------------------- gövde

def body_points(body, pose="neutral"):
    """Çeşidin ve pozun gövde noktaları (çeşit ölçeğinden önce, kök 0'da; eğilmeden önce)."""
    w, t = body["w"], body["t"]
    pts = {n: (Vector(p), r * w) for n, (p, r) in TORSO_POINTS.items()}
    pos, r = pts["belly"]
    pts["belly"] = (pos + Vector((0.0, -0.05 * (body["belly"] - 1.0), 0.0)), r * body["belly"] ** 0.6)
    for n, (p, r) in SIDE_POSES[pose].items():
        k = t if n in UPPER else body.get("legs", 1.0)
        for side, sx in (("L", 1.0), ("R", -1.0)):
            x = p[0] * (w if n in UPPER or n == "hip" else 1.0 + (w - 1.0) * 0.6)
            if n == "fist" and pose == "signature":
                x = p[0]                     # kenetli yumruklar ortada buluşur
            back = RIGHT_FOOT_BACK[pose] if side == "R" and n in ("knee", "ankle", "heel", "ball", "toe") else 0.0
            pts[f"{n}_{side}"] = (Vector((x * sx, p[1] + back * (0.6 if n == "knee" else 1.0), p[2])), r * k)
    return pts


def lean_matrix(pts, pose):
    pivot = pts["pelvis"][0]
    rot = Matrix.Rotation(math.radians(POSE_LEAN[pose]), 4, "X")
    return Matrix.Translation(pivot) @ rot @ Matrix.Translation(-pivot)


def apply_lean(pts, blobs, pose):
    """Gövdeyi pelvis çevresinde geriye yatırır (bacaklar sabit)."""
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
    body = v["body"]
    pts = body_points(body, pose)
    blobs = tp.masses(pts, body, body_points(body, "neutral"))
    pts, blobs = apply_lean(pts, blobs, pose)
    edges = list(TORSO_EDGES)
    for side in ("L", "R"):
        edges += [(f"{a}_{side}", f"{b}_{side}") for a, b in LIMB_CHAIN]
        edges += [("pelvis", f"hip_{side}"), ("upchest", f"shoulder_{side}")]
    skin_pts = {n: (tuple(p), r) for n, (p, r) in pts.items() if not n.startswith("fist")}
    obj = kit.skin_object("Tank_Body", skin_pts, edges, mat)
    tp.add_blobs(obj, blobs)
    kit.organic_pass(obj, voxel=VOXEL, lump=0.006)
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
    ramp = next(n for n in mat.node_tree.nodes if n.type == "VALTORGB")
    ramp.color_ramp.elements[0].position, ramp.color_ramp.elements[1].position = \
        v.get("bruise_band", BRUISE_BAND)
    return tpl.raw_skin(mat)


def build_extremities(v, pts, skin):
    """Yumruklar (ayrı ağ) ve çıplak ayakta parmaklar."""
    out = []
    hs = v["body"]["t"] * HAND_SCALE
    for side, sx in (("L", 1.0), ("R", -1.0)):
        out.append(tp.build_fist("Tank_Fist_" + side, pts[f"wrist_{side}"][0], pts[f"fist_{side}"][0],
                                 sx, hs, skin))
        if not v["shoes"]:
            out.append(tp.build_toes("Tank_Toes_" + side, pts[f"ball_{side}"][0], pts[f"toe_{side}"][0],
                                     sx, v["body"].get("legs", 1.0), skin, v["seed"]))
    return out


def build_variant(v, offset_x=0.0, pose="neutral"):
    before = set(bpy.data.objects)
    suffix = "_" + v["name"]
    rng = tp.rng_for(v)
    skin = skin_for(v, "M_Tank_Skin" + suffix)
    tooth_mat, _ = kit.material("M_Tank_Teeth" + suffix, th.TOOTH_COLOR, rough=0.5)
    style = wh.HAIR_STYLES.get(v["hair_style"])
    hair_mat = wh.hair_material("M_Tank_Hair" + suffix, v["hair"], style["rough"]) if style else None
    body_obj, segments, pts = build_body(v, skin, pose)
    cache = {}

    def part(co):
        key = (round(co.x, 3), round(co.y, 3), round(co.z, 3))
        if key not in cache:
            cache[key] = classify(co, segments)
        return cache[key]
    spots = tpl.plate_spots(body_obj, pts, math.radians(POSE_LEAN[pose]))
    tpl.swell_roots(body_obj, spots, v.get("plates", 1.0))
    build_extremities(v, pts, skin)
    tc.build_clothes(body_obj, part, pts, spots, v, suffix)
    if v["shoes"]:
        tc.build_shoes(body_obj, pts, part, v, suffix, 1.6)
    bone = tpl.bone_material("M_Tank_Bone" + suffix)
    for spot in spots:
        tpl.build_plate(spot, bone, rng, v.get("plates", 1.0), body=body_obj)
    pitch, jaw = POSE_HEAD[pose]
    th.build_head(v, skin, tooth_mat, hair_mat, pts["neck1"][0], pitch + POSE_LEAN[pose] * 0.5, jaw)
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
    return sum(sum(len(p.vertices) - 2 for p in o.data.polygons)
               for o in [root] + list(root.children_recursive) if o.type == "MESH")


def build(pose="neutral", save=True):
    kit.reset_scene()
    count = len(VARIANTS)
    roots = []
    for i, v in enumerate(VARIANTS):
        root = build_variant(v, (i - (count - 1) / 2) * LINEUP_SPACING, pose)
        print("TANK", v["name"], pose, "tris:", face_count(root))
        roots.append(root)
    kit.setup_look(target_height=1.4)
    if save:
        os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    return roots


# Modül olarak içe aktarılınca kurulum çalışmaz; doğrudan çalıştırınca çalışır.
if __name__ not in ("build_tank",):
    build()
