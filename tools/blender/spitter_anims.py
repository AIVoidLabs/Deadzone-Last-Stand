"""Tükürücü (spitter) klipleri — elle anahtarlanmış anahtar pozlar, kodla yeniden üretilir (7.3).

İmza `spit` (1.3 sn): durur → geriye kasılır (gövde geriye gerilir, kollar geri-dışa, kafa geride, ağız kapalı),
gırtlak kesesi şişer (neck_01 ölçek anahtarı) ve titrer → 0.8 sn'de (kare 24) öne bir hamle: sağ ayak öne
basar, gövde ve boyun öne fırlar, çene sonuna dek açılır, kese söner = BIRAKIŞ anı (oyun LobAttack asit
topunu bu anda ağız ucundan çıkarır) → takip, ayak geri çekilir, duruşa döner.
Ölçek sözleşmesi: yalnız neck_01 ölçeklenir (kese bu kemiğe ağırlıklı); çocuğu Head'de 1/k ile geri alınır
(kafa boyut değiştirmez). İki kemiğin ölçeği her klipte her karede anahtarlanır (tek tip; glTF/Godot taşır).

Poz çekirdeği, bacak IK'sı ve açı sözleşmesi walker_pose.py'de (iskelet uzayı, derece; X+ öne eğilme /
sarkan kolda geriye savrulma, Y+ sola yatma, Z+ sola dönme). Kollar FK. Döngüler `_Loop` ekli.

Oyun sözleşmesi (s73_design, GAME_PACE sonrası):
  walk   : 0.9 sn döngü, referans hız 1.92 m/sn (oyun boyu 1.7 m'de; model uzayında mesh_h/1.7 ile).
  spit   : 1.3 sn, bırakış = 0.8 sn. idle 2.0 (döngü), stagger 0.33.
  death_a 1.5, death_b 1.5, spawn 1.0: spitter_falls.py.
"""
import math

import bpy

import walker_pose as wp
from walker_pose import cyc, merge, track

TAU = math.tau
SCALE_BONES = ("neck_01", "Head")

# --- yürüyüş (kambur, öne düşen sekişli adım) ------------------------------------------
GAME_SPEED = 1.92         # = 2.4 * GAME_PACE (m/sn)
GAME_HEIGHT = 1.7         # = EnemyData spitter height
WALK_FRAMES = 27
WALK_CYCLE = WALK_FRAMES / wp.FPS      # 0.9 sn, iki adım
DUTY = 0.36               # basış payı: kısa uçuş evresi (öne düşer gibi sekişli adım)
R_STANCE = (0.0, DUTY)
L_STANCE = (0.5, 0.5 + DUTY)
CENTER = -0.04            # basış ortası dinlenmeye göre önde (m, rig.s ile)
LIFT = 0.10
CROUCH = 0.10
SPREAD = 0.02
SWAY = 0.035
LIFTOFF_FOLLOW = 0.9


def walk_speed(rig):
    h = getattr(rig, "mesh_h", None) or GAME_HEIGHT
    return GAME_SPEED * h / GAME_HEIGHT


def _hermite(p0, p1, m0, m1, u):
    u2, u3 = u * u, u * u * u
    return (2 * u3 - 3 * u2 + 1) * p0 + (u3 - 2 * u2 + u) * m0 + (-2 * u3 + 3 * u2) * p1 + (u3 - u2) * m1


def _ease(u, keys):
    return track(u, [(k, {"v": {"x": val}}) for k, val in keys])["v"]["x"]


def foot_track(phi, rng, rig):
    v = walk_speed(rig) * WALK_CYCLE
    dur = rng[1] - rng[0]
    reach = v * dur
    c = CENTER * rig.s
    u = ((phi - rng[0]) % 1.0) / dur
    if u <= 1.0:
        return c - reach / 2 + reach * u, u, True
    w = (u - 1.0) * dur / (1.0 - dur)
    m = v * (1.0 - dur)
    return _hermite(c + reach / 2, c - reach / 2, LIFTOFF_FOLLOW * m, m, w), w, False


