"""Tükürücü ölüm ve doğma klipleri (7.3) — spitter_anims.py'nin devamı, aynı sözleşme (kese ölçeği dahil).

death_a (1.5): gırtlağa darbe, kafa geri savrulur, geri sendeler, sırtüstü devrilir; kamburunun üstünde bir
  kez sekip yana yuvarlanır, kese çarpmada sallanır ve sönerek kalır (ölçek 0.85).
death_b (1.5): öne iki büklüm olur (karnını tutar gibi), dizlerinin üstüne çöker, bir an sallanır,
  sol yanına devrilir; kese söner.
spawn (1.0): öne çökük çömelme, kese sönük (0.85); doğrulur, kese hırıltıyla şişer (1.06), kafa kalkar.
Ayaklar yerdeyken IK, yere yığılırken kemik dönüşü (walker_falls.two_phase). Yatış pozlarının pelvis
yüksekliği ağın en alt noktası ölçülerek seçildi (spitter_check.py).
"""
import walker_falls as wf
from spitter_anims import side, stand, swell
from walker_pose import merge, track

DEATH_A_TIME = 1.5
DEATH_B_TIME = 1.5
SPAWN_TIME = 1.0
SUPINE_Z = -0.50          # sırtüstü yatışta pelvis inişi (m, rig.s ile)
SUPINE_Y = 0.36           # geriye kayma (m, rig.s ile)
SUPINE_LEGS = {"thigh_l": (40.0, 0.0, 10.0), "calf_l": (-40.0, 0.0, 0.0), "foot_l": (-20.0, 0.0, 0.0),
               "thigh_r": (24.0, 0.0, -12.0), "calf_r": (-20.0, 0.0, 0.0), "foot_r": (-24.0, 0.0, 0.0)}
SIDE_Z = -0.62            # yan yatışta pelvis inişi
SIDE_LEGS = {"thigh_l": (-50.0, 0.0, 0.0), "calf_l": (70.0, 0.0, 0.0), "foot_l": (20.0, 0.0, 0.0),
             "thigh_r": (-35.0, 0.0, 0.0), "calf_r": (60.0, 0.0, 0.0), "foot_r": (20.0, 0.0, 0.0)}


def _supine(rig, bounce=0.0, roll=10.0, k=0.85):
    """Sırtüstü: kambur yerde, karın yukarıda, bacaklar bükük, kollar iki yana, kafa yana düşmüş."""
    s = rig.s
    pose = {n: {"rot": r} for n, r in SUPINE_LEGS.items()}
    pose.update({
        "pelvis": {"loc": (0.0, SUPINE_Y * s, (SUPINE_Z + bounce) * s), "rot": (-84.0 + 60 * bounce, roll, 0.0)},
        "spine_01": {"rot": (-2.0, 0.0, 0.0)}, "spine_02": {"rot": (-6.0, 0.0, 0.0)},
        "spine_03": {"rot": (-6.0, 0.0, 0.0)},
        "neck_01": {"rot": (-10.0, 0.0, 0.0)}, "Head": {"rot": (-14.0, 0.0, -40.0)},
        "jaw": {"rot": (30.0, 0.0, 0.0)},
    })
    side(pose, "upperarm", (-10.0, -60.0, 0.0))
    side(pose, "lowerarm", (-20.0, 0.0, 0.0))
    side(pose, "hand", (-10.0, 0.0, 0.0))
    return swell(pose, k)


