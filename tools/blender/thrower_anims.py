"""Taş fırlatan klipleri — elle anahtarlanmış, kodla yeniden üretilir (7.3).

İmza: dev sağ elle yerden kaya kavrar, gövdeyi sağa burup geriye gerilir, omuz üstünden fırlatır.
Poz çekirdeği, IK ve açı sözleşmesi walker_pose.py'de (iskelet uzayı, derece; X+ öne eğilme, Y+ sola yatma,
Z+ sola dönme). Kol hedefleri iskelet (dünya) uzayında bilek konumu olarak verilir (world_hands), IK ile
çözülüp dönüş olarak yazılır. Döngü klipleri `_Loop` ekiyle: Godot eki atar, adlar `idle`, `walk` olur.
Değerler kemik ve ağ ölçülerek bulundu (thrower_check.py: basan ayağın kayması, kavrama anında kayanın
yere değmesi, bırakış anında elin yüksekliği, ağın en alt noktası, IK sınırı) ve kare özetiyle yinelendi.

Oyun sözleşmesi (s73_design, GAME_PACE 0.8 sonrası):
  idle   : 2.0 sn döngü.
  walk   : 1.0 sn döngü, referans hız WALK_REF_SPEED = 1.84 m/sn (model ölçeği 1, boy ~1.8 m).
  throw  : 1.5 sn; kavrama 0.0–0.45 (el yerde 0.30), gerilme 0.45–0.9, BIRAKIŞ 0.9 sn (kare 27), toparlanma.
  swat   : 1.0 sn; dev kolla yatay savurma, VURUŞ 0.6 sn (kare 18; el gövdenin ~1 m önünden geçer).
  stagger: 0.33 sn. Ölüm ve doğma: thrower_falls.py.
"""
import math

from mathutils import Vector

import walker_pose as wp
from walker_pose import cyc, merge, track

TAU = math.tau

# --- yürüyüş ---------------------------------------------------------------------
WALK_REF_SPEED = 1.84
WALK_FRAMES = 30
WALK_CYCLE = WALK_FRAMES / wp.FPS
DUTY = 0.50               # basış payı (hızlı, uzun adım: çift destek kısa)
R_STANCE = (0.0, DUTY)
L_STANCE = (0.5, 0.5 + DUTY)
LIFT = 0.09
CROUCH = 0.11             # yürürken pelvis alçak (m): uzun adımda bacak yetişsin
LEAN = 12.0
SWAY = 0.035
ROLL_R = -5.0             # gövde dev kolun ağırlığıyla sağa yatık (Y-)
LIFTOFF_FOLLOW = 0.45


def _span(phi, rng):
    return ((phi - rng[0]) % 1.0) / (rng[1] - rng[0])


def _hermite(p0, p1, m0, m1, u):
    u2, u3 = u * u, u * u * u
    return (2 * u3 - 3 * u2 + 1) * p0 + (u3 - 2 * u2 + u) * m0 + (-2 * u3 + 3 * u2) * p1 + (u3 - u2) * m1


def _ease(u, keys):
    return track(u, [(k, {"v": {"x": val}}) for k, val in keys])["v"]["x"]


def foot_track(phi, rng):
    """Basışta ayak WALK_REF_SPEED ile geri kayar (dünyada durur); salınımda Hermite ile öne."""
    v = WALK_REF_SPEED * WALK_CYCLE
    dur = rng[1] - rng[0]
    reach = v * dur
    u = _span(phi, rng)
    if u <= 1.0:
        return -reach / 2 + reach * u, u, True
    w = (u - 1.0) * dur / (1.0 - dur)
    m = v * (1.0 - dur)
    return _hermite(reach / 2, -reach / 2, LIFTOFF_FOLLOW * m, m, w), w, False


def walk_feet(phi, rig):
    feet = {}
    for side, rng, dx in (("r", R_STANCE, -0.015), ("l", L_STANCE, 0.01)):
        y, u, down = foot_track(phi, rng)
        if down:
            pitch, lift = _ease(u, [(0.0, -9.0), (0.12, 0.0), (0.58, 0.0), (0.85, 12.0), (1.0, 28.0)]), 0.0
        else:
            pitch = _ease(u, [(0.0, 28.0), (0.35, 18.0), (0.75, -4.0), (1.0, -9.0)])
            lift = LIFT * rig.s * math.sin(math.pi * u) ** 1.3 * (1.0 - 0.2 * u)
        feet[side] = (y, pitch, lift, dx * rig.s)
    return feet["l"], feet["r"]


