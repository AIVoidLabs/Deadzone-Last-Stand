"""Boss "Yığın" ölüm ve doğma klipleri (7.4) — boss_anims.py'nin devamı, aynı sözleşme.

death (3.0): 0.25 kalbinden vurulmuş gibi sarsılır (göğüs öne, kafa geri), 0.75 dizleri çözülür, 1.25 dizlerinin
  üstüne çöker, 1.6 sallanır (kafa ve kollar düşer), 2.15 öne devrilir, 2.4 yüzüstü yere çarpar (kambur öne
  yığılır, kollar iki yana savrulur), 2.55 küçük sekme, 3.0 yerleşmiş (kambur sarkık, bedenler dağılmış gibi).
  Ayaklar yerdeyken IK, devrilirken kemik dönüşü (walker_falls.two_phase). Yüzüstü yatışta pelvis yüksekliği
  ağın en alt noktası ölçülerek seçildi (boss_check.py).
spawn (2.0): yerden kalkış: kollarını yere dayamış çökük yığın → 0.5 hırıltıyla kabarır → 0.9 kollarıyla iter →
  1.35 yarı doğrulmuş → 1.65 göğsünü açıp kısa kükrer → 2.0 duruş.
"""
import walker_falls as wf
from boss_anims import base_pose, side, stand, world_hands
from walker_pose import merge, track

DEATH_TIME = 3.0
SPAWN_TIME = 2.0
PRONE_Z = -0.02           # yüzüstü yatışta pelvis inişi (m)
PRONE_Y = -1.10           # öne kayma (m)
PRONE_LEGS = {"thigh_l": (-20.0, 0.0, 10.0), "calf_l": (40.0, 0.0, 0.0), "foot_l": (30.0, 0.0, 0.0),
              "thigh_r": (-10.0, 0.0, -14.0), "calf_r": (30.0, 0.0, 0.0), "foot_r": (30.0, 0.0, 0.0)}


def _kneel(rig, sway=0.0, droop=0.0):
    pose = merge(stand(rig, 0.70, 0.16, 10.0 + 6.0 * droop), {
        "pelvis": {"loc": (0.0, -0.10, -0.70), "rot": (10.0 + 6.0 * droop, sway, 0.4 * sway)},
        "spine_01": {"rot": (6.0 + 4.0 * droop, -0.5 * sway, 0.0)}, "spine_02": {"rot": (4.0 * droop, 0.0, 0.0)},
        "hump": {"rot": (8.0 * droop, sway, 0.0)},
        "neck_01": {"rot": (8.0 + 10.0 * droop, 0.0, 0.0)}, "Head": {"rot": (6.0 + 14.0 * droop, sway, 0.0)},
        "jaw": {"rot": (30.0, 0.0, 0.0)}, "claw_r": {"rot": (-10.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.10, 24.0, 0.0, 0.16)}, "ik_r": {"foot": (0.14, 24.0, 0.0, -0.16)},
    })
    return world_hands(rig, pose, (0.98, -0.50 - 0.15 * droop, 1.12), (-0.98, -0.50 - 0.15 * droop, 1.00), 0.3)


def _prone(rig, bounce=0.0, k=1.0):
    pose = {n: {"rot": r} for n, r in PRONE_LEGS.items()}
    pose.update({
        "pelvis": {"loc": (0.0, PRONE_Y, PRONE_Z + bounce), "rot": (80.0 - 25.0 * bounce, 4.0, 3.0)},
        "spine_01": {"rot": (4.0, 0.0, 0.0)}, "spine_02": {"rot": (2.0, 0.0, 0.0)},
        "hump": {"rot": (16.0 * k, 6.0 * k, 0.0)},
        "neck_01": {"rot": (-30.0, 0.0, 0.0)}, "Head": {"rot": (-20.0, 0.0, 30.0)},
        "jaw": {"rot": (24.0, 0.0, 0.0)}, "claw_r": {"rot": (20.0, 0.0, 0.0)},
    })
    side(pose, "clavicle", (0.0, -6.0, 0.0))
    side(pose, "upperarm", (14.0, -62.0, 0.0))
    side(pose, "lowerarm", (-10.0, 0.0, 0.0))
    side(pose, "hand", (10.0, 0.0, 0.0))
    return pose


