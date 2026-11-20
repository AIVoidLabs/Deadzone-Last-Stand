"""Zıplayan klipleri (V.5 v2) — elle anahtarlanmış anahtar pozlar, kodla yeniden üretilir.

Poz çekirdeği walker_pose.py (aradeğerleme, bacak/kol IK, anahtarlama; o dosya değişmez). Sözleşme aynı:
açılar iskelet uzayında derece, ebeveyne göre; X+ yukarı uzanan kemikte öne eğilme, aşağı sarkan kol/bacakta
geriye savrulma; loc yalnız pelvis'te (m). Bacaklar ayak hedefiyle ("ik_l/ik_r": (y, pitch, lift, dx)),
basan ayak IK ile yerde kilitli. Kollar yere değdiği pozlarda bilek hedefiyle (hand_at), sonra FK'ya çözülür.
Döngüler `_Loop` ekiyle (Godot eki atıp döngü yapar → oyunda `idle`, `walk`).

Oyun sözleşmesi (EnemyData jumper, GAME_PACE 0.8 sonrası):
  walk_Loop  ref hız REF_SPEED (model uzayı m/sn). Oyun klibi gerçek hız / REF_SPEED ile oynatır; EnemyData
             height ≠ ağ boyu ise model ölçeklenir, ref hız da aynı oranla ölçeklenmelidir.
  crouch 0.7 = attack_windup (sonu patlamaya hazır; leap'in ilk karesi aynı poz)
  leap 0.9   = jump_time (yalnız gövde pozu; yayı oyun kodu çizer)
  land 0.8   iniş; şok anı 0.0 (eller yere vurmuş), sonra doğrulur; attack_recover 1.6 sn'nin başı.
"""
import math

from mathutils import Vector

import walker_pose as wp
from walker_pose import cyc, merge, track

TAU = math.tau
REF_SPEED = 2.4           # m/sn, model uzayı (EnemyData jumper yürüme ~2.4)
WALK_CYCLE = 0.70         # sn, iki adım (21 kare)
R_STANCE = (0.0, 0.42)    # basış evresi; aralarda kısa uçuş (yaylı, sıçrar gibi yürüyüş)
L_STANCE = (0.50, 0.92)
STANCE_CENTER = -0.02     # basış ortasında parmak ekleminin mutlak y'si (m): kalçanın biraz önü
SWING_LIFT = 0.17         # salınımda ayak kalkışı (m)
LIFTOFF_FOLLOW = 0.4
IDLE_CYCLE = 2.0
CROUCH_TIME, LEAP_TIME, LAND_TIME, STAGGER_TIME = 0.7, 0.9, 0.8, 0.35


def side(pose, base, rot_l, **extra):
    pose[base + "_l"] = {"rot": tuple(rot_l), **extra}
    pose[base + "_r"] = {"rot": (rot_l[0], -rot_l[1], -rot_l[2]), **extra}
    return pose


def feet(rig, y=0.0, pitch=0.0, lift=0.0, dx=0.0):
    """İki ayak aynı hedef (dx: dışa)."""
    s = rig.s
    return {"ik_l": {"foot": (y * s, pitch, lift * s, dx * s)}, "ik_r": {"foot": (y * s, pitch, lift * s, -dx * s)}}


def stand(rig, crouch=0.0):
    return merge({"pelvis": {"loc": (0.0, 0.0, -crouch * rig.s), "rot": (0.0, 0.0, 0.0)}}, feet(rig))


def arms_fk(rig, pose):
    """Kol IK girdilerini dönüşe çevirir (FK pozlarla aradeğerlensin diye)."""
    return wp.solve_arms(rig, {k: dict(v) for k, v in pose.items()})


def hand_at(rig, pose, point_l, out=0.25):
    """Bilekleri iskelet uzayında noktaya koyar (sol için; sağ X aynası). Pozu FK'ya çevirip döner."""
    q03, h03 = wp._fk_chest(rig, pose)
    for sd, sx in (("l", 1.0), ("r", -1.0)):
        p = Vector((point_l[0] * sx * rig.s, point_l[1] * rig.s, point_l[2]))
        rel = q03.inverted() @ (p - h03) + rig.head["spine_03"] - rig.head["hand_" + sd]
        pose["arm_" + sd] = {"hand": tuple(rel), "out": out}
    return arms_fk(rig, pose)


