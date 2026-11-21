"""Çığlıkçının kendi kafası (7.3): dar uzun kafatası, çökük şakak ve yanaklar, derin göz çukurları,
çürümüş burun (burun deliği oyuk), çekilmiş dudaklar (diş sırası görünür), uzun dar alt çene.

İmza parça: ÇENE. Alt çene `jaw` kemiğiyle sonuna dek (JAW_SCREAM_DEG) düşer. Çene ile kafa arasında
yırtık yanak zarı/ağız torbası (`Screamer_Mouth`) gerilir: torbanın üst köşeleri kafaya, alt köşeleri
çeneye bağlıdır (oyunda ağırlık w, konseptte aynı w ile döndürülür), böylece açık ağız boşluk değil
koyu kırmızı bir mağara olarak okunur. Uzun üst/alt diş sıraları ağzın çerçevesini çizer.
build_screamer.py içe aktarır. walker_head'in kafası kullanılmaz; yalnız saç üslubu (veri) oradan gelir.
Kafa yerel uzayı: köken boyun üstü, yüz -Y, Z yukarı, metre (ölçek öncesi).
"""
import math
import random

import bmesh
import bpy
from mathutils import Matrix, Vector

import walker_head as wh
import zombie_kit as kit

M = kit.mirrored
HEAD_BLOBS = (
    [((0.0, 0.010, 0.072), (0.062, 0.076, 0.072), False),     # dar, yüksek kafatası
     ((0.0, 0.046, 0.046), (0.055, 0.050, 0.058), False),     # art kafa
     ((0.0, 0.026, -0.014), (0.044, 0.042, 0.044), False),    # ense
     ((0.0, -0.060, 0.088), (0.050, 0.016, 0.012), False),    # kaş kemeri
     ((0.0, -0.046, 0.034), (0.030, 0.026, 0.044), False),    # orta yüz
     ((0.0, -0.082, 0.062), (0.009, 0.011, 0.016), False),    # burun kökü
     ((0.0, -0.086, 0.042), (0.012, 0.011, 0.010), False),    # çürük burun ucu
     ((0.0, -0.094, 0.038), (0.009, 0.008, 0.010), True),     # burun deliği oyuğu
     ((0.0, -0.068, 0.008), (0.027, 0.010, 0.007), False),    # ince üst dudak
     ((0.0, -0.086, -0.008), (0.030, 0.030, 0.013), True),    # ağız boşluğu
     ((0.0, -0.096, 0.070), (0.014, 0.008, 0.008), True)]     # kaşlar arası çentik
    + M((0.027, -0.070, 0.090), (0.017, 0.012, 0.010))       # kaş tümsekleri
    + M((0.046, -0.050, 0.046), (0.013, 0.020, 0.010))       # çıkık elmacık
    + M((0.066, -0.018, 0.064), (0.010, 0.020, 0.018), True)  # çökük şakak
    + M((0.048, -0.010, -0.004), (0.009, 0.016, 0.022))      # ince çiğneme kası
    + M((0.066, 0.012, 0.034), (0.007, 0.015, 0.019))        # kulak
    + M((0.028, -0.080, 0.060), (0.019, 0.020, 0.017), True)  # derin göz çukuru
    + M((0.042, -0.060, 0.012), (0.019, 0.020, 0.026), True)  # çökük yanak
)
JAW_HINGE = Vector((0.0, -0.008, -0.004))
JAW_BLOBS = (M((0.044, 0.000, -0.020), (0.011, 0.017, 0.030))   # çene kolu
             + M((0.045, -0.010, -0.050), (0.013, 0.017, 0.015))  # çene köşesi
             + M((0.031, -0.050, -0.058), (0.012, 0.040, 0.013))  # uzun çene gövdesi
             + [((0.0, -0.080, -0.062), (0.018, 0.014, 0.016), False),   # sivri çene ucu
                ((0.0, -0.076, -0.036), (0.022, 0.008, 0.006), False),   # alt dudak
                ((0.0, -0.046, -0.040), (0.026, 0.036, 0.012), True)])   # dil yatağı
