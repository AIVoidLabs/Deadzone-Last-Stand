"""Tank klipleri — elle anahtarlanmış, kodla yeniden üretilir (Aşama V.5).

İmza: iki yumruğunu başının üstünde kenetler, gövdesini geriye gerer, yere çekiç gibi vurur.
Poz çekirdeği, IK ve açı sözleşmesi walker_pose.py'de (iskelet uzayı, derece; X+ öne eğilme,
Y+ sola yatma, Z+ sola dönme). Döngü klipleri `_Loop` ekiyle: Godot eki atar, adlar `idle`, `walk` olur.
Değerler kemik ve ağ ölçülerek bulundu (tank_check.py: basan ayağın kayması, yumruğun vuruş anındaki
yüksekliği, ağın en alt noktası, IK sınırı) ve kare özetiyle yinelendi.

Oyun sözleşmesi (GAME_PACE 0.8 sonrası):
  walk     : referans hız WALK_REF_SPEED = 1.2 m/sn (model ölçeği 1; oyun gerçek hız / ref ile oynatır).
  attack   : 1.6 sn; 0.0–0.9 hazırlık (kenetle → geril → indir), VURUŞ 0.9 sn (yumruklar yerde,
             gövde önünde), 0.9–1.6 toparlanma. Erişim 1.5 m: yumruklar kökün ~0.75 m önüne iner.
  stagger  : küçük (0.35 sn). Ölüm ve doğma: tank_falls.py.
"""
import math

from mathutils import Vector

import walker_pose as wp
from walker_pose import cyc, merge, track

TAU = math.tau

# --- yürüyüş ---------------------------------------------------------------------
WALK_REF_SPEED = 1.2      # m/sn, model ölçeğinde
WALK_FRAMES = 29          # iki adım (0.967 sn); kısa bacak + 1.2 m/sn → sık ama ağır adım
WALK_CYCLE = WALK_FRAMES / wp.FPS
DUTY = 0.60               # basış payı (ağır: çift destek uzun)
R_STANCE = (0.0, DUTY)
L_STANCE = (0.5, 0.5 + DUTY)
LIFT = 0.075              # salınımda ayak kalkışı (m, rig.s ile)
CROUCH = 0.05             # yürürken pelvis alçak (m)
LEAN = 9.0                # pelvis öne eğimi (derece)
SWAY = 0.045              # yana yük aktarma (m): geniş, ağır
LIFTOFF_FOLLOW = 0.45


def _span(phi, rng):
    return ((phi - rng[0]) % 1.0) / (rng[1] - rng[0])


def _hermite(p0, p1, m0, m1, u):
    u2, u3 = u * u, u * u * u
    return (2 * u3 - 3 * u2 + 1) * p0 + (u3 - 2 * u2 + u) * m0 + (-2 * u3 + 3 * u2) * p1 + (u3 - u2) * m1


def _ease(u, keys):
    return track(u, [(k, {"v": {"x": val}}) for k, val in keys])["v"]["x"]


def foot_track(phi, rng):
    """Basışta ayak WALK_REF_SPEED ile geri kayar (dünyada durur); salınımda Hermite ile öne. (y, u, yerde)"""
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
    for side, rng, dx in (("r", R_STANCE, -0.01), ("l", L_STANCE, 0.01)):
        y, u, down = foot_track(phi, rng)
        if down:     # topuk vurur, taban iner, topuk kalkıp parmaktan iter
            pitch, lift = _ease(u, [(0.0, -7.0), (0.12, 0.0), (0.62, 0.0), (0.88, 10.0), (1.0, 24.0)]), 0.0
        else:
            pitch = _ease(u, [(0.0, 24.0), (0.35, 16.0), (0.75, -3.0), (1.0, -7.0)])
            lift = LIFT * rig.s * math.sin(math.pi * u) ** 1.3 * (1.0 - 0.2 * u)
        feet[side] = (y, pitch, lift, dx * rig.s)
    return feet["l"], feet["r"]


