"""Asker klipleri: dil sürüklenmesi ve kurtulma — elle anahtarlanmış, kodla yeniden üretilir (Aşama V.4).

Blender MCP içinde çalıştırılır (canlı Blender'da görüntüyle yinelenir):
    exec(open(r"<repo>/tools/blender/player_anims.py", encoding="utf-8").read())
Girdi : assets/models/characters/mannequin.glb (UAL manken, 25 kemik, T-poz)
Çıktı : assets/models/anim/player_anims.glb -> Godot'da AnimationLibrary (ual1 gibi, aynı kemik eşlemesi)
        build/blender/player_anims.blend     -> inceleme kopyası (git'e girmez)

Sözleşme dilci_anims.py ile aynı: her klip t (sn) -> poz; açılar İSKELET uzayında derece, dinlenme
pozuna göre (T-poz). Karakter -Y'ye bakar, sol +X, yukarı +Z. X+: yukarı uzanan kemikte öne eğilme,
aşağı sarkan kol/bacakta geriye savrulma. Sol kol (+X'e uzanır) için Y+ kolu indirir, Z- öne getirir;
sağ taraf aynalanır (Y, Z ters). loc: iskelet uzayında metre. Ölçek anahtarı yok.
Döngü klibi `_Loop` ekiyle (Godot eki atıp döngü yapar).

drag_Loop : dil göğse yapışmış, asker öndeki dilciye doğru çekiliyor. Geriye yaslanır, iki eliyle dili
            tutup asılır; öndeki ayak topukla toprağa gömülü kayar, arka ayak tökezleyip yeniden basar.
            Dilcinin çekiş ritmiyle (0.8 sn) göğüs öne silkelenir.
break_free: son bir asılış, dil kopar: kollar dışa/geriye fırlar, geriye yaslanmış asker bir adım
            geri sendeler (kollar dengede öne savrulur), bekleme duruşuna oturur.
Açılar Blender MCP'de pozu ölçerek bulundu (bilek göğüs önünde, ayaklar yerde) ve görüntüyle yinelendi.
"""
import math
import os

import bpy
from mathutils import Euler, Vector

REPO = r"C:\Users\pekta\projeler\Deadzone-Last-Stand"
SOURCE = os.path.join(REPO, "assets", "models", "characters", "mannequin.glb")
OUT_GLB = os.path.join(REPO, "assets", "models", "anim", "player_anims.glb")
OUT_BLEND = os.path.join(REPO, "build", "blender", "player_anims.blend")
FPS = 30
STEP = 2  # örnekleme aralığı (kare)
TAU = math.tau

DRAG_CYCLE = 0.8
BREAK_TIME = 0.8


def clamp01(x: float) -> float:
    return min(max(x, 0.0), 1.0)


def ease_out(x: float) -> float:
    return 1.0 - (1.0 - clamp01(x)) ** 3


def ease_in_out(x: float) -> float:
    x = clamp01(x)
    return x * x * (3.0 - 2.0 * x)


def back_out(x: float, s: float = 1.7) -> float:
    x = clamp01(x) - 1.0
    return 1.0 + x * x * ((s + 1.0) * x + s)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def side(pose: dict, base: str, rot_l, **extra) -> None:
    """Sol kemiğe rot_l, sağa aynası (Y ve Z ters)."""
    pose[base + "_l"] = {"rot": rot_l, **extra}
    pose[base + "_r"] = {"rot": (rot_l[0], -rot_l[1], -rot_l[2]), **extra}


def stand() -> dict:
    """Bekleme duruşu (UAL Idle'a yakın): kollar yanda, dirsekler hafif bükük. Kurtulma buraya oturur."""
    pose = {"spine_01": {"rot": (2, 0, 0)}, "Head": {"rot": (-2, 0, 0)}}
    side(pose, "upperarm", (0, 74, -6))
    side(pose, "lowerarm", (0, 6, -16))
    side(pose, "thigh", (0, 2, 0))
    return pose


# --- klipler ------------------------------------------------------------------

def grip(tug: float, reach: float = 0.0) -> dict:
    """Kollar: iki el göğsün önünde dili tutar (dirsekler aşağıda, yanda).
    tug 0..1: dirsekleri geriye asılış; reach 0..1: dilin çekişiyle kollar öne gerilir."""
    pose = {}
    side(pose, "clavicle", (0, 0, -6 + 8 * tug - 8 * reach))
    side(pose, "upperarm", (0, 60 - 6 * tug, -40 + 16 * tug - 22 * reach))
    side(pose, "lowerarm", (0, 30, -90 - 10 * tug + 34 * reach))
    side(pose, "hand", (0, 15, -15))
    return pose


