"""Dilci oyun modeli (Aşama V.4): build_dilci görünüşünden → zombie_dilci.glb.

Her çeşit tek ağ (~11 bin üçgen), hepsi tek iskelete bağlı (oyunda ModelVariants biri seçer).
İskelet: projenin 25 kemikli adları + ek kemikler jaw_l, jaw_r (yarık çene), sac (boğaz kesesi).
Dil ağda yok: oyunda yordamsal TongueRope ağızdan çıkar. Klipler dilci_anims.py.

Çalıştırma (Blender MCP içinden):
    exec(open(r"<repo>/tools/blender/dilci_game.py", encoding="utf-8").read())
"""
import importlib
import os
import sys

import bpy
from mathutils import Euler, Matrix, Vector

_HERE = globals().get("__file__", "")
REPO = os.path.abspath(os.path.join(os.path.dirname(_HERE), "..", "..")) if _HERE else ""
if not REPO or not os.path.isdir(os.path.join(REPO, "tools")):
    REPO = r"C:\Users\pekta\projeler\Deadzone-Last-Stand"
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import zombie_kit as kit  # noqa: E402
import zombie_game as zg  # noqa: E402
import build_dilci as dil  # noqa: E402
import dilci_anims as anims  # noqa: E402

for _mod in (kit, zg, dil, anims):
    importlib.reload(_mod)

OUT_GLB = os.path.join(REPO, "assets", "models", "characters", "zombie_dilci.glb")
OUT_BLEND = os.path.join(REPO, "build", "blender", "dilci_game.blend")
# Parça başına yüz hedefi (incelme sonrası üçgen sayısı ~ bu); toplam ~11 bin üçgen.
# Kıyafet solidify ile çift kat olduğu için hedefi gövdeden düşük.
BUDGET = {"Dilci_Body": 4200, "Dilci_Top": 1100, "Dilci_Pants": 1100, "Dilci_Head": 1300,
          "Dilci_Jaw_L": 160, "Dilci_Jaw_R": 160, "Dilci_ThroatSac": 700,
          "Dilci_Eye_L": 40, "Dilci_Eye_R": 40}
TEETH_COLOR = (0.55, 0.48, 0.32)
EYE_COLOR = (1.0, 0.7, 0.2)


def _p(name: str, side: str = "") -> Vector:
    if not side:
        return Vector(dil.BODY_POINTS[name][0])
    x, y, z = dil.SIDE_POINTS[name][0]
    return Vector((x if side == "l" else -x, y, z))


def _sac_local() -> Vector:
    return dil.THROAT_LOCAL if dil.SAC_STYLE == "throat" else dil.SAC_LOCAL


def head_matrix() -> Matrix:
    return Matrix.Translation(dil.HEAD_POS) @ Euler((zg.deg(dil.HEAD_TILT_DEG), 0.0, 0.0)).to_matrix().to_4x4()


def bones() -> list:
    """[(ad, baş, uç, ebeveyn)] — model pozunda (kambur) dinlenme."""
    hm = head_matrix()
    out = [("root", Vector((0, 0, 0)), Vector((0, 0, 0.25)), None),
           ("pelvis", _p("pelvis"), _p("spine"), "root"),
           ("spine_01", _p("spine"), _p("chest"), "pelvis"),
           ("spine_02", _p("chest"), _p("upchest"), "spine_01"),
           ("spine_03", _p("upchest"), _p("neck0"), "spine_02"),
           ("neck_01", _p("neck0"), _p("neck1"), "spine_03"),
           ("Head", _p("neck1"), hm @ Vector((0.0, -0.01, 0.13)), "neck_01"),
           ("sac", hm @ _sac_local(), hm @ (_sac_local() + Vector((0.0, -0.02, -0.08))), "Head")]
    for side, sx in (("l", 1.0), ("r", -1.0)):
        hinge = hm @ Vector((dil.JAW_HINGE[0] * sx, dil.JAW_HINGE[1], dil.JAW_HINGE[2]))
        jaw_rot = Euler((zg.deg(dil.JAW_OPEN_DEG), zg.deg(-10 * sx), zg.deg(dil.JAW_SPLAY_DEG * sx))).to_matrix()
        chin = hinge + (hm.to_3x3() @ (jaw_rot @ Vector((-0.036 * sx, -0.102, -0.036))))
        finger_tip = Vector((0.36 * sx, -0.33, 0.50))
        toe = _p("toe", side)
        out += [(f"clavicle_{side}", _p("upchest") + Vector((0.04 * sx, 0.0, 0.0)), _p("shoulder", side), "spine_03"),
                (f"upperarm_{side}", _p("shoulder", side), _p("elbow", side), f"clavicle_{side}"),
                (f"lowerarm_{side}", _p("elbow", side), _p("wrist", side), f"upperarm_{side}"),
                (f"hand_{side}", _p("wrist", side), finger_tip, f"lowerarm_{side}"),
                (f"thigh_{side}", _p("hip", side), _p("knee", side), "pelvis"),
                (f"calf_{side}", _p("knee", side), _p("ankle", side), f"thigh_{side}"),
                (f"foot_{side}", _p("ankle", side), _p("ball", side), f"calf_{side}"),
                (f"ball_{side}", _p("ball", side), toe, f"foot_{side}"),
                (f"ball_leaf_{side}", toe, toe + Vector((0.0, -0.04, 0.0)), f"ball_{side}"),
                (f"jaw_{side}", hinge, chin, "Head")]
    return out


