"""Taş fırlatanın kendi kafası (7.3): uzun yüz, ileri fırlamış alt çene (alt dişler üst dudağın önünde),
çökük yanaklar, kalın kaş kemeri, yana kırık burun, düşük sol göz kapağı; vest çeşidinde kırık baret.

build_thrower.py içe aktarır. walker_head'in kafası kullanılmaz; yalnız saç üslubu (veri) oradan gelir.
Yöntem tank_head ile aynı (metaball kütleleri + negatif oyuklar), işlevler kendi sabitleriyle kopyalandı.
Kafa yerel uzayı: köken boyun üstü, yüz -Y, Z yukarı, metre (ölçek öncesi).
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
    [((0.0, 0.012, 0.064), (0.070, 0.080, 0.074), False),     # yüksek kafatası
     ((0.0, 0.046, 0.040), (0.062, 0.054, 0.060), False),     # art kafa
     ((0.0, 0.030, -0.022), (0.056, 0.050, 0.050), False),    # ense
     ((0.0, -0.064, 0.084), (0.062, 0.022, 0.018), False),    # kaş kemeri
     ((0.0, -0.054, 0.030), (0.038, 0.030, 0.042), False),    # orta yüz
     ((0.003, -0.087, 0.058), (0.010, 0.012, 0.018), False),  # burun kökü
     ((0.008, -0.095, 0.034), (0.016, 0.016, 0.014), False),  # kırık burun (sola kaymış)
     ((0.0, -0.079, 0.004), (0.032, 0.019, 0.012), False),    # üst dudak
     ((0.0, -0.086, -0.012), (0.029, 0.030, 0.014), True),    # ağız boşluğu
     ((0.0, -0.097, 0.066), (0.016, 0.009, 0.009), True)]     # kaşlar arası çentik
    + M((0.030, -0.075, 0.086), (0.022, 0.018, 0.015))       # kaş tümsekleri
    + M((0.047, -0.055, 0.044), (0.019, 0.022, 0.015))       # elmacık (sivri)
    + M((0.066, -0.016, 0.062), (0.012, 0.026, 0.022))       # şakak
    + M((0.054, -0.012, -0.004), (0.016, 0.022, 0.028))      # çiğneme kası
    + M((0.074, 0.010, 0.034), (0.008, 0.016, 0.020))        # kulak
    + M((0.029, -0.082, 0.058), (0.018, 0.018, 0.015), True)  # göz çukuru
    + M((0.045, -0.064, 0.008), (0.015, 0.016, 0.022), True)  # çökük yanak
    + M((0.030, -0.091, 0.014), (0.006, 0.010, 0.015), True)  # burun-dudak kıvrımı
)
JAW_HINGE = Vector((0.0, -0.010, -0.008))
JAW_BLOBS = (M((0.050, 0.000, -0.016), (0.014, 0.020, 0.030))   # çene kolu
             + M((0.052, -0.008, -0.046), (0.017, 0.020, 0.018))  # çene köşesi
             + M((0.038, -0.052, -0.054), (0.016, 0.042, 0.016))  # çene gövdesi
             + [((0.0, -0.088, -0.056), (0.034, 0.022, 0.022), False),   # ileri fırlamış çene ucu
                ((0.0, -0.092, -0.030), (0.030, 0.012, 0.009), False),   # alt dudak
                ((0.0, -0.050, -0.032), (0.032, 0.038, 0.012), True)])   # dil yatağı
EYE_POS = Vector((0.029, -0.071, 0.058))
EYE_RADIUS = 0.0080
EYE_COLOR = (0.44, 0.40, 0.24)
PUPIL_COLOR = (0.03, 0.025, 0.02)
LID_DROOP = 0.45                         # sol üst göz kapağı (göz yarıçapı oranı)
MOUTH_CENTER = Vector((0.0, -0.054, -0.020))
MOUTH_RADII = Vector((0.032, 0.028, 0.028))
MOUTH_FRONT = (0.045, 0.010, 0.009)
MOUTH_BACK = (0.008, 0.0025, 0.002)
TONGUE = ((0.0, -0.052, -0.030), (0.020, 0.024, 0.005))
TONGUE_COLOR = (0.07, 0.022, 0.02)
TOOTH_COLOR = (0.40, 0.35, 0.22)
HAT_COLOR = (0.50, 0.33, 0.02)           # soluk sarı baret
FURROWS = 2


def _scaled(blobs, s):
    return [(tuple(Vector(c) * s), tuple(r * s for r in rad), neg) for c, rad, neg in blobs]


def _furrows(head, s):
    for v in head.data.vertices:
        c = v.co / s
        if c.y < -0.045 and 0.092 < c.z < 0.128 and abs(c.x) < 0.055:
            k = 0.5 + 0.5 * math.cos((c.z - 0.092) / 0.036 * FURROWS * math.tau)
            v.co -= v.normal * 0.0016 * s * k * (1.0 - abs(c.x) / 0.055)


def _teeth(parent, s, mat, rng, upper=True):
    """Üstte seyrek kırık dişler; altta ileri fırlamış çenede üst dudağın önüne çıkan sıra + iki köpek dişi."""
    count = 6 if upper else 7
    for i in range(count):
        a = math.radians(-54 + i * (108 / (count - 1)))
        if upper:
            if i in (1, 4):
                continue                       # eksik dişler
            pos = Vector((0.029 * math.sin(a), -0.080 - 0.016 * math.cos(a), -0.006)) * s
            size, depth = rng.uniform(0.0042, 0.0058) * s, rng.uniform(0.007, 0.012) * s
        else:
            pos = Vector((0.028 * math.sin(a), -0.084 - 0.014 * math.cos(a), -0.034)) * s
            tusk = i in (1, count - 2)
            size = (0.0068 if tusk else rng.uniform(0.0040, 0.0054)) * s
            depth = (0.024 if tusk else rng.uniform(0.010, 0.015)) * s
            pos.z += depth * 0.40
        tooth = kit.primitive("Thrower_ToothU" if upper else "Thrower_ToothL", "cone", pos,
                              radius1=size, depth=depth, segments=6)
        tooth.rotation_euler = (math.radians(180 if upper else 0) + rng.uniform(-0.18, 0.18),
                                rng.uniform(-0.2, 0.2), 0.0)
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
    mesh = bpy.data.meshes.new("Thrower_Mouth")
    bm.to_mesh(mesh)
    bm.free()
    cavity = bpy.data.objects.new("Thrower_Mouth", mesh)
    bpy.context.collection.objects.link(cavity)
    cavity.data.materials.append(mouth_material("M_Thrower_Mouth_" + name, s))
    cavity.parent = head
    tongue_mat, _ = kit.material("M_Thrower_Tongue_" + name, TONGUE_COLOR, rough=0.5)
    tongue = kit.metaball_mesh("Thrower_Tongue", _scaled([(TONGUE[0], TONGUE[1], False)], s),
                               tongue_mat, resolution=0.003)
    tongue.parent = jaw
    for obj in (cavity, tongue):
        for p in obj.data.polygons:
            p.use_smooth = True


def _eyes(head, s, skin, name):
    eye_mat, bsdf = kit.material("M_Thrower_Eye_" + name, EYE_COLOR, rough=0.6)
    bsdf.inputs["Specular IOR Level"].default_value = 0.25
    pupil_mat, _ = kit.material("M_Thrower_Pupil_" + name, PUPIL_COLOR, rough=0.4)
    for sx in (1.0, -1.0):
        guess = Vector((EYE_POS.x * sx, EYE_POS.y, EYE_POS.z)) * s
        hit, loc, _n, _i = head.ray_cast(Vector((guess.x, -0.5, guess.z)), Vector((0.0, 1.0, 0.0)))
        pos = Vector((guess.x, loc.y + EYE_RADIUS * s * 0.45, guess.z)) if hit else guess
        eye = kit.primitive("Thrower_Eye", "sphere", pos, segments=12, rings=8, radius=EYE_RADIUS * s)
        eye.data.materials.append(eye_mat)
        eye.parent = head
        pupil = kit.primitive("Thrower_Pupil", "sphere", pos + Vector((0.0, -EYE_RADIUS * s * 0.78, 0.0)),
                              segments=8, rings=6, radius=EYE_RADIUS * s * 0.36)
        pupil.data.materials.append(pupil_mat)
        pupil.parent = head
        if sx > 0.0:          # sol göz: sarkık kapak (ten rengi yarım kabuk)
            lid = kit.primitive("Thrower_Lid", "sphere", pos + Vector((0.0, 0.0, EYE_RADIUS * s * 0.25)),
                                segments=12, rings=8, radius=EYE_RADIUS * s * 1.12)
            bm = bmesh.new()
            bm.from_mesh(lid.data)
            bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < (0.5 - LID_DROOP) * EYE_RADIUS * s],
                             context="VERTS")
            bm.to_mesh(lid.data)
            bm.free()
            lid.data.materials.append(skin)
            lid.parent = head


def hard_hat(head, s, name, seed):
    """Kırık baret: tepe kubbesi + ön siper; bir dilimi kopuk, kafaya yana yatık oturur."""
    rng = random.Random(int(seed * 100) + 7)
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=20, v_segments=12, radius=1.0)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -0.05], context="VERTS")
    for v in bm.verts:
        ang = math.atan2(v.co.y, v.co.x)
        if -0.4 < ang < 0.9 and v.co.z < 0.75 + 0.15 * math.sin(ang * 7.0):   # kopuk dilim (sol-arka)
            v.tag = True
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if all(v.tag for v in f.verts)], context="FACES")
    for v in bm.verts:
        v.co = Vector((v.co.x * 0.084, v.co.y * 0.094, v.co.z * 0.060)) * s
    mesh = bpy.data.meshes.new("Thrower_Hat")
    bm.to_mesh(mesh)
    bm.free()
    hat = bpy.data.objects.new("Thrower_Hat", mesh)
    bpy.context.collection.objects.link(hat)
    mat = kit.cloth_material("M_Thrower_Hat_" + name, HAT_COLOR, stain=(0.10, 0.07, 0.03))
    hat.data.materials.append(mat)
    sol = hat.modifiers.new("Solid", "SOLIDIFY")
    sol.thickness = 0.006 * s
    kit.apply_all(hat)
    brim = kit.primitive("Thrower_Hat", "sphere", Vector((0.0, -0.080, 0.004)) * s, segments=12, rings=4,
                         radius=0.05 * s)
    brim.scale = (1.15, 0.55, 0.12)
    brim.data.materials.append(mat)
    brim.parent = hat
    for o in (hat, brim):
        for p in o.data.polygons:
            p.use_smooth = True
    hat.parent = head
    hat.location = Vector((0.004, 0.004, 0.098)) * s
    hat.rotation_euler = (math.radians(-8 + rng.uniform(-3, 3)), math.radians(-14), math.radians(6))
    return hat


def build_head(v, skin, tooth_mat, hair_mat, neck, pitch_deg, jaw_deg, roll_deg=0.0, yaw_deg=0.0):
    """Kafa + çene + gözler + ağız (+ baret); boyun üstüne yerleşmiş kafa nesnesini döner."""
    s = v["body"]["head"]
    rng = random.Random(int(v["seed"] * 1000) + 41)
    head = kit.metaball_mesh("Thrower_Head", _scaled(HEAD_BLOBS, s), skin, resolution=0.0032)
    _furrows(head, s)
    style = wh.HAIR_STYLES.get(v.get("hair_style", "bald"))
    if style and hair_mat is not None:
        wh.build_hair(head, s, style, hair_mat, v["seed"])
    _teeth(head, s, tooth_mat, rng, upper=True)
    _eyes(head, s, skin, v["name"])
    jaw = kit.metaball_mesh("Thrower_Jaw", _scaled(JAW_BLOBS, s), skin, resolution=0.003)
    _teeth(jaw, s, tooth_mat, rng, upper=False)
    jaw.parent = head
    jaw.location = JAW_HINGE * s
    jaw.rotation_euler = (math.radians(jaw_deg), 0.0, 0.0)
    _mouth(head, jaw, s, v["name"])
    if v.get("hat"):
        hard_hat(head, s, v["name"], v["seed"])
    head.location = neck + Vector((0.0, -0.026, 0.028)) * s
    head.rotation_euler = (math.radians(pitch_deg), math.radians(roll_deg), math.radians(yaw_deg))
    for obj in [head] + list(head.children_recursive):
        obj.name = obj.name.replace("Walker_", "Thrower_")
    return head
