"""Yürüyen zombinin kafası: çökük insan yüzü, sarkık çene, donuk gözler, seyrek saç (V.5 v2).

build_walker.py içe aktarır. Kafa yerel uzayı: köken boyun üstü, yüz -Y, Z yukarı, metre.
Saç kask değil: kafa derisine oturan, kenarı sıfıra incelen ince taban + uca doğru sivrilen
yassı tutamlar; dökülme yamalarında kafa derisi görünür. Çeşit başına üslup (kel / kısa /
seyrek / uzun yağlı).
"""
import heapq
import math
import random

import bmesh
import bpy

from mathutils import Matrix, Vector, noise

import zombie_kit as kit

# Sıska, çökük yüz: dar orta yüz, keskin elmacık, oyuk yanak ve şakak, derin göz çukuru.
HEAD_BLOBS = (
    [((0.0, 0.010, 0.070), (0.076, 0.090, 0.088), False),     # kafatası
     ((0.0, 0.050, 0.050), (0.062, 0.058, 0.064), False),     # art kafa
     ((0.0, -0.058, 0.020), (0.030, 0.028, 0.032), False),    # orta yüz (dar)
     ((0.0, -0.090, 0.040), (0.010, 0.016, 0.024), False),    # burun
     ((0.0, 0.020, -0.030), (0.042, 0.044, 0.060), False),    # boyun bağı
     ((0.0, -0.088, -0.018), (0.030, 0.034, 0.020), True)]    # ağız boşluğu
    + kit.mirrored((0.040, -0.058, 0.036), (0.013, 0.016, 0.009))   # elmacık kemiği (keskin)
    + kit.mirrored((0.025, -0.066, 0.080), (0.021, 0.012, 0.010))   # kaş kemeri
    + kit.mirrored((0.052, -0.014, 0.000), (0.011, 0.017, 0.020))  # çene menteşesi
    + kit.mirrored((0.078, 0.004, 0.036), (0.007, 0.015, 0.021))    # kulak
    + kit.mirrored((0.029, -0.084, 0.054), (0.021, 0.024, 0.020), True)  # göz çukuru (derin)
    + kit.mirrored((0.046, -0.068, 0.010), (0.018, 0.022, 0.020), True)  # oyuk yanak
    + kit.mirrored((0.076, -0.030, 0.070), (0.010, 0.020, 0.018), True)  # çökük şakak
)
EYE_POS = Vector((0.030, -0.069, 0.050))
EYE_RADIUS = 0.0078
JAW_HINGE = Vector((0.0, -0.010, -0.006))
JAW_BLOBS = (kit.mirrored((0.046, -0.004, -0.012), (0.009, 0.014, 0.028))
             + kit.mirrored((0.034, -0.048, -0.044), (0.010, 0.028, 0.013))
             + [((0.0, -0.072, -0.048), (0.024, 0.015, 0.017), False)])
JAW_OPEN_DEG = 30.0       # sarkık çene
JAW_SLACK_DEG = 6.0       # yana kaymış
HEAD_PITCH_DEG = 18.0     # öne düşük
HEAD_ROLL_DEG = 22.0      # düşük omuza (+X) yatık
HEAD_YAW_DEG = -8.0
SKULL_CENTER = Vector((0.0, 0.012, 0.062))