def walk_feet(phi, rig):
    feet = {}
    for side, rng, sx in (("r", R_STANCE, -1.0), ("l", L_STANCE, 1.0)):
        y, u, down = foot_track(phi, rng, rig)
        if down:      # topukla basar, düzleşir, parmaktan iter
            pitch, lift = _ease(u, [(0.0, -8.0), (0.12, 0.0), (0.55, 0.0), (0.80, 12.0), (1.0, 28.0)]), 0.0
        else:         # ayak sürünür gibi alçak gelir
            pitch = _ease(u, [(0.0, 28.0), (0.2, 44.0), (0.45, 20.0), (0.75, -4.0), (1.0, -8.0)])
            lift = LIFT * rig.s * math.sin(math.pi * u) ** 0.8
        feet[side] = (y, pitch, lift, sx * SPREAD * rig.s)
    return feet["l"], feet["r"]


def walk(t, rig):
    phi = (t / WALK_CYCLE) % 1.0
    s = rig.s
    # basışta gövde çöker ve kambur öne düşer (kafa ileri sarsılır, kese sallanır)
    dz = cyc(phi, [(0.03, -0.035), (0.25, 0.020), (0.53, -0.035), (0.75, 0.020)])
    sway = cyc(phi, [(0.0, -0.3), (0.2, -1.0), (0.5, 0.3), (0.7, 1.0)]) * SWAY
    roll = cyc(phi, [(0.05, -5.0), (0.30, -1.0), (0.55, 5.0), (0.80, 1.0)])
    yaw = cyc(phi, [(0.0, 9.0), (0.25, 0.0), (0.5, -9.0), (0.75, 0.0)])
    bob = cyc(phi - 0.05, [(0.0, 0.0), (0.07, 1.0), (0.20, -0.4), (0.32, 0.0),
                           (0.5, 0.0), (0.57, 1.0), (0.70, -0.4), (0.82, 0.0)])
    l_foot, r_foot = walk_feet(phi, rig)
    pose = {
        "pelvis": {"loc": (sway * s, 0.0, (dz - CROUCH) * s), "rot": (8.0, roll, yaw)},
        "spine_01": {"rot": (4.0 + 2.0 * bob, -0.5 * roll, -0.6 * yaw)},
        "spine_02": {"rot": (3.0 + 2.5 * bob, -0.3 * roll, -0.3 * yaw)},
        "spine_03": {"rot": (2.0, -0.2 * roll, 0.0)},
        "neck_01": {"rot": (-8.0 - 3.0 * bob, 0.3 * roll, 0.3 * yaw), "scale": 1.0 + 0.02 * bob},
        "Head": {"rot": (-6.0 + 5.0 * bob, 0.3 * roll, 0.4 * yaw)},
        "jaw": {"rot": (cyc(phi, [(0.05, 18.0), (0.3, 10.0), (0.55, 18.0), (0.8, 10.0)]), 0.0, 0.0)},
        "ik_l": {"foot": l_foot},
        "ik_r": {"foot": r_foot},
    }
    for sd, ph, sy in (("l", 0.5, 1.0), ("r", 0.0, -1.0)):   # uzun kollar sarkık, gecikmeli savrulur
        sw = cyc(phi - 0.12 + ph, [(0.0, -16.0), (0.5, 16.0)])
        pose["clavicle_" + sd] = {"rot": (0.0, sy * 0.3 * roll, 0.0)}
        pose["upperarm_" + sd] = {"rot": (sw, sy * -3.0, 0.0)}
        pose["lowerarm_" + sd] = {"rot": (cyc(phi - 0.25 + ph, [(0.0, -14.0), (0.5, 6.0)]), 0.0, 0.0)}
        pose["hand_" + sd] = {"rot": (cyc(phi - 0.35 + ph, [(0.0, -12.0), (0.5, 12.0)]), 0.0, 0.0)}
    return pose


