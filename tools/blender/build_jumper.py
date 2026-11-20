"""Zıplayan zombi konsepti v1 — Aşama V.5, tamamen Blender.

İmza: iri uyluklar. Derin çömelir, yay çizerek sıçrar, indiği yerde şok yaratır.
Siluet: dev uyluk ve baldır, yaylı / ters bükük bacak (topuk havada, parmak ucunda durur),
geniş açık duruş, küçük kambur üst gövde ve küçük kafa, yere uzanan uzun ince kollar.
Yukarıdan bakınca alt gövde kütlesi (yana açılmış uyluklar) okunur.

Gövde: iskelet noktaları + skin modifier + voxel remesh (zombie_kit). Kafa: walker_head (küçültülmüş,
yukarı bakar). Kıyafet: jumper_clothes.py. Görseller: jumper_render.py.

Çalıştırma (arka plan; canlı MCP değil):
    blender --background --python tools/blender/jumper_render.py            # sahne + tüm görseller
    blender --background --python tools/blender/build_jumper.py             # yalnız sahne
Çıktı: build/blender/jumper.blend. Bu adım yalnız konsept: iskelet, animasyon ve GLB yok.
"""
import importlib
import math
import os
import sys

import bpy
from mathutils import Vector, geometry

_HERE = globals().get("__file__", "")
REPO = os.path.abspath(os.path.join(os.path.dirname(_HERE), "..", "..")) if _HERE else ""
if not REPO or not os.path.isdir(os.path.join(REPO, "tools")):
    REPO = r"C:\Users\pekta\projeler\Deadzone-Last-Stand"
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import zombie_kit as kit  # noqa: E402
import walker_head as wh  # noqa: E402
import jumper_clothes as jc  # noqa: E402

importlib.reload(kit)
importlib.reload(wh)
importlib.reload(jc)
OUT_BLEND = os.path.join(REPO, "build", "blender", "jumper.blend")

# Karakter -Y yönüne bakar, Z yukarı, metre. Uzuv noktaları sol (+X) için; sağ aynalanır.
# (konum, yarıçap). "thigh" ve "calf" ara noktaları kas kütlesidir (öne kayık quadriceps,
# dizin altında arkaya kayık baldır). Bacak ters bükük: diz önde ve dışta, bilek (topuk) yüksek ve
# geride, ağırlık parmak kökünde.
POSES = {
    # nötr: yarı çömelik hazır duruş
    "stand": {
        "torso": {
            "pelvis": ((0.0, 0.060, 0.860), 0.150), "belly": ((0.0, 0.020, 0.975), 0.125),
            "spine": ((0.0, -0.035, 1.075), 0.120), "chest": ((0.0, -0.105, 1.170), 0.135),
            "upchest": ((0.0, -0.165, 1.240), 0.110), "neck0": ((0.0, -0.225, 1.290), 0.055),
            "neck1": ((0.0, -0.265, 1.320), 0.048)},
        "limb": {
            "hip": ((0.150, 0.060, 0.840), 0.125), "thigh": ((0.260, -0.050, 0.700), 0.172),
            "knee": ((0.315, -0.170, 0.530), 0.080), "calf": ((0.305, 0.030, 0.400), 0.128),
            "ankle": ((0.260, 0.110, 0.180), 0.045), "heel": ((0.260, 0.150, 0.135), 0.050),
            "ball": ((0.250, -0.050, 0.048), 0.060), "toe": ((0.245, -0.120, 0.038), 0.045),
            "shoulder": ((0.190, -0.160, 1.230), 0.082), "elbow": ((0.255, -0.235, 0.870), 0.056),
            "forearm": ((0.225, -0.330, 0.715), 0.058),
            "wrist": ((0.165, -0.450, 0.380), 0.040), "palm": ((0.155, -0.470, 0.295), 0.048)},
        "head": (-12.0, 4.0, 0.0),        # pitch (eksi: yukarı), roll, yaw — derece
    },
    # imza: sıçramadan önceki derin çömelme; kalça yere yakın, uyluklar yatay ve sıkışmış,
    # kollar geriye savrulmuş, kafa hedefe (yukarı-ileri) bakar
    "crouch": {
        "torso": {
            "pelvis": ((0.0, 0.170, 0.400), 0.150), "belly": ((0.0, 0.085, 0.500), 0.125),
            "spine": ((0.0, -0.020, 0.585), 0.120), "chest": ((0.0, -0.140, 0.665), 0.135),
            "upchest": ((0.0, -0.230, 0.720), 0.110), "neck0": ((0.0, -0.305, 0.775), 0.055),
            "neck1": ((0.0, -0.350, 0.815), 0.048)},
        "limb": {
            "hip": ((0.160, 0.160, 0.390), 0.125), "thigh": ((0.295, -0.020, 0.420), 0.185),
            "knee": ((0.335, -0.210, 0.470), 0.080), "calf": ((0.315, 0.000, 0.290), 0.135),
            "ankle": ((0.285, 0.130, 0.150), 0.045), "heel": ((0.285, 0.170, 0.110), 0.050),
            "ball": ((0.270, -0.060, 0.048), 0.060), "toe": ((0.265, -0.130, 0.038), 0.045),
            "shoulder": ((0.190, -0.210, 0.715), 0.082), "elbow": ((0.310, 0.130, 0.570), 0.056),
            "forearm": ((0.312, 0.280, 0.610), 0.058),
            "wrist": ((0.300, 0.470, 0.700), 0.040), "palm": ((0.295, 0.545, 0.735), 0.048)},
        "head": (-38.0, 0.0, 0.0),
    },
}
TORSO_EDGES = [("pelvis", "belly"), ("belly", "spine"), ("spine", "chest"), ("chest", "upchest"),
               ("upchest", "neck0"), ("neck0", "neck1")]