# --- bekleme -------------------------------------------------------------------------

def idle(t, rig):
    """Yaylı bekleme: dizlerde küçük sekme, solukla omuz kalkar, kafa seğirir, çene ağır oynar."""
    phi = (t / IDLE_CYCLE) % 1.0
    w = TAU * phi
    s = rig.s
    bounce = 0.012 * (1 - math.cos(2 * w)) + 0.006 * (1 - math.cos(4 * w))
    shift = 0.018 * math.sin(w)
    pose = merge(stand(rig, 0.01 + bounce), {
        "pelvis": {"loc": (shift * s, 0.0, -(0.01 + bounce) * s), "rot": (2.0 * math.sin(2 * w), 40 * shift, 3 * math.sin(w))},
        "spine_01": {"rot": (1.5 * math.sin(2 * w + 0.5), -30 * shift, 0.0)},
        "spine_02": {"rot": (-2.0 * math.sin(2 * w + 0.9), 0.0, -3 * math.sin(w))},
        "spine_03": {"rot": (-1.5 * math.sin(2 * w + 1.2), 0.0, 0.0)},
        "neck_01": {"rot": (2 * math.sin(w + 0.6), 0.0, 0.0)},
        "Head": {"rot": (3 * math.sin(2 * w + 1.4), cyc(phi, [(0.0, -4.0), (0.3, -6.0), (0.33, 5.0), (0.7, 3.0)]),
                         cyc(phi, [(0.0, 0.0), (0.45, 8.0), (0.5, -6.0), (0.8, -4.0)]))},
        "jaw": {"rot": (cyc(phi, [(0.0, 2.0), (0.2, 9.0), (0.45, 0.0), (0.7, 6.0), (0.85, 1.0)]), 0.0, 0.0)},
    })
    for sd, ph in (("l", 0.0), ("r", 1.7)):
        pose["clavicle_" + sd] = {"rot": (0.0, 0.0, 0.0)}
        pose["upperarm_" + sd] = {"rot": (3 * math.sin(w + ph), 0.0, 0.0)}
        pose["lowerarm_" + sd] = {"rot": (4 * math.sin(w + ph - 0.7), 0.0, 0.0)}
        pose["hand_" + sd] = {"rot": (6 * math.sin(w + ph - 1.4), 0.0, 0.0)}
    return pose


# --- yürüyüş -------------------------------------------------------------------------

def _span(phi, rng):
    return ((phi - rng[0]) % 1.0) / (rng[1] - rng[0])


def _hermite(p0, p1, m0, m1, u):
    u2, u3 = u * u, u * u * u
    return (2 * u3 - 3 * u2 + 1) * p0 + (u3 - 2 * u2 + u) * m0 + (-2 * u3 + 3 * u2) * p1 + (u3 - u2) * m1


def _foot(phi, rig, rng):
    """Basışta ayak REF_SPEED ile geri kayar (dünyada durur); salınımda Hermite ile öne döner."""
    v = REF_SPEED * WALK_CYCLE
    dur = rng[1] - rng[0]
    reach = v * dur
    c = STANCE_CENTER * rig.s
    u = _span(phi, rng)
    if u <= 1.0:
        return c - reach / 2 + reach * u, u, True
    w = (u - 1.0) * dur / (1.0 - dur)
    m = v * (1.0 - dur)
    return _hermite(c + reach / 2, c - reach / 2, LIFTOFF_FOLLOW * m, m, w), w, False


def _ease(u, keys):
    return track(u, [(k, {"v": {"x": val}}) for k, val in keys])["v"]["x"]


def walk_foot(phi, rig, rng, sd):
    y, u, down = _foot(phi, rig, rng)
    if down:    # parmak kökünden basar (topuk havada kalır), basış ortası dinlenme, parmaktan iter
        pitch, lift = _ease(u, [(0.0, 6.0), (0.25, 0.0), (0.6, 2.0), (0.85, 18.0), (1.0, 38.0)]), 0.0
    else:       # diz yukarı, ayak geride kıvrılır, inişe doğru parmak aşağı
        pitch = _ease(u, [(0.0, 38.0), (0.35, 30.0), (0.8, 10.0), (1.0, 6.0)])
        lift = SWING_LIFT * rig.s * math.sin(math.pi * u) ** 1.1
    sx = 1.0 if sd == "l" else -1.0
    return (y - rig.legs[sd]["ball0"].y, pitch, lift, 0.01 * sx * rig.s)