def side(pose, base, rot_l, **extra):
    pose[base + "_l"] = {"rot": tuple(rot_l), **extra}
    pose[base + "_r"] = {"rot": (rot_l[0], -rot_l[1], -rot_l[2]), **extra}
    return pose


def stand(rig, crouch=0.02, spread=0.0):
    sp = spread * rig.s
    return {"pelvis": {"loc": (0.0, 0.0, -crouch * rig.s), "rot": (0.0, 0.0, 0.0)},
            "ik_l": {"foot": (0.0, 0.0, 0.0, sp)}, "ik_r": {"foot": (0.0, 0.0, 0.0, -sp)}}


def swell(pose, k):
    """Gırtlak kesesi ölçeği k: neck_01 şişer, kafa 1/k ile eski boyunda kalır."""
    pose.setdefault("neck_01", {})["scale"] = k
    return pose


# --- bekleme ------------------------------------------------------------------------------
IDLE_CYCLE = 2.0


def idle(t, rig):
    """Hırıltılı nefes: kese kabarıp iner (ölçek), kambur iner-kalkar, kafa sallanır, kollar sarkık."""
    phi = (t / IDLE_CYCLE) % 1.0
    w = TAU * phi
    breath = cyc(phi, [(0.0, 0.0), (0.35, 1.0), (0.55, 0.85), (0.85, 0.0)])
    pose = merge(stand(rig, 0.03 + 0.01 * (1 - breath)), {
        "pelvis": {"loc": (0.006 * rig.s * math.sin(w), 0.0, -(0.03 + 0.01 * (1 - breath)) * rig.s),
                   "rot": (2.0, 1.5 * math.sin(w), 2.0 * math.sin(w))},
        "spine_01": {"rot": (1.0 - 1.5 * breath, -0.8 * math.sin(w), 0.0)},
        "spine_02": {"rot": (2.0 - 3.0 * breath, 0.0, -1.0 * math.sin(w))},
        "neck_01": {"rot": (-2.0 * breath, 0.0, 0.0), "scale": 1.0 + 0.06 * breath},
        "Head": {"rot": (1.0 - 5.0 * breath, 3.0 * math.sin(w + 0.6), 6.0 * math.sin(w + 0.3))},
        "jaw": {"rot": (8.0 + 12.0 * (1.0 - breath), 0.0, 0.0)},
    })
    for sd, ph, sy in (("l", 0.0, 1.0), ("r", 1.3, -1.0)):
        pose["upperarm_" + sd] = {"rot": (4.0 * math.sin(w + ph), sy * -2.0 * breath, 0.0)}
        pose["lowerarm_" + sd] = {"rot": (-5.0 + 5.0 * math.sin(w + ph - 0.6), 0.0, 0.0)}
        pose["hand_" + sd] = {"rot": (8.0 * math.sin(w + ph - 1.2), 0.0, 0.0)}
    return pose


# --- imza: tükürme -------------------------------------------------------------------------
SPIT_TIME = 1.3
SPIT_RELEASE = 0.8        # = attack_windup; bırakış karesi 24
SPIT_PEAK = 1.38


def _coil(rig, k, arch, arms, head, jaw, jit=0.0, crouch=0.06):
    """Geriye kasılma: diz kırık, gövde geriye gerilir, kollar geri-dışa, kafa geride; titreme `jit`."""
    s = rig.s
    pose = merge(stand(rig, crouch, 0.02), {
        "pelvis": {"loc": (0.0, 0.04 * s * arch / 12.0, -crouch * s), "rot": (-0.4 * arch, 0.6 * jit, 0.4 * jit)},
        "spine_01": {"rot": (-0.4 * arch, -0.8 * jit, 0.0)},
        "spine_02": {"rot": (-0.5 * arch, jit, 0.0)},
        "spine_03": {"rot": (-0.3 * arch, 0.0, 0.0)},
        "neck_01": {"rot": (-0.5 * arch, -jit, 0.0)},
        "Head": {"rot": (head, 1.5 * jit, -jit)},
        "jaw": {"rot": (jaw, 0.0, 0.0)},
    })
    side(pose, "clavicle", (0.0, -0.2 * arms, 0.0))
    side(pose, "upperarm", (arms, -0.5 * arms, 0.0))
    side(pose, "lowerarm", (-0.4 * arms, 0.0, 0.0))
    side(pose, "hand", (0.5 * arms, 0.0, 0.0))
    return swell(pose, k)


