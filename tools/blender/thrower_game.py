"""Taş fırlatan oyun modeli (7.3): build_thrower görünüşünden → zombie_thrower_<çeşit>.glb (+ kaya prop'u).

Hat tank_game.py ile aynı (ortak iş zombie_game.py'de): incelt → köşe rengi → ağırlık → birleştir →
iskelet → GLB. Farklar:
- Kollar asimetrik: kemikler yana özel noktalardan (sağ kol uzun ve dev, sol kısa). Kemik adları standart.
- Kıyafet kabukları gövdenin köşelerine boyanır (yansıtıcı şerit > yelek > kemer > üst > alt), gövde orada
  kumaş kalınlığı kadar kabartılır. Ekose (flannel) aynı desen fonksiyonuyla köşelere boyanır.
- El: lowerarm/hand, ayak parmakları: ball, bot: calf/foot/ball, baret ve göz kapağı: Head.
- İskelet: 25 standart kemik + `jaw`.
Klipler thrower_anims.py (+ thrower_falls.py): her çeşidin kendi iskeletine anahtarlanır, kendi GLB'sine gider.
Kaya: thrower_rock.py → assets/models/props/thrown_rock.glb (aynı çalıştırmada yeniden yazılır).

Çalıştırma (arka plan):  blender --background --python tools/blender/thrower_game.py [-- Vest Flannel Bare]
Çıktı: assets/models/characters/zombie_thrower_<çeşit>.glb, build/blender/thrower_game.blend
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
import walker_game as wg  # noqa: E402
import build_thrower as bt  # noqa: E402
import thrower_head as thh  # noqa: E402
import thrower_clothes as thc  # noqa: E402
import thrower_rock as rock  # noqa: E402
import thrower_anims as anims  # noqa: E402

for _mod in (kit, zg, bt, thh, thc, rock, anims):
    importlib.reload(_mod)

OUT_DIR = os.path.join(REPO, "assets", "models", "characters")
ROCK_OUT = os.path.join(REPO, "assets", "models", "props", "thrown_rock.glb")
OUT_BLEND = os.path.join(REPO, "build", "blender", "thrower_game.blend")
RIG_NAME = "Thrower_Rig"
LINEUP_SPACING = 1.6
BUDGET = {"Thrower_Body": 6000, "Thrower_Head": 1100, "Thrower_Jaw": 260, "Thrower_Hand_R": 1100,
          "Thrower_Hand_L": 320, "Thrower_Toes": 240, "Thrower_Mouth": 90, "Thrower_Tongue": 40,
          "Walker_Shoe": 260, "Thrower_Shoe": 260, "Thrower_Eye": 24, "Thrower_Pupil": 12,
          "Thrower_Lid": 30, "Thrower_Hat": 220}
PAINTED_SHELLS = (("Thrower_Stripe", 0.044), ("Thrower_Vest", 0.034), ("Thrower_Belt", 0.040),
                  ("Thrower_Top", 0.026), ("Thrower_Bottom", 0.026))
CLOTH_LIFT = 0.007
HAIR_REACH = 0.012
SOLE_COLOR = (0.015, 0.014, 0.013)
WEIGHT_SMOOTH = 4
GLB_ANIM = {"export_optimize_animation_keep_anim_armature": False}


def _base(name: str) -> str:
    return name.split(".")[0]


def _kind(name: str) -> str:
    b = _base(name)
    return b[:-2] if b.endswith(("_L", "_R")) and not b.startswith("Thrower_Hand") else b


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
           ("Head", pts["neck1"], hm @ (Vector((0.0, 0.012, 0.14)) * hs), "neck_01"),
           ("jaw", jm.translation.copy(), jm @ (Vector((0.0, -0.088, -0.056)) * hs), "Head")]
    for side, sx in (("l", 1.0), ("r", -1.0)):
        p = {k: pts[f"{k}_{side.upper()}"] for k in ("shoulder", "elbow", "wrist", "tip", "hip", "knee",
                                                     "ankle", "ball", "toe")}
        fwd = (p["toe"] - p["ball"]).normalized()
        out += [(f"clavicle_{side}", pts["upchest"] + Vector((0.05 * sx, 0.0, 0.0)) * s, p["shoulder"], "spine_03"),
                (f"upperarm_{side}", p["shoulder"], p["elbow"], f"clavicle_{side}"),
                (f"lowerarm_{side}", p["elbow"], p["wrist"], f"upperarm_{side}"),
                (f"hand_{side}", p["wrist"], p["tip"], f"lowerarm_{side}"),
                (f"thigh_{side}", p["hip"], p["knee"], "pelvis"),
                (f"calf_{side}", p["knee"], p["ankle"], f"thigh_{side}"),
                (f"foot_{side}", p["ankle"], p["ball"], f"calf_{side}"),
                (f"ball_{side}", p["ball"], p["toe"] + fwd * 0.06 * s, f"foot_{side}"),
                (f"ball_leaf_{side}", p["toe"] + fwd * 0.06 * s, p["toe"] + fwd * 0.10 * s, f"ball_{side}")]
    return out


def body_segments(bone_list) -> dict:
    skip = ("root", "jaw", "ball_leaf_l", "ball_leaf_r")
    return {name: [(h, t)] for name, h, t, _ in bone_list if name not in skip}


def weight_multi(obj, segments: dict, keep: int = 3, power: float = 4.0) -> None:
    groups = {n: obj.vertex_groups.get(n) or obj.vertex_groups.new(name=n) for n in segments}
    mw = obj.matrix_world
    for v in obj.data.vertices:
        p = mw @ v.co
        scored = sorted(((1.0 / max(min(wg._seg_dist(p, a, b) for a, b in segs), 0.004) ** power, n)
                         for n, segs in segments.items()), reverse=True)[:keep]
        total = sum(w for w, _ in scored)
        for w, n in scored:
            groups[n].add([v.index], w / total, "REPLACE")


# ---------------------------------------------------------------- renk

def plaid_color(v):
    base = zg.cloth_color(thc.PLAID_A, stain=(0.06, 0.03, 0.02), blood=v["blood"])

    def fn(p):
        c = base(p)
        return tuple(x * 0.14 for x in c) if thc.plaid_dark(p) else c
    return fn


def shell_color(kind, v):
    if kind == "Thrower_Stripe":
        return zg.cloth_color(thc.STRIPE, stain=(0.25, 0.22, 0.18))
    if kind == "Thrower_Vest":
        return zg.cloth_color(v["vest"], stain=(0.12, 0.06, 0.02), blood=0.3)
    if kind == "Thrower_Belt":
        return zg.flat_color(v.get("belt") or (0.02, 0.02, 0.02))
    if kind == "Thrower_Bottom":
        return zg.cloth_color(v["bottom_color"], stain=(0.06, 0.05, 0.03))
    if v["top"] == "flannel":
        return plaid_color(v)
    return zg.cloth_color(v["top_color"], blood=v["blood"])


def mouth_color(head, s):
    inv = head.matrix_world.inverted()
    y0, y1 = (thh.MOUTH_CENTER.y - thh.MOUTH_RADII.y * 0.3) * s, (thh.MOUTH_CENTER.y + thh.MOUTH_RADII.y) * s

    def fn(p):
        t = min(max(((inv @ p).y - y0) / (y1 - y0) / 0.8, 0.0), 1.0)
        return zg._mix(thh.MOUTH_FRONT, thh.MOUTH_BACK, t)
    return fn


def lift_cloth(body, shells) -> None:
    mw = body.matrix_world
    for vert in body.data.vertices:
        if any(tree.find_nearest(mw @ vert.co, reach)[0] is not None for tree, reach, _fn in shells):
            vert.co += vert.normal * CLOTH_LIFT


# ---------------------------------------------------------------- parça hazırlığı

def prepare_body(obj, ctx) -> None:
    zg.decimate(obj, BUDGET["Thrower_Body"])
    lift_cloth(obj, ctx["shells"])
    zg.paint(obj, zg.layered_color(ctx["shells"], ctx["skin"]))
    weight_multi(obj, ctx["segments"])
    zg.smooth_weights(obj, WEIGHT_SMOOTH)


def prepare_part(obj, v, ctx) -> None:
    kind, base = _kind(obj.name), _base(obj.name)
    side = base[-1].lower() if base.endswith(("_L", "_R")) else ""
    if kind in BUDGET:
        zg.decimate(obj, BUDGET[kind])
    seg, skin = ctx["segments"], ctx["skin"]
    if kind.startswith("Thrower_Hand"):
        zg.paint(obj, skin)
        weight_multi(obj, {k: seg[k] for k in (f"lowerarm_{side}", f"hand_{side}")}, keep=2)
    elif kind == "Thrower_Toes":
        zg.paint(obj, skin)
        zg.weight_to(obj, f"ball_{side}")
    elif kind in ("Thrower_Shoe", "Walker_Shoe"):
        shoe = zg.cloth_color(v["shoes"], stain=(0.04, 0.03, 0.02))
        zg.paint_slots(obj, [shoe, zg.flat_color(SOLE_COLOR)], dirt=0.3)
        weight_multi(obj, {k: seg[k] for k in (f"calf_{side}", f"foot_{side}", f"ball_{side}")})
    elif kind == "Thrower_Head":
        tree = ctx["hair_tree"]
        regions = [(tree, HAIR_REACH, wg.hair_color(v["hair"]))] if tree else []
        zg.paint(obj, zg.layered_color(regions, skin))
        if tree:
            wg.lift_scalp(obj, tree, wg.HAIR_LIFT * v["body"]["head"])
        zg.weight_to(obj, "Head")
    elif kind in ("Thrower_Jaw", "Thrower_Tongue", "Thrower_ToothL"):
        color = {"Thrower_Jaw": skin, "Thrower_Tongue": zg.flat_color(thh.TONGUE_COLOR),
                 "Thrower_ToothL": zg.flat_color(thh.TOOTH_COLOR)}[kind]
        zg.paint(obj, color, dirt=0.4 if kind == "Thrower_Jaw" else 0.0)
        zg.weight_to(obj, "jaw")
    else:   # ağız içi, göz, bebek, kapak, baret, üst diş: kafaya bağlı
        color = {"Thrower_Mouth": ctx["mouth"], "Thrower_Eye": zg.flat_color(thh.EYE_COLOR),
                 "Thrower_Pupil": zg.flat_color(thh.PUPIL_COLOR), "Thrower_Lid": skin,
                 "Thrower_Hat": zg.cloth_color(thh.HAT_COLOR, stain=(0.10, 0.07, 0.03))}.get(
            kind, zg.flat_color(thh.TOOTH_COLOR))
        zg.paint(obj, color, dirt=0.3 if kind in ("Thrower_Hat", "Thrower_Lid") else 0.0)
        zg.weight_to(obj, "Head")


def _detach(root):
    bpy.context.view_layer.update()
    objs = [o for o in root.children_recursive if o.type == "MESH"]
    for o in list(root.children):
        mw = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = mw
    bpy.data.objects.remove(root)
    bpy.context.view_layer.update()
    return sorted(objs, key=lambda o: o.name)


def build_variant_game(v, mat):
    objs = _detach(bt.build_variant(v, 0.0, "neutral"))
    find = {_base(o.name): o for o in objs}
    head, jaw = find["Thrower_Head"], find["Thrower_Jaw"]
    hs = v["body"]["head"]
    bone_list = bones(v, head, jaw)
    shells = []
    order = [k for k, _r in PAINTED_SHELLS]
    for shell in [o for o in objs if _kind(o.name) in dict(PAINTED_SHELLS)]:
        kind = _kind(shell.name)
        shells.append((zg.world_bvh(shell), dict(PAINTED_SHELLS)[kind], shell_color(kind, v), order.index(kind)))
        objs.remove(shell)
        bpy.data.objects.remove(shell)
    shells = [(t, r, c) for t, r, c, _i in sorted(shells, key=lambda x: x[3])]
    hair = next((o for o in objs if _kind(o.name) == "Thrower_Hair"), None)
    hair_tree = None
    if hair is not None:
        hair_tree = zg.world_bvh(hair)
        objs.remove(hair)
        bpy.data.objects.remove(hair)
    mouth_at = head.matrix_world @ (Vector((0.0, -0.09, -0.02)) * hs)
    body = find["Thrower_Body"]
    ctx = {"segments": body_segments(bone_list), "shells": shells, "hair_tree": hair_tree,
           "skin": wg.skin_color(v, mouth_at), "mouth": mouth_color(head, hs)}
    prepare_body(body, ctx)
    for obj in objs:
        if obj is not body:
            prepare_part(obj, v, ctx)
    mesh = zg.join([body] + [o for o in objs if o is not body], "Thrower_" + v["name"])
    mesh.data.validate(clean_customdata=False)
    mesh.data.materials.clear()
    mesh.data.materials.append(mat)
    arm = zg.build_armature(RIG_NAME, bone_list)
    zg.bind(mesh, arm)
    return arm, mesh


# ---------------------------------------------------------------- kurulum

def out_path(v) -> str:
    return os.path.join(OUT_DIR, "zombie_thrower_%s.glb" % v["name"].lower())


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
        print("THROWER GAME", v["name"], "tris", report[v["name"]][0], "bones", report[v["name"]][1],
              "height", report[v["name"]][2])
        arm.name = "%s_%s" % (RIG_NAME, v["name"])
        arm.data.name = arm.name
        arm.location.x = (i - (len(variants) - 1) / 2) * LINEUP_SPACING
    for variant, arm, _mesh in rigs:      # inceleme kopyası: klipler çeşit ekiyle .blend'de
        for name in anims.build_all(arm):
            bpy.data.actions[name].name = "%s_%s" % (name, variant)
        arm.animation_data.action = None
    rock.export(ROCK_OUT)
    kit.setup_look()
    os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    print("THROWER GAME exported:", report)
    return report


if __name__ != "thrower_game":
    _argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    build_game([a for a in _argv if not a.startswith("-")] or None)