LIMB_CHAIN = [("hip", "thigh"), ("thigh", "knee"), ("knee", "calf"), ("calf", "ankle"),
              ("ankle", "heel"), ("ankle", "ball"), ("ball", "toe"),
              ("shoulder", "elbow"), ("elbow", "forearm"), ("forearm", "wrist"), ("wrist", "palm")]
# Kıyafet sınıflandırması ana eklemlerden (kas ara noktaları yok sayılır).
CLASS_SEGMENTS = [("hips", "pelvis", "belly"), ("hips", "pelvis", "hip_*"), ("torso", "belly", "spine"),
                  ("torso", "spine", "chest"), ("torso", "chest", "upchest"), ("neck", "upchest", "neck1"),
                  ("clav", "upchest", "shoulder_*"), ("thigh", "hip_*", "knee_*"),
                  ("shin", "knee_*", "ankle_*"), ("foot", "ankle_*", "ball_*"), ("foot", "ball_*", "toe_*"),
                  ("uparm", "shoulder_*", "elbow_*"), ("forearm", "elbow_*", "wrist_*"),
                  ("hand", "wrist_*", "palm_*")]
LINEUP_SPACING = 1.25
QUAD = 0.042              # uyluk ön kas şişkinliği (m)
CALF = 0.030              # baldır şişkinliği (m, arkaya)

