"""Boss "Yığın" oyun modeli (7.4): build_boss görünüşünden → assets/models/characters/boss_heap.glb.

Hat bloater_game.py ile aynı (ortak iş zombie_game.py'de): incelt → köşe rengi → ağırlık → birleştir →
iskelet → GLB. Farklar:
- Tek çeşit, bütçe ~20 bin üçgen. Boyama konseptle aynı renk fonksiyonlarıyla (boss_paint), inceltmeden
  sonra ve kök ölçeği 1'deyken (yapı biriminde) yapılır; sonra kök BUILD_SCALE ile dünyaya açılır.
- Parıltı maskesi köşe başına (göğüs yarığı + kalp + damarlar + gözler): GLB'de COLOR_0 alfası için
  dışa aktarım `export_vertex_color="ACTIVE"` (bloater_game ile aynı); boss_check COLOR_0 tipini doğrular.
- İskelet: 25 standart kemik + `jaw` + 2 ek kemik: `claw_r` (pençe parmakları, hand_r çocuğu: kıvırma/açma),
  `hump` (kambur ve içindeki gömülü bedenler, spine_03 çocuğu: çağrıda silkelenme, nefeste kabarma).
- Topuz ve dikenleri hand_l'ye katı; pençe avucu hand_r, parmaklar ve tırnaklar claw_r; kalp gövde köşesinin ağırlığı.

Çalıştırma (arka plan):  blender --background --python tools/blender/boss_game.py
Çıktı: assets/models/characters/boss_heap.glb, build/blender/boss_game.blend
"""
import importlib
import os
import sys

import bpy
from mathutils import Matrix, Vector, kdtree

_HERE = globals().get("__file__", "")
REPO = os.path.abspath(os.path.join(os.path.dirname(_HERE), "..", "..")) if _HERE else ""
if not REPO or not os.path.isdir(os.path.join(REPO, "tools")):
    REPO = r"C:\Users\pekta\projeler\Deadzone-Last-Stand"
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import zombie_kit as kit  # noqa: E402
import zombie_game as zg  # noqa: E402
import bloater_paint as bpaint  # noqa: E402  (weight_multi, copy_weights: salt okunur)
import build_boss as bb  # noqa: E402
import boss_parts as bparts  # noqa: E402
import boss_anims as anims  # noqa: E402

for _mod in (kit, zg, bb, bparts, anims):
    importlib.reload(_mod)

OUT_PATH = os.path.join(REPO, "assets", "models", "characters", "boss_heap.glb")
OUT_BLEND = os.path.join(REPO, "build", "blender", "boss_game.blend")
RIG_NAME = "Boss_Rig"
BUDGET = {"Boss_Body": 14500, "Boss_Head": 1500, "Boss_Jaw": 450, "Boss_Mace": 900, "Boss_Claw": 900,
          "Boss_Toes": 260, "Boss_Core": 160, "Boss_Mouth": 90, "Boss_Tongue": 40, "Boss_Eye": 40}
WEIGHT_SMOOTH = 5
GLB_EXTRA = {"export_optimize_animation_keep_anim_armature": False, "export_vertex_color": "ACTIVE"}
CLAW_KNUCKLE = 0.15       # pençe: bilekten bu kadar ötesi (yapı birimi) claw_r kemiğine geçer
HUMP_HEAD = Vector((0.0, 0.16, 1.34))
HUMP_TAIL = Vector((-0.08, 0.24, 1.74))


def _base(name):
    return name.split(".")[0]


# ---------------------------------------------------------------- iskelet

def bones(head, jaw):
    """Dünya uzayında (kök ölçeği uygulanmış) kemik listesi."""
    S, hs = bb.BUILD_SCALE, bb.HEAD_S
    pts = {n: p * S for n, (p, _r) in bb.body_points("neutral").items()}
    hm, jm = head.matrix_world, jaw.matrix_world
    out = [("root", Vector((0, 0, 0)), Vector((0, 0, 0.5)), None),
           ("pelvis", pts["pelvis"], pts["spine"], "root"),
           ("spine_01", pts["spine"], pts["chest"], "pelvis"),
           ("spine_02", pts["chest"], pts["upchest"], "spine_01"),
           ("spine_03", pts["upchest"], pts["neck0"], "spine_02"),
           ("neck_01", pts["neck0"], pts["neck1"], "spine_03"),
           ("Head", pts["neck1"], hm @ (Vector((0.0, 0.012, 0.13)) * hs), "neck_01"),
           ("jaw", jm.translation.copy(), jm @ (Vector((0.0, -0.09, -0.056)) * hs), "Head"),
           ("hump", HUMP_HEAD * S, HUMP_TAIL * S, "spine_03")]
    for side, sx in (("l", 1.0), ("r", -1.0)):
        p = {k: pts[f"{k}_{side.upper()}"] for k in ("shoulder", "elbow", "wrist", "fist", "hip", "knee",
                                                     "ankle", "ball", "toe")}
        fwd = (p["toe"] - p["ball"]).normalized()
        out += [(f"clavicle_{side}", pts["upchest"] + Vector((0.10 * sx, 0.0, 0.0)) * S, p["shoulder"], "spine_03"),
                (f"upperarm_{side}", p["shoulder"], p["elbow"], f"clavicle_{side}"),
                (f"lowerarm_{side}", p["elbow"], p["wrist"], f"upperarm_{side}"),
                (f"hand_{side}", p["wrist"], p["fist"], f"lowerarm_{side}"),
                (f"thigh_{side}", p["hip"], p["knee"], "pelvis"),
                (f"calf_{side}", p["knee"], p["ankle"], f"thigh_{side}"),
                (f"foot_{side}", p["ankle"], p["ball"], f"calf_{side}"),
                (f"ball_{side}", p["ball"], p["toe"] + fwd * 0.05 * S, f"foot_{side}"),
                (f"ball_leaf_{side}", p["toe"] + fwd * 0.05 * S, p["toe"] + fwd * 0.09 * S, f"ball_{side}")]
    w, d = claw_axis_world()
    out.append(("claw_r", w + d * CLAW_KNUCKLE * S, w + d * 0.42 * S, "hand_r"))
    return out


