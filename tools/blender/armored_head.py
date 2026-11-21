"""Zırhlı zombinin kafası ve kaskı (7.3): çökük yanaklı çürük yüz + çevik kuvvet kaskı + çatlak vizör.

Yüz kendi metaball kütlelerinden (walker/tank kafası değil): keskin elmacık, çökük yanak, derin göz
çukuru, çürüyüp kısalmış burun (açık burun boşluğu), sağ yanakta et kaybı (dişler görünür), sarkık çene.
Kask yüzün üstünü örter; vizörün alt yarısı kırılıp düşmüş (kenarı tırtıklı), sol gözün önünde darbe
deliği ve ondan yayılan çatlaklar ('crack' köşe özniteliği). Çürük yüz vizörün altından ve delikten görünür.
Kafa yerel uzayı: köken boyun üstü, yüz -Y, Z yukarı, metre (ölçek öncesi).
"""
import math
import random

import bmesh
import bpy
from mathutils import Vector, noise

import armored_mats as am
import zombie_kit as kit

M = kit.mirrored
HEAD_BLOBS = (
    [((0.0, 0.012, 0.058), (0.072, 0.082, 0.070), False),     # kafatası
     ((0.0, 0.045, 0.035), (0.064, 0.054, 0.058), False),     # art kafa
     ((0.0, 0.032, -0.024), (0.052, 0.048, 0.052), False),    # ense
     ((0.0, -0.064, 0.078), (0.060, 0.020, 0.016), False),    # kaş kemeri
     ((0.0, -0.054, 0.030), (0.038, 0.030, 0.034), False),    # orta yüz
     ((0.0, -0.084, 0.055), (0.009, 0.010, 0.014), False),    # burun kökü
     ((0.0, -0.088, 0.036), (0.013, 0.011, 0.011), False),    # çürüyüp kısalmış burun
     ((0.0, -0.094, 0.031), (0.008, 0.008, 0.010), True),     # açık burun boşluğu
     ((0.0, -0.078, 0.006), (0.032, 0.019, 0.013), False),    # üst dudak çevresi
     ((0.0, -0.088, -0.010), (0.024, 0.026, 0.011), True),    # ağız boşluğu
     ((-0.040, -0.078, -0.002), (0.017, 0.018, 0.013), True)]  # sağ yanakta et kaybı
    + M((0.029, -0.072, 0.080), (0.021, 0.018, 0.015))        # kaş tümsekleri
    + M((0.047, -0.054, 0.043), (0.020, 0.021, 0.014))        # keskin elmacık
    + M((0.064, -0.016, 0.058), (0.012, 0.026, 0.022))        # şakak
    + M((0.075, 0.008, 0.034), (0.007, 0.015, 0.018))         # kulak
    + M((0.054, -0.012, -0.004), (0.015, 0.021, 0.025))       # çiğneme kası
    + M((0.028, -0.080, 0.054), (0.019, 0.018, 0.015), True)  # derin göz çukuru
    + M((0.049, -0.060, 0.010), (0.015, 0.015, 0.020), True)  # çökük yanak
    + M((0.029, -0.090, 0.016), (0.006, 0.009, 0.014), True)  # burun-dudak kıvrımı
)
JAW_HINGE = Vector((0.0, -0.012, -0.010))
JAW_BLOBS = (M((0.049, 0.000, -0.016), (0.012, 0.018, 0.027))
             + M((0.049, -0.006, -0.043), (0.015, 0.017, 0.015))
             + M((0.035, -0.045, -0.051), (0.013, 0.035, 0.014))
             + [((0.0, -0.074, -0.054), (0.027, 0.017, 0.019), False),
                ((0.0, -0.077, -0.032), (0.021, 0.007, 0.006), False),
                ((0.0, -0.046, -0.030), (0.029, 0.035, 0.012), True)])
EYE_POS = Vector((0.028, -0.070, 0.054))
EYE_RADIUS = 0.0085
EYE_COLOR = (0.62, 0.55, 0.26)          # sarımsı donuk; oyunda hafif parıltı
PUPIL_COLOR = (0.03, 0.025, 0.02)
MOUTH_CENTER = Vector((0.0, -0.056, -0.022))
MOUTH_RADII = Vector((0.034, 0.030, 0.030))
MOUTH_FRONT = (0.014, 0.004, 0.0035)
MOUTH_BACK = (0.008, 0.0025, 0.002)
TONGUE = ((0.0, -0.050, -0.030), (0.020, 0.024, 0.005))
TONGUE_COLOR = (0.065, 0.02, 0.018)
TOOTH_COLOR = (0.42, 0.37, 0.24)
# Kask: elipsoid kabuk; kesim önde kaşın üstünde, yanda kulak üstünde, arkada ensede
HELMET_CENTER = Vector((0.0, 0.010, 0.060))
HELMET_RADII = Vector((0.094, 0.106, 0.090))
HELMET_CUT = (0.076, -0.012)            # kesim z'si: önde, arkada
HELMET_THICK = 0.011
VISOR_RADII = Vector((0.101, 0.118, 0.097))
VISOR_TOP = 0.090                       # vizör üst kenarı (kaskın altına girer)
VISOR_SIDE = 74.0                       # vizör yan sınırı (derece, önden)
IMPACT = Vector((0.032, -0.104, 0.050)) # darbe deliği (sol göz önü)
HOLE_R = 0.020
CRACKS = 7
VISOR_COLOR = (0.035, 0.042, 0.05)
BOLT_COLOR = (0.30, 0.30, 0.31)


