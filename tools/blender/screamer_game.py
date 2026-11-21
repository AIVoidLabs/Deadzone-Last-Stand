"""Çığlıkçı oyun modeli (7.3): build_screamer görünüşünden → zombie_screamer_<çeşit>.glb.

Hat thrower_game / tank_game ile aynı (ortak iş zombie_game.py'de): incelt → köşe rengi → ağırlık →
birleştir → iskelet → GLB. Farklar:
- Kaburgalar incelmeden sonra da okunsun diye ten rengine de işlenir: screamer_parts.rib_field ile
  sırtlar açık, aralar koyu (RIB_SHADE). Kabartma geometride de var (konsept).
- Ağız torbası (`Screamer_Mouth`): köşe başına `jaw_w` ağırlığı → jaw (w) + Head (1 - w). Çene düşünce
  yanak zarı gerilir, açık ağız koyu kırmızı mağara olarak okunur.
- Etek (`Screamer_Skirt`) ayrı parça kalır (iki bacağın arasını köprüler): pelvis + uyluklara uzaklıkla.
- Kıyafet üstü/pantolon/kemer gövdenin köşelerine boyanır, gövde orada kumaş kalınlığı kadar kabartılır.
- Uzun saç (nurse) walker_game.game_locks ile az sayıda düşük çözünürlüklü tutam; diğerlerinde saç rengi.
- İskelet: 25 standart kemik + `jaw`. GLB köşe rengi alfası: export_vertex_color="ACTIVE" (COLOR_0 VEC4).
Klipler screamer_anims.py (+ screamer_falls.py): her çeşidin kendi iskeletine anahtarlanır, kendi GLB'sine.

Çalıştırma (arka plan):  blender --background --python tools/blender/screamer_game.py [-- Gown Nurse Bare]
Çıktı: assets/models/characters/zombie_screamer_<çeşit>.glb, build/blender/screamer_game.blend
"""
import importlib
import os
import sys

import bpy
from mathutils import Vector

_HERE = globals().get("__file__", "")
REPO = os.path.abspath(os.path.join(os.path.dirname(_HERE), "..", "..")) if _HERE else ""
if not REPO or not os.path.isdir(os.path.join(REPO, "tools")):
    REPO = r"C:\Users\pekta\projeler\Deadzone-Last-Stand"
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import zombie_kit as kit  # noqa: E402
import zombie_game as zg  # noqa: E402
import walker_game as wg  # noqa: E402
import walker_head as wh  # noqa: E402
import build_screamer as bs  # noqa: E402
import screamer_head as sh  # noqa: E402
import screamer_parts as sp  # noqa: E402
import screamer_clothes as sc  # noqa: E402
import screamer_anims as anims  # noqa: E402
import screamer_weights as sw  # noqa: E402

for _mod in (kit, zg, bs, sh, sp, sc, sw, anims):
    importlib.reload(_mod)

OUT_DIR = os.path.join(REPO, "assets", "models", "characters")
OUT_BLEND = os.path.join(REPO, "build", "blender", "screamer_game.blend")
RIG_NAME = "Screamer_Rig"
LINEUP_SPACING = 1.2
BUDGET = {"Screamer_Body": 6400, "Screamer_Head": 1300, "Screamer_Jaw": 320, "Screamer_Hand": 460,
          "Screamer_Toes": 200, "Screamer_Mouth": 360, "Screamer_Tongue": 40, "Screamer_Skirt": 900,
          "Walker_Shoe": 240, "Screamer_Shoe": 240, "Screamer_Eye": 24, "Screamer_Pupil": 12, "Screamer_Band": 48,
          "Screamer_Hair": 500}
PAINTED_SHELLS = (("Screamer_Belt", 0.034), ("Screamer_Top", 0.024), ("Screamer_Bottom", 0.026))
CLOTH_LIFT = 0.006
HAIR_REACH = 0.012
GAME_LOCKS = {"long": 14}
SOLE_COLOR = (0.20, 0.19, 0.17)
RIB_SHADE = 28.0          # ten rengi çarpanı = 1 + RIB_SHADE * rib_field (m): sırt açık, oluk koyu
WEIGHT_SMOOTH = 4
GLB_EXTRA = {"export_optimize_animation_keep_anim_armature": False, "export_vertex_color": "ACTIVE"}


def _base(name: str) -> str:
    return name.split(".")[0]


def _kind(name: str) -> str:
    b = _base(name)
    return b[:-2] if b.endswith(("_L", "_R")) else b


# ---------------------------------------------------------------- iskelet

