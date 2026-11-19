"""Dilci (dil zombisi) modeli — Aşama V, tamamen Blender (Taha 2026-11-19).

Gövde: iskelet noktaları + skin modifier + voxel remesh + yumrulu ten. Kafa ve çene: metaball.
İmza: ortadan yarılmış dişli alt çene, yarıkların arasında damarlı boğaz kesesi (dil burada durur,
saldırı öncesi şişer), ağızdan sarkan ıslak kanca uçlu dil. Kıyafet gövde yüzeyinden üretilir
(yırtık etek ve delikler); renk/kıyafet çeşitleri `VARIANTS` tablosunda.

Çalıştırma (Blender MCP içinden):
    exec(open(r"<repo>/tools/blender/build_dilci.py", encoding="utf-8").read())
Çıktı: build/blender/dilci.blend (çeşitler yan yana). Oyun için iskelet + dışa aktarım V.4'te.
"""
import importlib
import math
import os
import sys

import bpy
from mathutils import Vector, noise

_HERE = globals().get("__file__", "")
REPO = os.path.abspath(os.path.join(os.path.dirname(_HERE), "..", "..")) if _HERE else ""
if not REPO or not os.path.isdir(os.path.join(REPO, "tools")):
    REPO = r"C:\Users\pekta\projeler\Deadzone-Last-Stand"
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import zombie_kit as kit  # noqa: E402

importlib.reload(kit)
OUT_BLEND = os.path.join(REPO, "build", "blender", "dilci.blend")

# Karakter -Y yönüne bakar, Z yukarı, metre.
HEAD_POS = Vector((0.0, -0.40, 1.60))

BODY_POINTS = {
    "pelvis": ((0.0, 0.02, 0.96), 0.15),
    "spine": ((0.0, 0.03, 1.15), 0.135),
    "chest": ((0.0, -0.04, 1.33), 0.16),
    "upchest": ((0.0, -0.13, 1.46), 0.13),
    "neck0": ((0.0, -0.23, 1.53), 0.065),
    "neck1": ((0.0, -0.32, 1.57), 0.055),
}
SIDE_POINTS = {
    "hip": ((0.12, 0.02, 0.93), 0.10),
    "knee": ((0.17, -0.09, 0.52), 0.065),
    "ankle": ((0.16, 0.02, 0.10), 0.042),
    "heel": ((0.16, 0.06, 0.035), 0.036),
    "ball": ((0.165, -0.09, 0.03), 0.036),
    "toe": ((0.17, -0.17, 0.022), 0.026),
    "shoulder": ((0.21, -0.10, 1.44), 0.075),
    "elbow": ((0.33, -0.06, 1.10), 0.05),
    "wrist": ((0.37, -0.20, 0.80), 0.038),
    "palm": ((0.38, -0.24, 0.72), 0.042),
}
# Uzun parmaklar: (orta boğum, uç); son satır başparmak.
FINGERS = [
    ((0.40, -0.30, 0.60), (0.41, -0.33, 0.50)),
    ((0.37, -0.31, 0.59), (0.36, -0.34, 0.48)),
    ((0.34, -0.29, 0.61), (0.32, -0.31, 0.52)),
    ((0.33, -0.25, 0.68), (0.31, -0.29, 0.62)),
]
BODY_EDGES = [("pelvis", "spine"), ("spine", "chest"), ("chest", "upchest"),
              ("upchest", "neck0"), ("neck0", "neck1")]
SIDE_CHAIN = [("hip", "knee"), ("knee", "ankle"), ("ankle", "heel"), ("ankle", "ball"), ("ball", "toe"),
              ("shoulder", "elbow"), ("elbow", "wrist"), ("wrist", "palm")]

