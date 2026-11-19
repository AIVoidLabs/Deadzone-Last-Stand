"""Yürüyen ölüm ve doğma klipleri (Aşama V.5) — walker_anims.py'nin devamı, aynı sözleşme.

death_a: vurulup sarsılır, dizleri çöker, öne yüzüstü kapaklanır; kollar başın yanına yığılır, küçük sekme.
death_b: kafası yana savrulur, iki dizinin üstüne çöker, bir an sallanır, düşük omzuna (sola) devrilir.
spawn  : çömelmiş, elleri yere yakın, başı önde; doğrulur, baş en son kalkar (spawn_time 0.9 sn).
Ölümlerde anahtar pozlar önce kemik dönüşüne çözülür (IK -> FK), sonra aradeğerlenir: yerde yatan
pozlarda ayak hedefi yok, bacaklar dönüşle verilir.
"""
import walker_pose as wp
from walker_anims import hands, rest_arms, side, stand
from walker_pose import blend, merge, track

DEATH_A_TIME = 1.4
DEATH_B_TIME = 1.5
SPAWN_TIME = 0.9


# kapaklanma ortasında bacaklar (yere değmesinler diye ölçülerek seçildi)
FALL_LEGS = {"thigh_l": (20.0, 0.0, 4.0), "thigh_r": (26.0, 0.0, -6.0), "calf_l": (50.0, 0.0, 0.0),
             "calf_r": (40.0, 0.0, 0.0), "foot_l": (10.0, 0.0, 0.0), "foot_r": (10.0, 0.0, 0.0),
             "ball_l": (0.0, 0.0, 0.0), "ball_r": (0.0, 0.0, 0.0)}


# yan yatış (death_b sonu): pelvis yüksekliği, sola yatış ve bükük bacaklar (ölçülerek)
SIDE_LIE = {"z": -0.70, "roll": 86.0,
            "legs": {"thigh_l": (-50.0, 0.0, 0.0), "calf_l": (70.0, 0.0, 0.0), "foot_l": (20.0, 0.0, 0.0),
                     "thigh_r": (-35.0, 0.0, 0.0), "calf_r": (60.0, 0.0, 0.0), "foot_r": (20.0, 0.0, 0.0)}}


# devrilme ortası: bacakların yan yatışa geçiş payı, pelvis yüksekliği, sol ayağa ek dönüş (parmak gömülmesin)
SIDE_WIDTH_LIFT = 0.45   # omuz oranındaki her +1 için yan yatışta pelvis bu kadar yükselir (m)
TILT = {"mix": 0.4, "z": -0.36, "foot": (-30.0, 0.0, -30.0)}


def fk(rig, pose: dict) -> dict:
    """IK girdilerini dönüşe çevirir (kopya üstünde)."""
    return wp.solve_arms(rig, wp.solve_legs(rig, {k: dict(v) for k, v in pose.items()}))


def _jolt(rig, roll: float) -> dict:
    s = rig.s
    pose = merge(stand(rig, 0.03), {
        "pelvis": {"loc": (0.0, 0.05 * s, -0.03 * s), "rot": (-5.0, roll * 0.3, 0.0)},
        "spine_01": {"rot": (-10.0, 0.0, 0.0)}, "spine_02": {"rot": (-8.0, roll * 0.5, 0.0)},
        "Head": {"rot": (-22.0, roll, roll * 0.5)}, "jaw": {"rot": (24.0, 0.0, 0.0)},
    })
    side(pose, "upperarm", (-18.0, -20.0, 0.0))
    side(pose, "lowerarm", (-12.0, 0.0, 0.0))
    return pose


def two_phase(t: float, rig, ik_keys, fk_keys) -> dict:
    """Ayaklar yerdeyken IK hedefleriyle (kaymaz), yere yığılırken kemik dönüşleriyle aradeğerler."""
    if t <= ik_keys[-1][0]:
        return track(t, ik_keys)
    return track(t, [(k, fk(rig, p)) for k, p in ik_keys[-2:] + fk_keys])


