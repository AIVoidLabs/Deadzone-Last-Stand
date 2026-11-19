"""Dilci klipleri — elle anahtarlanmış, kodla yeniden üretilir (Aşama V.4).

Her klip t (sn) → poz fonksiyonu; 2 karede bir örneklenir, Bezier ile yumuşar. Açılar iskelet
uzayında derece: X+ öne eğilme (aşağı sarkan kol/bacakta geriye savrulma), Y+ karakterin
soluna yatma, Z+ sola dönme. Karakter -Y'ye bakar. loc: iskelet uzayında metre. scale: kese.
Döngü klipleri `_Loop` ekiyle (Godot ekini atıp döngü yapar). Önsezi, abartı, takip, yerleşme
ilkeleri: hazırlık önce geri çekilir, vuruş taşar, uzuvlar gövdeden gecikmeli gelir.
"""
import math

import bpy
from mathutils import Euler, Vector

FPS = 30
STEP = 2  # örnekleme aralığı (kare)
TAU = math.tau


def ease_out(x: float) -> float:
    x = min(max(x, 0.0), 1.0)
    return 1.0 - (1.0 - x) ** 3


def ease_in_out(x: float) -> float:
    x = min(max(x, 0.0), 1.0)
    return x * x * (3.0 - 2.0 * x)


def back_out(x: float, s: float = 1.7) -> float:
    """Hedefi aşıp geri oturan eğri (taşma)."""
    x = min(max(x, 0.0), 1.0) - 1.0
    return 1.0 + x * x * ((s + 1.0) * x + s)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def side(pose: dict, base: str, rot_l, mirror=(1, -1, -1), **extra) -> None:
    """Sol kemiğe rot_l, sağa aynası (Y ve Z ters)."""
    pose[base + "_l"] = {"rot": rot_l, **extra}
    pose[base + "_r"] = {"rot": (rot_l[0] * mirror[0], rot_l[1] * mirror[1], rot_l[2] * mirror[2]), **extra}


# --- klipler ------------------------------------------------------------------

def idle(t: float) -> dict:
    w = TAU * t / 2.4
    s = math.sin
    pose = {
        "pelvis": {"loc": (0.0, 0.0, 0.008 * s(2 * w))},
        "spine_01": {"rot": (3 + 2 * s(w), 0, 0)},
        "spine_02": {"rot": (2 + 1.5 * s(w + 0.4), 0, 0)},
        "neck_01": {"rot": (-2 * s(w + 0.8), 0, 0)},
        "Head": {"rot": (3 * s(w + 1.2), 4 * s(w * 0.5 + 1.0), 7 * s(w * 0.5))},
        "jaw_l": {"rot": (3 * s(2 * w), 0, 3 * s(3 * w))},
        "jaw_r": {"rot": (3 * s(2 * w + 1.3), 0, -3 * s(3 * w + 0.7))},
        "sac": {"scale": 1.0 + 0.07 * s(2 * w)},
    }
    side(pose, "upperarm", (3 * s(w + math.pi), 0, 0))
    side(pose, "lowerarm", (-3 + 3 * s(w + math.pi + 0.5), 0, 0))
    side(pose, "hand", (5 * s(w + 1.0), 0, 0))
    return pose


