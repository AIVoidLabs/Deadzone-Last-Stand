"""Koşucu zombi "Pençeli" konsepti — Aşama V.5, tamamen Blender. v2.

İnce, sinirli, uzun kollu ve uzun pençeli. Sessizce sinsice yaklaşır, çömelip çığlık atar,
pençeleriyle öne atılır (oyuncuya zorlattığı karar: dash'i doğru anda kullanmak). Yürüyenden farkı:
alçak ve öne eğik gövde, dizler hep bükük, öne uzanmış boyun, diz altına sarkan kollar ve uçlarında
uzun, koyu, uca doğru kararan pençeler; dirseklerde kemik dikeni; hafif parlayan gözler.

v2 (v1'e göre): kendi kafası (runner_head: kaş kemeri, elmacık, köşeli çene, derin göz çukuru,
parlayan göz, dudaksız diş sırası), tanımlı kas grupları ve eklem incelmesi (runner_body.MUSCLES),
ayak parmakları, kumaş gibi kıyafet (kıvrım, döküm, kıvrık kenar; runner_clothes), daha alçak ve
öne eğik nötr duruş, abartılı koyu pençeler.

Pozlar veri: runner_body.POSES ("stalk" nötr = oyun dinlenme pozu, "crouch" imza anı).
Çalıştırma (arka plan Blender):
    blender --background --python tools/blender/build_runner.py            # dizi + .blend
    blender --background --python tools/blender/runner_render.py -- all     # konsept görselleri
Çıktı: build/blender/runner.blend. Oyun modeli: runner_game.py.
"""
import importlib
import math
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
import walker_clothes as wc  # noqa: E402
import walker_head as wh  # noqa: E402
import runner_body as rb  # noqa: E402
import runner_parts as rp  # noqa: E402
import runner_clothes as rc  # noqa: E402
import runner_head as rh  # noqa: E402

for _m in (kit, wh, wc, rb, rp, rc, rh):
    importlib.reload(_m)
OUT_BLEND = os.path.join(REPO, "build", "blender", "runner.blend")
VOXEL = 0.006             # ince parmaklar için yürüyenden (0.008) sık
LINEUP_SPACING = 1.15
POSES = rb.POSES

# Çeşitler. body: h boy, w gövde genişliği, t uzuv kalınlığı, head kafa ölçeği.
# top: track (eşofman) / torn (yırtık gömlek) / tank (atlet) / None (çıplak gövde);
# stripe: eşofman yan şeridi; bib: göğüs numarası; hem: paça (0 kalça .. 1 bilek);
# shoes: renk ya da None (çıplak ayak, parmaklı); ribs/spine: çıplak gövdede kaburga, omurga. Doğrusal RGB.
VARIANTS = [
    {"name": "Jogger", "body": {"h": 1.00, "w": 0.95, "t": 0.92, "head": 0.95},
     "tone": (0.26, 0.27, 0.235), "bruise": (0.10, 0.08, 0.12), "bruise_band": (0.52, 0.72),
     "top": "track", "top_color": (0.025, 0.06, 0.11), "stripe": (0.55, 0.56, 0.56), "blood": 0.5,
     "holes": 0.15, "bottom_color": (0.025, 0.05, 0.09), "hem": 0.97, "hem_rag": 0.0,
     "shoes": (0.32, 0.32, 0.30), "hair": (0.04, 0.03, 0.02), "hair_style": "short", "seed": 2.0},
    {"name": "Torn", "body": {"h": 1.04, "w": 0.92, "t": 0.90, "head": 0.97},
     "tone": (0.22, 0.225, 0.20), "bruise": (0.08, 0.07, 0.10), "bruise_band": (0.50, 0.70),
     "top": "torn", "top_color": (0.40, 0.40, 0.36), "blood": 0.9, "holes": 0.38,
     "bottom_color": (0.06, 0.08, 0.13), "hem": 0.62, "hem_rag": 0.08,
     "shoes": None, "hair": (0.03, 0.025, 0.02), "hair_style": "sparse", "seed": 5.4},
    {"name": "Bare", "body": {"h": 0.98, "w": 0.90, "t": 0.88, "head": 0.94},
     "tone": (0.20, 0.17, 0.12), "bruise": (0.09, 0.06, 0.07), "bruise_band": (0.48, 0.70),
     "top": None, "ribs": True, "spine": True, "blood": 0.0,
     "bottom_color": (0.13, 0.12, 0.08), "hem": 0.78, "hem_rag": 0.10,
     "shoes": None, "hair": (0.02, 0.02, 0.02), "hair_style": "bald", "seed": 8.8},
    {"name": "Marathon", "body": {"h": 0.95, "w": 0.90, "t": 0.88, "head": 0.94},
     "tone": (0.25, 0.25, 0.25), "bruise": (0.09, 0.08, 0.13), "bruise_band": (0.50, 0.72),
     "top": "tank", "top_color": (0.42, 0.11, 0.025), "bib": (0.62, 0.62, 0.58), "blood": 0.6,
     "holes": 0.12, "bottom_color": (0.03, 0.03, 0.035), "hem": 0.28, "hem_rag": 0.02,
     "shoes": (0.10, 0.13, 0.16), "hair": (0.06, 0.035, 0.018), "hair_style": "long", "seed": 13.1},
]


