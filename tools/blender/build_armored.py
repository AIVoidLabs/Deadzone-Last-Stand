"""Zırhlı zombi ("Kalkan", tür id `armored`) konsepti — 7.3, tamamen Blender (arka plan örneği).

Kimlik (build/briefs/s73_design.md §1): çevik kuvvet zırhı giymiş zombi; çatlak vizörlü kask, kalın yelek,
omuzluklar, sol önkolunda kırık kalkan parçası (üstten kameradan önde büyük düz plaka). Kalkanın arkasına
sinmiş, kambur. İmza: kalkanı önde tutarak ağır yürüyüş; saldırı = kalkanla omuz darbesi.
Oyuncuya kararı: önden mermiler seker → yana/arkaya geç.

Ortak v2 düzeltmeleri baştan uygulandı: kendi kafası/yüzü (armored_head: keskin elmacık, çökük yanak,
çürümüş burun, yanakta et kaybı), tanımlı kas grupları ve ince eklemler (armored_body), kumaş gibi
okunan kıyafet (tank_clothes.garment: kat, kıvrık kenar), bot (takunya değil, konçlu, tabanlı).
Zırh parçaları malzeme yuvalarıyla: plastik / metal / kauçuk (oyunda köşe renginde ayrışır).

Dosyalar: armored_body (gövde), armored_head (kafa, kask, vizör), armored_gear (yelek, koruyucular, bot,
eldiven, kıyafet), armored_shield (kalkan), armored_mats (malzemeler), armored_render (görseller),
armored_game (oyun modeli), armored_anims + armored_falls (klipler), armored_check (ölçüm, kare özeti).

    blender --background --python tools/blender/armored_render.py      # konsept görselleri
    blender --background --python tools/blender/build_armored.py       # yalnız dizi blend'i
Çıktı: build/blender/armored.blend
"""
import importlib
import os
import sys

import bpy

_HERE = globals().get("__file__", "")
REPO = os.path.abspath(os.path.join(os.path.dirname(_HERE), "..", "..")) if _HERE else ""
if not REPO or not os.path.isdir(os.path.join(REPO, "tools")):
    REPO = r"C:\Users\pekta\projeler\Deadzone-Last-Stand"
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import zombie_kit as kit  # noqa: E402
import armored_mats as am  # noqa: E402
import armored_body as ab  # noqa: E402
import armored_head as ah  # noqa: E402
import armored_gear as ag  # noqa: E402
import armored_shield as ash  # noqa: E402

for _m in (am, ab, ah, ag, ash):
    importlib.reload(_m)
OUT_BLEND = os.path.join(REPO, "build", "blender", "armored.blend")
LINEUP_SPACING = 1.5
HEAD_PITCH = -12.0        # boyun öne uzanır, kafa kalkıp öne bakar
JAW_OPEN = 7.0

