"""Menü / son ekran / ikon amblemleri: menu_*, end_*, icon_* (18) — Çizgi roman mürekkep.

Çalıştırma (repo kökünden):
    blender --background --python tools/blender/ui_emblems_menu.py [-- menu_play icon_kill ...]
Çıktı: assets/textures/ui/emblems/<id>.png + build/shots/emblems_menu_contact.png (kontak).
"""

import math
import os
import sys

import bmesh
import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ui_ink as U  # noqa: E402

U.WORK_DIR = os.path.join(U.REPO, "build", "blender", "ink_menu")  # başka ajanla pasa dosyası çakışmasın
SOLDIER_GLB: str = os.path.join(U.REPO, "assets", "models", "characters", "soldier.glb")
HEAD_ZMIN: float = 1.60   # asker modelinde kafa bölgesi (z >= bu, |x| <= HEAD_XMAX)
HEAD_XMAX: float = 0.17
HEAD_SCALE: float = 5.0
VISOR_Z: tuple = (-0.22, 0.08)   # kafa merkezli, ölçeklenmiş birimde vizör bandı

def prism(k: U.Kit, polys: list, thick: float, m: str, c: tuple = (0, 0, 0), rot: tuple = (0, 0, 0)):
    """XZ düzleminde dışbükey çokgenlerden (saat yönü tersi) kalınlıklı levha."""
    verts: list = []
    faces: list = []
    for poly in polys:
        n = len(poly)
        b = len(verts)
        verts += [(x, -thick / 2, z) for x, z in poly]
        verts += [(x, thick / 2, z) for x, z in poly]
        faces.append(tuple(range(b, b + n)))
        faces.append(tuple(range(b + 2 * n - 1, b + n - 1, -1)))
        for i in range(n):
            j = (i + 1) % n
            faces.append((b + i, b + n + i, b + n + j, b + j))
    return k.mesh(verts, faces, m, c, rot)


def link(k: U.Kit, c: tuple, a: float, b: float, minor: float, angle: float, side: bool, m: str, segs: int = 28):
    """Zincir halkası (elips): angle = XZ düzleminde teğet açısı; side=True ise yandan görünür."""
    t = (math.cos(math.radians(angle)), 0.0, math.sin(math.radians(angle)))
    n = (0.0, 1.0, 0.0) if side else (-t[2], 0.0, t[0])
    verts: list = []
    faces: list = []
    ms = 8
    for i in range(segs):
        ph = 2 * math.pi * i / segs
        pu, pv = a * math.cos(ph), b * math.sin(ph)
        # dışa yön (yaklaşık)
        ou, ov = math.cos(ph) / a, math.sin(ph) / b
        ln = math.hypot(ou, ov)
        ou, ov = ou / ln, ov / ln
        for j in range(ms):
            q = 2 * math.pi * j / ms
            r = minor * math.cos(q)
            w = minor * math.sin(q)
            u, v = pu + ou * r, pv + ov * r
            verts.append((c[0] + t[0] * u + n[0] * v + 0 * w, c[1] + t[1] * u + n[1] * v + (w if not side else 0.0),
                          c[2] + t[2] * u + n[2] * v))
    # side=False: halka XZ düzleminde (v = dik yön), kalınlık y; side=True: halka (t, y) düzleminde, kalınlık dik yön
    if side:
        verts = []
        nn = (-t[2], 0.0, t[0])
        for i in range(segs):
            ph = 2 * math.pi * i / segs
            pu, pv = a * math.cos(ph), b * math.sin(ph)
            ou, ov = math.cos(ph) / a, math.sin(ph) / b
            ln = math.hypot(ou, ov)
            ou, ov = ou / ln, ov / ln
            for j in range(ms):
                q = 2 * math.pi * j / ms
                r = minor * math.cos(q)
                w = minor * math.sin(q)
                u, y = pu + ou * r, pv + ov * r
                verts.append((c[0] + t[0] * u + nn[0] * w, c[1] + y, c[2] + t[2] * u + nn[2] * w))
    for i in range(segs):
        i2 = (i + 1) % segs
        for j in range(ms):
            j2 = (j + 1) % ms
            faces.append((i * ms + j, i2 * ms + j, i2 * ms + j2, i * ms + j2))
    return k.mesh(verts, faces, m)


def bullet(k: U.Kit, c: tuple, rot: tuple, sc: float = 1.0, tip: float = 0.55, jacket: str = "copper") -> None:
    """Mermi: gömlek + kovan (taban z=0 merkez, uç +Z). Hepsi group_transform ile yerleşir."""
    before = {o.name for o in U.meshes()}
    case = [(0.0, 0.0), (0.095, 0.0), (0.100, 0.02), (0.084, 0.04), (0.086, 0.32), (0.078, 0.34)]
    jk = [(0.078, 0.34), (0.082, 0.50), (0.074, 0.50 + tip * 0.35), (0.045, 0.50 + tip * 0.75), (0.0, 0.50 + tip)]
    k.lathe(case, (0, 0, 0), "brass", segs=20)
    k.lathe(jk, (0, 0, 0), jacket, segs=20)
    k.ring((0, 0, 0.33), 0.082, 0.010, "dark", rot=(0, 0, 0))
    objs = [o for o in U.meshes() if o.name not in before]
    U.group_transform(objs, c, rot, sc)


