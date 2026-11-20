"""Tank zombisinin kıyafetleri (V.5 v2). build_tank.py içe aktarır.

v1'de kıyafet gövdeye boyanmış leke gibiydi. v2'de kumaş gibi okunsun diye:
- kıvrımlar: pantolon paçasında ve diz arkasında yığılma halkaları, karında yatay katlar, kol ağzında
  büzülme (normal boyunca, gürültüyle bükülmüş sinüs);
- kenar: yırtık kenar halkası gevşetilir, sonra dışa kıvrılıp kalınlaşır (kıvrık kumaş kenarı);
- bol kesim: paça baldırdan uzaklaşır, aşağı doğru genişler;
- parçalar: tulum askıları + göğüs cebi + düğmeler, gömlek yakası + cepler + arma, kemer + toka.
Sırt plakalarının çıktığı yerde kumaş yırtık açılır. Ayakkabı: walker_clothes.build_shoe (ölçekli).
"""
import math

import bmesh
import bpy
from mathutils import Vector, noise

import walker_clothes as wc
import zombie_kit as kit

PLATE_TEAR = 0.07         # plaka tabanı çevresinde kumaş açıklığı (m, plaka yarı enine eklenir)
FOLD = 1.0                # kıvrım genliği çarpanı (0 = düz)
HEM_ROLL = 0.006          # kenar kıvrımı dışa itme (m)


def _n(co, scale, seed):
    return noise.noise(co * scale + Vector((seed, seed * 0.7, 0.0)))


def _fold(co, cls, t, kind, seed):
    """Kıvrım yer değiştirmesi (m, normal boyunca)."""
    warp = 0.6 * _n(co, 5.0, seed)
    if cls in ("thigh", "shin"):
        bunch = (t if cls == "shin" else max(0.0, t - 0.75) * 3.0) if kind != "coverall" else 0.6 * t
        return 0.007 * bunch * math.sin(co.z * 85.0 + warp * 3.0)
    if cls in ("torso", "hips"):
        return 0.0035 * math.sin(co.z * 52.0 + warp * 2.5) * (0.5 + 0.5 * _n(co, 3.0, seed + 2))
    if cls == "uparm":
        return 0.004 * math.sin(co.z * 70.0 + warp * 3.0) * t
    return 0.0


