"""Patlayıcının kendi kafası (7.3): şiş yüz, kabarık yanaklar ve gıdı, gözleri sıkıştıran şiş göz
kapakları, belirgin kaş kemeri, şişmiş dudaklar, salyalı açık ağız; alında ve şakakta kabarcıklar.

build_bloater.py içe aktarır. tank_head'in yöntemi (kütleler + oyuklar, iç bükey ağız boşluğu, yassı dil,
kırık dişler) kopyalanıp bu türe uyarlandı (paylaşılan dosyaya dokunulmaz). Kafa yerel uzayı: köken
boyun üstü, yüz -Y, Z yukarı, metre (ölçek öncesi). Kafa küçük ve gövdeye gömük: boyun yok gibi.
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
    [((0.0, 0.012, 0.062), (0.074, 0.080, 0.066), False),     # yuvarlak kafatası
     ((0.0, 0.040, 0.030), (0.066, 0.056, 0.060), False),     # art kafa
     ((0.0, 0.030, -0.030), (0.084, 0.070, 0.058), False),    # kalın ense (gövdeye gömülür)
     ((0.0, -0.064, 0.084), (0.062, 0.022, 0.016), False),    # kaş kemeri
     ((0.0, -0.056, 0.030), (0.044, 0.034, 0.038), False),    # orta yüz
     ((0.0, -0.090, 0.054), (0.010, 0.011, 0.016), False),    # burun kökü
     ((0.0, -0.097, 0.032), (0.017, 0.015, 0.013), False),    # küçük kalkık burun
     ((0.0, -0.084, 0.004), (0.040, 0.020, 0.013), False),    # şiş üst dudak
     ((0.0, -0.093, -0.012), (0.030, 0.034, 0.016), True),    # ağız boşluğu
     ((0.0, -0.100, 0.068), (0.018, 0.010, 0.010), True)]     # kaşlar arası çentik
    + M((0.032, -0.074, 0.084), (0.024, 0.018, 0.015))       # kaş tümsekleri
    + M((0.050, -0.058, 0.046), (0.020, 0.020, 0.014))       # elmacık (şişin üstünde kenar)
    + M((0.060, -0.044, 0.006), (0.034, 0.036, 0.036))       # kabarık yanak
    + M((0.048, -0.050, -0.040), (0.036, 0.034, 0.028))      # sarkık gerdan yanağı
    + M((0.031, -0.079, 0.056), (0.018, 0.012, 0.007))       # şiş üst göz kapağı
    + M((0.031, -0.080, 0.040), (0.019, 0.012, 0.008))       # şiş alt göz kapağı (gözü sıkıştırır)
    + M((0.016, -0.093, 0.028), (0.009, 0.009, 0.008))       # burun kanatları
    + M((0.078, 0.004, 0.040), (0.010, 0.016, 0.020))        # kulak
    + M((0.030, -0.088, 0.050), (0.016, 0.016, 0.012), True)  # göz çukuru
    + M((0.036, -0.094, 0.018), (0.006, 0.010, 0.016), True)  # burun-dudak kıvrımı
    + M((0.055, -0.070, 0.030), (0.010, 0.010, 0.010), True)  # elmacık altı çukuru
)
JAW_HINGE = Vector((0.0, -0.010, -0.010))
JAW_BLOBS = (M((0.054, 0.000, -0.020), (0.016, 0.022, 0.030))     # çene kolu
             + M((0.050, -0.030, -0.050), (0.026, 0.030, 0.024))  # çene hattı (gıdının üstünde kenar)
             + [((0.0, -0.074, -0.054), (0.036, 0.022, 0.022), False),   # çene ucu
                ((0.0, -0.060, -0.080), (0.050, 0.040, 0.024), False),   # gıdı (çift çene)
                ((0.0, -0.086, -0.032), (0.034, 0.015, 0.011), False),   # şiş sarkık alt dudak
                ((0.0, -0.090, -0.064), (0.040, 0.010, 0.006), True),    # gıdı kıvrımı
                ((0.0, -0.048, -0.032), (0.034, 0.040, 0.013), True)])   # dil yatağı
EYE_POS = Vector((0.031, -0.080, 0.048))
EYE_RADIUS = 0.0075
EYE_COLOR = (0.62, 0.40, 0.10)          # sarı-turuncu, iltihaplı: kabarcık parıltısıyla akraba
PUPIL_COLOR = (0.03, 0.02, 0.01)
MOUTH_CENTER = Vector((0.0, -0.056, -0.022))
MOUTH_RADII = Vector((0.034, 0.030, 0.030))
MOUTH_FRONT = (0.050, 0.012, 0.008)
MOUTH_BACK = (0.010, 0.003, 0.002)
TONGUE = ((0.0, -0.050, -0.030), (0.020, 0.026, 0.0060))
TONGUE_COLOR = (0.09, 0.03, 0.015)
TOOTH_COLOR = (0.40, 0.33, 0.18)
FACE_BLISTERS = [((0.050, -0.040, 0.100), 0.016), ((0.064, -0.030, 0.088), 0.010),
                 ((-0.058, -0.010, 0.020), 0.013), ((-0.040, 0.010, 0.118), 0.012)]


def _scaled(blobs, s):
    return [(tuple(Vector(c) * s), tuple(r * s for r in rad), neg) for c, rad, neg in blobs]


def _teeth(parent, s, mat, rng, upper=True):
    """Seyrek, kırık dişler (eksik dişler arası boşluk)."""
    count = 7 if upper else 6
    for i in range(count):
        if rng.random() < 0.22:
            continue
        a = math.radians(-54 + i * (108 / (count - 1)))
        if upper:
            pos = Vector((0.029 * math.sin(a), -0.084 - 0.016 * math.cos(a), -0.006)) * s
        else:
            pos = Vector((0.027 * math.sin(a), -0.077 - 0.012 * math.cos(a), -0.033)) * s
        size = rng.uniform(0.0042, 0.0058) * s
        depth = rng.uniform(0.008, 0.012) * s
        tooth = kit.primitive("Bloater_ToothU" if upper else "Bloater_ToothL", "cone", pos,
                              radius1=size, depth=depth, segments=6)
        tooth.rotation_euler = (math.radians(180 if upper else 0) + rng.uniform(-0.2, 0.2),
                                rng.uniform(-0.25, 0.25), 0.0)
        tooth.data.materials.append(mat)
        tooth.parent = parent


def mouth_material(name, s):
    mat, bsdf = kit.material(name, MOUTH_FRONT, rough=0.85)
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
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=1.0)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.y < -0.1], context="VERTS")
    for v in bm.verts:
        v.co = (Vector((v.co.x * MOUTH_RADII.x, v.co.y * MOUTH_RADII.y, v.co.z * MOUTH_RADII.z))
                + MOUTH_CENTER) * s
    bmesh.ops.reverse_faces(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("Bloater_Mouth")
    bm.to_mesh(mesh)
    bm.free()
    cavity = bpy.data.objects.new("Bloater_Mouth", mesh)
    bpy.context.collection.objects.link(cavity)
    cavity.data.materials.append(mouth_material("M_Bloater_Mouth_" + name, s))
    cavity.parent = head
    tongue_mat, _ = kit.material("M_Bloater_Tongue_" + name, TONGUE_COLOR, rough=0.5)
    tongue = kit.metaball_mesh("Bloater_Tongue", _scaled([(TONGUE[0], TONGUE[1], False)], s),
                               tongue_mat, resolution=0.003)
    tongue.parent = jaw
    for obj in (cavity, tongue):
        for p in obj.data.polygons:
            p.use_smooth = True


def _eyes(head, s, name):
    eye_mat, bsdf = kit.material("M_Bloater_Eye_" + name, EYE_COLOR, rough=0.4,
                                 emission=EYE_COLOR, strength=1.5)
    pupil_mat, _ = kit.material("M_Bloater_Pupil_" + name, PUPIL_COLOR, rough=0.4)
    for sx in (1.0, -1.0):
        guess = Vector((EYE_POS.x * sx, EYE_POS.y, EYE_POS.z)) * s
        hit, loc, _n, _i = head.ray_cast(Vector((guess.x, -0.5, guess.z)), Vector((0.0, 1.0, 0.0)))
        pos = Vector((guess.x, loc.y + EYE_RADIUS * s * 0.55, guess.z)) if hit else guess
        eye = kit.primitive("Bloater_Eye", "sphere", pos, segments=12, rings=8, radius=EYE_RADIUS * s)
        eye.data.materials.append(eye_mat)
        eye.parent = head
        pupil = kit.primitive("Bloater_Pupil", "sphere", pos + Vector((0.0, -EYE_RADIUS * s * 0.80, 0.0)),
                              segments=8, rings=6, radius=EYE_RADIUS * s * 0.30)
        pupil.data.materials.append(pupil_mat)
        pupil.parent = head


def _face_blisters(head, s, mat):
    for c, r in FACE_BLISTERS:
        guess = Vector(c) * s
        d = (guess - Vector((0.0, 0.0, 0.04)) * s).normalized()
        hit, loc, n, _i = head.ray_cast(guess + d * 0.2, -d)
        if not hit:
            continue
        b = kit.primitive("Bloater_FaceBlister", "sphere", loc + n * r * s * 0.2, segments=10, rings=6,
                          radius=r * s)
        b.data.materials.append(mat)
        b.parent = head
        for p in b.data.polygons:
            p.use_smooth = True


def build_head(v, skin, tooth_mat, hair_mat, blister_mat, neck, pitch_deg, jaw_deg, yaw_deg=0.0):
    """Kafa + çene + gözler + ağız; boyun üstüne yerleşmiş ve eğilmiş kafa nesnesini döner."""
    s = v["body"]["head"]
    rng = random.Random(int(v["seed"] * 1000) + 41)
    head = kit.metaball_mesh("Bloater_Head", _scaled(HEAD_BLOBS, s), skin, resolution=0.0030)
    style = wh.HAIR_STYLES.get(v.get("hair_style", "bald"))
    if style and hair_mat is not None:
        wh.build_hair(head, s, style, hair_mat, v["seed"])
    _teeth(head, s, tooth_mat, rng, upper=True)
    _eyes(head, s, v["name"])
    _face_blisters(head, s, blister_mat)
    jaw = kit.metaball_mesh("Bloater_Jaw", _scaled(JAW_BLOBS, s), skin, resolution=0.003)
    for p in jaw.data.polygons:
        p.use_smooth = True
    _teeth(jaw, s, tooth_mat, rng, upper=False)
    jaw.parent = head
    jaw.location = JAW_HINGE * s
    jaw.rotation_euler = (math.radians(jaw_deg), 0.0, 0.0)
    _mouth(head, jaw, s, v["name"])
    head.location = neck + Vector((0.0, -0.020, 0.020)) * s
    head.rotation_euler = (math.radians(pitch_deg), 0.0, math.radians(yaw_deg))
    for obj in [head] + list(head.children_recursive):
        obj.name = obj.name.replace("Walker_", "Bloater_")
    return head
