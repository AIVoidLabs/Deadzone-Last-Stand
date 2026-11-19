"""Yürüyen (sürü) zombi konsepti — Aşama V.5, tamamen Blender (Taha 2026-11-19). v2.

Sıradan bir insanın bozulmuş hali: sivil, işçi, büro çalışanı. İmza duruş: ağırlık sağ bacakta,
sol omuz düşük, kollar yarı kalkık ve öne uzanmaya hazır (kucaklar gibi saldırı), çene sarkık,
kafa düşük omuza yatık. Dilciden farkı: dik gövde (kambur değil), insan kafası, tek parça sarkık çene.

Gövde: iskelet noktaları + skin modifier + voxel remesh (kit), sonra diz ve baldır kütlesi.
Kıyafet ve ayakkabı: walker_clothes.py. Kafa, yüz ve saç: walker_head.py. Görseller: walker_render.py.

Çalıştırma (Blender MCP içinden):
    exec(open(r"<repo>/tools/blender/build_walker.py", encoding="utf-8").read())
Çıktı: build/blender/walker.blend (çeşitler yan yana). Konsept görselleri:
    import walker_render as wr; wr.render_all()
Bu adım yalnız konsept: iskelet, animasyon ve GLB yok.
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

importlib.reload(kit)
importlib.reload(wh)
importlib.reload(wc)
OUT_BLEND = os.path.join(REPO, "build", "blender", "walker.blend")

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
LINEUP_SPACING = 1.05
CALF = 0.014              # baldır kütlesi (m, arkaya); varyant "calf" çarpanı
KNEE = 0.006              # diz kapağı çıkıntısı (m, öne)

# Çeşitler. body: h boy, w genişlik, t uzuv kalınlığı, belly göbek, head kafa ölçeği,
# leg bacak kalınlığı çarpanı, calf baldır çarpanı.
# top: tshirt / shirt (uzun kollu) / tank / None; vest: iş yeleği; tie: kravat;
# bottom: pants / shorts (hem: paçanın kesildiği bacak oranı 0 kalça .. 1 bilek);
# shoes: renk ya da None (çıplak ayak); hair_style: walker_head.HAIR_STYLES anahtarı.
# Renkler doğrusal RGB.
VARIANTS = [
    {"name": "Office", "body": {"h": 1.00, "w": 0.98, "t": 0.95, "belly": 1.0, "head": 1.00,
                                "leg": 1.0, "calf": 1.0},
     "tone": (0.30, 0.32, 0.26), "bruise": (0.24, 0.14, 0.16),
     "top": "shirt", "top_color": (0.62, 0.66, 0.70), "blood": 0.7, "vest": None,
     "tie": (0.30, 0.02, 0.03), "bottom": "pants", "bottom_color": (0.06, 0.06, 0.07), "hem": 0.97,
     "shoes": (0.02, 0.018, 0.016), "hair": (0.035, 0.025, 0.018), "hair_style": "short",
     "seed": 0.0},
    {"name": "Worker", "body": {"h": 0.98, "w": 1.22, "t": 1.18, "belly": 1.45, "head": 1.05,
                                "leg": 1.0, "calf": 1.0},
     "tone": (0.31, 0.27, 0.22), "bruise": (0.26, 0.10, 0.12),
     "top": "tshirt", "top_color": (0.16, 0.17, 0.18), "blood": 0.4, "vest": (0.85, 0.22, 0.02),
     "tie": None, "bottom": "pants", "bottom_color": (0.05, 0.09, 0.18), "hem": 0.98,
     "shoes": (0.12, 0.06, 0.025), "hair": (0.05, 0.04, 0.03), "hair_style": "fringe",
     "seed": 3.3},
    {"name": "Skinny", "body": {"h": 1.06, "w": 0.86, "t": 0.98, "belly": 0.85, "head": 0.97,
                                "leg": 1.14, "calf": 1.5},
     "tone": (0.17, 0.15, 0.22), "bruise": (0.24, 0.05, 0.16),
     "top": "tank", "top_color": (0.45, 0.42, 0.34), "blood": 0.9, "vest": None,
     "tie": None, "bottom": "shorts", "bottom_color": (0.20, 0.17, 0.09), "hem": 0.42,
     "shoes": None, "hair": (0.035, 0.030, 0.024), "hair_style": "long", "seed": 7.1},
    {"name": "Civilian", "body": {"h": 0.90, "w": 1.06, "t": 1.05, "belly": 1.1, "head": 1.04,
                                  "leg": 1.0, "calf": 1.0},
     "tone": (0.13, 0.10, 0.08), "bruise": (0.12, 0.05, 0.06),
     "top": "tshirt", "top_color": (0.42, 0.04, 0.035), "blood": 0.3, "vest": None,
     "tie": None, "bottom": "pants", "bottom_color": (0.09, 0.14, 0.25), "hem": 0.78,
     "shoes": (0.16, 0.155, 0.14), "hair": (0.05, 0.03, 0.018), "hair_style": "sparse",
     "seed": 11.7},
]


# ---------------------------------------------------------------- gövde

def _scaled(p, r, body, limb, leg=False):
    x, y, z = p
    w, h = body["w"], body["h"]
    rr = r * (body["t"] * (body.get("leg", 1.0) if leg else 1.0) if limb else w)
    return (Vector((x * w, y * (0.6 + 0.4 * w), z * h)), rr)


def body_points(body):
    """Çeşidin gövde noktaları (dünya, karakter kökü 0'da)."""
    pts = {}
    for n, (p, r) in TORSO_POINTS.items():
        pts[n] = _scaled(p, r, body, False)
    pos, r = pts["belly"]
    pts["belly"] = (pos + Vector((0.0, -0.03 * (body["belly"] - 1.0), 0.0)), r * body["belly"] ** 0.7)
    for n, (p, r) in LIMB_POINTS.items():
        pts[n] = _scaled(p, r, body, True, n.split("_")[0] in ("hip", "knee"))
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
    shape_legs(obj, pts, body)
    segments = []
    for a, b in edges:
        key = f"{a.split('_')[0]}-{b.split('_')[0]}"
        if key in PART_CLASS:
            segments.append((PART_CLASS[key], pts[a][0], pts[b][0]))
    return obj, segments, pts


def shape_legs(obj, pts, body):
    """Sopa bacak yerine: baldır kütlesi (arkada, dizin altında), diz kapağı, ince bilek."""
    calf, knee_amt = CALF * body.get("calf", 1.0) * body["t"], KNEE * body["t"]
    legs = [(pts[f"knee_{s}"][0], pts[f"ankle_{s}"][0], pts[f"hip_{s}"][0]) for s in ("L", "R")]
    top = max(k.z for k, _a, _h in legs) + 0.12
    for vert in obj.data.vertices:
        co = vert.co
        if co.z > top:
            continue
        best = None
        for knee, ankle, hip in legs:
            for a, b, kind in ((knee, ankle, "shin"), (hip, knee, "thigh")):
                closest, t = geometry.intersect_point_line(co, a, b)
                t = min(max(t, 0.0), 1.0)
                axis_pt = a.lerp(b, t)
                d = (co - axis_pt).length
                if best is None or d < best[0]:
                    best = (d, kind, t, axis_pt, (b - a).normalized())
        _d, kind, t, axis_pt, axis = best
        radial = co - axis_pt
        if radial.length < 1e-6:
            continue
        radial.normalize()
        back = Vector((0.0, 1.0, 0.0))
        back = (back - axis * back.dot(axis)).normalized()
        facing = radial.dot(back)
        push = 0.0
        if kind == "shin":
            bulge = math.exp(-((t - 0.30) / 0.17) ** 2)
            push += calf * bulge * (0.35 + 0.65 * max(0.0, facing))
            push -= 0.25 * calf * max(0.0, (t - 0.75) / 0.25)        # bilek incelir
            push += knee_amt * math.exp(-(t / 0.08) ** 2) * max(0.0, -facing)
        else:
            push += knee_amt * math.exp(-((1.0 - t) / 0.06) ** 2) * max(0.0, -facing)
        vert.co = co + radial * push


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


# ---------------------------------------------------------------- çeşit

def build_variant(v, offset_x=0.0):
    before = set(bpy.data.objects)
    suffix = "_" + v["name"]
    skin = kit.skin_material("M_Walker_Skin" + suffix, v["tone"], v["bruise"])
    tooth_mat, _ = kit.material("M_Walker_Teeth" + suffix, (0.45, 0.40, 0.28), rough=0.4)
    style = wh.HAIR_STYLES.get(v["hair_style"])
    hair_mat = wh.hair_material("M_Walker_Hair" + suffix, v["hair"], style["rough"]) if style else None
    body_obj, segments, pts = build_body(v, skin)
    part = wc.build_clothes(body_obj, lambda co: classify(co, segments), v, suffix)
    if v["shoes"]:
        wc.build_shoes(body_obj, pts, part, v, suffix)
    wh.build_head(v, skin, tooth_mat, hair_mat, pts["neck1"][0], v["body"]["h"])
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
    scene = bpy.context.scene
    eye, target = Vector((0.0, -6.2, 1.25)), Vector((0.0, -0.2, 0.92))
    scene.camera.location = eye
    scene.camera.rotation_euler = (target - eye).to_track_quat("-Z", "Y").to_euler()
    scene.camera.data.lens = 50
    scene.render.resolution_x, scene.render.resolution_y = 1400, 1100
    os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    print("WALKER built, variants:", count)


# Modül olarak içe aktarılınca kurulum çalışmaz; exec ile çalıştırınca çalışır.
if __name__ != "build_walker":
    build()
