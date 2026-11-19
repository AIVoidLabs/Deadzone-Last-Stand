"""Dilci deneme modeli (Aşama V.3): Blender MCP ile görünüş keşfi.

Oyun modeli değil, kalite denemesi. Organik gövde: iskelet noktalarına skin modifier +
subdivision + voxel remesh + gürültülü yer değiştirme. İmza parçalar: ikiye yarılmış alt
çene, boğaz kesesi, ağızdan sarkan uzun ıslak dil.

Çalıştırma (Blender MCP içinden): exec(open(r"<repo>/tools/blender/dilci_trial.py").read())
Arka planda: blender --background --python tools/blender/dilci_trial.py
"""
import math
import os

import bmesh
import bpy
from mathutils import Vector

_HERE = globals().get("__file__", "")
REPO = os.path.abspath(os.path.join(os.path.dirname(_HERE), "..", "..")) if _HERE else ""
if not REPO or not os.path.isdir(os.path.join(REPO, "tools")):
    REPO = r"C:\Users\pekta\projeler\Deadzone-Last-Stand"
OUT_BLEND = os.path.join(REPO, "build", "blender", "dilci_trial.blend")

# Karakter -Y yönüne bakar, Z yukarı, metre.
HEAD_POS = Vector((0.0, -0.40, 1.60))
MOUTH = Vector((0.0, -0.52, 1.535))

# --- iskelet noktaları: (ad, konum, yarıçap) ---------------------------------
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
    "ankle": ((0.16, 0.02, 0.09), 0.045),
    "toe": ((0.16, -0.13, 0.03), 0.04),
    "shoulder": ((0.21, -0.10, 1.44), 0.075),
    "elbow": ((0.33, -0.06, 1.10), 0.05),
    "wrist": ((0.37, -0.20, 0.80), 0.038),
    "palm": ((0.38, -0.24, 0.72), 0.042),
}
# Uzun parmaklar (bileğe göre uç noktaları); her biri iki boğum.
FINGERS = [
    ((0.40, -0.30, 0.60), (0.41, -0.33, 0.50)),
    ((0.37, -0.31, 0.59), (0.36, -0.34, 0.48)),
    ((0.34, -0.29, 0.61), (0.32, -0.31, 0.52)),
    ((0.33, -0.25, 0.68), (0.31, -0.29, 0.62)),  # başparmak
]
BODY_EDGES = [("pelvis", "spine"), ("spine", "chest"), ("chest", "upchest"),
              ("upchest", "neck0"), ("neck0", "neck1")]
SIDE_CHAIN = [("hip", "knee"), ("knee", "ankle"), ("ankle", "toe"),
              ("shoulder", "elbow"), ("elbow", "wrist"), ("wrist", "palm")]

# Dilin yolu: ağızdan öne çıkar, göğüs önünde S çizerek bele sarkar, ucu kıvrılır.
TONGUE_PATH = [
    (0.0, -0.52, 1.535), (0.0, -0.62, 1.50), (0.035, -0.68, 1.40),
    (-0.03, -0.64, 1.28), (0.05, -0.60, 1.15), (0.01, -0.64, 1.03),
    (-0.06, -0.70, 0.94), (-0.03, -0.78, 0.90), (0.02, -0.80, 0.94),
]
TONGUE_RADIUS = 0.025


def reset_scene() -> None:
    """Sahneyi operatörsüz boşaltır (MCP bağlamında read_homefile sonrası bağlam bozuluyor)."""
    for coll in (bpy.data.objects, bpy.data.meshes, bpy.data.curves, bpy.data.armatures,
                 bpy.data.materials, bpy.data.lights, bpy.data.cameras, bpy.data.textures,
                 bpy.data.images, bpy.data.actions, bpy.data.worlds):
        for block in list(coll):
            coll.remove(block)
    bpy.context.scene.unit_settings.system = "METRIC"


def primitive(name, kind, location=(0.0, 0.0, 0.0), **kw):
    """bmesh ile ilkel ağ nesnesi (bpy.ops yerine)."""
    bm = bmesh.new()
    if kind == "sphere":
        bmesh.ops.create_uvsphere(bm, u_segments=kw.get("segments", 32),
                                  v_segments=kw.get("rings", 24), radius=kw.get("radius", 1.0))
    elif kind == "cone":
        bmesh.ops.create_cone(bm, cap_ends=True, segments=kw.get("segments", 8),
                              radius1=kw["radius1"], radius2=0.0, depth=kw["depth"])
    elif kind == "plane":
        bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=kw["size"] * 0.5)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    obj.location = location
    bpy.context.collection.objects.link(obj)
    return obj