def walk(t, rig):
    """Sarsak, ağır sağ adım: sağ ayak basınca gövde daha derin çöker ve dev kola doğru yatar;
    dev kol geç kalan sarkaç gibi sallanır (el yere yakın, sürtmez), sıska kol göğse yakın titrer."""
    phi = (t / WALK_CYCLE) % 1.0
    s = rig.s
    dz = cyc(phi, [(0.05, -0.042), (0.27, 0.012), (0.55, -0.026), (0.77, 0.012)])
    sway = cyc(phi, [(0.0, -0.5), (0.22, -1.0), (0.5, 0.3), (0.72, 0.8)]) * SWAY
    roll = cyc(phi, [(0.06, -6.0), (0.3, -1.0), (0.56, 2.0), (0.8, -1.0)])
    yaw = cyc(phi, [(0.0, 7.0), (0.25, 0.0), (0.5, -7.0), (0.75, 0.0)])
    nod = cyc(phi - 0.1, [(0.05, 5.0), (0.27, -2.0), (0.55, 3.0), (0.77, -2.0)])
    l_foot, r_foot = walk_feet(phi, rig)
    pose = {
        "pelvis": {"loc": (sway * s, -0.02 * s, (dz - CROUCH) * s), "rot": (LEAN, ROLL_R * 0.4 + roll, yaw)},
        "spine_01": {"rot": (4.0, ROLL_R * 0.3 - 0.3 * roll, -0.6 * yaw)},
        "spine_02": {"rot": (3.0, ROLL_R * 0.3, -0.5 * yaw)},
        "spine_03": {"rot": (1.0, 0.0, -0.3 * yaw)},
        "neck_01": {"rot": (-10.0 - 0.5 * nod, 3.0, 0.0)},
        "Head": {"rot": (-6.0 + nod, 4.0 - 0.3 * roll, 0.4 * yaw)},
        "jaw": {"rot": (cyc(phi, [(0.0, 8.0), (0.3, 16.0), (0.5, 10.0), (0.8, 18.0)]), 0.0, 0.0)},
        "ik_l": {"foot": l_foot},
        "ik_r": {"foot": r_foot},
    }
    # dev kol: sol bacakla (karşı), gecikmeli büyük sarkaç; dirsek hafif kırık ki el yere sürtmesin
    big = cyc(phi - 0.18 + 0.5, [(0.0, -20.0), (0.5, 16.0)])
    pose["clavicle_r"] = {"rot": (0.0, 3.0 + 0.3 * roll, 0.0)}
    pose["upperarm_r"] = {"rot": (-LEAN - 4.0 + big, -5.0, 0.0)}
    pose["lowerarm_r"] = {"rot": (-16.0 + 0.6 * cyc(phi - 0.30 + 0.5, [(0.0, -14.0), (0.5, 10.0)]), 0.0, 0.0)}
    pose["hand_r"] = {"rot": (cyc(phi - 0.42 + 0.5, [(0.0, -12.0), (0.5, 12.0)]), 0.0, 0.0)}
    small = cyc(phi - 0.10, [(0.0, -8.0), (0.5, 10.0)])
    pose["upperarm_l"] = {"rot": (-LEAN + small, 6.0, 0.0)}
    pose["lowerarm_l"] = {"rot": (-30.0 + 0.5 * small, 0.0, 0.0)}
    pose["hand_l"] = {"rot": (cyc(phi * 2.0, [(0.0, -10.0), (0.5, 10.0)]), 0.0, 0.0)}
    return pose


def side(pose, base, rot_l, **extra):
    pose[base + "_l"] = {"rot": tuple(rot_l), **extra}
    pose[base + "_r"] = {"rot": (rot_l[0], -rot_l[1], -rot_l[2]), **extra}
    return pose


def stand(rig, crouch=0.02):
    return {"pelvis": {"loc": (0.0, 0.0, -crouch * rig.s), "rot": (3.0, -1.5, 0.0)},
            "ik_l": {"foot": (0.0, 0.0, 0.0, 0.0)}, "ik_r": {"foot": (0.0, 0.0, 0.0, 0.0)}}