def death_a(t, rig):
    s = rig.s
    jolt = merge(stand(rig, 0.04), {
        "pelvis": {"loc": (0.0, 0.05 * s, -0.04 * s), "rot": (-6.0, 3.0, 0.0)},
        "spine_01": {"rot": (-6.0, 0.0, 0.0)}, "spine_02": {"rot": (-8.0, 3.0, 0.0)},
        "neck_01": {"rot": (-12.0, 0.0, 0.0), "scale": 0.92},
        "Head": {"rot": (-26.0, 8.0, 6.0)}, "jaw": {"rot": (34.0, 0.0, 0.0)},
    })
    side(jolt, "upperarm", (14.0, -22.0, 0.0))
    side(jolt, "lowerarm", (-14.0, 0.0, 0.0))
    stumble = merge(stand(rig, 0.12), {
        "pelvis": {"loc": (0.0, 0.10 * s, -0.12 * s), "rot": (-12.0, -3.0, 4.0)},
        "spine_01": {"rot": (-6.0, 0.0, 0.0)}, "spine_02": {"rot": (-6.0, -3.0, 0.0)},
        "neck_01": {"rot": (-6.0, 0.0, 0.0), "scale": 1.04},
        "Head": {"rot": (-10.0, -6.0, 0.0)}, "jaw": {"rot": (24.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.12 * s, 0.0, 0.0, 0.04 * s)}, "ik_r": {"foot": (-0.02 * s, 0.0, 0.0, -0.05 * s)},
    })
    side(stumble, "upperarm", (-25.0, -35.0, 0.0))
    side(stumble, "lowerarm", (-25.0, 0.0, 0.0))
    tip = merge(stumble, {
        "pelvis": {"loc": (0.0, 0.22 * s, -0.24 * s), "rot": (-34.0, -2.0, 6.0)},
        "neck_01": {"rot": (-4.0, 0.0, 0.0), "scale": 1.0},
        "Head": {"rot": (6.0, -4.0, 0.0)},
        "ik_l": {"foot": (0.14 * s, -24.0, 0.0, 0.04 * s)}, "ik_r": {"foot": (0.04 * s, -18.0, 0.0, -0.05 * s)},
    })
    side(tip, "upperarm", (-55.0, -45.0, 0.0))
    fall = merge(wf.blend(wf.fk(rig, tip), _supine(rig, k=0.95), 0.55), {
        "pelvis": {"loc": (0.0, 0.32 * s, -0.18 * s), "rot": (-62.0, 2.0, 6.0)}})
    ik_keys = [(0.0, swell(stand(rig), 1.0)), (0.12, jolt), (0.40, stumble), (0.66, tip)]
    return wf.two_phase(t, rig, ik_keys, [
        (0.86, fall), (0.98, _supine(rig, k=0.95)), (1.10, _supine(rig, 0.04, roll=18.0, k=1.04)),
        (1.24, _supine(rig, 0.0, roll=6.0, k=0.88)), (1.36, _supine(rig, 0.008, roll=11.0, k=0.86)),
        (DEATH_A_TIME, _supine(rig))])


def _side_lie(rig, bounce=0.0, roll=86.0):
    s = rig.s
    pose = {n: {"rot": r} for n, r in SIDE_LEGS.items()}
    pose.update({
        "pelvis": {"loc": (0.30 * s, 0.10 * s, (SIDE_Z + bounce) * s), "rot": (10.0, roll, 10.0)},
        "spine_01": {"rot": (6.0, 0.0, 0.0)}, "spine_02": {"rot": (6.0, -2.0, 0.0)},
        "neck_01": {"rot": (0.0, -8.0, 0.0)}, "Head": {"rot": (4.0, -12.0, 10.0)}, "jaw": {"rot": (28.0, 0.0, 0.0)},
    })
    side(pose, "upperarm", (-30.0, -10.0, 0.0))
    side(pose, "lowerarm", (-30.0, 0.0, 0.0))
    return swell(pose, 0.85)


