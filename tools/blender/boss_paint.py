"""Boss "Yığın" köşe rengi (7.4): konsept ve oyun modeli aynı renk fonksiyonlarıyla boyanır.

Sözleşme zombie_game ile aynı: RGB × oyuk koyulaşması, alfa = 1 - parıltı (zombie_vc.gdshader:
EMISSION = COLOR.rgb * (1 - COLOR.a) * glow_strength). Renk fonksiyonu yapı biriminde (kök ölçeğinden
önce) nokta alır; `space` matrisi dünya → yapı birimi çevirir (oyun modelinde 1/BUILD_SCALE).

Gövde: kaynamış cesetlerden yamalı deri — voronoi hücreleri ayrı ceset tonu (bazıları kumaş artığı),
hücre sınırlarında koyu kaynak dikişi; gömülü yüzler ve kollar kendi solgun tonunda (üstten okunur);
göğüs yarığı kızıl parlar, çevresine parlayan damarlar yayılır (zayıf nokta uzaktan okunsun).
"""
import math

import bmesh
from mathutils import Matrix, Vector, noise

import boss_parts as bparts
import zombie_game as zg

CORPSE = [(0.20, 0.21, 0.15), (0.26, 0.24, 0.17), (0.21, 0.16, 0.16), (0.15, 0.14, 0.11),
          (0.24, 0.23, 0.19), (0.18, 0.19, 0.15), (0.23, 0.19, 0.14)]
CLOTH = [(0.06, 0.08, 0.13), (0.18, 0.05, 0.035), (0.11, 0.11, 0.06), (0.24, 0.23, 0.20)]
FACE_TONES = [(0.40, 0.37, 0.28), (0.34, 0.36, 0.27), (0.42, 0.34, 0.30), (0.36, 0.33, 0.24)]
SEAM = (0.07, 0.018, 0.016)
HEART = (1.0, 0.10, 0.025)
HEART_RIM = (0.75, 0.05, 0.02)
VEIN = (0.85, 0.06, 0.02)
HEAD_TONE = (0.24, 0.24, 0.18)
HEAD_BRUISE = (0.20, 0.12, 0.13)
BONE = (0.50, 0.44, 0.31)
BONE_STAIN = (0.16, 0.06, 0.04)
SPIKE = (0.36, 0.31, 0.21)
CLAW_SKIN = (0.15, 0.13, 0.10)
TALON = (0.025, 0.02, 0.02)
TOOTH = (0.42, 0.36, 0.22)
EYE = (1.0, 0.12, 0.04)
TONGUE = (0.09, 0.03, 0.015)
PATCH_SCALE = 3.6
SEAM_W = 0.030
WARP = 0.09
VEIN_REACH = 0.26
VEIN_GLOW = 0.55
DIRT = {"body": 0.65, "head": 0.5, "mace": 0.6}


def _h(cell):
    """Hücre konumundan 0..1 sözde rastgele."""
    return (math.sin(cell.x * 12.9898 + cell.y * 78.233 + cell.z * 37.719) * 43758.5453) % 1.0


def _voronoi_cell(p, scale):
    dist, pts = noise.voronoi(p * scale, distance_metric="DISTANCE", exponent=2.5)
    return dist[1] - dist[0], pts[0]


def body_color(info):
    """info: kabartmalar [(ad, merkez, yarıçap, tür)] (yapı biriminde)."""
    def fn(p):
        q = p + Vector((noise.noise(p * 4.0), noise.noise(p * 4.0 + Vector((7.0, 0, 0))),
                        noise.noise(p * 4.0 + Vector((0, 5.0, 0))))) * WARP
        edge, cell = _voronoi_cell(q, PATCH_SCALE)
        r = _h(cell)
        if r > 0.88:
            base = CLOTH[int(r * 97) % len(CLOTH)]
            base = zg._mix(base, (0.08, 0.06, 0.04), 0.35 * zg._smooth(0.4, 0.7, zg.fbm(p, 5.0)))
        else:
            base = CORPSE[int(r * 131) % len(CORPSE)]
            base = zg._mix(base, (0.20, 0.10, 0.12), 0.45 * zg._smooth(0.45, 0.70, zg.fbm(p, 6.0)))
        for i, (_name, c, rad, kind) in enumerate(info):
            d = (p - c).length
            if d < rad:
                tone = FACE_TONES[i % len(FACE_TONES)] if kind == "face" else CORPSE[(i * 3) % len(CORPSE)]
                base = zg._mix(base, tone, 1.0 - zg._smooth(0.75 * rad, rad, d))
                edge = 1.0
        if edge < SEAM_W:
            base = zg._mix(SEAM, base, zg._smooth(0.0, SEAM_W, edge))
        if p.z < 0.32:
            base = zg._mix(base, (0.06, 0.05, 0.04), 0.6 * (1.0 - p.z / 0.32))
        return heart_glow(p, base)
    return fn


