"""Çığlıkçı ölüm ve doğma klipleri (7.3) — screamer_anims.py'nin devamı, aynı sözleşme.

death_a: göğsüne darbe, bir adım geri sendeler, dizleri kilitli uzun gövde ağaç gibi SIRT ÜSTÜ devrilir;
         uzun boyun kırbaç gibi gecikir, kafa yere çarpıp yana döner, kollar yana açılır; küçük sekme.
death_b: dizleri çözülür, iki dizinin üstüne çöker, bir an sallanır, öne yüzüstü kapaklanır.
spawn  : yerde büzülmüş çömelme (kafa dizlerde); uzun bacaklar açılır, gövde doğrulur, boyun en son uzanır.
Ayaklar yerdeyken IK hedefiyle, yere yığılırken kemik dönüşüyle aradeğerlenir (walker_falls.two_phase).
Yerde yatan pozların pelvis yüksekliği ağın en alt noktası ölçülerek seçildi (screamer_check.py).
"""
import walker_falls as wf
from screamer_anims import _body, both, rest_arms, side, stand, world_hands
from walker_pose import merge, track

DEATH_A_TIME = 1.5
DEATH_B_TIME = 1.5
SPAWN_TIME = 1.0
SUPINE = {"z": -0.755, "y": 0.62, "pitch": -86.0}   # sırt üstü: pelvis inişi / geri kayma (m, rig.s), eğim
SUPINE_LEGS = {"thigh_l": (-14.0, 0.0, 7.0), "calf_l": (22.0, 0.0, 0.0), "foot_l": (-20.0, 0.0, 0.0),
               "thigh_r": (-4.0, 0.0, -9.0), "calf_r": (8.0, 0.0, 0.0), "foot_r": (-24.0, 0.0, 0.0)}
PRONE = {"z": -0.765, "y": -0.52, "pitch": 84.0}    # yüzüstü
PRONE_LEGS = {"thigh_l": (-4.0, 0.0, 8.0), "calf_l": (12.0, 0.0, 0.0), "foot_l": (30.0, 0.0, 0.0),
              "thigh_r": (2.0, 0.0, -8.0), "calf_r": (18.0, 0.0, 0.0), "foot_r": (30.0, 0.0, 0.0)}
FALL_LEGS = {"thigh_l": {"rot": (14.0, 0.0, 6.0)}, "calf_l": {"rot": (40.0, 0.0, 0.0)},
             "foot_l": {"rot": (30.0, 0.0, 0.0)}, "thigh_r": {"rot": (18.0, 0.0, -6.0)},
             "calf_r": {"rot": (34.0, 0.0, 0.0)}, "foot_r": {"rot": (30.0, 0.0, 0.0)}}


def _lying(rig, spec, legs, bounce=0.0, roll=0.0, head=(0.0, 0.0, 30.0), arms=None, neck=None, hands=None):
    s = rig.s
    sign = 1.0 if spec["pitch"] > 0 else -1.0
    pose = {n: {"rot": r} for n, r in legs.items()}
    pose.update({
        "pelvis": {"loc": (0.0, spec["y"] * s, (spec["z"] + bounce) * s),
                   "rot": (spec["pitch"] - sign * bounce * 110.0, 0.0, roll)},
        "spine_01": {"rot": (-2.0 * sign, 0.0, 0.0)}, "spine_02": {"rot": (-3.0 * sign, 0.0, 0.0)},
        "spine_03": {"rot": (-3.0 * sign, 0.0, 0.0)},
        "neck_01": {"rot": neck or (-14.0 * sign, 0.0, head[2] * 0.3)}, "Head": {"rot": head},
        "jaw": {"rot": (26.0, 0.0, 0.0)},
    })
    for sd, r in (hands or {}).items():
        pose["hand_" + sd] = {"rot": r}
    world_hands(rig, pose, arms, out=0.3)
    return wf.fk(rig, pose)


def _supine(rig, bounce=0.0):
    y = SUPINE["y"]
    return _lying(rig, SUPINE, SUPINE_LEGS, bounce, roll=6.0, head=(-12.0, 0.0, 34.0), neck=(-16.0, 0.0, 10.0),
                  arms={"l": (0.62, y + 0.16, 0.13), "r": (-0.62, y + 0.06, 0.13)})


def _prone(rig, bounce=0.0, roll=-6.0, head_turn=-32.0):
    y = PRONE["y"]
    return _lying(rig, PRONE, PRONE_LEGS, bounce, roll=roll, head=(-12.0, 0.0, head_turn),
                  arms={"l": (0.30, y - 0.70, 0.08), "r": (-0.42, y - 0.50, 0.08)},
                  hands={"l": (-85.0, 0.0, 0.0), "r": (-85.0, 0.0, 0.0)})


def _jolt(rig, roll):
    s = rig.s
    pose = merge(stand(rig, 0.03), {
        "pelvis": {"loc": (0.0, 0.05 * s, -0.04 * s), "rot": (-6.0, roll * 0.3, 0.0)},
        "spine_01": {"rot": (-8.0, 0.0, 0.0)}, "spine_02": {"rot": (-8.0, roll * 0.5, 0.0)},
        "neck_01": {"rot": (10.0, 0.0, 0.0)}, "Head": {"rot": (4.0, roll, roll * 0.4)}, "jaw": {"rot": (24.0, 0.0, 0.0)},
    })
    side(pose, "upperarm", (-18.0, 14.0, 0.0))
    side(pose, "lowerarm", (-16.0, 0.0, 0.0))
    return pose