def garment(body, name, keep, mat, cls_of, kind, seed, offset=0.012, thickness=0.008,
            holes=0.0, loose=0.0, smooth_edges=20):
    """kit.garment'ın kumaşlı hali: seçilen yüzler kopyalanır, kıvrılır, kenarı kıvrılıp kalınlaşır."""
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bm.transform(body.matrix_world)
    shift = Vector((seed, seed * 1.7, seed * 0.3))

    def torn(co):
        return holes > 0.0 and noise.noise(co * 9.0 + shift * 3.0) > 0.62 - holes * 0.3
    dead = [f for f in bm.faces if not keep(f.calc_center_median()) or torn(f.calc_center_median())]
    bmesh.ops.delete(bm, geom=dead, context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.normal_update()
    kit._relax_boundary(bm, smooth_edges)
    ring = {v for v in bm.verts if v.is_boundary}
    for v in bm.verts:
        cls, t = cls_of(v.co)
        push = offset + FOLD * _fold(v.co, cls, t, kind, seed)
        if cls == "shin":
            push += loose * t
        if v in ring:
            push += HEM_ROLL
        v.co += v.normal * push
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    solid = obj.modifiers.new("Solid", "SOLIDIFY")
    solid.thickness = thickness
    solid.offset = 1.0
    sub = obj.modifiers.new("Sub", "SUBSURF")
    sub.levels = 1
    kit.apply_all(obj)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def _sphere(name, pos, r, mat):
    obj = kit.primitive(name, "sphere", pos, segments=10, rings=6, radius=r)
    obj.scale = (1.0, 0.55, 1.0)
    obj.data.materials.append(mat)
    return obj


def build_clothes(body_obj, part, pts, spots, v, suffix):
    seed = v["seed"]
    w = v["body"]["w"]
    waist = pts["pelvis"][0].z + 0.20
    chest = pts["chest"][0]
    torn_back = [(s["loc"] + s["tail"] * s["size"] * 0.3, s["width"] * 0.5 + PLATE_TEAR) for s in spots]

    def near_plate(co):
        return any((co - loc).length < r + 0.03 * _n(co, 14.0, seed) for loc, r in torn_back)
    top = v["top"]
    made = []
    if top:
        sleeve = {"none": None, "torn": 0.30, "short": 0.62}[v.get("sleeve", "none")]
        strap_x = 0.20 * w

        def keep_top(co):
            if near_plate(co):
                return False
            cls, t = part(co)
            if top == "coverall":           # önlük + askılar; sırtta bel hizasına kadar
                strap = abs(abs(co.x) - strap_x) < 0.050 and co.z > chest.z - 0.1
                if cls in ("torso", "hump", "clav"):
                    if co.y < 0.0:
                        return abs(co.x) < 0.22 * w or strap
                    return co.z < waist + 0.22 or strap
                return cls in ("hips", "thigh") or (cls == "shin" and t < v["hem"] + 0.06 * _n(co, 9.0, seed))
            if cls in ("torso", "hump"):
                return top != "tank" or abs(co.x) < 0.22 * w or co.y > 0.12
            if cls == "hips":
                return co.z > waist - 0.10
            if cls == "clav":
                return t < (0.30 if top == "tank" else 0.62 if sleeve is None else 1.0)
            if cls == "uparm" and sleeve:
                return t < sleeve + 0.08 * _n(co, 9.0, seed)
            return False
        mat = kit.cloth_material("M_Tank_Top" + suffix, v["top_color"], blood=v["blood"])
        made.append(garment(body_obj, "Tank_Top", keep_top, mat, part, top, seed,
                            offset=0.012, holes=v.get("holes", 0.3), loose=0.012))
        extras(body_obj, part, pts, v, suffix, mat, made)
    if v.get("belt"):
        def keep_belt(co):
            return part(co)[0] in ("hips", "torso") and abs(co.z - waist + 0.02) < 0.045
        bmat, _ = kit.material("M_Tank_Belt" + suffix, v["belt"], rough=0.5)
        made.append(garment(body_obj, "Tank_Belt", keep_belt, bmat, part, "belt", seed,
                            offset=0.028, thickness=0.014, smooth_edges=6))
        buckle, _ = kit.material("M_Tank_Buckle" + suffix, (0.35, 0.30, 0.20), rough=0.35)
        hit, loc, _n2, _i = body_obj.ray_cast(Vector((0.0, -1.5, waist - 0.02)), Vector((0.0, 1.0, 0.0)))
        if hit:
            b = kit.primitive("Tank_Buckle", "sphere", loc - Vector((0.0, 0.035, 0.0)), segments=8, rings=4,
                              radius=0.035)
            b.scale = (1.3, 0.35, 0.9)
            b.data.materials.append(buckle)
            made.append(b)
    if v["bottom"]:
        hem = v["hem"]

        def keep_bottom(co):
            cls, t = part(co)
            if cls in ("hips", "torso"):
                return co.z < waist
            if cls == "thigh":
                return True
            if cls == "shin":
                return t < hem + 0.07 * _n(co, 9.0, seed)
            return False
        mat = kit.cloth_material("M_Tank_Bottom" + suffix, v["bottom_color"], stain=(0.05, 0.04, 0.03))
        made.append(garment(body_obj, "Tank_Bottom", keep_bottom, mat, part, "pants", seed + 1.0,
                            offset=0.010, holes=0.22, loose=0.020))
    return made


def extras(body_obj, part, pts, v, suffix, mat, made):
    """Kumaş ayrıntıları: tulumda göğüs cebi + düğmeler, gömlekte yaka + cepler + arma."""
    chest = pts["chest"][0]
    w = v["body"]["w"]
    dark, _ = kit.material("M_Tank_Button" + suffix, (0.03, 0.03, 0.03), rough=0.4)
    if v["top"] == "coverall":
        def keep_pocket(co):
            return co.y < 0.0 and abs(co.x) < 0.09 * w and abs(co.z - chest.z - 0.02) < 0.07
        made.append(garment(body_obj, "Tank_Pocket", keep_pocket, mat, part, "pocket", v["seed"],
                            offset=0.024, thickness=0.006, smooth_edges=4))
        for sx in (1.0, -1.0):
            hit, loc, n, _i = body_obj.ray_cast(Vector((0.20 * w * sx, -1.5, chest.z + 0.10)),
                                                Vector((0.0, 1.0, 0.0)))
            if hit:
                made.append(_sphere("Tank_Button", loc + n * 0.03, 0.022, dark))
    elif v["top"] == "shirt":
        neck = pts["neck0"][0]

        def keep_collar(co):
            cls, _t = part(co)
            return cls in ("neck", "torso", "hump") and (co - neck).length < 0.30 and co.y < 0.15
        made.append(garment(body_obj, "Tank_Collar", keep_collar, mat, part, "collar", v["seed"],
                            offset=0.026, thickness=0.010, smooth_edges=6))
        for sx in (1.0, -1.0):
            def keep_pocket(co, sx=sx):
                return co.y < 0.0 and abs(co.x - 0.15 * w * sx) < 0.065 and abs(co.z - chest.z - 0.04) < 0.06
            made.append(garment(body_obj, "Tank_Pocket", keep_pocket, mat, part, "pocket", v["seed"],
                                offset=0.024, thickness=0.006, smooth_edges=4))
        badge, _ = kit.material("M_Tank_Badge" + suffix, (0.45, 0.33, 0.08), rough=0.4)
        hit, loc, n, _i = body_obj.ray_cast(Vector((0.15 * w, -1.5, chest.z + 0.13)), Vector((0.0, 1.0, 0.0)))
        if hit:
            made.append(_sphere("Tank_Badge", loc + n * 0.03, 0.030, badge))


def build_shoes(body_obj, pts, part, v, suffix, s):
    mat, _ = kit.material("M_Tank_Shoes" + suffix, v["shoes"], rough=0.55)
    sole, _ = kit.material("M_Tank_Sole" + suffix, (0.015, 0.014, 0.013), rough=0.8)
    shoes = [wc.build_shoe(pts, side, mat, sole, s) for side in ("L", "R")]
    bm = bmesh.new()
    bm.from_mesh(body_obj.data)
    dead = [f for f in bm.faces if part(f.calc_center_median())[0] == "foot"]
    bmesh.ops.delete(bm, geom=dead, context="FACES")
    bm.to_mesh(body_obj.data)
    bm.free()
    return shoes