def flame(k: U.Kit, base: tuple, rotz: float = 0.0, sc: float = 1.0) -> None:
    prof = [(0.0, 0.0), (0.30, 0.05), (0.40, 0.25), (0.24, 0.5), (0.30, 0.78), (0.14, 1.05), (0.17, 1.3), (0.0, 1.75)]
    for (s, m) in ((1.0, "ember"), (0.72, "yellow"), (0.42, "white")):
        k.lathe([(r * s * sc, z * s * sc) for r, z in prof], base, m, rot=(0, -90 + rotz, 0), segs=14)


def drip(k: U.Kit, pts: list, m: str = "flesh") -> None:
    for (x, y, z, s) in pts:
        k.ball((x, y, z), (s, s, s * 1.5), m)


def extra_mats(k: U.Kit) -> None:
    k.m["green"] = U.mat("green", (0.42, 0.72, 0.24), 0.5)
    k.m["visor"] = U.mat("visor", (1.0, 0.45, 0.08), 0.3, 0.0, emit=(1.0, 0.42, 0.06), emit_strength=5.0)
    k.m["gem"] = U.mat("gem", (0.86, 0.92, 1.0), 0.15, 0.0, emit=(0.80, 0.90, 1.0), emit_strength=0.45)


def soldier_head(k: U.Kit) -> list:
    """Askerin kafa bölgesini (kask) GLB'den keser; merkezler, HEAD_SCALE ile büyütür. Oyun GLB'si değişmez."""
    objs = U.import_glb(SOLDIER_GLB, ["Soldier"])
    o = objs[0]
    for mod in list(o.modifiers):
        o.modifiers.remove(mod)
    o.parent = None
    for a in [x for x in bpy.data.objects if x.type == "ARMATURE"]:
        bpy.data.objects.remove(a, do_unlink=True)
    U.bake_transforms(o)
    bm = bmesh.new()
    bm.from_mesh(o.data)
    kill = [v for v in bm.verts if v.co.z < HEAD_ZMIN or abs(v.co.x) > HEAD_XMAX]
    bmesh.ops.delete(bm, geom=kill, context="VERTS")
    bm.to_mesh(o.data)
    bm.free()
    xs = [v.co.x for v in o.data.vertices]
    ys = [v.co.y for v in o.data.vertices]
    zs = [v.co.z for v in o.data.vertices]
    c = ((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (min(zs) + max(zs)) / 2)
    U.group_transform([o], (-c[0] * HEAD_SCALE, -c[1] * HEAD_SCALE, -c[2] * HEAD_SCALE), (0, 0, 0), HEAD_SCALE)
    return [o]


def flames_up(k: U.Kit, base: tuple, sc: float, tongues: tuple) -> None:
    """Yukarı doğru yelpaze alev dilleri (ember + sarı + beyaz çekirdek). tongues: (eğim derece, boy çarpanı)."""
    prof = [(0.0, 0.0), (0.30, 0.05), (0.40, 0.25), (0.24, 0.5), (0.30, 0.78), (0.14, 1.05), (0.17, 1.3), (0.0, 1.75)]
    for (rz, ls) in tongues:
        for (s, m, up) in ((1.0, "ember", 0.0), (0.68, "yellow", 0.03), (0.38, "white", 0.06)):
            k.lathe([(r * s * sc * 1.5, z * s * sc * ls) for r, z in prof], (base[0] + up * rz * 0.01, base[1], base[2]),
                    m, rot=(0, rz, 0), segs=14)


def head_info(o) -> tuple:
    vs = [v.co for v in o.data.vertices]
    return (min(v.x for v in vs), max(v.x for v in vs), min(v.y for v in vs), max(v.y for v in vs),
            min(v.z for v in vs), max(v.z for v in vs))


def zombie_skull(k: U.Kit, c: tuple, s: float, eyes: bool = True) -> None:
    cx, cy, cz = c
    k.ball((cx, cy, cz), (0.44 * s, 0.46 * s, 0.50 * s), "skin")
    k.ball((cx, cy - 0.12 * s, cz - 0.36 * s), (0.30 * s, 0.30 * s, 0.20 * s), "skin")
    for sx in (-1, 1):
        k.ball((cx + sx * 0.17 * s, cy - 0.38 * s, cz + 0.04 * s), (0.11 * s, 0.07 * s, 0.11 * s), "dark")
        k.ball((cx + sx * 0.17 * s, cy - 0.43 * s, cz + 0.04 * s), (0.05 * s, 0.03 * s, 0.05 * s), "glowred")
    k.bx((cx, cy - 0.36 * s, cz - 0.38 * s), (0.34 * s, 0.07 * s, 0.07 * s), "dark", bev=0.01 * s)
    for i in range(6):
        x = cx + (-0.125 + i * 0.05) * s
        k.bx((x, cy - 0.40 * s, cz - 0.33 * s), (0.036 * s, 0.04 * s, 0.075 * s), "bone", bev=0.006)
        k.bx((x, cy - 0.40 * s, cz - 0.43 * s), (0.034 * s, 0.04 * s, 0.06 * s), "bone", bev=0.006)
    k.ball((cx + 0.02 * s, cy - 0.46 * s, cz - 0.12 * s), (0.05 * s, 0.05 * s, 0.08 * s), "dark")
    k.ball((cx - 0.26 * s, cy - 0.20 * s, cz + 0.42 * s), (0.17 * s, 0.10 * s, 0.09 * s), "bone", rot=(20, 0, 20))


def gear(k: U.Kit, c: tuple, r: float, teeth: int, m: str, depth: float = 0.30) -> None:
    k.tb(c, r, depth, m, axis="Y", segs=40, bev=0.01)
    for i in range(teeth):
        a = 360.0 * i / teeth
        ra = math.radians(a)
        k.bx((c[0] + math.cos(ra) * (r + 0.07), c[1], c[2] + math.sin(ra) * (r + 0.07)), (0.17, depth, 0.15), m,
             rot=(0, -a, 0), bev=0.01)
    k.tb((c[0], c[1] - 0.02, c[2]), r * 0.36, depth + 0.06, "dark", axis="Y", segs=24)
    k.ring((c[0], c[1] - depth / 2, c[2]), r * 0.78, 0.025, "dark", rot=(90, 0, 0))


# ------------------------------------------------------------------------------------------ menu

def paint_visor(k: U.Kit, o, mat_id: str) -> None:
    """Dokuda sarı olan (vizör bandı) yüzleri ışıyan/karanlık malzemeye atar (UV'den doku rengi okunur)."""
    img = None
    for n in o.data.materials[0].node_tree.nodes:
        if n.type == "TEX_IMAGE":
            img = n.image
    w, h = img.size
    px = list(img.pixels)
    uv = o.data.uv_layers.active.data
    hit = 0
    chosen: list = []
    for p in o.data.polygons:
        u = sum(uv[i].uv.x for i in p.loop_indices) / p.loop_total
        v = sum(uv[i].uv.y for i in p.loop_indices) / p.loop_total
        i0 = (int(min(max(v, 0.0), 0.999) * h) * w + int(min(max(u, 0.0), 0.999) * w)) * 4
        r, g, b = px[i0], px[i0 + 1], px[i0 + 2]
        if r > 0.55 and g > 0.40 and b < 0.30 and r - b > 0.35:
            chosen.append(p.index)
            hit += 1
    # vizör ayrı nesne olur (ışıma nesne başına okunur); gövde malzemesi aynen kalır
    vis = o.copy()
    vis.data = o.data.copy()
    bpy.context.scene.collection.objects.link(vis)
    bm = bmesh.new()
    bm.from_mesh(vis.data)
    keep = set(chosen)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index not in keep], context="FACES")
    bmesh.ops.scale(bm, vec=(1.012, 1.03, 1.012), verts=bm.verts)
    bm.to_mesh(vis.data)
    bm.free()
    vis.data.materials.clear()
    vis.data.materials.append(k.m[mat_id])
    for p in vis.data.polygons:
        p.use_smooth = True
    print("VISOR_FACES", hit, "of", len(o.data.polygons), flush=True)


