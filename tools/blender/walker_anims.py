"""Yürüyen klipleri — elle anahtarlanmış, kodla yeniden üretilir (Aşama V.5).

İmza: sendeleyerek yürür, kollarını uzatıp kucaklar gibi saldırır. Dinlenme pozu konseptin duruşu
(ağırlık sağda, sol omuz düşük, sol ayak geride topuk kalkık, kollar yarı kalkık öne).
Poz çekirdeği, IK ve sözleşme walker_pose.py'de. Döngü klipleri `_Loop` ekiyle (Godot eki atıp döngü yapar).

Değerler Blender MCP içinde kemik konumları ölçülerek bulundu (basan ayağın hızı, topuk yerde mi, el ile
kök arası, ağın en alt noktası) ve `look` görüntüsüyle yinelendi. Mesafeler bacak boyuyla ölçeklenir
(rig.s), açılar çeşitten bağımsızdır.

Oyun sözleşmesi (EnemyData walker satırı, 2026-11-19):
  attack_windup 0.5 sn  -> windup klibi 0.5 sn; attack klibinin ilk 0.5 sn'si aynı hazırlık.
  attack_anim_hit_time 0.7 -> attack klibinde kollar 0.7 sn'de kapanır, çene 0.7 sn'de kapanır (vuruş karesi 21).
  attack_recover 0.6    -> attack klibi vuruştan sonra 0.6 sn toparlanır (toplam 1.3 sn).
  stagger_time 0.22, spawn_time 0.9 -> play_timed klip uzunluğunu süreye uydurur.
"""
import math

from mathutils import Vector

import walker_pose as wp
from walker_pose import blend, cyc, merge, smooth, track

TAU = math.tau

# --- yürüyüş ---------------------------------------------------------------------
WALK_CYCLE = 1.1          # sn, iki adım (sağ taşır, sol sürünür)
WALK_SPEED = 0.75         # m/sn (Office ölçeğinde; rig.s ile ölçeklenir): basan ayağın geri kayma hızı
R_STANCE = 0.62           # sağ ayağın yerde kaldığı evre payı
L_DRAG = (0.05, 0.55)     # sol ayağın süründüğü evre aralığı (gerisi basış)
R_CENTER = -0.06          # sağ parmak ekleminin basış ortası (iskelet Y, m)
L_CENTER = 0.03
R_LIFT = 0.07             # sağ ayağın salınımda kalkışı (m)
L_SCRAPE = 0.010          # sol ayak sürünürken en çok bu kadar kalkar
CROUCH = 0.015            # pelvis yürürken bu kadar alçak (dizler bükük)


def walk_feet(phi: float, rig) -> tuple:
    s = rig.s
    v = WALK_SPEED * s * WALK_CYCLE        # bir döngüde kat edilen yol
    r_range = v * R_STANCE
    if phi < R_STANCE:
        ry, rl = R_CENTER * s - r_range / 2 + v * phi, 0.0
    else:
        u = (phi - R_STANCE) / (1.0 - R_STANCE)
        ry, rl = R_CENTER * s + r_range / 2 - r_range * smooth(u), R_LIFT * s * math.sin(math.pi * u) ** 1.3
    r_pitch = cyc(phi, [(0.0, -14), (0.08, 0), (0.42, 2), (0.62, 34), (0.8, 6), (0.95, -16)])
    d0, d1 = L_DRAG
    l_range = v * (1.0 - (d1 - d0))
    if d0 <= phi < d1:
        u = (phi - d0) / (d1 - d0)
        ly = L_CENTER * s + l_range / 2 - l_range * smooth(u)
        ll = L_SCRAPE * s * math.sin(math.pi * u) ** 2
        ldx = -0.02 * s * math.sin(math.pi * u)
    else:
        psi = (phi - d1) % 1.0
        ly, ll, ldx = L_CENTER * s - l_range / 2 + v * psi, 0.0, 0.0
    l_pitch = cyc(phi, [(0.05, 40), (0.3, 46), (0.55, 30), (0.7, 18), (0.85, 20), (0.98, 34)])
    r_foot = (ry - rig.legs["r"]["ball0"].y, r_pitch, rl, -0.015 * s)
    l_foot = (ly - rig.legs["l"]["ball0"].y, l_pitch, ll, 0.015 * s + ldx)
    return l_foot, r_foot


