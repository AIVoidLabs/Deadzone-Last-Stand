"""Tank zombisinin sırt kemik plakaları (V.5 v2; DECISIONS K5: "sırtında kemik plakalar").

v1'de plakalar ince ve düzdü (cips gibi). v2: yassı ama KALIN kemik levhalar. Kesit süper-elips
(kalın, yuvarlatılmış pahlı kenar), enine kiremit gibi kavisli, boyuna ucu hafif kalkık; üst yüzde
büyüme halkaları. Omurga boyunca kuyruğa doğru üst üste biner (pullu zırh); kamburdaki büyükler
dikleşip kafanın arkasında taç yapar, yukarıdan okunur. Tabanı gövdeye gömülür; çevresindeki ten
şişer ve "çiğ" renk alır (et-kemik geçişi). Malzeme mat, lekeli yaşlı kemik (plastik değil).
"""
import math

import bmesh
import bpy
from mathutils import Matrix, Vector, noise

import zombie_kit as kit

UP = Vector((0.0, 0.0, 1.0))
# (A, B, oran, ışın açısı: 0 arkadan 90 tepeden, yan açı, boy, en, kalınlık, kalkış (derece))
PLATES = [
    ("spine", "chest", 0.05, 30, 0, 0.19, 0.14, 0.050, 2),
    ("spine", "chest", 0.45, 38, 0, 0.23, 0.17, 0.056, 4),
    ("spine", "chest", 0.85, 48, 0, 0.27, 0.20, 0.062, 7),
    ("chest", "hump", 0.45, 60, 0, 0.31, 0.23, 0.068, 12),
    ("chest", "hump", 0.95, 74, 0, 0.36, 0.26, 0.074, 34),
    ("hump", "neck0", 0.20, 90, 0, 0.38, 0.27, 0.076, 56),
    ("hump", "neck0", 0.42, 104, 0, 0.28, 0.20, 0.064, 62),
    ("spine", "chest", 0.70, 44, 40, 0.22, 0.16, 0.054, 4),
    ("chest", "hump", 0.55, 64, 46, 0.26, 0.19, 0.060, 10),
    ("hump", "neck0", 0.12, 86, 52, 0.29, 0.20, 0.062, 44),
]
SIDE_X = 0.15             # yan sıranın omurgadan uzaklığı (m)
SIDE_SPLAY = 12.0         # yan plakaların serbest ucu dışa döner (derece)
SINK = 0.035              # taban gövdeye gömülür (m)
EXPONENT = 2.8            # kesit süper-elipsi (2 = elips, büyük = köşeli)
BEND = 0.55               # enine kavis (kenarlar gövdeye doğru iner, en oranı)
LENGTH = 0.85             # boy çarpanı
CONFORM = 0.5             # giydirme payı: 1 = sırta tam yapışır (kapak gibi), 0 = düz levha (kanat gibi)
CURL = 0.0               # boyuna kavis (giydirmede gövde verir)
RINGS = 3                 # büyüme halkası sayısı
SWELL = 0.022             # taban çevresinde ten şişkinliği (m)
SWELL_REACH = 0.045       # şişkinliğin plaka kenarından erimi (m)
BONE = (0.30, 0.25, 0.16)        # yaşlı kemik (doğrusal)
BONE_EDGE = (0.46, 0.40, 0.28)    # aşınmış kenar
BONE_STAIN = (0.12, 0.08, 0.045)   # kahve lekeler
BONE_ROOT = (0.11, 0.035, 0.025)  # tabanda kurumuş kan
RAW = (0.13, 0.045, 0.04)          # plaka çevresinde çiğ et


def plate_spots(body_obj, pts, lean):
    """Plakaların yüzeydeki tabanı: dict(loc, n, tail, side, size, width, thick, lift, sx)."""
    spots = []
    rot = Matrix.Rotation(lean, 3, "X")
    back, up = rot @ Vector((0.0, 1.0, 0.0)), rot @ UP
    for a, b, f, ang, side_ang, size, width, thick, lift in PLATES:
        pa, pb = pts[a][0], pts[b][0]
        anchor = pa.lerp(pb, f)
        tangent = (pb - pa).normalized()
        for sx in ((1.0, -1.0) if side_ang else (0.0,)):
            ang_r = math.radians(ang)
            d = back * math.cos(ang_r) + up * math.sin(ang_r)
            if sx:
                d = (Matrix.Rotation(math.radians(side_ang) * sx, 3, tangent) @ d).normalized()
            origin = anchor + Vector((SIDE_X * sx, 0.0, 0.0)) + d * 1.5
            hit, loc, normal, _i = body_obj.ray_cast(origin, -d)
            if not hit:
                continue
            n = (normal * 0.6 + d * 0.4).normalized()
            tail = back * 0.35 - up            # serbest uç hep aşağı-geri (kuyruğa), yüzeye izdüşümü
            tail = (tail - n * tail.dot(n)).normalized()
            if sx:
                tail = Matrix.Rotation(math.radians(SIDE_SPLAY) * -sx, 3, n) @ tail
            spots.append({"loc": loc, "n": n, "tail": tail, "size": size, "width": width,
                          "thick": thick, "lift": lift, "sx": sx})
    return spots


def _section(u, size, width, thick):
    """Boyuna u (0 taban, 1 serbest uç) için yarı en ve yarı kalınlık: küt uçlu mercek."""
    k = math.sin(math.pi * min(max(u, 0.0), 1.0)) ** 0.5
    half_w = width * 0.5 * k * (1.12 - 0.5 * u)            # kalkan: tabana yakın geniş, uca daralır
    half_t = thick * 0.5 * (0.35 + 0.65 * k) * (1.0 - 0.35 * u)
    return half_w, half_t


def plate_mesh(spot, k, rng, n_u=12, n_ring=16):
    """Plaka ağı plaka yerelinde: x boyuna (kuyruğa), y enine, z dışa. Döner bmesh."""
    size, width, thick = spot["size"] * k * LENGTH * rng.uniform(0.92, 1.08), spot["width"] * k, spot["thick"] * k
    bm = bmesh.new()
    rings = []
    p = 2.0 / EXPONENT
    for i in range(1, n_u):
        u = i / n_u
        hw, ht = _section(u, size, width, thick)
        ring = []
        for j in range(n_ring):
            a = math.tau * j / n_ring
            ca, sa = math.cos(a), math.sin(a)
            y = hw * math.copysign(abs(ca) ** p, ca)
            z = ht * math.copysign(abs(sa) ** p, sa)
            z -= BEND * width * (y / max(width * 0.5, 1e-6)) ** 2 * 0.25   # kiremit kavisi
            z += CURL * size * u * u
            ring.append(bm.verts.new((u * size, y, z)))
        rings.append(ring)
    v0 = bm.verts.new((0.0, 0.0, CURL * 0.0))
    v1 = bm.verts.new((size, 0.0, CURL * size))
    for r0, r1 in zip(rings, rings[1:]):
        for j in range(n_ring):
            bm.faces.new((r0[j], r0[(j + 1) % n_ring], r1[(j + 1) % n_ring], r1[j]))
    for j in range(n_ring):
        bm.faces.new((rings[0][(j + 1) % n_ring], rings[0][j], v0))
        bm.faces.new((rings[-1][j], rings[-1][(j + 1) % n_ring], v1))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm, size, width


def build_plate(spot, mat, rng, k=1.0, name="Tank_Plate", body=None):
    """Plakayı kurar ve yerine koyar: taban gömülü, serbest uç kalkık. Nesne kökeni tabanda.
    body verilirse plaka sırta giydirilir (conform): kavisli kamburda kanat gibi açılmaz."""
    bm, size, width = plate_mesh(spot, k, rng)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    sub = obj.modifiers.new("Sub", "SUBSURF")
    sub.levels = 2
    kit.apply_all(obj)
    seed = Vector((rng.random() * 50.0, rng.random() * 50.0, 0.0))
    for v in obj.data.vertices:
        c = v.co
        if v.normal.z > 0.3:          # üst yüzde büyüme halkaları (tabandan uzaklıkla)
            r = math.hypot(c.x / size, c.y / max(width, 1e-6))
            c.z -= 0.0035 * k * max(0.0, math.sin(r * RINGS * math.tau)) ** 3
        c += v.normal * 0.0035 * k * noise.noise(c * 22.0 + seed)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    n, tail = spot["n"], spot["tail"]
    side = n.cross(tail).normalized()
    if body is not None:
        basis = Matrix((tail, n.cross(tail).normalized(), n)).transposed()
        obj.matrix_world = Matrix.Translation(spot["loc"]) @ basis.to_4x4()
        conform(obj, body, size, spot["lift"], spot["thick"] * k)
        return obj
    lift = Matrix.Rotation(-math.radians(spot["lift"]), 3, side)   # serbest uç dışa kalkar
    x_axis, z_axis = lift @ tail, lift @ n
    basis = Matrix((x_axis, z_axis.cross(x_axis).normalized(), z_axis)).transposed()
    obj.matrix_world = Matrix.Translation(spot["loc"] - n * SINK * k) @ basis.to_4x4()
    return obj