IDLE_CYCLE = 2.0


def idle(t, rig):
    """Ağır nefes; dev kol sarkaç gibi hafif salınır (ağırlığı gövdeyi sağa çeker), sıska kol titrer."""
    phi = (t / IDLE_CYCLE) % 1.0
    w = TAU * phi
    breath = cyc(phi, [(0.0, 0.0), (0.38, 1.0), (0.52, 0.9), (0.82, 0.0)])
    pose = merge(stand(rig, 0.03 + 0.012 * breath), {
        "pelvis": {"loc": (-0.010 * rig.s * (1 + math.sin(w)), 0.0, -(0.03 + 0.012 * (1 - breath)) * rig.s),
                   "rot": (3.0, -2.5 + 1.5 * math.sin(w), 1.5 * math.sin(w))},
        "spine_01": {"rot": (1.0 - 1.5 * breath, -0.8 * math.sin(w), 0.0)},
        "spine_02": {"rot": (1.0 - 3.0 * breath, -1.0, -1.0 * math.sin(w))},
        "spine_03": {"rot": (-2.5 * breath, 0.0, 0.0)},
        "neck_01": {"rot": (-4.0 + 1.5 * breath, 2.0, 0.0)},
        "Head": {"rot": (-2.0 + 4.0 * breath, 3.0 * math.sin(w + 0.6), 5.0 * math.sin(w + 0.3))},
        "jaw": {"rot": (8.0 + 12.0 * (1.0 - breath), 0.0, 0.0)},
    })
    side(pose, "clavicle", (0.0, -4.0 * breath, 0.0))
    pose["upperarm_r"] = {"rot": (5.0 * math.sin(w + 1.0), -1.5 * math.sin(w), 0.0)}
    pose["lowerarm_r"] = {"rot": (-6.0 + 4.0 * math.sin(w + 0.4), 0.0, 0.0)}
    pose["hand_r"] = {"rot": (6.0 * math.sin(w - 0.3), 0.0, 0.0)}
    pose["upperarm_l"] = {"rot": (-4.0 + 2.0 * math.sin(w * 3.0), 4.0, 0.0)}
    pose["lowerarm_l"] = {"rot": (-24.0 + 4.0 * math.sin(w * 2.0 + 1.0), 0.0, 0.0)}
    pose["hand_l"] = {"rot": (10.0 * math.sin(w * 4.0), 0.0, 0.0)}
    return pose


# --- kol IK yardımcıları ----------------------------------------------------------------

def world_hands(rig, pose, targets, out=0.0):
    """Bilek hedefleri iskelet uzayında (dünya): göğüs çerçevesine çevrilir (solve_arms sözleşmesi).
    targets: {"r": (x, y, z), "l": ...} m, rig.s ile ölçekli verilir."""
    q03, h03 = wp._fk_chest(rig, pose)
    inv = q03.inverted()
    for sd, t in targets.items():
        rel = inv @ (Vector(t) * rig.s - h03) + rig.head["spine_03"] - rig.head["hand_" + sd]
        pose["arm_" + sd] = {"hand": tuple(rel), "out": out if sd == "r" else 0.1}
    return pose


def rest_arms(pose):
    pose["arm_l"] = {"hand": (0.0, 0.0, 0.0), "out": 0.0}
    pose["arm_r"] = {"hand": (0.0, 0.0, 0.0), "out": 0.0}
    return pose


def _body(rig, crouch, pel, sp1, sp2=(0, 0, 0), sp3=(0, 0, 0), head=(0, 0, 0), jaw=12.0, feet=None, loc=(0.0, 0.0)):
    """Gövde anahtarı: pelvis/omurga dönüşleri (derece), çömelme (m), ayak hedefleri."""
    s = rig.s
    pose = merge(stand(rig, crouch), {
        "pelvis": {"loc": (loc[0] * s, loc[1] * s, -crouch * s), "rot": pel},
        "spine_01": {"rot": sp1}, "spine_02": {"rot": sp2}, "spine_03": {"rot": sp3},
        "neck_01": {"rot": (-head[0] * 0.4, 0.0, head[2] * 0.3)}, "Head": {"rot": head},
        "jaw": {"rot": (jaw, 0.0, 0.0)}})
    for sd, f in (feet or {}).items():
        pose["ik_" + sd] = {"foot": (f[0] * s, f[1], f[2] * s, f[3] * s)}
    return pose