def death_a(t: float, rig) -> dict:
    s = rig.s
    buckle = merge(stand(rig, 0.30), {
        "pelvis": {"loc": (0.0, -0.06 * s, -0.30 * s), "rot": (14.0, 0.0, 0.0)},
        "spine_01": {"rot": (14.0, 0.0, 0.0)}, "spine_02": {"rot": (8.0, 0.0, 0.0)},
        "Head": {"rot": (18.0, -6.0, 0.0)}, "jaw": {"rot": (14.0, 0.0, 0.0)},
    })
    side(buckle, "upperarm", (14.0, 4.0, 0.0))
    side(buckle, "lowerarm", (12.0, 0.0, 0.0))
    tip = merge(buckle, {
        "pelvis": {"loc": (0.0, -0.22 * s, -0.48 * s), "rot": (48.0, 0.0, 4.0)},
        "spine_01": {"rot": (10.0, 0.0, 0.0)},
        "Head": {"rot": (-10.0, -6.0, 0.0)}, "jaw": {"rot": (22.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.02 * s, 55.0, 0.0, 0.0)}, "ik_r": {"foot": (0.0, 40.0, 0.0, 0.0)},
    })
    hands(rig, tip, (0.22, -0.42, 0.05), out=0.3)
    flat = {
        "pelvis": {"loc": (0.0, -0.40 * s, -0.75 * s), "rot": (86.0, 0.0, 6.0)},
        "spine_01": {"rot": (-2.0, 0.0, 0.0)}, "spine_02": {"rot": (-3.0, 0.0, 0.0)},
        "neck_01": {"rot": (-14.0, 0.0, 0.0)}, "Head": {"rot": (-16.0, 0.0, 38.0)},
        "jaw": {"rot": (18.0, 0.0, 0.0)},
        "thigh_l": {"rot": (-2.0, 0.0, 4.0)}, "calf_l": {"rot": (6.0, 0.0, 0.0)}, "foot_l": {"rot": (20.0, 0.0, 0.0)},
        "thigh_r": {"rot": (2.0, 0.0, -6.0)}, "calf_r": {"rot": (2.0, 0.0, 0.0)}, "foot_r": {"rot": (18.0, 0.0, 0.0)},
    }
    hands(rig, flat, (0.30, 0.02, 0.22), (0.26, 0.04, -0.12), out=0.2)
    bounce = merge(flat, {"pelvis": {"loc": (0.0, -0.40 * s, -0.72 * s), "rot": (82.0, 0.0, 6.0)},
                          "Head": {"rot": (-24.0, 0.0, 34.0)}})
    # kapaklanma ortası: gövde 70 derece, ayak uçları geriye uzanır (parmak yere gömülmesin)
    fall = merge(blend(fk(rig, tip), flat, 0.6), {
        "pelvis": {"loc": (0.0, -0.36 * s, -0.60 * s), "rot": (72.0, 0.0, 5.0)},
    })
    for bone, rot in FALL_LEGS.items():
        fall[bone] = {"rot": rot}
    ik_keys = [(0.0, stand(rig)), (0.12, _jolt(rig, 0.0)), (0.42, buckle), (0.72, tip)]
    return two_phase(t, rig, ik_keys, [(0.86, fall), (0.98, flat), (1.12, bounce), (DEATH_A_TIME, flat)])


