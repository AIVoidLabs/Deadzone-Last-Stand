"""Yürüyen oyun modeli (Aşama V.5): build_walker görünüşünden → zombie_walker_<çeşit>.glb.

Hat dilci_game.py ile aynı (ortak iş zombie_game.py'de): incelt → köşe rengi → ağırlık →
birleştir → iskelet → GLB. Farklar:
- Kıyafet (üst, yelek, alt) ayrı kabuk değil: rengi gövdenin kendi köşelerine boyanır, kabuk silinir.
  Yalnız kravat (ince, siluete katkı) ve ayakkabılar ayrı parça kalır.
- Çeşitlerin boyu ve omuz genişliği farklı (h 0.90–1.06, w 0.86–1.22), eklemler çakışmaz. Bu yüzden
  her çeşit kendi iskeletiyle kendi GLB'sine gider (aynı kemik adları, aynı "Walker_Rig" düğümü).
- İskelet: 25 standart kemik + `jaw` (sarkık tek parça çene, imza; ısırma/inleme için).
Dinlenme pozu konseptin pozu (ağırlık sağda, sol omuz düşük, kollar yarı kalkık öne).
Klipler walker_anims.py (+ walker_falls.py, çekirdek walker_pose.py): her çeşidin kendi iskeletine
ayrı anahtarlanır ve kendi GLB'sine (AnimationPlayer) gider; dışa aktarımdan sonra actionlar çeşit ekiyle
yeniden adlandırılır, böylece sıradaki çeşit aynı klip adlarını alır ve yalnız kendi kliplerini taşır.

Çalıştırma (Blender MCP içinden):
    exec(open(r"<repo>/tools/blender/walker_game.py", encoding="utf-8").read())
Ağırlık testi: import walker_game as wg; wg.test_pose(rig) / wg.reset_pose(rig)
"""
import importlib
import os
import sys

import bpy
from mathutils import Quaternion, Vector

_HERE = globals().get("__file__", "")
REPO = os.path.abspath(os.path.join(os.path.dirname(_HERE), "..", "..")) if _HERE else ""
if not REPO or not os.path.isdir(os.path.join(REPO, "tools")):
    REPO = r"C:\Users\pekta\projeler\Deadzone-Last-Stand"
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import zombie_kit as kit  # noqa: E402
import zombie_game as zg  # noqa: E402
import walker_head as wh  # noqa: E402
import walker_clothes as wc  # noqa: E402
import build_walker as bw  # noqa: E402
import walker_pose as wpose  # noqa: E402
import walker_anims as anims  # noqa: E402

for _mod in (kit, zg, wh, wc, bw, wpose, anims):
    importlib.reload(_mod)

OUT_DIR = os.path.join(REPO, "assets", "models", "characters")
OUT_BLEND = os.path.join(REPO, "build", "blender", "walker_game.blend")
RIG_NAME = "Walker_Rig"
LINEUP_SPACING = 1.05     # .blend içinde çeşitler yan yana (GLB'de hepsi kökte)

# Parça başına üçgen hedefi (çeşit başına toplam ~3.6–4.4 bin).
BUDGET = {"Walker_Body": 2750, "Walker_Head": 700, "Walker_Jaw": 130, "Walker_Mouth": 60,
          "Walker_Tongue": 24, "Walker_Eye": 24, "Walker_Tie": 60, "Walker_Shoe_L": 140,
          "Walker_Shoe_R": 140, "Walker_ToothU": 6, "Walker_ToothL": 6}