def build_body(v, pose, mat):
    """Gövde ağı: iskelet noktaları + parmaklar + skin + voxel; kaslar. (nesne, parçalar, noktalar, pençeler)"""
    body = v["body"]
    pts = rb.body_points(pose, body)
    edges = list(rb.TORSO_EDGES)
    claws = []
    for side in ("L", "R"):
        edges += [(f"{a}_{side}", f"{b}_{side}") for a, b in rb.LIMB_CHAIN]
        edges += [("pelvis", f"hip_{side}"), ("upchest", f"shoulder_{side}")]
        extra, e, c = rp.hand(pts, side, POSES[pose]["hands"][side], body["t"])
        pts.update(extra)
        edges += e
        claws += c
        extra, e = rb.toes(pts, side, body["t"])
        pts.update(extra)
        edges += e
    obj = kit.skin_object("Runner_Body", {n: (tuple(p), r) for n, (p, r) in pts.items()}, edges, mat)
    kit.organic_pass(obj, voxel=VOXEL, lump=0.003)
    segments = [(rb.segment_class(a, b), pts[a][0], pts[b][0]) for a, b in edges]
    segments = [s for s in segments if s[0]]
    rb.shape_body(obj, segments, v)
    for s in ("L", "R"):          # ayakkabı için parmak ucu (orta parmak grubunun ucu)
        pts[f"toe_{s}"] = pts[f"toe11_{s}"]
    return obj, segments, pts, claws


def skin_for(v, name):
    mat = kit.skin_material(name, v["tone"], v["bruise"])
    ramp = next(n for n in mat.node_tree.nodes if n.type == "VALTORGB")
    ramp.color_ramp.elements[0].position, ramp.color_ramp.elements[1].position = v["bruise_band"]
    return mat


def pose_head(head, neck, pose, h):
    spec = POSES[pose]
    head.location = neck + Vector(spec["head_off"]) * h
    head.rotation_euler = tuple(math.radians(a) for a in spec["head_rot"])
    jaw = next(o for o in head.children if o.name.startswith("Runner_Jaw"))
    jaw.rotation_euler = (math.radians(spec["jaw"]), 0.0, 0.0)


def build_variant(v, pose="stalk", offset_x=0.0, prefix="Runner_"):
    before = set(bpy.data.objects)
    suffix = "_" + v["name"]
    skin = skin_for(v, "M_Runner_Skin" + suffix)
    tooth_mat, _ = kit.material("M_Runner_Teeth" + suffix, (0.40, 0.33, 0.20), rough=0.35)
    style = wh.HAIR_STYLES.get(v["hair_style"])
    hair_mat = wh.hair_material("M_Runner_Hair" + suffix, v["hair"], style["rough"]) if style else None
    body_obj, segments, pts, claws = build_body(v, pose, skin)
    cache = {}

    def part(co):
        key = (round(co.x, 4), round(co.y, 4), round(co.z, 4))
        if key not in cache:
            cache[key] = rb.classify(co, segments)
        return cache[key]
    rc.build_clothes(body_obj, part, v, suffix)
    if v["shoes"]:
        wc.build_shoes(body_obj, pts, lambda co: part(co)[:2], v, suffix)
        for o in set(bpy.data.objects) - before:
            if o.name.startswith("Walker_Shoe"):
                o.name = o.name.replace("Walker_", "Runner_")
    claw_mat = rp.claw_material("M_Runner_Claw" + suffix)
    rp.build_claws("Runner_Claws", claws, claw_mat)
    rp.build_claws("Runner_Spurs", rp.bone_spurs(pts, v.get("spine")), claw_mat, bend=25.0)
    head = rh.build_head(v, skin, tooth_mat, hair_mat)
    pose_head(head, pts["neck1"][0], pose, v["body"]["h"])
    created = list(set(bpy.data.objects) - before)
    root = bpy.data.objects.new(prefix + v["name"], None)
    bpy.context.collection.objects.link(root)
    for obj in created:
        if obj.parent is None:
            obj.parent = root
    root.location.x = offset_x
    bpy.context.view_layer.update()
    return root


def face_count(root):
    return sum(sum(len(p.vertices) - 2 for p in o.data.polygons)
               for o in root.children_recursive if o.type == "MESH")


def build(pose="stalk") -> None:
    kit.reset_scene()
    count = len(VARIANTS)
    for i, v in enumerate(VARIANTS):
        root = build_variant(v, pose, (i - (count - 1) / 2) * LINEUP_SPACING)
        print("RUNNER", v["name"], pose, "tris:", face_count(root))
    kit.setup_look()
    os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    print("RUNNER built, variants:", count)


if __name__ != "build_runner":
    build()
