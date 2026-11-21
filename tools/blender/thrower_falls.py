"""Taş fırlatan ölüm ve doğma klipleri (7.3) — thrower_anims.py'nin devamı, aynı sözleşme.

death_a: göğsüne darbe, geri sarsılır; dev kolun ağırlığı onu sağa çeker, dizleri çöker, sağ omzunun
         üstüne öne kapaklanır (dev kol altında kalmaz, önde yere yayılır); küçük sekme.
death_b: dev koluna dayanıp diz çöker, bir an kol onu tutar, kol kayar ve yüzüstü devrilir.
spawn  : dev eline dayanmış çömelme (el yerde); dev kolla kendini iter, doğrulur, başını kaldırıp kükrer.
Ayaklar yerdeyken IK hedefiyle, yere yığılırken kemik dönüşüyle aradeğerlenir (walker_falls.two_phase).
Yerde yatan pozların pelvis yüksekliği ağın en alt noktası ölçülerek seçildi (thrower_check.py).
"""
import walker_falls as wf
from thrower_anims import _body, rest_arms, side, stand, world_hands
from walker_pose import merge, track

DEATH_A_TIME = 1.6
DEATH_B_TIME = 1.6
SPAWN_TIME = 1.1
PRONE_Z = -0.70           # yüzüstü yatışta pelvis inişi (m, rig.s ile)
PRONE_Y = -0.46           # yüzüstü yatışta öne kayma (m, rig.s ile)
PRONE_HAND = (0.0, 0.0, 90.0)   # dev el yan yatık değil, avuç yere dönük (kalın el yere gömülmesin)
PRONE_ARM_Z = 0.12        # yerde yatan dev kolun bilek yüksekliği (m): el kalın, yere gömülmesin
PRONE_LEGS = {"thigh_l": (-4.0, 0.0, 8.0), "calf_l": (10.0, 0.0, 0.0), "foot_l": (24.0, 0.0, 0.0),
              "thigh_r": (2.0, 0.0, -8.0), "calf_r": (16.0, 0.0, 0.0), "foot_r": (26.0, 0.0, 0.0)}
# kapaklanma ortasında bacaklar: ayak uçları geriye uzanır (parmak yere gömülmesin; ölçülerek)
FALL_LEGS = {"thigh_l": {"rot": (14.0, 0.0, 6.0)}, "calf_l": {"rot": (40.0, 0.0, 0.0)},
             "foot_l": {"rot": (30.0, 0.0, 0.0)}, "thigh_r": {"rot": (18.0, 0.0, -6.0)},
             "calf_r": {"rot": (34.0, 0.0, 0.0)}, "foot_r": {"rot": (30.0, 0.0, 0.0)}}


def _prone(rig, bounce=0.0, roll=-8.0, head_turn=34.0):
    """Yüzüstü: gövde yatay, kafa yana dönük; dev kol gövde yanında yerde, sıska kol yanda."""
    s = rig.s
    pose = {n: {"rot": r} for n, r in PRONE_LEGS.items()}
    pose.update({
        "pelvis": {"loc": (0.0, PRONE_Y * s, (PRONE_Z + bounce) * s), "rot": (84.0 - bounce * 120.0, 0.0, roll)},
        "spine_01": {"rot": (-2.0, 0.0, 0.0)}, "spine_02": {"rot": (-4.0, 0.0, 0.0)},
        "spine_03": {"rot": (-4.0, 0.0, 0.0)},
        "neck_01": {"rot": (-16.0, 0.0, 0.0)}, "Head": {"rot": (-12.0, 0.0, head_turn)},
        "jaw": {"rot": (22.0, 0.0, 0.0)},
        "hand_r": {"rot": PRONE_HAND},
    })
    # kollar dünya hedefiyle (IK -> dönüş): dev kol gövdenin sağında yerde, ayağa doğru uzanmış, sıska kol gövde yanında
    world_hands(rig, pose, {"r": (-0.58 - roll * 0.004, PRONE_Y + 0.22, PRONE_ARM_Z),
                            "l": (0.34, PRONE_Y + 0.05, 0.10)}, out=0.4)
    return wf.fk(rig, pose)


def _jolt(rig, roll):
    s = rig.s
    pose = merge(stand(rig, 0.03), {
        "pelvis": {"loc": (0.0, 0.05 * s, -0.04 * s), "rot": (-6.0, roll * 0.3, 0.0)},
        "spine_01": {"rot": (-8.0, 0.0, 0.0)}, "spine_02": {"rot": (-8.0, roll * 0.5, 0.0)},
        "Head": {"rot": (-24.0, roll, roll * 0.4)}, "jaw": {"rot": (28.0, 0.0, 0.0)},
    })
    side(pose, "upperarm", (-14.0, -12.0, 0.0))
    pose["lowerarm_l"] = {"rot": (-24.0, 0.0, 0.0)}
    return pose


