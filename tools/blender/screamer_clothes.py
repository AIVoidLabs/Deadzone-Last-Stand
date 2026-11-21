"""Çığlıkçının kıyafetleri (7.3): hastane paçavraları. build_screamer.py içe aktarır.

Kumaş yöntemi tank_clothes.garment (içe aktarılır, düzenlenmez): seçilen gövde yüzleri kopyalanır,
kıvrılır, yırtık kenar halkası gevşetilip dışa kıvrılır. Etek kısmı gövdeden değil ayrı bir tüp
(skirt): iki bacağın arasını köprüler, kıvrımlı ve yırtık eteğe sahiptir (bacak bacak şort gibi okunmasın).
- gown : soluk camgöbeği hastane önlüğü; arkası açık (omurga görünür), V yaka (göğüs kemiği ve üst
         kaburgalar görünür), sol yanda yırtık (kaburgalar), diz üstü yırtık etek; bilekte hasta bilekliği.
- nurse: soluk mavi-beyaz hemşire elbisesi, önü göğüsten karna yırtılmış (kaburgalar), diz hizası etek,
         beyaz iş ayakkabısı, uzun saç.
- bare : çıplak gövde (tam kaburga), eski yırtık pantolon (baldır ortası), yalın ayak.
"""
import math

import bmesh
import bpy
from mathutils import Vector, noise

import tank_clothes as tc
import walker_clothes as wc
import zombie_kit as kit

SKIRT = {"gown": {"top": 1.11, "hem": 0.74, "back_open": True},
         "nurse": {"top": 1.11, "hem": 0.57, "back_open": False}}
SKIRT_RADII = ((0.150, 0.118), (0.205, 0.160))   # (rx, ry) üstte ve etekte (m)
SKIRT_FOLDS = 9
BAND_COLOR = (0.70, 0.70, 0.66)                   # hasta bilekliği


def _gap_front(co, pts, lo, hi, half):
    """Önde dikey yırtık/açıklık: göğüs noktasına göre z aralığında, |x| < half."""
    c = pts["chest"][0]
    return co.y < c.y - 0.02 and lo < co.z - c.z < hi and abs(co.x) < half


def build_clothes(body_obj, part, pts, v, suffix):
    seed = v["seed"]
    made = []
    top = v["top"]
    if top:
        neck_z = pts["upchest"][0].z
        c = pts["chest"][0]

        def keep_top(co):
            cls, t = part(co)
            if cls == "neck":
                return False
            if cls == "torso":
                if co.z > neck_z - 0.02:
                    return False
                if top == "gown":
                    if co.y > c.y + 0.03 and abs(co.x) < 0.045 + 0.02 * tc._n(co, 7.0, seed):
                        return False                   # açık sırt
                    if _gap_front(co, pts, -0.06 + 0.5 * (abs(co.x)), 0.20, 0.07):
                        return False                   # V yaka
                    if co.x > 0.08 and -0.13 < co.z - c.z < 0.02 and co.y > c.y - 0.06:
                        return False                   # sol yan yırtığı
                else:
                    if _gap_front(co, pts, -0.22, 0.03 + 0.02 * tc._n(co, 8.0, seed),
                                  0.045 + 0.03 * tc._n(co, 6.0, seed + 1)):
                        return False                   # önü yırtık
                return True
            if cls == "hips":
                return True
            if cls == "clav":
                return True
            if cls == "uparm":
                return t < (0.30 if top == "gown" else 0.42) + 0.08 * tc._n(co, 9.0, seed)
            return False
        mat = kit.cloth_material("M_Screamer_Top" + suffix, v["top_color"], stain=(0.14, 0.12, 0.08),
                                 blood=v["blood"])
        made.append(tc.garment(body_obj, "Screamer_Top", keep_top, mat, part, "shirt", seed,
                               offset=0.009, thickness=0.004, holes=v.get("holes", 0.2), loose=0.0))
        made.append(skirt("Screamer_Skirt", pts, SKIRT[top], mat, seed, v.get("holes", 0.2)))
    if v.get("bottom"):
        hem = v["hem"]
        waist = pts["pelvis"][0].z + 0.13

        def keep_bottom(co):
            cls, t = part(co)
            if cls in ("hips", "torso"):
                return co.z < waist
            if cls == "thigh":
                return True
            if cls == "shin":
                return t < hem + 0.08 * tc._n(co, 9.0, seed)
            return False
        mat = kit.cloth_material("M_Screamer_Bottom" + suffix, v["bottom_color"], stain=(0.06, 0.05, 0.03))
        made.append(tc.garment(body_obj, "Screamer_Bottom", keep_bottom, mat, part, "pants", seed + 1.0,
                               offset=0.009, holes=0.22, loose=0.012))
        rope, _ = kit.material("M_Screamer_Belt" + suffix, (0.16, 0.12, 0.07), rough=0.9)

        def keep_belt(co):
            return part(co)[0] in ("hips", "torso") and abs(co.z - waist + 0.015) < 0.013
        made.append(tc.garment(body_obj, "Screamer_Belt", keep_belt, rope, part, "belt", seed,
                               offset=0.020, thickness=0.008, smooth_edges=6))
    if v.get("band"):
        made.append(wrist_band(pts, suffix))
    return made