def _scaled(blobs, s):
    return [(tuple(Vector(c) * s), tuple(r * s for r in rad), neg) for c, rad, neg in blobs]


def _teeth(parent, s, mat, rng, upper=True):
    """Kırık, düzensiz dişler; bazıları eksik."""
    count = 8 if upper else 7
    for i in range(count):
        if rng.random() < 0.18:
            continue
        a = math.radians(-58 + i * (116 / (count - 1)))
        if upper:
            pos = Vector((0.028 * math.sin(a), -0.079 - 0.013 * math.cos(a), -0.004)) * s
        else:
            pos = Vector((0.026 * math.sin(a), -0.071 - 0.010 * math.cos(a), -0.033)) * s
        size = rng.uniform(0.0040, 0.0056) * s
        depth = rng.uniform(0.007, 0.012) * s
        tooth = kit.primitive("Armored_ToothU" if upper else "Armored_ToothL", "cone", pos,
                              radius1=size, depth=depth, segments=6)
        tooth.rotation_euler = (math.radians(180 if upper else 0) + rng.uniform(-0.25, 0.25),
                                rng.uniform(-0.25, 0.25), 0.0)
        tooth.data.materials.append(mat)
        tooth.parent = parent


def _mouth(head, jaw, s, name):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=1.0)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.y < -0.1], context="VERTS")
    for v in bm.verts:
        v.co = (Vector((v.co.x * MOUTH_RADII.x, v.co.y * MOUTH_RADII.y, v.co.z * MOUTH_RADII.z)) + MOUTH_CENTER) * s
    bmesh.ops.reverse_faces(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("Armored_Mouth")
    bm.to_mesh(mesh)
    bm.free()
    cavity = bpy.data.objects.new("Armored_Mouth", mesh)
    bpy.context.collection.objects.link(cavity)
    mat, _ = kit.material("M_Armored_Mouth_" + name, MOUTH_FRONT, rough=0.85)
    cavity.data.materials.append(mat)
    cavity.parent = head
    tmat, _ = kit.material("M_Armored_Tongue_" + name, TONGUE_COLOR, rough=0.5)
    tongue = kit.metaball_mesh("Armored_Tongue", _scaled([(TONGUE[0], TONGUE[1], False)], s), tmat,
                               resolution=0.003)
    tongue.parent = jaw


def _eyes(head, s, name):
    eye_mat, bsdf = kit.material("M_Armored_Eye_" + name, EYE_COLOR, rough=0.5,
                                 emission=EYE_COLOR, strength=1.5)
    pupil_mat, _ = kit.material("M_Armored_Pupil_" + name, PUPIL_COLOR, rough=0.4)
    for sx in (1.0, -1.0):
        guess = Vector((EYE_POS.x * sx, EYE_POS.y, EYE_POS.z)) * s
        hit, loc, _n, _i = head.ray_cast(Vector((guess.x, -0.5, guess.z)), Vector((0.0, 1.0, 0.0)))
        pos = Vector((guess.x, loc.y + EYE_RADIUS * s * 0.45, guess.z)) if hit else guess
        eye = kit.primitive("Armored_Eye", "sphere", pos, segments=12, rings=8, radius=EYE_RADIUS * s)
        eye.data.materials.append(eye_mat)
        eye.parent = head
        pupil = kit.primitive("Armored_Pupil", "sphere", pos + Vector((0.0, -EYE_RADIUS * s * 0.78, 0.0)),
                              segments=8, rings=6, radius=EYE_RADIUS * s * 0.34)
        pupil.data.materials.append(pupil_mat)
        pupil.parent = head


# ---------------------------------------------------------------- kask

def _theta(c):
    """Önden açı (derece): 0 tam ön, 180 tam arka."""
    return math.degrees(math.atan2(abs(c.x), -c.y))


def _shell(name, center, radii, keep, thick, s, mat, segs=(48, 32), sub=1):
    """Elipsoid kabuk parçası: keep(yerel_nokta) doğru yüzler kalır, kalınlaştırılır."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segs[0], v_segments=segs[1], radius=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * radii.x, v.co.y * radii.y, v.co.z * radii.z)) + center
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if not keep(f.calc_center_median())], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    kit._relax_boundary(bm, 3)
    for v in bm.verts:
        v.co *= s
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    solid = obj.modifiers.new("Solid", "SOLIDIFY")
    solid.thickness = thick * s
    solid.offset = 1.0
    solid.use_even_offset = True
    if sub:
        obj.modifiers.new("Sub", "SUBSURF").levels = sub
    kit.apply_all(obj)
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def _helmet_keep(c):
    th = _theta(c - HELMET_CENTER)
    k = (1.0 - math.cos(math.radians(th))) * 0.5
    return c.z > HELMET_CUT[0] + (HELMET_CUT[1] - HELMET_CUT[0]) * k


def _visor_keep(seed):
    def keep(c):
        th = _theta(c - HELMET_CENTER)
        if th > VISOR_SIDE or c.z > VISOR_TOP:
            return False
        if (c - IMPACT).length < HOLE_R * (1.0 + 0.45 * noise.noise(c * 160.0 + Vector((seed, 0, 0)))):
            return False
        # alt yarı kırılıp düşmüş: tırtıklı kenar, yanlarda daha aşağı iner
        low = 0.040 - 0.030 * (th / VISOR_SIDE) ** 1.5 + 0.012 * noise.noise(c * 90.0 + Vector((0, seed, 0)))
        return c.z > low
    return keep


def _paint_cracks(obj, s, rng):
    """Darbe noktasından yayılan çatlaklar: 'crack' köşe özniteliği (0..1)."""
    rays = [(rng.uniform(0, math.tau), rng.uniform(0.04, 0.09)) for _ in range(CRACKS)]
    attr = obj.data.attributes.new("crack", "FLOAT", "POINT")
    imp = IMPACT * s
    for v in obj.data.vertices:
        d = v.co - imp
        r = math.hypot(d.x, d.z)
        a = math.atan2(d.z, d.x)
        val = 0.0
        for ang, length in rays:
            da = abs((a - ang + math.pi) % math.tau - math.pi)
            wiggle = 0.12 * math.sin(r / s * 180.0 + ang * 5.0)
            if r < length * s and abs(da - wiggle) < 0.035:
                val = max(val, 1.0 - r / (length * s))
        if r < HOLE_R * s * 1.25:
            val = max(val, 0.6)
        attr.data[v.index].value = val


def build_helmet(head, v, s):
    """Kask kabuğu + vizör + menteşe vidaları; kafaya bağlı."""
    rng = random.Random(int(v["seed"] * 1000) + 77)
    suffix = "_" + v["name"]
    plastic = am.plastic("M_Armored_Helmet" + suffix, v["helmet"])
    helmet = _shell("Armored_Helmet", HELMET_CENTER, HELMET_RADII, _helmet_keep, HELMET_THICK, s, plastic)
    am.assign(helmet, [("plastic", v["helmet"])], "M_Armored_Helmet" + suffix)
    helmet.parent = head
    out = [helmet]
    if v.get("visor", True):
        vmat = am.visor("M_Armored_Visor" + suffix)
        visor = _shell("Armored_Visor", HELMET_CENTER, VISOR_RADII, _visor_keep(v["seed"]), 0.005, s, vmat,
                       segs=(192, 128), sub=0)
        _paint_cracks(visor, s, rng)
        am.assign(visor, [("visor", VISOR_COLOR)], "M_Armored_Visor" + suffix)
        visor.parent = head
        out.append(visor)
        for sx in (1.0, -1.0):         # menteşe vidaları (metal)
            pos = Vector((sx * 0.097, -0.020, 0.074)) * s
            bolt = kit.primitive("Armored_Bolt", "sphere", pos, segments=10, rings=6, radius=0.012 * s)
            bolt.scale = (0.5, 1.0, 1.0)
            am.assign(bolt, [("metal", BOLT_COLOR)], "M_Armored_Bolt" + suffix)
            bolt.parent = head
            out.append(bolt)
    return out


def build_head(v, skin, tooth_mat, neck, pitch_deg, jaw_deg, yaw_deg=0.0):
    s = v["body"]["head"]
    rng = random.Random(int(v["seed"] * 1000) + 41)
    head = kit.metaball_mesh("Armored_Head", _scaled(HEAD_BLOBS, s), skin, resolution=0.0030)
    _teeth(head, s, tooth_mat, rng, upper=True)
    _eyes(head, s, v["name"])
    jaw = kit.metaball_mesh("Armored_Jaw", _scaled(JAW_BLOBS, s), skin, resolution=0.003)
    _teeth(jaw, s, tooth_mat, rng, upper=False)
    jaw.parent = head
    jaw.location = JAW_HINGE * s
    jaw.rotation_euler = (math.radians(jaw_deg), 0.0, 0.0)
    _mouth(head, jaw, s, v["name"])
    build_helmet(head, v, s)
    head.location = neck + Vector((0.0, -0.028, 0.028)) * s
    head.rotation_euler = (math.radians(pitch_deg), 0.0, math.radians(yaw_deg))
    return head