def bones(v, head, jaw) -> list:
    """[(ad, baş, uç, ebeveyn)] — nötr konsept pozunda dinlenme, çeşit ölçeğiyle."""
    s, hs = v["body"]["s"], v["body"]["head"]
    pts = {n: p * s for n, (p, _r) in bs.body_points(v["body"]).items()}
    hm, jm = head.matrix_world, jaw.matrix_world
    chin = Vector((0.0, -0.080, -0.062)) - sh.JAW_HINGE
    out = [("root", Vector((0, 0, 0)), Vector((0, 0, 0.25)), None),
           ("pelvis", pts["pelvis"], pts["spine"], "root"),
           ("spine_01", pts["spine"], pts["chest"], "pelvis"),
           ("spine_02", pts["chest"], pts["upchest"], "spine_01"),
           ("spine_03", pts["upchest"], pts["neck0"], "spine_02"),
           ("neck_01", pts["neck0"], pts["neck1"], "spine_03"),
           ("Head", pts["neck1"], hm @ (Vector((0.0, 0.010, 0.14)) * hs), "neck_01"),
           ("jaw", jm.translation.copy(), jm @ (chin * hs), "Head")]
    for side, sx in (("l", 1.0), ("r", -1.0)):
        p = {k: pts[f"{k}_{side.upper()}"] for k in ("shoulder", "elbow", "wrist", "tip", "hip", "knee",
                                                     "ankle", "ball", "toe")}
        fwd = (p["toe"] - p["ball"]).normalized()
        out += [(f"clavicle_{side}", pts["upchest"] + Vector((0.04 * sx, 0.0, 0.0)) * s, p["shoulder"], "spine_03"),
                (f"upperarm_{side}", p["shoulder"], p["elbow"], f"clavicle_{side}"),
                (f"lowerarm_{side}", p["elbow"], p["wrist"], f"upperarm_{side}"),
                (f"hand_{side}", p["wrist"], p["tip"], f"lowerarm_{side}"),
                (f"thigh_{side}", p["hip"], p["knee"], "pelvis"),
                (f"calf_{side}", p["knee"], p["ankle"], f"thigh_{side}"),
                (f"foot_{side}", p["ankle"], p["ball"], f"calf_{side}"),
                (f"ball_{side}", p["ball"], p["toe"] + fwd * 0.05 * s, f"foot_{side}"),
                (f"ball_leaf_{side}", p["toe"] + fwd * 0.05 * s, p["toe"] + fwd * 0.09 * s, f"ball_{side}")]
    return out


def body_segments(bone_list) -> dict:
    skip = ("root", "jaw", "ball_leaf_l", "ball_leaf_r")
    return {name: [(h, t)] for name, h, t, _ in bone_list if name not in skip}


# ---------------------------------------------------------------- renk

def skin_color(v, mouth_at):
    """Ten (walker_game.skin_color: morluk + ağızdan sızan kan) × kaburga gölgesi."""
    base = wg.skin_color(v, mouth_at)
    s = v["body"]["s"]
    pts = bs.body_points(v["body"])

    def fn(p):
        c = base(p)
        k = 1.0 + RIB_SHADE * sp.rib_field(p / s, pts)
        return tuple(min(1.0, max(0.0, x * k)) for x in c)
    return fn


def shell_color(kind, v):
    if kind == "Screamer_Belt":
        return zg.flat_color((0.16, 0.12, 0.07))
    if kind == "Screamer_Bottom":
        return zg.cloth_color(v["bottom_color"], stain=(0.06, 0.05, 0.03))
    return top_color(v)


def top_color(v):
    return zg.cloth_color(v["top_color"], stain=(0.14, 0.12, 0.08), blood=v["blood"])


def mouth_color(head, s):
    inv = head.matrix_world.inverted()
    y0 = (sh.BAG_CENTER.y - sh.BAG_RADII.y * 0.6) * s
    y1 = (sh.BAG_CENTER.y + sh.BAG_RADII.y) * s

    def fn(p):
        t = min(max(((inv @ p).y - y0) / (y1 - y0) / 0.75, 0.0), 1.0)
        return zg._mix(sh.MOUTH_FRONT, sh.MOUTH_BACK, t)
    return fn


def lift_cloth(body, shells) -> None:
    mw = body.matrix_world
    for vert in body.data.vertices:
        if any(tree.find_nearest(mw @ vert.co, reach)[0] is not None for tree, reach, _fn in shells):
            vert.co += vert.normal * CLOTH_LIFT


# ---------------------------------------------------------------- parça hazırlığı

def prepare_body(obj, ctx) -> None:
    zg.decimate(obj, BUDGET["Screamer_Body"])
    lift_cloth(obj, ctx["shells"])
    zg.paint(obj, zg.layered_color(ctx["shells"], ctx["skin"]))
    body_seg = {k: sg for k, sg in ctx["segments"].items() if not k.startswith("hand_")}   # el ayrı ağ
    sw.weight_multi(obj, body_seg, geo=True)
    zg.smooth_weights(obj, WEIGHT_SMOOTH)