def walk(t, rig):
    phi = (t / WALK_CYCLE) % 1.0
    s = rig.s
    # iki basış (0, 0.5): basış ortasında yaylanıp çöker, uçuşta (0.46, 0.96) yükselir
    dz = cyc(phi, [(0.02, -0.02), (0.2, -0.065), (0.45, 0.025), (0.52, -0.02), (0.7, -0.065), (0.95, 0.025)])
    sway = cyc(phi, [(0.2, -0.025), (0.7, 0.025)])
    roll = cyc(phi, [(0.2, -4.0), (0.7, 4.0)])
    yaw = cyc(phi, [(0.0, 9.0), (0.5, -9.0)])
    lag = cyc(phi - 0.08, [(0.2, 5.0), (0.45, -3.0), (0.7, 5.0), (0.95, -3.0)])   # gövde basışta öne düşer
    pose = {
        "pelvis": {"loc": (sway * s, 0.0, (dz - 0.02) * s), "rot": (6.0 + 0.5 * lag, roll, yaw)},
        "spine_01": {"rot": (3.0 + 0.4 * lag, -0.4 * roll, -0.6 * yaw)},
        "spine_02": {"rot": (2.0 + 0.3 * lag, -0.3 * roll, -0.5 * yaw)},
        "spine_03": {"rot": (0.0, 0.0, -0.2 * yaw)},
        "neck_01": {"rot": (-4.0 - 0.6 * lag, 0.0, 0.0)},
        "Head": {"rot": (-6.0 - 0.5 * lag, 0.4 * roll, 0.5 * yaw)},
        "jaw": {"rot": (cyc(phi - 0.1, [(0.2, 8.0), (0.45, 2.0), (0.7, 8.0), (0.95, 2.0)]), 0.0, 0.0)},
        "ik_l": {"foot": walk_foot(phi, rig, L_STANCE, "l")},
        "ik_r": {"foot": walk_foot(phi, rig, R_STANCE, "r")},
    }
    # kollar karşı bacakla salınır (ağır, gecikmeli), dirsek salınım sonunda bükülür
    for sd, sgn in (("l", -1.0), ("r", 1.0)):
        sw = sgn * 24.0 * math.cos(TAU * (phi - 0.06))
        pose["clavicle_" + sd] = {"rot": (0.0, 0.0, -sgn * 3.0 * math.cos(TAU * phi))}
        pose["upperarm_" + sd] = {"rot": (sw - 4.0, 0.0, 0.0)}
        pose["lowerarm_" + sd] = {"rot": (-10.0 - 0.45 * max(0.0, -sw) + 0.15 * sw, 0.0, 0.0)}
        pose["hand_" + sd] = {"rot": (0.4 * sgn * 20 * math.cos(TAU * (phi - 0.18)), 0.0, 0.0)}
    return pose


# --- saldırı: çömelme → sıçrama → iniş ---------------------------------------------

def crouch_peak(rig, tremble=0.0):
    """Patlamaya hazır derin çömelme: kalça yere yakın ve geride, gövde öne, kollar geriye, kafa hedefe."""
    s = rig.s
    pose = merge({
        "pelvis": {"loc": (0.0, 0.10 * s, -0.37 * s), "rot": (26.0 + tremble, 0.0, 0.0)},
        "spine_01": {"rot": (8.0, 0.0, 0.0)}, "spine_02": {"rot": (6.0, 0.0, 0.0)},
        "spine_03": {"rot": (-6.0, 0.0, 0.0)}, "neck_01": {"rot": (-22.0, 0.0, 0.0)},
        "Head": {"rot": (-26.0 - tremble, 0.0, 0.0)}, "jaw": {"rot": (14.0 + 2 * tremble, 0.0, 0.0)},
    }, feet(rig, 0.0, 14.0, 0.0, 0.02))
    side(pose, "clavicle", (0.0, 0.0, 6.0))
    side(pose, "upperarm", (72.0 + tremble, 8.0, 0.0))
    side(pose, "lowerarm", (-12.0, 0.0, 0.0))
    return side(pose, "hand", (-30.0, 0.0, 0.0))


