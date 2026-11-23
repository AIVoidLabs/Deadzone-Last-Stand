"""Boss "Yığın" saldırı ve tepki klipleri (7.4) — boss_anims.py'nin devamı, aynı sözleşme.

slam (2.1)  : Yer Dövme. 0–0.8 kollar havaya (0.8 doruk: topuz ve pençe başın üstünde, gövde geriye
              gerilmiş, kükrer) → 0.8–1.1 iner → İNİŞ 1.1 sn (= slam_windup; topuz ve pençe önde yerde,
              gövde öne katlanmış, dizler kırık) → 1.1–1.45 sarsıntı ve tutuş → 2.1 duruş.
roar (1.5)  : kükreme; 0.3 nefes, 0.5–1.2 doruk (kollar iki yana açık, göğüs öne, kafa geride, çene sonuna
              kadar açık, titreyerek), 1.5 duruş.
summon (1.3): çağrı; çöker, gövdesini silker (sık anahtarlar: omurga ve kambur kemiği ileri-geri, yana),
              sırttaki bedenler kambur kemiğiyle kıpırdar, 1.05 doğrulur, 1.3 duruş.
spew (1.8)  : kusma (11.F); ayrıntı dosyanın sonunda, kusma anı 0.85 sn.
stun (1.4)  : duvara çarpma; 0.08 sarsılma (kafa geri, kollar öne savrulur), 0.3 geri sendeler,
              0.6–0.9 sersem (kafa sallanır), 1.1 kafasını silker, 1.4 duruş.
Kol hedefleri bilek konumuyla (world_hands, iskelet uzayı), değerler boss_check.py ölçümüyle seçildi.
"""
from mathutils import Vector

import walker_pose as wp
from boss_anims import base_pose, side, stand, world_hands
from walker_pose import merge, track

SLAM_TIME = 2.1
SLAM_PEAK = 0.8
SLAM_HIT = 1.1            # = slam_windup (oyun şok halkasını bu anda başlatır)
SLAM_HAND_Y = -1.30       # inişte bileklerin ileri yeri (m, kök önünde)
SLAM_HAND_Z = 0.615       # inişte bilek yüksekliği (m): topuz başı ve pençe yere değer
SLAM_HAND_X = 0.78
SLAM_CLAW_DZ = 0.23       # pençe bileği daha alçak: parmaklar yere değsin


def _sh(rig, sd="l"):
    return rig.head["upperarm_" + sd]


def _hands_rel(rig, pose, dl, dr, out=0.2):
    """Bilekler omuzların dinlenme yerine göre (dx dışa, dy, dz; m)."""
    tl = _sh(rig, "l") + Vector((dl[0], dl[1], dl[2]))
    tr = _sh(rig, "r") + Vector((-dr[0], dr[1], dr[2]))
    return world_hands(rig, pose, tl, tr, out)


def _gather(rig):
    pose = merge(stand(rig, 0.16, 0.10, 12.0), {
        "spine_01": {"rot": (6.0, 0.0, 0.0)}, "spine_02": {"rot": (4.0, 0.0, 0.0)},
        "hump": {"rot": (4.0, 0.0, 0.0)}, "Head": {"rot": (6.0, 0.0, 0.0)}, "jaw": {"rot": (16.0, 0.0, 0.0)},
        "claw_r": {"rot": (-10.0, 0.0, 0.0)}})
    return _hands_rel(rig, pose, (-0.10, -0.75, 0.10), (-0.10, -0.75, 0.10), 0.25)


def _peak(rig, extra=0.0):
    pose = merge(stand(rig, 0.10, 0.12, -6.0 - extra), {
        "pelvis": {"loc": (0.0, 0.06, -0.10), "rot": (-6.0 - extra, 0.0, 0.0)},
        "spine_01": {"rot": (-8.0 - extra, 0.0, 0.0)}, "spine_02": {"rot": (-8.0, 0.0, 0.0)},
        "spine_03": {"rot": (-6.0, 0.0, 0.0)}, "hump": {"rot": (-6.0, 0.0, 0.0)},
        "neck_01": {"rot": (-6.0, 0.0, 0.0)}, "Head": {"rot": (-20.0, 0.0, 0.0)},
        "jaw": {"rot": (40.0, 0.0, 0.0)}, "claw_r": {"rot": (30.0, 0.0, 0.0)},
        "hand_l": {"rot": (-20.0, 0.0, 0.0)}, "hand_r": {"rot": (-20.0, 0.0, 0.0)},
    })
    return _hands_rel(rig, pose, (-0.30, 0.30 + 0.01 * extra, 1.30), (-0.30, 0.30 + 0.01 * extra, 1.30), 0.2)