# Saç: konseptin ince tutamları incelince kırık kıymık oluyor. Oyunda saç = kafa derisinde
# hafif kabarık renk bölgesi (HAIR_LIFT) + yalnız uzun saçta az sayıda düşük çözünürlüklü tutam.
HAIR_LIFT = 0.0060        # saç kütlesi kalınlığı (m, kafa ölçeği 1)
GAME_LOCKS = {"long": 12}  # üslup -> oyun tutamı sayısı (3 köşeli kesit, alt bölümleme yok)
GAME_LOCK_WIDTH = 1.9     # az tutam boşluk bırakmasın: konsept genişliğinin katı
GAME_LOCK_RING = 3
# Gövdeye boyanıp silinen kabuklar: ad -> erişim (m, kabuk ofseti + kalınlık + pay). Sıra = öncelik.
PAINTED_SHELLS = (("Walker_Vest", 0.040), ("Walker_Top", 0.022), ("Walker_Bottom", 0.020))
HAIR_REACH = 0.012        # kafa derisinde saç tabanı rengi
TEETH_COLOR = (0.45, 0.40, 0.28)
EYE_COLOR = (0.30, 0.31, 0.27)   # donuk süt beyazı, parıltı yok (konsept)
SOLE_COLOR = (0.015, 0.014, 0.013)
BLOOD_COLOR = (0.10, 0.010, 0.012)
MOUTH_BLOOD = 0.85
TORSO_SMOOTH = 8          # göğüs-karın yumuşatma turu (0 = kapalı)
WEIGHT_SMOOTH = 4         # gövde ağırlığı yumuşatma turu (0 = yalnız uzaklık; eklemde yırtılma bandı)        # ağız çevresi kan izi gücü (0 = yok)


def _base(name: str) -> str:
    return name.split(".")[0]


# ---------------------------------------------------------------- iskelet

def bones(v, head, jaw) -> list:
    """[(ad, baş, uç, ebeveyn)] — konseptin pozunda dinlenme. Kafa ve çene nesnelerinden."""
    pts = {n: p for n, (p, _r) in bw.body_points(v["body"]).items()}
    s = v["body"]["head"]
    hm, jm = head.matrix_world, jaw.matrix_world
    out = [("root", Vector((0, 0, 0)), Vector((0, 0, 0.25)), None),
           ("pelvis", pts["pelvis"], pts["spine"], "root"),
           ("spine_01", pts["spine"], pts["chest"], "pelvis"),
           ("spine_02", pts["chest"], pts["upchest"], "spine_01"),
           ("spine_03", pts["upchest"], pts["neck0"], "spine_02"),
           ("neck_01", pts["neck0"], pts["neck1"], "spine_03"),
           ("Head", pts["neck1"], hm @ (Vector((0.0, 0.012, 0.158)) * s), "neck_01"),
           ("jaw", jm.translation.copy(), jm @ (Vector((0.0, -0.072, -0.048)) * s), "Head")]
    for side, sx in (("l", 1.0), ("r", -1.0)):
        p = {k: pts[f"{k}_{side.upper()}"] for k in ("shoulder", "elbow", "wrist", "palm", "hip",
                                                     "knee", "ankle", "ball", "toe")}
        finger = p["palm"] + (p["palm"] - p["wrist"]).normalized() * 0.075
        fwd = (p["toe"] - p["ball"]).normalized()
        out += [(f"clavicle_{side}", pts["upchest"] + Vector((0.04 * sx, 0.0, 0.0)), p["shoulder"], "spine_03"),
                (f"upperarm_{side}", p["shoulder"], p["elbow"], f"clavicle_{side}"),
                (f"lowerarm_{side}", p["elbow"], p["wrist"], f"upperarm_{side}"),
                (f"hand_{side}", p["wrist"], finger, f"lowerarm_{side}"),
                (f"thigh_{side}", p["hip"], p["knee"], "pelvis"),
                (f"calf_{side}", p["knee"], p["ankle"], f"thigh_{side}"),
                (f"foot_{side}", p["ankle"], p["ball"], f"calf_{side}"),
                (f"ball_{side}", p["ball"], p["toe"], f"foot_{side}"),
                (f"ball_leaf_{side}", p["toe"], p["toe"] + fwd * 0.04, f"ball_{side}")]
    return out


