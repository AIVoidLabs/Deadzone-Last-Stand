"""Zırhlı ölüm ve doğma klipleri (7.3) — armored_anims.py'nin devamı, aynı sözleşme.

death_a: kalkana ağır darbe, geri sarsılır, dizleri çöker, öne kalkanının üstüne kapaklanır (kalkan yanda).
death_b: sendeler, iki dizinin üstüne çöker, sağ yanına devrilir; kalkan kolu havada kalıp yere düşer.
spawn  : yerden doğrulur: çömelmiş, kalkan başın üstünde siper; kalkar, kalkanı öne indirip duruşa yerleşir.
Ayaklar yerdeyken IK hedefiyle, yere yığılırken kemik dönüşüyle aradeğerlenir (walker_falls.two_phase).
Yerde yatan pozların pelvis yüksekliği ağın en alt noktası ölçülerek seçildi (armored_check.py).
"""
import walker_falls as wf
from armored_anims import guard, shield, stand
from walker_pose import merge, track

DEATH_A_TIME = 1.6
DEATH_B_TIME = 1.6
SPAWN_TIME = 1.1
PRONE_Z = -0.37           # yüzüstü: pelvis inişi (m, rig.s ile; ağın en altı ölçülerek)
PRONE_Y = -0.55
PRONE_LEGS = {"thigh_l": (-6.0, 0.0, 6.0), "calf_l": (10.0, 0.0, 0.0), "foot_l": (30.0, 0.0, 0.0),
              "thigh_r": (2.0, 0.0, -8.0), "calf_r": (16.0, 0.0, 0.0), "foot_r": (30.0, 0.0, 0.0)}


def _prone(rig, bounce=0.0, roll=8.0):
    """Yüzüstü: gövde yatay, kafa yana dönük; kalkan kolu yana açık (kalkan gövdenin yanında yerde)."""
    s = rig.s
    pose = {n: {"rot": r} for n, r in PRONE_LEGS.items()}
    pose.update({
        "pelvis": {"loc": (0.0, PRONE_Y * s, (PRONE_Z + bounce) * s), "rot": (86.0 - 120 * bounce, 0.0, roll)},
        "spine_01": {"rot": (-4.0, 0.0, 0.0)}, "spine_02": {"rot": (-6.0, 0.0, 0.0)},
        "spine_03": {"rot": (-4.0, 0.0, 0.0)},
        "neck_01": {"rot": (-16.0, 0.0, 0.0)}, "Head": {"rot": (-12.0, 0.0, 36.0)},
        "jaw": {"rot": (18.0, 0.0, 0.0)},
        "upperarm_l": {"rot": (-40.0, 40.0, 30.0)}, "lowerarm_l": {"rot": (0.0, 0.0, 0.0)},
        "upperarm_r": {"rot": (-60.0, 0.0, -14.0)}, "lowerarm_r": {"rot": (-30.0, 0.0, 0.0)},
        "hand_r": {"rot": (-20.0, 0.0, 0.0)},
    })
    return pose


def _jolt(rig, roll):
    s = rig.s
    pose = merge(stand(rig, 0.05), {
        "pelvis": {"loc": (0.0, 0.07 * s, -0.05 * s), "rot": (-6.0, roll * 0.3, 0.0)},
        "spine_01": {"rot": (-8.0, 0.0, 0.0)}, "spine_02": {"rot": (-8.0, roll * 0.5, 0.0)},
        "Head": {"rot": (-24.0, roll, roll * 0.4)}, "jaw": {"rot": (26.0, 0.0, 0.0)},
    })
    shield(pose, 0.04 * s, 0.08 * s, 0.10 * s, out=0.2)
    pose["upperarm_r"] = {"rot": (-14.0, -18.0, 0.0)}
    pose["lowerarm_r"] = {"rot": (-10.0, 0.0, 0.0)}
    return pose


def death_a(t, rig):
    s = rig.s
    buckle = merge(stand(rig, 0.30), {
        "pelvis": {"loc": (0.0, -0.04 * s, -0.30 * s), "rot": (20.0, 0.0, 0.0)},
        "spine_01": {"rot": (12.0, 0.0, 0.0)}, "spine_02": {"rot": (8.0, 0.0, 0.0)},
        "Head": {"rot": (16.0, -4.0, 0.0)}, "jaw": {"rot": (18.0, 0.0, 0.0)},
    })
    shield(buckle, 0.0, -0.04 * s, -0.12 * s, out=0.2)
    buckle["upperarm_r"] = {"rot": (10.0, 4.0, 0.0)}
    tip = merge(buckle, {
        "pelvis": {"loc": (0.0, -0.22 * s, -0.46 * s), "rot": (48.0, 0.0, 4.0)},
        "Head": {"rot": (-12.0, -4.0, 0.0)}, "jaw": {"rot": (22.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.04 * s, 50.0, 0.0, 0.0)}, "ik_r": {"foot": (0.02 * s, 42.0, 0.0, 0.0)},
    })
    shield(tip, 0.06 * s, -0.10 * s, -0.20 * s, out=0.3)
    fall = merge(wf.blend(wf.fk(rig, tip), _prone(rig), 0.6), {
        "pelvis": {"loc": (0.0, -0.46 * s, -0.30 * s), "rot": (68.0, 0.0, 6.0)}})
    ik_keys = [(0.0, guard(rig)), (0.12, _jolt(rig, 0.0)), (0.45, buckle), (0.78, tip)]
    return wf.two_phase(t, rig, ik_keys, [(0.94, fall), (1.06, _prone(rig)), (1.18, _prone(rig, 0.03)),
                                          (1.32, _prone(rig)), (DEATH_A_TIME, _prone(rig))])