def drag(t: float) -> dict:
    """Halat çekme duruşu: ağırlık geride, iki ayak önde; ön topuk gömülü, arka diz bükük."""
    w = TAU * t / DRAG_CYCLE
    s = math.sin
    # dilcinin çekişi: döngüde bir kez sert silkeleme (gövde ve kollar öne), sonra asker yeniden asılır
    jerk = max(0.0, s(w)) ** 3
    tug = 0.5 + 0.5 * s(w + 2.4)
    # arka ayak: döngünün ikinci yarısında kalkıp yeniden basar (kayarken tökezleyen adım)
    step = max(0.0, s(w - math.pi)) ** 1.5
    pose = {
        "pelvis": {"loc": (0.0, 0.12 - 0.05 * jerk, -0.16 + 0.03 * jerk + 0.02 * step),
                   "rot": (-15 + 7 * jerk, 0, 3 * s(w))},
        "spine_01": {"rot": (-5 + 4 * jerk, 0, -2 * s(w))},
        "spine_02": {"rot": (-5 + 4 * jerk, 0, 2 * s(w + 0.5))},
        "spine_03": {"rot": (-4 + 6 * jerk - 3 * tug, 0, 3 * s(w + 1.0))},
        "neck_01": {"rot": (14 - 4 * jerk, 0, 0)},
        "Head": {"rot": (22 - 8 * jerk, 4 * s(2 * w), 5 * s(w + 0.6))},
        # ön bacak: düz, öne; topuk gömülü, parmaklar havada; silkelemede kayar ve diz kırılır
        "thigh_l": {"rot": (-30 + 4 * jerk, 2, 0)},
        "calf_l": {"rot": (6 + 10 * jerk, 0, 0)},
        "foot_l": {"rot": (9 - 6 * jerk, 0, 0)},
        # arka bacak: bükük, iter; adımda kalkar, öne gelip yeniden basar
        "thigh_r": {"rot": (-30 - 14 * step, -2, 0)},
        "calf_r": {"rot": (66 + 28 * step, 0, 0)},
        "foot_r": {"rot": (-21 + 12 * step, 0, 0)},
    }
    pose.update(grip(tug * (1.0 - jerk), jerk))
    return pose


def break_free(t: float) -> dict:
    """Son bir asılış, dil kopar: geriye yaslanmış asker geriye sendeler, kollar savrulur, dengesini bulur."""
    gather = ease_in_out(t / 0.1)
    snap = ease_out((t - 0.1) / 0.12)
    stumble = math.sin(clamp01((t - 0.16) / 0.42) * math.pi)
    settle = ease_in_out((t - 0.42) / (BREAK_TIME - 0.42))
    start = drag(0.0)
    heave = {**start, **grip(1.0)}
    heave["spine_03"] = {"rot": (-10, 0, 0)}
    heave["Head"] = {"rot": (8, 0, 0)}
    torn = {
        "pelvis": {"loc": (0.0, 0.2, -0.12), "rot": (-20, 0, 0)},
        "spine_01": {"rot": (-8, 0, 0)},
        "spine_02": {"rot": (-8, 0, 0)},
        "spine_03": {"rot": (-8, 0, 0)},
        "neck_01": {"rot": (-8, 0, 0)},
        "Head": {"rot": (-18, 0, 0)},
        "thigh_l": {"rot": (-35, 2, 0)}, "calf_l": {"rot": (10, 0, 0)}, "foot_l": {"rot": (15, 0, 0)},
        "thigh_r": {"rot": (-10, -2, 0)}, "calf_r": {"rot": (40, 0, 0)}, "foot_r": {"rot": (-10, 0, 0)},
    }
    # kollar dışa ve geriye fırlar: kopan dilin ucu elden kurtulur
    side(torn, "clavicle", (0, 0, 10))
    side(torn, "upperarm", (0, 22, 22))
    side(torn, "lowerarm", (0, 0, -25))
    side(torn, "hand", (0, -10, 0))
    pose = _blend(_blend(start, heave, gather), torn, snap)
    # sendeleme: arka ayak geriye atılır, kalça geride kalır, kollar denge için öne savrulur
    sway = {"thigh_r": {"rot": (30 * stumble, 0, 0)}, "calf_r": {"rot": (20 * stumble, 0, 0)},
            "pelvis": {"loc": (0.0, 0.05 * stumble, 0.02 * stumble)}, "spine_02": {"rot": (6 * stumble, 0, 0)}}
    side(sway, "upperarm", (0, -10 * stumble, -45 * stumble))
    pose = _add(pose, sway)
    return _blend(pose, stand(), settle)


