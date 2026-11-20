"""Zıplayan oyun modeli (Aşama V.5, v2): build_jumper görünüşünden → zombie_jumper_<çeşit>.glb.

Hat walker_game / dilci_game ile aynı (ortak iş zombie_game.py'de): incelt → köşe rengi → ağırlık →
birleştir → iskelet → GLB. Farklar:
- Kıyafet ayrı kabuk kalır (dilci gibi; kenar, bel bandı, paça rulosu, şerit kumaş gibi okunsun).
- Çeşitlerin boyu ve genişliği farklı: her çeşit kendi iskeletiyle kendi GLB'sine (aynı kemik adları,
  aynı "Jumper_Rig" düğümü). Eski zombie_jumper.glb'ye dokunulmaz (oyunda kullanılıyor).
- İskelet: 25 standart kemik + `jaw` (hırlayan çene).
Dinlenme pozu konseptin "stand" pozu (yarı çömelik, kambur). Klipler jumper_anims.py (+ jumper_falls.py).

Çalıştırma (arka plan ya da Blender MCP):
    blender --background --python tools/blender/jumper_game.py
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
import jumper_head as jh  # noqa: E402
import build_jumper as bj  # noqa: E402
import jumper_anims as anims  # noqa: E402

for _mod in (kit, zg, jh, bj, anims):
    importlib.reload(_mod)

OUT_DIR = os.path.join(REPO, "assets", "models", "characters")
OUT_BLEND = os.path.join(REPO, "build", "blender", "jumper_game.blend")
RIG_NAME = "Jumper_Rig"
LINEUP_SPACING = 1.15
# Parça başına üçgen hedefi (çeşit başına toplam ~11–14.5 bin). Kıyafet solidify ile çift kat.
BUDGET = {"Jumper_Body": 7200, "Jumper_Head": 1500, "Jumper_Jaw": 320, "Jumper_Mouth": 160,
          "Jumper_Tongue": 48, "Jumper_Gum": 64, "Jumper_Eye": 40,
          "Jumper_Bottom": 2000, "Jumper_Top": 2000, "Jumper_Bib": 900, "Jumper_Pocket": 120,
          "Jumper_Band": 320, "Jumper_Cuff": 320, "Jumper_Stripe": 420}
CLOTH = ("Jumper_Top", "Jumper_Bib", "Jumper_Pocket", "Jumper_Bottom", "Jumper_Band", "Jumper_Cuff",
         "Jumper_Stripe")
TEETH_COLOR = (0.45, 0.40, 0.28)
EYE_GLOW = 0.25           # sarı gözde hafif parıltı (alfa = 1 - parıltı)
WEIGHT_SMOOTH = 4
CLOTH_WEIGHT_SMOOTH = 8   # kalça kıvrımında kumaş gerilip yelken gibi açılmasın


def _base(name: str) -> str:
    return name.split(".")[0]


def bones(v, head, jaw) -> list:
    """[(ad, baş, uç, ebeveyn)] — "stand" pozunda dinlenme."""
    pts = {n: p for n, (p, _r) in bj.body_points(v["body"], "stand").items()}
    s = v["body"]["head"]
    hm, jm = head.matrix_world, jaw.matrix_world
    out = [("root", Vector((0, 0, 0)), Vector((0, 0, 0.25)), None),
           ("pelvis", pts["pelvis"], pts["spine"], "root"),
           ("spine_01", pts["spine"], pts["chest"], "pelvis"),
           ("spine_02", pts["chest"], pts["upchest"], "spine_01"),
           ("spine_03", pts["upchest"], pts["neck0"], "spine_02"),
           ("neck_01", pts["neck0"], pts["neck1"], "spine_03"),
           ("Head", pts["neck1"], hm @ (Vector((0.0, 0.010, 0.150)) * s), "neck_01"),
           ("jaw", jm.translation.copy(), jm @ (Vector((0.0, -0.080, -0.054)) * s), "Head")]
    for side, sx in (("l", 1.0), ("r", -1.0)):
        p = {k: pts[f"{k}_{side.upper()}"] for k in ("shoulder", "elbow", "wrist", "palm", "hip",
                                                     "knee", "ankle", "ball")}
        finger = p["palm"] + (p["palm"] - p["wrist"]).normalized() * 0.060
        fwd = Vector(((p["ball"] - p["ankle"]).x * 0.2, (p["ball"] - p["ankle"]).y, 0.0)).normalized()
        toe = p["ball"] + fwd * 0.055 + Vector((0.0, 0.0, -0.012))
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


def body_segments(bone_list) -> dict:
    skip = ("root", "jaw", "ball_leaf_l", "ball_leaf_r")
    return {name: (head, tail) for name, head, tail, _ in bone_list if name not in skip}


def skin_color(v):
    lo, hi = v["bruise_band"]
    return lambda p: zg._mix(v["tone"], v["bruise"], zg._smooth(lo, hi, zg.fbm(p, 6.0)))


def mouth_color(head, s):
    inv = head.matrix_world.inverted()
    y0 = (jh.MOUTH_CENTER.y - jh.MOUTH_RADII.y * 0.2) * s
    y1 = (jh.MOUTH_CENTER.y + jh.MOUTH_RADII.y) * s

    def fn(p):
        t = min(max(((inv @ p).y - y0) / (y1 - y0) / 0.85, 0.0), 1.0)
        return zg._mix(jh.MOUTH_FRONT, jh.MOUTH_BACK, t)
    return fn


def cloth_fn(name, v):
    blood = v["blood"]
    if name == "Jumper_Top":
        return zg.cloth_color(v["top_color"], blood=blood)
    if name == "Jumper_Bib":
        return zg.cloth_color(v["bib"], blood=blood)
    if name == "Jumper_Pocket":
        return zg.cloth_color(tuple(c * 0.7 for c in v["bib"]))
    if name == "Jumper_Stripe":
        return zg.cloth_color(v["stripe"], stain=(0.20, 0.18, 0.15))
    if name in ("Jumper_Band", "Jumper_Cuff"):
        return zg.cloth_color(tuple(c * 0.8 for c in v["bottom_color"]), stain=(0.05, 0.04, 0.03))
    return zg.cloth_color(v["bottom_color"], stain=(0.05, 0.04, 0.03), blood=blood * 0.4)


def transfer_weights(body, cloth, k: int = 4) -> None:
    """Kumaş ağırlığı gövdeden: her köşe en yakın k gövde köşesinin ağırlık ortalamasını alır. Kumaş
    kendi uzaklık ağırlığıyla kalçada pelvis'e takılıp sıçramada yelken gibi geriliyordu."""
    from mathutils.kdtree import KDTree
    mw_b, mw_c = body.matrix_world, cloth.matrix_world
    tree = KDTree(len(body.data.vertices))
    for vt in body.data.vertices:
        tree.insert(mw_b @ vt.co, vt.index)
    tree.balance()
    names = [g.name for g in body.vertex_groups]
    groups = {n: cloth.vertex_groups.get(n) or cloth.vertex_groups.new(name=n) for n in names}
    for vt in cloth.data.vertices:
        acc = {}
        for _co, idx, dist in tree.find_n(mw_c @ vt.co, k):
            w = 1.0 / max(dist, 1e-4)
            for ge in body.data.vertices[idx].groups:
                acc[ge.group] = acc.get(ge.group, 0.0) + ge.weight * w
        total = sum(acc.values()) or 1.0
        for g, wsum in acc.items():
            groups[names[g]].add([vt.index], wsum / total, "REPLACE")