def death_a(t, rig):
    s = rig.s
    buckle = _body(rig, 0.28, (18.0, -10.0, -6.0), (12.0, -4.0, 0.0), (6.0, 0, 0), head=(14.0, -4.0, 0.0),
                   jaw=18.0)
    world_hands(rig, buckle, {"r": (-0.46, -0.30, 0.40)}, out=0.3)
    tip = merge(buckle, {
        "pelvis": {"loc": (-0.04 * s, -0.20 * s, -0.42 * s), "rot": (46.0, -12.0, -6.0)},
        "Head": {"rot": (-12.0, -4.0, 0.0)}, "jaw": {"rot": (24.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.04 * s, 50.0, 0.0, 0.0)}, "ik_r": {"foot": (0.02 * s, 40.0, 0.0, 0.0)},
    })
    world_hands(rig, tip, {"r": (-0.50, -0.72, 0.30), "l": (0.30, -0.55, 0.55)}, out=0.3)
    fall = merge(wf.blend(wf.fk(rig, tip), _prone(rig), 0.6), {
        "pelvis": {"loc": (0.0, -0.40 * s, -0.40 * s), "rot": (66.0, 0.0, -6.0)}, **FALL_LEGS})
    fall = wf.fk(rig, world_hands(rig, fall, {"r": (-0.56, -0.62, 0.30)}, out=0.4))     # dev el yere dayanır
    ik_keys = [(0.0, stand(rig)), (0.12, _jolt(rig, 0.0)), (0.45, buckle), (0.76, tip)]
    land = wf.fk(rig, world_hands(rig, wf.blend(fall, _prone(rig), 0.5), {"r": (-0.58, -0.40, 0.26)}, out=0.4))
    return wf.two_phase(t, rig, ik_keys, [(0.94, fall), (1.00, land), (1.06, _prone(rig)), (1.20, _prone(rig, 0.035)),
                                          (1.36, _prone(rig)), (DEATH_A_TIME, _prone(rig))])


def death_b(t, rig):
    s = rig.s
    kneel = _body(rig, 0.40, (14.0, -6.0, -4.0), (8.0, -2.0, 0.0), head=(22.0, 8.0, 0.0), jaw=22.0,
                  feet={"l": (0.36, 72.0, 0.0, 0.0), "r": (0.42, 72.0, 0.0, 0.0)}, loc=(0.0, 0.10))
    world_hands(rig, kneel, {"r": (-0.44, -0.42, 0.42)}, out=0.3)     # dev el yere dayanır
    lean = merge(kneel, {"pelvis": {"loc": (-0.03 * s, 0.10 * s, -0.42 * s), "rot": (20.0, -10.0, 0.0)},
                         "spine_02": {"rot": (6.0, -6.0, 0.0)}, "Head": {"rot": (8.0, 18.0, 4.0)}})
    world_hands(rig, lean, {"r": (-0.48, -0.50, 0.36)}, out=0.35)
    k = wf.fk(rig, lean)
    topple = merge(wf.blend(k, _prone(rig, roll=6.0, head_turn=-30.0), 0.45), {
        "pelvis": {"loc": (0.0, -0.20 * s, -0.42 * s), "rot": (52.0, 0.0, 4.0)}, **FALL_LEGS})
    topple = wf.fk(rig, world_hands(rig, topple, {"r": (-0.56, -0.58, 0.32)}, out=0.4))
    ik_keys = [(0.0, stand(rig)), (0.12, _jolt(rig, -10.0)), (0.48, kneel), (0.80, lean)]
    down = _prone(rig, roll=6.0, head_turn=-30.0)
    land = wf.fk(rig, world_hands(rig, wf.blend(topple, down, 0.5), {"r": (-0.58, -0.30, 0.26)}, out=0.4))
    return wf.two_phase(t, rig, ik_keys, [(1.02, topple), (1.10, land), (1.18, down),
                                          (1.32, _prone(rig, 0.03, roll=6.0, head_turn=-30.0)),
                                          (1.46, down), (DEATH_B_TIME, down)])


def spawn(t, rig):
    crouch = _body(rig, 0.36, (36.0, -10.0, -6.0), (16.0, -4.0, 0.0), (8.0, 0, 0), head=(-14.0, 0.0, 0.0),
                   jaw=10.0, feet={"l": (0.0, 20.0, 0.0, 0.0), "r": (0.0, 20.0, 0.0, 0.0)})
    world_hands(rig, crouch, {"r": (-0.42, -0.42, 0.42), "l": (0.26, -0.40, 0.70)}, out=0.3)
    push = _body(rig, 0.20, (20.0, -6.0, -4.0), (8.0, -2.0, 0.0), head=(-6.0, 0.0, 0.0), jaw=14.0)
    world_hands(rig, push, {"r": (-0.42, -0.30, 0.50)}, out=0.2)
    roar = _body(rig, 0.04, (-4.0, -2.0, 0.0), (-8.0, 0.0, 0.0), (-5.0, 0, 0), head=(-20.0, 0.0, 0.0), jaw=36.0)
    world_hands(rig, roar, {"r": (-0.62, -0.18, 0.80), "l": (0.36, -0.10, 1.10)}, out=0.4)
    return track(t, [(0.0, crouch), (0.15, crouch), (0.45, push), (0.72, roar), (0.88, roar),
                     (SPAWN_TIME, rest_arms(stand(rig)))])


CLIPS = [("death_a", death_a, DEATH_A_TIME), ("death_b", death_b, DEATH_B_TIME), ("spawn", spawn, SPAWN_TIME)]