HEAD_BLOBS = (
    [((0.0, 0.015, 0.05), (0.080, 0.100, 0.084), False),       # kafatası
     ((0.0, 0.065, 0.03), (0.062, 0.058, 0.060), False),       # art kafa
     ((0.0, -0.074, 0.064), (0.070, 0.026, 0.020), False),     # kaş çıkıntısı
     ((0.0, -0.086, -0.022), (0.046, 0.044, 0.028), False),    # üst çene
     ((0.0, -0.110, -0.022), (0.028, 0.020, 0.022), False),    # ağız ucu
     ((0.0, -0.116, 0.016), (0.011, 0.012, 0.022), False),     # burun kemiği
     ((0.0, 0.020, -0.060), (0.040, 0.044, 0.060), False),     # boyun bağı
     ((0.0, -0.128, 0.004), (0.010, 0.012, 0.014), True),      # burun deliği
     ((0.0, -0.092, -0.052), (0.034, 0.040, 0.020), True)]     # damak boşluğu
    + kit.mirrored((0.052, -0.060, 0.012), (0.022, 0.034, 0.016))  # elmacık
    + kit.mirrored((0.064, -0.012, -0.030), (0.018, 0.022, 0.026))  # çene menteşesi
    + kit.mirrored((0.033, -0.106, 0.034), (0.021, 0.022, 0.017), True)  # göz çukuru
)
HEAD_TILT_DEG = -8.0
JAW_HINGE = (0.058, -0.016, -0.036)
JAW_OPEN_DEG = 44.0
JAW_SPLAY_DEG = 26.0
MOUTH_LOCAL = Vector((0.0, -0.080, -0.060))
SAC_LOCAL = Vector((0.0, -0.045, -0.115))
# Dilin yolu (ilk iki nokta ağızdan hesaplanır): göğüs önünde S çizip bele sarkar.
TONGUE_PATH = [
    (0.035, -0.68, 1.40), (-0.03, -0.64, 1.28), (0.05, -0.60, 1.15), (0.01, -0.64, 1.03),
    (-0.06, -0.70, 0.94), (-0.03, -0.78, 0.90), (0.02, -0.80, 0.94),
]
TONGUE_RADIUS = 0.025

# Çeşitler: ten, üst (tshirt / tank / None), alt; renkler doğrusal RGB.
VARIANTS = [
    {"name": "A", "tone": (0.26, 0.29, 0.22), "bruise": (0.22, 0.13, 0.16),
     "top": "tshirt", "top_color": (0.15, 0.045, 0.04), "blood": 0.5,
     "pants_color": (0.07, 0.09, 0.13), "pants_hem": 0.30, "seed": 0.0},
    {"name": "B", "tone": (0.30, 0.27, 0.29), "bruise": (0.25, 0.12, 0.12),
     "top": "tank", "top_color": (0.40, 0.38, 0.32), "blood": 0.8,
     "pants_color": (0.17, 0.14, 0.08), "pants_hem": 0.46, "seed": 3.3},
    {"name": "C", "tone": (0.12, 0.14, 0.14), "bruise": (0.14, 0.07, 0.09),
     "top": None, "top_color": None, "blood": 0.0,
     "pants_color": (0.035, 0.035, 0.04), "pants_hem": 0.18, "seed": 7.1},
]
LINEUP_SPACING = 1.15


def tongue_material(name):
    """Islak koyu et kırmızısı dil: parlak kaplama, alacalı renk, ince boğum çizgileri."""
    mat, bsdf = kit.material(name, (0.30, 0.045, 0.08), rough=0.22, sss=0.25, coat=1.0)
    bsdf.inputs["Coat Roughness"].default_value = 0.04
    bsdf.inputs["Subsurface Radius"].default_value = (0.05, 0.01, 0.01)
    nt = mat.node_tree
    ramp = kit._mottle(nt, 25.0, (0.42, 0.10, 0.13), (0.18, 0.02, 0.05), low=0.0, high=1.0)
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    wave = nt.nodes.new("ShaderNodeTexWave")
    wave.inputs["Scale"].default_value = 30.0
    wave.inputs["Distortion"].default_value = 6.0
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.5
    nt.links.new(wave.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def sac_material(name):
    """Gerilmiş, yarı saydam deri; koyu kırmızı damar ağı, içten sarı-yeşil sönük ışık."""
    mat, bsdf = kit.material(name, (0.40, 0.36, 0.20), rough=0.28, sss=0.6, coat=0.7,
                             emission=(0.40, 0.50, 0.08), strength=0.25)
    nt = mat.node_tree
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.feature = "DISTANCE_TO_EDGE"
    vor.inputs["Scale"].default_value = 9.0
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (0.22, 0.03, 0.05, 1.0)
    ramp.color_ramp.elements[1].position = 0.06
    ramp.color_ramp.elements[1].color = (0.42, 0.37, 0.20, 1.0)
    nt.links.new(vor.outputs["Distance"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.4
    bump.invert = True
    nt.links.new(ramp.outputs["Color"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def build_body(mat):
    points = dict(BODY_POINTS)
    edges = list(BODY_EDGES)
    for side, sx in (("L", 1.0), ("R", -1.0)):
        for n, (p, r) in SIDE_POINTS.items():
            points[f"{n}_{side}"] = ((p[0] * sx, p[1], p[2]), r)
        edges += [(f"{a}_{side}", f"{b}_{side}") for a, b in SIDE_CHAIN]
        edges += [("pelvis", f"hip_{side}"), ("upchest", f"shoulder_{side}")]
        for fi, (mid, tip) in enumerate(FINGERS):
            points[f"f{fi}a_{side}"] = ((mid[0] * sx, mid[1], mid[2]), 0.014)
            points[f"f{fi}b_{side}"] = ((tip[0] * sx, tip[1], tip[2]), 0.008)
            edges += [(f"palm_{side}", f"f{fi}a_{side}"), (f"f{fi}a_{side}", f"f{fi}b_{side}")]
    body = kit.skin_object("Dilci_Body", points, edges, mat)
    kit.organic_pass(body)
    return body


def build_head(mat, tooth_mat):
    """Uzun, çökük yanaklı kafatası (metaball); üst dişler damak kenarında aşağı bakar."""
    head = kit.metaball_mesh("Dilci_Head", HEAD_BLOBS, mat)
    for i in range(7):
        a = math.radians(-62 + i * (124 / 6))
        pos = (0.037 * math.sin(a), -0.078 - 0.034 * math.cos(a), -0.046)
        length = 0.016 + 0.008 * ((i * 37) % 5) / 4
        tooth = kit.primitive("Tooth_U", "cone", pos, radius1=0.005, depth=length)
        tooth.rotation_euler = (math.radians(180), 0.0, 0.0)
        tooth.data.materials.append(tooth_mat)
        tooth.parent = head
    head.location = HEAD_POS
    head.rotation_euler = (math.radians(HEAD_TILT_DEG), 0.0, 0.0)
    return head


def build_jaw(head, mat, tooth_mat):
    """İmza: ortadan ikiye yarılmış alt çene; yarılar menteşeden aşağı ve dışa açılır, dişli."""
    for sx in (1.0, -1.0):
        blobs = [((0.0, 0.0, 0.0), (0.012, 0.020, 0.026), False),
                 ((-0.012 * sx, -0.035, -0.022), (0.009, 0.028, 0.018), False),
                 ((-0.025 * sx, -0.070, -0.032), (0.008, 0.032, 0.015), False),
                 ((-0.036 * sx, -0.102, -0.036), (0.007, 0.018, 0.012), False)]
        jaw = kit.metaball_mesh(f"Dilci_Jaw_{'L' if sx > 0 else 'R'}", blobs, mat, resolution=0.003)
        for i in range(5):
            pos = Vector((-0.010 * sx, -0.042, -0.014)).lerp(Vector((-0.034 * sx, -0.102, -0.030)), i / 4.0)
            tooth = kit.primitive("Tooth_L", "cone", pos, radius1=0.0045, depth=0.015 + 0.006 * (i % 2))
            tooth.rotation_euler = (math.radians(-8), math.radians(12 * sx), 0.0)
            tooth.data.materials.append(tooth_mat)
            tooth.parent = jaw
        jaw.parent = head
        jaw.location = (JAW_HINGE[0] * sx, JAW_HINGE[1], JAW_HINGE[2])
        jaw.rotation_euler = (math.radians(JAW_OPEN_DEG), math.radians(-10 * sx),
                              math.radians(JAW_SPLAY_DEG * sx))


# Kese biçimi: "sac" sarı sarkan kese (ilk tasarım), "throat" tenle bütün şişkin gırtlak,
# "none" yok (önsezi yalnız gövde, çene ve dil ucuyla).
SAC_STYLE = "throat"  # Taha 2026-11-19: B (sarı kese beğenilmedi)
THROAT_LOCAL = Vector((0.0, 0.012, -0.100))


def build_throat_sac(head, mat, style=None):
    """Boğaz: dil burada kıvrılı durur; saldırıdan önce şişer (oyunda önsezi işareti)."""
    style = style or SAC_STYLE
    if style == "none":
        return None
    if style == "throat":
        # gırtlağa gömülü, boyun boyunca uzanan yumuşak şişlik; çenenin altından taşmaz
        blobs = [((0.0, 0.0, 0.0), (0.032, 0.030, 0.048), False),
                 ((0.0, 0.022, -0.038), (0.028, 0.027, 0.036), False),
                 ((0.015, -0.008, -0.010), (0.016, 0.016, 0.021), False),
                 ((-0.013, -0.007, -0.016), (0.015, 0.015, 0.019), False)]
        location = THROAT_LOCAL
    else:
        blobs = [((0.0, 0.0, 0.0), (0.048, 0.052, 0.066), False),
                 ((0.022, -0.020, -0.030), (0.026, 0.026, 0.030), False),
                 ((-0.020, -0.012, -0.040), (0.024, 0.024, 0.028), False),
                 ((0.004, -0.030, 0.020), (0.022, 0.020, 0.022), False)]
        location = SAC_LOCAL
    sac = kit.metaball_mesh("Dilci_ThroatSac", blobs, mat, resolution=0.0025)
    sac.parent = head
    sac.location = location
    return sac


def throat_material(name, tone):
    """Tenle aynı tonda, gerilmiş ve hafif ıslak gırtlak; mor-kırmızı damar ağı, parıltı yok."""
    skin = tuple(c * 0.92 for c in tone)
    mat, bsdf = kit.material(name, skin, rough=0.38, sss=0.3, coat=0.3)
    nt = mat.node_tree
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.feature = "DISTANCE_TO_EDGE"
    vor.inputs["Scale"].default_value = 11.0
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (0.20, 0.05, 0.08, 1.0)
    ramp.color_ramp.elements[1].position = 0.05
    ramp.color_ramp.elements[1].color = (*skin, 1.0)
    nt.links.new(vor.outputs["Distance"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def build_tongue(head, mat):
    """Keseden çıkıp yarık çenenin arasından sarkan, incelen, kanca uçlu dil."""
    bpy.context.view_layer.update()
    mouth = head.matrix_world @ MOUTH_LOCAL
    path = [tuple(mouth), tuple(mouth + Vector((0.0, -0.07, -0.05)))] + TONGUE_PATH
    curve = bpy.data.curves.new("Dilci_Tongue", "CURVE")
    curve.dimensions = "3D"
    spline = curve.splines.new("NURBS")
    spline.points.add(len(path) - 1)
    for p, co in zip(spline.points, path):
        p.co = (*co, 1.0)
    spline.use_endpoint_u = True
    spline.order_u = 4
    curve.bevel_depth = TONGUE_RADIUS
    curve.bevel_resolution = 6
    curve.resolution_u = 24
    n = len(spline.points)
    for i, p in enumerate(spline.points):
        t = i / (n - 1)
        p.radius = 1.25 * (1.0 - t) ** 1.1 + 0.18 + 0.25 * math.exp(-((t - 0.88) / 0.05) ** 2)
    obj = bpy.data.objects.new("Dilci_Tongue", curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    obj = kit.apply_all(obj)
    for poly in obj.data.polygons:
        poly.use_smooth = True


def build_eyes(head, mat):
    for sx in (1.0, -1.0):
        eye = kit.primitive(f"Dilci_Eye_{'L' if sx > 0 else 'R'}", "sphere", (0.033 * sx, -0.092, 0.033),
                            segments=16, rings=12, radius=0.0065)
        eye.data.materials.append(mat)
        eye.parent = head


def _collar(co):
    return (co - Vector((0.0, -0.20, 1.53))).length < 0.085 or co.z > 1.56


def keep_tshirt(co):
    if _collar(co) or co.z < 0.95:
        return False
    if abs(co.x) < 0.2:
        return True
    # kısa yen: kolun üst kısmı, yırtık kenarlı
    return abs(co.x) < 0.34 and co.z > 1.26 + 0.035 * noise.noise(co * 14.0)


def keep_tank(co):
    if _collar(co) or co.z < 0.95:
        return False
    return abs(co.x) < 0.165 - 0.03 * max(0.0, co.z - 1.38) / 0.1


def keep_pants(co):
    return abs(co.x) < 0.27 and co.z < 1.04


def build_clothes(body, v, suffix):
    if v["top"]:
        mat = kit.cloth_material("M_Dilci_Top" + suffix, v["top_color"], blood=v["blood"])
        keep = keep_tshirt if v["top"] == "tshirt" else keep_tank
        kit.garment(body, "Dilci_Top", keep, mat, hems=[(2, 1.02, 1.0, 0.04, 9.0)],
                    holes=0.35, seed=v["seed"])
    mat = kit.cloth_material("M_Dilci_Pants" + suffix, v["pants_color"], stain=(0.05, 0.04, 0.03))
    kit.garment(body, "Dilci_Pants", keep_pants, mat, offset=0.008,
                hems=[(2, v["pants_hem"], 1.0, 0.045, 10.0)], holes=0.25, seed=v["seed"] + 1.0)


def build_sac_gallery() -> None:
    """Kese biçimleri yan yana (aynı çeşit A, kafa yakın çekim için): sac | throat | none."""
    kit.reset_scene()
    for i, style in enumerate(("sac", "throat", "none")):
        v = dict(VARIANTS[0], name="A" + style, sac_style=style)
        build_variant(v, (i - 1) * 0.75)
    kit.setup_look()


def build_variant(v, offset_x, with_tongue=True):
    """Bir çeşidi kurar, kök nesneleri bir boşluğa bağlayıp yana kaydırır.
    Oyunda dil yordamsal (TongueRope) olduğu için oyun ağında with_tongue=False."""
    before = set(bpy.data.objects)
    suffix = "_" + v["name"]
    skin = kit.skin_material("M_Dilci_Skin" + suffix, v["tone"], v["bruise"])
    tooth_mat, _ = kit.material("M_Dilci_Teeth" + suffix, (0.55, 0.48, 0.32), rough=0.4)
    eye_mat, _ = kit.material("M_Dilci_Eye" + suffix, (0.8, 0.75, 0.3), rough=0.2,
                              emission=(1.0, 0.7, 0.2), strength=2.5)
    body = build_body(skin)
    build_clothes(body, v, suffix)
    head = build_head(skin, tooth_mat)
    build_jaw(head, skin, tooth_mat)
    style = v.get("sac_style", SAC_STYLE)
    sac_mat = throat_material("M_Dilci_Throat" + suffix, v["tone"]) if style == "throat" \
        else sac_material("M_Dilci_Sac" + suffix)
    build_throat_sac(head, sac_mat, style)
    build_eyes(head, eye_mat)
    if with_tongue:
        build_tongue(head, tongue_material("M_Dilci_Tongue" + suffix))
    created = list(set(bpy.data.objects) - before)
    root = bpy.data.objects.new("Dilci_" + v["name"], None)
    bpy.context.collection.objects.link(root)
    for obj in created:
        if obj.parent is None:
            obj.parent = root
    root.location.x = offset_x
    return root, created


def build() -> None:
    kit.reset_scene()
    count = len(VARIANTS)
    for i, v in enumerate(VARIANTS):
        build_variant(v, (i - (count - 1) / 2) * LINEUP_SPACING)
    kit.setup_look()
    cam = bpy.context.scene.camera
    cam.location = (2.4, -5.6, 1.75)
    cam.rotation_euler = (Vector((0.0, -0.3, 0.95)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.render.resolution_x = 1800
    bpy.context.scene.render.resolution_y = 1100
    os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    faces = sum(len(o.data.polygons) for o in bpy.data.objects if o.type == "MESH")
    print("DILCI built, variants:", count, "faces:", faces)


# Modül olarak içe aktarılınca (dilci_game.py) kurulum çalışmaz; exec ile çalıştırınca çalışır.
if __name__ != "build_dilci":
    build()
