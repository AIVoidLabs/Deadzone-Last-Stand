"""Boss "Yığın" kafası (7.4): kamburun altına, omuzların arasına gömülü, öne uzanmış iri ve ağır kafa.

Ağır kaş kemeri, derin göz çukurlarında küçük kızıl parlayan gözler (kalple akraba), kırık burun,
kafa derisinde kaynak dikişleri gibi oluklar, alt çenesi öne çıkık (alt çene ileri), kırık sivri dişler.
Yöntem bloater_head ile aynı (kütleler + oyuklar, iç bükey ağız boşluğu, yassı dil), kendi verisiyle.
Kafa yerel uzayı: köken boyun üstü, yüz -Y, Z yukarı, yapı birimi (ölçek öncesi). build_boss içe aktarır.
"""
import math
import random

import bmesh
import bpy
from mathutils import Vector

import zombie_kit as kit

M = kit.mirrored
HEAD_BLOBS = (
    [((0.0, 0.020, 0.060), (0.080, 0.086, 0.070), False),     # kafatası (basık, geniş)
     ((0.0, 0.050, 0.020), (0.074, 0.062, 0.062), False),     # art kafa
     ((0.0, 0.030, -0.035), (0.090, 0.072, 0.060), False),    # kalın ense
     ((0.0, -0.066, 0.080), (0.074, 0.028, 0.022), False),    # ağır kaş kemeri
     ((0.0, -0.056, 0.026), (0.048, 0.036, 0.040), False),    # orta yüz
     ((0.004, -0.094, 0.040), (0.015, 0.016, 0.024), False),  # kırık burun
     ((0.0, -0.082, 0.000), (0.044, 0.020, 0.012), False),    # üst dudak
     ((0.0, -0.092, -0.014), (0.034, 0.034, 0.016), True),    # ağız boşluğu
     ((0.0, 0.020, 0.128), (0.006, 0.090, 0.008), True)]      # kafa derisi dikiş oluğu
    + M((0.036, -0.078, 0.082), (0.030, 0.022, 0.018))       # kaş tümsekleri
    + M((0.056, -0.054, 0.044), (0.024, 0.024, 0.018))       # elmacık
    + M((0.064, -0.036, -0.004), (0.030, 0.032, 0.034))      # yanak
    + M((0.082, 0.004, 0.036), (0.012, 0.018, 0.022))        # kulak
    + M((0.032, -0.090, 0.050), (0.019, 0.018, 0.016), True)  # derin göz çukuru
    + M((0.040, -0.094, 0.012), (0.006, 0.010, 0.016), True)  # burun-dudak kıvrımı
    + M((0.050, 0.030, 0.100), (0.006, 0.060, 0.007), True)   # yan dikiş olukları
)
JAW_HINGE = Vector((0.0, -0.010, -0.012))
JAW_BLOBS = (M((0.060, 0.000, -0.020), (0.020, 0.026, 0.034))     # çene kolu
             + M((0.056, -0.040, -0.052), (0.030, 0.034, 0.028))  # geniş çene hattı
             + [((0.0, -0.090, -0.056), (0.046, 0.026, 0.026), False),   # öne çıkık çene ucu
                ((0.0, -0.098, -0.030), (0.040, 0.016, 0.013), False),   # kalın alt dudak
                ((0.0, -0.054, -0.030), (0.038, 0.044, 0.014), True)])   # dil yatağı
EYE_POS = Vector((0.032, -0.088, 0.050))
EYE_RADIUS = 0.0080
EYE_COLOR = (0.95, 0.10, 0.04)          # kızıl parıltı (kalple akraba)
PUPIL_COLOR = (0.08, 0.0, 0.0)
MOUTH_CENTER = Vector((0.0, -0.058, -0.022))
MOUTH_RADII = Vector((0.038, 0.032, 0.032))
MOUTH_FRONT = (0.055, 0.012, 0.008)
MOUTH_BACK = (0.010, 0.003, 0.002)
TONGUE = ((0.0, -0.056, -0.030), (0.022, 0.028, 0.0065))
TONGUE_COLOR = (0.09, 0.03, 0.015)
TOOTH_COLOR = (0.42, 0.36, 0.22)