def walk(t, rig):
    phi = (t / WALK_CYCLE) % 1.0
    s = rig.s
    # basış 0 (sağ) ve 0.5 (sol): ayak vurunca gövde çöker, ortada kalkar; ağırlık basan ayağa kayar
    dz = cyc(phi, [(0.04, -0.032), (0.25, 0.010), (0.54, -0.032), (0.75, 0.010)])
    sway = cyc(phi, [(0.0, -0.4), (0.22, -1.0), (0.5, 0.4), (0.72, 1.0)]) * SWAY
    roll = cyc(phi, [(0.05, -5.0), (0.3, 0.0), (0.55, 5.0), (0.8, 0.0)])
    yaw = cyc(phi, [(0.0, 6.0), (0.25, 0.0), (0.5, -6.0), (0.75, 0.0)])
    shrug = cyc(phi - 0.08, [(0.0, 7.0), (0.25, -2.0), (0.5, -7.0), (0.75, 2.0)])     # omuzlar sallanır
    nod = cyc(phi - 0.1, [(0.04, 4.0), (0.25, -2.0), (0.54, 4.0), (0.75, -2.0)])
    l_foot, r_foot = walk_feet(phi, rig)
    pose = {
        "pelvis": {"loc": (sway * s, 0.0, (dz - CROUCH) * s), "rot": (LEAN, roll, yaw)},
        "spine_01": {"rot": (3.0, -0.4 * roll, -0.6 * yaw)},
        "spine_02": {"rot": (2.0, shrug, -0.6 * yaw)},
        "spine_03": {"rot": (1.0, 0.5 * shrug, -0.3 * yaw)},
        "neck_01": {"rot": (-6.0 - 0.5 * nod, -0.4 * shrug, 0.0)},
        "Head": {"rot": (-4.0 + nod, -0.5 * shrug, 0.4 * yaw)},
        "jaw": {"rot": (cyc(phi, [(0.0, 10.0), (0.3, 5.0), (0.5, 12.0), (0.8, 5.0)]), 0.0, 0.0)},
        "ik_l": {"foot": l_foot},
        "ik_r": {"foot": r_foot},
    }
    for side, ph, sy in (("l", 0.5, 1.0), ("r", 0.0, -1.0)):     # kol karşı bacakla, gecikmeli ve ağır
        sw = cyc(phi - 0.12 + ph, [(0.0, -12.0), (0.5, 12.0)])
        pose["clavicle_" + side] = {"rot": (0.0, -sy * 0.5 * shrug, 0.0)}
        pose["upperarm_" + side] = {"rot": (-LEAN - 5.0 + sw, sy * 4.0, 0.0)}
        pose["lowerarm_" + side] = {"rot": (0.7 * cyc(phi - 0.25 + ph, [(0.0, -10.0), (0.5, 12.0)]), 0.0, 0.0)}
        pose["hand_" + side] = {"rot": (cyc(phi - 0.35 + ph, [(0.0, -8.0), (0.5, 8.0)]), 0.0, 0.0)}
    return pose


def side(pose, base, rot_l, **extra):
    pose[base + "_l"] = {"rot": tuple(rot_l), **extra}
    pose[base + "_r"] = {"rot": (rot_l[0], -rot_l[1], -rot_l[2]), **extra}
    return pose


def stand(rig, crouch=0.02):
    return {"pelvis": {"loc": (0.0, 0.0, -crouch * rig.s), "rot": (2.0, 0.0, 0.0)},
            "ik_l": {"foot": (0.0, 0.0, 0.0, 0.0)}, "ik_r": {"foot": (0.0, 0.0, 0.0, 0.0)}}


IDLE_CYCLE = 2.4


def idle(t, rig):
    """Ağır nefes: göğüs ve omuzlar kalkar (nefes al), çene açılıp sarkar (ver); kollar ağır sallanır."""
    phi = (t / IDLE_CYCLE) % 1.0
    w = TAU * phi
    breath = cyc(phi, [(0.0, 0.0), (0.35, 1.0), (0.5, 0.9), (0.8, 0.0)])
    pose = merge(stand(rig, 0.02 + 0.012 * breath), {
        "pelvis": {"loc": (0.008 * rig.s * math.sin(w), 0.0, -(0.02 + 0.012 * (1 - breath)) * rig.s),
                   "rot": (2.0, 1.2 * math.sin(w), 1.5 * math.sin(w))},
        "spine_01": {"rot": (1.0 - 1.5 * breath, -0.6 * math.sin(w), 0.0)},
        "spine_02": {"rot": (1.0 - 3.0 * breath, 0.0, -1.0 * math.sin(w))},
        "spine_03": {"rot": (-2.5 * breath, 0.0, 0.0)},
        "neck_01": {"rot": (1.5 * breath, 0.0, 0.0)},
        "Head": {"rot": (-3.0 + 4.0 * breath, 2.0 * math.sin(w + 0.6), 4.0 * math.sin(w + 0.3))},
        "jaw": {"rot": (6.0 + 12.0 * (1.0 - breath), 0.0, 0.0)},
    })
    side(pose, "clavicle", (0.0, -5.0 * breath, 0.0))
    for sd, ph in (("l", 0.0), ("r", 1.1)):
        pose["upperarm_" + sd] = {"rot": (3.0 * math.sin(w + ph), 0.0, 0.0)}
        pose["lowerarm_" + sd] = {"rot": (4.0 * math.sin(w + ph - 0.6), 0.0, 0.0)}
        pose["hand_" + sd] = {"rot": (6.0 * math.sin(w + ph - 1.2), 0.0, 0.0)}
    return pose


