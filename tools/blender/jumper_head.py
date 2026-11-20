"""Zıplayan v2 kafası: kaba, öne çıkık insan yüzü (walker_head'den ayrı).

build_jumper.py içe aktarır. Kafa yerel uzayı: köken boyun üstü, yüz -Y, Z yukarı, metre.
Yürüyen sıska ve çökük; zıplayan kaba ve hırlayan: alçak geniş kafatası, raf gibi kaş kemeri,
geniş elmacık ve elmacık kavsi, yassı geniş burun, öne çıkık üst çene, kalın köşeli alt çene,
derin göz çukurunda küçük sarımsı gözler, kalın boyun. Ağız içi koyu kırmızı-kahve kabuk + dil
(kara top değil), üst dişler açıkta (hırlama).
"""
import math

import bmesh
import bpy
from mathutils import Vector

import zombie_kit as kit

HEAD_BLOBS = (
    [((0.0, 0.020, 0.066), (0.074, 0.084, 0.072), False),     # kafatası (alçak, geniş)
     ((0.0, 0.058, 0.048), (0.064, 0.054, 0.060), False),     # art kafa
     ((0.0, -0.066, 0.080), (0.054, 0.016, 0.013), False),    # kaş kemeri (raf)
     ((0.0, -0.064, 0.018), (0.040, 0.036, 0.036), False),    # öne çıkık üst çene / orta yüz
     ((0.0, -0.098, 0.046), (0.014, 0.012, 0.020), False),    # burun sırtı (yassı)
     ((0.0, -0.094, 0.026), (0.020, 0.013, 0.010), False),    # burun ucu (geniş)
     ((0.0, 0.020, -0.034), (0.054, 0.052, 0.062), False),    # kalın boyun bağı
     ((0.0, -0.092, -0.010), (0.034, 0.036, 0.018), True)]    # ağız açıklığı
    + kit.mirrored((0.030, -0.074, 0.078), (0.025, 0.015, 0.013))   # kaş kemeri yanları
    + kit.mirrored((0.048, -0.054, 0.040), (0.018, 0.018, 0.012))   # elmacık kemiği
    + kit.mirrored((0.064, -0.020, 0.040), (0.010, 0.030, 0.008))   # elmacık kavsi
    + kit.mirrored((0.014, -0.092, 0.030), (0.010, 0.010, 0.009))   # burun kanadı
    + kit.mirrored((0.056, -0.010, 0.000), (0.014, 0.018, 0.022))   # çene menteşesi
    + kit.mirrored((0.076, 0.006, 0.036), (0.007, 0.014, 0.020))    # kulak
    + kit.mirrored((0.024, -0.082, 0.004), (0.016, 0.014, 0.010))   # üst dudak yanı (hırlama)
    + kit.mirrored((0.030, -0.088, 0.054), (0.018, 0.020, 0.014), True)  # göz çukuru (derin)
    + kit.mirrored((0.074, -0.030, 0.072), (0.010, 0.018, 0.016), True)  # çökük şakak
    + kit.mirrored((0.050, -0.072, 0.012), (0.012, 0.016, 0.014), True)  # yanak altı oyuğu
)
JAW_HINGE = Vector((0.0, -0.012, -0.006))
JAW_BLOBS = (kit.mirrored((0.052, -0.004, -0.014), (0.011, 0.016, 0.030))   # ramus
             + kit.mirrored((0.038, -0.050, -0.048), (0.013, 0.030, 0.015))  # çene gövdesi
             + kit.mirrored((0.050, -0.016, -0.046), (0.012, 0.014, 0.013))  # köşe (gonion)
             + [((0.0, -0.080, -0.054), (0.030, 0.018, 0.020), False)])     # kare çene ucu
JAW_OPEN_DEG = 22.0
EYE_POS = Vector((0.030, -0.074, 0.052))
EYE_RADIUS = 0.0086
EYE_COLOR = (0.55, 0.42, 0.06)          # donuk sarı; Godot'ta az parıltı
MOUTH_CENTER = Vector((0.0, -0.054, -0.030))
MOUTH_RADII = Vector((0.040, 0.032, 0.036))
MOUTH_FRONT = (0.060, 0.015, 0.012)
MOUTH_BACK = (0.012, 0.0035, 0.003)
TONGUE_POS = (0.0, -0.046, -0.040)
TONGUE_RADII = (0.018, 0.022, 0.0045)
TONGUE_COLOR = (0.055, 0.015, 0.013)
GUM_COLOR = (0.13, 0.03, 0.03)


def _scaled(blobs, s):
    return [(tuple(Vector(c) * s), tuple(r * s for r in rr), neg) for c, rr, neg in blobs]


def _socket_floor(head, guess, radius):
    hit, loc, _n, _i = head.ray_cast(Vector((guess.x, -0.5, guess.z)), Vector((0.0, 1.0, 0.0)))
    return Vector((guess.x, loc.y + radius * 0.45, guess.z)) if hit else guess


def _tooth(name, pos, r, depth, down, mat, parent, tilt=0.0):
    tooth = kit.primitive(name, "cone", pos, radius1=r, depth=depth, segments=6)
    tooth.rotation_euler = (math.radians(180.0 if down else 0.0) + tilt, 0.0, 0.0)
    tooth.data.materials.append(mat)
    tooth.parent = parent
    return tooth