def death_a(t, rig):
    s = rig.s
    back = _body(rig, 0.05, (-10.0, 0.0, 4.0), (-6.0, 0.0, 0.0), (-4.0, 0, 0), neck=(-6.0, 0, 0),
                 head=(-20.0, 0.0, 6.0), jaw=30.0, feet={"l": (0.30, -8.0, 0.0, 0.03), "r": (0.0, 0.0, 0.0, 0.0)},
                 loc=(0.0, 0.14))
    world_hands(rig, back, both(0.50, -0.10, 1.12), out=0.3)
    tip = merge(back, {
        "pelvis": {"loc": (0.0, 0.32 * s, -0.18 * s), "rot": (-34.0, 0.0, 6.0)},
        "neck_01": {"rot": (14.0, 0.0, 0.0)}, "Head": {"rot": (12.0, 0.0, 8.0)},
        "ik_l": {"foot": (0.10 * s, -24.0, 0.0, 0.03 * s)}, "ik_r": {"foot": (-0.08 * s, -30.0, 0.0, 0.0)},
    })
    world_hands(rig, tip, both(0.62, 0.20, 1.20), out=0.3)
    land = _supine(rig)
    fall = wf.blend(wf.fk(rig, tip), land, 0.55)
    fall = merge(fall, {"pelvis": {"loc": (0.0, 0.52 * s, -0.48 * s), "rot": (-64.0, 0.0, 6.0)},
                        "neck_01": {"rot": (20.0, 0.0, 6.0)}, "Head": {"rot": (14.0, 0.0, 14.0)}})
    ik_keys = [(0.0, stand(rig)), (0.10, _jolt(rig, 4.0)), (0.40, back), (0.66, tip)]
    return wf.two_phase(t, rig, ik_keys, [(0.86, fall), (0.98, land), (1.10, _supine(rig, 0.03)),
                                          (1.24, land), (DEATH_A_TIME, land)])


def death_b(t, rig):
    s = rig.s
    kneel = _body(rig, 0.52, (10.0, 0.0, -4.0), (8.0, 0.0, 0.0), (4.0, 0, 0), neck=(16.0, 0, 0),
                  head=(10.0, 8.0, 0.0), jaw=24.0,
                  feet={"l": (0.42, 74.0, 0.0, 0.0), "r": (0.48, 74.0, 0.0, 0.0)}, loc=(0.0, 0.12))
    world_hands(rig, kneel, both(0.24, -0.22, 0.52), out=0.2)
    sway = merge(kneel, {"pelvis": {"loc": (0.02 * s, 0.12 * s, -0.54 * s), "rot": (16.0, 6.0, 0.0)},
                         "spine_02": {"rot": (10.0, 6.0, 0.0)}, "Head": {"rot": (20.0, -10.0, 6.0)}})
    world_hands(rig, sway, both(0.26, -0.30, 0.42), out=0.2)
    down = _prone(rig)
    topple = merge(wf.blend(wf.fk(rig, sway), down, 0.45), {
        "pelvis": {"loc": (0.0, -0.20 * s, -0.50 * s), "rot": (50.0, 0.0, -4.0)}, **FALL_LEGS})
    topple = wf.fk(rig, world_hands(rig, topple, both(0.30, -0.80, 0.40), out=0.2))   # eller öne uzanır
    ik_keys = [(0.0, stand(rig)), (0.12, _jolt(rig, -8.0)), (0.48, kneel), (0.78, sway)]
    return wf.two_phase(t, rig, ik_keys, [(1.00, topple), (1.10, down), (1.22, _prone(rig, 0.03)),
                                          (1.34, down), (DEATH_B_TIME, down)])


def spawn(t, rig):
    crouch = _body(rig, 0.50, (40.0, 0.0, 0.0), (18.0, 0.0, 0.0), (10.0, 0, 0), neck=(30.0, 0, 0),
                   head=(10.0, 0.0, 0.0), jaw=-6.0, feet={"l": (0.0, 24.0, 0.0, 0.04), "r": (0.0, 24.0, 0.0, -0.04)})
    world_hands(rig, crouch, both(0.20, -0.40, 0.30), out=0.3)
    unfold = _body(rig, 0.22, (22.0, 0.0, 0.0), (8.0, 0.0, 0.0), (4.0, 0, 0), neck=(18.0, 0, 0),
                   head=(4.0, 0.0, 0.0), jaw=0.0)
    world_hands(rig, unfold, both(0.24, -0.20, 0.70), out=0.2)
    tall = _body(rig, 0.0, (-3.0, 0.0, 0.0), (-4.0, 0.0, 0.0), (-3.0, 0, 0), neck=(-14.0, 0, 0),
                 head=(-10.0, 0.0, 0.0), jaw=22.0)
    world_hands(rig, tall, both(0.30, -0.06, 0.92), out=0.1)
    return track(t, [(0.0, crouch), (0.12, crouch), (0.42, unfold), (0.70, tall), (0.84, tall),
                     (SPAWN_TIME, rest_arms(stand(rig)))])


CLIPS = [("death_a", death_a, DEATH_A_TIME), ("death_b", death_b, DEATH_B_TIME), ("spawn", spawn, SPAWN_TIME)]