def heart_glow(p, base):
    """Yarık içi tam kızıl, dudağı kısmen; çevrede parlayan damarlar (alfa = 1 - parıltı)."""
    if p.y > -0.05:
        return base
    t, d, w = bparts.slit_coords(p)
    mid = bparts.SLIT_TOP.lerp(bparts.SLIT_BOT, 0.5)
    far = Vector((p.x - mid.x, 0.0, (p.z - mid.z) * 0.55)).length
    if 0.0 <= t <= 1.0 and d < w:
        return (*HEART, 0.85)
    if 0.0 <= t <= 1.0 and d < w * 2.0 and w > 0.0:
        k = 1.0 - (d - w) / w
        return (*zg._mix(base, HEART_RIM, k), 0.55 * k)
    if far < VEIN_REACH and p.z < bparts.SLIT_TOP.z + 0.02:
        dist, _pts = noise.voronoi(p * 6.0, distance_metric="DISTANCE", exponent=2.5)
        line = 1.0 - zg._smooth(0.015, 0.05, dist[1] - dist[0])
        k = line * (1.0 - far / VEIN_REACH)
        if k > 0.05:
            return (*zg._mix(base, VEIN, k), VEIN_GLOW * k)
    return base


def head_color(p):
    return zg._mix(HEAD_TONE, HEAD_BRUISE, zg._smooth(0.42, 0.68, zg.fbm(p, 9.0)))


def mace_color(p):
    return zg._mix(BONE, BONE_STAIN, zg._smooth(0.50, 0.78, zg.fbm(p, 7.0)))


def claw_color(tip_axis):
    """Pençe: avuç koyu ten, parmak uçlarına doğru karalaşır."""
    origin, axis = tip_axis

    def fn(p):
        f = zg._smooth(0.10, 0.38, (p - origin).dot(axis))
        return zg._mix(CLAW_SKIN, (0.04, 0.035, 0.03), f)
    return fn


def mouth_color(head, s):
    import boss_head as bh
    inv = head.matrix_world.inverted()
    y0, y1 = (bh.MOUTH_CENTER.y - bh.MOUTH_RADII.y * 0.3) * s, (bh.MOUTH_CENTER.y + bh.MOUTH_RADII.y) * s

    def fn(p):
        t = min(max(((inv @ p).y - y0) / (y1 - y0) / 0.8, 0.0), 1.0)
        return zg._mix(bh.MOUTH_FRONT, bh.MOUTH_BACK, t)
    return fn


def flat(c, glow=0.0):
    return lambda p: (*c, glow)


def paint(obj, color_fn, dirt=0.45, space=None):
    """Köşe rengi: color_fn(yapı birimi nokta) -> (r, g, b[, parıltı]); oyuk koyulaşması parlamayan köşede."""
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
        shades.append(1.0 - dirt * min(max(concave * 90.0, 0.0), 1.0))
    bm.free()
    attr = mesh.color_attributes.get(zg.COLOR_ATTR) or mesh.color_attributes.new(zg.COLOR_ATTR, "FLOAT_COLOR", "POINT")
    mesh.color_attributes.active_color = attr
    mesh.color_attributes.render_color_index = mesh.color_attributes.find(zg.COLOR_ATTR)
    m = (space or Matrix.Identity(4)) @ obj.matrix_world
    for i, v in enumerate(mesh.vertices):
        c = color_fn(m @ v.co)
        glow = c[3] if len(c) > 3 else 0.0
        s = shades[i] if glow < 0.3 else 1.0
        attr.data[i].color = (c[0] * s, c[1] * s, c[2] * s, 1.0 - glow)


def part_color(kind, ctx):
    """Parça türüne göre (renk fonksiyonu, oyuk payı)."""
    table = {
        "Boss_Body": (ctx.get("body_fn"), DIRT["body"]),
        "Boss_Head": (head_color, DIRT["head"]), "Boss_Jaw": (head_color, DIRT["head"]),
        "Boss_Mace": (mace_color, DIRT["mace"]), "Boss_Spike": (flat(SPIKE), 0.2),
        "Boss_Claw": (ctx.get("claw_fn"), 0.5), "Boss_Talon": (flat(TALON), 0.0),
        "Boss_Toes": (lambda p: zg._mix(CLAW_SKIN, (0.06, 0.05, 0.04), 0.5), 0.5),
        "Boss_Core": (flat(HEART, 1.0), 0.0), "Boss_Eye": (flat(EYE, 1.0), 0.0),
        "Boss_ToothU": (flat(TOOTH), 0.0), "Boss_ToothL": (flat(TOOTH), 0.0),
        "Boss_Tongue": (flat(TONGUE), 0.0), "Boss_Mouth": (ctx.get("mouth_fn"), 0.0),
    }
    return table.get(kind, (head_color, 0.4))


def concept_material(name):
    """Konsept önizlemesi: köşe rengi + parıltı + ince yumru (Godot kendi shader'ını kullanır)."""
    mat = zg.vertex_color_material(name, glow_strength=4.0)
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    tex = nt.nodes.new("ShaderNodeTexNoise")
    tex.inputs["Scale"].default_value = 30.0
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.25
    nt.links.new(tex.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    bsdf.inputs["Roughness"].default_value = 0.62
    return mat