def body_segments(bone_list) -> dict:
    skip = ("root", "jaw", "ball_leaf_l", "ball_leaf_r")
    return {name: (head, tail) for name, head, tail, _ in bone_list if name not in skip}


def _subset(segments, prefixes) -> dict:
    return {k: ab for k, ab in segments.items() if k.startswith(prefixes)}


# ---------------------------------------------------------------- renk

def skin_color(v, mouth):
    """Konseptin ten malzemesi (morluk koyu uçta, Skinny'de dar bant) + ağızdan sızan kan."""
    tone, bruise = v["tone"], v["bruise"]
    lo, hi = v.get("bruise_band", (0.42, 0.68))

    def fn(p):
        c = zg._mix(tone, bruise, zg._smooth(lo, hi, zg.fbm(p, 6.0)))
        if MOUTH_BLOOD > 0.0:
            d = p - mouth
            if d.z < 0.0:
                d.z *= 0.45            # aşağı akar (çene, boyun)
            w = (1.0 - zg._smooth(0.025, 0.085, d.length)) * zg._smooth(0.30, 0.55, zg.fbm(p, 9.0))
            c = zg._mix(c, BLOOD_COLOR, w * MOUTH_BLOOD)
        return c
    return fn


def hair_color(color):
    light = tuple(min(1.0, c * 1.6 + 0.005) for c in color)
    return lambda p: zg._mix(color, light, zg._smooth(0.40, 0.80, zg.fbm(p, 40.0)))


def mouth_color(head, s):
    """Ağız içi: önde koyu kırmızı-kahve, arkaya (kafa yereli +Y) koyulaşır (walker_head ile aynı)."""
    inv = head.matrix_world.inverted()
    y0 = wh.MOUTH_CENTER.y * s - wh.MOUTH_RADII.y * s * 0.2
    y1 = wh.MOUTH_CENTER.y * s + wh.MOUTH_RADII.y * s

    def fn(p):
        t = min(max(((inv @ p).y - y0) / (y1 - y0) / 0.85, 0.0), 1.0)
        return zg._mix(wh.MOUTH_FRONT, wh.MOUTH_BACK, t)
    return fn


# ---------------------------------------------------------------- parça hazırlığı

def prepare_part(obj, v, ctx) -> None:
    """Parçayı inceltir, boyar, ağırlıklar. Ad ve ebeveynden rolü çıkarır."""
    name = _base(obj.name)
    parent = _base(obj.parent.name) if obj.parent else ""
    if name in BUDGET:
        zg.decimate(obj, BUDGET[name])
    skin = ctx["skin"]
    if name == "Walker_Body":
        smooth_torso(obj, ctx["segments"])
        regions = [(tree, reach, fn) for tree, reach, fn in ctx["shells"]]
        zg.paint(obj, zg.layered_color(regions, skin))
        zg.weight_by_distance(obj, ctx["segments"])
        zg.smooth_weights(obj, WEIGHT_SMOOTH)
    elif name == "Walker_Tie":
        zg.paint(obj, zg.cloth_color(v["tie"]), dirt=0.2)
        zg.weight_by_distance(obj, _subset(ctx["segments"], ("spine", "pelvis", "neck")))
    elif name.startswith("Walker_Shoe"):
        shoe = zg.cloth_color(v["shoes"], stain=(0.04, 0.03, 0.02))
        zg.paint_slots(obj, [shoe, zg.flat_color(SOLE_COLOR)], dirt=0.3)
        zg.weight_by_distance(obj, _subset(ctx["segments"], ("calf", "foot", "ball")))
    elif name == "Walker_Head":
        tree = ctx["hair_tree"]
        regions = [(tree, HAIR_REACH, hair_color(v["hair"]))] if tree else []
        zg.paint(obj, zg.layered_color(regions, skin))
        if tree:
            lift_scalp(obj, tree, HAIR_LIFT * v["body"]["head"])
        zg.weight_to(obj, "Head")
    elif name == "Walker_Hair":
        zg.paint(obj, hair_color(v["hair"]), dirt=0.3)
        zg.weight_to(obj, "Head")
    elif name == "Walker_Jaw":
        zg.paint(obj, skin)
        zg.weight_to(obj, "jaw")
    elif name == "Walker_Mouth":
        zg.paint(obj, ctx["mouth"], dirt=0.0)
        zg.weight_to(obj, "Head")
    elif name == "Walker_Tongue":
        zg.paint(obj, zg.flat_color(wh.TONGUE_COLOR), dirt=0.0)
        zg.weight_to(obj, "jaw")
    elif name == "Walker_Eye":
        zg.paint(obj, zg.flat_color(EYE_COLOR), dirt=0.0)
        zg.weight_to(obj, "Head")
    elif name.startswith("Walker_Tooth"):
        zg.paint(obj, zg.flat_color(TEETH_COLOR), dirt=0.0)
        zg.weight_to(obj, "jaw" if parent == "Walker_Jaw" else "Head")


