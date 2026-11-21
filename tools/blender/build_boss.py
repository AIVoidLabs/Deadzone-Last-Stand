"""Boss "Yığın" (boss_heap) — 7.4, tamamen Blender (arka plan örneği).

Kimlik (build/briefs/s74_boss.md): ölü bedenlerin birbirine kaynayıp yürüyen bir dağa dönüşmüş hali.
~3.6 m, çok geniş (yarıçap 1.4 m). Sırtında yarı gömülü bedenlerden asimetrik kambur (sağ tepe yüksek),
gövdede gömülü yüzler ve kollar (bazıları kamburdan dışarı uzanır), iki dev kol: sol kolun ucu kemik
topuz, sağ kol üç parmaklı pençe; iki kalın kısa bacak (fil ayağı parmakları). Göğüste kızıl parlayan
yarık ("kalp", zayıf nokta): parıltı maskesi köşe rengi alfası. Kafa kamburun altına gömülü, öne uzanık.
Tek çeşit (VARIANT). Model yapı biriminde (insan ölçüsü) kurulur, kök BUILD_SCALE ile büyütülür.

Gövde: iskelet noktaları + skin modifier + kas/yağ kütleleri + kabartmalar, voxel remesh ile kaynar
(zombie_kit). Renkler köşe rengi (boss_paint): konsept ve oyun aynı görünüşü taşır.
Pozlar veri: "neutral" ve "signature" (Yer Dövme doruğu: iki kol tepede, gövde geriye gerilmiş, kükrer).

Çalıştırma (arka plan):
    blender --background --python tools/blender/boss_render.py      (konsept görselleri)
    blender --background --python tools/blender/boss_game.py        (GLB + klipler)
    blender --background --python tools/blender/boss_check.py       (ölçüm + kare özeti)
Yalnız blend:  blender --background --python tools/blender/build_boss.py  → build/blender/boss.blend
"""
import importlib
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector, geometry

_HERE = globals().get("__file__", "")
REPO = os.path.abspath(os.path.join(os.path.dirname(_HERE), "..", "..")) if _HERE else ""
if not REPO or not os.path.isdir(os.path.join(REPO, "tools")):
    REPO = r"C:\Users\pekta\projeler\Deadzone-Last-Stand"
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import zombie_kit as kit  # noqa: E402
import boss_parts as bparts  # noqa: E402
import boss_head as bh  # noqa: E402
import boss_paint as paint  # noqa: E402

for _m in (kit, bparts, bh, paint):
    importlib.reload(_m)
OUT_BLEND = os.path.join(REPO, "build", "blender", "boss.blend")
BUILD_SCALE = 1.92
VOXEL = 0.011
HEAD_S = 1.8

# Karakter -Y yönüne bakar, Z yukarı, yapı birimi. Kambur öne eğik gövde: boyun öne uzanır.
TORSO_POINTS = {
    "pelvis": ((0.0, 0.03, 0.62), 0.20),
    "spine": ((0.0, 0.0, 0.92), 0.30),
    "chest": ((0.0, 0.02, 1.14), 0.30),
    "upchest": ((0.0, 0.04, 1.30), 0.24),
    "neck0": ((0.0, -0.14, 1.30), 0.13),
    "neck1": ((0.0, -0.26, 1.27), 0.11),
}
# Sol (+X); sağ aynalanır. Kollar maymun gibi uzun: topuz ve pençe dize iner.
SIDE_POSES = {
    "neutral": {
        "hip": ((0.21, 0.03, 0.60), 0.12), "knee": ((0.28, -0.05, 0.34), 0.10),
        "ankle": ((0.28, 0.02, 0.10), 0.085), "heel": ((0.28, 0.07, 0.05), 0.075),
        "ball": ((0.29, -0.10, 0.05), 0.065), "toe": ((0.29, -0.16, 0.04), 0.045),
        "shoulder": ((0.52, 0.04, 1.36), 0.14), "elbow": ((0.76, 0.06, 1.00), 0.10),
        "wrist": ((0.80, -0.06, 0.68), 0.085), "fist": ((0.81, -0.09, 0.54), 0.0),
    },
    # Yer Dövme doruğu: kollar başın üstünde, topuz ve pençe geride; dizler kırık, gövde geriye gerilmiş
    "signature": {
        "hip": ((0.21, 0.03, 0.56), 0.12), "knee": ((0.32, -0.12, 0.32), 0.10),
        "ankle": ((0.32, -0.04, 0.10), 0.085), "heel": ((0.32, 0.01, 0.05), 0.075),
        "ball": ((0.33, -0.16, 0.05), 0.065), "toe": ((0.33, -0.22, 0.04), 0.045),
        "shoulder": ((0.52, 0.06, 1.40), 0.14), "elbow": ((0.66, 0.16, 1.80), 0.10),
        "wrist": ((0.46, 0.20, 2.14), 0.085), "fist": ((0.40, 0.22, 2.28), 0.0),
    },
}
POSE_LEAN = {"neutral": 0.0, "signature": -14.0}
POSE_HEAD = {"neutral": (4.0, 14.0), "signature": (-26.0, 34.0)}
UPPER = {"shoulder", "elbow", "wrist", "fist"}
LEGS = ("hip", "knee", "ankle", "heel", "ball", "toe", "pelvis")
TORSO_EDGES = [("pelvis", "spine"), ("spine", "chest"), ("chest", "upchest"), ("upchest", "neck0"),
               ("neck0", "neck1")]