HELMET_BOX: tuple = (-1.2, 1.2, -1.2, 1.2, -1.5, 1.4)


def soldier_helmet(k: U.Kit, glow: bool = True) -> tuple:
    """Askerin kaskı (tek kurucu; menu_play / end_victory / end_defeat kullanır). Yüz -Y'ye bakar, ~2.9 birim boyunda.
    Yüksek kubbe, kaş siperi, geniş vizör (glow=False: kırık ve sönük), elmacık/çene zırhı, tek solunum ızgarası,
    iki küçük filtre, kulaklık diskleri, boyun yakası, turuncu şerit, çizikler."""
    k.m["hel"] = U.mat("hel", (0.26, 0.33, 0.44), 0.62, 0.3)
    k.m["hel2"] = U.mat("hel2", (0.19, 0.21, 0.25), 0.45, 0.4)
    k.m["visor"] = U.mat("visor", (1.0, 0.55, 0.06), 0.3, 0.0, emit=(1.0, 0.55, 0.05), emit_strength=5.0)
    k.ball((0, 0.10, 0.36), (1.02, 1.12, 1.08), "hel", segs=40)                               # yüksek kubbe
    k.bx((0, 0.0, 1.27), (0.20, 1.5, 0.10), "hel2", rot=(-6, 0, 0), bev=0.04)                 # tepe sırtı
    k.bx((0, -0.86, 0.55), (1.70, 0.34, 0.12), "hel2", rot=(-18, 0, 0), bev=0.05)             # kaş siperi
    k.ball((0, -0.64, 0.12), (1.03, 0.45, 0.34), "dark")                                      # vizör çerçevesi
    k.ball((0, -0.74, 0.12), (0.92, 0.47, 0.22), "visor" if glow else "dark")
    if glow:
        k.ball((0, -0.76, 0.12), (0.86, 0.47, 0.07), "yellow")
    for vx in (-0.30, 0.30):
        k.bx((vx, -1.17 + 0.05 * abs(vx), 0.12), (0.03, 0.06, 0.40), "dark", bev=0.004)                 # geniş vizör
    # alt yüz: çene/elmacık zırhı
    k.ball((0, -0.12, -0.66), (0.76, 0.82, 0.48), "hel", segs=36)
    k.bx((0, -0.95, -0.58), (1.0, 0.32, 0.70), "hel2", rot=(-8, 0, 0), bev=0.09)
    for sx in (-1, 1):
        k.bx((0.74 * sx, -0.62, -0.20), (0.38, 0.52, 0.48), "hel", rot=(0, 0, 26 * sx), bev=0.07)
        k.tb((0.64 * sx, -0.95, -0.55), 0.17, 0.30, "metal", axis="Y", segs=20, bev=0.02)    # filtre
        k.tb((0.64 * sx, -1.12, -0.55), 0.12, 0.05, "orange", axis="Y", segs=20)
        k.tb((1.02 * sx, 0.12, -0.02), 0.46, 0.26, "hel2", axis="X", segs=32, bev=0.03)       # kulaklık diski
        k.tb((1.17 * sx, 0.12, -0.02), 0.30, 0.08, "orange", axis="X", segs=28)
        k.tb((1.22 * sx, 0.12, -0.02), 0.13, 0.06, "dark", axis="X", segs=16)
        for (z, y) in ((0.70, -0.30), (0.30, -0.62)):
            k.ball((0.80 * sx * (1.0 if z < 0.5 else 0.8), y, z), (0.05, 0.05, 0.05), "steel")
    k.bx((0, -0.90, -1.00), (0.74, 0.36, 0.26), "hel2", rot=(-10, 0, 0), bev=0.06)           # çene ucu
    k.tb((0, -1.12, -0.55), 0.27, 0.12, "dark", axis="Y", segs=28)                            # solunum ızgarası
    k.tb((0, -1.16, -0.55), 0.31, 0.05, "steel", axis="Y", segs=28)
    for z in (-0.43, -0.55, -0.67):
        k.bx((0, -1.20, z), (0.40, 0.03, 0.045), "steel", bev=0.005)
    # boyun yakası
    k.tb((0, 0.10, -1.22), 0.82, 0.50, "hel2", axis="Z", segs=36, bev=0.03)
    k.tb((0, 0.10, -1.00), 0.88, 0.07, "steel", axis="Z", segs=36)
    k.bx((0, -0.62, -1.22), (1.00, 0.30, 0.40), "hel", rot=(-6, 0, 0), bev=0.06)
    # turuncu şerit + çizikler
    k.tube([(0, -0.78, 0.96), (0, -0.45, 1.22), (0, 0.2, 1.34), (0, 0.8, 1.12)], 0.09, "orange", 1.0, 8)
    k.tube([(0.78, -0.30, 0.45), (0.86, -0.1, 0.70)], 0.011, "bone", 1.0, 6)
    k.tube([(-0.60, -0.62, 0.95), (-0.42, -0.72, 0.75)], 0.011, "bone", 1.0, 6)
    if not glow:
        cracks(k, (0.20, -1.09, 0.08), 6, 4, 0.40)
        k.bx((-0.45, -1.07, 0.10), (0.30, 0.04, 0.20), "dark", rot=(0, 0, 25), bev=0.004)
    return HELMET_BOX