def _swing(rig):
    pose = merge(stand(rig, 0.22, 0.12, 18.0), {
        "pelvis": {"loc": (0.0, -0.06, -0.22), "rot": (18.0, 0.0, 0.0)},
        "spine_01": {"rot": (8.0, 0.0, 0.0)}, "spine_02": {"rot": (6.0, 0.0, 0.0)},
        "hump": {"rot": (-4.0, 0.0, 0.0)}, "neck_01": {"rot": (-14.0, 0.0, 0.0)},
        "Head": {"rot": (-10.0, 0.0, 0.0)}, "jaw": {"rot": (34.0, 0.0, 0.0)}, "claw_r": {"rot": (20.0, 0.0, 0.0)},
        "hand_l": {"rot": (-30.0, 0.0, 0.0)}, "hand_r": {"rot": (-30.0, 0.0, 0.0)},
    })
    return _hands_rel(rig, pose, (-0.10, -0.95, 0.75), (-0.10, -0.95, 0.75), 0.2)


def _impact(rig, squash=0.0):
    pose = merge(stand(rig, 0.40 + 0.04 * squash, 0.14, 30.0), {
        "pelvis": {"loc": (0.0, -0.16, -0.40 - 0.04 * squash), "rot": (30.0 + 2.0 * squash, 0.0, 0.0)},
        "spine_01": {"rot": (14.0 + 2.0 * squash, 0.0, 0.0)}, "spine_02": {"rot": (8.0, 0.0, 0.0)},
        "spine_03": {"rot": (4.0, 0.0, 0.0)}, "hump": {"rot": (10.0 + 4.0 * squash, 0.0, 0.0)},
        "neck_01": {"rot": (-24.0, 0.0, 0.0)}, "Head": {"rot": (-18.0, 0.0, 0.0)},
        "jaw": {"rot": (26.0, 0.0, 0.0)}, "claw_r": {"rot": (-14.0, 0.0, 0.0)},
        "hand_l": {"rot": (-55.0, 0.0, 0.0)}, "hand_r": {"rot": (-40.0, 0.0, 0.0)},
        "ik_l": {"foot": (-0.14, 0.0, 0.0, 0.14)}, "ik_r": {"foot": (0.10, 6.0, 0.0, -0.14)},
    })
    z = SLAM_HAND_Z + 0.06 * (1.0 - squash)
    return world_hands(rig, pose, (SLAM_HAND_X, SLAM_HAND_Y, z), (-SLAM_HAND_X, SLAM_HAND_Y, z - SLAM_CLAW_DZ), 0.3)


def _rise(rig):
    pose = merge(stand(rig, 0.24, 0.12, 18.0), {
        "pelvis": {"loc": (0.0, -0.08, -0.24), "rot": (18.0, 0.0, 0.0)},
        "spine_01": {"rot": (8.0, 0.0, 0.0)}, "hump": {"rot": (4.0, 0.0, 0.0)},
        "Head": {"rot": (-8.0, 0.0, 0.0)}, "jaw": {"rot": (14.0, 0.0, 0.0)},
        "hand_l": {"rot": (-20.0, 0.0, 0.0)}, "hand_r": {"rot": (-15.0, 0.0, 0.0)},
    })
    return world_hands(rig, pose, (SLAM_HAND_X, -0.95, 0.95), (-SLAM_HAND_X, -0.95, 0.95), 0.25)


