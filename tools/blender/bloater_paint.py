"""Patlayıcı oyun modeli yardımcıları (7.3): köşe başına parıltılı köşe rengi, kabarcık ve kızarık
taban renkleri, göbeğin spine_01'e çekilmesi. bloater_game.py içe aktarır.

Köşe rengi sözleşmesi zombie_game ile aynı: RGB renk × oyuk koyulaşması, alfa = 1 - parıltı
(zombie_vc.gdshader: EMISSION = COLOR.rgb * (1 - COLOR.a) * glow_strength). Burada renk fonksiyonu
(r, g, b) ya da (r, g, b, parıltı) döndürebilir: parıltı köşe başına değişir.
tank_game.weight_multi / copy_weights / mouth_color buraya kopyalandı (paylaşılan dosyaya dokunmamak ve
tank hattını içe aktarmamak için).
"""
import bmesh
from mathutils import Vector

import bloater_head as bh
import walker_game as wg
import zombie_game as zg

BLISTER_RIM = (0.95, 0.30, 0.03)
BLISTER_CORE = (1.0, 0.72, 0.18)
RASH_HOT = (0.55, 0.14, 0.03)       # kabarcık dibindeki kızarık et (hafif parlar)
RASH_DARK = (0.17, 0.035, 0.03)
RASH_GLOW = 0.45
GUT_PULL = 0.85                     # göbek yüzeyinde spine_01 payı


def paint(obj, color_fn, dirt=0.45):
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


def body_color(shells, skin, rashes):
    """Kumaş kabukları > kızarık taban (kabarcık dibi, kısmen parlar) > ten."""
    def fn(p):
        for tree, reach, color_fn in shells:
            if tree.find_nearest(p, reach)[0] is not None:
                return color_fn(p)
        w = 0.0
        for loc, r in rashes:
            d = (p - loc).length
            if d < r * 1.25:
                w = max(w, 1.0 - d / (r * 1.25))
        c = skin(p)
        if w <= 0.0:
            return c
        hot = zg._smooth(0.35, 0.8, w)
        c = zg._mix(zg._mix(c, RASH_DARK, zg._smooth(0.0, 0.35, w)), RASH_HOT, hot)
        return (*c, RASH_GLOW * hot)
    return fn


def blister_color(obj):
    """Kese: tepesi sarı çekirdek, kenarı turuncu; tamamı parlar (alfa ~0)."""
    inv = obj.matrix_world.inverted()
    r = max(obj.data.vertices[i].co.length for i in range(len(obj.data.vertices))) or 1.0

    def fn(p):
        h = (inv @ p).z / r
        core = zg._smooth(-0.1, 0.85, h)
        return (*zg._mix(BLISTER_RIM, BLISTER_CORE, core), 0.75 + 0.25 * core)
    return fn


def mouth_color(head, s):
    inv = head.matrix_world.inverted()
    y0, y1 = (bh.MOUTH_CENTER.y - bh.MOUTH_RADII.y * 0.3) * s, (bh.MOUTH_CENTER.y + bh.MOUTH_RADII.y) * s

    def fn(p):
        t = min(max(((inv @ p).y - y0) / (y1 - y0) / 0.8, 0.0), 1.0)
        return zg._mix(bh.MOUTH_FRONT, bh.MOUTH_BACK, t)
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


def gut_bias(obj, gut, hip):
    """Göbek küresinin yüzeyini spine_01'e çeker: swell ölçeği tüm küreyi şişirir, bacak kökü ve
    omuz bölgesi (kürenin dışı / üstü) kendi kemiklerinde kalır."""
    center, r = gut
    g01 = obj.vertex_groups["spine_01"].index
    mw = obj.matrix_world
    for v in obj.data.vertices:
        p = mw @ v.co
        d = (p - center).length
        if not (0.70 * r < d < 1.25 * r) or p.z > center.z + 0.22:
            continue
        if not (p.z > hip.z + 0.06 or p.y < hip.y - 0.12):
            continue
        g = GUT_PULL * (1.0 - zg._smooth(1.05 * r, 1.25 * r, d))
        row = {ge.group: ge.weight * (1.0 - g) for ge in v.groups}
        row[g01] = row.get(g01, 0.0) + g
        for gi, w in row.items():
            obj.vertex_groups[gi].add([v.index], w, "REPLACE")