HELMET_ARGS: dict = {"halo": 1.5, "halo_color": (1.0, 0.55, 0.12), "glow": 1.0,
                     "levels": (0.14, 0.40, 0.72, 1.0), "hatch": 0.7}


def blob_flame(k: U.Kit, base: tuple, sc: float, rot: float) -> None:
    """Yuvarlak, sade alev dili (sivri değil)."""
    prof = [(0.0, 0.0), (0.45, 0.08), (0.58, 0.40), (0.50, 0.80), (0.30, 1.15), (0.10, 1.38), (0.0, 1.45)]
    for (s, m, dz) in ((1.0, "ember", 0.0), (0.78, "yellow", 0.03), (0.50, "white", 0.06)):
        k.lathe([(r * s * sc, z * s * sc) for r, z in prof], (base[0], base[1], base[2] + dz), m, rot=(0, rot, 0), segs=16)


def menu_play(k: U.Kit) -> dict:
    soldier_helmet(k, True)
    return dict(az=-24, el=10, lens=55, roll=0, fill=0.84)


def menu_records(k: U.Kit) -> dict:
    k.tb((0, 0.1, -0.2), 0.10, 2.0, "wood", axis="Z", segs=12, r2=0.07)
    k.tb((0, 0.1, 0.80), 0.0, 0.40, "wood", axis="Z", r2=0.10, segs=12)
    zombie_skull(k, (0, -0.05, 0.52), 1.1)
    k.bx((0, 0.0, -0.40), (0.55, 0.06, 0.10), "wood", rot=(0, 0, 8), bev=0.01)
    for i in range(7):
        x = -0.18 + 0.06 * i
        k.ball((x, -0.1, -0.52 - 0.05 * math.sin(i)), (0.03, 0.03, 0.03), "steel")
    k.tube([(-0.2, -0.1, -0.46), (-0.35, -0.12, -0.64), (-0.1, -0.12, -0.78)], 0.02, "steel", 1.0, 6)
    k.bx((-0.10, -0.14, -0.92), (0.34, 0.04, 0.50), "steel", rot=(0, 0, -6), bev=0.05)
    for z in (-0.80, -0.92, -1.04):
        k.bx((-0.10, -0.17, z), (0.22, 0.02, 0.04), "dark", rot=(0, 0, -6), bev=0.003)
    drip(k, [(0.12, -0.5, 0.15, 0.04), (-0.25, -0.5, 0.35, 0.03), (0.25, -0.2, -0.65, 0.03)])
    return dict(az=-10, el=8, lens=55, roll=0, fill=0.93)