def walk(t: float, rig) -> dict:
    phi = (t / WALK_CYCLE) % 1.0
    s = rig.s
    dz = cyc(phi, [(0.0, -0.025), (0.12, -0.035), (0.32, 0.012), (0.55, -0.01), (0.72, -0.05), (0.9, -0.005)])
    sway = cyc(phi, [(0.0, -0.01), (0.3, -0.045), (0.55, 0.0), (0.75, 0.055), (0.95, 0.015)])
    roll = cyc(phi, [(0.0, 0.0), (0.3, -4.0), (0.75, 6.0), (0.95, 2.0)])
    yaw = cyc(phi, [(0.0, 6.0), (0.31, 0.0), (0.62, -6.0), (0.81, 0.0)])
    lurch = cyc(phi - 0.08, [(0.1, 2.0), (0.45, -3.0), (0.8, 10.0)])      # gövde düşük omuza yalpalar
    nod = cyc(phi - 0.05, [(0.1, 6.0), (0.35, -2.0), (0.8, 8.0), (0.95, 0.0)])
    flop = cyc(phi - 0.12, [(0.15, -6.0), (0.6, 1.0), (0.9, 10.0)])
    l_foot, r_foot = walk_feet(phi, rig)
    pose = {
        "pelvis": {"loc": (sway * s, 0.0, (dz - CROUCH) * s), "rot": (5.0, roll, yaw)},
        "spine_01": {"rot": (7.0, -0.5 * roll, -0.6 * cyc(phi - 0.06, [(0.0, 6.0), (0.31, 0.0), (0.62, -6.0), (0.81, 0.0)]))},
        "spine_02": {"rot": (5.0, lurch, -0.3 * yaw)},
        "spine_03": {"rot": (2.0, 0.6 * lurch, 0.0)},
        "neck_01": {"rot": (-0.4 * nod, 0.3 * flop, 0.0)},
        "Head": {"rot": (nod, flop, 2.0 * math.sin(TAU * phi))},
        "jaw": {"rot": (cyc(phi - 0.1, [(0.1, 6.0), (0.4, 1.0), (0.8, 9.0), (0.95, 3.0)]), 0.0, 0.0)},
        "ik_l": {"foot": l_foot},
        "ik_r": {"foot": r_foot},
    }
    # kollar yarı kalkık; bacakların tersine, gecikmeli ve gevşek salınır
    for side, ph, sy in (("l", 0.0, 1.0), ("r", 0.5, -1.0)):
        sw = cyc(phi - 0.15 + ph, [(0.0, -7.0), (0.35, 3.0), (0.6, 8.0), (0.9, -6.0)])
        pose["clavicle_" + side] = {"rot": (0.0, -sy * 0.4 * lurch, 0.0)}
        pose["upperarm_" + side] = {"rot": (sw, 0.0, 0.0)}
        pose["lowerarm_" + side] = {"rot": (0.6 * cyc(phi - 0.3 + ph, [(0.0, -7.0), (0.35, 3.0), (0.6, 8.0), (0.9, -6.0)]), 0.0, 0.0)}
        pose["hand_" + side] = {"rot": (cyc(phi - 0.4 + ph, [(0.0, -8.0), (0.5, 8.0)]), 0.0, 0.0)}
    return pose


def side(pose: dict, base: str, rot_l, **extra) -> dict:
    """Sol kemiğe rot_l, sağa aynası (Y ve Z ters)."""
    pose[base + "_l"] = {"rot": tuple(rot_l), **extra}
    pose[base + "_r"] = {"rot": (rot_l[0], -rot_l[1], -rot_l[2]), **extra}
    return pose


def stand(rig, crouch: float = 0.02) -> dict:
    """Bekleme duruşu: dinlenme pozu, biraz çökük; ayaklar dinlenmedeki yerinde (sol topuk kalkık)."""
    return {
        "pelvis": {"loc": (0.0, 0.0, -crouch * rig.s), "rot": (3.0, 0.0, 0.0)},
        "spine_01": {"rot": (3.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.0, rig.legs["l"]["rest_pitch"], 0.0, 0.0)},
        "ik_r": {"foot": (0.0, 0.0, 0.0, 0.0)},
    }


IDLE_CYCLE = 2.4