def skirt(name, pts, spec, mat, seed, holes):
    """Etek tüpü: üstte gövdeyi saran, aşağı genişleyen elips halkalar; kıvrımlar, yırtık etek, isteğe
    bağlı açık arka. Merkez pelvis çizgisinde (y)."""
    bm = bmesh.new()
    rings, seg = 9, 40
    top, hem = spec["top"], spec["hem"]
    y0 = pts["pelvis"][0].y
    grid = []
    for i in range(rings):
        u = i / (rings - 1)
        z = top + (hem - top) * u
        rx = SKIRT_RADII[0][0] + (SKIRT_RADII[1][0] - SKIRT_RADII[0][0]) * u ** 0.8
        ry = SKIRT_RADII[0][1] + (SKIRT_RADII[1][1] - SKIRT_RADII[0][1]) * u ** 0.8
        row = []
        for j in range(seg):
            a = math.tau * j / seg
            fold = 1.0 + (0.012 + 0.05 * u) * math.sin(a * SKIRT_FOLDS + 1.7 * tc._n(Vector((a, u, 0)), 2.0, seed))
            p = Vector((math.sin(a) * rx * fold, y0 - math.cos(a) * ry * fold, z))
            if i == rings - 1:
                p.z += 0.05 * tc._n(p, 6.0, seed) + 0.02 * math.sin(a * 3.0 + seed)   # yırtık etek
            row.append(bm.verts.new(p))
        grid.append(row)
    for i in range(rings - 1):
        for j in range(seg):
            a = math.tau * (j + 0.5) / seg
            if spec["back_open"] and abs(math.cos(a) + 1.0) < 0.03:
                continue                                       # arka yarık
            quad = [grid[i][j], grid[i][(j + 1) % seg], grid[i + 1][(j + 1) % seg], grid[i + 1][j]]
            centre = sum((q.co for q in quad), Vector()) / 4
            if holes and i > 1 and noise.noise(centre * 9.0 + Vector((seed, seed, 0))) > 0.66 - holes * 0.3:
                continue
            bm.faces.new(quad)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    sol = obj.modifiers.new("Solid", "SOLIDIFY")
    sol.thickness = 0.004
    sub = obj.modifiers.new("Sub", "SUBSURF")
    sub.levels = 1
    kit.apply_all(obj)
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def wrist_band(pts, suffix):
    """Sol bilekte hasta bilekliği (beyaz plastik halka)."""
    wr, el = pts["wrist_L"][0], pts["elbow_L"][0]
    d = (wr - el).normalized()
    band = kit.primitive("Screamer_Band", "sphere", wr - d * 0.03, segments=12, rings=6, radius=0.030)
    band.scale = (1.0, 1.0, 0.32)
    band.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    mat, _ = kit.material("M_Screamer_Band" + suffix, BAND_COLOR, rough=0.4)
    band.data.materials.append(mat)
    return band


def build_shoes(body_obj, pts, part, v, suffix):
    """Beyaz iş ayakkabısı: walker_clothes.build_shoe (ince ayağa göre ölçek) + gövdede ayak silinir."""
    mat, _ = kit.material("M_Screamer_Shoes" + suffix, v["shoes"], rough=0.5)
    sole, _ = kit.material("M_Screamer_Sole" + suffix, (0.20, 0.19, 0.17), rough=0.8)
    shoes = [wc.build_shoe(pts, side, mat, sole, 0.95) for side in ("L", "R")]
    bm = bmesh.new()
    bm.from_mesh(body_obj.data)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if part(f.calc_center_median())[0] == "foot"],
                     context="FACES")
    bm.to_mesh(body_obj.data)
    bm.free()
    return shoes