def _lunge(rig, k, fwd, head, jaw, step, lift=0.0, arms=-10.0):
    """Öne hamle: sağ ayak öne basar, gövde ve boyun öne fırlar, çene açılır."""
    s = rig.s
    pose = merge(stand(rig, 0.10, 0.02), {
        "pelvis": {"loc": (0.0, -0.08 * s * fwd / 14.0, -0.10 * s), "rot": (0.5 * fwd, 0.0, -4.0)},
        "spine_01": {"rot": (0.5 * fwd, 0.0, -2.0)},
        "spine_02": {"rot": (0.6 * fwd, 0.0, 0.0)},
        "spine_03": {"rot": (0.4 * fwd, 0.0, 0.0)},
        "neck_01": {"rot": (0.6 * fwd, 0.0, 0.0)},
        "Head": {"rot": (head, 0.0, 0.0)},
        "jaw": {"rot": (jaw, 0.0, 0.0)},
        "ik_r": {"foot": (-step * s, -4.0 if lift == 0.0 else 10.0, lift * s, -0.02 * s)},
        "ik_l": {"foot": (0.0, 14.0 * min(step / 0.18, 1.0), 0.0, 0.02 * s)},
    })
    side(pose, "clavicle", (0.0, 0.0, 0.0))
    side(pose, "upperarm", (arms, -10.0, 0.0))
    side(pose, "lowerarm", (-18.0, 0.0, 0.0))
    side(pose, "hand", (-10.0, 0.0, 0.0))
    return swell(pose, k)


def spit(t, rig):
    """0 duruş → 0.25 kasılmaya başlar → 0.55 tam kasılma, kese şiş → 0.62-0.74 titrer, en şiş →
    0.80 BIRAKIŞ (öne hamle, ağız sonuna dek açık, kese söner) → 0.92 takip → 1.3 duruş."""
    keys = [(0.0, swell(stand(rig), 1.0)),
            (0.25, _coil(rig, 1.12, 8.0, 14.0, -12.0, 4.0, crouch=0.04)),
            (0.55, _coil(rig, 1.30, 16.0, 28.0, -24.0, 3.0, crouch=0.07))]
    for tk, k, jit in ((0.62, 1.33, 2.5), (0.67, 1.36, -3.0), (0.71, SPIT_PEAK, 3.0)):
        keys.append((tk, _coil(rig, k, 17.0, 30.0, -26.0, 5.0, jit, crouch=0.08)))
    keys += [(0.75, _lunge(rig, 1.25, 4.0, -18.0, 18.0, 0.09, lift=0.06, arms=20.0)),
             (SPIT_RELEASE, _lunge(rig, 0.95, 16.0, -8.0, 40.0, 0.18)),
             (0.92, _lunge(rig, 0.92, 20.0, 4.0, 34.0, 0.18, arms=-16.0)),
             (1.05, _lunge(rig, 0.97, 10.0, 0.0, 20.0, 0.18, arms=-6.0)),
             (1.17, _lunge(rig, 1.0, 4.0, 0.0, 14.0, 0.08, lift=0.05, arms=0.0)),
             (SPIT_TIME, swell(stand(rig), 1.0))]
    return track(t, keys)


# --- tepki ----------------------------------------------------------------------------------
STAGGER_TIME = 0.33