def slam(t, rig):
    """İnişte iki ayrı anahtar dizisi: iniş anı uç anahtar olur (eğri yerin altına taşmaz)."""
    if t <= SLAM_HIT:
        return track(t, [(0.0, base_pose(rig)), (0.35, _gather(rig)), (0.62, _peak(rig)),
                         (SLAM_PEAK, _peak(rig, 5.0)), (0.97, _swing(rig)), (SLAM_HIT, _impact(rig, 1.0))])
    return track(t, [(SLAM_HIT, _impact(rig, 1.0)), (1.20, _impact(rig, 0.4)), (1.45, _impact(rig, 0.6)),
                     (1.75, _rise(rig)), (SLAM_TIME, base_pose(rig))])


# --- kükreme --------------------------------------------------------------------------------
ROAR_TIME = 1.5


def _roar(rig, jit=0.0, k=1.0):
    pose = merge(stand(rig, 0.08, 0.12, -6.0 * k), {
        "pelvis": {"loc": (0.0, 0.04 * k, -0.08), "rot": (-6.0 * k, 0.4 * jit, 0.0)},
        "spine_01": {"rot": (-6.0 * k, -0.6 * jit, 0.0)}, "spine_02": {"rot": (-8.0 * k, jit, 0.0)},
        "spine_03": {"rot": (-6.0 * k, 0.0, 0.0)}, "hump": {"rot": (-10.0 * k, 0.8 * jit, 0.0)},
        "neck_01": {"rot": (-8.0 * k, 0.0, 0.0)}, "Head": {"rot": (-24.0 * k, 1.5 * jit, -jit)},
        "jaw": {"rot": (44.0 * k + abs(jit), 0.0, 0.0)}, "claw_r": {"rot": (34.0 * k, 0.0, 0.0)},
    })
    side(pose, "clavicle", (0.0, -10.0 * k, 0.0))
    side(pose, "upperarm", (-35.0 * k, -65.0 * k, 0.0))
    side(pose, "lowerarm", (-30.0 * k + jit, 0.0, 0.0))
    side(pose, "hand", (-10.0 * k, 0.0, 0.0))
    return pose


def roar(t, rig):
    inhale = merge(stand(rig, 0.18, 0.10, 14.0), {
        "spine_01": {"rot": (6.0, 0.0, 0.0)}, "hump": {"rot": (6.0, 0.0, 0.0)},
        "Head": {"rot": (8.0, 0.0, 0.0)}, "jaw": {"rot": (6.0, 0.0, 0.0)}})
    side(inhale, "upperarm", (-8.0, -8.0, 0.0))
    side(inhale, "lowerarm", (-40.0, 0.0, 0.0))
    keys = [(0.0, base_pose(rig)), (0.30, inhale), (0.50, _roar(rig))]
    for i, tk in enumerate((0.60, 0.70, 0.80, 0.90, 1.00, 1.10)):
        keys.append((tk, _roar(rig, (3.0 if i % 2 else -3.0) * (1.0 + 0.1 * i))))
    keys += [(1.20, _roar(rig)), (1.36, _roar(rig, 0.0, 0.4)), (ROAR_TIME, base_pose(rig))]
    return track(t, keys)


# --- çağrı ----------------------------------------------------------------------------------
SUMMON_TIME = 1.3


def _hunch(rig, a=0.0, b=0.0, k=1.0):
    pose = merge(stand(rig, 0.20 * k, 0.10, 16.0 * k), {
        "pelvis": {"rot": (16.0 * k, 0.5 * b, 0.6 * a)},
        "spine_01": {"rot": (8.0 * k, b, a)}, "spine_02": {"rot": (6.0 * k, -b, -a)},
        "spine_03": {"rot": (4.0 * k, 0.5 * b, 0.0)},
        "hump": {"rot": (10.0 * k + 1.6 * a, 1.6 * b, 0.0)},
        "neck_01": {"rot": (-10.0 * k, -0.5 * b, 0.0)}, "Head": {"rot": (-6.0 * k, b, -1.2 * a)},
        "jaw": {"rot": (24.0 + abs(a), 0.0, 0.0)}, "claw_r": {"rot": (a * 2.0, 0.0, 0.0)},
    })
    side(pose, "upperarm", (6.0 * k + 0.6 * b, -14.0 * k, 0.0))
    side(pose, "lowerarm", (-34.0 * k - abs(a), 0.0, 0.0))
    side(pose, "hand", (0.8 * a, 0.0, 0.0))
    return pose


