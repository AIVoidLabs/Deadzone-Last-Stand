"""Zırhlı oyun modeli (7.3): build_armored görünüşünden → zombie_armored_<çeşit>.glb.

Hat tank_game.py ile aynı (ortak iş zombie_game.py'de): incelt → köşe rengi → ağırlık → birleştir →
iskelet → GLB. Farklar:
- Zırh parçalarının köşe rengi malzeme yuvası türünden (armored_mats.assign'ın 'slots' özelliği):
  plastik = renkli mat, kirli, ince açık çizik; metal = parlak çizgili gri, pas lekesi, dışbükey kenarı
  çok açık (aşınmış çelik); kauçuk = düz koyu. Böylece tek renkli gölgelendiricide (zombie_vc) metal ile
  plastik ayrışır. Vizör: 'crack' özniteliğinden açık çatlak çizgileri.
- Katı parçalar: kalkan hand_l'ye (klipte göğse kilitli, armored_anims), önkol koruyucu lowerarm_r'ye, kaval koruyucu calf'a, kask/vizör Head'e tam bağlı;
  omuzluk, diz, cep, göğüs plakası merkezlerine en yakın gövde köşesinin ağırlığını alır.
- Yelek ayrı ağ (kalınlığı okunsun), alt giysi ve pantolon gövdeye boyanır (tank gibi).
- GLB köşe rengi alfası: export_vertex_color="ACTIVE" ile COLOR_0 VEC4 çıkar (MATERIAL kipinde
  dışa aktarıcı alfayı atıyor). Alfa = 1 - parıltı (yalnız gözler).
İskelet: 25 standart kemik + `jaw`. Klipler armored_anims.py (+ armored_falls.py).

    blender --background --python tools/blender/armored_game.py [-- Riot Swat Guard]
Çıktı: assets/models/characters/zombie_armored_<çeşit>.glb, build/blender/armored_game.blend
"""
import importlib
import json
import os
import sys

import bmesh
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
import tank_game as tg  # noqa: E402
import build_armored as ba  # noqa: E402
import armored_body as ab  # noqa: E402
import armored_head as ah  # noqa: E402
import armored_anims as anims  # noqa: E402

for _mod in (ba, ab, ah, anims):
    importlib.reload(_mod)

OUT_DIR = os.path.join(REPO, "assets", "models", "characters")
OUT_BLEND = os.path.join(REPO, "build", "blender", "armored_game.blend")
RIG_NAME = "Armored_Rig"
LINEUP_SPACING = 1.5
BUDGET = {"Armored_Body": 3700, "Armored_Head": 800, "Armored_Jaw": 200, "Armored_Helmet": 640,
          "Armored_Visor": 420, "Armored_Vest": 1100, "Armored_Plate": 160, "Armored_Shield": 820,
          "Armored_Pad": 150, "Armored_Guard": 150, "Armored_Knee": 140, "Armored_Shin": 150,
          "Armored_Boot": 380, "Armored_Fist": 420, "Armored_Pouch": 60, "Armored_Mouth": 90,
          "Armored_Tongue": 40, "Armored_Eye": 24, "Armored_Pupil": 12, "Armored_Bolt": 24,
          "Armored_Top": 4000, "Armored_Bottom": 3000}   # son ikisi yalnız keep_materials (konsept imza) kipinde
PAINTED_SHELLS = (("Armored_Top", 0.030), ("Armored_Bottom", 0.028))
CLOTH_LIFT = 0.006
WEIGHT_SMOOTH = 4
EYE_GLOW = 0.6
CRACK_COLOR = (0.34, 0.36, 0.38)
METAL_EDGE = (0.62, 0.62, 0.64)
GLB_OPTS = {"export_optimize_animation_keep_anim_armature": False, "export_vertex_color": "ACTIVE"}


def _base(name):
    return name.split(".")[0]


def _kind(name):
    b = _base(name)
    return b[:-2] if b.endswith(("_L", "_R")) else b


# ---------------------------------------------------------------- iskelet

