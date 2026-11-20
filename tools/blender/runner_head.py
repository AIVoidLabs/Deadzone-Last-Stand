"""Koşucu (Pençeli) kafası (V.5 v2): kendi kafası; walker_head yalnız saç için kullanılır.

build_runner.py içe aktarır. Kafa yerel uzayı: köken boyun üstü, yüz -Y, Z yukarı, metre.
Yürüyenden farkı: uzun, köşeli kafatası; ağır tek parça kaş kemeri; keskin ve yüksek elmacık;
derin göz çukurunda hafif parlayan küçük gözler (çığlık öncesi tehdit); dudaksız, geniş açılan
köşeli çene; uzun düzensiz dişler. Kütleler metaball; ince/sert kütleler (kaş, elmacık, çene hattı)
kil görünümünü kırar.
"""
import math
import random

import bmesh
import bpy
from mathutils import Vector

import zombie_kit as kit
import walker_head as wh

M = kit.mirrored
HEAD_BLOBS = (
    [((0.0, 0.018, 0.078), (0.066, 0.090, 0.078), False),      # kafatası (uzun, dar)
     ((0.0, 0.062, 0.058), (0.054, 0.050, 0.058), False),      # art kafa
     ((0.0, -0.052, 0.016), (0.031, 0.030, 0.032), False),     # üst çene (maksilla)
     ((0.0, -0.068, 0.072), (0.040, 0.013, 0.012), False),     # kaş kemeri (tek ağır çubuk)
     ((0.0, -0.082, 0.048), (0.008, 0.010, 0.020), False),     # burun kökü
     ((0.0, -0.090, 0.028), (0.012, 0.011, 0.010), False),     # çökük burun ucu
     ((0.0, 0.026, -0.030), (0.040, 0.040, 0.056), False),     # boyun bağı
     ((0.0, -0.080, -0.016), (0.033, 0.034, 0.020), True)]     # ağız boşluğu (üst)
    + M((0.027, -0.070, 0.076), (0.021, 0.013, 0.011))         # kaş yumruları
    + M((0.045, -0.053, 0.034), (0.016, 0.020, 0.008))         # elmacık (keskin, yüksek)
    + M((0.053, -0.024, 0.032), (0.006, 0.022, 0.006))         # elmacık kemeri, kulağa uzanır
    + M((0.050, -0.010, 0.000), (0.010, 0.016, 0.020))         # çene menteşesi
    + M((0.070, 0.010, 0.038), (0.006, 0.014, 0.018))          # kulak (küçük)
    + M((0.006, -0.095, 0.023), (0.004, 0.005, 0.004), True)   # burun delikleri
    + M((0.027, -0.080, 0.050), (0.019, 0.020, 0.016), True)   # göz çukuru (derin)
    + M((0.044, -0.068, 0.008), (0.016, 0.020, 0.020), True)   # oyuk yanak
    + M((0.068, -0.028, 0.066), (0.010, 0.022, 0.020), True)   # çökük şakak
)
JAW_HINGE = Vector((0.0, -0.008, -0.006))
JAW_BLOBS = (M((0.045, -0.006, -0.022), (0.008, 0.012, 0.021))      # dikey kol (menteşe üstüne taşmaz)
             + M((0.044, -0.014, -0.040), (0.010, 0.012, 0.010))    # çene açısı (köşeli)
             + M((0.032, -0.046, -0.046), (0.008, 0.030, 0.010))    # çene gövdesi
             + [((0.0, -0.074, -0.050), (0.022, 0.013, 0.015), False),
                ((0.0, -0.082, -0.057), (0.012, 0.008, 0.010), False)])  # sivri çene ucu
EYE_POS = Vector((0.027, -0.071, 0.050))
EYE_RADIUS = 0.0072
EYE_COLOR = (1.0, 0.80, 0.42)      # soluk sarı; parıltı gücü abartısız
EYE_GLOW = 2.2
SKULL_CENTER = Vector((0.0, 0.015, 0.068))
MOUTH_CENTER = Vector((0.0, -0.040, -0.030))
MOUTH_RADII = Vector((0.030, 0.028, 0.030))
MOUTH_FRONT = (0.022, 0.0055, 0.0045)   # geniş açık çenede boğaz koyu kalsın (top gibi parlamasın)
MOUTH_BACK = (0.004, 0.0012, 0.0010)
TONGUE_POS = (0.0, -0.044, -0.042)
TONGUE_RADII = (0.016, 0.022, 0.0042)
UPPER_TEETH = 8
LOWER_TEETH = 7


def _scaled(blobs, s):
    return [(tuple(Vector(c) * s), tuple(r * s for r in rr), neg) for c, rr, neg in blobs]


def eye_material(name):
    mat, bsdf = kit.material(name, EYE_COLOR, rough=0.3, emission=EYE_COLOR, strength=EYE_GLOW)
    return mat


def _socket_floor(head, guess, radius):
    hit, loc, _n, _i = head.ray_cast(Vector((guess.x, -0.5, guess.z)), Vector((0.0, 1.0, 0.0)))
    return Vector((guess.x, loc.y + radius * 0.25, guess.z)) if hit else guess


