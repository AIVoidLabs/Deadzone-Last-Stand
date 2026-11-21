"""Patlayıcı ölüm ve doğma klipleri (7.3) — bloater_anims.py'nin devamı, aynı sözleşme (ölçek dahil).

death_a (1.6, yalnız FEATURE_ZOMBIE_BLOAT kapalıyken): göbeğe darbe, geri sendeler, topuklar kalkar,
  sırtüstü devrilir; yuvarlak sırtında bir kez sekip yuvarlanır, kollar iki yana açılır, göbek
  çarpmada basılıp dalgalanır (ölçek).
spawn (1.2): öne çökük, göbeği sönük (ölçek 0.92) çömelmeden hırıltıyla doğrulur, nefes alıp şişer
  (1.05), kollarını açıp kafasını kaldırır, duruşa yerleşir.
Ayaklar yerdeyken IK, yere yığılırken kemik dönüşü (walker_falls.two_phase). Sırtüstü yatışta pelvis
yüksekliği ağın en alt noktası ölçülerek seçildi (bloater_check.py).
"""
import walker_falls as wf
from bloater_anims import bloat, side, stand
from walker_pose import merge, track

DEATH_A_TIME = 1.6
SPAWN_TIME = 1.2
SUPINE_Z = -0.12          # sırtüstü yatışta pelvis inişi (m, rig.s ile): küre gövde yerde
SUPINE_Y = 0.42           # geriye kayma (m, rig.s ile)
SUPINE_LEGS = {"thigh_l": (62.0, 0.0, 10.0), "calf_l": (-30.0, 0.0, 0.0), "foot_l": (-10.0, 0.0, 0.0),
               "thigh_r": (52.0, 0.0, -14.0), "calf_r": (-18.0, 0.0, 0.0), "foot_r": (-14.0, 0.0, 0.0)}


def _supine(rig, bounce=0.0, roll=8.0, k=1.0):
    """Sırtüstü: gövde geriye yatık, bacaklar havada bükük, kollar iki yana açık, kafa yana düşmüş."""
    s = rig.s
    pose = {n: {"rot": r} for n, r in SUPINE_LEGS.items()}
    pose.update({
        "pelvis": {"loc": (0.0, SUPINE_Y * s, (SUPINE_Z + bounce) * s), "rot": (-78.0 + 60 * bounce, roll, 0.0)},
        "spine_01": {"rot": (-4.0, 0.0, 0.0)}, "spine_02": {"rot": (-4.0, 0.0, 0.0)},
        "neck_01": {"rot": (8.0, 0.0, 0.0)}, "Head": {"rot": (10.0, 0.0, -38.0)},
        "jaw": {"rot": (26.0, 0.0, 0.0)},
    })
    side(pose, "upperarm", (-20.0, -55.0, 0.0))
    side(pose, "lowerarm", (-25.0, 0.0, 0.0))
    side(pose, "hand", (-15.0, 0.0, 0.0))
    return bloat(pose, k)