def walk(t: float, cycle: float = 0.9) -> dict:
    """Kambur, sürüklenen kollu, hafif aksak yürüyüş (iki adım)."""
    w = TAU * t / cycle
    s, c = math.sin, math.cos
    pose = {
        "pelvis": {"loc": (0.0, 0.0, -0.03 * c(2 * w) + 0.01), "rot": (0, 3 * s(w), 6 * s(w))},
        "spine_01": {"rot": (2 + 2 * c(2 * w), 0, -3 * s(w))},
        "spine_02": {"rot": (1, -2 * s(w), -6 * s(w))},
        "neck_01": {"rot": (-2 * c(2 * w), 0, 3 * s(w))},
        "Head": {"rot": (4 * c(2 * w - 0.5), -2 * s(w), -4 * s(w))},
        "jaw_l": {"rot": (6 * c(2 * w - 0.9), 0, 2 * c(2 * w - 1.2))},
        "jaw_r": {"rot": (6 * c(2 * w - 1.1), 0, -2 * c(2 * w - 1.4))},
        "sac": {"scale": 1.0 + 0.09 * c(2 * w - 0.8)},
    }
    for name, phase, sx in (("_l", 0.0, 1.0), ("_r", math.pi, -1.0)):
        ph = w + phase
        thigh = -26 * s(ph)
        swing = max(0.0, c(ph))
        calf = 8 + 42 * swing ** 1.5
        pose["thigh" + name] = {"rot": (thigh, 0, 0)}
        pose["calf" + name] = {"rot": (calf, 0, 0)}
        pose["foot" + name] = {"rot": (-(thigh + calf) * 0.55 + 6, 0, 0)}
        # kollar bacağın tersine, gecikmeli ve gevşek savrulur
        pose["upperarm" + name] = {"rot": (18 * s(ph), 4 * sx, 0)}
        pose["lowerarm" + name] = {"rot": (-10 + 9 * s(ph - 0.7), 0, 0)}
        pose["hand" + name] = {"rot": (12 * s(ph - 1.3), 0, 0)}
    return pose


WINDUP_TIME = 0.8


def windup_pose(p: float, t: float) -> dict:
    """p: 0..1 hazırlık ilerlemesi. Önce küçük çöküş, sonra geriye gerilme; kese şişer, titrer."""
    dip = math.sin(min(p / 0.25, 1.0) * math.pi) * (1.0 if p < 0.25 else 0.0)
    q = ease_in_out(max(0.0, (p - 0.1) / 0.9))
    quiver = math.sin(t * 46.0) * q
    pose = {
        "pelvis": {"loc": (0.0, 0.03 * q, -0.03 * dip - 0.05 * q)},
        "spine_01": {"rot": (6 * dip - 14 * q, 0, 0)},
        "spine_02": {"rot": (4 * dip - 12 * q, 0, 0)},
        "neck_01": {"rot": (-16 * q, 0, 0)},
        "Head": {"rot": (8 * dip - 26 * q + 1.5 * quiver, 0, 0)},
        "jaw_l": {"rot": (22 * q + 2 * quiver, 0, 18 * q)},
        "jaw_r": {"rot": (22 * q - 2 * quiver, 0, -18 * q)},
        "sac": {"scale": 1.0 + 0.75 * q + 0.06 * quiver},
    }
    side(pose, "upperarm", (14 * q, 16 * q, 0))
    side(pose, "lowerarm", (-25 * q, 0, 0))
    side(pose, "hand", (-20 * q, 0, 0))
    side(pose, "thigh", (-12 * q, 0, 0))
    side(pose, "calf", (22 * q, 0, 0))
    side(pose, "foot", (-10 * q, 0, 0))
    return pose


def windup(t: float) -> dict:
    return windup_pose(t / WINDUP_TIME, t)


def lash(t: float) -> dict:
    """Hazırlığın sonundan öne şaklama: kafa fırlar, çene sonuna dek açılır, kese söner."""
    start = windup_pose(1.0, 0.0)
    snap = back_out(t / 0.12, 2.2)
    settle = ease_in_out((t - 0.12) / 0.23)
    target = {
        "pelvis": {"loc": (0.0, -0.07, -0.02)},
        "spine_01": {"rot": (14, 0, 0)},
        "spine_02": {"rot": (10, 0, 0)},
        "neck_01": {"rot": (12, 0, 0)},
        "Head": {"rot": (20, 0, 0)},
        "jaw_l": {"rot": (36, 0, 30)},
        "jaw_r": {"rot": (36, 0, -30)},
        "sac": {"scale": 0.7},
    }
    side(target, "upperarm", (-22, 8, 0))
    side(target, "lowerarm", (-20, 0, 0))
    side(target, "hand", (-10, 0, 0))
    side(target, "thigh", (-18, 0, 0))
    side(target, "calf", (20, 0, 0))
    side(target, "foot", (0, 0, 0))
    end = pull(0.0)
    return _blend(_blend(start, target, snap), end, settle * 0.6)