# --- çekiç vuruşu ----------------------------------------------------------------------
HIT_TIME = 0.9            # = attack_windup (EnemyData), vuruş karesi 27
ATTACK_TIME = 1.6
CLASP_GAP = 0.085         # kenetli yumruklar: bilekler arası yarı aralık (m, rig.s ile)
SLAM_Y = -0.62            # vuruş anında bileklerin ileri yeri (m, rig.s ile; yumruk ~0.75 m önde)
SLAM_Z = 0.125            # vuruş anında bilek yüksekliği (m, rig.s ile; yumruk yere değer)


def world_hands(rig, pose, target_l, target_r, out=0.0):
    """Bilek hedefleri iskelet uzayında (dünya): göğüs çerçevesine çevrilir (solve_arms sözleşmesi)."""
    q03, h03 = wp._fk_chest(rig, pose)
    inv = q03.inverted()
    for sd, t in (("l", target_l), ("r", target_r)):
        rel = inv @ (Vector(t) - h03) + rig.head["spine_03"] - rig.head["hand_" + sd]
        pose["arm_" + sd] = {"hand": tuple(rel), "out": out}
    return pose


def rest_arms(pose):
    pose["arm_l"] = {"hand": (0.0, 0.0, 0.0), "out": 0.0}
    pose["arm_r"] = {"hand": (0.0, 0.0, 0.0), "out": 0.0}
    return pose


def _clasp(rig, pose, up, back):
    """Bilekler başın üstünde: omuz hizasından `up` yukarı, `back` geride; yumruklar ortada buluşur."""
    sh = rig.head["upperarm_l"]
    g = CLASP_GAP * rig.s
    return world_hands(rig, pose, (g, sh.y + back * rig.s, sh.z + up * rig.s),
                       (-g, sh.y + back * rig.s, sh.z + up * rig.s), out=0.15)


def _raise(rig):
    """Kollar kalkarken: yumruklar göğüs önünde buluşur, gövde hafif çöker (güç toplar)."""
    pose = merge(stand(rig, 0.05), {"spine_01": {"rot": (4.0, 0.0, 0.0)}, "spine_02": {"rot": (3.0, 0.0, 0.0)},
                                    "Head": {"rot": (4.0, 0.0, 0.0)}, "jaw": {"rot": (14.0, 0.0, 0.0)}})
    sh = rig.head["upperarm_l"]
    g = CLASP_GAP * rig.s
    return world_hands(rig, pose, (g, sh.y - 0.45 * rig.s, sh.z - 0.15 * rig.s),
                       (-g, sh.y - 0.45 * rig.s, sh.z - 0.15 * rig.s), out=0.2)


def _arch(rig, extra=0.0):
    """Doruk: yumruklar başın üstünde kenetli, gövde geriye gerilmiş, kafa yukarı, ağız açık kükrer."""
    s = rig.s
    pose = merge(stand(rig, 0.04), {
        "pelvis": {"loc": (0.0, 0.05 * s, -0.04 * s), "rot": (-6.0 - extra, 0.0, 0.0)},
        "spine_01": {"rot": (-8.0 - extra, 0.0, 0.0)},
        "spine_02": {"rot": (-10.0 - extra, 0.0, 0.0)},
        "spine_03": {"rot": (-6.0, 0.0, 0.0)},
        "neck_01": {"rot": (-8.0, 0.0, 0.0)}, "Head": {"rot": (-14.0, 0.0, 0.0)},
        "jaw": {"rot": (32.0, 0.0, 0.0)},
        "ik_r": {"foot": (0.10 * s, 6.0, 0.0, 0.0)},
    })
    return _clasp(rig, pose, 0.62, 0.30 + 0.004 * extra)


def _slam(rig, squash=0.0):
    """Vuruş: gövde öne katlanmış, dizler kırık, kenetli yumruklar önde yerde; sol ayak öne basmış."""
    s = rig.s
    pose = merge(stand(rig, 0.30 + 0.01 * squash), {
        "pelvis": {"loc": (0.0, -0.10 * s, -(0.30 + 0.01 * squash) * s), "rot": (34.0 + 1 * squash, 0.0, 0.0)},
        "spine_01": {"rot": (20.0 + 2 * squash, 0.0, 0.0)},
        "spine_02": {"rot": (12.0 + 2 * squash, 0.0, 0.0)},
        "spine_03": {"rot": (6.0, 0.0, 0.0)},
        "neck_01": {"rot": (-18.0, 0.0, 0.0)}, "Head": {"rot": (-16.0, 0.0, 0.0)},
        "jaw": {"rot": (8.0, 0.0, 0.0)},
        "ik_l": {"foot": (-0.16 * s, 0.0, 0.0, 0.0)},
        "ik_r": {"foot": (0.12 * s, 8.0, 0.0, 0.0)},
    })
    g = CLASP_GAP * s
    return world_hands(rig, pose, (g, SLAM_Y * s, SLAM_Z * s), (-g, SLAM_Y * s, SLAM_Z * s), out=0.25)


