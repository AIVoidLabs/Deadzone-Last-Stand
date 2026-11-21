"""Patlayıcının kıyafetleri (7.3): şişkinliğin üstünde gerilmiş, göbekte boylamasına yarılmış kumaş.

build_bloater.py içe aktarır. Kumaş yöntemi tank_clothes.garment (kıvrım, gevşetilmiş ve kıvrılmış
yırtık kenar, kalınlık); burada yalnız kesim verisi var:
- yarık: göbeğin önünde mercek biçimli, kenarı gürültülü açıklık (kumaş gerilip patlamış, ten görünür);
- kabarcık delikleri: kabarcık kümelerinin çevresinde kumaş açılır (kabarcık kumaşı delmiş);
- chef: aşçı ceketi (yarık + kopmuş düğmeler) + önlük + koyu pantolon;
- trucker: yukarı sıyrılmış atlet (alt göbek açıkta) + kot + kemer + kasket;
- bare: yırtık şort.
"""
import math

import bpy
from mathutils import Vector, noise

import tank_clothes as tc
import zombie_kit as kit

SPLIT_WIDTH = 0.16        # yarığın en geniş yeri (m, yarım genişlik)
SPLIT_HALF_H = 0.30       # yarığın yarım boyu (m)
BLISTER_TEAR = 0.035      # kabarcık çevresinde kumaş açıklığı (m, yarıçapa eklenir)


def _n(co, scale, seed):
    return noise.noise(co * scale + Vector((seed, seed * 0.7, 0.0)))


def split(co, gut, seed, x0=0.0, width=SPLIT_WIDTH, half_h=SPLIT_HALF_H):
    """Göbeğin önündeki mercek yarık mı? (kenar gürültülü, yırtık)"""
    if co.y > gut.y - 0.10:
        return False
    u = (co.z - gut.z - 0.02) / half_h
    if abs(u) >= 1.0:
        return False
    w = width * math.sqrt(1.0 - u * u) * (1.0 + 0.45 * _n(co, 14.0, seed))
    return abs(co.x - x0 - 0.03 * _n(co, 4.0, seed + 3)) < w


def build_clothes(body, part, pts, blisters, v, suffix):
    seed, w = v["seed"], v["body"]["w"]
    gut = pts["belly"][0]
    waist = pts["pelvis"][0].z + 0.10
    holes = [(loc, r + BLISTER_TEAR) for loc, _n2, r, _c in blisters]

    def holed(co):
        return any((co - loc).length < r + 0.02 * _n(co, 16.0, seed) for loc, r in holes)
    made = []
    top = v["top"]
    if top:
        def keep_top(co):
            if holed(co):
                return False
            cls, t = part(co)
            if top == "jacket":
                if split(co, gut, seed):
                    return False
                if cls in ("torso", "hump", "clav", "neck"):
                    return cls != "neck" or co.y > 0.0
                if cls == "uparm":
                    return t < 0.75 + 0.08 * _n(co, 9.0, seed)
                if cls == "hips":
                    return co.z > waist - 0.02
                return False
            # atlet: askılı, alt kenarı göbeğin üstüne sıyrılmış
            if cls in ("torso", "hump", "clav", "neck"):
                lo = gut.z - 0.10 + 0.05 * _n(co, 6.0, seed)
                if co.z < lo or co.z > pts["neck0"][0].z - 0.05:
                    return False
                if co.y > 0.0:
                    return True
                return co.z < pts["chest"][0].z + 0.02 or abs(abs(co.x) - 0.17 * w) < 0.05
            return False
        mat = kit.cloth_material("M_Bloater_Top" + suffix, v["top_color"], blood=v["blood"])
        made.append(tc.garment(body, "Bloater_Top", keep_top, mat, part, top, seed,
                               offset=0.009, thickness=0.006, holes=v.get("holes", 0.25), loose=0.0))
    if v.get("apron"):
        def keep_apron(co):
            cls, t = part(co)
            if holed(co) or co.y > -0.05 or abs(co.x) > 0.30 * w:
                return False
            if cls in ("torso", "hips"):
                return co.z < gut.z - 0.06 + 0.03 * _n(co, 8.0, seed)
            return cls == "thigh" and t < 0.62 + 0.06 * _n(co, 9.0, seed)
        amat = kit.cloth_material("M_Bloater_Apron" + suffix, v["apron"], stain=(0.16, 0.10, 0.05), blood=0.7)
        made.append(tc.garment(body, "Bloater_Apron", keep_apron, amat, part, "apron", seed + 2.0,
                               offset=0.024, thickness=0.006, holes=0.15, loose=0.0, smooth_edges=10))
    if v.get("belt"):
        def keep_belt(co):
            return part(co)[0] in ("hips", "torso") and abs(co.z - waist + 0.03) < 0.035 and not holed(co)
        bmat, _ = kit.material("M_Bloater_Belt" + suffix, v["belt"], rough=0.5)
        made.append(tc.garment(body, "Bloater_Belt", keep_belt, bmat, part, "belt", seed,
                               offset=0.022, thickness=0.012, smooth_edges=6))
    if v["bottom"]:
        hem = v["hem"]

        def keep_bottom(co):
            cls, t = part(co)
            if cls in ("hips", "torso"):
                return co.z < waist
            if cls == "thigh":
                return t < hem + 0.08 * _n(co, 9.0, seed) if hem < 1.0 else True
            if cls == "shin":
                return hem > 1.0 and t < hem - 1.0 + 0.07 * _n(co, 9.0, seed)
            return False
        mat = kit.cloth_material("M_Bloater_Bottom" + suffix, v["bottom_color"], stain=(0.05, 0.04, 0.03))
        made.append(tc.garment(body, "Bloater_Bottom", keep_bottom, mat, part, "coverall", seed + 1.0,
                               offset=0.010, holes=0.22, loose=0.012))
    return made