def stagger(t, rig):
    """Darbe: kambur geri sarsılır, kafa savrulur, kese sallanır (ölçek), kollar açılır."""
    s = rig.s
    hit = merge(stand(rig, 0.04), {
        "pelvis": {"loc": (0.0, 0.04 * s, -0.04 * s), "rot": (-5.0, 2.0, -4.0)},
        "spine_01": {"rot": (-5.0, 0.0, 0.0)}, "spine_02": {"rot": (-6.0, 3.0, 0.0)},
        "neck_01": {"rot": (-6.0, 0.0, 0.0), "scale": 0.94},
        "Head": {"rot": (-16.0, 6.0, 6.0)}, "jaw": {"rot": (30.0, 0.0, 0.0)},
    })
    side(hit, "upperarm", (10.0, -14.0, 0.0))
    side(hit, "lowerarm", (-14.0, 0.0, 0.0))
    wobble = merge(stand(rig, 0.03), {"neck_01": {"rot": (2.0, 0.0, 0.0), "scale": 1.05},
                                      "spine_02": {"rot": (2.0, 0.0, 0.0)},
                                      "Head": {"rot": (4.0, -2.0, 0.0)}, "jaw": {"rot": (16.0, 0.0, 0.0)}})
    return track(t, [(0.0, swell(stand(rig), 1.0)), (0.06, hit), (0.17, wobble),
                     (0.25, swell(stand(rig, 0.025), 0.99)), (STAGGER_TIME, swell(stand(rig), 1.0))])


CLIPS = [("idle_Loop", idle, IDLE_CYCLE), ("walk_Loop", walk, WALK_CYCLE), ("spit", spit, SPIT_TIME),
         ("stagger", stagger, STAGGER_TIME)]


# --- anahtarlama (ölçekli) ----------------------------------------------------------------

def apply(rig, pose, frame):
    """walker_pose.apply + ölçek anahtarları (SCALE_BONES her karede)."""
    k = pose.get("neck_01", {}).get("scale", 1.0)
    clean = {n: {c: v for c, v in ch.items() if c != "scale"} for n, ch in pose.items()}
    wp.apply(rig, clean, frame)
    for name in SCALE_BONES:
        pb = rig.arm.pose.bones[name]
        f = k if name == "neck_01" else 1.0 / k
        pb.scale = (f, f, f)
        pb.keyframe_insert("scale", frame=frame, group=pb.name)


def build_clip(rig, name, fn, length):
    arm = rig.arm
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    arm.animation_data.action = action
    last = round(length * wp.FPS)
    for f in range(last + 1):
        apply(rig, fn(f / wp.FPS, rig), f)
    action.use_frame_range = True
    action.frame_start, action.frame_end = 0, last
    for pb in arm.pose.bones:
        pb.scale = (1.0, 1.0, 1.0)
    return action


def mesh_height(arm):
    for obj in bpy.data.objects:
        if obj.type == "MESH" and any(m.type == "ARMATURE" and m.object == arm for m in obj.modifiers):
            mw = arm.matrix_world.inverted() @ obj.matrix_world
            return max((mw @ v.co).z for v in obj.data.vertices)
    return 0.0


def build_all(arm) -> list:
    import importlib
    import spitter_falls
    importlib.reload(spitter_falls)
    bpy.context.scene.render.fps = wp.FPS
    bpy.context.scene.render.fps_base = 1.0
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.data.pose_position = "REST"
    rig = wp.Rig(arm)
    rig.mesh_h = mesh_height(arm)
    arm.data.pose_position = "POSE"
    names = []
    for name, fn, length in CLIPS + spitter_falls.CLIPS:
        build_clip(rig, name, fn, length)
        names.append(name)
    arm.animation_data.action = bpy.data.actions[CLIPS[0][0]]
    print("SPITTER ANIMS", names, "IK clamped frames:", rig.clamped, "rig.s %.3f" % rig.s,
          "mesh_h %.3f" % rig.mesh_h)
    return names
