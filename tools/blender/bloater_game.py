"""Patlayıcı oyun modeli (7.3): build_bloater görünüşünden → zombie_bloater_<çeşit>.glb.

Hat tank_game.py ile aynı (ortak iş zombie_game.py'de): incelt → köşe rengi → ağırlık → birleştir →
iskelet → GLB. Farklar:
- Parıltı maskesi köşe başına: kabarcık çekirdeği alfa 0 (tam parıltı), kenarı ve kızarık taban kısmen.
  Konseptteki kızarık taban ağları oyunda silinir, gövde köşelerine boyanır (üçgen tasarrufu).
- GLB COLOR_0 alfası: dışa aktarım `export_vertex_color="ACTIVE"` ile (MATERIAL kipinde opak malzemede
  alfa atılıyor ve COLOR_0 VEC3 çıkıyordu); bloater_check COLOR_0 tipini doğrular (VEC4 beklenir).
- Göbek küresi spine_01'e çekilir (swell ölçeği tüm küreyi şişirsin); kabarcıklar katı (altındaki gövde
  köşesinin ağırlığı), eller lowerarm/hand, kasket kafaya.
- İskelet: 25 standart kemik + `jaw`.

Çalıştırma (arka plan):  blender --background --python tools/blender/bloater_game.py [-- Chef Trucker Bare]
Çıktı: assets/models/characters/zombie_bloater_<çeşit>.glb, build/blender/bloater_game.blend
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
import build_bloater as bb  # noqa: E402
import bloater_head as bh  # noqa: E402
import bloater_parts as bp  # noqa: E402
import bloater_anims as anims  # noqa: E402
import bloater_paint as paint  # noqa: E402

for _mod in (kit, zg, bb, bh, bp, anims, paint):
    importlib.reload(_mod)

OUT_DIR = os.path.join(REPO, "assets", "models", "characters")
OUT_BLEND = os.path.join(REPO, "build", "blender", "bloater_game.blend")
RIG_NAME = "Bloater_Rig"
LINEUP_SPACING = 1.8
BUDGET = {"Bloater_Body": 5400, "Bloater_Head": 1100, "Bloater_Jaw": 280, "Bloater_Hand": 300,
          "Bloater_Toes": 200, "Bloater_Blister": 36, "Bloater_FaceBlister": 24, "Bloater_Mouth": 90,
          "Bloater_Tongue": 40, "Bloater_Shoe": 220, "Bloater_Eye": 24, "Bloater_Pupil": 12,
          "Bloater_Cap": 300, "Bloater_Brim": 60}
PAINTED_SHELLS = (("Bloater_Belt", 0.045), ("Bloater_Apron", 0.040), ("Bloater_Top", 0.026),
                  ("Bloater_Bottom", 0.026))
CLOTH_LIFT = 0.007
HAIR_REACH = 0.012
SOLE_COLOR = (0.015, 0.014, 0.013)
WEIGHT_SMOOTH = 4
GLB_EXTRA = {"export_optimize_animation_keep_anim_armature": False, "export_vertex_color": "ACTIVE"}


def _base(name):
    return name.split(".")[0]


def _kind(name):
    b = _base(name)
    return b[:-2] if b.endswith(("_L", "_R")) else b


# ---------------------------------------------------------------- iskelet

def bones(v, head, jaw):
    s, hs = v["body"]["s"], v["body"]["head"]
    pts = {n: p * s for n, (p, _r) in bb.body_points(v["body"]).items()}
    hm, jm = head.matrix_world, jaw.matrix_world
    out = [("root", Vector((0, 0, 0)), Vector((0, 0, 0.25)), None),
           ("pelvis", pts["pelvis"], pts["spine"], "root"),
           ("spine_01", pts["spine"], pts["chest"], "pelvis"),
           ("spine_02", pts["chest"], pts["upchest"], "spine_01"),
           ("spine_03", pts["upchest"], pts["neck0"], "spine_02"),
           ("neck_01", pts["neck0"], pts["neck1"], "spine_03"),
           ("Head", pts["neck1"], hm @ (Vector((0.0, 0.012, 0.13)) * hs), "neck_01"),
           ("jaw", jm.translation.copy(), jm @ (Vector((0.0, -0.074, -0.054)) * hs), "Head")]
    for side, sx in (("l", 1.0), ("r", -1.0)):
        p = {k: pts[f"{k}_{side.upper()}"] for k in ("shoulder", "elbow", "wrist", "fist", "hip", "knee",
                                                     "ankle", "ball", "toe")}
        fwd = (p["toe"] - p["ball"]).normalized()
        out += [(f"clavicle_{side}", pts["upchest"] + Vector((0.06 * sx, 0.0, 0.0)) * s, p["shoulder"], "spine_03"),
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
    pts = {n: p * s for n, (p, _r) in bb.body_points(v["body"]).items()}
    seg["pelvis"] = [(pts["hip_L"], pts["hip_R"])]
    gut_c = bb.gut_sphere(v, bb.body_points(v["body"]))[0] * s
    seg["spine_01"].append((gut_c - Vector((0.0, 0.0, 0.20 * s)), gut_c + Vector((0.0, 0.0, 0.10 * s))))
    return seg


# ---------------------------------------------------------------- parça hazırlığı

def prepare_body(obj, v, ctx):
    zg.decimate(obj, BUDGET["Bloater_Body"])
    _lift(obj, ctx["shells"])
    paint.paint(obj, paint.body_color(ctx["shells"], ctx["skin"], ctx["rashes"]))
    paint.weight_multi(obj, ctx["segments"])
    paint.gut_bias(obj, ctx["gut"], ctx["hip"])
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
    if kind in ("Bloater_Blister", "Bloater_FaceBlister"):
        paint.paint(obj, paint.blister_color(obj), dirt=0.0)
        if kind == "Bloater_Blister":
            paint.copy_weights(obj, ctx["body"], ctx["tree"], obj.matrix_world.translation)
        else:
            zg.weight_to(obj, "Head")
    elif kind == "Bloater_Hand":
        paint.paint(obj, paint.opaque(skin))
        paint.weight_multi(obj, {k: seg[k] for k in (f"lowerarm_{side}", f"hand_{side}")}, keep=2)
    elif kind == "Bloater_Toes":
        paint.paint(obj, paint.opaque(skin))
        zg.weight_to(obj, f"ball_{side}")
    elif kind == "Bloater_Shoe":
        shoe = zg.cloth_color(v["shoes"], stain=(0.04, 0.03, 0.02))
        zg.paint_slots(obj, [shoe, zg.flat_color(SOLE_COLOR)], dirt=0.3)
        paint.weight_multi(obj, {k: seg[k] for k in (f"calf_{side}", f"foot_{side}", f"ball_{side}")})
    elif kind in ("Bloater_Cap", "Bloater_Brim"):
        zg.paint(obj, zg.cloth_color(v["cap"], stain=(0.06, 0.05, 0.04)), dirt=0.3)
        zg.weight_to(obj, "Head")
    elif kind == "Bloater_Head":
        tree = ctx["hair_tree"]
        regions = [(tree, HAIR_REACH, wg.hair_color(v["hair"]))] if tree else []
        zg.paint(obj, zg.layered_color(regions, skin))
        if tree:
            wg.lift_scalp(obj, tree, wg.HAIR_LIFT * v["body"]["head"])
        zg.weight_to(obj, "Head")
    elif kind in ("Bloater_Jaw", "Bloater_Tongue", "Bloater_ToothL"):
        color = {"Bloater_Jaw": skin, "Bloater_Tongue": zg.flat_color(bh.TONGUE_COLOR),
                 "Bloater_ToothL": zg.flat_color(bh.TOOTH_COLOR)}[kind]
        zg.paint(obj, color, dirt=0.4 if kind == "Bloater_Jaw" else 0.0)
        zg.weight_to(obj, "jaw")
    elif kind == "Bloater_Eye":
        zg.paint(obj, zg.flat_color(bh.EYE_COLOR), glow=0.6, dirt=0.0)
        zg.weight_to(obj, "Head")
    else:   # ağız içi, bebek, üst diş
        color = {"Bloater_Mouth": ctx["mouth"], "Bloater_Pupil": zg.flat_color(bh.PUPIL_COLOR)}.get(
            kind, zg.flat_color(bh.TOOTH_COLOR))
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


def _take(objs, kinds):
    out = [o for o in objs if _kind(o.name) in kinds]
    for o in out:
        objs.remove(o)
    return out


def build_variant_game(v, mat):
    objs = _detach(bb.build_variant(v, 0.0, "neutral"))
    find = {_base(o.name): o for o in objs}
    head, jaw, body = find["Bloater_Head"], find["Bloater_Jaw"], find["Bloater_Body"]
    hs, s = v["body"]["head"], v["body"]["s"]
    bone_list = bones(v, head, jaw)
    shells = []
    reach = dict(PAINTED_SHELLS)
    for shell in _take(objs, reach):
        k = _kind(shell.name)
        color = {"Bloater_Bottom": zg.cloth_color(v["bottom_color"], stain=(0.05, 0.04, 0.03)),
                 "Bloater_Belt": zg.flat_color(v.get("belt") or (0.02, 0.02, 0.02)),
                 "Bloater_Apron": zg.cloth_color(v.get("apron") or (0.4, 0.4, 0.4), stain=(0.16, 0.10, 0.05),
                                                 blood=0.7)}.get(k, zg.cloth_color(v["top_color"] or (0, 0, 0),
                                                                                    blood=v["blood"]))
        shells.append((zg.world_bvh(shell), reach[k], color, [n for n, _r in PAINTED_SHELLS].index(k)))
        bpy.data.objects.remove(shell)
    shells = [(t, r, c) for t, r, c, _i in sorted(shells, key=lambda x: x[3])]
    hair_tree = None
    for hair in _take(objs, ("Bloater_Hair",)):
        hair_tree = zg.world_bvh(hair)
        bpy.data.objects.remove(hair)
    rashes = []
    for rash in _take(objs, ("Bloater_Rash",)):
        rashes.append((rash.matrix_world.translation.copy(), max(rash.dimensions) * 0.5))
        bpy.data.objects.remove(rash)
    mouth_at = head.matrix_world @ (Vector((0.0, -0.09, -0.02)) * hs)
    pts = {n: p * s for n, (p, _r) in bb.body_points(v["body"]).items()}
    gut_c, gut_r = bb.gut_sphere(v, bb.body_points(v["body"]))
    ctx = {"segments": body_segments(v, bone_list), "shells": shells, "hair_tree": hair_tree,
           "skin": wg.skin_color(v, mouth_at), "mouth": paint.mouth_color(head, hs), "body": body, "rashes": rashes,
           "gut": (gut_c * s, gut_r * s), "hip": pts["hip_L"]}
    prepare_body(body, v, ctx)
    tree = kdtree.KDTree(len(body.data.vertices))
    for vert in body.data.vertices:
        tree.insert(body.matrix_world @ vert.co, vert.index)
    tree.balance()
    ctx["tree"] = tree
    for obj in objs:
        if obj is not body:
            prepare_part(obj, v, ctx)
    mesh = zg.join([body] + [o for o in objs if o is not body], "Bloater_" + v["name"])
    mesh.data.validate(clean_customdata=False)
    mesh.data.materials.clear()
    mesh.data.materials.append(mat)
    arm = zg.build_armature(RIG_NAME, bone_list)
    zg.bind(mesh, arm)
    return arm, mesh


# ---------------------------------------------------------------- kurulum

def out_path(v):
    return os.path.join(OUT_DIR, "zombie_bloater_%s.glb" % v["name"].lower())


def build_game(names=None):
    kit.reset_scene()
    mat = zg.vertex_color_material("M_Zombie_VC", glow_strength=2.0)
    variants = [v for v in bb.VARIANTS if not names or v["name"] in names]
    report, rigs = {}, []
    for i, v in enumerate(variants):
        arm, mesh = build_variant_game(v, mat)
        clips = anims.build_all(arm)
        zg.export_glb(out_path(v), [arm, mesh], **GLB_EXTRA)
        for name in clips:
            bpy.data.actions.remove(bpy.data.actions[name])
        rigs.append((v["name"], arm, mesh))
        report[v["name"]] = (zg.tri_count(mesh), len(arm.data.bones), round(anims.mesh_height(arm), 3))
        print("BLOATER GAME", v["name"], "tris", report[v["name"]][0], "bones", report[v["name"]][1],
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
    print("BLOATER GAME exported:", report)
    return report


if __name__ != "bloater_game":
    _argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    build_game([a for a in _argv if not a.startswith("-")] or None)