def menu_settings(k: U.Kit) -> dict:
    gear(k, (-0.15, 0.0, 0.12), 0.58, 10, "metal")
    k.ball((-0.40, -0.18, 0.40), (0.14, 0.03, 0.10), "flesh")
    k.ball((0.10, -0.18, -0.05), (0.10, 0.03, 0.14), "flesh")
    # İngiliz anahtarı: çapraz
    k.bx((0.30, -0.30, -0.05), (0.18, 0.12, 1.7), "steel", rot=(0, 38, 0), bev=0.03)
    k.tb((0.84, -0.30, 0.64), 0.26, 0.14, "steel", axis="Y", segs=6, rot=(0, 0, 0), bev=0.01)
    k.tb((0.84, -0.30, 0.64), 0.12, 0.2, "dark", axis="Y", segs=12)
    k.bx((0.84, -0.30, 0.82), (0.14, 0.2, 0.18), "dark", bev=0.01)
    k.tb((-0.25, -0.30, -0.60), 0.22, 0.14, "steel", axis="Y", segs=10)
    k.bx((-0.34, -0.30, -0.62), (0.18, 0.2, 0.16), "dark", bev=0.01)
    drip(k, [(0.3, -0.38, -0.4, 0.035), (-0.5, -0.2, -0.50, 0.03)])
    return dict(az=-8, el=6, lens=55, roll=0, fill=0.93)


def menu_credits(k: U.Kit) -> dict:
    def tag(c: tuple, rot: tuple, lines: int) -> None:
        k.bx(c, (0.62, 0.04, 0.95), "steel", rot=rot, bev=0.08)
        k.bx((c[0], c[1] - 0.025, c[2]), (0.52, 0.02, 0.85), "metal", rot=rot, bev=0.06)
        for i in range(lines):
            k.bx((c[0], c[1] - 0.04, c[2] + 0.22 - i * 0.14), (0.36, 0.02, 0.05), "dark", rot=rot, bev=0.003)
        k.tb((c[0] + 0.0, c[1], c[2] + 0.5), 0.06, 0.06, "dark", axis="Y", rot=rot, segs=12)
    tag((-0.32, 0.0, -0.10), (0, 0, 14), 4)
    tag((0.38, -0.1, -0.20), (0, 0, -10), 3)
    k.ball((0.30, -0.16, -0.28), (0.07, 0.02, 0.10), "flesh")
    pts = [(-0.50, 0.0, 0.40), (-0.6, 0.0, 0.8), (-0.2, 0.0, 1.1), (0.2, 0.0, 1.1), (0.5, 0.0, 0.8), (0.50, -0.1, 0.30)]
    for i in range(24):
        t = i / 23
        a = math.pi * (0.1 + 0.8 * t)
        k.ball((-math.cos(a) * 0.62 + 0.0, -0.05, 0.40 + math.sin(a) * 0.80), (0.04, 0.04, 0.04), "steel")
    drip(k, [(-0.4, -0.06, -0.62, 0.035), (0.5, -0.12, -0.72, 0.03)])
    return dict(az=-6, el=8, lens=55, roll=-4, fill=0.93)


def menu_quit(k: U.Kit) -> dict:
    k.bx((0, 0.20, 0), (1.5, 0.10, 1.9), "dark", bev=0.03)
    k.bx((0, 0.10, 0.0), (1.05, 0.04, 1.45), "ember", bev=0.01)       # içeriden sızan turuncu ışık
    k.bx((0, 0.0, 0.98), (1.55, 0.26, 0.16), "metal", bev=0.02)
    k.bx((0, 0.0, -0.98), (1.55, 0.26, 0.16), "metal", bev=0.02)
    k.bx((-0.76, 0.0, 0), (0.16, 0.26, 1.9), "metal", bev=0.02)
    k.bx((0.76, 0.0, 0), (0.16, 0.26, 1.9), "metal", bev=0.02)
    before = {o.name for o in U.meshes()}
    k.bx((0.65, 0.0, 0.0), (1.3, 0.20, 1.62), "steel", bev=0.04)
    k.bx((0.65, -0.11, 0.0), (1.12, 0.03, 1.44), "metal", bev=0.02)
    for (x, z) in ((0.14, 0.68), (1.16, 0.68), (0.14, -0.68), (1.16, -0.68)):
        k.ball((x, -0.14, z), (0.05, 0.03, 0.05), "dark")
    gear(k, (0.65, -0.13, 0.0), 0.30, 8, "dark", 0.10)
    for a in (0, 60, 120):
        k.bx((0.65, -0.20, 0.0), (0.74, 0.05, 0.07), "steel", rot=(0, a, 0), bev=0.01)
    k.tb((0.65, -0.24, 0.0), 0.09, 0.06, "gold", axis="Y", segs=14)
    for z in (-0.33, 0.33):
        k.bx((0.65, -0.13, z * 1.9), (0.9, 0.03, 0.05), "dark", bev=0.003)
    objs = [o for o in U.meshes() if o.name not in before]
    U.group_transform(objs, (-0.70, -0.16, 0.0), (0, 0, -58), 1.0)
    for z in (-0.6, 0.6):
        k.tb((-0.72, -0.13, z), 0.07, 0.3, "dark", axis="Z", segs=10)
    return dict(az=-4, el=8, lens=55, roll=0, fill=0.93)