def idle(t: float, rig) -> dict:
    """Ağırlığını iki yana aktaran sarsak bekleme; kafa sarkar, çene ağır ağır oynar."""
    phi = (t / IDLE_CYCLE) % 1.0
    s = rig.s
    w = TAU * phi
    shift = cyc(phi, [(0.0, -0.02), (0.25, -0.03), (0.55, 0.03), (0.8, 0.025)])
    pose = merge(stand(rig, 0.02 + 0.008 * (1 - math.cos(2 * w))), {
        "pelvis": {"loc": (shift * s, 0.0, -(0.02 + 0.008 * (1 - math.cos(2 * w))) * s),
                   "rot": (3.0, 60 * shift, 4 * math.sin(w))},
        "spine_02": {"rot": (2 + 1.5 * math.sin(2 * w), -100 * shift, -3 * math.sin(w))},
        "spine_03": {"rot": (1 + math.sin(2 * w + 0.4), -40 * shift, 0.0)},
        "neck_01": {"rot": (2 * math.sin(w + 0.8), 0.0, 0.0)},
        "Head": {"rot": (4 + 4 * math.sin(w + 1.2), cyc(phi - 0.1, [(0.0, -5.0), (0.3, -8.0), (0.6, 7.0), (0.85, 4.0)]),
                         6 * math.sin(w + 0.5))},
        "jaw": {"rot": (cyc(phi, [(0.0, 2.0), (0.2, 9.0), (0.45, 1.0), (0.7, 6.0), (0.85, 0.0)]), 0.0, 0.0)},
    })
    for sd, ph in (("l", 0.0), ("r", 1.3)):
        pose["upperarm_" + sd] = {"rot": (4 * math.sin(w + ph), 0.0, 0.0)}
        pose["lowerarm_" + sd] = {"rot": (5 * math.sin(w + ph - 0.6), 0.0, 0.0)}
        pose["hand_" + sd] = {"rot": (8 * math.sin(w + ph - 1.2), 0.0, 0.0)}
    return pose


# --- kucaklama saldırısı ------------------------------------------------------------
WINDUP_TIME = 0.5         # = EnemyData attack_windup
HIT_TIME = 0.7            # = attack_anim_hit_time (vuruş karesi 21)
ATTACK_TIME = 1.3         # vuruş + attack_recover 0.6


def hands(rig, pose: dict, rel_l, rel_r=None, out: float = 0.0) -> dict:
    """Bilek hedefleri omuza göre (sol için; sağ X aynası), göğüs çerçevesinde, bacak boyuyla ölçekli."""
    for side, sx, rel in (("l", 1.0, rel_l), ("r", -1.0, rel_r or rel_l)):
        target = rig.head["upperarm_" + side] + Vector((sx * rel[0], rel[1], rel[2])) * rig.s
        pose["arm_" + side] = {"hand": tuple(target - rig.head["hand_" + side]), "out": out}
    return pose


def rest_arms(pose: dict) -> dict:
    """Kollar dinlenmedeki yerinde (IK hedefi sıfır kayma); IK'lı pozlarla aradeğerlenebilsin."""
    pose["arm_l"] = {"hand": (0.0, 0.0, 0.0), "out": 0.0}
    pose["arm_r"] = {"hand": (0.0, 0.0, 0.0), "out": 0.0}
    return pose


def _open_pose(rig) -> dict:
    """Hazırlığın doruğu: kollar iki yana açılıp kalkmış, gövde geriye gerilmiş, çene açık."""
    s = rig.s
    pose = merge(stand(rig, 0.05), {
        "pelvis": {"loc": (0.0, 0.04 * s, -0.05 * s), "rot": (-4.0, 0.0, 0.0)},
        "spine_01": {"rot": (-5.0, 0.0, 0.0)},
        "spine_02": {"rot": (-7.0, 0.0, 0.0)},
        "spine_03": {"rot": (-4.0, 0.0, 0.0)},
        "neck_01": {"rot": (-6.0, 0.0, 0.0)},
        "Head": {"rot": (-14.0, 0.0, 0.0)},
        "jaw": {"rot": (26.0, 0.0, 0.0)},
    })
    side(pose, "clavicle", (0.0, -8.0, 0.0))
    side(pose, "hand", (-20.0, 0.0, 0.0))
    return hands(rig, pose, (0.40, -0.20, 0.06), out=0.3)


def windup(t: float, rig) -> dict:
    dip = merge(stand(rig, 0.04), {"spine_01": {"rot": (8.0, 0.0, 0.0)}, "spine_02": {"rot": (4.0, 0.0, 0.0)},
                                   "Head": {"rot": (8.0, 0.0, 0.0)}, "jaw": {"rot": (6.0, 0.0, 0.0)}})
    hands(rig, dip, (0.10, -0.22, -0.30))
    shake = merge(_open_pose(rig), {"Head": {"rot": (-16.0, 3.0, 0.0)}, "jaw": {"rot": (30.0, 0.0, 0.0)}})
    hands(rig, shake, (0.43, -0.16, 0.09), out=0.3)
    base = rest_arms(stand(rig))
    return track(t, [(0.0, base), (0.12, dip), (0.4, _open_pose(rig)), (WINDUP_TIME, shake)])


