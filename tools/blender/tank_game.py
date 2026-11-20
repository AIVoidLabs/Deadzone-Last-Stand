"""Tank oyun modeli (Aşama V.5): build_tank v2 görünüşünden → zombie_tank_<çeşit>.glb.

Hat walker_game.py ile aynı (ortak iş zombie_game.py'de): incelt → köşe rengi → ağırlık → birleştir →
iskelet → GLB. Farklar:
- Kök (Tank_<çeşit>) ölçekli; parçalar dünya dönüşümü korunarak kökten ayrılır, kemikler ölçekli noktalardan.
- Kıyafet kabukları gövdenin köşelerine boyanır ve gövde orada kumaş kalınlığı kadar kabartılır (kenar okunur).
- Kambur: gövde ağırlığı kemik başına birden çok parçayla (spine_02/03 kamburu da taşır), kol kalkınca
  kambur kopmaz. Kemik plakalar katı: tabanının altındaki gövde köşesinin ağırlığını aynen alır.
- Yumruk: lowerarm/hand, ayak parmakları: ball, ayakkabı: calf/foot/ball.
- İskelet: 25 standart kemik + `jaw`. Eski zombie_tank.glb'ye dokunulmaz (oyunda kullanılıyor).
Klipler tank_anims.py (+ tank_falls.py): her çeşidin kendi iskeletine anahtarlanır, kendi GLB'sine gider.

Çalıştırma (arka plan):  blender --background --python tools/blender/tank_game.py [-- Overall Guard ...]
Çıktı: assets/models/characters/zombie_tank_<çeşit>.glb, build/blender/tank_game.blend
"""
import importlib
import os
import sys

import bpy
from mathutils import Vector, kdtree

_HERE = globals().get("__file__", "")
REPO = os.path.abspath(os.path.join(os.path.dirname(_HERE), "..", "..")) if _HERE else ""
if not REPO or not os.path.isdir(os.path.join(REPO, "tools")):
    REPO = r"C:\Users\pekta\projeler\Deadzone-Last-Stand"
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import zombie_kit as kit  # noqa: E402
import zombie_game as zg  # noqa: E402
import walker_head as wh  # noqa: E402
import walker_game as wg  # noqa: E402
import build_tank as bt  # noqa: E402
import tank_head as th  # noqa: E402
import tank_plates as tpl  # noqa: E402
import tank_anims as anims  # noqa: E402

for _mod in (kit, zg, bt, th, tpl, anims):
    importlib.reload(_mod)

OUT_DIR = os.path.join(REPO, "assets", "models", "characters")
OUT_BLEND = os.path.join(REPO, "build", "blender", "tank_game.blend")
RIG_NAME = "Tank_Rig"
LINEUP_SPACING = 1.8
BUDGET = {"Tank_Body": 6600, "Tank_Head": 1300, "Tank_Jaw": 300, "Tank_Fist": 620, "Tank_Toes": 260,
          "Tank_Plate": 190, "Tank_Mouth": 90, "Tank_Tongue": 40, "Tank_Shoe": 240, "Tank_Eye": 24,
          "Tank_Pupil": 12, "Tank_Button": 20, "Tank_Badge": 20, "Tank_Buckle": 20}
# Gövdeye boyanan kabuklar: ad -> erişim (m). Sıra = öncelik.
PAINTED_SHELLS = (("Tank_Pocket", 0.040), ("Tank_Collar", 0.045), ("Tank_Belt", 0.050), ("Tank_Top", 0.030),
                  ("Tank_Bottom", 0.028))
CLOTH_LIFT = 0.008        # kumaş bölgesinde gövde kabartması (m): kenar basamağı okunur
HAIR_REACH = 0.012
PUPIL_COLOR = (0.02, 0.018, 0.015)
SOLE_COLOR = (0.015, 0.014, 0.013)
WEIGHT_SMOOTH = 4
GLB_ANIM = {"export_optimize_animation_keep_anim_armature": False}


def _base(name: str) -> str:
    return name.split(".")[0]


def _kind(name: str) -> str:
    b = _base(name)
    return b[:-2] if b.endswith(("_L", "_R")) else b


# ---------------------------------------------------------------- iskelet