def death_b(t, rig):
    s = rig.s
    double = merge(stand(rig, 0.10), {
        "pelvis": {"loc": (0.0, 0.04 * s, -0.10 * s), "rot": (14.0, 0.0, 0.0)},
        "spine_01": {"rot": (12.0, 0.0, 0.0)}, "spine_02": {"rot": (12.0, 0.0, 0.0)},
        "neck_01": {"rot": (6.0, 0.0, 0.0), "scale": 0.94},
        "Head": {"rot": (14.0, 0.0, 0.0)}, "jaw": {"rot": (30.0, 0.0, 0.0)},
    })
    side(double, "upperarm", (-30.0, 10.0, 0.0))
    side(double, "lowerarm", (-40.0, 0.0, 0.0))
    kneel = merge(stand(rig), {
        "pelvis": {"loc": (0.0, 0.10 * s, -0.44 * s), "rot": (10.0, 0.0, 0.0)},
        "spine_01": {"rot": (10.0, 0.0, 0.0)}, "spine_02": {"rot": (8.0, 4.0, 0.0)},
        "neck_01": {"rot": (4.0, 0.0, 0.0), "scale": 0.9},
        "Head": {"rot": (20.0, 10.0, 0.0)}, "jaw": {"rot": (24.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.40 * s, 75.0, 0.0, 0.0)}, "ik_r": {"foot": (0.50 * s, 75.0, 0.0, 0.0)},
    })
    side(kneel, "upperarm", (-10.0, 6.0, 0.0))
    side(kneel, "lowerarm", (-20.0, 0.0, 0.0))
    sway = merge(kneel, {"pelvis": {"loc": (0.0, 0.10 * s, -0.45 * s), "rot": (6.0, 6.0, 0.0)},
                         "spine_02": {"rot": (2.0, 8.0, 0.0)}, "Head": {"rot": (6.0, 22.0, 6.0)}})
    down = _side_lie(rig)
    tilt = merge(wf.blend(wf.fk(rig, kneel), down, 0.4), {
        "pelvis": {"loc": (0.14 * s, 0.10 * s, -0.40 * s), "rot": (8.0, 34.0, 6.0)}})
    fl = tilt["foot_l"]["rot"]
    tilt["foot_l"] = {"rot": (fl[0] - 30.0, fl[1], fl[2] - 30.0)}
    ik_keys = [(0.0, swell(stand(rig), 1.0)), (0.16, double), (0.48, kneel), (0.72, sway)]
    return wf.two_phase(t, rig, ik_keys, [(0.94, tilt), (1.12, down), (1.26, _side_lie(rig, 0.03, 82.0)),
                                          (DEATH_B_TIME, down)])


def spawn(t, rig):
    s = rig.s
    slump = merge(stand(rig, 0.30, 0.04), {
        "pelvis": {"loc": (0.0, 0.10 * s, -0.30 * s), "rot": (26.0, 0.0, 0.0)},
        "spine_01": {"rot": (14.0, 0.0, 0.0)}, "spine_02": {"rot": (12.0, 0.0, 0.0)},
        "neck_01": {"rot": (14.0, 0.0, 0.0), "scale": 0.85}, "Head": {"rot": (20.0, 6.0, 0.0)},
        "jaw": {"rot": (22.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.0, 18.0, 0.0, 0.04 * s)}, "ik_r": {"foot": (0.0, 18.0, 0.0, -0.04 * s)},
    })
    side(slump, "upperarm", (-24.0, 4.0, 0.0))
    side(slump, "lowerarm", (-20.0, 0.0, 0.0))
    half = merge(stand(rig, 0.14, 0.03), {
        "pelvis": {"loc": (0.0, 0.05 * s, -0.14 * s), "rot": (12.0, -3.0, 4.0)},
        "spine_01": {"rot": (6.0, 0.0, 0.0)}, "spine_02": {"rot": (4.0, 2.0, 0.0)},
        "neck_01": {"rot": (6.0, 0.0, 0.0), "scale": 0.92},
        "Head": {"rot": (8.0, -4.0, 0.0)}, "jaw": {"rot": (16.0, 0.0, 0.0)},
    })
    side(half, "upperarm", (-8.0, -6.0, 0.0))
    heave = merge(stand(rig, 0.04, 0.02), {
        "pelvis": {"rot": (-3.0, 0.0, 0.0)}, "spine_02": {"rot": (-5.0, 0.0, 0.0)},
        "neck_01": {"rot": (-6.0, 0.0, 0.0), "scale": 1.06},
        "Head": {"rot": (-18.0, 0.0, 0.0)}, "jaw": {"rot": (34.0, 0.0, 0.0)},
    })
    side(heave, "upperarm", (8.0, -18.0, 0.0))
    side(heave, "lowerarm", (-12.0, 0.0, 0.0))
    return track(t, [(0.0, slump), (0.10, slump), (0.38, half), (0.64, heave), (0.76, heave),
                     (SPAWN_TIME, swell(stand(rig), 1.0))])


CLIPS = [("death_a", death_a, DEATH_A_TIME), ("death_b", death_b, DEATH_B_TIME), ("spawn", spawn, SPAWN_TIME)]