def bones(v, head, jaw):
    s, hs = v["body"]["s"], v["body"]["head"]
    pts = {n: p * s for n, (p, _r) in ab.body_points(v["body"]).items()}
    hm, jm = head.matrix_world, jaw.matrix_world
    out = [("root", Vector((0, 0, 0)), Vector((0, 0, 0.25)), None),
           ("pelvis", pts["pelvis"], pts["spine"], "root"),
           ("spine_01", pts["spine"], pts["chest"], "pelvis"),
           ("spine_02", pts["chest"], pts["upchest"], "spine_01"),
           ("spine_03", pts["upchest"], pts["neck0"], "spine_02"),
           ("neck_01", pts["neck0"], pts["neck1"], "spine_03"),
           ("Head", pts["neck1"], hm @ (Vector((0.0, 0.016, 0.13)) * hs), "neck_01"),
           ("jaw", jm.translation.copy(), jm @ (Vector((0.0, -0.074, -0.054)) * hs), "Head")]
    for side, sx in (("l", 1.0), ("r", -1.0)):
        p = {k: pts[f"{k}_{side.upper()}"] for k in ("shoulder", "elbow", "wrist", "fist", "hip", "knee",
                                                     "ankle", "ball", "toe")}
        finger = p["fist"] + (p["fist"] - p["wrist"]).normalized() * 0.05
        fwd = (p["toe"] - p["ball"]).normalized()
        out += [(f"clavicle_{side}", pts["upchest"] + Vector((0.04 * sx, 0.0, 0.0)) * s, p["shoulder"], "spine_03"),
                (f"upperarm_{side}", p["shoulder"], p["elbow"], f"clavicle_{side}"),
                (f"lowerarm_{side}", p["elbow"], p["wrist"], f"upperarm_{side}"),
                (f"hand_{side}", p["wrist"], finger, f"lowerarm_{side}"),
                (f"thigh_{side}", p["hip"], p["knee"], "pelvis"),
                (f"calf_{side}", p["knee"], p["ankle"], f"thigh_{side}"),
                (f"foot_{side}", p["ankle"], p["ball"], f"calf_{side}"),
                (f"ball_{side}", p["ball"], p["toe"] + fwd * 0.05 * s, f"foot_{side}"),
                (f"ball_leaf_{side}", p["toe"] + fwd * 0.05 * s, p["toe"] + fwd * 0.09 * s, f"ball_{side}")]
    return out


def body_segments(v, bone_list):
    seg = {n: [(h, t)] for n, h, t, _ in bone_list if n not in ("root", "jaw", "ball_leaf_l", "ball_leaf_r")}
    s = v["body"]["s"]
    pts = {n: p * s for n, (p, _r) in ab.body_points(v["body"]).items()}
    mid = pts["chest"].lerp(pts["hump"], 0.5)
    seg["spine_02"].append((pts["chest"], mid))
    seg["spine_03"].append((mid, pts["hump"]))
    seg["spine_03"].append((pts["hump"], pts["neck0"]))
    return seg


# ---------------------------------------------------------------- renk

def _hl(c, k, add):
    return tuple(min(1.0, x * k + add) for x in c)


def kind_color(kind, color):
    """Yuva türünden köşe rengi fonksiyonu: (renk_fn, kenar_açma, kenar_rengi)."""
    if kind == "metal":
        def fn(p):
            c = zg._mix(color, _hl(color, 1.7, 0.06), zg._smooth(0.45, 0.75, zg.fbm(p * Vector((1, 1, 6)), 9.0)))
            return zg._mix(c, (0.15, 0.06, 0.025), 0.8 * zg._smooth(0.66, 0.80, zg.fbm(p + Vector((3, 1, 2)), 5.0)))
        return fn, 0.75, METAL_EDGE
    if kind == "plastic":
        def fn(p):
            c = zg._mix(color, tuple(x * 0.55 for x in color), zg._smooth(0.50, 0.80, zg.fbm(p, 5.0)))
            return zg._mix(c, _hl(color, 2.2, 0.07), 0.8 * zg._smooth(0.70, 0.78, zg.fbm(p, 38.0)))
        return fn, 0.25, _hl(color, 2.2, 0.07)
    if kind == "rubber":
        return (lambda p: zg._mix(color, tuple(x * 0.6 for x in color), zg._smooth(0.5, 0.8, zg.fbm(p, 6.0)))), 0.1, \
            _hl(color, 2.0, 0.03)
    if kind == "visor":
        return zg.flat_color(color), 0.0, color
    return zg.cloth_color(color, stain=(0.05, 0.04, 0.03)), 0.0, color


