"""Koşucu zombi "Pençeli" konsepti — Aşama V.5, tamamen Blender. v1.

İnce, sinirli, uzun kollu ve uzun pençeli. Sessizce çömelir, çığlık atar, pençeleriyle öne atılır
(oyuncuya zorlattığı karar: dash'i doğru anda kullanmak). Yürüyenden farkı: alçak ve öne uzamış
gövde, dizler hep bükük (parmak ucunda), öne uzanmış gergin boyun, dizlere inen kollar ve uçlarında
kıvrık boynuz pençeler; dirseklerde kemik dikeni.

Pozlar veri (`POSES`): "stalk" nötr duruş (sinsi, yarı çömelik), "crouch" imza anı (atılmadan önceki
çömelme: gövde yere yakın, pençeler önde yerde açık, baş kalkık, çene sonuna kadar açık çığlık).
Gövde: iskelet noktaları + skin modifier + voxel remesh (kit). Kafa: walker_head (çene/duruş burada
ezilir). El, pençe, kemik ve kıyafet: runner_parts.py. Görseller: runner_render.py.

Çalıştırma (arka plan Blender):
    blender --background --python tools/blender/build_runner.py            # dizi + .blend
    blender --background --python tools/blender/runner_render.py -- all     # tüm konsept görselleri
Çıktı: build/blender/runner.blend. Bu adım yalnız konsept: iskelet, animasyon ve GLB yok.
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
import walker_clothes as wc  # noqa: E402
import walker_head as wh  # noqa: E402
import runner_parts as rp  # noqa: E402

for _m in (kit, wh, wc, rp):
    importlib.reload(_m)
OUT_BLEND = os.path.join(REPO, "build", "blender", "runner.blend")
VOXEL = 0.006             # ince parmaklar için yürüyenden (0.008) sık
LINEUP_SPACING = 1.15
MOUTH_SCALE = (0.80, 0.90, 0.92)   # walker_head ağız boşluğu, çığlık çenesine göre

# Karakter -Y yönüne bakar, Z yukarı, metre. (konum, yarıçap); sol taraf +X.
POSES = {
    "stalk": {
        "torso": {"pelvis": ((0.0, 0.050, 0.860), 0.112), "belly": ((0.0, 0.005, 0.980), 0.092),
                  "spine": ((0.0, -0.060, 1.090), 0.102), "chest": ((0.0, -0.165, 1.185), 0.124),
                  "upchest": ((0.0, -0.255, 1.245), 0.104), "neck0": ((0.0, -0.330, 1.280), 0.050),
                  "neck1": ((0.0, -0.395, 1.300), 0.044)},
        "limbs": {
            "hip_R": ((-0.100, 0.050, 0.850), 0.078), "hip_L": ((0.100, 0.050, 0.850), 0.078),
            "knee_R": ((-0.140, -0.150, 0.500), 0.050), "knee_L": ((0.135, -0.060, 0.480), 0.050),
            "ankle_R": ((-0.140, 0.060, 0.120), 0.032), "ankle_L": ((0.135, 0.180, 0.140), 0.032),
            "heel_R": ((-0.140, 0.100, 0.078), 0.029), "heel_L": ((0.135, 0.225, 0.100), 0.029),
            "ball_R": ((-0.140, -0.040, 0.030), 0.031), "ball_L": ((0.135, 0.080, 0.030), 0.031),
            "toe_R": ((-0.140, -0.100, 0.022), 0.023), "toe_L": ((0.135, 0.020, 0.022), 0.023),
            "shoulder_R": ((-0.165, -0.235, 1.235), 0.056), "shoulder_L": ((0.165, -0.235, 1.235), 0.056),
            "elbow_R": ((-0.255, -0.360, 0.935), 0.039), "elbow_L": ((0.260, -0.400, 0.950), 0.039),
            "wrist_R": ((-0.265, -0.450, 0.610), 0.027), "wrist_L": ((0.295, -0.560, 0.650), 0.027),
            "palm_R": ((-0.268, -0.480, 0.530), 0.034), "palm_L": ((0.302, -0.610, 0.575), 0.034)},
        "hands": {"R": {"fdir": None, "cup": (0.0, -1.0, 0.25), "fan": 7.0},
                  "L": {"fdir": None, "cup": (0.0, -1.0, 0.25), "fan": 8.0}},
        "head_off": (0.0, -0.040, 0.005), "head_rot": (-14.0, 4.0, 6.0), "jaw": 24.0,
    },
    "crouch": {
        "torso": {"pelvis": ((0.0, 0.150, 0.500), 0.112), "belly": ((0.0, 0.045, 0.575), 0.092),
                  "spine": ((0.0, -0.060, 0.650), 0.102), "chest": ((0.0, -0.175, 0.730), 0.124),
                  "upchest": ((0.0, -0.260, 0.790), 0.104), "neck0": ((0.0, -0.320, 0.870), 0.050),
                  "neck1": ((0.0, -0.355, 0.945), 0.044)},
        "limbs": {
            "hip_R": ((-0.105, 0.150, 0.500), 0.078), "hip_L": ((0.105, 0.150, 0.500), 0.078),
            "knee_R": ((-0.235, -0.215, 0.420), 0.050), "knee_L": ((0.215, -0.135, 0.270), 0.050),
            "ankle_R": ((-0.200, 0.100, 0.120), 0.032), "ankle_L": ((0.200, 0.250, 0.105), 0.032),
            "heel_R": ((-0.200, 0.150, 0.100), 0.029), "heel_L": ((0.200, 0.300, 0.100), 0.029),
            "ball_R": ((-0.200, 0.000, 0.030), 0.031), "ball_L": ((0.200, 0.150, 0.030), 0.031),
            "toe_R": ((-0.200, -0.065, 0.022), 0.023), "toe_L": ((0.200, 0.090, 0.022), 0.023),
            "shoulder_R": ((-0.170, -0.250, 0.780), 0.056), "shoulder_L": ((0.170, -0.250, 0.780), 0.056),
            "elbow_R": ((-0.310, -0.390, 0.530), 0.039), "elbow_L": ((0.315, -0.355, 0.545), 0.039),
            "wrist_R": ((-0.310, -0.585, 0.200), 0.027), "wrist_L": ((0.340, -0.505, 0.200), 0.027),
            "palm_R": ((-0.315, -0.630, 0.115), 0.033), "palm_L": ((0.355, -0.550, 0.115), 0.033)},
        "hands": {"R": {"fdir": (-0.15, -0.80, -0.55), "cup": (0.0, 0.35, -1.0), "fan": 12.0, "curl": 0.8},
                  "L": {"fdir": (0.20, -0.80, -0.55), "cup": (0.0, 0.35, -1.0), "fan": 12.0, "curl": 0.8}},
        "head_off": (0.0, -0.030, 0.010), "head_rot": (-24.0, 0.0, -4.0), "jaw": 40.0,
    },
}
TORSO_EDGES = [("pelvis", "belly"), ("belly", "spine"), ("spine", "chest"), ("chest", "upchest"),
               ("upchest", "neck0"), ("neck0", "neck1")]
LIMB_CHAIN = [("hip", "knee"), ("knee", "ankle"), ("ankle", "heel"), ("ankle", "ball"),
              ("ball", "toe"), ("shoulder", "elbow"), ("elbow", "wrist"), ("wrist", "palm")]
PART_CLASS = {
    "pelvis-belly": "hips", "belly-spine": "torso_lo", "spine-chest": "torso_mid",
    "chest-upchest": "torso_hi", "upchest-neck0": "neck", "neck0-neck1": "neck",
    "pelvis-hip": "pelvis", "upchest-shoulder": "clav", "hip-knee": "thigh", "knee-ankle": "shin",
    "ankle-heel": "foot", "ankle-ball": "foot", "ball-toe": "foot", "shoulder-elbow": "uparm",
    "elbow-wrist": "forearm", "wrist-palm": "hand",
}

# Çeşitler. body: h boy, w gövde genişliği, t uzuv kalınlığı, head kafa ölçeği.
# top: track (eşofman, uzun kol) / torn (yırtık gömlek) / tank (atlet) / None (çıplak gövde);
# stripe: eşofman yan şeridi rengi; bib: göğüs numarası; hem: paça (0 kalça .. 1 bilek);
# shoes: renk ya da None; ribs/spine: çıplak gövdede kaburga ve omurga çıkıntısı. Doğrusal RGB.
VARIANTS = [
    {"name": "Jogger", "body": {"h": 1.00, "w": 0.95, "t": 0.92, "head": 0.95},
     "tone": (0.26, 0.27, 0.235), "bruise": (0.10, 0.08, 0.12), "bruise_band": (0.52, 0.72),
     "top": "track", "top_color": (0.025, 0.06, 0.11), "stripe": (0.55, 0.56, 0.56), "blood": 0.5,
     "holes": 0.18, "bottom_color": (0.025, 0.05, 0.09), "hem": 0.98, "hem_rag": 0.0,
     "shoes": (0.32, 0.32, 0.30), "hair": (0.04, 0.03, 0.02), "hair_style": "short", "seed": 2.0},
    {"name": "Torn", "body": {"h": 1.04, "w": 0.92, "t": 0.90, "head": 0.97},
     "tone": (0.22, 0.225, 0.20), "bruise": (0.08, 0.07, 0.10), "bruise_band": (0.50, 0.70),
     "top": "torn", "top_color": (0.40, 0.40, 0.36), "blood": 0.9, "holes": 0.42,
     "bottom_color": (0.06, 0.08, 0.13), "hem": 0.62, "hem_rag": 0.08,
     "shoes": None, "hair": (0.03, 0.025, 0.02), "hair_style": "sparse", "seed": 5.4},
    {"name": "Bare", "body": {"h": 0.98, "w": 0.90, "t": 0.88, "head": 0.94},
     "tone": (0.20, 0.17, 0.12), "bruise": (0.09, 0.06, 0.07), "bruise_band": (0.48, 0.70),
     "top": None, "ribs": True, "spine": True, "blood": 0.0,
     "bottom_color": (0.13, 0.12, 0.08), "hem": 0.80, "hem_rag": 0.10,
     "shoes": None, "hair": (0.02, 0.02, 0.02), "hair_style": "bald", "seed": 8.8},
    {"name": "Marathon", "body": {"h": 0.95, "w": 0.90, "t": 0.88, "head": 0.94},
     "tone": (0.25, 0.25, 0.25), "bruise": (0.09, 0.08, 0.13), "bruise_band": (0.50, 0.72),
     "top": "tank", "top_color": (0.42, 0.11, 0.025), "bib": (0.62, 0.62, 0.58), "blood": 0.6,
     "holes": 0.15, "bottom_color": (0.03, 0.03, 0.035), "hem": 0.28, "hem_rag": 0.02,
     "shoes": (0.10, 0.13, 0.16), "hair": (0.06, 0.035, 0.018), "hair_style": "long", "seed": 13.1},
]


# ---------------------------------------------------------------- gövde

def body_points(pose, body):
    w, h, t = body["w"], body["h"], body["t"]
    pts = {}
    for n, ((x, y, z), r) in POSES[pose]["torso"].items():
        pts[n] = (Vector((x * w, y, z * h)), r * w)
    for n, ((x, y, z), r) in POSES[pose]["limbs"].items():
        pts[n] = (Vector((x * w, y, z * h)), r * t)
    return pts


def segment_class(a, b):
    key = f"{a.split('_')[0]}-{b.split('_')[0]}"
    if key in PART_CLASS:
        return PART_CLASS[key]
    return "hand" if a[0] in "fpt" and b[0] in "ft" else None


def shape_body(obj, pts, v):
    """Kaburga dalgası (çıplak gövde) ve sinirli baldır: ağ köşelerini iskelet ekseninden iter."""
    chest, spine = pts["chest"], pts["spine"]
    legs = [(pts[f"knee_{s}"][0], pts[f"ankle_{s}"][0]) for s in ("L", "R")]
    for vert in obj.data.vertices:
        co = vert.co
        push, normal = 0.0, None
        for knee, ankle in legs:
            _c, t = geometry.intersect_point_line(co, knee, ankle)
            if 0.0 < t < 1.0 and (co - knee.lerp(ankle, t)).length < 0.07:
                axis = (ankle - knee).normalized()
                radial = (co - knee.lerp(ankle, t))
                back = Vector((0.0, 1.0, 0.0)) - axis * axis.y
                face = radial.normalized().dot(back.normalized())
                push += 0.010 * math.exp(-((t - 0.28) / 0.15) ** 2) * max(0.0, face)
                normal = radial.normalized()
        if v.get("ribs"):
            _c, t = geometry.intersect_point_line(co, spine[0], chest[0] + (chest[0] - spine[0]) * 0.4)
            radial = co - spine[0].lerp(chest[0], t)
            if 0.0 < t < 1.3 and radial.length < chest[1] * 1.4 and radial.normalized().y < 0.2:
                rn = radial.normalized()
                phase = t + 0.22 * max(0.0, -rn.y)              # kaburga öne doğru iner
                fade = min(1.0, abs(rn.x) * 2.2 + 0.15) * min(1.0, (1.3 - t) * 2.0)
                push += fade * (0.0032 * math.sin(phase * math.pi * 5.0) ** 2 - 0.0016)
                normal = rn
        if normal is not None and push:
            vert.co = co + normal * push


def build_body(v, pose, mat):
    body = v["body"]
    pts = body_points(pose, body)
    edges = list(TORSO_EDGES)
    claws = []
    for side in ("L", "R"):
        edges += [(f"{a}_{side}", f"{b}_{side}") for a, b in LIMB_CHAIN]
        edges += [("pelvis", f"hip_{side}"), ("upchest", f"shoulder_{side}")]
        extra, e, c = rp.hand(pts, side, POSES[pose]["hands"][side], body["t"])
        pts.update(extra)
        edges += e
        claws += c
    obj = kit.skin_object("Runner_Body", {n: (tuple(p), r) for n, (p, r) in pts.items()}, edges, mat)
    kit.organic_pass(obj, voxel=VOXEL, lump=0.004)
    shape_body(obj, pts, v)
    segments = [(segment_class(a, b), pts[a][0], pts[b][0]) for a, b in edges]
    return obj, [s for s in segments if s[0]], pts, claws


def classify(co, segments):
    """Noktanın en yakın iskelet parçası: (sınıf, parça boyunca 0..1, eksenden dışa birim yön)."""
    best, best_d = None, 1e9
    for cls, a, b in segments:
        _c, t = geometry.intersect_point_line(co, a, b)
        t = min(max(t, 0.0), 1.0)
        d = co - a.lerp(b, t)
        if d.length < best_d:
            best, best_d = (cls, t, d), d.length
    cls, t, d = best
    return cls, t, (d.normalized() if d.length > 1e-6 else Vector((0.0, 0.0, 1.0)))


# ---------------------------------------------------------------- çeşit

def skin_for(v, name):
    mat = kit.skin_material(name, v["tone"], v["bruise"])
    ramp = next(n for n in mat.node_tree.nodes if n.type == "VALTORGB")
    ramp.color_ramp.elements[0].position, ramp.color_ramp.elements[1].position = v["bruise_band"]
    return mat


def pose_head(head, neck, pose, h):
    spec = POSES[pose]
    head.location = neck + Vector(spec["head_off"]) * h
    head.rotation_euler = tuple(math.radians(a) for a in spec["head_rot"])
    jaw = next(o for o in head.children if o.name.startswith("Walker_Jaw"))
    jaw.rotation_euler = (math.radians(spec["jaw"]), math.radians(2.0), 0.0)
    mouth = next((o for o in head.children if o.name.startswith("Walker_Mouth")), None)
    if mouth is not None:   # geniş açık çenede boşluk yanaktan taşmasın: daralt, geri it
        mouth.scale = MOUTH_SCALE
        mouth.location = (0.0, 0.006, 0.0)


def build_variant(v, pose="stalk", offset_x=0.0, prefix="Runner_"):
    before = set(bpy.data.objects)
    suffix = "_" + v["name"]
    skin = skin_for(v, "M_Runner_Skin" + suffix)
    tooth_mat, _ = kit.material("M_Runner_Teeth" + suffix, (0.42, 0.36, 0.22), rough=0.4)
    style = wh.HAIR_STYLES.get(v["hair_style"])
    hair_mat = wh.hair_material("M_Runner_Hair" + suffix, v["hair"], style["rough"]) if style else None
    body_obj, segments, pts, claws = build_body(v, pose, skin)
    cache = {}

    def part(co):
        key = (round(co.x, 4), round(co.y, 4), round(co.z, 4))
        if key not in cache:
            cache[key] = classify(co, segments)
        return cache[key]
    rp.build_clothes(body_obj, part, v, suffix)
    if v["shoes"]:
        wc.build_shoes(body_obj, pts, lambda co: part(co)[:2], v, suffix)
    claw_mat = rp.claw_material("M_Runner_Claw" + suffix)
    rp.build_claws("Runner_Claws", claws, claw_mat)
    rp.build_claws("Runner_Spurs", rp.bone_spurs(pts, v.get("spine")), claw_mat, bend=25.0)
    head = wh.build_head(v, skin, tooth_mat, hair_mat, pts["neck1"][0], v["body"]["h"])
    pose_head(head, pts["neck1"][0], pose, v["body"]["h"])
    created = list(set(bpy.data.objects) - before)
    root = bpy.data.objects.new(prefix + v["name"], None)
    bpy.context.collection.objects.link(root)
    for obj in created:
        if obj.parent is None:
            obj.parent = root
    root.location.x = offset_x
    bpy.context.view_layer.update()
    return root


def face_count(root):
    return sum(sum(len(p.vertices) - 2 for p in o.data.polygons)
               for o in root.children_recursive if o.type == "MESH")


def build(pose="stalk") -> None:
    kit.reset_scene()
    count = len(VARIANTS)
    for i, v in enumerate(VARIANTS):
        root = build_variant(v, pose, (i - (count - 1) / 2) * LINEUP_SPACING)
        print("RUNNER", v["name"], pose, "tris:", face_count(root))
    kit.setup_look()
    os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    print("RUNNER built, variants:", count)


# Modül olarak içe aktarılınca kurulum çalışmaz; betik olarak çalıştırınca çalışır.
if __name__ != "build_runner":
    build()
