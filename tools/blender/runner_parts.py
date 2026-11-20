"""Koşucu (Pençeli) parçaları (V.5 v2): uzun parmaklı el, abartılı koyu pençeler, kemik çıkıntıları, kıyafet.

build_runner.py içe aktarır. v2 farkları:
- Pençeler uzun ve kalın, koyu kemik/boynuz; uca doğru koyulaşır. Pençe ağında köşe başına "claw_t"
  (kök 0 .. uç 1) özniteliği var: konsept malzemesi ve oyun köşe rengi bunu kullanır.
- Kıyafet kumaş gibi: gövde yüzeyinden kopyalanır ama boşluklu oturur (karında bol), uzuvlarda
  eklem çevresinde kıvrım halkaları, gövdede dikey dökümler, kesik kenarda kalın kıvrık kenar (hem);
  kol ağzı kola yakın oturur (kol kıyafetten kopuk görünmez).
"""
import heapq
import math

import bmesh
import bpy
from mathutils import Matrix, Vector, noise

import zombie_kit as kit

CLOTH_EDGE_SMOOTH = 16
FINGER_SEGS = ((0.058, 10.0), (0.046, 16.0), (0.034, 20.0))   # (boy m, kıvrılma derece)
FINGER_LEN = (0.88, 1.0, 0.96, 0.80)                           # işaret .. serçe
FINGER_RADII = (0.0110, 0.0100, 0.0090, 0.0082)                # kök .. uç boğum
CLAW_LEN = 0.150                                               # pençe boyu (orta parmak)
CLAW_RADIUS = 1.60                                             # pençe kökü / parmak ucu yarıçapı
CLAW_ROOT = (0.075, 0.052, 0.034)  # koyu boynuz kökü (doğrusal RGB)
CLAW_TIP = (0.008, 0.006, 0.005)   # uç: neredeyse siyah
CLAW_ATTR = "claw_t"


# ---------------------------------------------------------------- el ve pençe

def _toward(d, cup, deg):
    axis = d.cross(cup)
    if axis.length < 1e-5:
        return d.copy()
    return (Matrix.Rotation(math.radians(deg), 3, axis.normalized()) @ d).normalized()


def hand(pts, side, spec, t):
    """Uzun dört parmak + başparmak (skin düğümleri) ve her ucun pençe tarifi."""
    wrist, palm = pts[f"wrist_{side}"][0], pts[f"palm_{side}"][0]
    d = Vector(spec["fdir"]).normalized() if spec.get("fdir") else (palm - wrist).normalized()
    cup = Vector(spec["cup"]).normalized()
    across = d.cross(cup).normalized()
    inward = Vector((-1.0 if palm.x > 0 else 1.0, 0.0, 0.0))
    if across.dot(inward) < 0.0:
        across = -across
    extra, edges, claws = {}, [], []
    for i in range(4):
        p = palm + across * (1.5 - i) * 0.022 * t + d * 0.012
        fd = (Matrix.Rotation(math.radians((1.5 - i) * spec["fan"]), 3, d.cross(across)) @ d).normalized()
        prev = f"palm_{side}"
        for j, (seg, curl) in enumerate(FINGER_SEGS):
            fd = _toward(fd, cup, curl * spec.get("curl", 1.0))
            p = p + fd * seg * FINGER_LEN[i]
            extra[f"f{i}{j}_{side}"] = (p.copy(), FINGER_RADII[j + 1] * t)
            edges.append((prev, f"f{i}{j}_{side}"))
            prev = f"f{i}{j}_{side}"
        claws.append((p, fd, cup, CLAW_LEN * FINGER_LEN[i] ** 0.5, FINGER_RADII[3] * t * CLAW_RADIUS))
    td = (d * 0.35 + across * 0.75 + cup * 0.35).normalized()
    p = palm + across * 0.030 * t
    prev = f"palm_{side}"
    for j in range(2):
        td = _toward(td, cup, 18.0)
        p = p + td * 0.038
        extra[f"th{j}_{side}"] = (p.copy(), 0.0104 * t)
        edges.append((prev, f"th{j}_{side}"))
        prev = f"th{j}_{side}"
    claws.append((p, td, cup, CLAW_LEN * 0.70, 0.0104 * t * CLAW_RADIUS))
    return extra, edges, claws


def claw_mesh(bm, layer, base, d, cup, length, radius, bend=50.0, steps=6, ring=6):
    """Yaydan geçen, yanlardan basık, uca doğru sivrilen pençe. Köşe özniteliği: kökten uca 0..1."""
    p = base - d * radius * 0.9
    axis = d.cross(cup)
    axis = axis.normalized() if axis.length > 1e-4 else d.orthogonal().normalized()
    step_rot = Matrix.Rotation(math.radians(bend / steps), 3, axis)
    rings = []
    for k in range(steps):
        f = k / steps
        up = axis.cross(d).normalized()
        r = radius * (1.0 - f) ** 0.7
        row = []
        for q in range(ring):
            a = 2.0 * math.pi * q / ring
            vert = bm.verts.new(p + up * math.sin(a) * r + axis * math.cos(a) * r * 0.55)
            vert[layer] = f
            row.append(vert)
        rings.append(row)
        p = p + d * (length / steps)
        d = (step_rot @ d).normalized()
    tip = bm.verts.new(p)
    tip[layer] = 1.0
    for r0, r1 in zip(rings, rings[1:]):
        for q in range(ring):
            bm.faces.new((r0[q], r0[(q + 1) % ring], r1[(q + 1) % ring], r1[q]))
    for q in range(ring):
        bm.faces.new((rings[-1][q], rings[-1][(q + 1) % ring], tip))
    bm.faces.new(list(reversed(rings[0])))