def summon(t, rig):
    shakes = [(0.25, 8.0, -5.0), (0.333, -9.0, 6.0), (0.417, 10.0, -6.0), (0.50, -10.0, 7.0),
              (0.583, 10.0, -7.0), (0.667, -9.0, 6.0), (0.75, 9.0, -6.0), (0.833, -8.0, 5.0), (0.917, 6.0, -3.0)]
    keys = [(0.0, base_pose(rig)), (0.16, _hunch(rig))]
    keys += [(tk, _hunch(rig, a, b)) for tk, a, b in shakes]
    heave = merge(_hunch(rig, 0.0, 0.0, 0.3), {"Head": {"rot": (-16.0, 0.0, 0.0)}, "jaw": {"rot": (36.0, 0.0, 0.0)},
                                               "hump": {"rot": (-8.0, 0.0, 0.0)}})
    side(heave, "upperarm", (-10.0, -40.0, 0.0))
    keys += [(1.05, heave), (SUMMON_TIME, base_pose(rig))]
    return track(t, keys)


# --- sersemleme -----------------------------------------------------------------------------
STUN_TIME = 1.4


def stun(t, rig):
    hit = merge(stand(rig, 0.10, 0.08, -10.0), {
        "pelvis": {"loc": (0.0, 0.16, -0.10), "rot": (-10.0, 3.0, 0.0)},
        "spine_01": {"rot": (-8.0, 0.0, 0.0)}, "spine_02": {"rot": (-6.0, 3.0, 0.0)},
        "hump": {"rot": (12.0, 0.0, 0.0)}, "neck_01": {"rot": (-10.0, 0.0, 0.0)},
        "Head": {"rot": (-30.0, 6.0, 4.0)}, "jaw": {"rot": (34.0, 0.0, 0.0)}, "claw_r": {"rot": (30.0, 0.0, 0.0)},
    })
    side(hit, "upperarm", (-40.0, -20.0, 0.0))
    side(hit, "lowerarm", (-20.0, 0.0, 0.0))
    stagger = merge(stand(rig, 0.20, 0.10, 4.0), {
        "pelvis": {"loc": (0.06, 0.20, -0.20), "rot": (4.0, -5.0, 6.0)},
        "Head": {"rot": (6.0, -8.0, 10.0)}, "jaw": {"rot": (26.0, 0.0, 0.0)}, "hump": {"rot": (-4.0, 4.0, 0.0)},
        "ik_l": {"foot": (0.30, 0.0, 0.0, 0.12)}, "ik_r": {"foot": (0.12, 0.0, 0.0, -0.12)},
    })
    side(stagger, "upperarm", (4.0, -18.0, 0.0))
    side(stagger, "lowerarm", (-24.0, 0.0, 0.0))

    def daze(roll):
        p = merge(stagger, {"pelvis": {"loc": (0.0, 0.20, -0.24), "rot": (10.0, 0.4 * roll, 0.0)},
                            "spine_01": {"rot": (6.0, 0.3 * roll, 0.0)}, "neck_01": {"rot": (12.0, 0.0, 0.0)},
                            "Head": {"rot": (16.0, roll, 0.8 * roll)}, "jaw": {"rot": (30.0, 0.0, 0.0)}})
        side(p, "upperarm", (-6.0, -10.0, 0.0))
        side(p, "lowerarm", (-42.0, 0.0, 0.0))
        return p
    shake = [(1.02 + 0.06 * i, merge(daze(0.0), {"Head": {"rot": (4.0, 0.0, 18.0 if i % 2 else -18.0)}}))
             for i in range(4)]
    return track(t, [(0.0, merge(base_pose(rig), {"pelvis": {"rot": (14.0, 0.0, 0.0)}})), (0.08, hit),
                     (0.30, stagger), (0.58, daze(14.0)), (0.84, daze(-12.0))] + shake + [(STUN_TIME, base_pose(rig))])