def conform(obj, body, size, lift_deg, thick, samples=9):
    """Plakayı ekseni boyunca sırta büker: eksende 9 noktada yüzey derinliği ölçülür (ışın), köşeler
    yereli z'de bu yumuşak eğri kadar kaydırılır; uçta kalkış eklenir. Köşe başına normal kullanılmaz
    (pürüzlü gövde normali plakayı parçalar)."""
    mw = obj.matrix_world
    n = (mw.to_3x3() @ Vector((0.0, 0.0, 1.0))).normalized()
    rise = math.sin(math.radians(lift_deg))
    conform_k = CONFORM * (1.0 - min(max((lift_deg - 25.0) / 30.0, 0.0), 1.0) * 0.7)   # taç plakaları dik kalır
    depth = []
    for i in range(samples):
        p = mw @ Vector((size * i / (samples - 1), 0.0, 0.0))
        hit, loc, _nrm, _i = body.ray_cast(p + n * 0.6, -n)
        depth.append((loc - p).dot(n) if hit else (depth[-1] if depth else 0.0))
    for v in obj.data.vertices:
        f = min(max(v.co.x / size, 0.0), 1.0) * (samples - 1)
        i = min(int(f), samples - 2)
        d = depth[i] + (depth[i + 1] - depth[i]) * (f - i)
        u = f / (samples - 1)
        v.co.z += conform_k * d + thick * 0.5 - SINK + size * rise * u * u


def swell_roots(body_obj, spots, k=1.0, attr_name="raw"):
    """Plaka tabanı çevresinde teni şişirir ve 'raw' ağırlığı yazar (et-kemik geçişi)."""
    mesh = body_obj.data
    attr = mesh.attributes.get(attr_name) or mesh.attributes.new(attr_name, "FLOAT", "POINT")
    mw = body_obj.matrix_world
    inv = mw.inverted()
    bases = [(s["loc"] + s["tail"] * s["size"] * k * 0.15, s["width"] * k * 0.55) for s in spots]
    for v in mesh.vertices:
        p = mw @ v.co
        w = 0.0
        for loc, r in bases:
            d = (p - loc).length
            if d < r + SWELL_REACH:
                w = max(w, 1.0 - max(d - r * 0.6, 0.0) / (r * 0.4 + SWELL_REACH))
        if w > 0.0:
            v.co = inv @ (p + (mw.to_3x3() @ v.normal).normalized() * SWELL * k * w * w)
        attr.data[v.index].value = w
    return attr


def bone_material(name):
    """Mat, lekeli yaşlı kemik: kenarlar aşınmış açık (pointiness), tabanda kurumuş kan, kahve lekeler."""
    mat, bsdf = kit.material(name, BONE, rough=0.82, sss=0.02)
    bsdf.inputs["Specular IOR Level"].default_value = 0.25
    nt = mat.node_tree
    ramp = kit._mottle(nt, 5.0, BONE_STAIN, BONE, low=0.52, high=0.86)
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    edge = nt.nodes.new("ShaderNodeMapRange")
    edge.inputs["From Min"].default_value = 0.5
    edge.inputs["From Max"].default_value = 0.56
    nt.links.new(geo.outputs["Pointiness"], edge.inputs["Value"])
    mix_edge = nt.nodes.new("ShaderNodeMix")
    mix_edge.data_type = "RGBA"
    mix_edge.inputs["B"].default_value = (*BONE_EDGE, 1.0)
    nt.links.new(edge.outputs["Result"], mix_edge.inputs["Factor"])
    nt.links.new(ramp.outputs["Color"], mix_edge.inputs["A"])
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    root = nt.nodes.new("ShaderNodeMapRange")
    root.inputs["From Min"].default_value = 0.09
    root.inputs["From Max"].default_value = 0.0
    nt.links.new(coord.outputs["Object"], sep.inputs["Vector"])
    nt.links.new(sep.outputs["X"], root.inputs["Value"])
    mix_root = nt.nodes.new("ShaderNodeMix")
    mix_root.data_type = "RGBA"
    mix_root.inputs["B"].default_value = (*BONE_ROOT, 1.0)
    nt.links.new(root.outputs["Result"], mix_root.inputs["Factor"])
    nt.links.new(mix_edge.outputs["Result"], mix_root.inputs["A"])
    kit._ao_darken(nt, mix_root.outputs["Result"], bsdf, crevice=(0.06, 0.045, 0.03))
    kit._bump(nt, bsdf, 60.0, 0.18)
    return mat


def raw_skin(mat):
    """Ten malzemesine 'raw' köşe ağırlığıyla çiğ et rengi karıştırır (plaka çevresi)."""
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    link = next(lk for lk in nt.links if lk.to_socket == bsdf.inputs["Base Color"])
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "raw"
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.inputs["B"].default_value = (*RAW, 1.0)
    nt.links.new(attr.outputs["Fac"], mix.inputs["Factor"])
    nt.links.new(link.from_socket, mix.inputs["A"])
    nt.links.remove(link)
    nt.links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
    return mat
