"""Tank ölüm ve doğma klipleri (Aşama V.5) — tank_anims.py'nin devamı, aynı sözleşme.

death_a: göğsüne darbe, geri sarsılır, dizleri çöker, öne yüzüstü kapaklanır; kollar öne yığılır, ağır sekme.
death_b: iki dizinin üstüne çöker, bir an sallanır, öne göğsünün üstüne devrilir (yumruklar yanda).
spawn  : yumruklarına dayanmış çömelme; doğrulur, göğsünü şişirip kollarını açarak kükrer, duruşa yerleşir.
Ayaklar yerdeyken IK hedefiyle, yere yığılırken kemik dönüşüyle aradeğerlenir (walker_falls.two_phase).
Yerde yatan pozların pelvis yüksekliği ağın en alt noktası ölçülerek seçildi (tank_check.py).
"""
import walker_falls as wf
from tank_anims import rest_arms, side, stand, world_hands
from walker_pose import merge, track

DEATH_A_TIME = 1.6
DEATH_B_TIME = 1.8
SPAWN_TIME = 1.1          # = EnemyData tank spawn_time
PRONE_Z = -0.12           # yüzüstü yatışta pelvis inişi (m, rig.s ile): kalın gövde yerde kalır
PRONE_Y = -0.62           # yüzüstü yatışta öne kayma (m, rig.s ile)
PRONE_LEGS = {"thigh_l": (-4.0, 0.0, 6.0), "calf_l": (8.0, 0.0, 0.0), "foot_l": (24.0, 0.0, 0.0),
              "thigh_r": (2.0, 0.0, -8.0), "calf_r": (14.0, 0.0, 0.0), "foot_r": (26.0, 0.0, 0.0)}


def _prone(rig, bounce=0.0, roll=6.0):
    """Yüzüstü: gövde yatay, kafa yana dönük, kollar başın iki yanında."""
    s = rig.s
    pose = {n: {"rot": r} for n, r in PRONE_LEGS.items()}
    pose.update({
        "pelvis": {"loc": (0.0, PRONE_Y * s, (PRONE_Z + bounce) * s), "rot": (84.0 - 4 * bounce / 0.03, 0.0, roll)},
        "spine_01": {"rot": (-2.0, 0.0, 0.0)}, "spine_02": {"rot": (-4.0, 0.0, 0.0)},
        "spine_03": {"rot": (-4.0, 0.0, 0.0)},
        "neck_01": {"rot": (-14.0, 0.0, 0.0)}, "Head": {"rot": (-10.0, 0.0, 34.0)},
        "jaw": {"rot": (20.0, 0.0, 0.0)},
    })
    side(pose, "upperarm", (-62.0, 0.0, 14.0))
    side(pose, "lowerarm", (-30.0, 0.0, 0.0))
    side(pose, "hand", (-20.0, 0.0, 0.0))
    return pose


def _jolt(rig, roll):
    s = rig.s
    pose = merge(stand(rig, 0.03), {
        "pelvis": {"loc": (0.0, 0.05 * s, -0.04 * s), "rot": (-6.0, roll * 0.3, 0.0)},
        "spine_01": {"rot": (-8.0, 0.0, 0.0)}, "spine_02": {"rot": (-8.0, roll * 0.5, 0.0)},
        "Head": {"rot": (-24.0, roll, roll * 0.4)}, "jaw": {"rot": (28.0, 0.0, 0.0)},
    })
    side(pose, "upperarm", (-14.0, -14.0, 0.0))
    side(pose, "lowerarm", (-10.0, 0.0, 0.0))
    return pose


def death_a(t, rig):
    s = rig.s
    buckle = merge(stand(rig, 0.28), {
        "pelvis": {"loc": (0.0, -0.04 * s, -0.28 * s), "rot": (18.0, 0.0, 0.0)},
        "spine_01": {"rot": (12.0, 0.0, 0.0)}, "spine_02": {"rot": (8.0, 0.0, 0.0)},
        "Head": {"rot": (14.0, -4.0, 0.0)}, "jaw": {"rot": (18.0, 0.0, 0.0)},
    })
    side(buckle, "upperarm", (12.0, 4.0, 0.0))
    tip = merge(buckle, {
        "pelvis": {"loc": (0.0, -0.20 * s, -0.42 * s), "rot": (46.0, 0.0, 3.0)},
        "Head": {"rot": (-12.0, -4.0, 0.0)}, "jaw": {"rot": (24.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.04 * s, 50.0, 0.0, 0.0)}, "ik_r": {"foot": (0.02 * s, 40.0, 0.0, 0.0)},
    })
    world_hands(rig, tip, (0.25 * s, -0.75 * s, 0.35 * s), (-0.25 * s, -0.70 * s, 0.40 * s), out=0.3)
    fall = merge(wf.blend(wf.fk(rig, tip), _prone(rig), 0.6), {
        "pelvis": {"loc": (0.0, -0.50 * s, -0.24 * s), "rot": (68.0, 0.0, 5.0)}})
    ik_keys = [(0.0, stand(rig)), (0.12, _jolt(rig, 0.0)), (0.45, buckle), (0.78, tip)]
    return wf.two_phase(t, rig, ik_keys, [(0.94, fall), (1.06, _prone(rig)), (1.20, _prone(rig, 0.035)),
                                          (1.36, _prone(rig)), (DEATH_A_TIME, _prone(rig))])


