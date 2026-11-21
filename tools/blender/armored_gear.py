"""Zırhlı zombinin teçhizatı (7.3): yelek, omuzluk, önkol/diz/kaval koruyucu, cepler, bot, eldiven.

build_armored.py içe aktarır. Katı zırh parçaları elipsoid kabuk kesitleridir (oriented_shell): yönlü
eksenle uzva oturur, kalınlaştırılır, kenarı yumuşatılır. Her parçanın malzeme yuvaları
armored_mats.assign ile yazılır (oyunda yuva türü köşe rengini belirler: plastik / metal / kauçuk).
Yelek gövde yüzeyinden kalın kabuk (tank_clothes.garment), kumaş üstü/pantolon da öyle.
Bot: walker_clothes.build_shoe'nun kopyası + konç (paylaşılan dosyaya dokunmamak için).
"""
import math

import bmesh
import bpy
from mathutils import Matrix, Vector

import armored_mats as am
import tank_clothes as tc
import tank_parts as tp
import zombie_kit as kit

UP = Vector((0.0, 0.0, 1.0))


def oriented_shell(name, center, radii, axes, keep, thick, segs=(32, 24), sub=1, relax=3):
    """Elipsoid kabuk kesiti. axes: (x, y, z) dünya eksenleri; keep(u) birim küre noktasında karar verir."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segs[0], v_segments=segs[1], radius=1.0)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if not keep(f.calc_center_median())], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    kit._relax_boundary(bm, relax)
    m = Matrix(axes).transposed()
    for v in bm.verts:
        v.co = Vector(center) + m @ Vector((v.co.x * radii[0], v.co.y * radii[1], v.co.z * radii[2]))
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(bpy.data.materials.get("M_Tmp") or bpy.data.materials.new("M_Tmp"))
    solid = obj.modifiers.new("Solid", "SOLIDIFY")
    solid.thickness = thick
    solid.offset = 1.0
    if sub:
        obj.modifiers.new("Sub", "SUBSURF").levels = sub
    kit.apply_all(obj)
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def limb_axes(a, b, out_hint):
    """Uzuv boyunca z, dışa x (ipucuna göre), y = z × x."""
    z = (b - a).normalized()
    x = (out_hint - z * out_hint.dot(z)).normalized()
    return x, z.cross(x).normalized(), z


# ---------------------------------------------------------------- katı zırh

def shoulder_pads(pts, v, suffix, sides=("L", "R")):
    out = []
    for side in sides:
        sx = 1.0 if side == "L" else -1.0
        sh, el = pts["shoulder_" + side][0], pts["elbow_" + side][0]
        x, y, z = limb_axes(sh, el, Vector((sx, 0.0, 0.0)))
        cap = oriented_shell("Armored_Pad", sh + x * 0.012 + UP * 0.012, (0.086, 0.098, 0.074), (x, y, -z),
                             lambda u: u.x > -0.25 and u.z > -0.45, 0.013)
        band = oriented_shell("Armored_Pad", sh + z * 0.095 + x * 0.018, (0.078, 0.090, 0.080), (x, y, z),
                              lambda u: u.x > 0.0 and -0.55 < u.z < 0.55, 0.011)
        for obj in (cap, band):
            out.append(am.assign(obj, [("plastic", v["armor"])], "M_Armored_Pad" + suffix))
    return out


def forearm_guard(pts, v, suffix, side="R"):
    sx = 1.0 if side == "L" else -1.0
    el, wr = pts["elbow_" + side][0], pts["wrist_" + side][0]
    x, y, z = limb_axes(el, wr, Vector((sx * 0.6, -0.8, 0.0)))
    c = el.lerp(wr, 0.55)
    obj = oriented_shell("Armored_Guard", c, (0.050, 0.050, 0.135), (x, y, z), lambda u: u.x > -0.25, 0.010)
    return am.assign(obj, [("plastic", v["armor"])], "M_Armored_Guard" + suffix)


def leg_guards(pts, v, suffix):
    out = []
    for side in ("L", "R"):
        kn, an = pts["knee_" + side][0], pts["ankle_" + side][0]
        x, y, z = limb_axes(kn, an, Vector((0.0, -1.0, 0.0)))
        knee = oriented_shell("Armored_Knee", kn + x * 0.030, (0.068, 0.072, 0.080), (x, y, z),
                              lambda u: u.x > -0.1, 0.012)
        out.append(am.assign(knee, [("plastic", v["armor"])], "M_Armored_Knee" + suffix))
        if "shin" in v["pads"]:
            shin = oriented_shell("Armored_Shin", kn.lerp(an, 0.52) + x * 0.022, (0.055, 0.062, 0.165),
                                  (x, y, z), lambda u: u.x > -0.2, 0.009)
            out.append(am.assign(shin, [("plastic", v["armor"])], "M_Armored_Shin" + suffix))
    return out


def pouches(body, pts, v, suffix):
    """Yelek önünde cepler (kutu, yumuşatılmış)."""
    out = []
    z = pts["pelvis"][0].z + 0.14
    for ang in v.get("pouches", ()):          # bel çevresinde, önden açı (derece; kalkanın arkasında kalmasın)
        d = Vector((math.sin(math.radians(ang)), -math.cos(math.radians(ang)), 0.0))
        hit, loc, nrm, _i = body.ray_cast(Vector((0.0, 0.0, z)) + d * 1.0, -d)
        if not hit:
            continue
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        mesh = bpy.data.meshes.new("Armored_Pouch")
        bm.to_mesh(mesh)
        bm.free()
        obj = bpy.data.objects.new("Armored_Pouch", mesh)
        bpy.context.collection.objects.link(obj)
        obj.data.materials.append(bpy.data.materials.new("M_Tmp"))
        obj.modifiers.new("Sub", "SUBSURF").levels = 2
        kit.apply_all(obj)
        obj.data.transform(Matrix.Diagonal((0.085, 0.055, 0.10, 1.0)))
        obj.rotation_euler.z = math.radians(ang)
        obj.location = loc + d * 0.050
        out.append(am.assign(obj, [("cloth", v["vest"])], "M_Armored_Pouch" + suffix))
    return out


# ---------------------------------------------------------------- kumaş

def build_vest(body, part, pts, v, suffix):
    """Kalın yelek (ayrı ağ): gövde ve kamburu sarar, omuz başında biter; altı belde."""
    waist = pts["pelvis"][0].z + 0.10

    def keep(co):
        cls, t = part(co)
        if cls in ("torso", "hump"):
            return True
        if cls == "clav":
            return t < 0.55
        return cls == "hips" and co.z > waist
    obj = tc.garment(body, "Armored_Vest", keep, am.make("cloth", v["vest"], "M_Armored_Vest" + suffix),
                     part, "vest", v["seed"], offset=0.020, thickness=0.016, holes=0.0, smooth_edges=12)
    out = [am.assign(obj, [("cloth", v["vest"])], "M_Armored_Vest" + suffix)]
    plate = v.get("plate")
    if plate:
        chest = pts["chest"][0]

        def keep_plate(co):
            return co.y < 0.0 and abs(co.x) < 0.115 and abs(co.z - chest.z + 0.02) < 0.13
        p = tc.garment(body, "Armored_Plate", keep_plate, am.make(plate[0], plate[1], "M_Tmp"), part, "plate",
                       v["seed"], offset=0.040, thickness=0.012, smooth_edges=4)
        out.append(am.assign(p, [plate], "M_Armored_Plate" + suffix))
    return out


def build_clothes(body, part3, pts, v, suffix):
    """Alt giysi (üst) + pantolon; gövdeye kumaş kabuğu. part3(co) -> (sınıf, t, yan)."""
    waist = pts["pelvis"][0].z + 0.16
    seed = v["seed"]
    sleeves = v["sleeves"]          # {"L": oran, "R": oran}: kolun ne kadarı kapalı (1.4 = bileğe dek)

    def part(co):
        return part3(co)[:2]

    def keep_top(co):
        cls, t, side = part3(co)
        if cls in ("torso", "hump", "clav", "neck"):
            return cls != "neck" or t < 0.4
        if cls == "hips":
            return co.z > waist - 0.10
        cover = sleeves.get(side, 0.0)
        if cls == "uparm":
            return t < cover + 0.06 * tc._n(co, 9.0, seed)
        if cls == "forearm":
            return t < cover - 1.0 + 0.08 * tc._n(co, 9.0, seed)
        return False
    top = tc.garment(body, "Armored_Top", keep_top, am.make("cloth", v["suit"], "M_Armored_Top" + suffix),
                     part, "shirt", seed, offset=0.010, holes=v.get("holes", 0.15), loose=0.0)

    def keep_bottom(co):
        cls, t = part(co)
        if cls in ("hips", "torso"):
            return co.z < waist
        return cls == "thigh" or (cls == "shin" and t < 0.85)
    bottom = tc.garment(body, "Armored_Bottom", keep_bottom, am.make("cloth", v["pants"], "M_Armored_Bot" + suffix),
                        part, "pants", seed + 1.0, offset=0.010, holes=0.12, loose=0.010)
    return [am.assign(top, [("cloth", v["suit"])], "M_Armored_Top" + suffix),
            am.assign(bottom, [("cloth", v["pants"])], "M_Armored_Bot" + suffix)]


# ---------------------------------------------------------------- bot ve eldiven

BOOT_BLOBS = [(0.15, 0.045, (0.056, 0.045, 0.046)), (0.44, 0.048, (0.085, 0.047, 0.040)),
              (0.70, 0.036, (0.062, 0.052, 0.034)), (0.88, 0.030, (0.046, 0.048, 0.028))]
SOLE = 0.020


def build_boot(pts, side, slots, name):
    heel, toe, ankle = (pts[f"{k}_{side}"] for k in ("heel", "toe", "ankle"))
    knee = pts["knee_" + side][0]
    heel_b, toe_b = heel[0] - UP * heel[1], toe[0] - UP * toe[1]
    fwd = (toe_b - heel_b).normalized()
    side_v = fwd.cross(UP).normalized()
    up = side_v.cross(fwd).normalized()
    length = (toe_b - heel_b).length + (heel[1] + toe[1]) * 0.7
    origin = heel_b - fwd * heel[1] * 0.9
    rot = Matrix((fwd, side_v, up)).transposed().to_quaternion()
    blobs = [(tuple(origin + fwd * u * length + up * z), r, rot, False) for u, z, r in BOOT_BLOBS]
    for f, r in ((0.10, 0.058), (0.24, 0.056)):      # konç: baldırın alt çeyreği
        blobs.append((tuple(ankle[0].lerp(knee, f)), (r, r, 0.06), rot, False))
    boot = kit.metaball_oriented(name, blobs, bpy.data.materials.new("M_Tmp"), resolution=0.0045, smooth=3)
    for vert in boot.data.vertices:
        h = (vert.co - origin).dot(up)
        if h < 0.0:
            vert.co -= up * h
    for poly in boot.data.polygons:
        poly.material_index = 1 if (poly.center - origin).dot(up) < SOLE else 0
    return am.assign(boot, slots, name.replace("Armored_", "M_Armored_"))


def build_boots_gloves(body, pts, part, v, suffix, skin):
    out = []
    for side, sx in (("L", 1.0), ("R", -1.0)):
        out.append(build_boot(pts, side, [("rubber", v["boots"]), ("rubber", (0.012, 0.011, 0.010))],
                              "Armored_Boot_" + side))
        fist = tp.build_fist("Armored_Fist_" + side, pts["wrist_" + side][0], pts["fist_" + side][0], sx,
                             v["body"].get("hand", 0.78), skin)
        out.append(am.assign(fist, [("rubber", v["gloves"])], "M_Armored_Glove" + suffix))
    bm = bmesh.new()             # botun içinde kalan ayak ağı silinir
    bm.from_mesh(body.data)
    dead = [f for f in bm.faces if part(f.calc_center_median())[0] == "foot"]
    bmesh.ops.delete(bm, geom=dead, context="FACES")
    bm.to_mesh(body.data)
    bm.free()
    return out


def deg(x):
    return math.radians(x)