def bones(v, head, jaw) -> list:
    """[(ad, baş, uç, ebeveyn)] — nötr konsept pozunda dinlenme, çeşit ölçeğiyle."""
    s, hs = v["body"]["s"], v["body"]["head"]
    pts = {n: p * s for n, (p, _r) in bt.body_points(v["body"]).items()}
    hm, jm = head.matrix_world, jaw.matrix_world
    out = [("root", Vector((0, 0, 0)), Vector((0, 0, 0.25)), None),
           ("pelvis", pts["pelvis"], pts["spine"], "root"),
           ("spine_01", pts["spine"], pts["chest"], "pelvis"),
           ("spine_02", pts["chest"], pts["upchest"], "spine_01"),
           ("spine_03", pts["upchest"], pts["neck0"], "spine_02"),
           ("neck_01", pts["neck0"], pts["neck1"], "spine_03"),
           ("Head", pts["neck1"], hm @ (Vector((0.0, 0.016, 0.13)) * hs), "neck_01"),
           ("jaw", jm.translation.copy(), jm @ (Vector((0.0, -0.084, -0.058)) * hs), "Head")]
    for side, sx in (("l", 1.0), ("r", -1.0)):
        p = {k: pts[f"{k}_{side.upper()}"] for k in ("shoulder", "elbow", "wrist", "fist", "hip", "knee",
                                                     "ankle", "ball", "toe")}
        finger = p["fist"] + (p["fist"] - p["wrist"]).normalized() * 0.06
        fwd = (p["toe"] - p["ball"]).normalized()
        out += [(f"clavicle_{side}", pts["upchest"] + Vector((0.05 * sx, 0.0, 0.0)) * s, p["shoulder"], "spine_03"),
                (f"upperarm_{side}", p["shoulder"], p["elbow"], f"clavicle_{side}"),
                (f"lowerarm_{side}", p["elbow"], p["wrist"], f"upperarm_{side}"),
                (f"hand_{side}", p["wrist"], finger, f"lowerarm_{side}"),
                (f"thigh_{side}", p["hip"], p["knee"], "pelvis"),
                (f"calf_{side}", p["knee"], p["ankle"], f"thigh_{side}"),
                (f"foot_{side}", p["ankle"], p["ball"], f"calf_{side}"),
                (f"ball_{side}", p["ball"], p["toe"] + fwd * 0.06 * s, f"foot_{side}"),
                (f"ball_leaf_{side}", p["toe"] + fwd * 0.06 * s, p["toe"] + fwd * 0.10 * s, f"ball_{side}")]
    return out


def body_segments(v, bone_list) -> dict:
    """Kemik -> [parça]; kambur spine_02/03'e, kalça-kasık pelvis'e ek parçalar."""
    seg = {name: [(h, t)] for name, h, t, _ in bone_list if name not in ("root", "jaw", "ball_leaf_l", "ball_leaf_r")}
    s = v["body"]["s"]
    pts = {n: p * s for n, (p, _r) in bt.body_points(v["body"]).items()}
    mid = pts["chest"].lerp(pts["hump"], 0.5)
    seg["spine_02"].append((pts["chest"], mid))
    seg["spine_03"].append((mid, pts["hump"]))
    seg["spine_03"].append((pts["hump"], pts["neck0"]))
    return seg


def weight_multi(obj, segments: dict, keep: int = 3, power: float = 4.0) -> None:
    """zg.weight_by_distance gibi; kemik başına en yakın parçası sayılır."""
    groups = {n: obj.vertex_groups.get(n) or obj.vertex_groups.new(name=n) for n in segments}
    mw = obj.matrix_world
    for v in obj.data.vertices:
        p = mw @ v.co
        scored = sorted(((1.0 / max(min(wg._seg_dist(p, a, b) for a, b in segs), 0.004) ** power, n)
                         for n, segs in segments.items()), reverse=True)[:keep]
        total = sum(w for w, _ in scored)
        for w, n in scored:
            groups[n].add([v.index], w / total, "REPLACE")


def _subset(segments, prefixes) -> dict:
    return {k: segs for k, segs in segments.items() if k.startswith(prefixes)}


# ---------------------------------------------------------------- renk

def bone_color(obj, size):
    """Plaka köşe rengi: plaka yereli x (tabandan uzaklık) ile kök kanı, lekeler, açık kenar payı."""
    inv = obj.matrix_world.inverted()

    def fn(p):
        x = (inv @ p).x
        c = zg._mix(tpl.BONE, tpl.BONE_STAIN, zg._smooth(0.52, 0.86, zg.fbm(p, 5.0)))
        c = zg._mix(c, tpl.BONE_EDGE, 0.35 * zg._smooth(0.45, 0.9, x / max(size, 1e-3)))
        return zg._mix(c, tpl.BONE_ROOT, 1.0 - zg._smooth(0.0, 0.07, x))
    return fn


def skin_color(v, mouth, roots):
    """Ten + ağızdan sızan kan + plaka tabanında çiğ et."""
    base = wg.skin_color(v, mouth)

    def fn(p):
        c = base(p)
        w = 0.0
        for loc, r in roots:
            d = (p - loc).length
            if d < r + tpl.SWELL_REACH:
                w = max(w, 1.0 - max(d - r * 0.6, 0.0) / (r * 0.4 + tpl.SWELL_REACH))
        return zg._mix(c, tpl.RAW, w * w) if w > 0.0 else c
    return fn