SIDE_Z = -0.49            # sağ yana yatış: pelvis inişi (m; ağın en altı ölçülerek)


def _side(rig, bounce=0.0):
    """Sağ yanına yatmış: gövde yana devrik, kalkan kolu üstte, kalkan gövdenin önünde yerde."""
    s = rig.s
    return {
        "pelvis": {"loc": (-0.30 * s, -0.10 * s, (SIDE_Z + bounce) * s), "rot": (16.0, -84.0 + 60 * bounce, 0.0)},
        "spine_01": {"rot": (6.0, 0.0, 0.0)}, "spine_02": {"rot": (6.0, -4.0, 0.0)},
        "neck_01": {"rot": (4.0, -10.0, 0.0)}, "Head": {"rot": (10.0, -16.0, -10.0)},
        "jaw": {"rot": (24.0, 0.0, 0.0)},
        "thigh_l": {"rot": (34.0, 0.0, 4.0)}, "calf_l": {"rot": (40.0, 0.0, 0.0)}, "foot_l": {"rot": (20.0, 0.0, 0.0)},
        "thigh_r": {"rot": (20.0, 0.0, -4.0)}, "calf_r": {"rot": (54.0, 0.0, 0.0)}, "foot_r": {"rot": (20.0, 0.0, 0.0)},
        "upperarm_l": {"rot": (10.0, 0.0, 0.0)},
        "upperarm_r": {"rot": (-50.0, 0.0, -20.0)}, "lowerarm_r": {"rot": (-40.0, 0.0, 0.0)},
    }


def death_b(t, rig):
    s = rig.s
    kneel = merge(stand(rig), {
        "pelvis": {"loc": (0.0, 0.10 * s, -0.44 * s), "rot": (8.0, -4.0, 0.0)},
        "spine_01": {"rot": (8.0, -4.0, 0.0)}, "spine_02": {"rot": (6.0, -3.0, 0.0)},
        "Head": {"rot": (24.0, -8.0, 0.0)}, "jaw": {"rot": (22.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.40 * s, 72.0, 0.0, 0.0)}, "ik_r": {"foot": (0.44 * s, 72.0, 0.0, 0.0)},
    })
    shield(kneel, 0.04 * s, -0.02 * s, -0.22 * s, out=0.25)
    kneel["upperarm_r"] = {"rot": (8.0, 4.0, 0.0)}
    sway = merge(kneel, {"pelvis": {"loc": (-0.02 * s, 0.10 * s, -0.45 * s), "rot": (4.0, -10.0, 0.0)},
                         "spine_02": {"rot": (0.0, -6.0, 0.0)}, "Head": {"rot": (6.0, -18.0, 4.0)}})
    topple = merge(wf.blend(wf.fk(rig, kneel), _side(rig), 0.5), {
        "pelvis": {"loc": (-0.16 * s, 0.0, -0.44 * s), "rot": (12.0, -46.0, 0.0)}})
    ik_keys = [(0.0, guard(rig)), (0.12, _jolt(rig, 10.0)), (0.48, kneel), (0.78, sway)]
    return wf.two_phase(t, rig, ik_keys, [(1.00, topple), (1.16, _side(rig)), (1.28, _side(rig, 0.03)),
                                          (1.42, _side(rig)), (DEATH_B_TIME, _side(rig))])


def spawn(t, rig):
    s = rig.s
    crouch = merge(stand(rig), {
        "pelvis": {"loc": (0.0, 0.08 * s, -0.40 * s), "rot": (30.0, 0.0, 0.0)},
        "spine_01": {"rot": (14.0, 0.0, 0.0)}, "spine_02": {"rot": (8.0, 0.0, 0.0)},
        "neck_01": {"rot": (-8.0, 0.0, 0.0)}, "Head": {"rot": (-4.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.0, 24.0, 0.0, 0.0)}, "ik_r": {"foot": (0.06 * s, 28.0, 0.0, 0.0)},
    })
    shield(crouch, 0.0, 0.02 * s, 0.22 * s, out=0.2)        # kalkan başın üstünde siper
    crouch["upperarm_r"] = {"rot": (30.0, 0.0, 0.0)}
    crouch["lowerarm_r"] = {"rot": (-10.0, 0.0, 0.0)}
    half = merge(stand(rig, 0.22), {"pelvis": {"loc": (0.0, 0.04 * s, -0.22 * s), "rot": (18.0, 0.0, 0.0)},
                                    "spine_01": {"rot": (8.0, 0.0, 0.0)}, "Head": {"rot": (-6.0, 0.0, 0.0)},
                                    "jaw": {"rot": (16.0, 0.0, 0.0)}})
    shield(half, 0.0, 0.0, 0.10 * s)
    roar = merge(stand(rig, 0.06), {"pelvis": {"rot": (0.0, 0.0, 0.0)}, "spine_02": {"rot": (-6.0, 0.0, 0.0)},
                                    "Head": {"rot": (-16.0, 0.0, 0.0)}, "jaw": {"rot": (30.0, 0.0, 0.0)}})
    shield(roar, 0.0, -0.08 * s, -0.04 * s)
    roar["upperarm_r"] = {"rot": (-10.0, -20.0, 0.0)}
    return track(t, [(0.0, crouch), (0.15, crouch), (0.45, half), (0.72, roar), (0.85, roar),
                     (SPAWN_TIME, guard(rig))])


CLIPS = [("death_a", death_a, DEATH_A_TIME), ("death_b", death_b, DEATH_B_TIME), ("spawn", spawn, SPAWN_TIME)]