# Çeşitler. body: h boy, w gövde genişliği, t uzuv kalınlığı, leg bacak kütle çarpanı, arm kol
# kalınlığı, head kafa ölçeği. top: None / tank / tshirt; bib: tulum önlüğü rengi (askılı);
# bottom: shorts / pants; hem: paça boyu (0 kalça .. 1 bilek); burst: uyluk/baldırda patlak yoğunluğu;
# pocket: kargo cebi rengi. Hepsi yalınayak (ayakkabı kas şişmesiyle patlamış). Renkler doğrusal RGB.
VARIANTS = [
    {"name": "Shorts", "body": {"h": 1.00, "w": 1.00, "t": 1.00, "leg": 1.08, "arm": 0.95, "head": 0.86},
     "tone": (0.24, 0.26, 0.21), "bruise": (0.09, 0.08, 0.12), "bruise_band": (0.50, 0.70),
     "top": None, "top_color": None, "bib": None, "blood": 0.5,
     "bottom": "shorts", "bottom_color": (0.30, 0.025, 0.03), "hem": 0.30, "burst": 0.10, "pocket": None,
     "hair": (0.03, 0.025, 0.02), "hair_style": "bald", "seed": 2.0},
    {"name": "Cargo", "body": {"h": 1.04, "w": 0.95, "t": 1.00, "leg": 1.00, "arm": 1.00, "head": 0.88},
     "tone": (0.22, 0.24, 0.195), "bruise": (0.10, 0.075, 0.11), "bruise_band": (0.50, 0.70),
     "top": "tank", "top_color": (0.50, 0.48, 0.40), "bib": None, "blood": 0.8,
     "bottom": "pants", "bottom_color": (0.13, 0.13, 0.07), "hem": 0.70, "burst": 0.32,
     "pocket": (0.10, 0.10, 0.055), "hair": (0.04, 0.03, 0.02), "hair_style": "fringe", "seed": 5.4},
    {"name": "Overall", "body": {"h": 0.97, "w": 1.10, "t": 1.08, "leg": 1.12, "arm": 1.05, "head": 0.90},
     "tone": (0.25, 0.235, 0.19), "bruise": (0.12, 0.07, 0.09), "bruise_band": (0.50, 0.70),
     "top": None, "top_color": None, "bib": (0.04, 0.10, 0.16), "blood": 0.3,
     "bottom": "pants", "bottom_color": (0.04, 0.10, 0.16), "hem": 0.55, "burst": 0.22, "pocket": None,
     "hair": (0.05, 0.035, 0.02), "hair_style": "sparse", "seed": 9.1},
    {"name": "Track", "body": {"h": 1.02, "w": 0.92, "t": 0.96, "leg": 1.04, "arm": 0.92, "head": 0.85},
     "tone": (0.13, 0.105, 0.085), "bruise": (0.10, 0.045, 0.05), "bruise_band": (0.50, 0.70),
     "top": "tshirt", "top_color": (0.10, 0.20, 0.32), "bib": None, "blood": 0.5,
     "bottom": "pants", "bottom_color": (0.035, 0.035, 0.04), "hem": 0.85, "burst": 0.28, "pocket": None,
     "hair": (0.02, 0.016, 0.012), "hair_style": "short", "seed": 13.3},
]


# ---------------------------------------------------------------- gövde

def body_points(body, pose="stand"):
    """Çeşidin gövde noktaları (karakter kökü 0'da); uzuvlar L (+X) ve R (-X)."""
    p = POSES[pose]
    h, w = body["h"], body["w"]
    pts = {}
    for n, (c, r) in p["torso"].items():
        pts[n] = (Vector((c[0] * w, c[1], c[2] * h)), r * w)
    leg_names = ("hip", "thigh", "knee", "calf", "ankle", "heel", "ball", "toe")
    for n, (c, r) in p["limb"].items():
        k = body["t"] * (body["leg"] if n in leg_names else body["arm"])
        xs = w if n in ("hip", "shoulder") else 1.0
        for side, sx in (("L", 1.0), ("R", -1.0)):
            pts[f"{n}_{side}"] = (Vector((c[0] * xs * sx, c[1], c[2] * h)), r * k)
    return pts