def menu_resume(k: U.Kit) -> dict:
    prism(k, [[(-0.55, 0.65), (-0.55, -0.65), (0.75, 0.0)]], 0.10, "steel", (0.1, 0, 0))
    prism(k, [[(-0.40, 0.45), (-0.40, -0.45), (0.45, 0.0)]], 0.05, "edge", (0.1, -0.07, 0))
    k.bx((-0.72, 0.0, 0.0), (0.32, 0.18, 0.9), "leather", bev=0.03)
    k.bx((-0.72, -0.10, 0.0), (0.10, 0.04, 0.8), "dark", bev=0.01)
    for z in (-0.3, 0.0, 0.3):
        k.ball((-0.72, -0.12, z), (0.04, 0.03, 0.04), "brass")
    k.ball((0.2, -0.12, 0.15), (0.12, 0.02, 0.16), "flesh")
    drip(k, [(0.55, -0.12, -0.1, 0.035), (0.0, -0.12, -0.62, 0.03)])
    return dict(az=-6, el=4, lens=55, roll=0, fill=0.93)


def menu_restart(k: U.Kit) -> dict:
    n = 18
    for i in range(n):
        a = math.radians(40 + 280 * i / (n - 1))
        x, z = math.cos(a) * 0.72, math.sin(a) * 0.72
        link(k, (x, 0.0, z), 0.13, 0.075, 0.032, math.degrees(a) + 90, i % 2 == 1, "steel")
    a = math.radians(320)
    d = (-math.sin(a), math.cos(a))
    c = (math.cos(a) * 0.72 + d[0] * 0.28, math.sin(a) * 0.72 + d[1] * 0.28)
    prism(k, [[(-0.36, -0.30), (0.36, -0.30), (0.0, 0.35)]], 0.12, "steel", (c[0], 0, c[1]),
          (0, math.degrees(math.atan2(d[0], d[1])), 0))
    k.ball((0.62, -0.09, -0.62), (0.07, 0.03, 0.10), "flesh")
    drip(k, [(-0.7, -0.06, -0.3, 0.035), (-0.2, -0.06, -0.75, 0.03)])
    return dict(az=-4, el=4, lens=55, roll=0, fill=0.93)


def menu_home(k: U.Kit) -> dict:
    """Sığınak kapısı: betonarme duvarda perçinli çelik kapı, valf çarkı, kilit pimleri, uyarı şeridi."""
    k.bx((0, 0.25, 0.0), (2.0, 0.40, 1.9), "dust", bev=0.05)                      # beton duvar
    k.bx((0, -0.02, -0.02), (1.30, 0.16, 1.55), "dark", bev=0.03)                  # kapı çerçevesi
    k.bx((0, -0.12, -0.02), (1.14, 0.12, 1.40), "metal", bev=0.05)                 # kapı kanadı
    for sz in (-0.5, 0.5):
        k.bx((0, -0.19, sz * 0.9 - 0.02), (1.0, 0.03, 0.30), "hel2" if False else "dark", bev=0.01)
    for (x, z) in [(-0.50, 0.62), (0.50, 0.62), (-0.50, -0.66), (0.50, -0.66), (-0.50, 0.0), (0.50, 0.0)]:
        k.ball((x, -0.20, z), (0.045, 0.03, 0.045), "steel")                       # perçinler
    k.ring((0, -0.22, 0.05), 0.34, 0.05, "steel", rot=(90, 0, 0))                  # valf çarkı
    k.tb((0, -0.22, 0.05), 0.09, 0.08, "steel", axis="Y", segs=16)
    for a in (0, 45, 90, 135):
        k.bx((0, -0.22, 0.05), (0.66, 0.04, 0.05), "steel", rot=(0, a, 0), bev=0.005)
    for z in (0.40, 0.05, -0.30):                                                  # kilit pimleri
        k.bx((0.62, -0.18, z), (0.24, 0.07, 0.10), "gold", bev=0.01)
    for sz in (0.62, -0.66):
        k.bx((-0.64, -0.17, sz), (0.10, 0.08, 0.26), "steel", bev=0.01)            # menteşe
    for i in range(7):                                                              # uyarı şeridi (sarı-siyah)
        k.bx((-0.78 + i * 0.26, -0.21, 0.98), (0.17, 0.05, 0.11), "yellow" if i % 2 == 0 else "dark",
             rot=(0, 0, 25), bev=0.004)
    k.bx((0, -0.18, 0.87), (1.14, 0.05, 0.05), "dark", bev=0.004)
    drip(k, [(-0.3, -0.22, -0.78, 0.035), (0.5, -0.22, -0.60, 0.03)])
    return dict(az=-20, el=8, lens=55, roll=0, fill=0.94)


# ------------------------------------------------------------------------------------------ son ekran