# Çeşitler (renkler doğrusal). body: s ölçek, w genişlik, t kol kası, legs bacak, belly göbek, head kafa,
# hand eldiven. suit/pants kumaş, vest yelek, armor plastik zırh rengi, helmet kask, plate göğüs plakası
# (tür, renk) ya da None, pads koruyucular, sleeves kolun kapalı oranı (1.4 = bileğe dek, 0.55 = kısa kol),
# shield: break kırık çizgisi ((x0,z0),(x1,z1)), accent vurgu, slots (yüz, çerçeve, vurgu).
VARIANTS = [
    {"name": "Riot", "body": {"s": 1.0, "w": 1.04, "t": 1.0, "legs": 1.0, "belly": 1.0, "head": 1.12, "hand": 0.80},
     "tone": (0.20, 0.22, 0.18), "bruise": (0.09, 0.06, 0.08),
     "suit": (0.022, 0.030, 0.065), "pants": (0.020, 0.026, 0.055), "vest": (0.016, 0.020, 0.040),
     "armor": (0.030, 0.040, 0.095), "helmet": (0.030, 0.040, 0.095), "plate": ("plastic", (0.035, 0.046, 0.105)),
     "pads": {"shoulder_L", "shoulder_R", "forearm_R", "shin"}, "sleeves": {"L": 1.4, "R": 1.15},
     "boots": (0.012, 0.012, 0.012), "gloves": (0.015, 0.015, 0.016), "pouches": (115, -115), "holes": 0.15,
     "shield": {"break": ((-0.02, 0.44), (-0.31, 0.05)), "accent": "band",
                "slots": [("plastic", (0.30, 0.33, 0.36)), ("metal", (0.10, 0.10, 0.11)),
                          ("plastic", (0.62, 0.62, 0.60))]},
     "seed": 2.1},
    {"name": "Swat", "body": {"s": 1.0, "w": 1.08, "t": 1.05, "legs": 1.02, "belly": 1.0, "head": 1.12, "hand": 0.82},
     "tone": (0.22, 0.23, 0.19), "bruise": (0.10, 0.07, 0.09),
     "suit": (0.014, 0.014, 0.016), "pants": (0.014, 0.014, 0.016), "vest": (0.020, 0.022, 0.018),
     "armor": (0.016, 0.016, 0.018), "helmet": (0.016, 0.016, 0.018), "plate": ("metal", (0.20, 0.20, 0.21)),
     "pads": {"shoulder_L"}, "sleeves": {"L": 1.4, "R": 0.75},
     "boots": (0.010, 0.010, 0.010), "gloves": (0.012, 0.012, 0.012), "pouches": (75, -75, 110, -110, 180), "holes": 0.25,
     "shield": {"break": ((0.02, 0.44), (-0.31, 0.02)), "accent": "window",
                "slots": [("metal", (0.17, 0.175, 0.18)), ("metal", (0.06, 0.06, 0.065)),
                          ("visor", (0.02, 0.025, 0.03))]},
     "seed": 5.7},
    {"name": "Guard", "body": {"s": 0.98, "w": 1.0, "t": 0.95, "legs": 1.0, "belly": 1.15, "head": 1.12, "hand": 0.78},
     "tone": (0.24, 0.24, 0.20), "bruise": (0.12, 0.07, 0.09),
     "suit": (0.20, 0.20, 0.19), "pants": (0.025, 0.030, 0.045), "vest": (0.018, 0.018, 0.020),
     "armor": (0.12, 0.12, 0.12), "helmet": (0.13, 0.13, 0.13), "plate": None, "visor": True,
     "pads": {"shoulder_L"}, "sleeves": {"L": 0.55, "R": 0.55},
     "boots": (0.018, 0.014, 0.010), "gloves": (0.02, 0.018, 0.016), "pouches": (), "holes": 0.2,
     "shield": {"break": ((-0.10, 0.44), (-0.31, 0.20)), "accent": "low_band",
                "slots": [("plastic", (0.22, 0.22, 0.21)), ("rubber", (0.02, 0.02, 0.02)),
                          ("plastic", (0.55, 0.40, 0.04))]},
     "seed": 9.3},
]


def build_variant(v, offset_x=0.0, pose="neutral", head_pitch=HEAD_PITCH, jaw=JAW_OPEN):
    before = set(bpy.data.objects)
    suffix = "_" + v["name"]
    skin = kit.skin_material("M_Armored_Skin" + suffix, v["tone"], v["bruise"])
    tooth_mat, _ = kit.material("M_Armored_Teeth" + suffix, ah.TOOTH_COLOR, rough=0.5)
    body, segments, pts = ab.build_body(v, skin, pose)
    cache = {}

    def part3(co):
        key = (round(co.x, 3), round(co.y, 3), round(co.z, 3))
        if key not in cache:
            cache[key] = ab.classify_side(co, segments)
        return cache[key]

    def part(co):
        return part3(co)[:2]
    ag.build_clothes(body, part3, pts, v, suffix)
    ag.build_vest(body, part, pts, v, suffix)
    ag.pouches(body, pts, v, suffix)
    pads = v["pads"]
    sides = tuple(s for s in ("L", "R") if "shoulder_" + s in pads)
    if sides:
        ag.shoulder_pads(pts, v, suffix, sides)
    if "forearm_R" in pads:
        ag.forearm_guard(pts, v, suffix, "R")
    ag.leg_guards(pts, v, suffix)
    ag.build_boots_gloves(body, pts, part, v, suffix, skin)
    ash.build_shield(pts, v, suffix)
    ah.build_head(v, skin, tooth_mat, pts["neck1"][0], head_pitch, jaw)
    created = list(set(bpy.data.objects) - before)
    root = bpy.data.objects.new(f"Armored_{v['name']}_{pose}", None)
    bpy.context.collection.objects.link(root)
    for obj in created:
        if obj.parent is None:
            obj.parent = root
    root.scale = (v["body"]["s"],) * 3
    root.location.x = offset_x
    return root


def face_count(root):
    return sum(sum(len(p.vertices) - 2 for p in o.data.polygons)
               for o in [root] + list(root.children_recursive) if o.type == "MESH")


def build(pose="neutral", save=True):
    kit.reset_scene()
    roots = []
    for i, v in enumerate(VARIANTS):
        root = build_variant(v, (i - (len(VARIANTS) - 1) / 2) * LINEUP_SPACING, pose)
        print("ARMORED", v["name"], pose, "tris:", face_count(root))
        roots.append(root)
    kit.setup_look(target_height=1.3)
    if save:
        os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    return roots


if __name__ not in ("build_armored",):
    build()