def pull(t: float) -> dict:
    """Bağlıyken: geriye yaslanıp ritmik çekiş; kollar dönüşümlü pençeler, ayaklar dirençli."""
    w = TAU * t / 0.8
    s = math.sin
    yank = max(0.0, s(w)) ** 2
    pose = {
        "pelvis": {"loc": (0.0, 0.05 + 0.03 * yank, -0.06)},
        "spine_01": {"rot": (-6 - 8 * yank, 0, 0)},
        "spine_02": {"rot": (-4 - 6 * yank, 0, 0)},
        "neck_01": {"rot": (-6 - 6 * yank, 0, 0)},
        "Head": {"rot": (-8 - 12 * yank, 0, 3 * s(w * 0.5))},
        "jaw_l": {"rot": (20 + 4 * yank, 0, 16)},
        "jaw_r": {"rot": (20 + 4 * yank, 0, -16)},
        "sac": {"scale": 0.75 + 0.05 * s(2 * w)},
        "thigh_l": {"rot": (-16, 0, 0)}, "calf_l": {"rot": (18, 0, 0)}, "foot_l": {"rot": (-2, 0, 0)},
        "thigh_r": {"rot": (14, 0, 0)}, "calf_r": {"rot": (22, 0, 0)}, "foot_r": {"rot": (-30, 0, 0)},
    }
    for name, phase, sx in (("_l", 0.0, 1.0), ("_r", math.pi, -1.0)):
        reach = s(w + phase)
        pose["upperarm" + name] = {"rot": (-28 + 26 * reach, 6 * sx, 0)}
        pose["lowerarm" + name] = {"rot": (-38 + 22 * reach, 0, 0)}
        pose["hand" + name] = {"rot": (-15 - 15 * reach, 0, 0)}
    return pose


def stagger(t: float) -> dict:
    hit = ease_out(t / 0.1) * (1.0 - ease_in_out((t - 0.1) / 0.35))
    pose = {
        "pelvis": {"loc": (0.0, 0.06 * hit, -0.02 * hit)},
        "spine_01": {"rot": (-16 * hit, 0, 4 * hit)},
        "spine_02": {"rot": (-10 * hit, 0, 0)},
        "Head": {"rot": (-22 * hit, 8 * hit, 0)},
        "jaw_l": {"rot": (14 * hit, 0, 10 * hit)},
        "jaw_r": {"rot": (14 * hit, 0, -10 * hit)},
        "sac": {"scale": 1.0 + 0.2 * hit},
    }
    side(pose, "upperarm", (20 * hit, 22 * hit, 0))
    side(pose, "lowerarm", (-20 * hit, 0, 0))
    return pose


def death(t: float) -> dict:
    """Dizler çöker, geriye devrilir, sırtüstü yere oturur ve küçük bir sekme."""
    buckle = ease_in_out(t / 0.3)
    fall = ease_in_out((t - 0.2) / 0.75)
    bounce = math.sin(min(max((t - 0.95) / 0.3, 0.0), 1.0) * math.pi) * 0.04
    pose = {
        "pelvis": {"loc": (0.0, 0.15 * fall, -0.25 * buckle * (1.0 - fall) - 0.84 * fall + bounce),
                   "rot": (-85 * fall, 0, 10 * fall)},
        "spine_01": {"rot": (10 * buckle - 15 * fall, 0, 0)},
        "spine_02": {"rot": (-10 * fall, 0, 0)},
        "neck_01": {"rot": (-10 * fall, 0, 0)},
        "Head": {"rot": (-25 * fall, 15 * fall, 20 * fall)},
        "jaw_l": {"rot": (30 * fall, 0, 24 * fall)},
        "jaw_r": {"rot": (30 * fall, 0, -24 * fall)},
        "sac": {"scale": 1.0 - 0.35 * fall},
    }
    # çöken dizler düşerken açılır; kalça devrildiği için bacaklar öne, yere uzanır
    side(pose, "thigh", (-35 * buckle * (1.0 - fall) - 5 * fall, 6 * fall, 0))
    side(pose, "calf", (55 * buckle * (1.0 - fall) + 12 * fall, 0, 0))
    # gövde geriye devrilince kollar iki yana, yere yığılır (havaya dikilmez)
    side(pose, "upperarm", (-10 * buckle + 75 * fall, 35 * fall, 0))
    side(pose, "lowerarm", (-15 * fall, 0, 0))
    side(pose, "hand", (20 * fall, 0, 0))
    return pose