def _buttons(body, gut, v, suffix):
    """Ceketin yarığının iki yanında düğmeler (bir kısmı kopmuş)."""
    mat, _ = kit.material("M_Bloater_Button" + suffix, (0.55, 0.52, 0.45), rough=0.4)
    out = []
    for i, z in enumerate((0.30, 0.16, -0.24)):
        for sx in (1.0, -1.0):
            if (i + (sx > 0)) % 3 == 2:
                continue
            x = sx * (SPLIT_WIDTH * 1.25 if abs(z) < 0.25 else 0.08)
            hit, loc, n, _i = body.ray_cast(Vector((x, -1.5, gut.z + z)), Vector((0.0, 1.0, 0.0)))
            if hit:
                b = kit.primitive("Bloater_Button", "sphere", loc + n * 0.016, segments=8, rings=4, radius=0.016)
                b.scale = (1.0, 0.45, 1.0)
                b.data.materials.append(mat)
                out.append(b)
    return out


def build_cap(head, s, color, suffix):
    """Kasket: kafatasına oturan kubbe + öne siper (kafa yerelinde, kafaya bağlı)."""
    mat = kit.cloth_material("M_Bloater_Cap" + suffix, color, stain=(0.06, 0.05, 0.04))
    dome = [((0.0, 0.010, 0.080), (0.080, 0.086, 0.052), False),
            ((0.0, 0.010, 0.050), (0.080, 0.086, 0.030), True)]
    cap = kit.metaball_mesh("Bloater_Cap", [(tuple(Vector(c) * s), tuple(r * s for r in rr), ng)
                                            for c, rr, ng in dome], mat, resolution=0.004)
    brim = kit.primitive("Bloater_Brim", "sphere", Vector((0.0, -0.085, 0.084)) * s, segments=16, rings=6,
                         radius=0.060 * s)
    brim.scale = (1.0, 0.75, 0.10)
    brim.rotation_euler = (math.radians(-12.0), 0.0, 0.0)
    brim.data.materials.append(mat)
    for o in (cap, brim):
        o.parent = head
        for p in o.data.polygons:
            p.use_smooth = True
    return [cap, brim]


def build_shoes(body, pts, part, v, suffix, s):
    shoes = tc.build_shoes(body, pts, part, v, suffix, s)
    for o in list(bpy.data.objects):
        if o.name.startswith("Tank_Shoe") or o.name.startswith("Walker_Shoe"):
            o.name = o.name.replace("Tank_", "Bloater_").replace("Walker_", "Bloater_")
    return shoes