def _seg_dist(p, a, b) -> float:
    ab = b - a
    t = min(max((p - a).dot(ab) / max(ab.length_squared, 1e-9), 0.0), 1.0)
    return (p - (a + ab * t)).length


def smooth_torso(body, segments) -> None:
    """Gövde ortasını (göğüs-karın) yumuşatır. Konseptte kıyafet kabuğunun altında kalan göğüs
    altı basamağı, kıyafet gövdeye boyanınca görünür oluyordu. Uzuvlar ve el korunur."""
    if TORSO_SMOOTH <= 0:
        return
    group = body.vertex_groups.new(name="_smooth")
    spine = [segments[k] for k in ("spine_01", "spine_02")]
    other = [ab for k, ab in segments.items() if not k.startswith(("spine", "pelvis", "neck"))]
    mw = body.matrix_world
    for v in body.data.vertices:
        p = mw @ v.co
        d_spine = min(_seg_dist(p, a, b) for a, b in spine)
        d_other = min(_seg_dist(p, a, b) for a, b in other)
        w = min(max((d_other - d_spine) / 0.06 + 0.3, 0.0), 1.0)
        if w > 0.0:
            group.add([v.index], w, "REPLACE")
    mod = body.modifiers.new("TorsoSmooth", "SMOOTH")
    mod.factor = 0.8
    mod.iterations = TORSO_SMOOTH
    mod.vertex_group = group.name
    kit.apply_all(body)
    body.vertex_groups.remove(body.vertex_groups["_smooth"])


def lift_scalp(head, tree, lift) -> None:
    """Saç bölgesindeki kafa köşelerini normal boyunca kabartır (saç kütlesi, kask kenarı yok)."""
    mw = head.matrix_world
    for vert in head.data.vertices:
        if tree.find_nearest(mw @ vert.co, HAIR_REACH)[0] is not None:
            vert.co += vert.normal * lift


def game_locks(head, hair_tree, v, style, count):
    """Uzun saç için az sayıda düşük çözünürlüklü tutam (walker_head tutam omurgasıyla).
    Kökler konsept saçının kapladığı kafa yüzlerinden seçilir. Kafa incelmeden önce çağrılır."""
    import random
    import bmesh
    s = v["body"]["head"]
    rng = random.Random(int(v["seed"] * 1000) + 17)
    mw = head.matrix_world
    roots = [(p.center.copy(), p.normal.copy()) for p in head.data.polygons
             if p.normal.z > -0.3 and hair_tree.find_nearest(mw @ p.center, HAIR_REACH)[0] is not None]
    if not roots or count <= 0:
        return None
    rng.shuffle(roots)
    roots = sorted(roots[:count * 8], key=lambda r: (r[0].x, r[0].y))[::8][:count]
    bm = bmesh.new()
    ring, wh.LOCK_RING = wh.LOCK_RING, GAME_LOCK_RING
    try:
        for co, n in roots:
            path = wh._lock_path(head, co, n, s, style, rng)
            k = rng.uniform(0.85, 1.15)
            wh._add_lock(bm, path, style["width"] * s * k * GAME_LOCK_WIDTH, style["thick"] * s * k * 1.4,
                         style["base"] * s * 1.5)
    finally:
        wh.LOCK_RING = ring
    mesh = bpy.data.meshes.new("Walker_Hair")
    bm.to_mesh(mesh)
    bm.free()
    hair = bpy.data.objects.new("Walker_Hair", mesh)
    bpy.context.collection.objects.link(hair)
    for poly in mesh.polygons:
        poly.use_smooth = True
    hair.parent = head
    return hair