def mouth_color(head, s):
    inv = head.matrix_world.inverted()
    y0, y1 = (th.MOUTH_CENTER.y - th.MOUTH_RADII.y * 0.3) * s, (th.MOUTH_CENTER.y + th.MOUTH_RADII.y) * s

    def fn(p):
        t = min(max(((inv @ p).y - y0) / (y1 - y0) / 0.8, 0.0), 1.0)
        return zg._mix(th.MOUTH_FRONT, th.MOUTH_BACK, t)
    return fn


def lift_cloth(body, shells) -> None:
    mw = body.matrix_world
    for vert in body.data.vertices:
        p = mw @ vert.co
        if any(tree.find_nearest(p, reach)[0] is not None for tree, reach, _fn in shells):
            vert.co += vert.normal * CLOTH_LIFT


# ---------------------------------------------------------------- parça hazırlığı

def prepare_body(obj, v, ctx) -> None:
    zg.decimate(obj, BUDGET["Tank_Body"])
    lift_cloth(obj, ctx["shells"])
    zg.paint(obj, zg.layered_color(ctx["shells"], ctx["skin"]))
    weight_multi(obj, ctx["segments"])
    zg.smooth_weights(obj, WEIGHT_SMOOTH)


def copy_weights(obj, body, tree, at) -> None:
    """Katı parça: `at` noktasına en yakın gövde köşesinin ağırlıkları tüm köşelere."""
    _co, idx, _d = tree.find(at)
    for ge in body.data.vertices[idx].groups:
        name = body.vertex_groups[ge.group].name
        g = obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name)
        g.add(range(len(obj.data.vertices)), ge.weight, "REPLACE")


def prepare_part(obj, v, ctx) -> None:
    kind, base = _kind(obj.name), _base(obj.name)
    side = base[-1].lower() if base.endswith(("_L", "_R")) else ""
    if kind in BUDGET:
        size = obj.dimensions.x
        zg.decimate(obj, BUDGET[kind])
    seg, skin = ctx["segments"], ctx["skin"]
    if kind == "Tank_Plate":
        zg.paint(obj, bone_color(obj, size), dirt=0.5)
        copy_weights(obj, ctx["body"], ctx["tree"], obj.matrix_world.translation)
    elif kind == "Tank_Fist":
        zg.paint(obj, skin)
        weight_multi(obj, {k: seg[k] for k in (f"lowerarm_{side}", f"hand_{side}")}, keep=2)
    elif kind == "Tank_Toes":
        zg.paint(obj, skin)
        zg.weight_to(obj, f"ball_{side}")
    elif kind == "Tank_Shoe":
        shoe = zg.cloth_color(v["shoes"], stain=(0.04, 0.03, 0.02))
        zg.paint_slots(obj, [shoe, zg.flat_color(SOLE_COLOR)], dirt=0.3)
        weight_multi(obj, {k: seg[k] for k in (f"calf_{side}", f"foot_{side}", f"ball_{side}")})
    elif kind in ("Tank_Button", "Tank_Badge", "Tank_Buckle"):
        color = {"Tank_Badge": (0.45, 0.33, 0.08), "Tank_Buckle": (0.35, 0.30, 0.20)}.get(kind, (0.03, 0.03, 0.03))
        zg.paint(obj, zg.flat_color(color), dirt=0.0)
        copy_weights(obj, ctx["body"], ctx["tree"], obj.matrix_world.translation)
    elif kind == "Tank_Head":
        tree = ctx["hair_tree"]
        regions = [(tree, HAIR_REACH, wg.hair_color(v["hair"]))] if tree else []
        zg.paint(obj, zg.layered_color(regions, skin))
        if tree:
            wg.lift_scalp(obj, tree, wg.HAIR_LIFT * v["body"]["head"])
        zg.weight_to(obj, "Head")
    elif kind in ("Tank_Jaw", "Tank_Tongue", "Tank_ToothL"):
        color = {"Tank_Jaw": skin, "Tank_Tongue": zg.flat_color(th.TONGUE_COLOR),
                 "Tank_ToothL": zg.flat_color(th.TOOTH_COLOR)}[kind]
        zg.paint(obj, color, dirt=0.4 if kind == "Tank_Jaw" else 0.0)
        zg.weight_to(obj, "jaw")
    else:   # ağız içi, göz, bebek, üst diş: kafaya bağlı
        color = {"Tank_Mouth": ctx["mouth"], "Tank_Eye": zg.flat_color(th.EYE_COLOR),
                 "Tank_Pupil": zg.flat_color(PUPIL_COLOR)}.get(kind, zg.flat_color(th.TOOTH_COLOR))
        zg.paint(obj, color, dirt=0.0)
        zg.weight_to(obj, "Head")