def build_teeth(head, jaw, s, mat, gum_mat):
    """Üst sıra açıkta (hırlama): 8 düzensiz diş + diş eti şeridi; alt sıra 6 diş."""
    gum = kit.primitive("Jumper_Gum", "sphere", Vector((0.0, -0.072, -0.006)) * s,
                        segments=16, rings=6, radius=1.0)
    gum.scale = Vector((0.033, 0.026, 0.0075)) * s
    gum.data.materials.append(gum_mat)
    gum.parent = head
    for i in range(8):
        a = math.radians(-63 + i * 18)
        long = 1.35 if i in (1, 6) else 1.0           # köpek dişleri
        pos = Vector((0.031 * math.sin(a), -0.074 - 0.024 * math.cos(a), -0.014)) * s
        _tooth("Jumper_ToothU", pos, 0.0052 * s, 0.014 * s * long, True, mat, head)
    for i in range(6):
        a = math.radians(-50 + i * 20)
        pos = Vector((0.029 * math.sin(a), -0.076 - 0.010 * math.cos(a), -0.040)) * s
        _tooth("Jumper_ToothL", pos, 0.005 * s, 0.012 * s, False, mat, jaw)


def mouth_cavity(head, jaw, s, mat, tongue_mat):
    """Dişlerin arkasında iç bükey kabuk (arka yarı elipsoit, normaller içe) + çene tabanında dil."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=18, v_segments=10, radius=1.0)
    bmesh.ops.delete(bm, geom=[vt for vt in bm.verts if vt.co.y < -0.05], context="VERTS")
    for vt in bm.verts:
        vt.co = (Vector((vt.co.x * MOUTH_RADII.x, vt.co.y * MOUTH_RADII.y, vt.co.z * MOUTH_RADII.z))
                 + MOUTH_CENTER) * s
    bmesh.ops.reverse_faces(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("Jumper_Mouth")
    bm.to_mesh(mesh)
    bm.free()
    cavity = bpy.data.objects.new("Jumper_Mouth", mesh)
    bpy.context.collection.objects.link(cavity)
    cavity.data.materials.append(mat)
    cavity.parent = head
    tongue = kit.primitive("Jumper_Tongue", "sphere", Vector(TONGUE_POS) * s, segments=12, rings=6, radius=1.0)
    tongue.scale = Vector(TONGUE_RADII) * s
    tongue.data.materials.append(tongue_mat)
    tongue.parent = jaw
    for obj in (cavity, tongue):
        for poly in obj.data.polygons:
            poly.use_smooth = True


def mouth_material(name, s):
    """Ağız içi: önde koyu kırmızı-kahve, derinlikle (yerel +Y) koyulaşır."""
    mat, bsdf = kit.material(name, MOUTH_FRONT, rough=0.45)
    nt = mat.node_tree
    coord, sep = nt.nodes.new("ShaderNodeTexCoord"), nt.nodes.new("ShaderNodeSeparateXYZ")
    rng, ramp = nt.nodes.new("ShaderNodeMapRange"), nt.nodes.new("ShaderNodeValToRGB")
    rng.inputs["From Min"].default_value = (MOUTH_CENTER.y - MOUTH_RADII.y * 0.2) * s
    rng.inputs["From Max"].default_value = (MOUTH_CENTER.y + MOUTH_RADII.y) * s
    ramp.color_ramp.elements[0].color = (*MOUTH_FRONT, 1.0)
    ramp.color_ramp.elements[1].position = 0.85
    ramp.color_ramp.elements[1].color = (*MOUTH_BACK, 1.0)
    nt.links.new(coord.outputs["Object"], sep.inputs["Vector"])
    nt.links.new(sep.outputs["Y"], rng.inputs["Value"])
    nt.links.new(rng.outputs["Result"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def build_head(v, skin, tooth_mat, scalp_mat=None):
    """Kafa + çene + gözler + ağız. Dönüş: kafa nesnesi (konumu çağıran verir)."""
    s, name = v["body"]["head"], v["name"]
    head = kit.metaball_mesh("Jumper_Head", _scaled(HEAD_BLOBS, s), skin, resolution=0.0030)
    if scalp_mat is not None:            # saç: kafa derisinin tepesine ayrı yuva (oyunda renk bölgesi)
        head.data.materials.append(scalp_mat)
        for poly in head.data.polygons:
            c = poly.center / s
            if c.z > 0.068 - 0.35 * max(0.0, c.y + 0.02) and c.y > -0.050:
                poly.material_index = 1
    eye_mat, _ = kit.material("M_Jumper_Eye_" + name, EYE_COLOR, rough=0.35)
    for sx in (1.0, -1.0):
        pos = _socket_floor(head, Vector((EYE_POS.x * sx, EYE_POS.y, EYE_POS.z)) * s, EYE_RADIUS * s)
        eye = kit.primitive("Jumper_Eye", "sphere", pos, segments=10, rings=6, radius=EYE_RADIUS * s)
        eye.data.materials.append(eye_mat)
        eye.parent = head
    jaw = kit.metaball_mesh("Jumper_Jaw", _scaled(JAW_BLOBS, s), skin, resolution=0.003)
    jaw.parent = head
    jaw.location = JAW_HINGE * s
    jaw.rotation_euler = (math.radians(JAW_OPEN_DEG), 0.0, 0.0)
    gum_mat, _ = kit.material("M_Jumper_Gum_" + name, GUM_COLOR, rough=0.5)
    build_teeth(head, jaw, s, tooth_mat, gum_mat)
    tongue_mat, _ = kit.material("M_Jumper_Tongue_" + name, TONGUE_COLOR, rough=0.5)
    mouth_cavity(head, jaw, s, mouth_material("M_Jumper_Mouth_" + name, s), tongue_mat)
    return head