def death_a(t, rig):
    s = rig.s
    jolt = merge(stand(rig, 0.03), {
        "pelvis": {"loc": (0.0, 0.05 * s, -0.03 * s), "rot": (-6.0, 3.0, 0.0)},
        "spine_01": {"rot": (-6.0, 0.0, 0.0), "scale": 0.95}, "spine_02": {"rot": (-6.0, 3.0, 0.0)},
        "Head": {"rot": (-20.0, 8.0, 4.0)}, "jaw": {"rot": (30.0, 0.0, 0.0)},
    })
    side(jolt, "upperarm", (-14.0, -20.0, 0.0))
    side(jolt, "lowerarm", (-14.0, 0.0, 0.0))
    stumble = merge(stand(rig, 0.12), {
        "pelvis": {"loc": (0.0, 0.10 * s, -0.12 * s), "rot": (-12.0, -3.0, 4.0)},
        "spine_01": {"rot": (-6.0, 0.0, 0.0), "scale": 1.03}, "spine_02": {"rot": (-6.0, -3.0, 0.0)},
        "Head": {"rot": (-6.0, -6.0, 0.0)}, "jaw": {"rot": (22.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.10 * s, 0.0, 0.0, 0.05 * s)}, "ik_r": {"foot": (-0.02 * s, 0.0, 0.0, -0.06 * s)},
    })
    side(stumble, "upperarm", (-30.0, -35.0, 0.0))
    side(stumble, "lowerarm", (-30.0, 0.0, 0.0))
    tip = merge(stumble, {
        "pelvis": {"loc": (0.0, 0.22 * s, -0.20 * s), "rot": (-30.0, -2.0, 6.0)},
        "spine_01": {"rot": (-8.0, 0.0, 0.0), "scale": 1.0},
        "Head": {"rot": (8.0, -4.0, 0.0)},
        "ik_l": {"foot": (0.12 * s, -24.0, 0.0, 0.05 * s)}, "ik_r": {"foot": (0.04 * s, -18.0, 0.0, -0.06 * s)},
    })
    side(tip, "upperarm", (-55.0, -45.0, 0.0))
    fall = merge(wf.blend(wf.fk(rig, tip), _supine(rig), 0.55), {
        "pelvis": {"loc": (0.0, 0.32 * s, -0.16 * s), "rot": (-58.0, 2.0, 6.0)}})
    ik_keys = [(0.0, bloat(stand(rig), 1.0)), (0.12, jolt), (0.42, stumble), (0.72, tip)]
    return wf.two_phase(t, rig, ik_keys, [
        (0.92, fall), (1.04, _supine(rig, k=0.92)), (1.16, _supine(rig, 0.045, roll=14.0, k=1.05)),
        (1.30, _supine(rig, 0.0, roll=4.0, k=0.98)), (1.42, _supine(rig, 0.01, roll=9.0, k=1.01)),
        (DEATH_A_TIME, _supine(rig, 0.0, roll=8.0, k=1.0))])


def spawn(t, rig):
    s = rig.s
    slump = merge(stand(rig, 0.26, 0.06), {
        "pelvis": {"loc": (0.0, 0.10 * s, -0.26 * s), "rot": (22.0, 0.0, 0.0)},
        "spine_01": {"rot": (12.0, 0.0, 0.0), "scale": 0.92}, "spine_02": {"rot": (10.0, 0.0, 0.0)},
        "neck_01": {"rot": (16.0, 0.0, 0.0)}, "Head": {"rot": (22.0, 6.0, 0.0)},
        "jaw": {"rot": (24.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.0, 14.0, 0.0, 0.06 * s)}, "ik_r": {"foot": (0.0, 14.0, 0.0, -0.06 * s)},
    })
    side(slump, "upperarm", (24.0, 6.0, 0.0))
    side(slump, "lowerarm", (-20.0, 0.0, 0.0))
    heave = merge(stand(rig, 0.14, 0.05), {
        "pelvis": {"loc": (0.0, 0.05 * s, -0.14 * s), "rot": (10.0, -3.0, 4.0)},
        "spine_01": {"rot": (6.0, 0.0, 0.0), "scale": 0.97}, "spine_02": {"rot": (4.0, 2.0, 0.0)},
        "Head": {"rot": (6.0, -4.0, 0.0)}, "jaw": {"rot": (16.0, 0.0, 0.0)},
    })
    side(heave, "upperarm", (8.0, -8.0, 0.0))
    breathe = merge(stand(rig, 0.03, 0.04), {
        "pelvis": {"rot": (-4.0, 0.0, 0.0)}, "spine_01": {"rot": (-4.0, 0.0, 0.0), "scale": 1.06},
        "spine_02": {"rot": (-5.0, 0.0, 0.0)}, "Head": {"rot": (-18.0, 0.0, 0.0)},
        "jaw": {"rot": (36.0, 0.0, 0.0)},
    })
    side(breathe, "upperarm", (-10.0, -30.0, 0.0))
    side(breathe, "lowerarm", (-16.0, 0.0, 0.0))
    end = bloat(stand(rig), 1.0)
    return track(t, [(0.0, slump), (0.12, slump), (0.42, heave), (0.72, breathe), (0.88, breathe),
                     (SPAWN_TIME, end)])


CLIPS = [("death_a", death_a, DEATH_A_TIME), ("spawn", spawn, SPAWN_TIME)]