# --- kusma (11.F) ---------------------------------------------------------------------------
# spew (1.8): 0–0.4 geriye gerilip nefes alır (göğüs ve kambur kabarır, kafa yukarı, kollar iki yana açılır)
#   → 0.4–0.85 öne savrulur → KUSMA 0.85 sn (= spew_anim_hit_time; gövde öne katlanmış, kafa ileri-aşağı,
#   çene sonuna kadar açık, kollar alçakta öne dayanmış) → 0.95–1.35 üç öğürme (kambur ve omurga sarsılır)
#   → 1.55 doğrulur → 1.8 duruş.
SPEW_TIME = 1.8
SPEW_HIT = 0.85


def _spew_draw(rig, k=1.0):
    pose = merge(stand(rig, 0.06, 0.14, -10.0 * k), {
        "pelvis": {"loc": (0.0, 0.10 * k, -0.06), "rot": (-10.0 * k, 0.0, 0.0)},
        "spine_01": {"rot": (-8.0 * k, 0.0, 0.0)}, "spine_02": {"rot": (-10.0 * k, 0.0, 0.0)},
        "spine_03": {"rot": (-6.0 * k, 0.0, 0.0)}, "hump": {"rot": (-14.0 * k, 0.0, 0.0)},
        "neck_01": {"rot": (-10.0 * k, 0.0, 0.0)}, "Head": {"rot": (-20.0 * k, 0.0, 0.0)},
        "jaw": {"rot": (14.0 * k, 0.0, 0.0)}, "claw_r": {"rot": (20.0 * k, 0.0, 0.0)},
    })
    side(pose, "clavicle", (0.0, -8.0 * k, 0.0))
    side(pose, "upperarm", (-20.0 * k, -50.0 * k, 0.0))
    side(pose, "lowerarm", (-24.0 * k, 0.0, 0.0))
    return pose


def _spew_out(rig, heave=0.0, k=1.0):
    pose = merge(stand(rig, 0.24 * k, 0.16, 16.0 * k), {
        "pelvis": {"loc": (0.0, -0.10 * k, -0.24 * k), "rot": (16.0 * k, 0.0, 0.3 * heave)},
        "spine_01": {"rot": (10.0 * k + heave, 0.0, 0.0)}, "spine_02": {"rot": (10.0 * k - 0.5 * heave, 0.0, 0.0)},
        "spine_03": {"rot": (4.0 * k, 0.0, 0.0)}, "hump": {"rot": (6.0 * k + 1.5 * heave, 0.0, 0.0)},
        "neck_01": {"rot": (2.0 * k, 0.0, 0.0)}, "Head": {"rot": (-14.0 * k - heave, 0.0, 0.0)},
        "jaw": {"rot": (52.0 * k + abs(heave), 0.0, 0.0)}, "claw_r": {"rot": (-14.0 * k, 0.0, 0.0)},
    })
    side(pose, "upperarm", (-30.0 * k, -16.0 * k, 0.0))
    side(pose, "lowerarm", (-30.0 * k, 0.0, 0.0))
    side(pose, "hand", (-10.0 * k, 0.0, 0.0))
    return pose


def spew(t, rig):
    keys = [(0.0, base_pose(rig)), (0.22, _spew_draw(rig, 0.7)), (0.40, _spew_draw(rig)),
            (0.62, _spew_draw(rig, -0.4)), (SPEW_HIT, _spew_out(rig)),
            (0.98, _spew_out(rig, 7.0)), (1.12, _spew_out(rig, -5.0)), (1.26, _spew_out(rig, 6.0)),
            (1.38, _spew_out(rig, 0.0, 0.8)), (1.55, _spew_out(rig, 0.0, 0.35)), (SPEW_TIME, base_pose(rig))]
    return track(t, keys)


CLIPS = [("slam", slam, SLAM_TIME), ("roar", roar, ROAR_TIME), ("summon", summon, SUMMON_TIME),
         ("stun", stun, STUN_TIME), ("spew", spew, SPEW_TIME)]