def body_segments(bone_list) -> dict:
    """Gövde/kıyafet ağırlığı için kemik parçaları (kök, yaprak, çene, kese hariç)."""
    skip = ("root", "sac", "ball_leaf_l", "ball_leaf_r", "jaw_l", "jaw_r")
    return {name: (head, tail) for name, head, tail, _ in bone_list if name not in skip}


def prepare_part(obj, v, segments) -> None:
    """Parçayı inceltir, boyar, ağırlıklar. Ad ve ebeveynden rolü çıkarır."""
    name = obj.name.split(".")[0]
    if name in BUDGET:
        zg.decimate(obj, BUDGET[name])
    parent = obj.parent.name.split(".")[0] if obj.parent else ""
    if name == "Dilci_Body":
        zg.paint(obj, zg.skin_color(v["tone"], v["bruise"]))
        zg.weight_by_distance(obj, segments)
    elif name == "Dilci_Top":
        zg.paint(obj, zg.cloth_color(v["top_color"], blood=v["blood"]))
        zg.weight_by_distance(obj, segments)
    elif name == "Dilci_Pants":
        zg.paint(obj, zg.cloth_color(v["pants_color"], stain=(0.05, 0.04, 0.03)))
        zg.weight_by_distance(obj, segments)
    elif name == "Dilci_Head":
        zg.paint(obj, zg.skin_color(v["tone"], v["bruise"]))
        zg.weight_to(obj, "Head")
    elif name.startswith("Dilci_Jaw_"):
        zg.paint(obj, zg.skin_color(v["tone"], v["bruise"]))
        zg.weight_to(obj, "jaw_" + name[-1].lower())
    elif name == "Dilci_ThroatSac":
        if dil.SAC_STYLE == "throat":
            skin = tuple(c * 0.92 for c in v["tone"])
            zg.paint(obj, zg.vein_color(base=skin, vein=(0.20, 0.05, 0.08)), dirt=0.3)
        else:
            zg.paint(obj, zg.vein_color(), glow=0.3, dirt=0.2)
        zg.weight_to(obj, "sac")
    elif name.startswith("Dilci_Eye_"):
        zg.paint(obj, zg.flat_color(EYE_COLOR), glow=1.0, dirt=0.0)
        zg.weight_to(obj, "Head")
    elif name.startswith("Tooth"):
        zg.paint(obj, zg.flat_color(TEETH_COLOR), dirt=0.0)
        zg.weight_to(obj, "jaw_" + parent[-1].lower() if parent.startswith("Dilci_Jaw_") else "Head")


def build_game() -> None:
    kit.reset_scene()
    bone_list = bones()
    segments = body_segments(bone_list)
    arm = zg.build_armature("Dilci_Rig", bone_list)
    mat = zg.vertex_color_material("M_Zombie_VC")
    meshes = []
    for v in dil.VARIANTS:
        root, created = dil.build_variant(v, 0.0, with_tongue=False)
        bpy.data.objects.remove(root)
        parts = [o for o in created if o.type == "MESH"]
        for obj in parts:
            prepare_part(obj, v, segments)
        mesh = zg.join(parts, "Dilci_" + v["name"])
        mesh.data.validate(clean_customdata=False)  # incelmeden kalan bozuk yüzleri temizler
        mesh.data.materials.clear()
        mesh.data.materials.append(mat)
        zg.bind(mesh, arm)
        meshes.append(mesh)
        print("variant", v["name"], "tris", zg.tri_count(mesh))
    clips = anims.build_all(arm)
    kit.setup_look()
    os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    zg.export_glb(OUT_GLB, [arm] + meshes)
    print("DILCI GAME exported:", OUT_GLB, "clips:", clips)


if __name__ != "dilci_game":
    build_game()