def paint_armor(obj, dirt=0.35):
    """Yuva türlerine göre köşe rengi; dışbükey kenarlar türün kenar rengine açılır (aşınma)."""
    slots = json.loads(obj["slots"])
    fns = [kind_color(k, tuple(c)) for k, c in slots]
    mesh = obj.data
    votes = [[0] * len(fns) for _ in mesh.vertices]
    for poly in mesh.polygons:
        for vi in poly.vertices:
            votes[vi][min(poly.material_index, len(fns) - 1)] += 1
    crack = mesh.attributes.get("crack")
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.normal_update()
    curv = []
    for vert in bm.verts:
        if vert.link_edges:
            avg = sum((e.other_vert(vert).co for e in vert.link_edges), Vector()) / len(vert.link_edges)
            curv.append((avg - vert.co).dot(vert.normal) * 120.0)
        else:
            curv.append(0.0)
    bm.free()
    attr = mesh.color_attributes.get(zg.COLOR_ATTR) or mesh.color_attributes.new(zg.COLOR_ATTR, "FLOAT_COLOR", "POINT")
    mw = obj.matrix_world
    for i, vert in enumerate(mesh.vertices):
        slot = max(range(len(fns)), key=lambda s, row=votes[i]: row[s])
        fn, edge_k, edge_c = fns[slot]
        c = fn(mw @ vert.co)
        k = curv[i]
        if k < 0.0:
            c = zg._mix(c, edge_c, edge_k * min(-k, 1.0))
        else:
            c = tuple(x * (1.0 - dirt * min(k, 1.0)) for x in c)
        if crack is not None:
            c = zg._mix(c, CRACK_COLOR, min(crack.data[i].value * 1.3, 1.0))
        attr.data[i].color = (*c, 1.0)


# ---------------------------------------------------------------- parça hazırlığı

def _center(obj):
    mw = obj.matrix_world
    return sum((mw @ v.co for v in obj.data.vertices), Vector()) / max(len(obj.data.vertices), 1)


RIGID = {"Armored_Shield": "hand_l", "Armored_Guard": "lowerarm_r", "Armored_Helmet": "Head",
         "Armored_Visor": "Head", "Armored_Bolt": "Head"}
NEAREST = ("Armored_Pad", "Armored_Knee", "Armored_Pouch", "Armored_Plate")


def prepare_part(obj, v, ctx, keep_materials=False):
    kind, base = _kind(obj.name), _base(obj.name)
    side = base[-1].lower() if base.endswith(("_L", "_R")) else ""
    if kind in BUDGET:
        zg.decimate(obj, BUDGET[kind])
    seg, skin = ctx["segments"], ctx["skin"]
    if "slots" in obj.keys():
        paint_armor(obj)
    if kind in RIGID:
        zg.weight_to(obj, RIGID[kind])
    elif kind == "Armored_Shin":
        c = _center(obj)
        zg.weight_to(obj, "calf_l" if c.x > 0 else "calf_r")
    elif kind in NEAREST:
        tg.copy_weights(obj, ctx["body"], ctx["tree"], _center(obj))
    elif kind == "Armored_Vest" or kind in dict(PAINTED_SHELLS):
        tg.weight_multi(obj, {k: s for k, s in seg.items() if not k.startswith(("hand", "lowerarm", "Head"))})
        zg.smooth_weights(obj, 2)
    elif kind == "Armored_Fist":
        tg.weight_multi(obj, {k: seg[k] for k in (f"lowerarm_{side}", f"hand_{side}")}, keep=2)
    elif kind == "Armored_Boot":
        tg.weight_multi(obj, {k: seg[k] for k in (f"calf_{side}", f"foot_{side}", f"ball_{side}")})
    elif kind == "Armored_Head":
        zg.paint(obj, skin)
        zg.weight_to(obj, "Head")
    elif kind in ("Armored_Jaw", "Armored_Tongue", "Armored_ToothL"):
        color = {"Armored_Jaw": skin, "Armored_Tongue": zg.flat_color(ah.TONGUE_COLOR),
                 "Armored_ToothL": zg.flat_color(ah.TOOTH_COLOR)}[kind]
        zg.paint(obj, color, dirt=0.4 if kind == "Armored_Jaw" else 0.0)
        zg.weight_to(obj, "jaw")
    else:
        color = {"Armored_Mouth": zg.flat_color(ah.MOUTH_BACK), "Armored_Eye": zg.flat_color(ah.EYE_COLOR),
                 "Armored_Pupil": zg.flat_color(ah.PUPIL_COLOR)}.get(kind, zg.flat_color(ah.TOOTH_COLOR))
        zg.paint(obj, color, glow=EYE_GLOW if kind == "Armored_Eye" else 0.0, dirt=0.0)
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