JAW_REST_DEG = 14.0       # nötr pozda (oyunun dinlenme pozu) çene açıklığı
JAW_SCREAM_DEG = 64.0     # çığlık tepe anı (dinlenmeden +50°)
EYE_POS = Vector((0.028, -0.068, 0.060))
EYE_RADIUS = 0.0072
EYE_COLOR = (0.50, 0.50, 0.42)           # donuk süt beyazı
PUPIL_COLOR = (0.05, 0.045, 0.04)
# Ağız torbası (yanak zarı): kafa yereli, çene kapalıyken; alt köşeler çeneyle döner
BAG_CENTER = Vector((0.0, -0.046, -0.020))
BAG_RADII = Vector((0.030, 0.040, 0.034))
BAG_W = (0.006, -0.026)   # z: üstünde ağırlık 0 (kafa), altında 1 (çene)
MOUTH_FRONT = (0.26, 0.022, 0.020)       # et kırmızısı (oyun kamerasından açık ağız okunsun)
MOUTH_BACK = (0.010, 0.003, 0.003)
TONGUE = ((0.0, -0.050, -0.034), (0.019, 0.026, 0.006))
TONGUE_COLOR = (0.09, 0.025, 0.025)
TOOTH_COLOR = (0.46, 0.41, 0.28)


def _scaled(blobs, s, shift=Vector()):
    return [(tuple((Vector(c) - shift) * s), tuple(r * s for r in rad), neg) for c, rad, neg in blobs]


def bag_weight(z_closed):
    """Torba köşesinin çene ağırlığı (kafa yereli, çene kapalıyken z)."""
    t = min(max((BAG_W[0] - z_closed) / (BAG_W[0] - BAG_W[1]), 0.0), 1.0)
    return t * t * (3.0 - 2.0 * t)


def _rot_hinge(co, deg, s):
    h = JAW_HINGE * s
    return h + Matrix.Rotation(math.radians(deg), 3, "X") @ (co - h)


def _teeth(parent, s, mat, rng, upper=True):
    """Uzun, seyrek, eğri diş sıraları; altta ve üstte köpek dişleri. Çene açıkken ağzı çerçeveler."""
    count = 8
    for i in range(count):
        a = math.radians(-60 + i * (120 / (count - 1)))
        if upper and i in (2,):
            continue                          # eksik diş
        fang = i in (1, count - 2)
        size = (0.0050 if fang else rng.uniform(0.0034, 0.0046)) * s
        depth = (0.020 if fang else rng.uniform(0.010, 0.016)) * s
        if upper:
            pos = Vector((0.027 * math.sin(a), -0.074 - 0.014 * math.cos(a), 0.004 - depth / s * 0.35)) * s
            name = "Screamer_ToothU"
        else:
            pos = Vector((0.025 * math.sin(a), -0.075 - 0.012 * math.cos(a), -0.034 + depth / s * 0.35)) * s
            pos -= JAW_HINGE * s
            name = "Screamer_ToothL"
        tooth = kit.primitive(name, "cone", pos, radius1=size, depth=depth, segments=6)
        tooth.rotation_euler = (math.radians(180 if upper else 0) + rng.uniform(-0.2, 0.2),
                                rng.uniform(-0.2, 0.2), 0.0)
        tooth.data.materials.append(mat)
        tooth.parent = parent