def material(name, base, rough=0.6, sss=0.0, coat=0.0, emission=None, strength=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*base, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Subsurface Weight"].default_value = sss
    bsdf.inputs["Subsurface Radius"].default_value = (0.08, 0.03, 0.02)
    bsdf.inputs["Coat Weight"].default_value = coat
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = strength
    return mat, bsdf


def skin_material():
    """Soluk gri-yeşil ten; çürük morluklar ve oyuklarda koyulaşma (gürültü + AO)."""
    mat, bsdf = material("M_Dilci_Skin", (0.30, 0.32, 0.26), rough=0.55, sss=0.12)
    nt = mat.node_tree
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 6.0
    noise.inputs["Detail"].default_value = 8.0
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.42
    ramp.color_ramp.elements[0].color = (0.26, 0.29, 0.22, 1.0)
    ramp.color_ramp.elements[1].position = 0.68
    ramp.color_ramp.elements[1].color = (0.22, 0.13, 0.16, 1.0)
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    ao = nt.nodes.new("ShaderNodeAmbientOcclusion")
    ao.inputs["Distance"].default_value = 0.05
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    nt.links.new(ao.outputs["AO"], mix.inputs["Factor"])
    mix.inputs["A"].default_value = (0.12, 0.10, 0.10, 1.0)
    nt.links.new(ramp.outputs["Color"], mix.inputs["B"])
    # AO düşükse (oyuk) koyu, yüksekse ten rengi
    lerp = nt.nodes.new("ShaderNodeMix")
    lerp.data_type = "RGBA"
    nt.links.new(ao.outputs["AO"], lerp.inputs["Factor"])
    lerp.inputs["A"].default_value = (0.10, 0.08, 0.08, 1.0)
    nt.links.new(ramp.outputs["Color"], lerp.inputs["B"])
    nt.links.new(lerp.outputs["Result"], bsdf.inputs["Base Color"])
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.25
    vein = nt.nodes.new("ShaderNodeTexNoise")
    vein.inputs["Scale"].default_value = 40.0
    nt.links.new(vein.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def tongue_material():
    """Islak koyu pembe-mor dil: parlak kaplama, ince boğum çizgileri."""
    mat, bsdf = material("M_Dilci_Tongue", (0.30, 0.045, 0.08), rough=0.22, sss=0.25, coat=1.0)
    bsdf.inputs["Coat Roughness"].default_value = 0.04
    bsdf.inputs["Subsurface Radius"].default_value = (0.05, 0.01, 0.01)
    nt = mat.node_tree
    # koyu-açık alacalı et rengi
    tint = nt.nodes.new("ShaderNodeTexNoise")
    tint.inputs["Scale"].default_value = 25.0
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (0.18, 0.02, 0.05, 1.0)
    ramp.color_ramp.elements[1].color = (0.42, 0.10, 0.13, 1.0)
    nt.links.new(tint.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    wave = nt.nodes.new("ShaderNodeTexWave")
    wave.inputs["Scale"].default_value = 30.0
    wave.inputs["Distortion"].default_value = 6.0
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.5
    nt.links.new(wave.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def sac_material():
    """Gerilmiş, yarı saydam deri; koyu kırmızı damar ağı, içten sarı-yeşil sönük ışık."""
    mat, bsdf = material("M_Dilci_Sac", (0.40, 0.36, 0.20), rough=0.28, sss=0.6, coat=0.7,
                         emission=(0.40, 0.50, 0.08), strength=0.25)
    nt = mat.node_tree
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.feature = "DISTANCE_TO_EDGE"
    vor.inputs["Scale"].default_value = 9.0
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.0
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


def skin_object(name, points, edges, mat):
    """Nokta + kenar listesinden skin modifier'lı organik ağ; uygulanmış ve yumuşatılmış döner."""
    names = list(points)
    verts = [points[n][0] for n in names]
    index = {n: i for i, n in enumerate(names)}
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [(index[a], index[b]) for a, b in edges], [])
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    skin = obj.modifiers.new("Skin", "SKIN")
    skin.use_smooth_shade = True
    for i, n in enumerate(names):
        r = points[n][1]
        obj.data.skin_vertices[0].data[i].radius = (r, r * 0.85)
    obj.data.skin_vertices[0].data[0].use_root = True
    sub = obj.modifiers.new("Sub", "SUBSURF")
    sub.levels = 2
    obj.data.materials.append(mat)
    apply_all(obj)
    return obj


def apply_all(obj) -> None:
    """Modifier'ları değerlendirilmiş ağa çevirir (operatörsüz; MCP bağlamında da çalışır)."""
    depsgraph = bpy.context.evaluated_depsgraph_get()
    depsgraph.update()
    mesh = bpy.data.meshes.new_from_object(obj.evaluated_get(depsgraph))
    old = obj.data
    if obj.type == "MESH":
        obj.modifiers.clear()
        obj.data = mesh
        if old.users == 0:
            bpy.data.meshes.remove(old)
        return
    # eğri: ağ nesnesiyle değiştir
    name, matrix = obj.name, obj.matrix_world.copy()
    bpy.data.objects.remove(obj)
    new_obj = bpy.data.objects.new(name, mesh)
    new_obj.matrix_world = matrix
    bpy.context.collection.objects.link(new_obj)
    return new_obj


def organic_pass(obj, voxel=0.008, lump=0.006) -> None:
    """Voxel remesh ile birleşim yerlerini eritir, sonra hafif yumrulu ten."""
    rem = obj.modifiers.new("Remesh", "REMESH")
    rem.mode = "VOXEL"
    rem.voxel_size = voxel
    smooth = obj.modifiers.new("Smooth", "CORRECTIVE_SMOOTH")
    smooth.iterations = 6
    tex = bpy.data.textures.new(obj.name + "_lump", "CLOUDS")
    tex.noise_scale = 0.06
    disp = obj.modifiers.new("Lump", "DISPLACE")
    disp.texture = tex
    disp.strength = lump
    disp.mid_level = 0.5
    apply_all(obj)
    for poly in obj.data.polygons:
        poly.use_smooth = True


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
    body = skin_object("Dilci_Body", points, edges, mat)
    organic_pass(body)
    return body


METABALL_SURFACE = 0.57  # eşik 0.6'da yüzey, etki yarıçapının ~0.57 katında oluşur


def metaball_mesh(name, blobs, mat, resolution=0.0035):
    """Elipsoid kütlelerden (negatifler oyar) organik ağ: heykel yerine kütle birleştirme.
    blobs: [(merkez, (yarıçap_x, y, z), negatif_mi)]"""
    mb = bpy.data.metaballs.new(name + "_mb")
    mb.resolution = resolution
    mb.render_resolution = resolution
    for center, radii, negative in blobs:
        el = mb.elements.new(type="ELLIPSOID")
        el.co = center
        r = max(radii) / METABALL_SURFACE
        el.radius = r
        el.size_x, el.size_y, el.size_z = (radii[0] / (METABALL_SURFACE * r) * 1.0,
                                           radii[1] / (METABALL_SURFACE * r),
                                           radii[2] / (METABALL_SURFACE * r))
        el.use_negative = negative
        el.stiffness = 1.8 if not negative else 3.0
    tmp = bpy.data.objects.new(name + "_tmp", mb)
    bpy.context.collection.objects.link(tmp)
    depsgraph = bpy.context.evaluated_depsgraph_get()
    depsgraph.update()
    mesh = bpy.data.meshes.new_from_object(tmp.evaluated_get(depsgraph))
    bpy.data.objects.remove(tmp)
    bpy.data.metaballs.remove(mb)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    smooth = obj.modifiers.new("Smooth", "CORRECTIVE_SMOOTH")
    smooth.iterations = 4
    apply_all(obj)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def mirrored(center, radii, negative=False):
    x, y, z = center
    return [((x, y, z), radii, negative), ((-x, y, z), radii, negative)]


# Kafa yerel uzayı: köken boyun üstü, yüz -Y.
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
    + mirrored((0.052, -0.060, 0.012), (0.022, 0.034, 0.016))  # elmacık
    + mirrored((0.064, -0.012, -0.030), (0.018, 0.022, 0.026))  # çene menteşesi
    + mirrored((0.033, -0.106, 0.034), (0.021, 0.022, 0.017), True)  # göz çukuru
)
HEAD_TILT_DEG = -8.0
JAW_HINGE = (0.058, -0.016, -0.036)
JAW_OPEN_DEG = 44.0
JAW_SPLAY_DEG = 26.0
MOUTH_LOCAL = Vector((0.0, -0.080, -0.060))
SAC_LOCAL = Vector((0.0, -0.045, -0.115))


def build_head(mat, tooth_mat):
    """Uzun, çökük yanaklı kafatası (metaball); üst dişler damak kenarında aşağı bakar."""
    head = metaball_mesh("Dilci_Head", HEAD_BLOBS, mat)
    for i in range(7):
        a = math.radians(-62 + i * (124 / 6))
        pos = (0.037 * math.sin(a), -0.078 - 0.034 * math.cos(a), -0.046)
        length = 0.016 + 0.008 * ((i * 37) % 5) / 4
        tooth = primitive("Tooth_U", "cone", pos, radius1=0.005, depth=length)
        tooth.rotation_euler = (math.radians(180), 0.0, 0.0)
        tooth.data.materials.append(tooth_mat)
        tooth.parent = head
    head.location = HEAD_POS
    head.rotation_euler = (math.radians(HEAD_TILT_DEG), 0.0, 0.0)
    return head


def build_jaw(head, mat, tooth_mat):
    """İmza: ortadan ikiye yarılmış alt çene; yarılar menteşeden aşağı ve dışa açılır, dişli."""
    parts = []
    for sx in (1.0, -1.0):
        # yassı, bıçak gibi kemik yarısı (x ince, z yüksek)
        blobs = [((0.0, 0.0, 0.0), (0.012, 0.020, 0.026), False),
                 ((-0.012 * sx, -0.035, -0.022), (0.009, 0.028, 0.018), False),
                 ((-0.025 * sx, -0.070, -0.032), (0.008, 0.032, 0.015), False),
                 ((-0.036 * sx, -0.102, -0.036), (0.007, 0.018, 0.012), False)]
        jaw = metaball_mesh(f"Dilci_Jaw_{'L' if sx > 0 else 'R'}", blobs, mat, resolution=0.003)
        for i in range(5):
            t = i / 4.0
            pos = Vector((-0.010 * sx, -0.042, -0.014)).lerp(Vector((-0.034 * sx, -0.102, -0.030)), t)
            tooth = primitive("Tooth_L", "cone", pos, radius1=0.0045, depth=0.015 + 0.006 * (i % 2))
            tooth.rotation_euler = (math.radians(-8), math.radians(12 * sx), 0.0)
            tooth.data.materials.append(tooth_mat)
            tooth.parent = jaw
        jaw.parent = head
        jaw.location = (JAW_HINGE[0] * sx, JAW_HINGE[1], JAW_HINGE[2])
        jaw.rotation_euler = (math.radians(JAW_OPEN_DEG), math.radians(-10 * sx),
                              math.radians(JAW_SPLAY_DEG * sx))
        parts.append(jaw)
    return parts


def build_throat_sac(head, mat):
    """Boğaz kesesi: yarık çenenin arasından boyna sarkan, damarlı, içten parlayan şişlik.
    Dil burada kıvrılı durur; saldırıdan önce kese şişer (oyunda önsezi işareti)."""
    blobs = [((0.0, 0.0, 0.0), (0.048, 0.052, 0.066), False),
             ((0.022, -0.020, -0.030), (0.026, 0.026, 0.030), False),
             ((-0.020, -0.012, -0.040), (0.024, 0.024, 0.028), False),
             ((0.004, -0.030, 0.020), (0.022, 0.020, 0.022), False)]
    sac = metaball_mesh("Dilci_ThroatSac", blobs, mat, resolution=0.003)
    sac.parent = head
    sac.location = SAC_LOCAL
    return sac


def build_tongue(head, mat):
    """Dil keseden çıkar, yarık çenenin arasından sarkar; yol kafanın ağız noktasına bağlı."""
    bpy.context.view_layer.update()
    mouth = head.matrix_world @ MOUTH_LOCAL
    path = [tuple(mouth), tuple(mouth + Vector((0.0, -0.07, -0.05)))] + TONGUE_PATH[2:]
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
    # uca doğru incelme: nokta yarıçapı
    n = len(spline.points)
    for i, p in enumerate(spline.points):
        t = i / (n - 1)
        # kökte kalın (kese çıkışı), ortada ince, uçta hafif şişkin kanca ucu
        p.radius = 1.25 * (1.0 - t) ** 1.1 + 0.18 + 0.25 * math.exp(-((t - 0.88) / 0.05) ** 2)
    obj = bpy.data.objects.new("Dilci_Tongue", curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    obj = apply_all(obj)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def build_eyes(head, mat):
    """Çukurun dibinde küçük, sönük parlayan gözler."""
    eyes = []
    for sx in (1.0, -1.0):
        eye = primitive(f"Dilci_Eye_{'L' if sx > 0 else 'R'}", "sphere", (0.033 * sx, -0.092, 0.033),
                        segments=16, rings=12, radius=0.0065)
        eye.data.materials.append(mat)
        eye.parent = head
        eyes.append(eye)
    return eyes


def build_pants(mat):
    """Yırtık koyu pantolon: bacak zincirinin biraz kalın kopyası, dizin altında biter."""
    points = {"waist": ((0.0, 0.02, 1.02), 0.152)}
    edges = []
    for side, sx in (("L", 1.0), ("R", -1.0)):
        points[f"hip_{side}"] = ((0.115 * sx, 0.02, 0.92), 0.108)
        points[f"knee_{side}"] = ((0.17 * sx, -0.09, 0.52), 0.074)
        points[f"shin_{side}"] = ((0.165 * sx, -0.04, 0.30), 0.062)
        edges += [("waist", f"hip_{side}"), (f"hip_{side}", f"knee_{side}"), (f"knee_{side}", f"shin_{side}")]
    pants = skin_object("Dilci_Pants", points, edges, mat)
    organic_pass(pants, voxel=0.008, lump=0.004)
    return pants


def setup_look(target_height=1.2) -> None:
    scene = bpy.context.scene
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (0.02, 0.022, 0.028, 1.0)
    scene.world = world
    ground, _ = material("M_Ground", (0.05, 0.05, 0.055), rough=0.9)
    primitive("Ground", "plane", size=40).data.materials.append(ground)
    try:
        scene.view_settings.view_transform = "AgX"
    except TypeError as err:
        print("view transform:", err)

    def area(name, loc, energy, color, size):
        light = bpy.data.lights.new(name, "AREA")
        light.energy = energy
        light.color = color
        light.size = size
        obj = bpy.data.objects.new(name, light)
        obj.location = loc
        scene.collection.objects.link(obj)
        direction = Vector((0, -0.3, target_height)) - Vector(loc)
        obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

    area("Key", (1.6, -2.0, 2.4), 160, (1.0, 0.85, 0.7), 1.2)
    area("Rim", (-1.4, 1.6, 2.2), 260, (0.45, 0.75, 1.0), 0.8)
    area("Fill", (-1.8, -1.5, 1.0), 25, (0.7, 0.75, 0.9), 2.0)
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.lens = 55
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    cam.location = (1.5, -3.2, 1.55)
    cam.rotation_euler = (Vector((0, -0.3, 1.05)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    scene.render.resolution_x = 1080
    scene.render.resolution_y = 1350


def build() -> None:
    reset_scene()
    skin = skin_material()
    tongue_mat = tongue_material()
    sac_mat = sac_material()
    tooth_mat, _ = material("M_Dilci_Teeth", (0.55, 0.48, 0.32), rough=0.4)
    eye_mat, _ = material("M_Dilci_Eye", (0.8, 0.75, 0.3), rough=0.2, emission=(1.0, 0.7, 0.2), strength=2.5)
    pants_mat, _ = material("M_Dilci_Pants", (0.06, 0.07, 0.09), rough=0.85)
    build_body(skin)
    build_pants(pants_mat)
    head = build_head(skin, tooth_mat)
    build_jaw(head, skin, tooth_mat)
    build_throat_sac(head, sac_mat)
    build_eyes(head, eye_mat)
    build_tongue(head, tongue_mat)
    setup_look()
    os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    tris = sum(len(o.data.polygons) for o in bpy.data.objects if o.type == "MESH")
    print("DILCI built, faces:", tris)


build()
