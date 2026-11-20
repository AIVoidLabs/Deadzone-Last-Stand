"""Koşucu (Pençeli) oyun modeli (Aşama V.5): build_runner v2 görünüşünden → zombie_runner_<çeşit>.glb.

Hat walker_game.py ile aynı (ortak iş zombie_game.py'de): incelt → köşe rengi → ağırlık → birleştir →
iskelet → GLB; her çeşit kendi iskeletiyle kendi GLB'sine (aynı kemik adları, aynı "Runner_Rig" düğümü).
Farklar:
- Özel zombi bütçesi (8–15 bin üçgen): kıyafet ayrı kabuk olarak kalır (kıvrım, kıvrık kenar okunsun);
  eşofman şeridi ve göğüs numarası kabuğa boyanır.
- Pençeler ayrı parça, el kemiğine bağlı; rengi claw_t özniteliğinden (kök koyu kahve → uç siyah).
- Gözler köşe alfasıyla hafif parlar (zombie_vc.gdshader: 1 - COLOR.a parıltı), EYE_GLOW.
- İskelet: 25 standart kemik + `jaw` (çığlık). Dinlenme pozu konseptin "stalk" duruşu.
Klipler runner_anims.py (+ runner_moves.py).

Çalıştırma: blender --background --python tools/blender/runner_game.py
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
import walker_head as wh  # noqa: E402
import walker_game as wg  # noqa: E402
import build_runner as br  # noqa: E402
import runner_body as rb  # noqa: E402
import runner_head as rh  # noqa: E402
import runner_parts as rp  # noqa: E402
import runner_anims as anims  # noqa: E402

for _mod in (kit, zg, wh, br, rb, rh, rp, anims):
    importlib.reload(_mod)

OUT_DIR = os.path.join(REPO, "assets", "models", "characters")
OUT_BLEND = os.path.join(REPO, "build", "blender", "runner_game.blend")
RIG_NAME = "Runner_Rig"
LINEUP_SPACING = 1.05
SHEET_VARIANT = "Torn"    # .blend'de klipleri tutulan çeşit (runner_sheet.py)
BUDGET = {"Runner_Body": 6200, "Runner_Top": 2000, "Runner_Bottom": 1700, "Runner_Head": 1500,
          "Runner_Jaw": 320, "Runner_Mouth": 120, "Runner_Tongue": 40, "Runner_Eye": 40,
          "Runner_Shoe_L": 260, "Runner_Shoe_R": 260, "Runner_Spurs": 300}
PAINTED = ("Runner_Stripe", "Runner_Bib")   # ince kabuklar: alttaki kabuğa boyanır, silinir
PAINT_REACH = 0.012
TEETH_COLOR = (0.40, 0.33, 0.20)
EYE_COLOR = (0.95, 0.72, 0.36)
EYE_GLOW = 0.55          # abartısız parıltı
HAIR_REACH = 0.012


def _base(name):
    return name.split(".")[0]


def bones(v, head, jaw):
    """[(ad, baş, uç, ebeveyn)]: konseptin stalk pozunda dinlenme."""
    pts = {n: p for n, (p, _r) in rb.body_points("stalk", v["body"]).items()}
    s = v["body"]["head"]
    hm, jm = head.matrix_world, jaw.matrix_world
    out = [("root", Vector((0, 0, 0)), Vector((0, 0, 0.25)), None),
           ("pelvis", pts["pelvis"], pts["spine"], "root"),
           ("spine_01", pts["spine"], pts["chest"], "pelvis"),
           ("spine_02", pts["chest"], pts["upchest"], "spine_01"),
           ("spine_03", pts["upchest"], pts["neck0"], "spine_02"),
           ("neck_01", pts["neck0"], pts["neck1"], "spine_03"),
           ("Head", pts["neck1"], hm @ (Vector((0.0, 0.010, 0.150)) * s), "neck_01"),
           ("jaw", jm.translation.copy(), jm @ (Vector((0.0, -0.074, -0.050)) * s), "Head")]
    for side, sx in (("l", 1.0), ("r", -1.0)):
        p = {k: pts[f"{k}_{side.upper()}"] for k in ("shoulder", "elbow", "wrist", "palm", "hip",
                                                     "knee", "ankle", "ball")}
        finger = p["palm"] + (p["palm"] - p["wrist"]).normalized() * 0.13
        fwd = Vector((p["ball"].x - p["ankle"].x, p["ball"].y - p["ankle"].y, 0.0)).normalized()
        toe = p["ball"] + fwd * 0.05
        out += [(f"clavicle_{side}", pts["upchest"] + Vector((0.04 * sx, 0.0, 0.0)), p["shoulder"], "spine_03"),
                (f"upperarm_{side}", p["shoulder"], p["elbow"], f"clavicle_{side}"),
                (f"lowerarm_{side}", p["elbow"], p["wrist"], f"upperarm_{side}"),
                (f"hand_{side}", p["wrist"], finger, f"lowerarm_{side}"),
                (f"thigh_{side}", p["hip"], p["knee"], "pelvis"),
                (f"calf_{side}", p["knee"], p["ankle"], f"thigh_{side}"),
                (f"foot_{side}", p["ankle"], p["ball"], f"calf_{side}"),
                (f"ball_{side}", p["ball"], toe, f"foot_{side}"),
                (f"ball_leaf_{side}", toe, toe + fwd * 0.04, f"ball_{side}")]
    return out


def body_segments(bone_list):
    skip = ("root", "jaw", "ball_leaf_l", "ball_leaf_r")
    return {name: (h, t) for name, h, t, _ in bone_list if name not in skip}


def _subset(segments, prefixes):
    return {k: ab for k, ab in segments.items() if k.startswith(prefixes)}


def mouth_color(head, s):
    inv = head.matrix_world.inverted()
    y0 = (rh.MOUTH_CENTER.y - rh.MOUTH_RADII.y * 0.2) * s
    y1 = (rh.MOUTH_CENTER.y + rh.MOUTH_RADII.y) * s

    def fn(p):
        t = min(max(((inv @ p).y - y0) / (y1 - y0) / 0.85, 0.0), 1.0)
        return zg._mix(rh.MOUTH_FRONT, rh.MOUTH_BACK, t)
    return fn


def paint_claws(obj):
    """Pençe köşe rengi claw_t özniteliğinden (konsept malzemesiyle aynı geçiş) × oyuk koyulaşması."""
    attr = obj.data.attributes[rp.CLAW_ATTR]
    vals = [d.value for d in attr.data]
    zg._paint_verts(obj, lambda i, _p: rp.claw_color(vals[i]), 0.0, 0.2)


def _side_weight(obj, left, right):
    """Köşe x işaretine göre iki kemikten birine (pençeler)."""
    gl = obj.vertex_groups.new(name=left)
    gr = obj.vertex_groups.new(name=right)
    mw = obj.matrix_world
    for v in obj.data.vertices:
        (gl if (mw @ v.co).x > 0 else gr).add([v.index], 1.0, "REPLACE")


def prepare_part(obj, v, ctx):
    name = _base(obj.name)
    parent = _base(obj.parent.name) if obj.parent else ""
    if name in BUDGET:
        zg.decimate(obj, BUDGET[name])
    seg = ctx["segments"]
    if name == "Runner_Body":
        zg.paint(obj, ctx["skin"])
        zg.weight_by_distance(obj, seg)
        zg.smooth_weights(obj, 4)
    elif name in ("Runner_Top", "Runner_Bottom"):
        key = "top_color" if name == "Runner_Top" else "bottom_color"
        base = zg.cloth_color(v[key], blood=v["blood"] if name == "Runner_Top" else 0.0)
        zg.paint(obj, zg.layered_color(ctx["shells"], base), dirt=0.55)
        zg.weight_by_distance(obj, seg)
        zg.smooth_weights(obj, 3)
    elif name.startswith("Runner_Shoe"):
        shoe = zg.cloth_color(v["shoes"], stain=(0.04, 0.03, 0.02))
        zg.paint_slots(obj, [shoe, zg.flat_color((0.015, 0.014, 0.013))], dirt=0.3)
        zg.weight_by_distance(obj, _subset(seg, ("calf", "foot", "ball")))
    elif name == "Runner_Claws":
        paint_claws(obj)
        _side_weight(obj, "hand_l", "hand_r")
    elif name == "Runner_Spurs":
        zg.paint(obj, zg.flat_color(rp.claw_color(0.6)), dirt=0.2)
        zg.weight_by_distance(obj, _subset(seg, ("upperarm", "lowerarm", "spine", "pelvis")))
    elif name == "Runner_Head":
        tree = ctx["hair_tree"]
        regions = [(tree, HAIR_REACH, wg.hair_color(v["hair"]))] if tree else []
        zg.paint(obj, zg.layered_color(regions, ctx["skin"]))
        if tree:
            wg.lift_scalp(obj, tree, wg.HAIR_LIFT * v["body"]["head"])
        zg.weight_to(obj, "Head")
    elif name == "Walker_Hair":
        zg.paint(obj, wg.hair_color(v["hair"]), dirt=0.3)
        zg.weight_to(obj, "Head")
    elif name == "Runner_Jaw":
        zg.paint(obj, ctx["skin"])
        zg.weight_to(obj, "jaw")
    elif name == "Runner_Mouth":
        zg.paint(obj, ctx["mouth"], dirt=0.0)
        zg.weight_to(obj, "Head")
    elif name == "Runner_Tongue":
        zg.paint(obj, zg.flat_color(wh.TONGUE_COLOR), dirt=0.0)
        zg.weight_to(obj, "jaw")
    elif name == "Runner_Eye":
        zg.paint(obj, zg.flat_color(EYE_COLOR), glow=EYE_GLOW, dirt=0.0)
        zg.weight_to(obj, "Head")
    elif name.startswith("Runner_Tooth"):
        zg.paint(obj, zg.flat_color(TEETH_COLOR), dirt=0.0)
        zg.weight_to(obj, "jaw" if parent == "Runner_Jaw" else "Head")
    else:
        raise RuntimeError("bilinmeyen parça: " + name)


def build_variant_game(v, mat):
    root = br.build_variant(v, "stalk")
    objs = sorted((o for o in root.children_recursive if o.type == "MESH"), key=lambda o: o.name)
    bpy.data.objects.remove(root)
    bpy.context.view_layer.update()
    head = next(o for o in objs if _base(o.name) == "Runner_Head")
    jaw = next(o for o in objs if _base(o.name) == "Runner_Jaw")
    s = v["body"]["head"]
    bone_list = bones(v, head, jaw)
    shells = []
    for obj in [o for o in objs if _base(o.name) in PAINTED]:
        color = v["stripe"] if _base(obj.name) == "Runner_Stripe" else v["bib"]
        shells.append((zg.world_bvh(obj), PAINT_REACH, zg.cloth_color(color, blood=0.3)))
        objs.remove(obj)
        bpy.data.objects.remove(obj)
    hair = next((o for o in objs if _base(o.name) == "Runner_Hair"), None)
    hair_tree = None
    if hair is not None:      # konsept saçı yalnız bölge; uzun saçta az tutam (walker_game yöntemi)
        hair_tree = zg.world_bvh(hair)
        objs.remove(hair)
        bpy.data.objects.remove(hair)
        style = wh.HAIR_STYLES[v["hair_style"]]
        locks = wg.game_locks(head, hair_tree, v, style, wg.GAME_LOCKS.get(v["hair_style"], 0))
        if locks is not None:
            objs.append(locks)
    ctx = {"segments": body_segments(bone_list), "shells": shells, "hair_tree": hair_tree,
           "skin": wg.skin_color(v, head.matrix_world @ (Vector((0.0, -0.085, -0.03)) * s)),
           "mouth": mouth_color(head, s)}
    for obj in objs:
        prepare_part(obj, v, ctx)
    mesh = zg.join(objs, "Runner_" + v["name"])
    mesh.data.validate(clean_customdata=False)
    mesh.data.materials.clear()
    mesh.data.materials.append(mat)
    arm = zg.build_armature(RIG_NAME, bone_list)
    zg.bind(mesh, arm)
    return arm, mesh


def out_path(v):
    return os.path.join(OUT_DIR, "zombie_runner_%s.glb" % v["name"].lower())


def build_game(variants=None, export=True):
    kit.reset_scene()
    mat = zg.vertex_color_material("M_Zombie_VC", glow_strength=2.0)
    variants = variants or br.VARIANTS
    report, rigs = {}, []
    for i, v in enumerate(variants):
        arm, mesh = build_variant_game(v, mat)
        clips = anims.build_all(arm)
        if export:
            zg.export_glb(out_path(v), [arm, mesh], **wg.GLB_ANIM)
        arm.animation_data.action = None
        for name in clips:          # dışa aktarıcı uyumlu tüm actionları alır: sıradaki çeşide karışmasın
            bpy.data.actions.remove(bpy.data.actions[name])
        report[v["name"]] = (zg.tri_count(mesh), len(arm.data.bones))
        print("RUNNER GAME", v["name"], "tris", report[v["name"]][0], "bones", report[v["name"]][1])
        arm.name = "%s_%s" % (RIG_NAME, v["name"])
        arm.data.name = arm.name
        arm.location.x = (i - (len(variants) - 1) / 2) * LINEUP_SPACING
        rigs.append((v["name"], arm))
    for vname, arm in rigs:         # inceleme kopyası: yalnız kare özeti çeşidinin klipleri, çeşit ekiyle
        if vname == SHEET_VARIANT:
            x = arm.location.x
            arm.location.x = 0.0
            for name in anims.build_all(arm):
                bpy.data.actions[name].name = "%s_%s" % (name, vname)
            arm.animation_data.action = bpy.data.actions["idle_Loop_%s" % vname]
            arm.location.x = x
    kit.setup_look()
    os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    print("RUNNER GAME exported:", report)
    return report


if __name__ != "runner_game":
    build_game()