# --- fırlatma -----------------------------------------------------------------------------
GRAB_TIME = 0.30          # el yerde, kaya kavranır
RELEASE_TIME = 0.90       # = attack_windup; kare 27
THROW_TIME = 1.5
GRAB_WRIST = (-0.40, -0.40, 0.22)       # kavrama anında sağ bilek (m): kaya avuçta, tabanı yerde
COCK_WRIST = (-0.42, 0.42, 1.62)        # gerilme doruğu: kaya sağ omzun arkasında, yukarıda
RELEASE_WRIST = (-0.18, -0.52, 1.90)    # bırakış: el omuz üstünde önde, kol uzanmış


def _left_guard(rig, pose, forward):
    """Sıska kol: hedefi gösterir (forward 0..1) ya da göğse çekilir."""
    return world_hands(rig, pose, {"l": (0.24 - 0.04 * forward, -0.20 - 0.38 * forward, 1.18 + 0.20 * forward)})


def throw(t, rig):
    """0 duruş → 0.15 hazırlık → 0.30 KAVRAMA (dev el yerde) → 0.45 kaya göğüs önünde, doğrulur →
    0.72 gerilme doruğu (sağa burulmuş, geriye yatık, kaya omuz arkasında) → 0.82 en gergin →
    0.90 BIRAKIŞ (kol omuz üstünden önde uzanmış, sol ayak öne basmış) → 1.05 savrulma → 1.5 duruş."""
    lean_in = _body(rig, 0.06, (10.0, -3.0, -6.0), (6.0, -2.0, -4.0), (4.0, 0, 0), head=(-6.0, 0, 0), jaw=16.0)
    world_hands(rig, lean_in, {"r": (-0.40, -0.22, 0.62)}, out=0.1)
    _left_guard(rig, lean_in, 0.0)
    reach = _body(rig, 0.26, (32.0, -8.0, -12.0), (13.0, -5.0, -6.0), (7.0, 0, 0), head=(-22.0, 0, 4.0),
                  jaw=20.0, feet={"r": (-0.06, 0.0, 0.0, -0.03), "l": (0.08, 14.0, 0.0, 0.0)}, loc=(-0.03, -0.05))
    world_hands(rig, reach, {"r": (GRAB_WRIST[0], GRAB_WRIST[1], GRAB_WRIST[2] + 0.10)}, out=0.2)
    _left_guard(rig, reach, 0.0)
    grab = _body(rig, 0.34, (42.0, -10.0, -14.0), (16.0, -6.0, -6.0), (8.0, 0, 0), head=(-26.0, 0, 6.0),
                 jaw=22.0, feet={"r": (-0.08, 0.0, 0.0, -0.04), "l": (0.10, 18.0, 0.0, 0.0)}, loc=(-0.04, -0.06))
    world_hands(rig, grab, {"r": GRAB_WRIST}, out=0.2)
    _left_guard(rig, grab, 0.0)
    clutch = merge(grab, {"pelvis": {"loc": (-0.04 * rig.s, -0.06 * rig.s, -0.31 * rig.s)}})
    world_hands(rig, clutch, {"r": (GRAB_WRIST[0], GRAB_WRIST[1] + 0.03, GRAB_WRIST[2] + 0.07)}, out=0.25)
    haul = _body(rig, 0.16, (18.0, -4.0, -18.0), (6.0, 0.0, -8.0), (2.0, 0, -4.0), head=(-14.0, 0, 10.0),
                 jaw=18.0, feet={"r": (0.04, 0.0, 0.0, -0.02), "l": (0.04, 10.0, 0.0, 0.0)})
    world_hands(rig, haul, {"r": (-0.36, -0.30, 1.12)}, out=0.4)
    _left_guard(rig, haul, 0.3)
    cock = _body(rig, 0.10, (-4.0, 6.0, -26.0), (-8.0, 2.0, -12.0), (-6.0, 0, -6.0), head=(-12.0, -4.0, 30.0),
                 jaw=30.0, feet={"r": (0.16, 6.0, 0.0, -0.02), "l": (-0.10, -6.0, 0.03, 0.0)}, loc=(0.0, 0.05))
    world_hands(rig, cock, {"r": COCK_WRIST}, out=0.7)
    _left_guard(rig, cock, 1.0)
    taut = merge(cock, {"pelvis": {"rot": (-7.0, 7.0, -30.0)}, "spine_02": {"rot": (-11.0, 2.0, -14.0)},
                        "Head": {"rot": (-14.0, -4.0, 34.0)}})
    world_hands(rig, taut, {"r": (-0.40, 0.50, 1.68)}, out=0.75)
    _left_guard(rig, taut, 1.0)
    release = _body(rig, 0.12, (16.0, -2.0, 18.0), (10.0, -2.0, 10.0), (6.0, 0, 4.0), head=(-18.0, 0, -8.0),
                    jaw=34.0, feet={"r": (0.20, 22.0, 0.0, -0.02), "l": (-0.22, 0.0, 0.0, 0.0)}, loc=(0.0, -0.10))
    world_hands(rig, release, {"r": RELEASE_WRIST}, out=0.35)
    _left_guard(rig, release, 0.4)
    follow = _body(rig, 0.20, (30.0, -4.0, 26.0), (16.0, -2.0, 12.0), (8.0, 0, 4.0), head=(-10.0, 0, -10.0),
                   jaw=22.0, feet={"r": (0.20, 26.0, 0.0, -0.02), "l": (-0.22, 0.0, 0.0, 0.0)}, loc=(0.0, -0.12))
    world_hands(rig, follow, {"r": (0.08, -0.62, 0.80)}, out=0.2)
    _left_guard(rig, follow, 0.0)
    settle = _body(rig, 0.08, (10.0, -2.0, 6.0), (4.0, 0, 2.0), (2.0, 0, 0), head=(-6.0, 0, 0), jaw=14.0,
                   feet={"r": (0.08, 8.0, 0.0, 0.0), "l": (-0.06, 0.0, 0.0, 0.0)})
    world_hands(rig, settle, {"r": (-0.36, -0.20, 0.66)}, out=0.1)
    _left_guard(rig, settle, 0.0)
    end = rest_arms(stand(rig))
    return track(t, [(0.0, rest_arms(stand(rig))), (0.15, lean_in), (0.24, reach), (GRAB_TIME, grab), (0.37, clutch),
                     (0.50, haul), (0.72, cock), (0.82, taut), (RELEASE_TIME, release), (1.05, follow),
                     (1.28, settle), (THROW_TIME, end)])