CLIPS = [("drag_Loop", drag, DRAG_CYCLE), ("break_free", break_free, BREAK_TIME)]


# --- anahtarlama -----------------------------------------------------------------

def _blend(a: dict, b: dict, t: float) -> dict:
    out = {}
    for name in set(a) | set(b):
        ca, cb = a.get(name, {}), b.get(name, {})
        ch = {}
        for key in ("rot", "loc"):
            if key in ca or key in cb:
                va, vb = ca.get(key, (0, 0, 0)), cb.get(key, (0, 0, 0))
                ch[key] = tuple(lerp(va[i], vb[i], t) for i in range(3))
        out[name] = ch
    return out


def _add(a: dict, b: dict) -> dict:
    out = {k: dict(v) for k, v in a.items()}
    for name, cb in b.items():
        ch = out.setdefault(name, {})
        for key, vb in cb.items():
            va = ch.get(key, (0, 0, 0))
            ch[key] = tuple(va[i] + vb[i] for i in range(3))
    return out


def _apply(arm, pose: dict, frame: int) -> None:
    for pb in arm.pose.bones:
        ch = pose.get(pb.name, {})
        rest = pb.bone.matrix_local.to_quaternion()
        q = Euler(tuple(math.radians(a) for a in ch.get("rot", (0, 0, 0))), "XYZ").to_quaternion()
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = rest.inverted() @ q @ rest
        pb.location = rest.inverted() @ Vector(ch.get("loc", (0, 0, 0)))
        pb.keyframe_insert("rotation_quaternion", frame=frame, group=pb.name)
        pb.keyframe_insert("location", frame=frame, group=pb.name)


def build_clip(arm, name: str, fn, length: float):
    old = bpy.data.actions.get(name)
    if old is not None:
        bpy.data.actions.remove(old)
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    arm.animation_data.action = action
    last = round(length * FPS)
    # döngüde son kare ilk karenin aynısıdır; Godot klip boyunu son anahtardan alır
    for f in list(range(0, last, STEP)) + [last]:
        _apply(arm, fn(f / FPS), f + 1)
    action.use_frame_range = True
    action.frame_start, action.frame_end = 1, last + 1
    return action


def load_mannequin():
    """Sahneyi temizler (fabrika ayarı YOK: MCP eklentisini kapatır) ve mankeni içe aktarır."""
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)
    for block in (bpy.data.meshes, bpy.data.armatures, bpy.data.materials):
        for item in list(block):
            if item.users == 0:
                block.remove(item)
    bpy.ops.import_scene.gltf(filepath=SOURCE)
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    if arm.animation_data is None:
        arm.animation_data_create()
    return arm


def export(arm) -> None:
    os.makedirs(os.path.dirname(OUT_GLB), exist_ok=True)
    with bpy.context.temp_override(selected_objects=list(bpy.data.objects), active_object=arm):
        for obj in bpy.data.objects:
            obj.select_set(True)
        bpy.ops.export_scene.gltf(
            filepath=OUT_GLB, export_format="GLB", use_selection=True,
            export_animations=True, export_animation_mode="ACTIONS", export_skins=True, export_yup=True,
        )
    print("yazıldı:", OUT_GLB, "%.0f KB" % (os.path.getsize(OUT_GLB) / 1024.0))


def build(do_export: bool = True):
    bpy.context.scene.render.fps = FPS
    bpy.context.scene.render.fps_base = 1.0
    arm = load_mannequin()
    for name, fn, length in CLIPS:
        build_clip(arm, name, fn, length)
    arm.animation_data.action = bpy.data.actions["drag_Loop"]
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = round(DRAG_CYCLE * FPS) + 1
    if do_export:
        export(arm)
        os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND, copy=True)
    return arm


if __name__ == "__main__" or "PLAYER_ANIMS_NO_RUN" not in globals():
    build(globals().get("PLAYER_ANIMS_EXPORT", True))