def prepare_part(obj, v, ctx) -> None:
    """Parçayı inceltir, boyar, ağırlıklar. Ad ve ebeveynden rolü çıkarır."""
    name = _base(obj.name)
    parent = _base(obj.parent.name) if obj.parent else ""
    if name in BUDGET:
        zg.decimate(obj, BUDGET[name])
    skin = ctx["skin"]
    if name == "Jumper_Body":
        zg.paint(obj, skin)
        zg.weight_by_distance(obj, ctx["segments"])
        zg.smooth_weights(obj, WEIGHT_SMOOTH)
        ctx["body"] = obj
    elif name in CLOTH:
        zg.paint(obj, cloth_fn(name, v), dirt=0.3)
        transfer_weights(ctx["body"], obj)
        zg.smooth_weights(obj, CLOTH_WEIGHT_SMOOTH)
    elif name == "Jumper_Head":
        fns = [skin] + ([zg.cloth_color(v["scalp"], stain=(0.01, 0.01, 0.01))] if v["scalp"] else [])
        zg.paint_slots(obj, fns)
        zg.weight_to(obj, "Head")
    elif name in ("Jumper_Jaw", "Jumper_Tongue", "Jumper_ToothL"):
        color = {"Jumper_Jaw": skin, "Jumper_Tongue": zg.flat_color(jh.TONGUE_COLOR),
                 "Jumper_ToothL": zg.flat_color(TEETH_COLOR)}[name]
        zg.paint(obj, color, dirt=0.45 if name == "Jumper_Jaw" else 0.0)
        zg.weight_to(obj, "jaw")
    elif name == "Jumper_Mouth":
        zg.paint(obj, ctx["mouth"], dirt=0.0)
        zg.weight_to(obj, "Head")
    elif name == "Jumper_Eye":
        zg.paint(obj, zg.flat_color(jh.EYE_COLOR), glow=EYE_GLOW, dirt=0.0)
        zg.weight_to(obj, "Head")
    elif name == "Jumper_Gum":
        zg.paint(obj, zg.flat_color(jh.GUM_COLOR), dirt=0.0)
        zg.weight_to(obj, "Head")
    elif name == "Jumper_ToothU":
        zg.paint(obj, zg.flat_color(TEETH_COLOR), dirt=0.0)
        zg.weight_to(obj, "jaw" if parent == "Jumper_Jaw" else "Head")