def _tooth(name, pos, length, radius, down, mat, parent, tilt):
    t = kit.primitive(name, "cone", pos, radius1=radius, depth=length, segments=6)
    t.rotation_euler = (math.radians(180.0 + tilt) if down else math.radians(tilt), 0.0, 0.0)
    t.data.materials.append(mat)
    t.parent = parent
    return t


def _teeth_row(parent, s, mat, count, upper, rng):
    """Dudaksız, uzun ve düzensiz diş sırası (U biçimli yay)."""
    for i in range(count):
        a = math.radians(-58 + i * 116 / (count - 1))
        length = (0.017 if upper else 0.014) * rng.uniform(0.75, 1.2) * s
        if upper:
            pos = Vector((0.031 * math.sin(a), -0.082 - 0.020 * math.cos(a), -0.006 - length * 0.35 / s)) * s
        else:
            pos = Vector((0.027 * math.sin(a), -0.070 - 0.012 * math.cos(a), -0.036 + length * 0.35 / s)) * s
        _tooth("Runner_ToothU" if upper else "Runner_ToothL", pos, length, 0.0048 * s, upper, mat, parent,
               rng.uniform(-14.0, 6.0))


def build_jaw(head, s, mat, tooth_mat, rng):
    jaw = kit.metaball_mesh("Runner_Jaw", _scaled(JAW_BLOBS, s), mat, resolution=0.003)
    _teeth_row(jaw, s, tooth_mat, LOWER_TEETH, False, rng)
    jaw.parent = head
    jaw.location = JAW_HINGE * s
    return jaw


def mouth_cavity(head, jaw, s, name):
    """Dişlerin arkasında iç bükey koyu boşluk + çene tabanında dil (walker_head yöntemi, bu kafaya göre)."""
    saved = (wh.MOUTH_CENTER, wh.MOUTH_RADII, wh.MOUTH_FRONT, wh.MOUTH_BACK)
    wh.MOUTH_CENTER, wh.MOUTH_RADII, wh.MOUTH_FRONT, wh.MOUTH_BACK = (MOUTH_CENTER, MOUTH_RADII,
                                                                     MOUTH_FRONT, MOUTH_BACK)
    try:
        mat = wh.mouth_material("M_Runner_Mouth_" + name, s)
        bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        bsdf.inputs["Roughness"].default_value = 0.75
    finally:
        wh.MOUTH_CENTER, wh.MOUTH_RADII, wh.MOUTH_FRONT, wh.MOUTH_BACK = saved
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=1.0)
    bmesh.ops.delete(bm, geom=[vt for vt in bm.verts if vt.co.y < wh.MOUTH_CUT], context="VERTS")
    for vt in bm.verts:
        vt.co = (Vector((vt.co.x * MOUTH_RADII.x, vt.co.y * MOUTH_RADII.y, vt.co.z * MOUTH_RADII.z))
                 + MOUTH_CENTER) * s
    bmesh.ops.reverse_faces(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("Runner_Mouth")
    bm.to_mesh(mesh)
    bm.free()
    cavity = bpy.data.objects.new("Runner_Mouth", mesh)
    bpy.context.collection.objects.link(cavity)
    cavity.data.materials.append(mat)
    cavity.parent = head
    tongue_mat, _ = kit.material("M_Runner_Tongue_" + name, wh.TONGUE_COLOR, rough=0.5)
    tongue = kit.primitive("Runner_Tongue", "sphere", Vector(TONGUE_POS) * s, segments=10, rings=6, radius=1.0)
    tongue.scale = Vector(TONGUE_RADII) * s
    tongue.data.materials.append(tongue_mat)
    tongue.parent = jaw
    for obj in (cavity, tongue):
        for poly in obj.data.polygons:
            poly.use_smooth = True


def build_head(v, mat, tooth_mat, hair_mat):
    """Kafa nesnesi (köken boyun üstü). Çene 'Runner_Jaw' çocuğu; açı/duruş pozda verilir."""
    s = v["body"]["head"]
    rng = random.Random(int(v["seed"] * 100) + 3)
    head = kit.metaball_mesh("Runner_Head", _scaled(HEAD_BLOBS, s), mat, resolution=0.0028)
    style = wh.HAIR_STYLES.get(v.get("hair_style", "bald"))
    if style and hair_mat is not None:
        hair = wh.build_hair(head, s, style, hair_mat, v["seed"])
        hair.name = "Runner_Hair"
    _teeth_row(head, s, tooth_mat, UPPER_TEETH, True, rng)
    eye_mat = eye_material("M_Runner_Eye_" + v["name"])
    for sx in (1.0, -1.0):
        pos = _socket_floor(head, Vector((EYE_POS.x * sx, EYE_POS.y, EYE_POS.z)) * s, EYE_RADIUS * s)
        eye = kit.primitive("Runner_Eye", "sphere", pos, segments=10, rings=6, radius=EYE_RADIUS * s)
        eye.scale = (1.0, 0.8, 0.75)       # kısık, yatık göz
        eye.data.materials.append(eye_mat)
        eye.parent = head
    jaw = build_jaw(head, s, mat, tooth_mat, rng)
    mouth_cavity(head, jaw, s, v["name"])
    return head
