"""Tükürücü (spitter, "Asitli") zombi — 7.3, tamamen Blender (arka plan örneği).

İmza (s73_design): durur, geriye kasılır, gırtlak şişer (parlar), öne bir hamlede asit topu tükürür.
Oyuncuya kararı: asit alanından uzak dur, güvenli koridor bul.
Siluet: kambur (omurga kamburu öne eğik, kafa öne-aşağıda), sarkık şiş karın, gırtlakta sarkan dev guatr
kesesi; kese, karın ve kambur sırtında yeşil parlayan kabarcıklar (oyun kamerasından yeşil nokta kümeleri),
ağız ve göğüs yeşil asit lekeli. Dilciden farkı: dilci ince-uzun, dilli, sarı gırtlak; tükürücü kambur,
karınlı, yeşil parlayan.
v2 ortak düzeltmeleri baştan: kendi kafası (spitter_head), tanımlı kas grupları + ince eklemler
(spitter_parts, tank kas listesi küçültülmüş), çıplak ayakta parmaklar, kumaş gibi kıyafet (spitter_clothes).

Gövde: iskelet noktaları + skin modifier + kas/yağ kütleleri, voxel remesh ile kaynar (zombie_kit).
Pozlar veri: "neutral" ve "signature" (bırakıştan hemen önce: geriye kasılmış, gırtlak en şiş, ağız açık).

Çalıştırma (arka plan):
    blender --background --python tools/blender/spitter_render.py      (konsept görselleri)
    blender --background --python tools/blender/spitter_game.py        (GLB + klipler)
Yalnız dizi blend'i:  blender --background --python tools/blender/build_spitter.py
Çıktı: build/blender/spitter.blend
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
import spitter_parts as sp  # noqa: E402
import spitter_head as sh  # noqa: E402
import spitter_clothes as sc  # noqa: E402
import spitter_paint as spaint  # noqa: E402

for _m in (kit, wh, sp, sh, sc, spaint):
    importlib.reload(_m)
OUT_BLEND = os.path.join(REPO, "build", "blender", "spitter.blend")

# Karakter -Y yönüne bakar, Z yukarı, metre. Kambur nötr duruşa gömülü: omurga üstü öne eğik, boyun öne.
TORSO_POINTS = {
    "pelvis": ((0.0, 0.02, 0.90), 0.13),
    "belly": ((0.0, -0.02, 1.03), 0.14),
    "spine": ((0.0, 0.01, 1.15), 0.135),
    "chest": ((0.0, -0.03, 1.28), 0.135),
    "upchest": ((0.0, -0.10, 1.38), 0.11),
    "neck0": ((0.0, -0.18, 1.43), 0.070),
    "neck1": ((0.0, -0.235, 1.46), 0.060),
}
# Sol (+X) taraf; sağ aynalanır. Uzun, öne sarkan kollar; dizler hafif kırık.
SIDE_POSES = {
    "neutral": {
        "hip": ((0.11, 0.02, 0.88), 0.065), "knee": ((0.135, -0.06, 0.49), 0.042),
        "ankle": ((0.125, 0.02, 0.09), 0.040), "heel": ((0.125, 0.07, 0.045), 0.036),
        "ball": ((0.13, -0.09, 0.04), 0.034), "toe": ((0.13, -0.13, 0.035), 0.026),
        "shoulder": ((0.20, -0.06, 1.35), 0.042), "elbow": ((0.26, -0.11, 1.08), 0.030),
        "wrist": ((0.255, -0.21, 0.87), 0.026), "fist": ((0.25, -0.24, 0.78), 0.0),
    },
    # bırakıştan önce: geriye kasılmış, dizler kırık, kollar geride-dışta, göğüs açık
    "signature": {
        "hip": ((0.11, 0.02, 0.86), 0.065), "knee": ((0.16, -0.12, 0.49), 0.042),
        "ankle": ((0.15, -0.06, 0.09), 0.040), "heel": ((0.15, -0.01, 0.045), 0.036),
        "ball": ((0.155, -0.17, 0.04), 0.034), "toe": ((0.155, -0.21, 0.035), 0.026),
        "shoulder": ((0.21, -0.02, 1.36), 0.042), "elbow": ((0.33, 0.10, 1.16), 0.030),
        "wrist": ((0.38, 0.16, 0.94), 0.026), "fist": ((0.39, 0.18, 0.85), 0.0),
    },
}
POSE_LEAN = {"neutral": 0.0, "signature": -11.0}
POSE_HEAD = {"neutral": (-6.0, 14.0), "signature": (-34.0, 30.0)}   # (eğim, çene)
POSE_THROAT = {"neutral": 1.0, "signature": 1.32}
POSE_GLOW = {"neutral": 1.0, "signature": 2.4}
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
LINEUP_SPACING = 1.3
VOXEL = 0.009

# Çeşitler. body: s genel ölçek, w genişlik, t kol kalınlığı, legs bacak, belly karın, throat kese, head kafa.
# top: coverall / shirt / None; bottom: pants ya da None; hem: >1 baldıra iner (1 + baldır oranı);
# shoes: renk ya da None (çıplak, parmaklı). Renkler doğrusal.
VARIANTS = [
    {"name": "Worker", "body": {"s": 1.05, "w": 1.0, "t": 1.0, "legs": 1.0, "belly": 1.0, "throat": 1.0, "head": 1.10},
     "tone": (0.19, 0.20, 0.14), "bruise": (0.11, 0.10, 0.07),
     "top": "coverall", "top_color": (0.10, 0.17, 0.19), "blood": 0.3, "holes": 0.2,
     "bottom": None, "hem": 1.80, "bottom_color": (0.10, 0.17, 0.19),
     "shoes": (0.07, 0.05, 0.03), "belt": None,
     "hair": (0.04, 0.03, 0.02), "hair_style": "bald", "bubbles": 1.0, "seed": 3.3},
    {"name": "Suit", "body": {"s": 1.05, "w": 0.96, "t": 0.95, "legs": 1.0, "belly": 1.06, "throat": 1.05, "head": 1.10},
     "tone": (0.21, 0.21, 0.16), "bruise": (0.13, 0.10, 0.08),
     "top": "shirt", "top_color": (0.50, 0.50, 0.44), "blood": 0.45, "holes": 0.15,
     "bottom": "pants", "hem": 1.95, "bottom_color": (0.035, 0.035, 0.045),
     "shoes": (0.03, 0.025, 0.02), "belt": (0.02, 0.015, 0.01),
     "hair": (0.10, 0.08, 0.06), "hair_style": "short", "bubbles": 1.0, "seed": 6.1},
    {"name": "Bare", "body": {"s": 1.03, "w": 1.02, "t": 1.0, "legs": 1.0, "belly": 1.10, "throat": 1.10, "head": 1.10},
     "tone": (0.17, 0.19, 0.14), "bruise": (0.10, 0.09, 0.07),
     "top": None, "top_color": None, "blood": 0.0, "holes": 0.0,
     "bottom": "pants", "hem": 1.62, "bottom_color": (0.08, 0.10, 0.14),
     "shoes": None, "belt": None,
     "hair": (0.02, 0.02, 0.02), "hair_style": "bald", "bubbles": 1.3, "seed": 8.8},
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


def throat_sac(v, pts, pose="neutral"):
    """Gırtlak kesesinin merkezi ve yarıçapları (kas kütlesi, sınıf, kabarcık, ağırlık için)."""
    k = v["body"]["throat"] * POSE_THROAT[pose]
    c = pts["neck0"][0] + Vector((0.0, -0.065, -0.115)) + Vector((0.0, -0.02, -0.03)) * (k - 1.0)
    return c, Vector((0.110, 0.095, 0.100)) * k


def build_body(v, mat, pose):
    body = dict(v["body"])
    pts = body_points(body, pose)
    sac = throat_sac(v, pts, pose)
    blobs = sp.masses(pts, body, body_points(body, "neutral"), sac)
    pts, blobs = apply_lean(pts, blobs, pose)
    edges = list(TORSO_EDGES)
    for side in ("L", "R"):
        edges += [(f"{a}_{side}", f"{b}_{side}") for a, b in LIMB_CHAIN]
        edges += [("pelvis", f"hip_{side}"), ("upchest", f"shoulder_{side}")]
    skin_pts = {n: (tuple(p), r) for n, (p, r) in pts.items() if not n.startswith("fist")}
    obj = kit.skin_object("Spitter_Body", skin_pts, edges, mat)
    sp.add_blobs(obj, blobs)
    kit.organic_pass(obj, voxel=VOXEL, lump=0.004)
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


def in_ellipsoid(co, center, radii, k=1.0):
    d = co - center
    return (d.x / radii.x) ** 2 + (d.y / radii.y) ** 2 + (d.z / radii.z) ** 2 < k * k


def gut_ellipsoid(v, pts):
    """Sarkık karnın kabaca elipsoidi (kıyafet sınıfı: önünden sarkan kollar karnı sahiplenmesin)."""
    g, w = v["body"]["belly"], v["body"]["w"]
    return pts["belly"][0] + Vector((0.0, -0.10, -0.09)), Vector((0.20 * g * w, 0.19 * g, 0.22 * g))


def posed_sac(v, pts_raw, pts, pose):
    """Eğilmiş pozda kesenin merkezi (lean matrisi uygulanmış)."""
    c, r = throat_sac(v, pts_raw, pose)
    if POSE_LEAN[pose]:
        c = lean_matrix(pts_raw, pose) @ c
    return c, r


# ---------------------------------------------------------------- çeşit

def build_extremities(v, pts, skin):
    out = []
    for side, sx in (("L", 1.0), ("R", -1.0)):
        out.append(sp.build_hand("Spitter_Hand_" + side, pts[f"wrist_{side}"][0], pts[f"fist_{side}"][0],
                                 sx, v["body"]["t"] * 1.15, skin))
        if not v["shoes"]:
            out.append(sp.build_toes("Spitter_Toes_" + side, pts[f"ball_{side}"][0], pts[f"toe_{side}"][0],
                                     sx, v["body"].get("legs", 1.0), skin, v["seed"]))
    return out


def build_variant(v, offset_x=0.0, pose="neutral"):
    before = set(bpy.data.objects)
    suffix = "_" + v["name"]
    skin = spaint.acid_skin_material("M_Spitter_Skin" + suffix, v["tone"], v["bruise"])
    tooth_mat, _ = kit.material("M_Spitter_Teeth" + suffix, sh.TOOTH_COLOR, rough=0.5)
    bubble_mat = sp.bubble_material("M_Spitter_Bubble" + suffix, POSE_GLOW[pose])
    style = wh.HAIR_STYLES.get(v["hair_style"])
    hair_mat = wh.hair_material("M_Spitter_Hair" + suffix, v["hair"], style["rough"]) if style else None
    body_obj, segments, pts = build_body(v, skin, pose)
    sac_c, sac_r = posed_sac(v, body_points(v["body"], pose), pts, pose)
    gut_c, gut_r = gut_ellipsoid(v, pts)
    cache = {}

    def part(co):
        key = (round(co.x, 3), round(co.y, 3), round(co.z, 3))
        if key not in cache:
            if in_ellipsoid(co, sac_c, sac_r, 1.18):
                cache[key] = ("sac", 0.5)
            elif in_ellipsoid(co, gut_c, gut_r, 1.15):
                cache[key] = ("hips" if co.z < pts["pelvis"][0].z + 0.08 else "torso", 0.5)
            else:
                cache[key] = classify(co, segments)
        return cache[key]
    spots = sp.bubble_spots(body_obj, pts, (sac_c, sac_r), v["seed"], v.get("bubbles", 1.0))
    build_extremities(v, pts, skin)
    sc.build_clothes(body_obj, part, pts, spots, v, suffix)
    if v["shoes"]:
        sc.build_shoes(body_obj, pts, part, v, suffix, 1.0)
    sp.build_bubbles(spots, bubble_mat, suffix)
    pitch, jaw = POSE_HEAD[pose]
    head = sh.build_head(v, skin, tooth_mat, hair_mat, pts["neck1"][0], pitch + POSE_LEAN[pose] * 0.5, jaw)
    bpy.context.view_layer.update()
    mouth = head.matrix_world @ (sh.MOUTH_TIP * v["body"]["head"])
    acid = spaint.acid_field(mouth, pts, (sac_c, sac_r), v["seed"])
    for obj in [body_obj, head] + [c for c in head.children_recursive if c.name.startswith("Spitter_Jaw")]:
        spaint.mask_attrs(obj, acid, (sac_c, sac_r))
    created = list(set(bpy.data.objects) - before)
    for obj in created:
        obj.name = obj.name.replace("Walker_", "Spitter_").replace("Tank_", "Spitter_")
    root = bpy.data.objects.new(f"Spitter_{v['name']}_{pose}", None)
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
        print("SPITTER", v["name"], pose, "tris:", face_count(root))
        roots.append(root)
    kit.setup_look(target_height=1.2)
    if save:
        os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    return roots


if __name__ not in ("build_spitter",):
    build()