# --- yakın vuruş -------------------------------------------------------------------------
SWAT_HIT = 0.60           # kare 18
SWAT_TIME = 1.0
SWAT_HIT_WRIST = (-0.05, -0.82, 1.02)   # vuruş: dev el gövdenin ~1 m önünden soldan geçer (yatay)


def swat(t, rig):
    """0 duruş → 0.32 kurulma (sağa burulur, dev kol geride-yanda) → 0.52 hızlanma →
    0.60 VURUŞ (el önde, yatay savrulur) → 0.74 savrulma (el sola geçer) → 1.0 duruş."""
    wind = _body(rig, 0.12, (6.0, -6.0, -26.0), (2.0, -4.0, -14.0), (0, 0, -6.0), head=(-10.0, 0, 26.0),
                 jaw=26.0, feet={"r": (0.10, 6.0, 0.0, -0.03), "l": (-0.06, 0.0, 0.0, 0.0)})
    world_hands(rig, wind, {"r": (-0.70, 0.30, 0.98)}, out=0.5)
    _left_guard(rig, wind, 0.6)
    whip = _body(rig, 0.14, (10.0, -4.0, -6.0), (4.0, -2.0, -2.0), (0, 0, 0), head=(-12.0, 0, 10.0), jaw=30.0,
                 feet={"r": (0.10, 6.0, 0.0, -0.03), "l": (-0.10, 0.0, 0.0, 0.0)}, loc=(0.0, -0.04))
    world_hands(rig, whip, {"r": (-0.62, -0.50, 1.00)}, out=0.4)
    _left_guard(rig, whip, 0.2)
    hit = _body(rig, 0.15, (14.0, -2.0, 20.0), (6.0, 0.0, 12.0), (2.0, 0, 6.0), head=(-14.0, 0, -6.0), jaw=32.0,
                feet={"r": (0.12, 14.0, 0.0, -0.03), "l": (-0.14, 0.0, 0.0, 0.0)}, loc=(0.0, -0.08))
    world_hands(rig, hit, {"r": SWAT_HIT_WRIST}, out=0.3)
    _left_guard(rig, hit, 0.0)
    past = _body(rig, 0.14, (16.0, -2.0, 32.0), (8.0, 0.0, 16.0), (2.0, 0, 8.0), head=(-8.0, 0, -12.0), jaw=22.0,
                 feet={"r": (0.12, 16.0, 0.0, -0.03), "l": (-0.14, 0.0, 0.0, 0.0)}, loc=(0.0, -0.08))
    world_hands(rig, past, {"r": (0.40, -0.52, 0.92)}, out=0.2)
    _left_guard(rig, past, 0.0)
    settle = _body(rig, 0.06, (6.0, -2.0, 8.0), (2.0, 0, 2.0), head=(-4.0, 0, 0), jaw=14.0,
                   feet={"r": (0.04, 4.0, 0.0, 0.0), "l": (-0.04, 0.0, 0.0, 0.0)})
    world_hands(rig, settle, {"r": (-0.30, -0.25, 0.70)}, out=0.1)
    _left_guard(rig, settle, 0.0)
    start = rest_arms(stand(rig))
    return track(t, [(0.0, start), (0.32, wind), (0.52, whip), (SWAT_HIT, hit), (0.74, past),
                     (0.86, settle), (SWAT_TIME, rest_arms(stand(rig)))])


