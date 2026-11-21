"""Tükürücünün kendi kafası (7.3): sıska, uzun yüz; ağır kaş kemeri, keskin elmacık, çökük yanak ve
şakak, geniş açılan çene, kalın sarkık dudaklar; alt dudaktan sarkan parlayan asit salyası.

build_spitter.py içe aktarır. bloater_head'in yöntemi (kütleler + oyuklar, iç bükey ağız boşluğu, yassı dil,
kırık dişler) kopyalanıp bu türe uyarlandı (başka türün dosyasına dokunulmaz). Kafa yerel uzayı: köken
boyun üstü, yüz -Y, Z yukarı, metre (ölçek öncesi).
MOUTH_TIP: ağız açıklığının ön ortası (kafa yereli, ölçek öncesi) — asit topu buradan çıkar.
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
    [((0.0, 0.010, 0.064), (0.066, 0.078, 0.070), False),     # kafatası (dar)
     ((0.0, 0.040, 0.030), (0.058, 0.052, 0.056), False),     # art kafa
     ((0.0, 0.030, -0.018), (0.050, 0.050, 0.044), False),    # ense
     ((0.0, -0.064, 0.086), (0.064, 0.024, 0.019), False),    # ağır kaş kemeri
     ((0.0, -0.056, 0.030), (0.040, 0.032, 0.042), False),    # orta yüz
     ((0.0, -0.088, 0.058), (0.009, 0.011, 0.016), False),    # burun kökü
     ((0.0, -0.095, 0.036), (0.012, 0.014, 0.015), False),    # çürük burun
     ((0.0, -0.082, 0.006), (0.040, 0.018, 0.012), False),    # kalın üst dudak
     ((0.0, -0.093, -0.012), (0.034, 0.034, 0.018), True),    # ağız boşluğu
     ((0.0, -0.100, 0.070), (0.018, 0.010, 0.010), True)]     # kaşlar arası çentik
    + M((0.032, -0.074, 0.086), (0.024, 0.018, 0.015))       # kaş tümsekleri
    + M((0.050, -0.058, 0.050), (0.021, 0.019, 0.014))       # keskin elmacık
    + M((0.056, -0.034, 0.008), (0.026, 0.030, 0.032))       # yanak arkası (çene kası)
    + M((0.031, -0.077, 0.061), (0.016, 0.010, 0.006))       # üst göz kapağı
    + M((0.014, -0.090, 0.030), (0.008, 0.008, 0.007))       # burun kanatları
    + M((0.072, 0.004, 0.042), (0.010, 0.016, 0.020))        # kulak
    + M((0.030, -0.088, 0.050), (0.017, 0.016, 0.013), True)  # derin göz çukuru
    + M((0.052, -0.074, 0.014), (0.017, 0.015, 0.020), True)  # çökük yanak
    + M((0.064, -0.038, 0.074), (0.011, 0.014, 0.016), True)  # çökük şakak
    + M((0.036, -0.094, 0.018), (0.006, 0.010, 0.016), True)  # burun-dudak kıvrımı
)
JAW_HINGE = Vector((0.0, -0.010, -0.010))
JAW_BLOBS = (M((0.050, 0.000, -0.020), (0.014, 0.020, 0.028))     # çene kolu
             + M((0.042, -0.034, -0.046), (0.018, 0.026, 0.016))  # çene hattı
             + [((0.0, -0.074, -0.054), (0.030, 0.018, 0.018), False),   # çene ucu
                ((0.0, -0.084, -0.030), (0.033, 0.015, 0.011), False),   # kalın sarkık alt dudak
                ((0.0, -0.048, -0.032), (0.032, 0.040, 0.012), True)])   # dil yatağı
EYE_POS = Vector((0.030, -0.080, 0.050))
EYE_RADIUS = 0.0078
EYE_COLOR = (0.50, 0.62, 0.10)          # hastalıklı sarı-yeşil: kabarcık parıltısıyla akraba
PUPIL_COLOR = (0.02, 0.025, 0.01)
MOUTH_CENTER = Vector((0.0, -0.056, -0.022))
MOUTH_RADII = Vector((0.034, 0.030, 0.030))
MOUTH_FRONT = (0.050, 0.040, 0.008)     # asitle yanmış damak (kahve-yeşil; kara top değil)
MOUTH_BACK = (0.010, 0.012, 0.002)
MOUTH_TIP = Vector((0.0, -0.098, -0.014))
TONGUE = ((0.0, -0.050, -0.030), (0.020, 0.026, 0.0060))
TONGUE_COLOR = (0.07, 0.09, 0.02)
TOOTH_COLOR = (0.36, 0.34, 0.16)
DROOL_COLOR = (0.30, 1.0, 0.06)
# alt dudaktan sarkan salya iplikleri (çene yereli): (x, uzunluk)
DROOL = [(0.012, 0.050), (-0.016, 0.034)]


def _scaled(blobs, s):
    return [(tuple(Vector(c) * s), tuple(r * s for r in rad), neg) for c, rad, neg in blobs]


def _teeth(parent, s, mat, rng, upper=True):
    count = 7 if upper else 6
    for i in range(count):
        if rng.random() < 0.25:
            continue
        a = math.radians(-54 + i * (108 / (count - 1)))
        if upper:
            pos = Vector((0.029 * math.sin(a), -0.084 - 0.016 * math.cos(a), -0.006)) * s
        else:
            pos = Vector((0.027 * math.sin(a), -0.077 - 0.012 * math.cos(a), -0.033)) * s
        size = rng.uniform(0.0040, 0.0056) * s
        depth = rng.uniform(0.009, 0.013) * s
        tooth = kit.primitive("Spitter_ToothU" if upper else "Spitter_ToothL", "cone", pos,
                              radius1=size, depth=depth, segments=6)
        tooth.rotation_euler = (math.radians(180 if upper else 0) + rng.uniform(-0.2, 0.2),
                                rng.uniform(-0.25, 0.25), 0.0)
        tooth.data.materials.append(mat)
        tooth.parent = parent


def mouth_material(name, s):
    mat, bsdf = kit.material(name, MOUTH_FRONT, rough=0.6)
    bsdf.inputs["Specular IOR Level"].default_value = 0.2
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
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=1.0)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.y < -0.1], context="VERTS")
    for v in bm.verts:
        v.co = (Vector((v.co.x * MOUTH_RADII.x, v.co.y * MOUTH_RADII.y, v.co.z * MOUTH_RADII.z))
                + MOUTH_CENTER) * s
    bmesh.ops.reverse_faces(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("Spitter_Mouth")
    bm.to_mesh(mesh)
    bm.free()
    cavity = bpy.data.objects.new("Spitter_Mouth", mesh)
    bpy.context.collection.objects.link(cavity)
    cavity.data.materials.append(mouth_material("M_Spitter_Mouth_" + name, s))
    cavity.parent = head
    tongue_mat, _ = kit.material("M_Spitter_Tongue_" + name, TONGUE_COLOR, rough=0.4)
    tongue = kit.metaball_mesh("Spitter_Tongue", _scaled([(TONGUE[0], TONGUE[1], False)], s),
                               tongue_mat, resolution=0.003)
    tongue.parent = jaw
    for obj in (cavity, tongue):
        for p in obj.data.polygons:
            p.use_smooth = True


def _eyes(head, s, name):
    eye_mat, _ = kit.material("M_Spitter_Eye_" + name, EYE_COLOR, rough=0.4, emission=EYE_COLOR, strength=1.2)
    pupil_mat, _ = kit.material("M_Spitter_Pupil_" + name, PUPIL_COLOR, rough=0.4)
    for sx in (1.0, -1.0):
        guess = Vector((EYE_POS.x * sx, EYE_POS.y, EYE_POS.z)) * s
        hit, loc, _n, _i = head.ray_cast(Vector((guess.x, -0.5, guess.z)), Vector((0.0, 1.0, 0.0)))
        pos = Vector((guess.x, loc.y + EYE_RADIUS * s * 0.55, guess.z)) if hit else guess
        eye = kit.primitive("Spitter_Eye", "sphere", pos, segments=12, rings=8, radius=EYE_RADIUS * s)
        eye.data.materials.append(eye_mat)
        eye.parent = head
        pupil = kit.primitive("Spitter_Pupil", "sphere", pos + Vector((0.0, -EYE_RADIUS * s * 0.80, 0.0)),
                              segments=8, rings=6, radius=EYE_RADIUS * s * 0.28)
        pupil.data.materials.append(pupil_mat)
        pupil.parent = head


def _drool(jaw, s, name):
    """Alt dudaktan sarkan, uca doğru incelip damlayan asit salyası (çeneye bağlı, parlar)."""
    mat, _ = kit.material("M_Spitter_Drool_" + name, DROOL_COLOR, rough=0.15, coat=0.5,
                          emission=DROOL_COLOR, strength=1.6)
    for x, length in DROOL:
        blobs = []
        for i in range(6):
            u = i / 5
            r = 0.0042 * (1.0 - 0.55 * u) + (0.0030 if i == 5 else 0.0)
            blobs.append(((x, -0.090 - 0.004 * u, -0.036 - length * u), (r, r, r * 1.6), False))
        d = kit.metaball_mesh("Spitter_Drool", _scaled(blobs, s), mat, resolution=0.0022)
        d.parent = jaw


def build_head(v, skin, tooth_mat, hair_mat, neck, pitch_deg, jaw_deg, yaw_deg=0.0):
    """Kafa + çene + gözler + ağız + salya; boyun üstüne yerleşmiş, eğilmiş kafa nesnesini döner."""
    s = v["body"]["head"]
    rng = random.Random(int(v["seed"] * 1000) + 43)
    head = kit.metaball_mesh("Spitter_Head", _scaled(HEAD_BLOBS, s), skin, resolution=0.0028)
    style = wh.HAIR_STYLES.get(v.get("hair_style", "bald"))
    if style and hair_mat is not None:
        wh.build_hair(head, s, style, hair_mat, v["seed"])
    _teeth(head, s, tooth_mat, rng, upper=True)
    _eyes(head, s, v["name"])
    jaw = kit.metaball_mesh("Spitter_Jaw", _scaled(JAW_BLOBS, s), skin, resolution=0.0028)
    _teeth(jaw, s, tooth_mat, rng, upper=False)
    _drool(jaw, s, v["name"])
    jaw.parent = head
    jaw.location = JAW_HINGE * s
    jaw.rotation_euler = (math.radians(jaw_deg), 0.0, 0.0)
    _mouth(head, jaw, s, v["name"])
    head.location = neck + Vector((0.0, -0.022, 0.016)) * s
    head.rotation_euler = (math.radians(pitch_deg), 0.0, math.radians(yaw_deg))
    for obj in [head] + list(head.children_recursive):
        obj.name = obj.name.replace("Walker_", "Spitter_")
    return head
