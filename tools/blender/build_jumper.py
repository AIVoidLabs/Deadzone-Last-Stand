"""Zıplayan zombi konsepti v2 — Aşama V.5, tamamen Blender.

İmza: kaslı, yaylı bacaklar. Derin çömelir, yay çizerek sıçrar, indiği yerde şok yaratır.
Siluet (v1'den korunan): alçak kemer, kambur küçük üst gövde, yana açık dev alt gövde.
v2 düzeltmeleri: bacak balon/armut değil kas grupları (ön uyluk üç baş, iç uyluk, hamstring, kalça,
diz kapağı, iki başlı sıkı baldır, ince aşil ve bilek); kollar kısaldı ve kaslandı (deltoid, biseps,
triseps, önkol; dirsekte incelir); bacak insansı: eklem sırası değişmez, topuk yalnız ~6 cm havada;
ayakta beş parmak ve topuk; kendi kafası (jumper_head); kargo pantolon çıktı.

Gövde: iskelet noktaları + skin modifier (kemik hacmi) + ayrı kas elipsoitleri (jumper_muscles),
birleştirilip voxel remesh (kaslar arası oluk kalır). Kıyafet: jumper_clothes.py. Görseller: jumper_render.py.

Çalıştırma (arka plan; canlı MCP değil):
    blender --background --python tools/blender/jumper_render.py            # sahne + tüm görseller
    blender --background --python tools/blender/build_jumper.py             # yalnız sahne
Çıktı: build/blender/jumper.blend. Oyun modeli: jumper_game.py.
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
import jumper_head as jh  # noqa: E402
import jumper_muscles as jm  # noqa: E402
import jumper_clothes as jc  # noqa: E402

for _m in (kit, jh, jm, jc):
    importlib.reload(_m)
OUT_BLEND = os.path.join(REPO, "build", "blender", "jumper.blend")

# Karakter -Y yönüne bakar, Z yukarı, metre. Uzuv noktaları sol (+X) için; sağ aynalanır.
# Yarıçaplar kemik hacmidir (ince); kütleyi kaslar verir.
POSES = {
    # nötr: yarı çömelik hazır duruş (oyun modelinin dinlenme pozu)
    "stand": {
        "torso": {
            "pelvis": ((0.0, 0.050, 0.800), 0.135), "belly": ((0.0, 0.010, 0.915), 0.112),
            "spine": ((0.0, -0.040, 1.010), 0.112), "chest": ((0.0, -0.110, 1.100), 0.122),
            "upchest": ((0.0, -0.170, 1.165), 0.100), "neck0": ((0.0, -0.225, 1.215), 0.058),
            "neck1": ((0.0, -0.262, 1.245), 0.050)},
        "limb": {
            "hip": ((0.115, 0.050, 0.785), 0.088), "knee": ((0.290, -0.180, 0.470), 0.056),
            "ankle": ((0.245, 0.095, 0.120), 0.037), "heel": ((0.245, 0.122, 0.058), 0.038),
            "ball": ((0.235, -0.075, 0.032), 0.036),
            "shoulder": ((0.190, -0.150, 1.150), 0.058), "elbow": ((0.265, -0.200, 0.880), 0.038),
            "wrist": ((0.225, -0.320, 0.690), 0.029), "palm": ((0.212, -0.362, 0.618), 0.036)},
        "head": (-14.0, 4.0, 0.0),        # pitch (eksi: yukarı), roll, yaw — derece
    },
    # imza: sıçramadan önceki derin çömelme; kalça yere yakın, kollar geriye, kafa hedefe bakar
    "crouch": {
        "torso": {
            "pelvis": ((0.0, 0.200, 0.400), 0.135), "belly": ((0.0, 0.120, 0.500), 0.112),
            "spine": ((0.0, 0.020, 0.580), 0.112), "chest": ((0.0, -0.090, 0.650), 0.122),
            "upchest": ((0.0, -0.180, 0.700), 0.100), "neck0": ((0.0, -0.245, 0.745), 0.058),
            "neck1": ((0.0, -0.285, 0.780), 0.050)},
        "limb": {
            "hip": ((0.125, 0.200, 0.385), 0.088), "knee": ((0.300, -0.170, 0.460), 0.050),
            "ankle": ((0.270, 0.120, 0.125), 0.032), "heel": ((0.270, 0.148, 0.062), 0.036),
            "ball": ((0.260, -0.050, 0.032), 0.036),
            "shoulder": ((0.190, -0.160, 0.690), 0.058), "elbow": ((0.280, 0.080, 0.580), 0.038),
            "wrist": ((0.300, 0.330, 0.620), 0.029), "palm": ((0.300, 0.400, 0.640), 0.036)},
        "head": (-36.0, 0.0, 0.0),
    },
}
TORSO_EDGES = [("pelvis", "belly"), ("belly", "spine"), ("spine", "chest"), ("chest", "upchest"),
               ("upchest", "neck0"), ("neck0", "neck1")]
LIMB_CHAIN = [("hip", "knee"), ("knee", "ankle"), ("ankle", "heel"), ("ankle", "ball"),
              ("shoulder", "elbow"), ("elbow", "wrist"), ("wrist", "palm")]
LEG_NAMES = ("hip", "knee", "ankle", "heel", "ball")
CLASS_SEGMENTS = [("hips", "pelvis", "belly"), ("hips", "pelvis", "hip_*"), ("torso", "belly", "spine"),
                  ("torso", "spine", "chest"), ("torso", "chest", "upchest"), ("neck", "upchest", "neck1"),
                  ("clav", "upchest", "shoulder_*"), ("thigh", "hip_*", "knee_*"),
                  ("shin", "knee_*", "ankle_*"), ("foot", "ankle_*", "ball_*"),
                  ("uparm", "shoulder_*", "elbow_*"), ("forearm", "elbow_*", "wrist_*"),
                  ("hand", "wrist_*", "palm_*")]
LINEUP_SPACING = 1.15
VOXEL = 0.0065            # kas oluklarını tutacak kadar ince
SMOOTH = 3                # remesh sonrası yumuşatma (fazlası olukları siler)

# Çeşitler. body: h boy, w gövde genişliği, t uzuv kalınlığı, leg/arm kas çarpanı, head kafa ölçeği.
# top: None / jacket (eşofman üstü, kollar dirseğe sıvalı); bib: tulum önlüğü rengi (askılı);
# bottom_color + hem: paça boyu (0 kalça .. 1 bilek); stripe: yan şerit rengi; scalp: kısa saç rengi.
# Hepsi yalınayak (ayakkabı kas şişmesiyle patlamış). Renkler doğrusal RGB.
VARIANTS = [
    {"name": "Shorts", "body": {"h": 1.00, "w": 1.00, "t": 1.00, "leg": 1.08, "arm": 0.96, "head": 0.92},
     "tone": (0.24, 0.26, 0.21), "bruise": (0.09, 0.08, 0.12), "bruise_band": (0.50, 0.70),
     "top": None, "top_color": None, "bib": None, "blood": 0.5,
     "bottom_color": (0.30, 0.025, 0.03), "hem": 0.34, "stripe": None, "scalp": None, "seed": 2.0},
    {"name": "Overall", "body": {"h": 0.97, "w": 1.10, "t": 1.05, "leg": 1.12, "arm": 1.06, "head": 0.94},
     "tone": (0.25, 0.235, 0.19), "bruise": (0.12, 0.07, 0.09), "bruise_band": (0.50, 0.70),
     "top": None, "top_color": None, "bib": (0.04, 0.10, 0.16), "blood": 0.3,
     "bottom_color": (0.04, 0.10, 0.16), "hem": 0.66, "stripe": None, "scalp": (0.05, 0.035, 0.02),
     "seed": 9.1},
    {"name": "Track", "body": {"h": 1.02, "w": 0.94, "t": 0.96, "leg": 1.04, "arm": 0.93, "head": 0.90},
     "tone": (0.13, 0.105, 0.085), "bruise": (0.10, 0.045, 0.05), "bruise_band": (0.50, 0.70),
     "top": "jacket", "top_color": (0.035, 0.07, 0.17), "bib": None, "blood": 0.5,
     "bottom_color": (0.03, 0.03, 0.035), "hem": 0.93, "stripe": (0.55, 0.55, 0.52),
     "scalp": (0.02, 0.016, 0.012), "seed": 13.3},
]


# ---------------------------------------------------------------- gövde

def body_points(body, pose="stand"):
    """Çeşidin gövde noktaları (karakter kökü 0'da); uzuvlar L (+X) ve R (-X)."""
    p = POSES[pose]
    h, w = body["h"], body["w"]
    pts = {}
    for n, (c, r) in p["torso"].items():
        pts[n] = (Vector((c[0] * w, c[1], c[2] * h)), r * w)
    for n, (c, r) in p["limb"].items():
        k = body["t"]
        xs = w if n in ("hip", "shoulder") else 1.0
        for side, sx in (("L", 1.0), ("R", -1.0)):
            pts[f"{n}_{side}"] = (Vector((c[0] * xs * sx, c[1], c[2] * h)), r * k)
    for side in ("L", "R"):          # ayak tabanı yerde kalır (boy ölçeği yalnız bacağı uzatır)
        for n in ("ball", "heel"):
            c, r = pts[f"{n}_{side}"]
            pts[f"{n}_{side}"] = (Vector((c.x, c.y, POSES[pose]["limb"][n][0][2])), r)
    return pts


def _hand(pts, side, t):
    """Kısa, boğumlu dört parmak (yarı kıvrık) + başparmak."""
    wrist, palm = pts[f"wrist_{side}"][0], pts[f"palm_{side}"][0]
    d = (palm - wrist).normalized()
    ref = Vector((0.0, -1.0, 0.0)) if abs(d.y) < 0.8 else Vector((0.0, 0.0, 1.0))
    across = d.cross(ref).normalized()
    curl = across.cross(d).normalized()
    extra, edges = {}, []
    for i in range(4):
        spread = (i - 1.5) * 0.021 * t
        base = palm + across * spread
        k = 1.0 - abs(i - 1.3) * 0.08
        mid = base + d * 0.040 * k + curl * 0.008 + across * spread * 0.3
        tip = mid + d * 0.026 * k + curl * 0.026
        extra[f"f{i}a_{side}"] = (mid, 0.0118 * t)
        extra[f"f{i}b_{side}"] = (tip, 0.0092 * t)
        edges += [(f"palm_{side}", f"f{i}a_{side}"), (f"f{i}a_{side}", f"f{i}b_{side}")]
    inward = Vector((-1.0 if palm.x > 0 else 1.0, 0.0, 0.0))
    extra[f"th_{side}"] = (palm + d * 0.022 + inward * 0.036 + curl * 0.018, 0.0115 * t)
    edges.append((f"palm_{side}", f"th_{side}"))
    return extra, edges


def _toes(pts, side):
    """Beş parmak: kalın başparmak içte, küçükler dışa doğru kısalır; uçları yerde."""
    ball, ankle = pts[f"ball_{side}"][0], pts[f"ankle_{side}"][0]
    fwd = Vector(((ball - ankle).x * 0.2, (ball - ankle).y, 0.0)).normalized()
    out = Vector((1.0 if ball.x > 0 else -1.0, 0.0, 0.0))
    extra, edges = {}, []
    for i, (off, length, r) in enumerate(((-0.030, 0.060, 0.0150), (-0.012, 0.056, 0.0108),
                                          (0.004, 0.051, 0.0100), (0.019, 0.045, 0.0094),
                                          (0.033, 0.038, 0.0088))):
        root = ball + out * off + Vector((0.0, 0.0, -0.004))
        knuckle = root + fwd * length * 0.55 + Vector((0.0, 0.0, 0.004))
        tip = root + fwd * length
        tip.z = r + 0.002
        extra[f"t{i}a_{side}"] = (knuckle, r * 1.05)
        extra[f"t{i}b_{side}"] = (tip, r)
        edges += [(f"ball_{side}", f"t{i}a_{side}"), (f"t{i}a_{side}", f"t{i}b_{side}")]
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


def _flesh(obj):
    """Remesh (kaslar gövdeyle kaynaşır, aralarında oluk kalır) + az yumuşatma + ince yumru."""
    rem = obj.modifiers.new("Remesh", "REMESH")
    rem.mode, rem.voxel_size = "VOXEL", VOXEL
    sm = obj.modifiers.new("Smooth", "SMOOTH")       # düz yumuşatma (remesh sonrası köşe sayısı değişir)
    sm.factor, sm.iterations = 0.5, SMOOTH
    tex = bpy.data.textures.new(obj.name + "_lump", "CLOUDS")
    tex.noise_scale = 0.05
    disp = obj.modifiers.new("Lump", "DISPLACE")
    disp.texture, disp.strength, disp.mid_level = tex, 0.004, 0.5
    kit.apply_all(obj)
    for poly in obj.data.polygons:
        poly.use_smooth = True


def build_body(v, mat, pose, drape=False):
    """Gövde (kemik hacmi + ayrı kaslar, oluklu). drape=True: kaslar tek metaball (kumaş örtüsü)."""
    body = v["body"]
    pts = body_points(body, pose)
    edges = list(TORSO_EDGES)
    skin_pts = dict(pts)
    for side in ("L", "R"):
        edges += [(f"{a}_{side}", f"{b}_{side}") for a, b in LIMB_CHAIN]
        edges += [("pelvis", f"hip_{side}"), ("upchest", f"shoulder_{side}")]
        for fn in (lambda: _hand(pts, side, body["t"]), lambda: _toes(pts, side)):
            extra, e = fn()
            skin_pts.update(extra)
            edges += e
    name = "Jumper_Drape" if drape else "Jumper_Body"
    obj = kit.skin_object(name, {n: (tuple(p), r) for n, (p, r) in skin_pts.items()}, edges, mat)
    muscles = jm.build(pts, body, mat, merged=drape)
    from zombie_game import join
    obj = join([obj] + muscles, name)
    _flesh(obj)
    return obj, pts


# ---------------------------------------------------------------- çeşit

def skin_for(v, name):
    mat = kit.skin_material(name, v["tone"], v["bruise"])
    ramp = next(n for n in mat.node_tree.nodes if n.type == "VALTORGB")
    ramp.color_ramp.elements[0].position, ramp.color_ramp.elements[1].position = v["bruise_band"]
    return mat


def build_variant(v, offset_x=0.0, pose="stand"):
    before = set(bpy.data.objects)
    suffix = "_" + v["name"] + ("" if pose == "stand" else "_" + pose)
    skin = skin_for(v, "M_Jumper_Skin" + suffix)
    tooth_mat, _ = kit.material("M_Jumper_Teeth" + suffix, (0.45, 0.40, 0.28), rough=0.4)
    scalp = kit.cloth_material("M_Jumper_Scalp" + suffix, v["scalp"]) if v["scalp"] else None
    body_obj, pts = build_body(v, skin, pose)
    drape, _ = build_body(v, skin, pose, drape=True)
    drape["chest_z"], drape["belly_z"] = pts["chest"][0].z, pts["belly"][0].z
    jc.build_clothes(drape, classify_fn(pts), v, suffix)
    bpy.data.objects.remove(drape)
    head = jh.build_head(dict(v, name="Jumper" + suffix), skin, tooth_mat, scalp)
    head.location = pts["neck1"][0] + Vector((0.0, -0.022, 0.018))
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