# --- tepki ------------------------------------------------------------------------------
STAGGER_TIME = 0.33


def stagger(t, rig):
    """Küçük: göğse darbe, gövde ve kafa geri, dev kol gecikip sallanır; ayaklar yerinde."""
    hit = merge(stand(rig, 0.03), {
        "pelvis": {"loc": (0.0, 0.03 * rig.s, -0.03 * rig.s), "rot": (-4.0, 1.0, -3.0)},
        "spine_01": {"rot": (-6.0, 0.0, 0.0)}, "spine_02": {"rot": (-7.0, 2.0, 0.0)},
        "Head": {"rot": (-16.0, 6.0, 4.0)}, "jaw": {"rot": (22.0, 0.0, 0.0)},
        "upperarm_r": {"rot": (8.0, 4.0, 0.0)}, "upperarm_l": {"rot": (-14.0, -10.0, 0.0)},
        "lowerarm_l": {"rot": (-30.0, 0.0, 0.0)}})
    swing = merge(stand(rig, 0.03), {"spine_01": {"rot": (3.0, 0.0, 0.0)}, "Head": {"rot": (4.0, -2.0, 0.0)},
                                     "upperarm_r": {"rot": (-8.0, -3.0, 0.0)}})
    return track(t, [(0.0, stand(rig)), (0.07, hit), (0.19, swing), (STAGGER_TIME, stand(rig))])


CLIPS = [("idle_Loop", idle, IDLE_CYCLE), ("walk_Loop", walk, WALK_CYCLE), ("throw", throw, THROW_TIME),
         ("swat", swat, SWAT_TIME), ("stagger", stagger, STAGGER_TIME)]


def mesh_height(arm):
    import bpy
    for obj in bpy.data.objects:
        if obj.type == "MESH" and any(m.type == "ARMATURE" and m.object == arm for m in obj.modifiers):
            mw = arm.matrix_world.inverted() @ obj.matrix_world
            return max((mw @ v.co).z for v in obj.data.vertices)
    return 0.0


def build_all(arm) -> list:
    import importlib
    import bpy
    import thrower_falls
    importlib.reload(thrower_falls)
    bpy.context.scene.render.fps = wp.FPS
    bpy.context.scene.render.fps_base = 1.0
    if arm.animation_data is None:
        arm.animation_data_create()
    rig = wp.Rig(arm)
    names = []
    for name, fn, length in CLIPS + thrower_falls.CLIPS:
        wp.build_clip(rig, name, fn, length)
        names.append(name)
    arm.animation_data.action = bpy.data.actions[CLIPS[0][0]]
    print("THROWER ANIMS", names, "IK clamped frames:", rig.clamped, "rig.s %.3f" % rig.s)
    return names
