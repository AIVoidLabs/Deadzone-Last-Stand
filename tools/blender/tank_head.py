"""Tank zombisinin kendi kafası (V.5 v2): ağır kaş kemeri, geniş elmacık, kare çene, alt köpek dişleri.

build_tank.py içe aktarır. walker_head'in kafası kullanılmaz; yalnız göz malzemesi ve saç (üslup verisi)
oradan gelir. Kafa yerel uzayı: köken boyun üstü, yüz -Y, Z yukarı, metre (ölçek öncesi).
Yüz kil gibi durmasın diye: kütleler arasında oyuklar (göz çukuru, elmacık altı, burun-dudak kıvrımı),
alında kırışık, ağızda koyu kırmızı iç boşluk (top değil) ve yassı dil.
"""
import math
import random

import bmesh
import bpy
from mathutils import Vector

import walker_head as wh
import zombie_kit as kit

M = kit.mirrored
HEAD_BLOBS = (
    [((0.0, 0.016, 0.058), (0.084, 0.088, 0.068), False),     # alçak, geniş kafatası
     ((0.0, 0.052, 0.034), (0.074, 0.060, 0.064), False),     # art kafa
     ((0.0, 0.040, -0.032), (0.078, 0.066, 0.064), False),    # kalın ense
     ((0.0, -0.070, 0.080), (0.070, 0.024, 0.020), False),    # kaş kemeri (raf)
     ((0.0, -0.060, 0.030), (0.044, 0.032, 0.036), False),    # orta yüz
     ((0.0, -0.092, 0.054), (0.011, 0.012, 0.018), False),    # burun kökü
     ((0.0, -0.101, 0.030), (0.021, 0.015, 0.013), False),    # yassı, kırık burun
     ((0.0, -0.086, 0.004), (0.040, 0.022, 0.014), False),    # üst dudak / ağız çevresi
     ((0.0, -0.094, -0.012), (0.033, 0.032, 0.015), True),    # ağız boşluğu
     ((0.0, -0.104, 0.064), (0.020, 0.010, 0.010), True)]     # kaşlar arası çentik
    + M((0.033, -0.080, 0.081), (0.026, 0.020, 0.017))       # kaş tümsekleri
    + M((0.052, -0.058, 0.040), (0.024, 0.024, 0.017))       # geniş elmacık
    + M((0.058, -0.036, 0.008), (0.022, 0.026, 0.026))       # yanak kütlesi
    + M((0.017, -0.095, 0.027), (0.010, 0.010, 0.009))       # burun kanatları
    + M((0.063, -0.012, -0.004), (0.020, 0.026, 0.030))      # çiğneme kası
    + M((0.074, -0.018, 0.058), (0.014, 0.030, 0.024))       # şakak kası
    + M((0.086, 0.010, 0.036), (0.008, 0.016, 0.019))        # ezik kulak
    + M((0.030, -0.088, 0.056), (0.020, 0.020, 0.016), True)  # derin göz çukuru
    + M((0.052, -0.076, 0.004), (0.013, 0.014, 0.016), True)  # elmacık altı oyuğu
    + M((0.033, -0.098, 0.016), (0.006, 0.010, 0.016), True)  # burun-dudak kıvrımı
)
JAW_HINGE = Vector((0.0, -0.012, -0.010))
JAW_BLOBS = (M((0.058, 0.000, -0.018), (0.016, 0.022, 0.032))   # çene kolu
             + M((0.060, -0.006, -0.048), (0.020, 0.022, 0.020))  # geniş çene köşesi
             + M((0.044, -0.050, -0.056), (0.018, 0.040, 0.018))  # çene gövdesi
             + [((0.0, -0.084, -0.058), (0.040, 0.022, 0.024), False),   # kare çene ucu
                ((0.0, -0.088, -0.034), (0.034, 0.013, 0.009), False),   # alt dudak
                ((0.0, -0.050, -0.032), (0.036, 0.040, 0.013), True)])   # dil yatağı
