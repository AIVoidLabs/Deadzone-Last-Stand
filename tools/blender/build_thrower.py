"""Taş fırlatan zombi ("Ağır Kol", `thrower`) konsepti — 7.3, tamamen Blender (arka plan örneği).

İmza: SAĞ KOL AŞIRI BÜYÜMÜŞ (deltoid/önkol kütlesi, dev yarı açık el, parmak boğumları); sol kol sıska ve kısa.
Dev kol yere yakın sarkar, gövdeyi sağa yatırır (sağ omuz düşük, göğüs sağa kayık). Dev elle yerden kaya
kavrar, geriye gerilir, omuz üstünden fırlatır. Oyuncuya kararı: atışı gör, düşeceği yerden yana çekil.
Siluet (yukarıdan): tek yanı dev, öbür yanı çöp kol; yürüyenle karışmaz.
v2 ortak düzeltmeleri baştan: kendi kafası (thrower_head), tanımlı kas grupları + ince eklemler
(thrower_parts), çıplak ayakta parmaklar, kumaş gibi kıyafet (thrower_clothes), parmak boğumlu el.

Gövde: iskelet noktaları + skin modifier + kas kütleleri, voxel remesh ile kaynar (zombie_kit).
El ve ayak parmakları ayrı ağ. Pozlar: "neutral" ve "signature" (bırakıştan hemen önce, kaya elde).

Çalıştırma (arka plan):
    blender --background --python tools/blender/thrower_render.py      (konsept görselleri)
Yalnız dizi blend'i:  blender --background --python tools/blender/build_thrower.py
Çıktı: build/blender/thrower.blend. Oyun modeli: thrower_game.py.
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
import thrower_parts as thp  # noqa: E402
import thrower_head as thh  # noqa: E402
import thrower_clothes as thc  # noqa: E402
import thrower_rock as rock  # noqa: E402

for _m in (kit, wh, tp, thp, thh, thc, rock):
    importlib.reload(_m)
OUT_BLEND = os.path.join(REPO, "build", "blender", "thrower.blend")

# Karakter -Y'ye bakar, Z yukarı, metre. Gövde sağa (-X) yatık: göğüs/boyun sağa kayık, sağ omuz düşük.
TORSO_POINTS = {
    "pelvis": ((0.0, 0.04, 0.98), 0.165),
    "belly": ((0.0, -0.02, 1.14), 0.170),
    "spine": ((-0.010, 0.03, 1.31), 0.180),
    "chest": ((-0.030, -0.02, 1.47), 0.195),
    "upchest": ((-0.040, -0.07, 1.58), 0.150),
    "neck0": ((-0.030, -0.14, 1.62), 0.085),
    "neck1": ((-0.020, -0.20, 1.67), 0.075),
}
# Kollar yana özel (asimetri): (nokta, yarıçap). "tip": el yönü (bilekten parmaklara).
ARM_POINTS = {
    "R": {"shoulder": ((-0.27, -0.02, 1.52), 0.085), "elbow": ((-0.40, 0.04, 1.08), 0.060),
          "wrist": ((-0.41, -0.07, 0.63), 0.055), "tip": ((-0.41, -0.10, 0.53), 0.0)},
    "L": {"shoulder": ((0.20, -0.01, 1.58), 0.060), "elbow": ((0.25, 0.05, 1.33), 0.040),
          "wrist": ((0.25, -0.06, 1.12), 0.032), "tip": ((0.25, -0.09, 1.04), 0.0)},
}
# Bacaklar: sol (+X), sağ aynalanır
LEG_POINTS = {
    "hip": ((0.115, 0.04, 0.95), 0.10), "knee": ((0.150, -0.04, 0.52), 0.068),
    "ankle": ((0.160, 0.03, 0.10), 0.050), "heel": ((0.160, 0.08, 0.05), 0.042),
    "ball": ((0.165, -0.10, 0.045), 0.042), "toe": ((0.165, -0.155, 0.035), 0.032),
}
HAND_SCALE = {"R": 1.35, "L": 0.55}
HAND_CURL = {"R": 0.55, "L": 0.95}
ARMS = ("shoulder", "elbow", "wrist", "tip")
LEGS = tuple(LEG_POINTS)
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
# İmza pozu (bırakıştan hemen önce): gövde sağa dönmüş + geriye yatmış, dev kol omuz üstünde geride
# (kaya elde), sıska kol hedefi gösterir, sol ayak önde.
SIG_TORSO = (-10.0, -5.0, -28.0)          # (X geriye yatma, Y yana, Z dönme) derece, pelvis çevresinde
SIG_DROP = 0.05
SIG_ARMS = {"R": ((-0.45, 0.55, 0.40), (0.25, 0.30, 0.92)), "L": ((0.30, -0.75, -0.35), (0.05, -0.95, 0.15))}
SIG_LEGS = {"L": {"knee": (0.17, -0.20, 0.50), "ankle": (0.18, -0.22, 0.10), "heel": (0.18, -0.17, 0.05),
                  "ball": (0.185, -0.35, 0.045), "toe": (0.185, -0.405, 0.035)},
            "R": {"knee": (-0.16, 0.12, 0.50), "ankle": (-0.17, 0.30, 0.12), "heel": (-0.17, 0.36, 0.08),
                  "ball": (-0.17, 0.19, 0.04), "toe": (-0.17, 0.14, 0.03)}}
POSE_HEAD = {"neutral": (-6.0, 14.0, -8.0, 0.0), "signature": (-14.0, 30.0, 0.0, 24.0)}  # eğim, çene, yatış, dönüş
LINEUP_SPACING = 1.5
VOXEL = 0.010

# Çeşitler. body: s ölçek, w gövde genişliği, legs bacak kası, belly göbek, head kafa ölçeği,
# arm sağ kol ek çarpanı, thin sol kol. top: tee/flannel/None, sleeve sol kol yeni (uparm 0..1, >1 önkola),
# vest: renk ya da None, hem paça (shin 0..1), shoes renk ya da None (yalın ayak), belt, hat (baret).
VARIANTS = [
    {"name": "Vest", "body": {"s": 0.965, "w": 1.0, "legs": 1.0, "belly": 1.15, "head": 1.05, "arm": 1.0, "thin": 1.0},
     "tone": (0.24, 0.25, 0.20), "bruise": (0.10, 0.07, 0.10),
     "top": "tee", "sleeve": 0.55, "top_color": (0.05, 0.07, 0.11), "blood": 0.4, "holes": 0.15,
     "vest": (0.80, 0.20, 0.012), "bottom_color": (0.20, 0.15, 0.08), "hem": 0.95,
     "shoes": (0.10, 0.06, 0.03), "belt": None, "hair": (0.04, 0.03, 0.02), "hair_style": "fringe",
     "hat": True, "seed": 2.1},
    {"name": "Flannel", "body": {"s": 0.955, "w": 0.96, "legs": 0.96, "belly": 0.95, "head": 1.04, "arm": 1.04, "thin": 0.95},
     "tone": (0.27, 0.26, 0.21), "bruise": (0.12, 0.07, 0.09),
     "top": "flannel", "sleeve": 1.85, "top_color": (0.30, 0.025, 0.02), "blood": 0.5, "holes": 0.18,
     "vest": None, "bottom_color": (0.06, 0.09, 0.16), "hem": 0.92,
     "shoes": (0.03, 0.025, 0.02), "belt": (0.04, 0.025, 0.015), "hair": (0.05, 0.035, 0.02),
     "hair_style": "short", "hat": False, "seed": 5.7},
    {"name": "Bare", "body": {"s": 0.975, "w": 1.0, "legs": 1.02, "belly": 0.85, "head": 1.03, "arm": 1.08, "thin": 0.9},
     "tone": (0.21, 0.23, 0.20), "bruise": (0.09, 0.06, 0.09),
     "top": None, "sleeve": 0.0, "top_color": None, "blood": 0.0, "vest": None,
     "bottom_color": (0.07, 0.07, 0.06), "hem": 0.62, "shoes": None, "belt": (0.03, 0.02, 0.012),
     "hair": (0.02, 0.02, 0.02), "hair_style": "bald", "hat": False, "seed": 9.3},
]


# ---------------------------------------------------------------- noktalar

def _limb(start, dirs, lengths):
    a = Vector(start)
    b = a + Vector(dirs[0]).normalized() * lengths[0]
    c = b + Vector(dirs[1]).normalized() * lengths[1]
    return b, c, c + Vector(dirs[1]).normalized() * lengths[2]


def body_points(body, pose="neutral"):
    """Çeşidin ve pozun gövde noktaları {ad: (Vector, yarıçap)} (çeşit ölçeğinden önce, kök 0'da)."""
    w = body["w"]
    pts = {n: (Vector(p), r * w) for n, (p, r) in TORSO_POINTS.items()}
    pos, r = pts["belly"]
    pts["belly"] = (pos + Vector((0.0, -0.04 * (body["belly"] - 1.0), 0.0)), r * body["belly"] ** 0.5)
    for side, arm in ARM_POINTS.items():
        k = body.get("arm", 1.0) if side == "R" else body.get("thin", 1.0)
        for n, (p, r) in arm.items():
            pts[f"{n}_{side}"] = (Vector(p), r * k)
    for n, (p, r) in LEG_POINTS.items():
        for side, sx in (("L", 1.0), ("R", -1.0)):
            pts[f"{n}_{side}"] = (Vector((p[0] * sx, p[1], p[2])), r * body.get("legs", 1.0))
    if pose == "signature":
        _signature(pts)
    return pts


def _signature(pts):
    pivot = pts["pelvis"][0].copy()
    rx, ry, rz = (math.radians(a) for a in SIG_TORSO)
    rot = Matrix.Rotation(rz, 4, "Z") @ Matrix.Rotation(ry, 4, "Y") @ Matrix.Rotation(rx, 4, "X")
    m = Matrix.Translation(pivot - Vector((0, 0, SIG_DROP))) @ rot @ Matrix.Translation(-pivot)
    for n, (p, r) in list(pts.items()):
        base = n.split("_")[0]
        if base in LEGS and base != "hip":
            continue
        if base == "hip":
            pts[n] = (p - Vector((0.0, 0.0, SIG_DROP)), r)
        else:
            pts[n] = (m @ p, r)
    for side, (d_up, d_fore) in SIG_ARMS.items():
        a = ARM_POINTS[side]
        lens = ((Vector(a["elbow"][0]) - Vector(a["shoulder"][0])).length,
                (Vector(a["wrist"][0]) - Vector(a["elbow"][0])).length,
                (Vector(a["tip"][0]) - Vector(a["wrist"][0])).length)
        el, wr, tip = _limb(pts["shoulder_" + side][0], (d_up, d_fore), lens)
        for n, p in (("elbow", el), ("wrist", wr), ("tip", tip)):
            pts[f"{n}_{side}"] = (p, pts[f"{n}_{side}"][1])
    for side, legs in SIG_LEGS.items():
        for n, p in legs.items():
            pts[f"{n}_{side}"] = (Vector(p), pts[f"{n}_{side}"][1])


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
    blobs = thp.masses(pts, body, body_points(body, "neutral"))
    eds = edges()
    skin_pts = {n: (tuple(p), r) for n, (p, r) in pts.items() if not n.startswith("tip")}
    obj = kit.skin_object("Thrower_Body", skin_pts, eds, mat)
    tp.add_blobs(obj, blobs)
    kit.organic_pass(obj, voxel=VOXEL, lump=0.005)
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


def build_extremities(v, pts, skin):
    """Eller (ayrı ağ; sağ dev, sol küçük) ve yalın ayakta parmaklar."""
    out = []
    for side, sx in (("L", 1.0), ("R", -1.0)):
        k = v["body"].get("arm", 1.0) if side == "R" else v["body"].get("thin", 1.0)
        out.append(thp.build_hand("Thrower_Hand_" + side, pts[f"wrist_{side}"][0], pts[f"tip_{side}"][0],
                                  sx, HAND_SCALE[side] * k, skin, HAND_CURL[side]))
        if not v["shoes"]:
            out.append(tp.build_toes("Thrower_Toes_" + side, pts[f"ball_{side}"][0], pts[f"toe_{side}"][0],
                                     sx, 0.85, skin, v["seed"]))
    return out


def rock_in_hand(v, pts):
    """İmza pozunda kaya: dev elin avucunun önünde (oyunda prop RightHand kemiğine bağlanır)."""
    k = v["body"].get("arm", 1.0) * HAND_SCALE["R"]
    obj = rock.build_rock("Thrower_Rock")
    obj.data.materials.append(rock.rock_material("M_Thrower_Rock_" + v["name"]))
    obj.location = thp.palm_point(pts["wrist_R"][0], pts["tip_R"][0], -1.0, k, rock.ROCK_RADIUS * 0.85)
    return obj


def build_variant(v, offset_x=0.0, pose="neutral"):
    before = set(bpy.data.objects)
    suffix = "_" + v["name"]
    skin = kit.skin_material("M_Thrower_Skin" + suffix, v["tone"], v["bruise"])
    tooth_mat, _ = kit.material("M_Thrower_Teeth" + suffix, thh.TOOTH_COLOR, rough=0.5)
    style = wh.HAIR_STYLES.get(v["hair_style"])
    hair_mat = wh.hair_material("M_Thrower_Hair" + suffix, v["hair"], style["rough"]) if style else None
    body_obj, segments, pts = build_body(v, skin, pose)
    cache = {}

    def part(co):
        key = (round(co.x, 3), round(co.y, 3), round(co.z, 3))
        if key not in cache:
            cache[key] = classify(co, segments)
        return cache[key]
    build_extremities(v, pts, skin)
    thc.build_clothes(body_obj, part, pts, v, suffix)
    if v["shoes"]:
        thc.build_shoes(body_obj, pts, part, v, suffix)
    if pose == "signature":
        rock_in_hand(v, pts)
    pitch, jaw, roll, yaw = POSE_HEAD[pose]
    thh.build_head(v, skin, tooth_mat, hair_mat, pts["neck1"][0], pitch, jaw, roll, yaw)
    created = list(set(bpy.data.objects) - before)
    for obj in created:
        obj.name = obj.name.replace("Walker_", "Thrower_").replace("Tank_", "Thrower_")
    root = bpy.data.objects.new(f"Thrower_{v['name']}_{pose}", None)
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
        print("THROWER", v["name"], pose, "tris:", face_count(root))
        roots.append(root)
    kit.setup_look(target_height=1.3)
    if save:
        os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    return roots


if __name__ not in ("build_thrower",):
    build()