def crouch(t, rig):
    s = rig.s
    dip = merge(stand(rig, 0.06), {"pelvis": {"loc": (0.0, 0.02 * s, -0.08 * s), "rot": (8.0, 0.0, 0.0)},
                                   "spine_01": {"rot": (4.0, 0.0, 0.0)}, "Head": {"rot": (-8.0, 0.0, 0.0)}})
    side(dip, "upperarm", (20.0, 4.0, 0.0))
    deep = crouch_peak(rig)
    deep["pelvis"]["loc"] = (0.0, 0.11 * s, -0.40 * s)          # taşar, sonra hazırda titrer
    return track(t, [(0.0, stand(rig)), (0.18, dip), (0.48, deep), (0.6, crouch_peak(rig, 1.5)),
                     (CROUCH_TIME, crouch_peak(rig))])


def _air(rig, pel, foot, arm, fore, head=-10.0, jaw=20.0, spine=0.0):
    s = rig.s
    pose = merge({"pelvis": {"loc": (0.0, pel[0] * s, pel[1] * s), "rot": (pel[2], 0.0, 0.0)},
                  "spine_01": {"rot": (spine, 0.0, 0.0)}, "spine_02": {"rot": (spine * 0.7, 0.0, 0.0)},
                  "neck_01": {"rot": (head * 0.5, 0.0, 0.0)}, "Head": {"rot": (head, 0.0, 0.0)},
                  "jaw": {"rot": (jaw, 0.0, 0.0)}}, feet(rig, *foot))
    side(pose, "clavicle", (0.0, 0.0, 0.0))
    side(pose, "upperarm", (arm, 6.0, 0.0))
    side(pose, "lowerarm", (fore, 0.0, 0.0))
    return side(pose, "hand", (0.0, 0.0, 0.0))


def leap(t, rig):
    """Kalkış uzanması (bacaklar açılır, kollar öne-yukarı savrulur) → havada toplanma (dizler göğse) →
    inişe açılma (bacaklar aşağı, kollar başın üstünde vurmaya hazır)."""
    push = _air(rig, (-0.06, 0.12, 16.0), (0.06, 55.0, 0.0, 0.02), -95.0, -8.0, -16.0, 24.0, -6.0)
    tuck = _air(rig, (0.0, 0.06, 6.0), (-0.10, 34.0, 0.30, 0.07), -60.0, -40.0, -8.0, 18.0, 6.0)
    open_ = _air(rig, (0.0, 0.0, 16.0), (-0.16, 24.0, 0.20, 0.07), -135.0, -25.0, -18.0, 30.0, -4.0)
    reach = _air(rig, (0.0, -0.03, 20.0), (-0.10, 14.0, 0.07, 0.06), -118.0, -12.0, -12.0, 32.0, 2.0)
    return track(t, [(0.0, crouch_peak(rig)), (0.12, push), (0.42, tuck), (0.72, open_), (LEAP_TIME, reach)])


def _impact(rig, z, pitch, head, hand_y=-0.40):
    s = rig.s
    pose = merge({"pelvis": {"loc": (0.0, 0.07 * s, z * s), "rot": (pitch, 0.0, 0.0)},
                  "spine_01": {"rot": (14.0, 0.0, 0.0)}, "spine_02": {"rot": (8.0, 0.0, 0.0)},
                  "spine_03": {"rot": (2.0, 0.0, 0.0)}, "neck_01": {"rot": (-16.0, 0.0, 0.0)},
                  "Head": {"rot": (head, 0.0, 0.0)}, "jaw": {"rot": (26.0, 0.0, 0.0)}},
                 feet(rig, 0.02, 10.0, 0.0, 0.05))
    side(pose, "clavicle", (0.0, 0.0, -4.0))
    side(pose, "hand", (-40.0, 0.0, 0.0))
    return hand_at(rig, pose, (0.20, hand_y, 0.075))