LIMB_CHAIN = [("hip", "knee"), ("knee", "ankle"), ("ankle", "heel"), ("ankle", "ball"),
              ("ball", "toe"), ("shoulder", "elbow"), ("elbow", "wrist")]
VARIANT = {"name": "Heap", "seed": 3.3}
LAST = {}                 # son kurulumun kabartmaları, noktaları ve kafası (oyun hattı için)


# ---------------------------------------------------------------- gövde

def body_points(pose="neutral"):
    pts = {n: (Vector(p), r) for n, (p, r) in TORSO_POINTS.items()}
    for n, (p, r) in SIDE_POSES[pose].items():
        for side, sx in (("L", 1.0), ("R", -1.0)):
            # sağ kol (pençe) biraz daha dışta ve iri: üstten asimetri
            k = 1.06 if (side == "R" and n in UPPER) else 1.0
            pts[f"{n}_{side}"] = (Vector((p[0] * sx * k, p[1], p[2])), r * k)
    return pts


def lean_matrix(pts, pose):
    pivot = pts["pelvis"][0]
    rot = Matrix.Rotation(math.radians(POSE_LEAN[pose]), 4, "X")
    return Matrix.Translation(pivot) @ rot @ Matrix.Translation(-pivot)


def apply_lean(pts, blobs, pose):
    if not POSE_LEAN[pose]:
        return pts, blobs
    m = lean_matrix(pts, pose)
    q = m.to_quaternion()
    out = {n: ((m @ p) if n.split("_")[0] not in LEGS else p, r) for n, (p, r) in pts.items()}
    pz = pts["pelvis"][0].z + 0.05
    new = [((tuple(m @ Vector(c)) if c[2] > pz else c), radii, ((q @ rot) if c[2] > pz else rot), neg)
           for c, radii, rot, neg in blobs]
    return out, new


def build_body(mat, pose):
    pts = body_points(pose)
    blobs = bparts.masses(pts, body_points("neutral"))
    pts, blobs = apply_lean(pts, blobs, pose)
    edges = list(TORSO_EDGES)
    for side in ("L", "R"):
        edges += [(f"{a}_{side}", f"{b}_{side}") for a, b in LIMB_CHAIN]
        edges += [("pelvis", f"hip_{side}"), ("upchest", f"shoulder_{side}")]
    skin_pts = {n: (tuple(p), r) for n, (p, r) in pts.items() if not n.startswith("fist")}
    obj = kit.skin_object("Boss_Body", skin_pts, edges, mat)
    bparts.tp.add_blobs(obj, blobs, resolution=0.016)
    relief, info = bparts.relief_blobs(obj)
    bparts.tp.add_blobs(obj, relief, resolution=0.009)
    kit.organic_pass(obj, voxel=VOXEL, lump=0.007)
    bparts.carve_slit(obj)
    return obj, pts, info


# ---------------------------------------------------------------- kurulum

def build_variant(offset_x=0.0, pose="neutral", painted=True):
    """Boss'u kurar; kökü (BUILD_SCALE) döner. Parçalar köşe rengiyle boyanır (yapı biriminde)."""
    before = set(bpy.data.objects)
    mat = paint.concept_material("M_Boss_VC")
    body, pts, info = build_body(mat, pose)
    core = bparts.build_core(body, mat)
    mace, spikes = bparts.build_mace("Boss_Mace", pts["wrist_L"][0], pts["fist_L"][0], 1.0, mat, mat)
    claw, talons = bparts.build_claw("Boss_Claw", pts["wrist_R"][0], pts["fist_R"][0], -1.0, mat, mat)
    toes = [bparts.build_toes("Boss_Toes_" + sd, pts[f"ball_{sd}"][0], pts[f"toe_{sd}"][0], sx, mat, 3.3)
            for sd, sx in (("L", 1.0), ("R", -1.0))]
    pitch, jaw = POSE_HEAD[pose]
    head = bh.build_head(HEAD_S, mat, pts["neck1"][0], pitch + POSE_LEAN[pose] * 0.5, jaw)
    bpy.context.view_layer.update()
    if painted:
        paint_all(list(set(bpy.data.objects) - before), info, pts, head)
    created = list(set(bpy.data.objects) - before)
    root = bpy.data.objects.new(f"Boss_{pose}", None)
    bpy.context.collection.objects.link(root)
    for obj in created:
        if obj.parent is None:
            obj.parent = root
    root.scale = (BUILD_SCALE,) * 3
    root.location.x = offset_x
    LAST.update(info=info, pts=pts, head=head)
    return root


def claw_axis(pts):
    w, f = pts["wrist_R"][0], pts["fist_R"][0]
    return w, (f - w).normalized()


def kind_of(name):
    b = name.split(".")[0]
    return b[:-2] if b.endswith(("_L", "_R")) else b


def paint_all(objs, info, pts, head, space=None):
    ctx = {"body_fn": paint.body_color(info), "claw_fn": paint.claw_color(claw_axis(pts)),
           "mouth_fn": paint.mouth_color(head, HEAD_S)}
    for obj in objs:
        if obj.type != "MESH":
            continue
        fn, dirt = paint.part_color(kind_of(obj.name), ctx)
        paint.paint(obj, fn, dirt, space)


def face_count(root):
    return sum(sum(len(p.vertices) - 2 for p in o.data.polygons)
               for o in [root] + list(root.children_recursive) if o.type == "MESH")


def build(pose="neutral", save=True):
    kit.reset_scene()
    root = build_variant(0.0, pose)
    print("BOSS", pose, "tris:", face_count(root))
    kit.setup_look(target_height=2.4)
    if save:
        os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    return root


if __name__ not in ("build_boss",):
    build()