def _find(objs, name):
    return next(o for o in objs if _base(o.name) == name)


def build_variant_game(v, mat):
    """Bir çeşidi kurar, oyuna hazırlar; (iskelet, ağ) döner. Nesneler dünya kökünde."""
    root = bw.build_variant(v, 0.0)
    # ad sırası: build_variant küme sırasıyla döner, birleştirme sırası (ve GLB) sabit kalsın
    objs = sorted((o for o in root.children_recursive if o.type == "MESH"), key=lambda o: o.name)
    bpy.data.objects.remove(root)
    bpy.context.view_layer.update()
    head, jaw = _find(objs, "Walker_Head"), _find(objs, "Walker_Jaw")
    s = v["body"]["head"]
    bone_list = bones(v, head, jaw)
    shells = []
    for shell_name, reach in PAINTED_SHELLS:
        shell = next((o for o in objs if _base(o.name) == shell_name), None)
        if shell is None:
            continue
        color = {"Walker_Vest": zg.cloth_color(v["vest"] or (0, 0, 0), blood=0.3),
                 "Walker_Top": zg.cloth_color(v["top_color"] or (0, 0, 0), blood=v["blood"]),
                 "Walker_Bottom": zg.cloth_color(v["bottom_color"], stain=(0.05, 0.04, 0.03))}[shell_name]
        shells.append((zg.world_bvh(shell), reach, color))
        objs.remove(shell)
        bpy.data.objects.remove(shell)
    hair = next((o for o in objs if _base(o.name) == "Walker_Hair"), None)
    hair_tree = None
    if hair is not None:          # konsept saçı: yalnız bölge olarak kalır, ağı silinir
        hair_tree = zg.world_bvh(hair)
        objs.remove(hair)
        bpy.data.objects.remove(hair)
        style = wh.HAIR_STYLES[v["hair_style"]]
        locks = game_locks(head, hair_tree, v, style, GAME_LOCKS.get(v["hair_style"], 0))
        if locks is not None:
            objs.append(locks)
    ctx = {"segments": body_segments(bone_list), "shells": shells, "hair_tree": hair_tree,
           "skin": skin_color(v, head.matrix_world @ (Vector((0.0, -0.085, -0.03)) * s)),
           "mouth": mouth_color(head, s)}
    for obj in objs:
        prepare_part(obj, v, ctx)
    mesh = zg.join(objs, "Walker_" + v["name"])
    mesh.data.validate(clean_customdata=False)
    mesh.data.materials.clear()
    mesh.data.materials.append(mat)
    arm = zg.build_armature(RIG_NAME, bone_list)
    zg.bind(mesh, arm)
    return arm, mesh


# ---------------------------------------------------------------- ağırlık testi