def build_variant_game(v, mat, keep_materials=False):
    objs = _detach(ba.build_variant(v, 0.0, "neutral"))
    find = {_base(o.name): o for o in objs}
    head, jaw = find["Armored_Head"], find["Armored_Jaw"]
    bone_list = bones(v, head, jaw)
    shells = []
    if not keep_materials:
        for shell in [o for o in objs if _kind(o.name) in dict(PAINTED_SHELLS)]:
            slots = json.loads(shell["slots"])
            shells.append((zg.world_bvh(shell), dict(PAINTED_SHELLS)[_kind(shell.name)],
                           zg.cloth_color(tuple(slots[0][1]), stain=(0.05, 0.04, 0.03), blood=0.3)))
            objs.remove(shell)
            bpy.data.objects.remove(shell)
    mouth_at = head.matrix_world @ (Vector((0.0, -0.085, -0.02)) * v["body"]["head"])
    body = find["Armored_Body"]
    ctx = {"segments": body_segments(v, bone_list), "skin": wg.skin_color(v, mouth_at), "body": body}
    zg.decimate(body, BUDGET["Armored_Body"])
    tg.lift_cloth(body, shells)
    zg.paint(body, zg.layered_color(shells, ctx["skin"]))
    tg.weight_multi(body, ctx["segments"])
    zg.smooth_weights(body, WEIGHT_SMOOTH)
    tree = kdtree.KDTree(len(body.data.vertices))
    for vert in body.data.vertices:
        tree.insert(body.matrix_world @ vert.co, vert.index)
    tree.balance()
    ctx["tree"] = tree
    for obj in objs:
        if obj is not body:
            prepare_part(obj, v, ctx, keep_materials)
    mesh = zg.join([body] + [o for o in objs if o is not body], "Armored_" + v["name"])
    mesh.data.validate(clean_customdata=False)
    if not keep_materials:
        mesh.data.materials.clear()
        mesh.data.materials.append(mat)
        cols = mesh.data.color_attributes
        cols.active_color = cols[zg.COLOR_ATTR]
        cols.render_color_index = cols.find(zg.COLOR_ATTR)
    arm = zg.build_armature(RIG_NAME, bone_list)
    zg.bind(mesh, arm)
    return arm, mesh


def out_path(v):
    return os.path.join(OUT_DIR, "zombie_armored_%s.glb" % v["name"].lower())


def build_game(names=None):
    kit.reset_scene()
    mat = zg.vertex_color_material("M_Zombie_VC", glow_strength=2.0)
    variants = [v for v in ba.VARIANTS if not names or v["name"] in names]
    report, rigs = {}, []
    for i, v in enumerate(variants):
        arm, mesh = build_variant_game(v, mat)
        clips = anims.build_all(arm)
        zg.export_glb(out_path(v), [arm, mesh], **GLB_OPTS)
        for name in clips:
            bpy.data.actions.remove(bpy.data.actions[name])
        rigs.append((v["name"], arm, mesh))
        report[v["name"]] = (zg.tri_count(mesh), len(arm.data.bones), round(anims.mesh_height(arm), 3))
        print("ARMORED GAME", v["name"], "tris", report[v["name"]][0], "bones", report[v["name"]][1],
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
    print("ARMORED GAME exported:", report)
    return report


if __name__ != "armored_game":
    _argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    build_game([a for a in _argv if not a.startswith("-")] or None)