def death(t, rig):
    jolt = merge(stand(rig, 0.06, 0.06, -8.0), {
        "pelvis": {"loc": (0.0, 0.10, -0.06), "rot": (-8.0, 2.0, 0.0)},
        "spine_01": {"rot": (-10.0, 0.0, 0.0)}, "spine_02": {"rot": (-8.0, 2.0, 0.0)},
        "hump": {"rot": (-10.0, 0.0, 0.0)}, "Head": {"rot": (-26.0, 6.0, 4.0)},
        "jaw": {"rot": (42.0, 0.0, 0.0)}, "claw_r": {"rot": (34.0, 0.0, 0.0)},
    })
    side(jolt, "upperarm", (-26.0, -30.0, 0.0))
    side(jolt, "lowerarm", (-34.0, 0.0, 0.0))
    buckle = merge(stand(rig, 0.42, 0.12, 4.0), {
        "pelvis": {"loc": (0.04, 0.02, -0.42), "rot": (4.0, -4.0, 3.0)},
        "Head": {"rot": (-6.0, -6.0, 0.0)}, "jaw": {"rot": (30.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.04, 10.0, 0.0, 0.14)}, "ik_r": {"foot": (0.08, 10.0, 0.0, -0.14)},
    })
    side(buckle, "upperarm", (-14.0, -20.0, 0.0))
    side(buckle, "lowerarm", (-62.0, 0.0, 0.0))
    buckle["claw_r"] = {"rot": (-20.0, 0.0, 0.0)}
    buckle["hand_l"] = {"rot": (-45.0, 0.0, 0.0)}
    topple = merge(wf.blend(wf.fk(rig, _kneel(rig, 0.0, 1.0)), _prone(rig), 0.5), {
        "pelvis": {"loc": (0.0, -0.62, -0.30), "rot": (48.0, 2.0, 2.0)},
        "thigh_l": {"rot": (-64.0, 0.0, 8.0)}, "thigh_r": {"rot": (-58.0, 0.0, -10.0)}})
    side(topple, "upperarm", (24.0, -50.0, 0.0))
    side(topple, "lowerarm", (-40.0, 0.0, 0.0))
    ik_keys = [(0.0, base_pose(rig)), (0.25, jolt), (0.75, buckle), (1.25, _kneel(rig)),
               (1.45, _kneel(rig, 5.0, 0.5)), (1.7, _kneel(rig, -4.0, 1.0))]
    return wf.two_phase(t, rig, ik_keys, [
        (2.15, topple), (2.40, _prone(rig)), (2.55, _prone(rig, 0.05, 1.2)), (2.70, _prone(rig, 0.0, 1.1)),
        (DEATH_TIME, _prone(rig, 0.0, 1.3))])


def _heap(rig, crouch=0.62, lean=42.0, hands_z=0.95):
    pose = merge(stand(rig, crouch, 0.16, lean), {
        "pelvis": {"loc": (0.0, 0.10, -crouch), "rot": (lean, 0.0, 0.0)},
        "spine_01": {"rot": (14.0, 0.0, 0.0)}, "spine_02": {"rot": (8.0, 0.0, 0.0)},
        "hump": {"rot": (10.0, 0.0, 0.0)}, "neck_01": {"rot": (6.0, 0.0, 0.0)},
        "Head": {"rot": (16.0, 0.0, 0.0)}, "jaw": {"rot": (20.0, 0.0, 0.0)}, "claw_r": {"rot": (-14.0, 0.0, 0.0)},
        })
    return world_hands(rig, pose, (0.82, -1.0, hands_z), (-0.82, -1.0, hands_z - 0.10), 0.3)


def spawn(t, rig):
    heave = merge(_heap(rig, 0.58, 38.0, 0.98), {"hump": {"rot": (-4.0, 0.0, 0.0)}, "jaw": {"rot": (32.0, 0.0, 0.0)}})
    push = _heap(rig, 0.42, 28.0, 1.05)
    half = merge(stand(rig, 0.20, 0.12, 12.0), {
        "spine_01": {"rot": (6.0, 0.0, 0.0)}, "hump": {"rot": (4.0, 0.0, 0.0)},
        "Head": {"rot": (-4.0, 0.0, 0.0)}, "jaw": {"rot": (18.0, 0.0, 0.0)}})
    world_hands(rig, half, (0.95, -0.70, 1.15), (-0.95, -0.70, 1.08), 0.3)
    bellow = merge(stand(rig, 0.06, 0.10, -4.0), {
        "spine_02": {"rot": (-6.0, 0.0, 0.0)}, "hump": {"rot": (-8.0, 0.0, 0.0)},
        "Head": {"rot": (-18.0, 0.0, 0.0)}, "jaw": {"rot": (38.0, 0.0, 0.0)}, "claw_r": {"rot": (28.0, 0.0, 0.0)}})
    side(bellow, "upperarm", (-16.0, -34.0, 0.0))
    side(bellow, "lowerarm", (-18.0, 0.0, 0.0))
    return track(t, [(0.0, _heap(rig)), (0.18, _heap(rig)), (0.50, heave), (0.90, push), (1.35, half),
                     (1.65, bellow), (SPAWN_TIME, base_pose(rig))])


CLIPS = [("death", death, DEATH_TIME), ("spawn", spawn, SPAWN_TIME)]
