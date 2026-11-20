"""Tank zombisinin parçaları (V.5 konsept): kas kütleleri, yumruklar, sırt kemik plakaları, kafa.

build_tank.py içe aktarır. Kütleler ve yumruklar gövde ağına eklenip voxel remesh ile kaynaşır;
plakalar gövde yüzeyine ışınla oturtulur (poz ne olursa olsun sırtı izler).
Kafa: walker_head.build_head yeniden kullanılır; yalnız kafa/çene kütleleri geçici olarak
tankınkilerle değiştirilir (paylaşılan dosya düzenlenmez, çalışma anında yer değiştirme).
"""
import math
import random

import bmesh
import bpy
from mathutils import Matrix, Quaternion, Vector, noise

import walker_head as wh
import zombie_kit as kit

UP = Vector((0.0, 0.0, 1.0))

# ---------------------------------------------------------------- kas kütleleri
# (ad, A noktası, B noktası, A->B oranı, ek ofset (m), yarıçaplar (m), uzuv boyunca mı)
# Kütle merkezi lerp(A, B, t) + ofset; uzuv boyunca olanlar o yöne döndürülür.
MASSES = [
    ("trap", "hump", "shoulder", 0.42, (0.0, 0.02, 0.07), (0.18, 0.15, 0.13), False),
    ("delt", "shoulder", "elbow", 0.10, (0.0, -0.01, 0.0), (0.17, 0.17, 0.19), True),
    ("pec", "chest", "shoulder", 0.42, (0.0, -0.17, -0.06), (0.17, 0.10, 0.13), False),
    ("lat", "spine", "shoulder", 0.50, (0.0, 0.10, -0.05), (0.13, 0.15, 0.22), False),
    ("bicep", "shoulder", "elbow", 0.55, (0.0, -0.02, 0.0), (0.12, 0.12, 0.22), True),
    ("fore", "elbow", "wrist", 0.45, (0.0, -0.01, 0.0), (0.145, 0.14, 0.28), True),
    ("thigh", "hip", "knee", 0.38, (0.0, -0.02, 0.0), (0.17, 0.17, 0.22), True),
    ("calf", "knee", "ankle", 0.32, (0.0, 0.05, 0.0), (0.12, 0.12, 0.16), True),
]
LEGS = ("hip", "knee", "ankle", "heel", "ball", "toe", "thigh", "calf")


def _limb_quat(a, b):
    return (b - a).normalized().to_track_quat("Z", "Y")


def masses(pts, body):
    """Kas kütleleri (metaball): [(merkez, yarıçaplar, dönüş, negatif)]."""
    blobs = []
    t = body["t"]
    for name, a, b, f, off, radii, along in MASSES:
        for side, sx in (("L", 1.0), ("R", -1.0)):
            pa = pts[a if a in ("hump", "chest", "spine") else f"{a}_{side}"][0]
            pb = pts[f"{b}_{side}"][0]
            c = pa.lerp(pb, f) + Vector((off[0] * sx, off[1], off[2]))
            q = _limb_quat(pa, pb) if along else Quaternion()
            k = body.get("legs", 1.0) if name in LEGS else t
            blobs.append((tuple(c), tuple(r * k for r in radii), q, False))
    gut = pts["belly"][0] + Vector((0.0, -0.07, -0.03))
    g = body["belly"]
    blobs.append((tuple(gut), (0.25 * g, 0.20 * g, 0.22 * g), Quaternion(), False))
    return blobs


