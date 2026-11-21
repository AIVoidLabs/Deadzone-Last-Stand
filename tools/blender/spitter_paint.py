"""Tükürücü boyası (7.3): asit lekesi ve gırtlak kesesi alanları — konsept malzemesi ve oyun köşe rengi aynı
alan fonksiyonlarından okunur (tek kaynak).

- acid_field: ağızdan çeneye, keseye, göğse ve karnın üstüne aşağı akan yeşil asit lekesi (0..1).
- sac_weight: gırtlak kesesinin gergin, damarlı, sarı-yeşil, hafif parlayan derisi (0..1).
Konsept: ağa "Acid"/"Sac" köşe öznitelikleri yazılır, acid_skin_material bunları okuyup ten rengine karıştırır.
Oyun: paint() köşe rengi sözleşmesi zombie_game ile aynı (RGB × oyuk koyulaşması, alfa = 1 - parıltı;
zombie_vc.gdshader: EMISSION = COLOR.rgb * (1 - COLOR.a) * glow_strength). bloater_paint'ten kopyalanan
paint / weight_multi / copy_weights burada (başka türün dosyasına bağımlı kalmamak için).
"""
import bmesh
from mathutils import Vector, noise

import walker_game as wg
import zombie_game as zg
import zombie_kit as kit

ACID_COLOR = (0.20, 0.55, 0.03)
ACID_GLOW = 0.35
SAC_COLOR = (0.36, 0.42, 0.12)
SAC_VEIN = (0.10, 0.16, 0.03)
SAC_GLOW = 0.20
BUBBLE_RIM = (0.20, 0.85, 0.04)
BUBBLE_CORE = (0.75, 1.0, 0.30)
THROAT_PULL = 0.9                 # kese yüzeyinde neck_01 payı


def acid_field(mouth, pts, sac, seed):
    """Asit lekesi ağırlığı: ağızdan aşağı akan lekeler (dikeyde uzamış), gürültüyle parçalı."""
    sc, sr = sac
    anchors = [(mouth, 0.045), (mouth + Vector((0.0, 0.005, -0.05)), 0.040),
               (sc + Vector((0.01, -sr.y * 0.9, 0.04)), 0.05), (sc + Vector((-0.04, -sr.y * 0.6, -sr.z * 0.8)), 0.06),
               (pts["chest"][0] + Vector((0.03, -0.15, -0.04)), 0.075),
               (pts["belly"][0] + Vector((-0.05, -0.25, 0.08)), 0.06)]
    shift = Vector((seed, seed * 0.3, 0.0))

    def fn(p):
        w = 0.0
        for a, r in anchors:
            d = p - a
            if d.z < 0.0:
                d.z *= 0.45            # aşağı akar
            w = max(w, 1.0 - zg._smooth(0.45 * r, r, d.length))
        if w <= 0.0:
            return 0.0
        n = zg._smooth(0.38, 0.62, zg.fbm(p + shift, 9.0))
        return w * (0.35 + 0.65 * n) if w < 0.85 else w
    return fn


def sac_weight(p, sac):
    c, r = sac
    d = p - c
    q = ((d.x / r.x) ** 2 + (d.y / r.y) ** 2 + (d.z / r.z) ** 2) ** 0.5
    return 1.0 - zg._smooth(0.95, 1.25, q)


def sac_color(p):
    """Gergin kese derisi: sarı-yeşil, koyu damar ağı."""
    dist, _pts = noise.voronoi(p * 22.0, distance_metric="DISTANCE", exponent=2.5)
    return zg._mix(SAC_VEIN, SAC_COLOR, zg._smooth(0.0, 0.05, dist[1] - dist[0]))


# ---------------------------------------------------------------- konsept

def mask_attrs(obj, acid, sac):
    mesh = obj.data
    mw = obj.matrix_world
    for name, fn in (("Acid", acid), ("Sac", lambda p: sac_weight(p, sac))):
        attr = mesh.attributes.get(name) or mesh.attributes.new(name, "FLOAT", "POINT")
        for i, v in enumerate(mesh.vertices):
            attr.data[i].value = fn(mw @ v.co)


def acid_skin_material(name, tone, bruise):
    """kit.skin_material + Sac (gergin yeşil deri, hafif parıltı) + Acid (yeşil leke, parıltı)."""
    mat = kit.skin_material(name, tone, bruise)
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    link = next(lk for lk in nt.links if lk.to_socket == bsdf.inputs["Base Color"])
    src = link.from_socket
    nt.links.remove(link)
    color = src
    for attr_name, col in (("Sac", SAC_COLOR), ("Acid", ACID_COLOR)):
        a = nt.nodes.new("ShaderNodeAttribute")
        a.attribute_name = attr_name
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        nt.links.new(a.outputs["Fac"], mix.inputs["Factor"])
        nt.links.new(color, mix.inputs["A"])
        mix.inputs["B"].default_value = (*col, 1.0)
        color = mix.outputs["Result"]
        if attr_name == "Acid":
            acid_fac = a.outputs["Fac"]
        else:
            sac_fac = a.outputs["Fac"]
    nt.links.new(color, bsdf.inputs["Base Color"])
    nt.links.new(color, bsdf.inputs["Emission Color"])
    m1 = nt.nodes.new("ShaderNodeMath")
    m1.operation = "MULTIPLY"
    m1.inputs[1].default_value = 0.25
    nt.links.new(sac_fac, m1.inputs[0])
    m2 = nt.nodes.new("ShaderNodeMath")
    m2.operation = "MULTIPLY_ADD"
    m2.inputs[1].default_value = 0.8
    nt.links.new(acid_fac, m2.inputs[0])
    nt.links.new(m1.outputs[0], m2.inputs[2])
    nt.links.new(m2.outputs[0], bsdf.inputs["Emission Strength"])
    return mat