# Saç üslupları. Saç iki katman: (1) kafa derisinden kopyalanan ince taban (kenara doğru sıfıra
# incelir, kask kenarı yok; dökülme yamalarında kafa derisi görünür), (2) tabandan çıkan,
# kafa derisini izleyip uca doğru sivrilen yassı tutamlar (az sayıda kütle, ince şerit değil).
# density: taban bölgesinin tutulan oranı; crown_loss: tepede ek dökülme; patch: yama ölçeği;
# base: taban kalınlığı (m); locks: tutam sayısı; length/width/thick: tutam ölçüsü (m);
# spread: tutam yön dağınıklığı (radyan); hang: tutamlar kafatasından sonra aşağı sarkar;
# hairline: alın çizgisi (yerel y); low/top_z: saç bölgesinin alt / üst sınırı (z);
# rough: pürüz (yağlı saç düşük).
HAIR_STYLES = {
    "bald": None,
    "fringe": {"density": 0.72, "crown_loss": 1.0, "patch": 26.0, "base": 0.0022, "locks": 14,
               "length": 0.020, "width": 0.009, "thick": 0.0030, "spread": 0.9, "hang": False,
               "hairline": 0.030, "low": 0.010, "top_z": 0.100, "rough": 0.85},
    "short": {"density": 0.64, "crown_loss": 0.35, "patch": 13.0, "base": 0.0030, "locks": 80,
              "length": 0.048, "width": 0.0110, "thick": 0.0068, "spread": 0.55, "hang": False,
              "hairline": -0.050, "low": 0.022, "top_z": 1.0, "rough": 0.8},
    "sparse": {"density": 0.56, "crown_loss": 0.25, "patch": 20.0, "base": 0.0022, "locks": 42,
               "length": 0.040, "width": 0.0095, "thick": 0.0055, "spread": 0.9, "hang": False,
               "hairline": -0.030, "low": 0.025, "top_z": 1.0, "rough": 0.8},
    "long": {"density": 0.62, "crown_loss": 0.50, "patch": 14.0, "base": 0.0026, "locks": 64,
             "length": 0.130, "width": 0.0120, "thick": 0.0055, "spread": 0.35, "hang": True,
             "hairline": -0.035, "low": 0.004, "top_z": 1.0, "rough": 0.42},
}
HAIR_FLOW = Vector((0.0, 0.55, -0.6))   # saç akışı: geriye-aşağı
LOCK_RING = 6                           # tutam kesiti köşe sayısı (mercek biçimi)


def _scaled_blobs(blobs, s):
    return [(tuple(Vector(c) * s), tuple(r_ * s for r_ in r), neg) for c, r, neg in blobs]


def eye_material(name):
    """Donuk, süt beyazı göz: parıltı yok (yüksek pürüz, emisyon yok), hafif bulanık gri merkez."""
    mat, bsdf = kit.material(name, (0.30, 0.31, 0.27), rough=0.85)
    bsdf.inputs["Specular IOR Level"].default_value = 0.1
    return mat


def hair_material(name, color, rough=0.8):
    """Saç: koyu-açık tel alacası + ince tel pürüzü; yağlı saçta düşük pürüz."""
    mat, bsdf = kit.material(name, color, rough=rough)
    nt = mat.node_tree
    light = tuple(min(1.0, c * 1.6 + 0.005) for c in color)
    ramp = kit._mottle(nt, 140.0, color, light, low=0.40, high=0.80)
    kit._ao_darken(nt, ramp.outputs["Color"], bsdf, crevice=(0.01, 0.01, 0.01))
    kit._bump(nt, bsdf, 420.0, 0.15)
    bsdf.inputs["Specular IOR Level"].default_value = 0.3
    return mat


def build_head(v, mat, tooth_mat, hair_mat, neck, h):
    s = v["body"]["head"]
    head = kit.metaball_mesh("Walker_Head", _scaled_blobs(HEAD_BLOBS, s), mat)
    style = HAIR_STYLES.get(v.get("hair_style", "bald"))
    if style and hair_mat is not None:
        build_hair(head, s, style, hair_mat, v["seed"])
    _teeth(head, s, tooth_mat)
    eye_mat = eye_material("M_Walker_Eye_" + v["name"])
    for sx in (1.0, -1.0):
        pos = _socket_floor(head, Vector((EYE_POS.x * sx, EYE_POS.y, EYE_POS.z)) * s, EYE_RADIUS * s)
        eye = kit.primitive("Walker_Eye", "sphere", pos, segments=12, rings=8, radius=EYE_RADIUS * s)
        eye.data.materials.append(eye_mat)
        eye.parent = head
    # koyu ağız içi: sarkık çenenin açtığı boşluk karanlık okunsun
    mouth_mat, _ = kit.material("M_Walker_Mouth_" + v["name"], (0.005, 0.0015, 0.0015), rough=1.0)
    mouth = kit.metaball_mesh("Walker_Mouth", [((0.0, -0.042, -0.030), (0.030, 0.026, 0.032), False)],
                              mouth_mat, resolution=0.004)
    for vert in mouth.data.vertices:
        vert.co *= s
    mouth.parent = head
    build_jaw(head, s, mat, tooth_mat)
    head.location = neck + Vector((0.006, -0.022, 0.030)) * h
    head.rotation_euler = (math.radians(HEAD_PITCH_DEG), math.radians(HEAD_ROLL_DEG),
                           math.radians(HEAD_YAW_DEG))
    return head


def _socket_floor(head, guess, radius):
    """Göz çukurunun dibini önden ışınla bul; göz oraya yarı gömülür (dışarı taşmaz)."""
    origin = Vector((guess.x, -0.5, guess.z))
    hit, loc, _n, _i = head.ray_cast(origin, Vector((0.0, 1.0, 0.0)))
    return Vector((guess.x, loc.y + radius * 0.35, guess.z)) if hit else guess


def _teeth(head, s, tooth_mat):
    for i in range(6):
        a = math.radians(-50 + i * 20)
        pos = Vector((0.030 * math.sin(a), -0.080 - 0.022 * math.cos(a), -0.008)) * s
        tooth = kit.primitive("Walker_ToothU", "cone", pos, radius1=0.0055 * s, depth=0.013 * s)
        tooth.rotation_euler = (math.radians(180), 0.0, 0.0)
        tooth.data.materials.append(tooth_mat)
        tooth.parent = head


def build_jaw(head, s, mat, tooth_mat):
    """Tek parça, menteşeden sarkık ve hafif yana kaymış alt çene."""
    jaw = kit.metaball_mesh("Walker_Jaw", _scaled_blobs(JAW_BLOBS, s), mat, resolution=0.003)
    for i in range(5):
        a = math.radians(-44 + i * 22)
        pos = Vector((0.028 * math.sin(a), -0.072 - 0.010 * math.cos(a), -0.034)) * s
        tooth = kit.primitive("Walker_ToothL", "cone", pos, radius1=0.005 * s, depth=0.011 * s)
        tooth.data.materials.append(tooth_mat)
        tooth.parent = jaw
    jaw.parent = head
    jaw.location = JAW_HINGE * s
    jaw.rotation_euler = (math.radians(JAW_OPEN_DEG), math.radians(JAW_SLACK_DEG), 0.0)


# ---------------------------------------------------------------- saç

def _scalp_point(head, direction, s):
    """Kafa merkezinden `direction` yönünde kafa derisindeki nokta ve normal (yerel)."""
    center = SKULL_CENTER * s
    origin = center + direction.normalized() * 0.3 * s
    hit, loc, normal, _ = head.ray_cast(origin, (center - origin).normalized())
    return (loc, normal) if hit else (None, None)


def _allowed(co, style, s):
    """Tutam bu noktaya konabilir mi: yüz, kulak çevresi ve ense altı açık."""
    c = co / s
    if c.z < style["low"] or c.z > style["top_z"]:
        return False
    if c.y < style["hairline"] and c.z < 0.125:          # alın
        return False
    if abs(c.x) > 0.060 and c.z < 0.075 and -0.03 < c.y < 0.035:  # kulak çevresi
        return False
    return True


def _flow_frame(normal, flow=HAIR_FLOW):
    d = flow - normal * flow.dot(normal)
    if d.length < 1e-4:
        d = Vector((0.0, 1.0, 0.0))
    d.normalize()
    return d, normal.cross(d).normalized()


def _lock_path(head, loc, normal, s, style, rng):
    """Tutam omurgası: kafa derisini izler; uzun saçta kafatası bitince aşağı sarkar.
    Döner: [(nokta, normal, akış)]"""
    base_flow = Vector((0.0, 0.3, -1.0)) if style["hang"] else HAIR_FLOW
    flow = Matrix.Rotation(rng.uniform(-1.0, 1.0) * style["spread"], 3, normal) @ base_flow
    length = style["length"] * s * rng.uniform(0.7, 1.3)
    n_seg = 6 if style["hang"] else 4
    seg = length / n_seg
    path, p, n, free = [], loc, normal, False
    for _i in range(n_seg + 1):
        d, _side = _flow_frame(n, flow)
        path.append((p, n, d))
        nxt = p + d * seg
        hit_loc, hit_n = (None, None) if free else _scalp_point(head, nxt - SKULL_CENTER * s, s)
        if hit_loc is not None and (hit_loc - nxt).length < seg * 0.8:
            p, n = hit_loc, hit_n
        else:  # kafatası bitti: yerçekimiyle aşağı, normal dışa sabit
            free = True
            p = nxt
            flow = flow.lerp(Vector((0.0, 0.08, -1.0)), 0.6)
    return path