def mouth_material(name, s):
    mat, bsdf = kit.material(name, MOUTH_FRONT, rough=0.8)
    bsdf.inputs["Specular IOR Level"].default_value = 0.15
    nt = mat.node_tree
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    rng = nt.nodes.new("ShaderNodeMapRange")
    rng.inputs["From Min"].default_value = (BAG_CENTER.y - BAG_RADII.y * 0.6) * s
    rng.inputs["From Max"].default_value = (BAG_CENTER.y + BAG_RADII.y) * s
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*MOUTH_FRONT, 1.0)
    ramp.color_ramp.elements[1].position = 0.75
    ramp.color_ramp.elements[1].color = (*MOUTH_BACK, 1.0)
    nt.links.new(coord.outputs["Object"], sep.inputs["Vector"])
    nt.links.new(sep.outputs["Y"], rng.inputs["Value"])
    nt.links.new(rng.outputs["Result"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def build_bag(head, s, jaw_deg, name):
    """Ağız torbası: önü açık elipsoid, iki yüzlü (solidify); alt yarısı çeneyle döner.
    Köşe başına çene ağırlığı `jaw_w` adlı köşe grubunda (oyun ağırlığı bununla verilir)."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=18, v_segments=12, radius=1.0)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.y < -0.55], context="VERTS")
    weights = []
    for v in bm.verts:
        closed = Vector((v.co.x * BAG_RADII.x, v.co.y * BAG_RADII.y, v.co.z * BAG_RADII.z)) + BAG_CENTER
        w = bag_weight(closed.z)
        weights.append(w)
        v.co = _rot_hinge(closed * s, jaw_deg * w, s)
    mesh = bpy.data.meshes.new("Screamer_Mouth")
    bm.to_mesh(mesh)
    bm.free()
    bag = bpy.data.objects.new("Screamer_Mouth", mesh)
    bpy.context.collection.objects.link(bag)
    grp = bag.vertex_groups.new(name="jaw_w")
    for i, w in enumerate(weights):
        grp.add([i], w, "REPLACE")
    bag.data.materials.append(mouth_material("M_Screamer_Mouth_" + name, s))
    sol = bag.modifiers.new("Solid", "SOLIDIFY")
    sol.thickness = 0.0015 * s
    sol.offset = 0.0
    kit.apply_all(bag)          # köşe grupları solidify ile korunur
    for p in bag.data.polygons:
        p.use_smooth = True
    bag.parent = head
    return bag


def _eyes(head, s, name):
    eye_mat, bsdf = kit.material("M_Screamer_Eye_" + name, EYE_COLOR, rough=0.5)
    bsdf.inputs["Specular IOR Level"].default_value = 0.3
    pupil_mat, _ = kit.material("M_Screamer_Pupil_" + name, PUPIL_COLOR, rough=0.4)
    for sx in (1.0, -1.0):
        guess = Vector((EYE_POS.x * sx, EYE_POS.y, EYE_POS.z)) * s
        hit, loc, _n, _i = head.ray_cast(Vector((guess.x, -0.5, guess.z)), Vector((0.0, 1.0, 0.0)))
        pos = Vector((guess.x, loc.y + EYE_RADIUS * s * 0.55, guess.z)) if hit else guess
        eye = kit.primitive("Screamer_Eye", "sphere", pos, segments=12, rings=8, radius=EYE_RADIUS * s)
        eye.data.materials.append(eye_mat)
        eye.parent = head
        pupil = kit.primitive("Screamer_Pupil", "sphere", pos + Vector((0.0, -EYE_RADIUS * s * 0.80, 0.0)),
                              segments=8, rings=6, radius=EYE_RADIUS * s * 0.26)
        pupil.data.materials.append(pupil_mat)
        pupil.parent = head


def build_head(v, skin, tooth_mat, hair_mat, neck, pitch_deg, jaw_deg):
    """Kafa + çene + gözler + ağız torbası; boyun üstüne yerleşmiş kafa nesnesini döner."""
    s = v["body"]["head"]
    rng = random.Random(int(v["seed"] * 1000) + 43)
    head = kit.metaball_mesh("Screamer_Head", _scaled(HEAD_BLOBS, s), skin, resolution=0.0030)
    style = wh.HAIR_STYLES.get(v.get("hair_style", "bald"))
    if style and hair_mat is not None:
        wh.build_hair(head, s, style, hair_mat, v["seed"])
    _teeth(head, s, tooth_mat, rng, upper=True)
    _eyes(head, s, v["name"])
    jaw = kit.metaball_mesh("Screamer_Jaw", _scaled(JAW_BLOBS, s, JAW_HINGE), skin, resolution=0.0028)
    _teeth(jaw, s, tooth_mat, rng, upper=False)
    tongue_mat, _ = kit.material("M_Screamer_Tongue_" + v["name"], TONGUE_COLOR, rough=0.5)
    tongue = kit.metaball_mesh("Screamer_Tongue", _scaled([(TONGUE[0], TONGUE[1], False)], s, JAW_HINGE),
                               tongue_mat, resolution=0.003)
    tongue.parent = jaw
    jaw.parent = head
    jaw.location = JAW_HINGE * s
    jaw.rotation_euler = (math.radians(jaw_deg), 0.0, 0.0)
    build_bag(head, s, jaw_deg, v["name"])
    head.location = neck + Vector((0.0, -0.020, 0.026)) * s
    head.rotation_euler = (math.radians(pitch_deg), 0.0, 0.0)
    for obj in [head] + list(head.children_recursive):
        obj.name = obj.name.replace("Walker_", "Screamer_")
    return head