# ---------------------------------------------------------------- oyun köşe rengi

def paint(obj, color_fn, dirt=0.45):
    """color_fn: (r, g, b) ya da (r, g, b, parıltı). Parlayan köşede oyuk koyulaşması yok."""
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.normal_update()
    shades = []
    for v in bm.verts:
        concave = 0.0
        if v.link_edges:
            avg = sum((e.other_vert(v).co for e in v.link_edges), Vector()) / len(v.link_edges)
            concave = (avg - v.co).dot(v.normal)
        shades.append(1.0 - dirt * min(max(concave * 120.0, 0.0), 1.0))
    bm.free()
    attr = mesh.color_attributes.get(zg.COLOR_ATTR) or mesh.color_attributes.new(zg.COLOR_ATTR, "FLOAT_COLOR", "POINT")
    mesh.color_attributes.active_color = attr
    mesh.color_attributes.render_color_index = mesh.color_attributes.find(zg.COLOR_ATTR)
    mw = obj.matrix_world
    for i, v in enumerate(mesh.vertices):
        c = color_fn(mw @ v.co)
        glow = c[3] if len(c) > 3 else 0.0
        s = shades[i] if glow < 0.5 else 1.0
        attr.data[i].color = (c[0] * s, c[1] * s, c[2] * s, 1.0 - glow)


def opaque(fn):
    return lambda p: tuple(fn(p)[:3])


def skin_color(skin, acid, sac):
    """Ten < kese derisi (hafif parlar) < asit lekesi (parlar)."""
    def fn(p):
        c, glow = skin(p), 0.0
        ws = sac_weight(p, sac)
        if ws > 0.0:
            c = zg._mix(c, sac_color(p), ws)
            glow = SAC_GLOW * ws
        wa = acid(p)
        if wa > 0.0:
            c = zg._mix(c, ACID_COLOR, wa)
            glow = max(glow, ACID_GLOW * wa)
        return (*c, glow)
    return fn


def body_color(shells, skin_fn):
    """Kumaş kabukları > ten (asit/kese dahil)."""
    def fn(p):
        for tree, reach, color_fn in shells:
            if tree.find_nearest(p, reach)[0] is not None:
                return color_fn(p)
        return skin_fn(p)
    return fn


def bubble_color(obj):
    """Kese: tepesi açık yeşil çekirdek, kenarı asit yeşili; tamamı parlar (alfa ~0)."""
    inv = obj.matrix_world.inverted()
    r = max(v.co.length for v in obj.data.vertices) or 1.0

    def fn(p):
        h = (inv @ p).z / r
        core = zg._smooth(-0.1, 0.85, h)
        return (*zg._mix(BUBBLE_RIM, BUBBLE_CORE, core), 0.8 + 0.2 * core)
    return fn


def weight_multi(obj, segments, keep=3, power=4.0):
    groups = {n: obj.vertex_groups.get(n) or obj.vertex_groups.new(name=n) for n in segments}
    mw = obj.matrix_world
    for v in obj.data.vertices:
        p = mw @ v.co
        scored = sorted(((1.0 / max(min(wg._seg_dist(p, a, b) for a, b in segs), 0.004) ** power, n)
                         for n, segs in segments.items()), reverse=True)[:keep]
        total = sum(w for w, _ in scored)
        for w, n in scored:
            groups[n].add([v.index], w / total, "REPLACE")


def copy_weights(obj, body, tree, at):
    _co, idx, _d = tree.find(at)
    for ge in body.data.vertices[idx].groups:
        name = body.vertex_groups[ge.group].name
        g = obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name)
        g.add(range(len(obj.data.vertices)), ge.weight, "REPLACE")


def throat_bias(obj, sac):
    """Kese yüzeyini neck_01'e çeker: neck_01 ölçeği keseyi şişirir (spit klibi)."""
    g = obj.vertex_groups["neck_01"].index
    mw = obj.matrix_world
    for v in obj.data.vertices:
        w = THROAT_PULL * sac_weight(mw @ v.co, sac)
        if w <= 0.0:
            continue
        row = {ge.group: ge.weight * (1.0 - w) for ge in v.groups}
        row[g] = row.get(g, 0.0) + w
        for gi, wt in row.items():
            obj.vertex_groups[gi].add([v.index], wt, "REPLACE")


def reweight_region(obj, segments, inside, keep=3, power=4.0):
    """Bölge içindeki köşelerin ağırlığını yalnız verilen kemikler arasında yeniden dağıtır."""
    names = list(segments)
    groups = {n: obj.vertex_groups.get(n) or obj.vertex_groups.new(name=n) for n in names}
    mw = obj.matrix_world
    for v in obj.data.vertices:
        p = mw @ v.co
        if not inside(p):
            continue
        for ge in list(v.groups):
            obj.vertex_groups[ge.group].remove([v.index])
        scored = sorted(((1.0 / max(min(wg._seg_dist(p, a, b) for a, b in segs), 0.004) ** power, n)
                         for n, segs in segments.items()), reverse=True)[:keep]
        total = sum(w for w, _ in scored)
        for w, n in scored:
            groups[n].add([v.index], w / total, "REPLACE")