def _hand(pts, side, t):
    """Uzun, pençe gibi kıvrık dört parmak + başparmak."""
    wrist, palm = pts[f"wrist_{side}"][0], pts[f"palm_{side}"][0]
    d = (palm - wrist).normalized()
    ref = Vector((0.0, -1.0, 0.0)) if abs(d.y) < 0.8 else Vector((0.0, 0.0, 1.0))
    across = d.cross(ref).normalized()
    curl = across.cross(d).normalized()
    extra, edges = {}, []
    for i in range(4):
        spread = (i - 1.5) * 0.024 * t
        base = palm + across * spread
        mid = base + d * 0.060 + curl * 0.010 + across * spread * 0.5
        tip = mid + d * 0.040 + curl * 0.035 + across * spread * 0.3
        extra[f"f{i}a_{side}"] = (mid, 0.0115 * t)
        extra[f"f{i}b_{side}"] = (tip, 0.0080 * t)
        edges += [(f"palm_{side}", f"f{i}a_{side}"), (f"f{i}a_{side}", f"f{i}b_{side}")]
    inward = Vector((-1.0 if palm.x > 0 else 1.0, 0.0, 0.0))
    extra[f"th_{side}"] = (palm + d * 0.040 + inward * 0.040 + curl * 0.012, 0.0105 * t)
    edges.append((f"palm_{side}", f"th_{side}"))
    return extra, edges


def _toes(pts, side):
    """Çıplak ayakta dört kısa parmak (takunya değil)."""
    ball, toe = pts[f"ball_{side}"][0], pts[f"toe_{side}"][0]
    fwd = (toe - ball).normalized()
    across = Vector((1.0, 0.0, 0.0))
    extra, edges = {}, []
    for i in range(4):
        off = (i - 1.5) * 0.032 * (1.0 if ball.x > 0 else -1.0)
        tip = ball + fwd * (0.135 - abs(i - 0.8) * 0.018) + across * off
        tip.z = 0.016
        extra[f"t{i}_{side}"] = (tip, 0.0135 - i * 0.0010)
        edges.append((f"ball_{side}", f"t{i}_{side}"))
    return extra, edges


def classify_fn(pts):
    """Noktanın en yakın ana parçası: (sınıf, parça boyunca 0..1, ekseninden dışa birim vektör)."""
    segs = []
    for cls, a, b in CLASS_SEGMENTS:
        for side in (("L", "R") if "*" in a or "*" in b else ("",)):
            segs.append((cls, pts[a.replace("*", side)][0], pts[b.replace("*", side)][0]))

    def classify(co):
        best, best_d = ("torso", 0.0, Vector((0.0, -1.0, 0.0))), 1e9
        for cls, a, b in segs:
            _c, t = geometry.intersect_point_line(co, a, b)
            t = min(max(t, 0.0), 1.0)
            axis_pt = a.lerp(b, t)
            d = (co - axis_pt).length
            if d < best_d:
                radial = (co - axis_pt).normalized() if d > 1e-6 else Vector((0.0, -1.0, 0.0))
                best, best_d = (cls, t, radial), d
        return best
    return classify


def shape_muscles(obj, pts, body):
    """Uyluk önüne quadriceps, dizin altında arkaya baldır şişkinliği; ince bilek."""
    quad, calf = QUAD * body["leg"], CALF * body["leg"]
    legs = [(pts[f"hip_{s}"][0], pts[f"knee_{s}"][0], pts[f"ankle_{s}"][0]) for s in ("L", "R")]
    top = max(h.z for h, _k, _a in legs) + 0.10
    for vert in obj.data.vertices:
        co = vert.co
        if co.z > top:
            continue
        best = None
        for hip, knee, ankle in legs:
            for a, b, kind in ((hip, knee, "thigh"), (knee, ankle, "shin")):
                _c, t = geometry.intersect_point_line(co, a, b)
                t = min(max(t, 0.0), 1.0)
                axis_pt = a.lerp(b, t)
                d = (co - axis_pt).length
                if best is None or d < best[0]:
                    best = (d, kind, t, axis_pt, (b - a).normalized())
        d, kind, t, axis_pt, axis = best
        if d > 0.28 or d < 1e-6:
            continue
        radial = (co - axis_pt).normalized()
        # bacağın "önü": dizin baktığı yön (uyluk için) / dizin geldiği yön (baldır arka)
        front = Vector((0.0, -1.0, 0.25))
        front = (front - axis * front.dot(axis)).normalized()
        facing = radial.dot(front)
        if kind == "thigh":
            push = quad * math.exp(-((t - 0.55) / 0.28) ** 2) * (0.3 + 0.7 * max(0.0, facing))
            inner = radial.dot(Vector((-1.0 if co.x > 0 else 1.0, 0.0, 0.0)))
            push += 0.5 * quad * math.exp(-((t - 0.82) / 0.09) ** 2) * max(0.0, inner)  # damla kas
        else:
            push = calf * math.exp(-((t - 0.25) / 0.18) ** 2) * (0.3 + 0.7 * max(0.0, -facing))
            push -= 0.30 * calf * max(0.0, (t - 0.75) / 0.25)
        vert.co = co + radial * push