def claw_axis_world():
    w, d = bb.claw_axis(bb.body_points("neutral"))
    return w * bb.BUILD_SCALE, d


def body_segments(bone_list):
    skip = ("root", "jaw", "ball_leaf_l", "ball_leaf_r", "claw_r", "hand_l", "hand_r")
    seg = {name: [(h, t)] for name, h, t, _ in bone_list if name not in skip}
    S = bb.BUILD_SCALE
    pts = {n: p * S for n, (p, _r) in bb.body_points("neutral").items()}
    seg["pelvis"] = [(pts["hip_L"], pts["hip_R"]), (pts["pelvis"], pts["spine"])]
    seg["hump"] = [(HUMP_HEAD * S, HUMP_TAIL * S), (Vector((-0.26, 0.20, 1.62)) * S, Vector((0.24, 0.34, 1.62)) * S)]
    return seg


# ---------------------------------------------------------------- parça hazırlığı

def prepare_part(obj, ctx):
    kind = bb.kind_of(obj.name)
    side = _base(obj.name)[-1].lower() if _base(obj.name).endswith(("_L", "_R")) else ""
    if kind in ("Boss_Head", "Boss_Eye", "Boss_Mouth", "Boss_ToothU"):
        zg.weight_to(obj, "Head")
    elif kind in ("Boss_Jaw", "Boss_Tongue", "Boss_ToothL"):
        zg.weight_to(obj, "jaw")
    elif kind in ("Boss_Mace", "Boss_Spike"):
        zg.weight_to(obj, "hand_l")
    elif kind == "Boss_Talon":
        zg.weight_to(obj, "claw_r")
    elif kind == "Boss_Claw":
        claw_weights(obj)
    elif kind == "Boss_Toes":
        zg.weight_to(obj, f"ball_{side}")
    elif kind == "Boss_Core":
        bpaint.copy_weights(obj, ctx["body"], ctx["tree"], obj.matrix_world @ obj.data.vertices[0].co)
    else:
        zg.weight_to(obj, "spine_02")


def claw_weights(obj):
    """Avuç hand_r, parmaklar claw_r (bilekten uzaklığa göre yumuşak geçiş)."""
    w, d = claw_axis_world()
    S = bb.BUILD_SCALE
    gh = obj.vertex_groups.new(name="hand_r")
    gc = obj.vertex_groups.new(name="claw_r")
    for v in obj.data.vertices:
        t = ((obj.matrix_world @ v.co) - w).dot(d) / S
        k = zg._smooth(CLAW_KNUCKLE - 0.03, CLAW_KNUCKLE + 0.06, t)
        gh.add([v.index], 1.0 - k, "REPLACE")
        gc.add([v.index], k, "REPLACE")


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


def build_game_model(mat):
    root = bb.build_variant(0.0, "neutral", painted=False)
    objs = [o for o in root.children_recursive if o.type == "MESH"]
    for o in objs:
        k = bb.kind_of(o.name)
        if k in BUDGET:
            zg.decimate(o, BUDGET[k])
    root.scale = (1.0, 1.0, 1.0)            # boyama yapı biriminde (konseptle aynı fonksiyonlar)
    bpy.context.view_layer.update()
    info, pts, head = bb.LAST["info"], bb.LAST["pts"], bb.LAST["head"]
    bb.paint_all(objs, info, pts, head)
    root.scale = (bb.BUILD_SCALE,) * 3
    objs = _detach(root)
    find = {_base(o.name): o for o in objs}
    head, jaw, body = find["Boss_Head"], find["Boss_Jaw"], find["Boss_Body"]
    bone_list = bones(head, jaw)
    bpaint.weight_multi(body, body_segments(bone_list))
    zg.smooth_weights(body, WEIGHT_SMOOTH)
    tree = kdtree.KDTree(len(body.data.vertices))
    for v in body.data.vertices:
        tree.insert(body.matrix_world @ v.co, v.index)
    tree.balance()
    ctx = {"body": body, "tree": tree}
    for o in objs:
        if o is not body:
            prepare_part(o, ctx)
    mesh = zg.join([body] + [o for o in objs if o is not body], "Boss_Heap")
    mesh.data.validate(clean_customdata=False)
    mesh.data.materials.clear()
    mesh.data.materials.append(mat)
    arm = zg.build_armature(RIG_NAME, bone_list)
    zg.bind(mesh, arm)
    return arm, mesh


def build_game():
    kit.reset_scene()
    mat = zg.vertex_color_material("M_Zombie_VC", glow_strength=2.0)
    arm, mesh = build_game_model(mat)
    clips = anims.build_all(arm)
    zg.export_glb(OUT_PATH, [arm, mesh], **GLB_EXTRA)
    report = (zg.tri_count(mesh), len(arm.data.bones), round(anims.mesh_height(arm), 3))
    print("BOSS GAME tris", report[0], "bones", report[1], "height", report[2], "clips", clips)
    kit.setup_look(target_height=2.4)
    os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    return arm, mesh, clips


if __name__ != "boss_game":
    build_game()