def fist_blobs(pts, side, t):
    """Dev yumruk: avuç bloğu + dört boğum + kıvrık parmaklar + başparmak."""
    wrist, fist = pts[f"wrist_{side}"][0], pts[f"fist_{side}"][0]
    d = (fist - wrist).normalized()
    front = Vector((0.0, -1.0, 0.0))
    front = (front - d * front.dot(d))
    front = front.normalized() if front.length > 1e-3 else Vector((0.0, 0.0, 1.0))
    across = d.cross(front).normalized()
    inward = across if across.x * fist.x < 0.0 else -across
    q = Matrix((across, front, d)).transposed().to_quaternion()
    s = t
    blobs = [(tuple(fist), (0.115 * s, 0.10 * s, 0.12 * s), q, False)]
    for i in range(4):
        o = (i - 1.5) * 0.056 * s
        k = fist + d * 0.085 * s + front * 0.055 * s + across * o
        blobs.append((tuple(k), (0.036 * s, 0.036 * s, 0.034 * s), q, False))
        f = fist + d * 0.11 * s - front * 0.01 * s + across * o
        blobs.append((tuple(f), (0.032 * s, 0.045 * s, 0.03 * s), q, False))
    th = fist + inward * 0.09 * s + front * 0.05 * s + d * 0.02 * s
    blobs.append((tuple(th), (0.036 * s, 0.05 * s, 0.035 * s), q, False))
    return blobs


def toe_blobs(pts, side):
    """Çıplak ayakta geniş, kalın beş parmak (topuz ayak olmasın)."""
    ball, toe = pts[f"ball_{side}"][0], pts[f"toe_{side}"][0]
    fwd = (toe - ball)
    fwd.z = 0.0
    fwd.normalize()
    across = fwd.cross(UP).normalized()
    q = Matrix((across, fwd, UP)).transposed().to_quaternion()
    sx = 1.0 if ball.x > 0 else -1.0
    blobs = []
    for i, (o, r, ln) in enumerate(((-0.055, 0.030, 0.040), (-0.020, 0.024, 0.034), (0.010, 0.022, 0.030),
                                    (0.036, 0.020, 0.026), (0.058, 0.018, 0.022))):
        c = toe - across * o * sx +fwd * (0.02 - 0.01 * i) - UP * (toe.z - r * 0.85)
        blobs.append((tuple(c), (r, ln, r * 0.85), q, False))
    return blobs


def add_blobs(obj, blobs, resolution=0.012):
    """Metaball kütlelerini gövde ağına ekler (voxel remesh sonra kaynaştırır)."""
    extra = kit.metaball_oriented("Tank_Mass", blobs, obj.active_material, resolution=resolution, smooth=0)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.from_mesh(extra.data)
    bm.to_mesh(obj.data)
    bm.free()
    mesh = extra.data
    bpy.data.objects.remove(extra)
    bpy.data.meshes.remove(mesh)


# ---------------------------------------------------------------- kemik plakalar
# Sırt sırası: (A, B, oran, açı: 0 = tam arkaya, 90 = tam yukarı, yan açı, boy, taban boyu)
PLATES = [
    ("spine", "chest", 0.20, 40, 0, 0.18, 0.10),
    ("spine", "chest", 0.80, 50, 0, 0.28, 0.12),
    ("chest", "hump", 0.55, 64, 0, 0.38, 0.14),
    ("hump", "neck0", 0.05, 82, 0, 0.42, 0.15),
    ("hump", "neck0", 0.42, 104, 0, 0.24, 0.11),
    # kürek kemiği çiftleri: yandan dışa açılır (önden/yukarıdan kamburu taç gibi çevreler)
    ("spine", "chest", 0.85, 46, 50, 0.22, 0.10),
    ("chest", "hump", 0.45, 60, 56, 0.32, 0.12),
    ("hump", "neck0", 0.10, 78, 62, 0.34, 0.12),
]
WOUNDS = False            # plaka tabanında ayrı et halkası (v1 denemesi: tabak gibi durdu)
PLATE_ROUND = 0.65        # kalınlık / taban boyu (düşük = yassı cips, yüksek = yuvarlak diken)
PLATE_SWEEP = 0.30        # uç geriye (kuyruğa) bükülme oranı
PLATE_THICK = 0.040       # taban kalınlığı (m); taban boyunun en az yarısı (tıknaz kemik)