def claw_color(f):
    """Pençe rengi kökten uca (oyun köşe rengi de bunu kullanır)."""
    k = min(max((f - 0.15) / 0.75, 0.0), 1.0) ** 0.8
    return tuple(CLAW_ROOT[i] + (CLAW_TIP[i] - CLAW_ROOT[i]) * k for i in range(3))


def claw_material(name):
    """Koyu boynuz: kökte kahve, uçta siyaha yakın (claw_t özniteliği), parlak cilalı."""
    mat, bsdf = kit.material(name, CLAW_ROOT, rough=0.30)
    nt = mat.node_tree
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = CLAW_ATTR
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.15
    ramp.color_ramp.elements[0].color = (*CLAW_ROOT, 1.0)
    ramp.color_ramp.elements[1].position = 0.90
    ramp.color_ramp.elements[1].color = (*CLAW_TIP, 1.0)
    nt.links.new(attr.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Specular IOR Level"].default_value = 0.6
    return mat


def build_claws(name, claws, mat, bend=42.0):
    bm = bmesh.new()
    layer = bm.verts.layers.float.new(CLAW_ATTR)
    for base, d, cup, length, radius in claws:
        claw_mesh(bm, layer, base, d.normalized(), cup.normalized(), length, radius, bend)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def bone_spurs(pts, spine_ridge):
    """Dirsekten geriye kemik dikeni; çıplak gövdede omurga boyunca küçük çıkıntılar."""
    spurs = []
    for s in ("L", "R"):
        sh, el, wr = (pts[f"{k}_{s}"][0] for k in ("shoulder", "elbow", "wrist"))
        back = ((el - wr).normalized() + (el - sh).normalized()).normalized()
        out = Vector((1.0 if el.x > 0 else -1.0, 0.0, 0.0))
        spurs.append((el + back * pts[f"elbow_{s}"][1] * 0.5, back, out, 0.045, 0.011))
    if spine_ridge:
        chain = [pts[n][0] for n in ("belly", "spine", "chest", "upchest")]
        for a, b in zip(chain, chain[1:]):
            axis = (b - a).normalized()
            back = Vector((0.0, 1.0, 0.0))
            back = (back - axis * back.dot(axis)).normalized()
            for f in (0.25, 0.75):
                spurs.append((a.lerp(b, f) + back * pts["spine"][1] * 0.80, back, -axis, 0.022, 0.011))
    return spurs


# ---------------------------------------------------------------- kumaş

def _edge_distance(bm):
    """Her köşenin açık kenara ağ üstü uzaklığı (m)."""
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
    return dist


FOLD_ZONES = {   # sınıf -> [(t merkez, t genişlik)]: eklem çevresinde sıkışma kıvrımları
    "uparm": [(0.85, 0.15)], "forearm": [(0.10, 0.15), (0.90, 0.12)],
    "thigh": [(0.10, 0.12), (0.90, 0.15)], "shin": [(0.10, 0.15), (0.85, 0.15)],
}
LIMB_LEN = {"uparm": 0.35, "forearm": 0.36, "thigh": 0.42, "shin": 0.40}


def _cloth_offset(co, part, base, seed, loose):
    """Kumaşın ten üstündeki yüksekliği: oturuş + kıvrım + döküm."""
    cls, t, _r = part(co)[:3]
    off = base
    sh = Vector((seed, 0.0, 0.0))
    if cls in FOLD_ZONES:          # boğumlu halka kıvrımları (gürültüyle bükülmüş)
        zone = sum(math.exp(-((t - c) / w) ** 2) for c, w in FOLD_ZONES[cls])
        phase = t * LIMB_LEN[cls] / 0.045 + 2.2 * noise.noise(co * 9.0 + sh)
        mask = max(0.0, noise.noise(co * 6.0 - sh)) * 1.6       # kıvrım yer yer, halka değil
        off += (0.0006 + 0.0026 * zone * mask) * (0.5 + 0.5 * math.sin(phase * math.tau))
    elif cls.startswith("torso") or cls == "hips":   # bol gövde: dikey döküm + karında bolluk
        drape = noise.noise(Vector((co.x * 22.0, co.y * 22.0, co.z * 4.0)) + sh)
        off += loose + 0.0035 * drape
    return off


def garment(body, name, keep, mat, part, base=0.006, loose=0.006, thickness=0.004,
            holes=0.0, seed=0.0, hem=0.004):
    """Gövdeden kumaş: keep(co) yüzleri kopyalar, kıvrım/dökümle dışa iter, kesik kenarı kıvırır."""
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bm.transform(body.matrix_world)
    shift = Vector((seed, seed * 1.7, seed * 0.3))

    def dead(f):
        c = f.calc_center_median()
        return not keep(c) or (holes > 0.0 and noise.noise(c * 9.0 + shift * 3.0) > 0.62 - holes * 0.3)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if dead(f)], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.normal_update()
    kit._relax_boundary(bm, CLOTH_EDGE_SMOOTH)
    bm.normal_update()
    dist = _edge_distance(bm)
    moves = []
    for v in bm.verts:
        roll = hem * math.exp(-(dist[v] / 0.007) ** 2)        # kalın kıvrık kenar
        fit = min(1.0, 0.15 + dist[v] / 0.04)                  # kenara yakın kola/bacağa oturur
        moves.append((v, v.normal * (_cloth_offset(v.co, part, base, seed, loose) * fit + roll)))
    for v, m in moves:
        v.co += m
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    solid = obj.modifiers.new("Solid", "SOLIDIFY")
    solid.thickness = thickness
    solid.offset = 1.0
    kit.apply_all(obj)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj
