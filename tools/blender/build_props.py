"""Yıpratılmış prop hattı (8.1e): hazır paket modellerini yıkık gece şehrine uyarlar.

blender --background --python tools/blender/build_props.py -- [ad ...]   (ad yoksa PROPS'un hepsi)
Çıktı: assets/models/world/props/<ad>.glb. Yeni prop = PROPS'a bir satır.
Kaynaklar assets/models/source/ altında (git'e girmez); Kenney Car Kit 3.1 + Taha'nın CC0 indirmeleri.
"""
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import wreck_kit as wk  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
SRC = ROOT + "/assets/models/source/"
CARS = SRC + "kenney_car_kit/Models/GLB format/"
OUT = ROOT + "/assets/models/world/props/"

# ---- TABLO: bir satır = bir prop -------------------------------------------------------------
# kind car: scale=(genişlik, uzunluk, yükseklik) çarpanı, wheel=tekerlek ölçeği, dents=çökme sayısı,
#   flat=inik lastik ('fl','fr','bl','br'), tilt=derece, door_missing='l'|'r'|None, burned=yanmış
# kind prop: scale=tek çarpan
COMMON = dict(sat=0.40, val=0.40, rust=1.0)
PROPS = [
    dict(name="sedan_wreck", kind="car", src=CARS + "sedan.glb", scale=(1.2, 1.76, 1.15), wheel=1.12,
         seed=11, dents=3, flat="fl", tilt=5.0, missing_glass=1, cracked=2, **COMMON),
    dict(name="sedan_burned", kind="car", src=CARS + "sedan.glb", scale=(1.2, 1.76, 1.15), wheel=1.12,
         seed=23, dents=4, flat=None, tilt=0.0, burned=True, **dict(COMMON, sat=0.2, val=0.35)),
    dict(name="van_wreck", kind="car", src=CARS + "van.glb", scale=(1.15, 1.72, 1.15), wheel=1.12,
         seed=37, dents=3, flat="br", tilt=5.0, door_missing="l", missing_glass=0, cracked=1, roof_dark=0.9, **dict(COMMON, val=0.3)),
    dict(name="sedan_wreck_b", kind="car", src=CARS + "sedan.glb", scale=(1.2, 1.76, 1.15), wheel=1.12,
         seed=71, dents=4, flat="bl", tilt=-4.0, door_missing="r", missing_glass=0, cracked=2, **COMMON),
    dict(name="suv_wreck", kind="car", src=CARS + "suv.glb", scale=(1.2, 1.7, 1.12), wheel=1.12,
         seed=83, dents=3, flat="fr", tilt=4.0, missing_glass=1, cracked=1, **COMMON),
    dict(name="taxi_wreck", kind="car", src=CARS + "taxi.glb", scale=(1.2, 1.68, 1.05), wheel=1.12,
         seed=97, dents=4, flat="fl", tilt=5.0, missing_glass=0, cracked=2, **dict(COMMON, sat=0.5, val=0.42)),
    dict(name="police_wreck", kind="car", src=CARS + "police.glb", scale=(1.2, 1.5, 1.12), wheel=1.12,
         seed=101, dents=3, flat="br", tilt=4.0, missing_glass=0, cracked=2, **dict(COMMON, val=0.3)),
    dict(name="delivery_wreck", kind="car", src=CARS + "delivery.glb", scale=(1.15, 1.6, 1.05), wheel=1.12,
         seed=113, dents=3, flat="bl", tilt=-5.0, door_missing="l", missing_glass=1, cracked=0, **COMMON),
    dict(name="suv_burned", kind="car", src=CARS + "suv.glb", scale=(1.2, 1.7, 1.12), wheel=1.12,
         seed=127, dents=4, flat=None, tilt=0.0, burned=True, **dict(COMMON, sat=0.2, val=0.35)),
    dict(name="van_burned", kind="car", src=CARS + "van.glb", scale=(1.15, 1.72, 1.15), wheel=1.12,
         seed=131, dents=4, flat=None, tilt=0.0, burned=True, **dict(COMMON, sat=0.2, val=0.35)),
    dict(name="traffic_light_wreck", kind="prop", src=SRC + "traffic-light.glb", scale=1.0, seed=17, dents=0,
         anchor="base", lean=3.0, **dict(COMMON, sat=0.3, val=0.24)),
    dict(name="traffic_barrier_wreck", kind="prop", src=SRC + "traffic-barier.glb", scale=1.0, seed=19, dents=1,
         **dict(COMMON, sat=0.5, val=0.45)),
    dict(name="paper_debris_a", kind="prop", src=SRC + "debris-paper.glb", scale=1.0, seed=3, dents=0, double=True,
         tint=(1.0, 0.97, 0.9), **dict(COMMON, sat=0.9, val=0.3, rust=0.0)),
    dict(name="paper_debris_b", kind="prop", src=SRC + "debris-paper.glb", scale=0.85, seed=4, dents=0, double=True,
         tint=(0.9, 0.88, 0.78), **dict(COMMON, sat=0.9, val=0.22, rust=0.0)),
    dict(name="paper_debris_c", kind="prop", src=SRC + "debris-paper.glb", scale=1.15, seed=6, dents=0, double=True,
         tint=(0.85, 0.9, 0.95), **dict(COMMON, sat=0.9, val=0.16, rust=0.0)),
    dict(name="trashbin_wreck", kind="prop", src=SRC + "trashbin.glb", scale=0.72, seed=5, dents=1, **COMMON),
    dict(name="barricade_wreck", kind="prop", src=SRC + "barricade.glb", scale=1.0, seed=9, dents=0,
         **dict(COMMON, sat=0.5, val=0.36)),
]

BODY, GLASS, INSIDE = 0, 1, 2


def lum(c) -> float:
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]


def scale_part(part, s) -> None:
    for v in part.bm.verts:
        v.co = Vector((v.co.x * s[0], v.co.y * s[1], v.co.z * s[2]))


def glass_components(part) -> list:
    """Cam yüzleri (açık ve düşük doygunluklu, belin üstünde) bağlı bileşenlere ayrılır."""
    layer = part.bm.loops.layers.float_color["Col"]
    glass = set()
    for f in part.bm.faces:
        c = wk.face_color(f, layer)
        if min(c) > 0.55 and f.calc_center_median().z > 0.45:
            glass.add(f)
    comps, seen = [], set()
    for f in glass:
        if f in seen:
            continue
        stack, comp = [f], []
        seen.add(f)
        while stack:
            cur = stack.pop()
            comp.append(cur)
            for e in cur.edges:
                for nb in e.link_faces:
                    if nb in glass and nb not in seen:
                        seen.add(nb)
                        stack.append(nb)
        comps.append(comp)
    return comps


def build_car(cfg: dict) -> list:
    rng = random.Random(cfg["seed"])
    seed = cfg["seed"]
    parts = wk.import_parts(cfg["src"])
    body = next(p for p in parts if p.name.startswith("body"))
    wheels = [p for p in parts if p.name.startswith("wheel")]
    sx, sy, sz = cfg["scale"]
    ws = cfg["wheel"]
    centers = {}
    for w in wheels:
        c = w.center()
        centers[w.name] = c
    scale_part(body, (sx, sy, sz))
    for w in wheels:
        c = centers[w.name]
        nc = Vector((c.x * sx, c.y * sy, c.z * sz))
        for v in w.bm.verts:
            v.co = nc + (v.co - c) * ws
        centers[w.name] = nc
    # cam bileşenleri (renkler henüz ham)
    comps = sorted(glass_components(body), key=lambda cp: -len(cp))
    glass_faces = {f: i for i, cp in enumerate(comps) for f in cp}
    print("GLASS comps", cfg["name"], [len(cp) for cp in comps])
    gone = set(range(cfg.get("missing_glass", 0)))
    cracked = set(range(cfg.get("missing_glass", 0), cfg.get("missing_glass", 0) + cfg.get("cracked", 0)))
    # çökmeler: konuma bağlı
    lo, hi = body.bounds()
    for i in range(cfg["dents"]):
        side = rng.choice((-1, 1))
        kind = i % 3
        if kind == 0:   # yan çökme
            c = Vector((side * hi.x, rng.uniform(lo.y * 0.55, hi.y * 0.55), rng.uniform(0.45, 0.8) * hi.z))
            wk.dent([body], c, Vector((-side, 0, 0)), 0.6, 0.24)
        elif kind == 1:  # ön/arka tampon-köşe
            ys = rng.choice((-1, 1))
            c = Vector((side * hi.x * 0.7, ys * hi.y * 0.98, rng.uniform(0.4, 0.65) * hi.z))
            wk.dent([body], c, Vector((0, -ys, 0)), 0.65, 0.3)
        else:            # kaput/tavan
            ys = rng.choice((-1, 1))
            c = Vector((rng.uniform(-0.3, 0.3), ys * hi.y * 0.5, hi.z * 0.98))
            wk.dent([body], c, Vector((0, 0, -1)), 0.65, 0.2)
    if cfg.get("burned"):
        wk.dent([body], Vector((0, 0, hi.z)), Vector((0, 0, -1)), 1.0, 0.1)
    # lastik / jant
    flat_name = {"fl": "wheel-front-left", "fr": "wheel-front-right",
                 "bl": "wheel-back-left", "br": "wheel-back-right"}.get(cfg.get("flat"))
    # renk geçişi: hasar yoğunluğu için tekerlek ekseni yakınlığı
    axle = [(c.y, c.z) for c in centers.values()]

    def arch(p: Vector) -> float:
        d = min(math.hypot(p.y - ay, p.z - az) for ay, az in axle)
        return 1.0 - wk.smoothstep(0.45 * ws, 1.0 * ws, d)

    layer_b = body.bm.loops.layers.float_color["Col"]
    # kapı eksik: yan yüzeyde bir bölge (cam değil) iç malzemeye
    door_x = None
    if cfg.get("door_missing"):
        door_x = 1 if cfg["door_missing"] == "l" else -1
    for f in body.bm.faces:
        cen = f.calc_center_median()
        is_glass = f in glass_faces
        f.material_index = BODY
        base = wk.face_color(f, layer_b)
        if is_glass:
            gi = glass_faces[f]
            f.material_index = GLASS
            if cfg.get("burned") or gi in gone or (gi in cracked and rng.random() < 0.55):
                f.material_index = INSIDE
            continue
        for lp in f.loops:
            p = lp.vert.co
            lp[layer_b] = (*wk.weather_corner(lp[layer_b][:3], p, 0.12, 0.55, seed, cfg, arch(p), f.normal.z), 1.0)
        if cfg.get("roof_dark") and f.normal.z > 0.6 and cen.z > hi.z * 0.7:
            for lp in f.loops:
                lp[layer_b] = (*wk.mix(lp[layer_b][:3], wk.DIRT, cfg["roof_dark"]), 1.0)
        if door_x and cen.x * door_x > hi.x * 0.6 and 0.3 < cen.z < hi.z * 0.62 and abs(cen.y - (lo.y + hi.y) * 0.5) < hi.y * 0.28 \
                and f.normal.x * door_x > 0.6:
            f.material_index = INSIDE
    # kırık cam: kalan cam yüzlerin bir kısmı kömür gibi matlaşır (çatlak)
    # tekerlekler
    tire_faces = []
    for w in wheels:
        lay = w.bm.loops.layers.float_color["Col"]
        for f in w.bm.faces:
            c = wk.face_color(f, lay)
            f.material_index = BODY
            is_tire = lum(c) < 0.4
            for lp in f.loops:
                p = lp.vert.co
                cc = lp[lay][:3]
                if is_tire:
                    cc = (0.03, 0.03, 0.032)
                lp[lay] = (*wk.weather_corner(cc, p, 0.0, 0.4, seed + 1, dict(cfg, rust=1.4 if not is_tire else 0.4),
                                               0.6), 1.0)
            if is_tire:
                tire_faces.append((w, f))
    # eğim + inik lastik (yan taraf aşağı)
    if cfg.get("tilt", 0) and flat_name:
        side = 1 if centers[flat_name].x > 0 else -1
        pivot = Vector((-side * abs(centers[flat_name].x), 0, 0))
        rot = Matrix.Rotation(math.radians(cfg["tilt"]) * side, 4, "Y")
        for part in parts:
            for v in part.bm.verts:
                v.co = pivot + rot @ (v.co - pivot)
        w = next(w for w in wheels if w.name == flat_name)
        c = w.center()
        r = (w.bounds()[1].z - w.bounds()[0].z) / 2
        s = max(0.6, c.z / r)
        for v in w.bm.verts:
            v.co.z = c.z + (v.co.z - c.z) * s
    # yanmış: lastik yok, jant yerde (zemine oturma main'de tüm aracı indirir)
    if cfg.get("burned"):
        for w, f in tire_faces:
            if f.is_valid:
                bmesh.ops.delete(w.bm, geom=[f], context="FACES_ONLY")
    return parts