def land(t, rig):
    """Ağır iniş: 0.0'da eller yere vurmuş, gövde çökmüş (şok anı); taşar, kafa kalkar hırlar, doğrulur."""
    s = rig.s
    hit = _impact(rig, -0.40, 44.0, -10.0)
    sink = _impact(rig, -0.45, 50.0, -4.0)
    snarl = _impact(rig, -0.36, 38.0, -38.0, -0.36)
    rise = merge(stand(rig, 0.10), {"pelvis": {"loc": (0.0, 0.03 * s, -0.12 * s), "rot": (14.0, 0.0, 0.0)},
                                    "spine_01": {"rot": (6.0, 0.0, 0.0)}, "Head": {"rot": (-14.0, 0.0, 0.0)},
                                    "jaw": {"rot": (12.0, 0.0, 0.0)}})
    side(rise, "upperarm", (-12.0, 0.0, 0.0))
    side(rise, "lowerarm", (-10.0, 0.0, 0.0))
    for p in (hit, sink, snarl):
        p.update(feet(rig, 0.02, 10.0, 0.0, 0.05))
    rise.update(feet(rig, 0.01, 4.0, 0.0, 0.025))
    return track(t, [(0.0, hit), (0.10, sink), (0.36, snarl), (0.58, rise), (LAND_TIME, idle(0.0, rig))])


# --- tepki -----------------------------------------------------------------------------

def stagger(t, rig):
    s = rig.s
    hit = merge(stand(rig, 0.04), {
        "pelvis": {"loc": (0.0, 0.07 * s, -0.04 * s), "rot": (-8.0, 4.0, -6.0)},
        "spine_01": {"rot": (-12.0, 0.0, 0.0)}, "spine_02": {"rot": (-10.0, 5.0, 0.0)},
        "neck_01": {"rot": (-8.0, 0.0, 0.0)}, "Head": {"rot": (-22.0, 10.0, 8.0)},
        "jaw": {"rot": (20.0, 0.0, 0.0)}})
    side(hit, "upperarm", (8.0, -16.0, 0.0))      # gövde ~30° geri: kollar dünyada az öne savrulur
    side(hit, "lowerarm", (-18.0, 0.0, 0.0))
    settle = merge(stand(rig, 0.05), {"pelvis": {"rot": (8.0, 0.0, 0.0)}, "spine_01": {"rot": (5.0, 0.0, 0.0)},
                                      "Head": {"rot": (6.0, -3.0, 0.0)}, "jaw": {"rot": (6.0, 0.0, 0.0)}})
    return track(t, [(0.0, idle(0.0, rig)), (0.07, hit), (0.2, settle), (STAGGER_TIME, idle(0.0, rig))])


CLIPS = [("idle_Loop", idle, IDLE_CYCLE), ("walk_Loop", walk, WALK_CYCLE), ("crouch", crouch, CROUCH_TIME),
         ("leap", leap, LEAP_TIME), ("land", land, LAND_TIME), ("stagger", stagger, STAGGER_TIME)]


def build_all(arm) -> list:
    import bpy
    import importlib
    import jumper_falls
    importlib.reload(jumper_falls)
    bpy.context.scene.render.fps = wp.FPS
    bpy.context.scene.render.fps_base = 1.0
    if arm.animation_data is None:
        arm.animation_data_create()
    rig = wp.Rig(arm)
    mesh = next((o for o in bpy.data.objects if o.type == "MESH"
                 and any(m.type == "ARMATURE" and m.object == arm for m in o.modifiers)), None)
    names, fixes = [], {}
    for name, fn, length in CLIPS + jumper_falls.CLIPS:
        action = wp.build_clip(rig, name, fn, length)
        if name in jumper_falls.GROUND_FROM and mesh is not None:
            fixes[name] = round(jumper_falls.ground_fix(arm, mesh, action, jumper_falls.GROUND_FROM[name],
                                                        round(length * wp.FPS)), 3)
        names.append(name)
    arm.animation_data.action = bpy.data.actions[CLIPS[0][0]]
    print("JUMPER ANIMS", names, "IK clamped frames:", rig.clamped, "rig.s %.3f" % rig.s,
          "ground fix (m):", fixes)
    return names