def _scaled(blobs, s):
    return [(tuple(Vector(c) * s), tuple(r * s for r in rad), neg) for c, rad, neg in blobs]


def _teeth(parent, s, mat, rng, upper=True):
    """Seyrek kırık dişler; alt çenede iki uzun yan diş (alt çene ileri: dişler üst dudağı aşar)."""
    count = 7 if upper else 8
    for i in range(count):
        if rng.random() < 0.2:
            continue
        a = math.radians(-58 + i * (116 / (count - 1)))
        tusk = (not upper) and i in (1, count - 2)
        if upper:
            pos = Vector((0.032 * math.sin(a), -0.084 - 0.016 * math.cos(a), -0.006)) * s
        else:
            pos = Vector((0.034 * math.sin(a), -0.092 - 0.012 * math.cos(a), -0.030)) * s
        size = (0.0085 if tusk else rng.uniform(0.0045, 0.0062)) * s
        depth = (0.026 if tusk else rng.uniform(0.009, 0.013)) * s
        tooth = kit.primitive("Boss_ToothU" if upper else "Boss_ToothL", "cone", pos,
                              radius1=size, depth=depth, segments=6)
        tooth.rotation_euler = (math.radians(180 if upper else 0) + rng.uniform(-0.2, 0.2),
                                rng.uniform(-0.25, 0.25), 0.0)
        tooth.data.materials.append(mat)
        tooth.parent = parent


def _mouth(head, jaw, s, mat, tongue_mat):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=1.0)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.y < -0.1], context="VERTS")
    for v in bm.verts:
        v.co = (Vector((v.co.x * MOUTH_RADII.x, v.co.y * MOUTH_RADII.y, v.co.z * MOUTH_RADII.z))
                + MOUTH_CENTER) * s
    bmesh.ops.reverse_faces(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("Boss_Mouth")
    bm.to_mesh(mesh)
    bm.free()
    cavity = bpy.data.objects.new("Boss_Mouth", mesh)
    bpy.context.collection.objects.link(cavity)
    cavity.data.materials.append(mat)
    cavity.parent = head
    tongue = kit.metaball_mesh("Boss_Tongue", _scaled([(TONGUE[0], TONGUE[1], False)], s),
                               tongue_mat, resolution=0.004)
    tongue.parent = jaw
    for obj in (cavity, tongue):
        for p in obj.data.polygons:
            p.use_smooth = True


def _eyes(head, s, mat):
    for sx in (1.0, -1.0):
        guess = Vector((EYE_POS.x * sx, EYE_POS.y, EYE_POS.z)) * s
        hit, loc, _n, _i = head.ray_cast(Vector((guess.x, -0.5, guess.z)), Vector((0.0, 1.0, 0.0)))
        pos = Vector((guess.x, loc.y + EYE_RADIUS * s * 0.5, guess.z)) if hit else guess
        eye = kit.primitive("Boss_Eye", "sphere", pos, segments=10, rings=6, radius=EYE_RADIUS * s)
        eye.data.materials.append(mat)
        eye.parent = head


def build_head(s, mat, neck, pitch_deg, jaw_deg, seed=3.3):
    """Kafa + çene + gözler + ağız; tüm parçalar aynı (köşe rengi) malzemeyle, ad önekiyle ayrılır."""
    rng = random.Random(int(seed * 1000) + 41)
    head = kit.metaball_mesh("Boss_Head", _scaled(HEAD_BLOBS, s), mat, resolution=0.0045)
    _teeth(head, s, mat, rng, upper=True)
    _eyes(head, s, mat)
    jaw = kit.metaball_mesh("Boss_Jaw", _scaled(JAW_BLOBS, s), mat, resolution=0.0045)
    for p in jaw.data.polygons:
        p.use_smooth = True
    _teeth(jaw, s, mat, rng, upper=False)
    jaw.parent = head
    jaw.location = JAW_HINGE * s
    jaw.rotation_euler = (math.radians(jaw_deg), 0.0, 0.0)
    _mouth(head, jaw, s, mat, mat)
    head.location = neck + Vector((0.0, -0.020, 0.010)) * s
    head.rotation_euler = (math.radians(pitch_deg), 0.0, 0.0)
    return head