def cracks(k: U.Kit, c: tuple, n: int, seed: int, length: float = 0.28) -> None:
    import random
    rnd = random.Random(seed)
    for i in range(n):
        ang = rnd.uniform(0, 6.28)
        pts = []
        r = 0.05
        for s in range(4):
            r += rnd.uniform(0.4, 0.8) * length / 2
            aa = ang + rnd.uniform(-0.35, 0.35)
            pts.append((c[0] + math.cos(aa) * r, c[1], c[2] + math.sin(aa) * r))
        k.tube(pts, 0.022, "dark", 0.3, 6)


def end_victory(k: U.Kit) -> dict:
    soldier_helmet(k, True)
    # sade şafak diski + ışınlar (kaskın arkasında)
    for (r, mm, y) in ((2.15, "ember", 1.2), (1.75, "yellow", 1.18), (1.30, "white", 1.16)):
        k.tb((0, y, 0.10), r, 0.05, mm, axis="Y", segs=48)
    for i in range(12):
        a = i * 30
        k.bx((math.sin(math.radians(a)) * 2.7, 1.2, 0.10 + math.cos(math.radians(a)) * 2.7), (0.22, 0.04, 0.9), "yellow",
             rot=(0, a, 0), bev=0.004)
    # künye: zincir + yırtık köşeli plaka
    k.tube([(-0.75, -0.55, -1.25), (-0.40, -0.85, -1.62), (0.0, -0.95, -1.75), (0.40, -0.85, -1.62), (0.75, -0.55, -1.25)],
           0.035, "steel", 1.0, 8)
    prism(k, [[(-0.30, -1.62), (-0.30, -2.15), (0.05, -2.22), (0.30, -2.12), (0.30, -1.62)]], 0.06, "steel", (0.0, -0.98, 0.0))
    k.bx((0.0, -1.03, -1.78), (0.5, 0.03, 0.08), "red", bev=0.004)
    for z in (-1.92, -2.02):
        k.bx((0.0, -1.03, z), (0.38, 0.03, 0.035), "dark", bev=0.003)
    k.ball((0.0, -1.03, -1.68), (0.05, 0.03, 0.05), "dark")
    return dict(az=-24, el=6, lens=55, roll=0, fill=0.94)


def end_defeat(k: U.Kit) -> dict:
    before = {o.name for o in U.meshes()}
    soldier_helmet(k, False)
    objs = [o for o in U.meshes() if o.name not in before]
    U.group_transform(objs, (0, 0, 0), (0, 62, 0), 1.0)      # yan yatık, düşmüş
    U.bpy.context.view_layer.update()
    zmin = min(p.z for p in U.sample_points(objs, 1))
    k.m["pool"] = U.mat("pool", (0.30, 0.01, 0.02), 0.12)
    for (ox, oy, sx, sy, mm) in ((0.0, 0.0, 2.3, 1.7, "pool"), (0.2, -0.1, 1.5, 1.1, "pool")):
        k.ball((ox, oy, zmin + 0.02), (sx, sy, 0.05), mm)
    for (x, y, s) in ((1.7, -0.9, 0.12), (-1.8, -0.5, 0.10), (0.6, -1.7, 0.09), (-1.0, 1.2, 0.08)):
        k.ball((x, y, zmin + 0.03), (s, s, 0.04), "pool")
    return dict(az=-12, el=14, lens=55, roll=0, fill=0.92)


# ------------------------------------------------------------------------------------------ ikonlar (kalın, sade)

def icon_crystal(k: U.Kit) -> dict:
    """Parlak, çok yüzeyli kristal öbeği; yüzeyler belirgin ton farkı + beyaz uç ve parıltılar."""
    k.m["gem"] = U.mat("gem2", (0.42, 0.86, 1.0), 0.12, 0.0)
    k.m["gem2"] = U.mat("gem3", (0.75, 0.95, 1.0), 0.1, 0.0)
    prof = [(0.0, -0.55), (0.28, -0.38), (0.36, 0.20), (0.30, 0.55), (0.0, 1.0)]
    for (x, z, sc, rot, mm) in ((0.0, 0.0, 1.0, (0, 0, 0), "gem"), (-0.52, -0.25, 0.68, (0, 22, 8), "gem2"),
                                (0.50, -0.28, 0.62, (0, -26, -8), "gem")):
        k.lathe([(r * sc, zz * sc) for r, zz in prof], (x, 0, z), mm, rot=rot, segs=5)
    k.lathe([(0.0, 0.0), (0.12, 0.0), (0.0, 0.35)], (0.0, -0.04, 0.80), "white", segs=5)   # parlak uç
    for (x, z, s) in ((-0.55, 0.75, 0.16), (0.62, 0.55, 0.12), (0.30, 1.15, 0.10)):         # parıltı yıldızları
        k.bx((x, -0.2, z), (s * 2.4, 0.02, s * 0.4), "white", bev=0.002)
        k.bx((x, -0.2, z), (s * 0.4, 0.02, s * 2.4), "white", bev=0.002)
    k.ball((0.0, 0.0, -0.62), (0.7, 0.08, 0.06), "dark")
    return dict(az=0, el=12, lens=60, roll=0, fill=0.95)


def icon_kill(k: U.Kit) -> dict:
    zombie_skull(k, (0, 0, 0), 1.5)
    return dict(az=0, el=6, lens=60, roll=-6, fill=0.95)