def prepare_part(obj, v, ctx) -> None:
    kind, base = _kind(obj.name), _base(obj.name)
    side = base[-1].lower() if base.endswith(("_L", "_R")) else ""
    if kind in BUDGET:
        zg.decimate(obj, BUDGET[kind])
    seg, skin = ctx["segments"], ctx["skin"]
    if kind == "Screamer_Hand":
        zg.paint(obj, skin)
        sw.weight_multi(obj, {k: seg[k] for k in (f"lowerarm_{side}", f"hand_{side}")}, keep=2)
    elif kind == "Screamer_Toes":
        zg.paint(obj, skin)
        zg.weight_to(obj, f"ball_{side}")
    elif kind in ("Walker_Shoe", "Screamer_Shoe"):
        shoe = zg.cloth_color(v["shoes"], stain=(0.10, 0.09, 0.07))
        zg.paint_slots(obj, [shoe, zg.flat_color(SOLE_COLOR)], dirt=0.3)
        sw.weight_multi(obj, {k: seg[k] for k in (f"calf_{side}", f"foot_{side}", f"ball_{side}")})
    elif kind == "Screamer_Skirt":
        zg.paint(obj, top_color(v), dirt=0.3)
        sw.weight_multi(obj, {k: seg[k] for k in ("pelvis", "thigh_l", "thigh_r", "spine_01")}, keep=3, power=3.0)
        zg.smooth_weights(obj, 3)
    elif kind == "Screamer_Band":
        zg.paint(obj, zg.flat_color(sc.BAND_COLOR), dirt=0.0)
        zg.weight_to(obj, "lowerarm_l")
    elif kind == "Screamer_Head":
        tree = ctx["hair_tree"]
        regions = [(tree, HAIR_REACH, wg.hair_color(v["hair"]))] if tree else []
        zg.paint(obj, zg.layered_color(regions, skin))
        if tree:
            wg.lift_scalp(obj, tree, wg.HAIR_LIFT * v["body"]["head"])
        zg.weight_to(obj, "Head")
    elif kind == "Screamer_Hair":
        zg.paint(obj, wg.hair_color(v["hair"]), dirt=0.3)
        zg.weight_to(obj, "Head")
    elif kind == "Screamer_Mouth":
        zg.paint(obj, ctx["mouth"], dirt=0.0)
        sw.weight_bag(obj)
    elif kind in ("Screamer_Jaw", "Screamer_Tongue", "Screamer_ToothL"):
        color = {"Screamer_Jaw": skin, "Screamer_Tongue": zg.flat_color(sh.TONGUE_COLOR),
                 "Screamer_ToothL": zg.flat_color(sh.TOOTH_COLOR)}[kind]
        zg.paint(obj, color, dirt=0.4 if kind == "Screamer_Jaw" else 0.0)
        zg.weight_to(obj, "jaw")
    else:   # göz, bebek, üst diş: kafaya bağlı
        color = {"Screamer_Eye": zg.flat_color(sh.EYE_COLOR),
                 "Screamer_Pupil": zg.flat_color(sh.PUPIL_COLOR)}.get(kind, zg.flat_color(sh.TOOTH_COLOR))
        zg.paint(obj, color, dirt=0.0)
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


def _hair(objs, head, v):
    """Konsept saçı yalnız bölge olarak kalır (ağı silinir); uzun saçta oyun tutamları eklenir."""
    hair = next((o for o in objs if _kind(o.name) in ("Screamer_Hair", "Walker_Hair")), None)
    if hair is None:
        return None
    tree = zg.world_bvh(hair)
    objs.remove(hair)
    bpy.data.objects.remove(hair)
    count = GAME_LOCKS.get(v["hair_style"], 0)
    if count:
        locks = wg.game_locks(head, tree, v, wh.HAIR_STYLES[v["hair_style"]], count)
        if locks is not None:
            locks.name = "Screamer_Hair"
            objs.append(locks)
    return tree


def build_variant_game(v, mat):
    objs = _detach(bs.build_variant(v, 0.0, "neutral"))
    find = {_base(o.name): o for o in objs}
    head, jaw = find["Screamer_Head"], find["Screamer_Jaw"]
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
    hair_tree = _hair(objs, head, v)
    mouth_at = head.matrix_world @ (Vector((0.0, -0.085, -0.03)) * hs)
    body = find["Screamer_Body"]
    ctx = {"segments": body_segments(bone_list), "shells": shells, "hair_tree": hair_tree,
           "skin": skin_color(v, mouth_at), "mouth": mouth_color(head, hs)}
    prepare_body(body, ctx)
    for obj in objs:
        if obj is not body:
            prepare_part(obj, v, ctx)
    mesh = zg.join([body] + [o for o in objs if o is not body], "Screamer_" + v["name"])
    mesh.data.validate(clean_customdata=False)
    mesh.data.materials.clear()
    mesh.data.materials.append(mat)
    arm = zg.build_armature(RIG_NAME, bone_list)
    zg.bind(mesh, arm)
    return arm, mesh


# ---------------------------------------------------------------- kurulum

def out_path(v) -> str:
    return os.path.join(OUT_DIR, "zombie_screamer_%s.glb" % v["name"].lower())


def build_game(names=None) -> dict:
    kit.reset_scene()
    mat = zg.vertex_color_material("M_Zombie_VC", glow_strength=0.0)
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
        print("SCREAMER GAME", v["name"], "tris", report[v["name"]][0], "bones", report[v["name"]][1],
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
    print("SCREAMER GAME exported:", report)
    return report


if __name__ != "screamer_game":
    _argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    build_game([a for a in _argv if not a.startswith("-")] or None)