# Kemik -> (dünya ekseni, derece). Karakter -Y'ye bakar; kemik yerel eksenleri (roll 0) keyfi
# olduğu için test pozu dünya ekseniyle verilir: kollar yana kalkar, sol diz derin bükülür,
# kafa döner, çene kapanır (ısırma), gövde döner.
TEST_POSE = {
    "upperarm_l": ((0, -1, 0), 80), "upperarm_r": ((0, 1, 0), 80), "lowerarm_l": ((0, 0, 1), 45),
    "clavicle_l": ((0, -1, 0), 15), "clavicle_r": ((0, 1, 0), 15),
    "thigh_l": ((-1, 0, 0), 70), "calf_l": ((1, 0, 0), 95), "thigh_r": ((-1, 0, 0), 30),
    "calf_r": ((1, 0, 0), 45), "foot_l": ((-1, 0, 0), 20),
    "Head": ((0, 0, 1), 45), "neck_01": ((0, 0, 1), 15), "jaw": ((1, 0, 0), -20),
    "spine_02": ((0, 0, 1), 20), "spine_01": ((1, 0, 0), 15),
}


def test_pose(arm, pose=None) -> None:
    """Ağırlık testi: dünya ekseninde döndürür (eksen kemiğin dinlenme uzayına çevrilir)."""
    for name, (axis, angle) in (pose or TEST_POSE).items():
        local = arm.data.bones[name].matrix_local.to_3x3().inverted() @ Vector(axis)
        arm.pose.bones[name].rotation_quaternion = Quaternion(local.normalized(), zg.deg(angle))


def reset_pose(arm) -> None:
    for pb in arm.pose.bones:
        pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
        pb.location = (0.0, 0.0, 0.0)
        pb.scale = (1.0, 1.0, 1.0)


# ---------------------------------------------------------------- kurulum

def out_path(v) -> str:
    return os.path.join(OUT_DIR, "zombie_walker_%s.glb" % v["name"].lower())


# Klipler: yalnız anahtarlanan izler (dönüş + pelvis konumu) dışa aktarılır, sabit konum/ölçek izi yok.
GLB_ANIM = {"export_optimize_animation_keep_anim_armature": False}


def stash_clips(arm, clips, variant: str) -> None:
    """Dışa aktarılmış çeşidin kliplerini siler: dışa aktarıcı dosyadaki tüm uyumlu actionları GLB'ye
    koyduğu için (kemik adları aynı) sıradaki çeşide karışırlar. .blend için en sonda yeniden üretilir."""
    for name in clips:
        bpy.data.actions.remove(bpy.data.actions[name])


def keep_clips_in_blend(rigs) -> None:
    """İnceleme kopyası: her çeşidin klipleri çeşit ekiyle, sessiz NLA izinde (dışa aktarım bitti)."""
    for variant, arm in rigs:
        for name in anims.build_all(arm):
            act = bpy.data.actions[name]
            act.name = "%s_%s" % (name, variant)
            track = arm.animation_data.nla_tracks.new()
            track.name = act.name
            track.mute = True
            track.strips.new(act.name, int(act.frame_range[0]), act)
        arm.animation_data.action = bpy.data.actions["idle_Loop_%s" % variant]
    arm.animation_data.action = None


def build_game(variants=None) -> dict:
    kit.reset_scene()
    mat = zg.vertex_color_material("M_Zombie_VC", glow_strength=0.0)
    variants = variants or bw.VARIANTS
    count = len(variants)
    report = {}
    rigs = []
    for i, v in enumerate(variants):
        arm, mesh = build_variant_game(v, mat)
        clips = anims.build_all(arm)
        zg.export_glb(out_path(v), [arm, mesh], **GLB_ANIM)
        stash_clips(arm, clips, v["name"])
        rigs.append((v["name"], arm))
        report[v["name"]] = (zg.tri_count(mesh), len(arm.data.bones))
        print("WALKER GAME", v["name"], "tris", report[v["name"]][0], "bones", report[v["name"]][1])
        arm.name = "%s_%s" % (RIG_NAME, v["name"])      # sıradaki çeşit aynı adı alsın
        arm.data.name = arm.name
        arm.location.x = (i - (count - 1) / 2) * LINEUP_SPACING
    keep_clips_in_blend(rigs)
    kit.setup_look()
    os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    print("WALKER GAME exported:", report)
    return report


if __name__ != "walker_game":
    build_game()
