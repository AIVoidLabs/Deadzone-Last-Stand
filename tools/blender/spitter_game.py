"""Tükürücü oyun modeli (7.3): build_spitter görünüşünden → zombie_spitter_<çeşit>.glb.

Hat bloater_game.py ile aynı (ortak iş zombie_game.py'de): incelt → köşe rengi → ağırlık → birleştir →
iskelet → GLB. Farklar:
- Parıltı maskesi köşe başına: kabarcıklar ve salya alfa ~0 (tam parıltı), asit lekesi kısmen, gırtlak kesesi
  derisi hafif (spitter_paint). Gözler hafif parlar.
- GLB COLOR_0 alfası: dışa aktarım `export_vertex_color="ACTIVE"` ile (spitter_check COLOR_0 tipini doğrular,
  VEC4 beklenir).
- Kese yüzeyi neck_01'e çekilir (spit klibinde neck_01 ölçeği keseyi şişirir; Head 1/k ile geri alınır).
- Karın elipsoidi yalnız gövde kemiklerine ağırlıklı (önünden sarkan kollar karnı sürüklemesin).
- Kabarcıklar katı (altındaki gövde köşesinin ağırlığı), eller lowerarm/hand, salya çeneye.
- İskelet: 25 standart kemik + `jaw`.

Çalıştırma (arka plan):  blender --background --python tools/blender/spitter_game.py [-- Worker Suit Bare]
Çıktı: assets/models/characters/zombie_spitter_<çeşit>.glb, build/blender/spitter_game.blend
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
import build_spitter as bs  # noqa: E402
import spitter_head as sh  # noqa: E402
import spitter_anims as anims  # noqa: E402
import spitter_paint as paint  # noqa: E402

for _mod in (kit, zg, bs, sh, anims, paint):
    importlib.reload(_mod)

OUT_DIR = os.path.join(REPO, "assets", "models", "characters")
OUT_BLEND = os.path.join(REPO, "build", "blender", "spitter_game.blend")
RIG_NAME = "Spitter_Rig"
LINEUP_SPACING = 1.4
BUDGET = {"Spitter_Body": 5000, "Spitter_Head": 1000, "Spitter_Jaw": 240, "Spitter_Hand": 280,
          "Spitter_Toes": 200, "Spitter_Bubble": 28, "Spitter_Mouth": 90, "Spitter_Tongue": 40,
          "Spitter_Shoe": 220, "Spitter_Eye": 24, "Spitter_Pupil": 12, "Spitter_Drool": 40}
PAINTED_SHELLS = (("Spitter_Belt", 0.040), ("Spitter_Top", 0.026), ("Spitter_Bottom", 0.026))
CLOTH_LIFT = 0.007
HAIR_REACH = 0.012
SOLE_COLOR = (0.015, 0.014, 0.013)
WEIGHT_SMOOTH = 4
TORSO_BONES = ("pelvis", "spine_01", "spine_02")
GLB_EXTRA = {"export_optimize_animation_keep_anim_armature": False, "export_vertex_color": "ACTIVE"}


def _base(name):
    return name.split(".")[0]


def _kind(name):
    b = _base(name)
    return b[:-2] if b.endswith(("_L", "_R")) else b


# ---------------------------------------------------------------- iskelet

def bones(v, head, jaw):
    s, hs = v["body"]["s"], v["body"]["head"]
    pts = {n: p * s for n, (p, _r) in bs.body_points(v["body"]).items()}
    hm, jm = head.matrix_world, jaw.matrix_world
    out = [("root", Vector((0, 0, 0)), Vector((0, 0, 0.25)), None),
           ("pelvis", pts["pelvis"], pts["spine"], "root"),
           ("spine_01", pts["spine"], pts["chest"], "pelvis"),
           ("spine_02", pts["chest"], pts["upchest"], "spine_01"),
           ("spine_03", pts["upchest"], pts["neck0"], "spine_02"),
           ("neck_01", pts["neck0"], pts["neck1"], "spine_03"),
           ("Head", pts["neck1"], hm @ (Vector((0.0, 0.010, 0.13)) * hs), "neck_01"),
           ("jaw", jm.translation.copy(), jm @ (Vector((0.0, -0.074, -0.054)) * hs), "Head")]
    for side, sx in (("l", 1.0), ("r", -1.0)):
        p = {k: pts[f"{k}_{side.upper()}"] for k in ("shoulder", "elbow", "wrist", "fist", "hip", "knee",
                                                     "ankle", "ball", "toe")}
        fwd = (p["toe"] - p["ball"]).normalized()
        out += [(f"clavicle_{side}", pts["upchest"] + Vector((0.05 * sx, 0.0, 0.0)) * s, p["shoulder"], "spine_03"),
                (f"upperarm_{side}", p["shoulder"], p["elbow"], f"clavicle_{side}"),
                (f"lowerarm_{side}", p["elbow"], p["wrist"], f"upperarm_{side}"),
                (f"hand_{side}", p["wrist"], p["fist"], f"lowerarm_{side}"),
                (f"thigh_{side}", p["hip"], p["knee"], "pelvis"),
                (f"calf_{side}", p["knee"], p["ankle"], f"thigh_{side}"),
                (f"foot_{side}", p["ankle"], p["ball"], f"calf_{side}"),
                (f"ball_{side}", p["ball"], p["toe"] + fwd * 0.05 * s, f"foot_{side}"),
                (f"ball_leaf_{side}", p["toe"] + fwd * 0.05 * s, p["toe"] + fwd * 0.09 * s, f"ball_{side}")]
    return out


def body_segments(v, bone_list):
    seg = {name: [(h, t)] for name, h, t, _ in bone_list if name not in ("root", "jaw", "ball_leaf_l", "ball_leaf_r")}
    s = v["body"]["s"]
    pts = {n: p * s for n, (p, _r) in bs.body_points(v["body"]).items()}
    seg["pelvis"] = [(pts["hip_L"], pts["hip_R"])]
    return seg


# ---------------------------------------------------------------- parça hazırlığı

def _scaled(ell, s):
    return ell[0] * s, ell[1] * s


def prepare_body(obj, v, ctx):
    zg.decimate(obj, BUDGET["Spitter_Body"])
    _lift(obj, ctx["shells"])
    paint.paint(obj, paint.body_color(ctx["shells"], ctx["skin"]))
    paint.weight_multi(obj, ctx["segments"])
    gut_c, gut_r = ctx["gut"]
    paint.reweight_region(obj, {k: ctx["segments"][k] for k in TORSO_BONES},
                          lambda p: bs.in_ellipsoid(p, gut_c, gut_r, 1.12))
    paint.throat_bias(obj, ctx["sac"])
    zg.smooth_weights(obj, WEIGHT_SMOOTH)


def _lift(body, shells):
    mw = body.matrix_world
    for vert in body.data.vertices:
        if any(tree.find_nearest(mw @ vert.co, reach)[0] is not None for tree, reach, _fn in shells):
            vert.co += vert.normal * CLOTH_LIFT


def prepare_part(obj, v, ctx):
    kind, base = _kind(obj.name), _base(obj.name)
    side = base[-1].lower() if base.endswith(("_L", "_R")) else ""
    if kind in BUDGET:
        zg.decimate(obj, BUDGET[kind])
    seg, skin = ctx["segments"], ctx["skin"]
    if kind == "Spitter_Bubble":
        paint.paint(obj, paint.bubble_color(obj), dirt=0.0)
        paint.copy_weights(obj, ctx["body"], ctx["tree"], obj.matrix_world.translation)
    elif kind == "Spitter_Drool":
        paint.paint(obj, lambda p: (*paint.BUBBLE_RIM, 0.85), dirt=0.0)
        zg.weight_to(obj, "jaw")
    elif kind == "Spitter_Hand":
        paint.paint(obj, paint.opaque(skin))
        paint.weight_multi(obj, {k: seg[k] for k in (f"lowerarm_{side}", f"hand_{side}")}, keep=2)
    elif kind == "Spitter_Toes":
        paint.paint(obj, paint.opaque(skin))
        zg.weight_to(obj, f"ball_{side}")
    elif kind == "Spitter_Shoe":
        shoe = zg.cloth_color(v["shoes"], stain=(0.04, 0.03, 0.02))
        zg.paint_slots(obj, [shoe, zg.flat_color(SOLE_COLOR)], dirt=0.3)
        paint.weight_multi(obj, {k: seg[k] for k in (f"calf_{side}", f"foot_{side}", f"ball_{side}")})
    elif kind == "Spitter_Head":
        tree = ctx["hair_tree"]
        regions = [(tree, HAIR_REACH, wg.hair_color(v["hair"]))] if tree else []
        paint.paint(obj, zg.layered_color(regions, skin) if tree else skin)
        if tree:
            wg.lift_scalp(obj, tree, wg.HAIR_LIFT * v["body"]["head"])
        zg.weight_to(obj, "Head")
    elif kind in ("Spitter_Jaw", "Spitter_Tongue", "Spitter_ToothL"):
        color = {"Spitter_Jaw": skin, "Spitter_Tongue": zg.flat_color(sh.TONGUE_COLOR),
                 "Spitter_ToothL": zg.flat_color(sh.TOOTH_COLOR)}[kind]
        paint.paint(obj, color, dirt=0.4 if kind == "Spitter_Jaw" else 0.0)
        zg.weight_to(obj, "jaw")
    elif kind == "Spitter_Eye":
        zg.paint(obj, zg.flat_color(sh.EYE_COLOR), glow=0.5, dirt=0.0)
        zg.weight_to(obj, "Head")
    else:   # ağız içi, bebek, üst diş
        color = {"Spitter_Mouth": ctx["mouth"], "Spitter_Pupil": zg.flat_color(sh.PUPIL_COLOR)}.get(
            kind, zg.flat_color(sh.TOOTH_COLOR))
        zg.paint(obj, color, dirt=0.0)
        zg.weight_to(obj, "Head")


def mouth_color(head, s):
    inv = head.matrix_world.inverted()
    y0, y1 = (sh.MOUTH_CENTER.y - sh.MOUTH_RADII.y * 0.3) * s, (sh.MOUTH_CENTER.y + sh.MOUTH_RADII.y) * s

    def fn(p):
        t = min(max(((inv @ p).y - y0) / (y1 - y0) / 0.8, 0.0), 1.0)
        return zg._mix(sh.MOUTH_FRONT, sh.MOUTH_BACK, t)
    return fn


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


def _take(objs, kinds):
    out = [o for o in objs if _kind(o.name) in kinds]
    for o in out:
        objs.remove(o)
    return out


def _shell_color(v, k):
    if k == "Spitter_Bottom":
        return zg.cloth_color(v["bottom_color"], stain=(0.05, 0.05, 0.03))
    if k == "Spitter_Belt":
        return zg.flat_color(v.get("belt") or (0.02, 0.02, 0.02))
    stain = (0.06, 0.07, 0.03) if v["top"] == "coverall" else (0.20, 0.22, 0.08)
    return zg.cloth_color(v["top_color"] or (0, 0, 0), stain=stain, blood=v["blood"])


def build_variant_game(v, mat):
    objs = _detach(bs.build_variant(v, 0.0, "neutral"))
    find = {_base(o.name): o for o in objs}
    head, jaw, body = find["Spitter_Head"], find["Spitter_Jaw"], find["Spitter_Body"]
    hs, s = v["body"]["head"], v["body"]["s"]
    bone_list = bones(v, head, jaw)
    shells = []
    reach = dict(PAINTED_SHELLS)
    order = [n for n, _r in PAINTED_SHELLS]
    for shell in _take(objs, reach):
        k = _kind(shell.name)
        shells.append((zg.world_bvh(shell), reach[k], _shell_color(v, k), order.index(k)))
        bpy.data.objects.remove(shell)
    shells = [(t, r, c) for t, r, c, _i in sorted(shells, key=lambda x: x[3])]
    hair_tree = None
    for hair in _take(objs, ("Spitter_Hair", "Walker_Hair")):
        hair_tree = zg.world_bvh(hair)
        bpy.data.objects.remove(hair)
    raw = bs.body_points(v["body"])
    sac = _scaled(bs.throat_sac(v, raw), s)
    gut = _scaled(bs.gut_ellipsoid(v, raw), s)
    mouth = head.matrix_world @ (sh.MOUTH_TIP * hs)
    pts = {n: (p * s, r) for n, (p, r) in raw.items()}
    acid = paint.acid_field(mouth, pts, sac, v["seed"])
    skin = paint.skin_color(zg.skin_color(v["tone"], v["bruise"]), acid, sac)
    ctx = {"segments": body_segments(v, bone_list), "shells": shells, "hair_tree": hair_tree,
           "skin": skin, "mouth": mouth_color(head, hs), "body": body, "sac": sac, "gut": gut}
    prepare_body(body, v, ctx)
    tree = kdtree.KDTree(len(body.data.vertices))
    for vert in body.data.vertices:
        tree.insert(body.matrix_world @ vert.co, vert.index)
    tree.balance()
    ctx["tree"] = tree
    for obj in objs:
        if obj is not body:
            prepare_part(obj, v, ctx)
    mesh = zg.join([body] + [o for o in objs if o is not body], "Spitter_" + v["name"])
    mesh.data.validate(clean_customdata=False)
    mesh.data.materials.clear()
    mesh.data.materials.append(mat)
    arm = zg.build_armature(RIG_NAME, bone_list)
    zg.bind(mesh, arm)
    arm["mouth_tip_rest"] = list(mouth)
    return arm, mesh


# ---------------------------------------------------------------- kurulum

def out_path(v):
    return os.path.join(OUT_DIR, "zombie_spitter_%s.glb" % v["name"].lower())


def build_game(names=None):
    kit.reset_scene()
    mat = zg.vertex_color_material("M_Zombie_VC", glow_strength=2.0)
    variants = [v for v in bs.VARIANTS if not names or v["name"] in names]
    report, rigs = {}, []
    for i, v in enumerate(variants):
        arm, mesh = build_variant_game(v, mat)
        clips = anims.build_all(arm)
        zg.export_glb(out_path(v), [arm, mesh], **GLB_EXTRA)
        for name in clips:
            bpy.data.actions.remove(bpy.data.actions[name])
        rigs.append((v["name"], arm, mesh))
        report[v["name"]] = (zg.tri_count(mesh), len(arm.data.bones), round(anims.mesh_height(arm), 3))
        print("SPITTER GAME", v["name"], "tris", report[v["name"]][0], "bones", report[v["name"]][1],
              "height", report[v["name"]][2])
        arm.name = "%s_%s" % (RIG_NAME, v["name"])
        arm.data.name = arm.name
        arm.location.x = (i - (len(variants) - 1) / 2) * LINEUP_SPACING
    for variant, arm, _mesh in rigs:
        for name in anims.build_all(arm):
            bpy.data.actions[name].name = "%s_%s" % (name, variant)
        arm.animation_data.action = None
    kit.setup_look()
    os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    print("SPITTER GAME exported:", report)
    return report


if __name__ != "spitter_game":
    _argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    build_game([a for a in _argv if not a.startswith("-")] or None)