def build_variant_game(v, mat):
    """Bir çeşidi kurar, oyuna hazırlar; (iskelet, ağ) döner. Nesneler dünya kökünde."""
    root = bj.build_variant(v, 0.0, "stand")
    # gövde önce (kumaş ağırlığını ondan alır), sonra ad sırası (birleştirme ve GLB sırası sabit)
    objs = sorted((o for o in root.children_recursive if o.type == "MESH"),
                  key=lambda o: (_base(o.name) != "Jumper_Body", o.name))
    bpy.data.objects.remove(root)
    bpy.context.view_layer.update()
    head = next(o for o in objs if _base(o.name) == "Jumper_Head")
    jaw = next(o for o in objs if _base(o.name) == "Jumper_Jaw")
    bone_list = bones(v, head, jaw)
    ctx = {"segments": body_segments(bone_list), "skin": skin_color(v),
           "mouth": mouth_color(head, v["body"]["head"])}
    for obj in objs:
        prepare_part(obj, v, ctx)
    mesh = zg.join(objs, "Jumper_" + v["name"])
    mesh.data.validate(clean_customdata=False)
    mesh.data.materials.clear()
    mesh.data.materials.append(mat)
    arm = zg.build_armature(RIG_NAME, bone_list)
    zg.bind(mesh, arm)
    return arm, mesh


def out_path(v) -> str:
    return os.path.join(OUT_DIR, "zombie_jumper_%s.glb" % v["name"].lower())


GLB_ANIM = {"export_optimize_animation_keep_anim_armature": False}


def build_game(variants=None) -> dict:
    kit.reset_scene()
    mat = zg.vertex_color_material("M_Zombie_VC", glow_strength=2.0)
    variants = variants or bj.VARIANTS
    report, rigs = {}, []
    for i, v in enumerate(variants):
        arm, mesh = build_variant_game(v, mat)
        clips = anims.build_all(arm)
        zg.export_glb(out_path(v), [arm, mesh], **GLB_ANIM)
        for name in clips:          # dışa aktarıcı uyumlu tüm actionları alır: sıradaki çeşide karışmasın
            bpy.data.actions.remove(bpy.data.actions[name])
        h = max((mesh.matrix_world @ vt.co).z for vt in mesh.data.vertices)
        report[v["name"]] = (zg.tri_count(mesh), len(arm.data.bones), round(h, 3))
        print("JUMPER GAME", v["name"], "tris", report[v["name"]][0], "bones", report[v["name"]][1],
              "height", report[v["name"]][2])
        arm.name = "%s_%s" % (RIG_NAME, v["name"])
        arm.data.name = arm.name
        arm.location.x = (i - (len(variants) - 1) / 2) * LINEUP_SPACING
        rigs.append(arm)
    anims.build_all(rigs[0])        # inceleme kopyası: ilk çeşidin klipleri .blend'de (kare özeti)
    kit.setup_look()
    os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    print("JUMPER GAME exported:", report)
    return report


if __name__ != "jumper_game":
    build_game()