def death_b(t, rig):
    s = rig.s
    kneel = merge(stand(rig), {
        "pelvis": {"loc": (0.0, 0.10 * s, -0.40 * s), "rot": (8.0, 0.0, 0.0)},
        "spine_01": {"rot": (8.0, 0.0, 0.0)}, "spine_02": {"rot": (6.0, 3.0, 0.0)},
        "Head": {"rot": (22.0, 8.0, 0.0)}, "jaw": {"rot": (22.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.36 * s, 72.0, 0.0, 0.0)}, "ik_r": {"foot": (0.42 * s, 72.0, 0.0, 0.0)},
    })
    side(kneel, "upperarm", (10.0, 4.0, 0.0))
    sway = merge(kneel, {"pelvis": {"loc": (0.0, 0.10 * s, -0.41 * s), "rot": (2.0, 4.0, 0.0)},
                         "spine_02": {"rot": (0.0, 6.0, 0.0)}, "Head": {"rot": (6.0, 18.0, 4.0)}})
    k = wf.fk(rig, kneel)
    topple = merge(wf.blend(k, _prone(rig, roll=-4.0), 0.45), {
        "pelvis": {"loc": (0.0, -0.22 * s, -0.28 * s), "rot": (50.0, 0.0, -3.0)}})
    ik_keys = [(0.0, stand(rig)), (0.12, _jolt(rig, -10.0)), (0.50, kneel), (0.80, sway)]
    return wf.two_phase(t, rig, ik_keys, [(1.04, topple), (1.22, _prone(rig, roll=-4.0)),
                                          (1.36, _prone(rig, 0.03, roll=-4.0)), (1.52, _prone(rig, roll=-4.0)),
                                          (DEATH_B_TIME, _prone(rig, roll=-4.0))])


def spawn(t, rig):
    s = rig.s
    crouch = merge(stand(rig), {
        "pelvis": {"loc": (0.0, 0.06 * s, -0.31 * s), "rot": (34.0, 0.0, 0.0)},
        "spine_01": {"rot": (16.0, 0.0, 0.0)}, "spine_02": {"rot": (10.0, 0.0, 0.0)},
        "neck_01": {"rot": (-12.0, 0.0, 0.0)}, "Head": {"rot": (-6.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.0, 20.0, 0.0, 0.0)}, "ik_r": {"foot": (0.0, 20.0, 0.0, 0.0)},
    })
    world_hands(rig, crouch, (0.32 * s, -0.50 * s, 0.23 * s), (-0.32 * s, -0.50 * s, 0.23 * s), out=0.3)
    roar = merge(stand(rig, 0.03), {
        "pelvis": {"rot": (-4.0, 0.0, 0.0)}, "spine_02": {"rot": (-8.0, 0.0, 0.0)},
        "spine_03": {"rot": (-5.0, 0.0, 0.0)}, "Head": {"rot": (-18.0, 0.0, 0.0)},
        "jaw": {"rot": (34.0, 0.0, 0.0)},
    })
    side(roar, "clavicle", (0.0, -10.0, 0.0))
    sh = rig.head["upperarm_l"]      # kollar iki yana açık, yumruklar bel hizasında (IK; FK ile karışmasın)
    world_hands(rig, roar, (sh.x + 0.42 * s, sh.y - 0.20 * s, sh.z - 0.45 * s),
                (-sh.x - 0.42 * s, sh.y - 0.20 * s, sh.z - 0.45 * s), out=0.3)
    half = merge(stand(rig, 0.18), {"pelvis": {"loc": (0.0, 0.03 * s, -0.18 * s), "rot": (16.0, 0.0, 0.0)},
                                    "spine_01": {"rot": (8.0, 0.0, 0.0)}, "Head": {"rot": (-4.0, 0.0, 0.0)}})
    rest_arms(half)
    return track(t, [(0.0, crouch), (0.15, crouch), (0.45, half), (0.70, roar), (0.85, roar),
                     (SPAWN_TIME, rest_arms(stand(rig)))])


CLIPS = [("death_a", death_a, DEATH_A_TIME), ("death_b", death_b, DEATH_B_TIME), ("spawn", spawn, SPAWN_TIME)]