def icon_wave(k: U.Kit) -> dict:
    k.bx((0, 0.05, 0), (1.5, 0.12, 1.5), "metal", bev=0.08)
    for i, x in enumerate((-0.42, 0.0, 0.42)):
        prism(k, [[(x - 0.22, 0.74), (x + 0.30, -0.74), (x + 0.04, 0.74)]], 0.10, "dark", (0, -0.04, 0))
        prism(k, [[(x - 0.16, 0.64), (x + 0.26, -0.62), (x + 0.0, 0.64)]], 0.04, "glowred", (0, -0.10, 0))
    drip(k, [(-0.3, -0.12, -0.78, 0.05), (0.4, -0.12, -0.80, 0.04)])
    return dict(az=0, el=4, lens=60, roll=-6, fill=0.95)


def icon_time(k: U.Kit) -> dict:
    k.tb((0, 0, 0), 0.72, 0.22, "steel", axis="Y", segs=40)
    k.tb((0, -0.12, 0), 0.60, 0.06, "bone", axis="Y", segs=40)
    k.ring((0, -0.1, 0), 0.68, 0.06, "metal", rot=(90, 0, 0))
    for i in range(12):
        a = math.radians(i * 30)
        k.bx((math.cos(a) * 0.50, -0.17, math.sin(a) * 0.50), (0.07, 0.03, 0.14 if i % 3 == 0 else 0.08), "dark",
             rot=(0, 90 - math.degrees(a), 0), bev=0.004)
    k.bx((0.0, -0.2, 0.18), (0.10, 0.04, 0.42), "dark", rot=(0, 0, -14), bev=0.01)
    k.bx((0.15, -0.2, -0.02), (0.36, 0.04, 0.09), "glowred", rot=(0, 0, 20), bev=0.01)
    k.ball((0, -0.22, 0), (0.08, 0.04, 0.08), "metal")
    k.tb((0, 0, 0.82), 0.08, 0.20, "steel", axis="Z", segs=12)
    cracks(k, (-0.25, -0.2, 0.2), 3, 5, 0.9)
    k.tube([(-0.60, -0.2, 0.28), (-0.30, -0.2, 0.05), (-0.45, -0.2, -0.20), (-0.10, -0.2, -0.50)], 0.03, "dark", 0.5, 6)
    return dict(az=0, el=4, lens=60, roll=-8, fill=0.95)


def icon_level(k: U.Kit) -> dict:
    k.bx((0, 0.06, 0), (1.5, 0.10, 1.7), "metal", bev=0.10)
    for z0, m in ((0.05, "orange"), (-0.35, "yellow")):
        l = [(-0.6, z0 - 0.25), (0.0, z0 + 0.15), (0.0, z0 + 0.4), (-0.6, z0)]
        r = [(0.0, z0 + 0.15), (0.6, z0 - 0.25), (0.6, z0), (0.0, z0 + 0.4)]
        prism(k, [l, r], 0.12, m, (0, -0.06, 0.32 if m == "orange" else 0.3))
    for (x, z) in ((-0.62, 0.72), (0.62, 0.72), (-0.62, -0.72), (0.62, -0.72)):
        k.ball((x, -0.02, z), (0.06, 0.04, 0.06), "steel")
    return dict(az=0, el=4, lens=60, roll=0, fill=0.95)


MENU: dict = {
    "menu_play": (menu_play, 301, HELMET_ARGS), "menu_records": (menu_records, 302, {}),
    "menu_settings": (menu_settings, 303, {}), "menu_credits": (menu_credits, 304, {}),
    "menu_quit": (menu_quit, 305, {}), "menu_resume": (menu_resume, 306, {}),
    "menu_restart": (menu_restart, 307, {}), "menu_home": (menu_home, 308, {}),
    "end_victory": (end_victory, 309, dict(HELMET_ARGS, halo=0.0, blood_spots=2)), "end_defeat": (end_defeat, 310, {"rim": 0.15, "blood_spots": 7, "levels": (0.14, 0.40, 0.72, 1.0)}),
    "icon_crystal": (icon_crystal, 311, {"blood_spots": 0, "levels": (0.3, 0.55, 0.8, 1.0), "halo": 0.7, "halo_color": (0.45, 0.85, 1.0), "glow": 0.0}), "icon_kill": (icon_kill, 312, {}),
    "icon_wave": (icon_wave, 313, {}), "icon_time": (icon_time, 314, {}), "icon_level": (icon_level, 315, {"blood_spots": 1}),
}


def build(sid: str) -> str:
    fn, seed, extra = MENU[sid]
    U.reset_scene()
    k = U.Kit(1.0)
    extra_mats(k)
    cfg = fn(k)
    cam = U.fit_camera(U.meshes(), az=cfg["az"], el=cfg["el"], lens=cfg["lens"], fill=cfg["fill"], roll=cfg["roll"])
    U.add_lights(cam)
    return U.make(sid, seed=seed, **extra)


def main() -> None:
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    for sid in (args or list(MENU)):
        print("EMBLEM", build(sid), flush=True)
    U.contact_sheet(list(MENU), os.path.join(U.REPO, "build", "shots", "emblems_menu_contact.png"), cols=5, tile=204)


main()