def plate_spots(body_obj, pts, lean):
    """Her plakanın yüzeydeki tabanı: (konum, yukarı, ileri(kafaya), boy, taban, yan işareti)."""
    spots = []
    rot = Matrix.Rotation(lean, 3, "X")
    back = rot @ Vector((0.0, 1.0, 0.0))
    up = rot @ UP
    for a, b, f, ang, side_ang, size, base in PLATES:
        pa, pb = pts[a][0], pts[b][0]
        anchor = pa.lerp(pb, f)
        tangent = (pb - pa).normalized()
        for sx in ((1.0, -1.0) if side_ang else (0.0,)):
            ang_r = math.radians(ang)
            d = back * math.cos(ang_r) + up * math.sin(ang_r)
            if sx:
                d = (Matrix.Rotation(math.radians(side_ang) * sx, 3, tangent) @ d).normalized()
                anchor_s = anchor + Vector((0.14 * sx, 0.0, 0.0))
            else:
                anchor_s = anchor
            origin = anchor_s + d * 1.5
            hit, loc, normal, _i = body_obj.ray_cast(origin, -d)
            if not hit:
                continue
            u = (normal * 0.35 + d * 0.65).normalized()
            fwd = (tangent - u * tangent.dot(u)).normalized()
            spots.append((loc, u, fwd, size, base, sx))
    return spots


def build_plate(spot, mat, wound_mat, rng, k=1.0):
    """Bıçak gibi yassı, uca doğru sivrilen, geriye bükük kemik plaka + tabanında yırtık et."""
    loc, up, fwd, size, base, _sx = spot
    size, base = size * k * rng.uniform(0.9, 1.1), base * k
    side = fwd.cross(up).normalized()
    bm = bmesh.new()
    rings, n_ring, steps = [], 10, 7
    for i in range(steps):
        f = i / steps
        c = loc + up * (size * f - 0.05) - fwd * size * PLATE_SWEEP * f * f
        c += side * 0.012 * math.sin(f * 3.0 + rng.random() * 3.0)
        length = base * (1.0 - f) ** 0.85 + 0.012
        thick = max(PLATE_THICK * k, base * PLATE_ROUND) * (1.0 - 0.75 * f)
        ring = []
        for j in range(n_ring):
            a = 2.0 * math.pi * j / n_ring
            ring.append(bm.verts.new(c + fwd * math.cos(a) * length + side * math.sin(a) * thick))
        rings.append(ring)
    tip = bm.verts.new(loc + up * (size - 0.04) - fwd * size * (PLATE_SWEEP + 0.08))
    for r0, r1 in zip(rings, rings[1:]):
        for j in range(n_ring):
            bm.faces.new((r0[j], r0[(j + 1) % n_ring], r1[(j + 1) % n_ring], r1[j]))
    for j in range(n_ring):
        bm.faces.new((rings[-1][j], rings[-1][(j + 1) % n_ring], tip))
    bm.faces.new(list(reversed(rings[0])))
    mesh = bpy.data.meshes.new("Tank_Plate")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Tank_Plate", mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    sub = obj.modifiers.new("Sub", "SUBSURF")
    sub.levels = 2
    kit.apply_all(obj)
    seed = Vector((rng.random() * 50.0, rng.random() * 50.0, 0.0))
    for v in obj.data.vertices:   # kemik yüzeyi: hafif oyuk ve sırt
        v.co += v.normal * 0.004 * noise.noise(v.co * 28.0 + seed)
    for p in obj.data.polygons:
        p.use_smooth = True
    q = Matrix((fwd, side, up)).transposed().to_quaternion()
    if not WOUNDS:
        return obj, None
    wound = kit.metaball_oriented("Tank_Wound", [
        (tuple(loc - up * 0.012), (base * 1.15, max(PLATE_THICK * k, base * PLATE_ROUND) * 2.0, 0.022), q, False),
        (tuple(loc - up * 0.010 - fwd * base * 0.6), (base * 0.55, max(PLATE_THICK * k, base * PLATE_ROUND) * 1.4, 0.018), q, False)],
        wound_mat, resolution=0.008, smooth=2)
    return obj, wound