EYE_POS = Vector((0.030, -0.074, 0.054))
EYE_RADIUS = 0.0085
EYE_COLOR = (0.46, 0.42, 0.26)          # donuk sarımsı; tenden açık, oyun kamerasından seçilir
PUPIL_COLOR = (0.03, 0.025, 0.02)
MOUTH_CENTER = Vector((0.0, -0.058, -0.022))
MOUTH_RADII = Vector((0.036, 0.030, 0.030))
MOUTH_FRONT = (0.045, 0.010, 0.009)
MOUTH_BACK = (0.008, 0.0025, 0.002)
TONGUE = ((0.0, -0.052, -0.030), (0.022, 0.026, 0.0055))   # çene yereli: yassı, çene tabanında
TONGUE_COLOR = (0.07, 0.022, 0.02)
TOOTH_COLOR = (0.40, 0.35, 0.22)
FURROWS = 3                              # alında yatay kırışık sayısı


def _scaled(blobs, s):
    return [(tuple(Vector(c) * s), tuple(r * s for r in rad), neg) for c, rad, neg in blobs]


def _furrows(head, s):
    """Alında yatay kırışıklar ve ince ten yumruları (kil yüzeyi kırılsın)."""
    for v in head.data.vertices:
        c = v.co / s
        if c.y < -0.045 and 0.088 < c.z < 0.128 and abs(c.x) < 0.06:
            k = 0.5 + 0.5 * math.cos((c.z - 0.088) / 0.040 * FURROWS * math.tau)
            fade = 1.0 - abs(c.x) / 0.06
            v.co -= v.normal * 0.0016 * s * k * fade


def _teeth(parent, s, mat, rng, upper=True):
    """Kırık, düzensiz dişler; alt çenede iki iri köpek dişi üst dudağın önüne çıkar."""
    out = []
    count = 8 if upper else 6
    for i in range(count):
        a = math.radians(-56 + i * (112 / (count - 1)))
        if upper:
            pos = Vector((0.031 * math.sin(a), -0.086 - 0.018 * math.cos(a), -0.006)) * s
            size = rng.uniform(0.0045, 0.0062) * s
            depth = rng.uniform(0.008, 0.013) * s
        else:
            pos = Vector((0.029 * math.sin(a), -0.078 - 0.012 * math.cos(a), -0.036)) * s
            tusk = i in (0, count - 1)
            size = (0.0080 if tusk else rng.uniform(0.0042, 0.0058)) * s
            depth = (0.026 if tusk else rng.uniform(0.008, 0.012)) * s
            pos.z += depth * 0.35
        tooth = kit.primitive("Tank_ToothU" if upper else "Tank_ToothL", "cone", pos,
                              radius1=size, depth=depth, segments=6)
        tooth.rotation_euler = (math.radians(180 if upper else 0) + rng.uniform(-0.15, 0.15),
                                rng.uniform(-0.2, 0.2), 0.0)
        tooth.data.materials.append(mat)
        tooth.parent = parent
        out.append(tooth)
    return out