def build_body(v, mat, pose):
    body = v["body"]
    pts = body_points(body, pose)
    edges = list(TORSO_EDGES)
    skin_pts = dict(pts)
    for side in ("L", "R"):
        edges += [(f"{a}_{side}", f"{b}_{side}") for a, b in LIMB_CHAIN]
        edges += [("pelvis", f"hip_{side}"), ("upchest", f"shoulder_{side}")]
        for fn in (lambda: _hand(pts, side, body["t"] * body["arm"]), lambda: _toes(pts, side)):
            extra, e = fn()
            skin_pts.update(extra)
            edges += e
    obj = kit.skin_object("Jumper_Body", {n: (tuple(p), r) for n, (p, r) in skin_pts.items()}, edges, mat)
    kit.organic_pass(obj, voxel=0.008)
    shape_muscles(obj, pts, body)
    return obj, pts


# ---------------------------------------------------------------- çeşit

def skin_for(v, name):
    mat = kit.skin_material(name, v["tone"], v["bruise"])
    band = v.get("bruise_band")
    if band:
        ramp = next(n for n in mat.node_tree.nodes if n.type == "VALTORGB")
        ramp.color_ramp.elements[0].position, ramp.color_ramp.elements[1].position = band
    return mat


def build_variant(v, offset_x=0.0, pose="stand"):
    before = set(bpy.data.objects)
    suffix = "_" + v["name"] + ("" if pose == "stand" else "_" + pose)
    skin = skin_for(v, "M_Jumper_Skin" + suffix)
    tooth_mat, _ = kit.material("M_Jumper_Teeth" + suffix, (0.45, 0.40, 0.28), rough=0.4)
    style = wh.HAIR_STYLES.get(v["hair_style"])
    hair_mat = wh.hair_material("M_Jumper_Hair" + suffix, v["hair"], style["rough"]) if style else None
    body_obj, pts = build_body(v, skin, pose)
    body_obj["chest_z"], body_obj["belly_z"] = pts["chest"][0].z, pts["belly"][0].z
    jc.build_clothes(body_obj, classify_fn(pts), v, suffix)
    hv = dict(v, name="Jumper" + suffix)
    head = wh.build_head(hv, skin, tooth_mat, hair_mat, pts["neck1"][0], 1.0)
    head.location = pts["neck1"][0] + Vector((0.0, -0.030, 0.020))
    pitch, roll, yaw = POSES[pose]["head"]
    head.rotation_euler = (math.radians(pitch), math.radians(roll), math.radians(yaw))
    created = list(set(bpy.data.objects) - before)
    root = bpy.data.objects.new("Jumper_" + v["name"] + ("" if pose == "stand" else "_" + pose), None)
    bpy.context.collection.objects.link(root)
    for obj in created:
        if obj.parent is None:
            obj.parent = root
    root.location.x = offset_x
    return root


def face_count(root):
    return sum(sum(len(p.vertices) - 2 for p in o.data.polygons)
               for o in [root] + list(root.children_recursive) if o.type == "MESH")


def build() -> None:
    kit.reset_scene()
    count = len(VARIANTS)
    for i, v in enumerate(VARIANTS):
        root = build_variant(v, (i - (count - 1) / 2) * LINEUP_SPACING)
        print("JUMPER", v["name"], "tris:", face_count(root))
    kit.setup_look()
    os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    print("JUMPER built, variants:", count)


if __name__ == "__main__":
    build()