def bone_material(name, color=(0.72, 0.57, 0.30)):
    """Kemik: sarımsı kirli beyaz, uca doğru açılır; tabanda kanlı kahve; gözenekli pürüz."""
    mat, bsdf = kit.material(name, color, rough=0.5, sss=0.05)
    nt = mat.node_tree
    dirty = (0.30, 0.20, 0.09)   # boyuna kirli damarlar: cips gibi benekli olmasın
    ramp = kit._mottle(nt, 3.0, dirty, color, low=0.50, high=0.90)
    ao =nt.nodes.new("ShaderNodeAmbientOcclusion")
    ao.inputs["Distance"].default_value = 0.08
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.inputs["A"].default_value = (0.13, 0.025, 0.02, 1.0)     # tabanda kan
    nt.links.new(ao.outputs["AO"], mix.inputs["Factor"])
    nt.links.new(ramp.outputs["Color"], mix.inputs["B"])
    nt.links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
    kit._bump(nt, bsdf, 25.0, 0.12)
    return mat


def wound_material(name):
    mat, bsdf = kit.material(name, (0.085, 0.018, 0.016), rough=0.45, sss=0.1, coat=0.15)
    kit._bump(mat.node_tree, bsdf, 30.0, 0.4)
    return mat


# ---------------------------------------------------------------- kafa
# Kaba, kalın kafa: ağır kaş kemeri, geniş elmacık, kalın ense; oyuk yanak/şakak yok.
HEAD_BLOBS = (
    [((0.0, 0.012, 0.064), (0.080, 0.090, 0.082), False),     # kafatası (alçak)
     ((0.0, 0.050, 0.040), (0.070, 0.062, 0.064), False),     # art kafa
     ((0.0, -0.060, 0.022), (0.040, 0.030, 0.034), False),    # orta yüz
     ((0.0, -0.092, 0.036), (0.016, 0.016, 0.020), False),    # yassı geniş burun
     ((0.0, -0.074, 0.080), (0.064, 0.022, 0.018), False),    # ağır kaş kemeri
     ((0.0, 0.035, -0.035), (0.075, 0.070, 0.070), False),    # kalın ense
     ((0.0, -0.088, -0.018), (0.032, 0.034, 0.020), True)]    # ağız boşluğu
    + kit.mirrored((0.050, -0.056, 0.032), (0.020, 0.020, 0.014))   # geniş elmacık
    + kit.mirrored((0.058, -0.012, 0.000), (0.016, 0.020, 0.024))   # çene menteşesi
    + kit.mirrored((0.080, 0.006, 0.034), (0.007, 0.014, 0.018))    # kulak (ezik)
    + kit.mirrored((0.029, -0.086, 0.054), (0.020, 0.022, 0.016), True)  # göz çukuru
)
JAW_BLOBS = (kit.mirrored((0.052, -0.004, -0.014), (0.013, 0.016, 0.030))
             + kit.mirrored((0.040, -0.050, -0.046), (0.014, 0.030, 0.016))
             + [((0.0, -0.076, -0.052), (0.032, 0.018, 0.020), False)])


def build_head(v, skin, tooth_mat, hair_mat, neck, pitch_deg, jaw_deg):
    """walker_head.build_head'i tank kütleleriyle çalıştırır, sonra kafayı yerine koyar."""
    saved = wh.HEAD_BLOBS, wh.JAW_BLOBS
    wh.HEAD_BLOBS, wh.JAW_BLOBS = HEAD_BLOBS, JAW_BLOBS
    try:
        head = wh.build_head(v, skin, tooth_mat, hair_mat, neck, 1.0)
    finally:
        wh.HEAD_BLOBS, wh.JAW_BLOBS = saved
    s = v["body"]["head"]
    head.location = neck + Vector((0.0, -0.035, 0.035)) * s
    head.rotation_euler = (math.radians(pitch_deg), 0.0, math.radians(v.get("head_yaw", 0.0)))
    jaw = next(c for c in head.children if c.name.startswith("Walker_Jaw"))
    jaw.rotation_euler.x = math.radians(jaw_deg)
    return head


def rng_for(v):
    return random.Random(int(v["seed"] * 1000) + 5)