def death_b(t: float, rig) -> dict:
    s = rig.s
    kneel = merge(stand(rig), {
        "pelvis": {"loc": (0.0, 0.10 * s, -0.44 * s), "rot": (6.0, 0.0, 0.0)},
        "spine_01": {"rot": (10.0, 0.0, 0.0)}, "spine_02": {"rot": (8.0, 4.0, 0.0)},
        "Head": {"rot": (26.0, 10.0, 0.0)}, "jaw": {"rot": (20.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.40 * s, 75.0, 0.0, 0.0)}, "ik_r": {"foot": (0.50 * s, 75.0, 0.0, 0.0)},
    })
    side(kneel, "upperarm", (16.0, 6.0, 0.0))
    side(kneel, "lowerarm", (10.0, 0.0, 0.0))
    sway = merge(kneel, {"pelvis": {"loc": (0.0, 0.10 * s, -0.45 * s), "rot": (2.0, 5.0, 0.0)},
                         "spine_02": {"rot": (2.0, 8.0, 0.0)}, "Head": {"rot": (8.0, 22.0, 6.0)}})
    k = fk(rig, kneel)
    lie = SIDE_LIE
    wide = (rig.w - 1.0) * SIDE_WIDTH_LIFT    # geniş omuzlu çeşit yan yatınca daha yüksekte kalır
    down = merge({n: {"rot": r} for n, r in lie["legs"].items()}, {
        "pelvis": {"loc": (0.30 * s, 0.10 * s, lie["z"] * s + wide), "rot": (8.0, lie["roll"], 10.0)},
        "spine_01": {"rot": (6.0, 0.0, 0.0)}, "spine_02": {"rot": (4.0, -2.0, 0.0)},
        "neck_01": {"rot": (0.0, -6.0, 0.0)}, "Head": {"rot": (6.0, -10.0, 10.0)}, "jaw": {"rot": (26.0, 0.0, 0.0)},
    })
    hands(rig, down, (-0.12, -0.40, 0.10), (0.02, -0.22, -0.36), out=0.2)
    bounce = merge(down, {"pelvis": {"loc": (0.30 * s, 0.10 * s, (lie["z"] + 0.03) * s + wide),
                                     "rot": (8.0, lie["roll"] - 4.0, 10.0)}})
    tilt = merge(blend(k, down, TILT["mix"]), {"pelvis": {"loc": (0.14 * s, 0.10 * s, TILT["z"] * s + wide * 0.5),
                                                          "rot": (6.0, 34.0, 6.0)}})
    fl = tilt["foot_l"]["rot"]
    tilt["foot_l"] = {"rot": (fl[0] + TILT["foot"][0], fl[1], fl[2] + TILT["foot"][2])}
    ik_keys = [(0.0, stand(rig)), (0.12, _jolt(rig, -16.0)), (0.48, kneel), (0.72, sway)]
    return two_phase(t, rig, ik_keys, [(0.94, tilt), (1.12, down), (1.26, bounce), (DEATH_B_TIME, down)])


def spawn(t: float, rig) -> dict:
    s = rig.s
    crouch = merge(stand(rig), {
        "pelvis": {"loc": (0.0, 0.10 * s, -0.42 * s), "rot": (24.0, 0.0, 0.0)},
        "spine_01": {"rot": (22.0, 0.0, 0.0)}, "spine_02": {"rot": (14.0, 0.0, 0.0)},
        "neck_01": {"rot": (10.0, 0.0, 0.0)}, "Head": {"rot": (26.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.0, 35.0, 0.0, 0.0)},
    })
    hands(rig, crouch, (0.06, -0.45, -0.25), out=0.1)
    half = merge(stand(rig, 0.20), {
        "pelvis": {"loc": (0.0, 0.05 * s, -0.20 * s), "rot": (16.0, 0.0, 0.0)},
        "spine_01": {"rot": (14.0, 0.0, 0.0)}, "spine_02": {"rot": (8.0, 0.0, 0.0)},
        "neck_01": {"rot": (8.0, 0.0, 0.0)}, "Head": {"rot": (24.0, 4.0, 0.0)},
    })
    hands(rig, half, (0.05, -0.30, -0.32), out=0.1)
    lift = merge(stand(rig, 0.03), {"Head": {"rot": (-10.0, -4.0, 0.0)}, "jaw": {"rot": (22.0, 0.0, 0.0)},
                                    "spine_02": {"rot": (-3.0, 0.0, 0.0)}})
    rest_arms(lift)
    end = rest_arms(stand(rig))
    return track(t, [(0.0, crouch), (0.12, crouch), (0.45, half), (0.72, lift), (SPAWN_TIME, end)])


CLIPS = [("death_a", death_a, DEATH_A_TIME), ("death_b", death_b, DEATH_B_TIME), ("spawn", spawn, SPAWN_TIME)]