def mouth_material(name, s):
    """Ağız içi: önde koyu kırmızı, arkaya koyulaşır (walker_head ile aynı yöntem, tank ölçüleri)."""
    mat, bsdf = kit.material(name, MOUTH_FRONT, rough=0.85)   # mat: parlak top gibi durmasın
    bsdf.inputs["Specular IOR Level"].default_value = 0.1
    nt = mat.node_tree
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    rng = nt.nodes.new("ShaderNodeMapRange")
    rng.inputs["From Min"].default_value = (MOUTH_CENTER.y - MOUTH_RADII.y * 0.3) * s
    rng.inputs["From Max"].default_value = (MOUTH_CENTER.y + MOUTH_RADII.y) * s
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*MOUTH_FRONT, 1.0)
    ramp.color_ramp.elements[1].position = 0.8
    ramp.color_ramp.elements[1].color = (*MOUTH_BACK, 1.0)
    nt.links.new(coord.outputs["Object"], sep.inputs["Vector"])
    nt.links.new(sep.outputs["Y"], rng.inputs["Value"])
    nt.links.new(rng.outputs["Result"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def _mouth(head, jaw, s, name):
    """Dişlerin arkasında açıklığa bakan iç bükey boşluk (normaller içe) + yassı dil."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=1.0)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.y < -0.1], context="VERTS")
    for v in bm.verts:
        v.co = (Vector((v.co.x * MOUTH_RADII.x, v.co.y * MOUTH_RADII.y, v.co.z * MOUTH_RADII.z))
                + MOUTH_CENTER) * s
    bmesh.ops.reverse_faces(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("Tank_Mouth")
    bm.to_mesh(mesh)
    bm.free()
    cavity = bpy.data.objects.new("Tank_Mouth", mesh)
    bpy.context.collection.objects.link(cavity)
    cavity.data.materials.append(mouth_material("M_Tank_Mouth_" + name, s))
    cavity.parent = head
    tongue_mat, _ = kit.material("M_Tank_Tongue_" + name, TONGUE_COLOR, rough=0.5)
    tongue = kit.metaball_mesh("Tank_Tongue", _scaled([(TONGUE[0], TONGUE[1], False)], s),
                               tongue_mat, resolution=0.003)
    tongue.parent = jaw
    for obj in (cavity, tongue):
        for p in obj.data.polygons:
            p.use_smooth = True


def _eyes(head, s, name):
    eye_mat, bsdf = kit.material("M_Tank_Eye_" + name, EYE_COLOR, rough=0.6)
    bsdf.inputs["Specular IOR Level"].default_value = 0.25
    pupil_mat, _ = kit.material("M_Tank_Pupil_" + name, PUPIL_COLOR, rough=0.4)
    for sx in (1.0, -1.0):
        guess = Vector((EYE_POS.x * sx, EYE_POS.y, EYE_POS.z)) * s
        hit, loc, _n, _i = head.ray_cast(Vector((guess.x, -0.5, guess.z)), Vector((0.0, 1.0, 0.0)))
        pos = Vector((guess.x, loc.y + EYE_RADIUS * s * 0.45, guess.z)) if hit else guess
        eye = kit.primitive("Tank_Eye", "sphere", pos, segments=12, rings=8, radius=EYE_RADIUS * s)
        eye.data.materials.append(eye_mat)
        eye.parent = head
        pupil = kit.primitive("Tank_Pupil", "sphere", pos + Vector((0.0, -EYE_RADIUS * s * 0.78, 0.0)),
                              segments=8, rings=6, radius=EYE_RADIUS * s * 0.36)
        pupil.data.materials.append(pupil_mat)
        pupil.parent = head


def build_head(v, skin, tooth_mat, hair_mat, neck, pitch_deg, jaw_deg, yaw_deg=0.0):
    """Kafa + çene + gözler + ağız; boyun üstüne yerleşmiş ve eğilmiş kafa nesnesini döner."""
    s = v["body"]["head"]
    rng = random.Random(int(v["seed"] * 1000) + 41)
    head = kit.metaball_mesh("Tank_Head", _scaled(HEAD_BLOBS, s), skin, resolution=0.0032)
    _furrows(head, s)
    style = wh.HAIR_STYLES.get(v.get("hair_style", "bald"))
    if style and hair_mat is not None:
        wh.build_hair(head, s, style, hair_mat, v["seed"])
    _teeth(head, s, tooth_mat, rng, upper=True)
    _eyes(head, s, v["name"])
    jaw = kit.metaball_mesh("Tank_Jaw", _scaled(JAW_BLOBS, s), skin, resolution=0.003)
    for p in jaw.data.polygons:
        p.use_smooth = True
    _teeth(jaw, s, tooth_mat, rng, upper=False)
    jaw.parent = head
    jaw.location = JAW_HINGE * s
    jaw.rotation_euler = (math.radians(jaw_deg), 0.0, 0.0)
    _mouth(head, jaw, s, v["name"])
    head.location = neck + Vector((0.0, -0.030, 0.030)) * s
    head.rotation_euler = (math.radians(pitch_deg), 0.0, math.radians(yaw_deg))
    for obj in [head] + list(head.children_recursive):
        obj.name = obj.name.replace("Walker_", "Tank_")
    return head