def _detach(root):
    """Ölçekli kökten ayırır, dünya dönüşümünü korur. Döner: ağ nesneleri (ad sıralı)."""
    bpy.context.view_layer.update()
    objs = [o for o in root.children_recursive if o.type == "MESH"]
    for o in [c for c in root.children]:
        mw = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = mw
    bpy.data.objects.remove(root)
    bpy.context.view_layer.update()
    return sorted(objs, key=lambda o: o.name)


def build_variant_game(v, mat):
    objs = _detach(bt.build_variant(v, 0.0, "neutral"))
    find = {_base(o.name): o for o in objs}
    head, jaw = find["Tank_Head"], find["Tank_Jaw"]
    hs = v["body"]["head"]
    bone_list = bones(v, head, jaw)
    shells = []
    for shell in [o for o in objs if _kind(o.name) in dict(PAINTED_SHELLS)]:
        reach = dict(PAINTED_SHELLS)[_kind(shell.name)]
        color = {"Tank_Bottom": zg.cloth_color(v["bottom_color"], stain=(0.05, 0.04, 0.03)),
                 "Tank_Belt": zg.flat_color(v.get("belt") or (0.02, 0.02, 0.02))}.get(
            _kind(shell.name), zg.cloth_color(v["top_color"] or (0, 0, 0), blood=v["blood"]))
        shells.append((zg.world_bvh(shell), reach, color, PAINTED_SHELLS.index((_kind(shell.name), reach))))
        objs.remove(shell)
        bpy.data.objects.remove(shell)
    shells = [(t, r, c) for t, r, c, _i in sorted(shells, key=lambda x: x[3])]
    hair = next((o for o in objs if _kind(o.name) == "Tank_Hair"), None)
    hair_tree = None
    if hair is not None:          # konsept saçı yalnız bölge olarak kalır
        hair_tree = zg.world_bvh(hair)
        objs.remove(hair)
        bpy.data.objects.remove(hair)
    plates = [o for o in objs if _kind(o.name) == "Tank_Plate"]
    roots = [(p.matrix_world.translation.copy(), p.dimensions.y * 0.55) for p in plates]
    mouth_at = head.matrix_world @ (Vector((0.0, -0.09, -0.02)) * hs)
    body = find["Tank_Body"]
    ctx = {"segments": body_segments(v, bone_list), "shells": shells, "hair_tree": hair_tree,
           "skin": skin_color(v, mouth_at, roots), "mouth": mouth_color(head, hs), "body": body}
    prepare_body(body, v, ctx)
    tree = kdtree.KDTree(len(body.data.vertices))
    for vert in body.data.vertices:
        tree.insert(body.matrix_world @ vert.co, vert.index)
    tree.balance()
    ctx["tree"] = tree
    for obj in objs:
        if obj is not body:
            prepare_part(obj, v, ctx)
    mesh = zg.join([body] + [o for o in objs if o is not body], "Tank_" + v["name"])
    mesh.data.validate(clean_customdata=False)
    mesh.data.materials.clear()
    mesh.data.materials.append(mat)
    arm = zg.build_armature(RIG_NAME, bone_list)
    zg.bind(mesh, arm)
    return arm, mesh


# ---------------------------------------------------------------- kurulum

def out_path(v) -> str:
    return os.path.join(OUT_DIR, "zombie_tank_%s.glb" % v["name"].lower())


def build_game(names=None) -> dict:
    kit.reset_scene()
    mat = zg.vertex_color_material("M_Zombie_VC", glow_strength=0.0)
    variants = [v for v in bt.VARIANTS if not names or v["name"] in names]
    report, rigs = {}, []
    for i, v in enumerate(variants):
        arm, mesh = build_variant_game(v, mat)
        clips = anims.build_all(arm)
        zg.export_glb(out_path(v), [arm, mesh], **GLB_ANIM)
        for name in clips:
            bpy.data.actions.remove(bpy.data.actions[name])
        rigs.append((v["name"], arm, mesh))
        report[v["name"]] = (zg.tri_count(mesh), len(arm.data.bones), round(anims.mesh_height(arm), 3))
        print("TANK GAME", v["name"], "tris", report[v["name"]][0], "bones", report[v["name"]][1],
              "height", report[v["name"]][2])
        arm.name = "%s_%s" % (RIG_NAME, v["name"])
        arm.data.name = arm.name
        arm.location.x = (i - (len(variants) - 1) / 2) * LINEUP_SPACING
    for variant, arm, _mesh in rigs:      # inceleme kopyası: klipler çeşit ekiyle .blend'de
        for name in anims.build_all(arm):
            bpy.data.actions[name].name = "%s_%s" % (name, variant)
        arm.animation_data.action = None
    kit.setup_look()
    os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    print("TANK GAME exported:", report)
    return report


if __name__ != "tank_game":
    _argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    build_game([a for a in _argv if not a.startswith("-")] or None)