def attack(t, rig):
    """0 duruş → 0.3 yumruklar göğüs önünde → 0.6 baş üstünde kenetli, geriye gerilir → 0.78 en gergin →
    0.9 VURUŞ (yumruklar yerde) → 1.05 sarsıntı → 1.6 toparlanmış duruş."""
    s = rig.s
    swing = merge(_arch(rig), {"pelvis": {"loc": (0.0, -0.02 * s, -0.14 * s), "rot": (12.0, 0.0, 0.0)},
                               "spine_01": {"rot": (6.0, 0.0, 0.0)}, "spine_02": {"rot": (4.0, 0.0, 0.0)},
                               "Head": {"rot": (-10.0, 0.0, 0.0)}, "jaw": {"rot": (24.0, 0.0, 0.0)},
                               "ik_l": {"foot": (-0.16 * s, -6.0, 0.03 * s, 0.0)}})
    _clasp(rig, swing, 0.30, -0.25)
    rise = merge(_slam(rig, 0.0), {"pelvis": {"loc": (0.0, -0.06 * s, -0.18 * s), "rot": (18.0, 0.0, 0.0)},
                                   "spine_01": {"rot": (8.0, 0.0, 0.0)}, "spine_02": {"rot": (6.0, 0.0, 0.0)},
                                   "jaw": {"rot": (12.0, 0.0, 0.0)}})
    g = CLASP_GAP * s
    world_hands(rig, rise, (g, -0.48 * s, 0.45 * s), (-g, -0.48 * s, 0.45 * s), out=0.2)
    end = rest_arms(stand(rig))
    return track(t, [(0.0, rest_arms(stand(rig))), (0.30, _raise(rig)), (0.60, _arch(rig)),
                     (0.76, _arch(rig, 5.0)), (0.84, swing), (HIT_TIME, _slam(rig, 1.0)),
                     (1.02, _slam(rig, 0.6)), (1.25, rise), (ATTACK_TIME, end)])


# --- tepki ------------------------------------------------------------------------------
STAGGER_TIME = 0.35


def stagger(t, rig):
    """Küçük: göğse darbe, gövde ve kafa geri, omuzlar açılır; ayaklar yerinde."""
    s = rig.s
    hit = merge(stand(rig, 0.03), {
        "pelvis": {"loc": (0.0, 0.03 * s, -0.03 * s), "rot": (-3.0, 2.0, -3.0)},
        "spine_01": {"rot": (-5.0, 0.0, 0.0)}, "spine_02": {"rot": (-6.0, 2.0, 0.0)},
        "Head": {"rot": (-14.0, 6.0, 4.0)}, "jaw": {"rot": (20.0, 0.0, 0.0)},
    })
    side(hit, "upperarm", (-8.0, -8.0, 0.0))
    side(hit, "lowerarm", (-6.0, 0.0, 0.0))
    settle = merge(stand(rig, 0.03), {"spine_01": {"rot": (3.0, 0.0, 0.0)}, "Head": {"rot": (4.0, -2.0, 0.0)}})
    return track(t, [(0.0, stand(rig)), (0.07, hit), (0.20, settle), (STAGGER_TIME, stand(rig))])


CLIPS = [("idle_Loop", idle, IDLE_CYCLE), ("walk_Loop", walk, WALK_CYCLE), ("attack", attack, ATTACK_TIME),
         ("stagger", stagger, STAGGER_TIME)]


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
    import tank_falls
    importlib.reload(tank_falls)
    bpy.context.scene.render.fps = wp.FPS
    bpy.context.scene.render.fps_base = 1.0
    if arm.animation_data is None:
        arm.animation_data_create()
    rig = wp.Rig(arm)
    names = []
    for name, fn, length in CLIPS + tank_falls.CLIPS:
        wp.build_clip(rig, name, fn, length)
        names.append(name)
    arm.animation_data.action = bpy.data.actions[CLIPS[0][0]]
    print("TANK ANIMS", names, "IK clamped frames:", rig.clamped, "rig.s %.3f" % rig.s)
    return names