def _add_lock(bm, path, width, thick, lift):
    """Omurga boyunca mercek kesitli, uca doğru sivrilen tutam (kök kafa derisine gömülü)."""
    rings = []
    last = len(path) - 1
    for i, (p, n, d) in enumerate(path[:-1]):
        f = i / last
        side = n.cross(d).normalized()
        w = width * (1.0 - 0.75 * f ** 1.4)
        t = thick * (1.0 - 0.55 * f)
        c = p + n * (lift * f - (thick * 0.6 if i == 0 else 0.0) + t * 0.4)
        ring = []
        for k in range(LOCK_RING):
            a = 2.0 * math.pi * k / LOCK_RING
            up = math.sin(a) * (t if math.sin(a) > 0 else t * 0.35)
            ring.append(bm.verts.new(c + side * math.cos(a) * w + n * up))
        rings.append(ring)
    p, n, _d = path[-1]
    tip = bm.verts.new(p + n * (lift + thick * 0.2))
    for r0, r1 in zip(rings, rings[1:]):
        for k in range(LOCK_RING):
            bm.faces.new((r0[k], r0[(k + 1) % LOCK_RING], r1[(k + 1) % LOCK_RING], r1[k]))
    for k in range(LOCK_RING):
        bm.faces.new((rings[-1][k], rings[-1][(k + 1) % LOCK_RING], tip))


def _base_region(head, s, style, seed):
    """Kafa derisinden saç tabanı bölgesi (dökülme yamaları gürültüyle, kenar gevşetilmiş)."""
    shift = Vector((seed * 1.3, seed * 0.4, 5.0))
    bm = bmesh.new()
    bm.from_mesh(head.data)

    def keep(f):
        c = f.calc_center_median()
        if not _allowed(c, style, s):
            return False
        density = style["density"] - (style["crown_loss"] if f.normal.z > 0.8 else 0.0)
        n = noise.noise(c / s * style["patch"] + shift) \
            + 0.45 * noise.noise(c / s * style["patch"] * 3.2 - shift)
        return n * 0.5 + 0.5 < density
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if not keep(f)], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.normal_update()
    kit._relax_boundary(bm, 8)
    return bm


def _taper_base(bm, s, thickness, falloff=0.008):
    """Tabanı kenardan uzaklığa göre kalınlaştır (kenarda sıfır: kask kenarı yok)."""
    dist = {v: (0.0 if v.is_boundary else 1e9) for v in bm.verts}
    heap = [(0.0, v.index, v) for v in bm.verts if v.is_boundary]
    heapq.heapify(heap)
    while heap:
        d, _i, v = heapq.heappop(heap)
        if d > dist[v]:
            continue
        for e in v.link_edges:
            o = e.other_vert(v)
            nd = d + e.calc_length()
            if nd < dist[o]:
                dist[o] = nd
                heapq.heappush(heap, (nd, o.index, o))
    for v in bm.verts:
        x = min(1.0, dist[v] / (falloff * s))
        v.co += v.normal * (0.0006 * s + thickness * s * x * x * (3.0 - 2.0 * x))


def build_hair(head, s, style, mat, seed):
    rng = random.Random(int(seed * 1000) + 17)
    bm = _base_region(head, s, style, seed)
    bm.verts.index_update()
    roots = [(f.calc_center_median(), f.normal.copy(), f.calc_area()) for f in bm.faces]
    _taper_base(bm, s, style["base"])
    total = sum(r[2] for r in roots)
    for _ in range(style["locks"] if roots else 0):
        pick, acc = rng.random() * total, 0.0
        for co, n, area in roots:
            acc += area
            if acc >= pick:
                break
        path = _lock_path(head, co, n, s, style, rng)
        k = rng.uniform(0.75, 1.25)
        _add_lock(bm, path, style["width"] * s * k, style["thick"] * s * k,
                  style["base"] * s * rng.uniform(0.8, 2.5))
    mesh = bpy.data.meshes.new("Walker_Hair")
    bm.to_mesh(mesh)
    bm.free()
    hair = bpy.data.objects.new("Walker_Hair", mesh)
    bpy.context.collection.objects.link(hair)
    hair.data.materials.append(mat)
    sub = hair.modifiers.new("Sub", "SUBSURF")
    sub.levels = 1
    kit.apply_all(hair)
    for poly in hair.data.polygons:
        poly.use_smooth = True
    hair.parent = head
    return hair