def spawn(t: float) -> dict:
    """Yerden kalkış: çömelmiş ve öne kapanmış gövde açılır, kafa en son kalkar."""
    rise = ease_out(t / 0.8)
    head = ease_out((t - 0.25) / 0.65)
    low = 1.0 - rise
    pose = {
        "pelvis": {"loc": (0.0, 0.0, -0.45 * low)},
        "spine_01": {"rot": (35 * low, 0, 0)},
        "spine_02": {"rot": (25 * low, 0, 0)},
        "Head": {"rot": (30 * (1.0 - head), 0, 0)},
        "sac": {"scale": 1.0 + 0.15 * math.sin(head * math.pi)},
    }
    side(pose, "thigh", (-70 * low, 0, 0))
    side(pose, "calf", (110 * low, 0, 0))
    side(pose, "foot", (-40 * low, 0, 0))
    side(pose, "upperarm", (-30 * low, 10 * low, 0))
    return pose


CLIPS = [("idle_Loop", idle, 2.4), ("walk_Loop", walk, 0.9), ("windup", windup, WINDUP_TIME),
         ("lash", lash, 0.35), ("pull_Loop", pull, 0.8), ("stagger", stagger, 0.45),
         ("death_a", death, 1.3), ("spawn", spawn, 0.9)]


# --- anahtarlama -----------------------------------------------------------------

def _blend(a: dict, b: dict, t: float) -> dict:
    out = {}
    for name in set(a) | set(b):
        ca, cb = a.get(name, {}), b.get(name, {})
        ch = {}
        for key, zero in (("rot", (0, 0, 0)), ("loc", (0, 0, 0))):
            if key in ca or key in cb:
                va, vb = ca.get(key, zero), cb.get(key, zero)
                ch[key] = tuple(lerp(va[i], vb[i], t) for i in range(3))
        if "scale" in ca or "scale" in cb:
            ch["scale"] = lerp(ca.get("scale", 1.0), cb.get("scale", 1.0), t)
        out[name] = ch
    return out


def _apply(arm, pose: dict, frame: int) -> None:
    for pb in arm.pose.bones:
        ch = pose.get(pb.name, {})
        rest = pb.bone.matrix_local.to_quaternion()
        rot = ch.get("rot", (0, 0, 0))
        q = Euler(tuple(math.radians(a) for a in rot), "XYZ").to_quaternion()
        pb.rotation_quaternion = rest.inverted() @ q @ rest
        pb.location = rest.inverted() @ Vector(ch.get("loc", (0, 0, 0)))
        sc = ch.get("scale", 1.0)
        pb.scale = (sc, sc, sc)
        pb.keyframe_insert("rotation_quaternion", frame=frame, group=pb.name)
        pb.keyframe_insert("location", frame=frame, group=pb.name)
        pb.keyframe_insert("scale", frame=frame, group=pb.name)


def build_clip(arm, name: str, fn, length: float):
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    arm.animation_data.action = action
    last = round(length * FPS)
    frames = list(range(0, last, STEP)) + [last]
    for f in frames:
        _apply(arm, fn(f / FPS), f + 1)
    action.use_frame_range = True
    action.frame_start, action.frame_end = 1, last + 1
    return action


def build_all(arm) -> list:
    # dışa aktarıcı sahne FPS'ini kullanır; kareler 30 FPS'e göre anahtarlandı
    bpy.context.scene.render.fps = FPS
    bpy.context.scene.render.fps_base = 1.0
    if arm.animation_data is None:
        arm.animation_data_create()
    names = []
    for name, fn, length in CLIPS:
        build_clip(arm, name, fn, length)
        names.append(name)
    arm.animation_data.action = bpy.data.actions["idle_Loop"]
    return names