def build_prop(cfg: dict) -> list:
    seed = cfg["seed"]
    parts = wk.import_parts(cfg["src"])
    s = cfg["scale"]
    for part in parts:
        scale_part(part, (s, s, s))
    lo = Vector((min(p.bounds()[0].x for p in parts), min(p.bounds()[0].y for p in parts), min(p.bounds()[0].z for p in parts)))
    hi = Vector((max(p.bounds()[1].x for p in parts), max(p.bounds()[1].y for p in parts), max(p.bounds()[1].z for p in parts)))
    off = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
    if cfg.get("anchor") == "base":   # direğin dibi orijinde
        base = [v.co for p in parts for v in p.bm.verts if v.co.z < lo.z + 0.15]
        off = Vector((sum(b.x for b in base) / len(base), sum(b.y for b in base) / len(base), lo.z))
    rng = random.Random(seed)
    for i in range(cfg["dents"]):
        side = rng.choice((-1, 1))
        wk.dent(parts, Vector((side * hi.x * s, rng.uniform(lo.y, hi.y) * 0.3, (hi.z - lo.z) * 0.4)),
                Vector((-side, 0, 0)), 0.5, 0.1)
    for part in parts:
        for v in part.bm.verts:
            v.co -= off
        if cfg.get("lean"):
            rot = Matrix.Rotation(math.radians(cfg["lean"]), 3, "X")
            for v in part.bm.verts:
                v.co = rot @ v.co
        if cfg.get("double"):   # düz levha: iki yüzlü
            res = bmesh.ops.duplicate(part.bm, geom=list(part.bm.faces))
            bmesh.ops.reverse_faces(part.bm, faces=[g for g in res["geom"] if isinstance(g, bmesh.types.BMFace)])
        lay = part.bm.loops.layers.float_color["Col"]
        for f in part.bm.faces:
            f.material_index = BODY
            for lp in f.loops:
                p = lp.vert.co
                base = lp[lay][:3]
                if cfg.get("tint"):
                    base = tuple(a * b for a, b in zip(base, cfg["tint"]))
                lp[lay] = (*wk.weather_corner(base, p, 0.0, max(0.05, (hi.z - lo.z) * 0.5), seed, cfg, 0.0, f.normal.z), 1.0)
    return parts


def main() -> None:
    names = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    os.makedirs(OUT, exist_ok=True)
    for cfg in PROPS:
        if names and cfg["name"] not in names:
            continue
        wk.reset_scene()
        parts = build_car(cfg) if cfg["kind"] == "car" else build_prop(cfg)
        # zemine otur: en alttaki nokta z=0, ağırlık merkezi XY'de ortalı
        lo = min(p.bounds()[0].z for p in parts)
        for part in parts:
            for v in part.bm.verts:
                v.co.z -= lo
        wk.write_glb(parts, OUT + cfg["name"] + ".glb", {BODY: "wreck_body", GLASS: "wreck_glass", INSIDE: "wreck_inside"})
        los = [min(p.bounds()[0][i] for p in parts) for i in range(3)]
        his = [max(p.bounds()[1][i] for p in parts) for i in range(3)]
        print("PROP", cfg["name"], "tris", wk.count_tris(parts),
              "size_xyz", [round(his[i] - los[i], 2) for i in range(3)], "min", [round(v, 2) for v in los])


main()