def _hug_pose(rig, squeeze: float) -> dict:
    """Vuruş: öne atılmış, kollar içe kapanmış, gövde ve kafa öne düşmüş, çene kapalı."""
    s = rig.s
    pose = merge(stand(rig, 0.08), {
        "pelvis": {"loc": (0.0, -0.12 * s, -0.08 * s), "rot": (8.0, 0.0, 0.0)},
        "spine_01": {"rot": (6.0 + 2 * squeeze, 0.0, 0.0)},
        "spine_02": {"rot": (5.0 + 2 * squeeze, 0.0, 0.0)},
        "neck_01": {"rot": (2.0, 0.0, 0.0)},
        "Head": {"rot": (4.0 + 5 * squeeze, 0.0, 0.0)},
        "jaw": {"rot": (-3.0 + 2 * squeeze, 0.0, 0.0)},
        "ik_r": {"foot": (-0.14 * s, 0.0, 0.0, 0.0)},
    })
    side(pose, "clavicle", (0.0, 6.0, -8.0))
    side(pose, "hand", (0.0, 0.0, -20.0))
    return hands(rig, pose, (-0.10 - 0.03 * squeeze, -0.42, 0.0), out=0.4)


def attack(t: float, rig) -> dict:
    """0–0.5 hazırlık (windup ile aynı), 0.5–0.7 atılış, 0.7 vuruş, 0.7–1.3 toparlanma."""
    if t <= WINDUP_TIME:
        return windup(t, rig)
    s = rig.s
    lunge = merge(blend(_open_pose(rig), _hug_pose(rig, 0.0), 0.45), {
        "jaw": {"rot": (34.0, 0.0, 0.0)},
        "ik_r": {"foot": (-0.10 * s, 8.0, 0.05 * s, 0.0)},
    })
    hands(rig, lunge, (0.24, -0.40, 0.02), out=0.4)
    back = merge(blend(_hug_pose(rig, 0.0), stand(rig), 0.55), {"jaw": {"rot": (10.0, 0.0, 0.0)},
                                                                "ik_r": {"foot": (-0.06 * s, 0.0, 0.03 * s, 0.0)}})
    hands(rig, back, (0.02, -0.33, -0.18), out=0.2)
    end = rest_arms(stand(rig))
    return track(t, [(WINDUP_TIME, windup(WINDUP_TIME, rig)), (0.62, lunge), (HIT_TIME, _hug_pose(rig, 1.0)),
                     (0.84, _hug_pose(rig, 0.4)), (1.05, back), (ATTACK_TIME, end)])


# --- tepkiler ---------------------------------------------------------------------
STAGGER_TIME = 0.4


def stagger(t: float, rig) -> dict:
    s = rig.s
    hit = merge(stand(rig, 0.04), {
        "pelvis": {"loc": (0.0, 0.06 * s, -0.04 * s), "rot": (-6.0, 3.0, -6.0)},
        "spine_01": {"rot": (-12.0, 0.0, 0.0)}, "spine_02": {"rot": (-10.0, 4.0, 0.0)},
        "neck_01": {"rot": (-8.0, 0.0, 0.0)}, "Head": {"rot": (-24.0, 10.0, 6.0)},
        "jaw": {"rot": (22.0, 0.0, 0.0)},
    })
    side(hit, "upperarm", (-22.0, -22.0, 0.0))
    side(hit, "lowerarm", (-16.0, 0.0, 0.0))
    side(hit, "hand", (-20.0, 0.0, 0.0))
    settle = merge(stand(rig, 0.03), {"spine_01": {"rot": (7.0, 0.0, 0.0)}, "Head": {"rot": (8.0, -3.0, 0.0)},
                                      "jaw": {"rot": (6.0, 0.0, 0.0)}})
    return track(t, [(0.0, stand(rig)), (0.07, hit), (0.22, settle), (STAGGER_TIME, stand(rig))])


#DEATHS_PLACEHOLDER

CLIPS = [("idle_Loop", idle, IDLE_CYCLE), ("walk_Loop", walk, WALK_CYCLE), ("windup", windup, WINDUP_TIME),
         ("attack", attack, ATTACK_TIME), ("stagger", stagger, STAGGER_TIME)]


def build_all(arm) -> list:
    import bpy
    bpy.context.scene.render.fps = wp.FPS
    bpy.context.scene.render.fps_base = 1.0
    if arm.animation_data is None:
        arm.animation_data_create()
    import importlib
    import walker_falls
    importlib.reload(walker_falls)
    rig = wp.Rig(arm)
    names = []
    for name, fn, length in CLIPS + walker_falls.CLIPS:
        wp.build_clip(rig, name, fn, length)
        names.append(name)
    arm.animation_data.action = bpy.data.actions[CLIPS[0][0]]
    print("WALKER ANIMS", names, "IK clamped frames:", rig.clamped)
    return names
