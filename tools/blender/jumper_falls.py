"""Zıplayan ölüm ve doğma klipleri (V.5 v2) — jumper_anims.py'nin devamı, aynı sözleşme.

death_a: vurulup geri sarsılır, dizleri çöker, öne yüzüstü kapaklanır; kollar yanlara yığılır, küçük sekme.
death_b: kafası yana savrulur, döner, kalçasının üstüne oturup sırtüstü devrilir; bacaklar havada bükük kalır.
spawn  : yerde kıvrık, elleri yere basmış; ellerle iterek doğrulur, kafa en son kalkar (0.9 sn).
Ayaklar yerdeyken IK (kaymaz), yere yığılırken anahtar pozlar önce FK'ya çözülüp aradeğerlenir.
Yere gömülme / havada kalma: kliple birlikte ağın en alt noktası ölçülüp pelvis yüksekliği kare kare
düzeltilir (ground_fix) — yere değdikten sonra en alt nokta tam zeminde.
"""
import walker_pose as wp
from walker_pose import merge, track
from jumper_anims import arms_fk, feet, hand_at, idle, side, stand

DEATH_A_TIME, DEATH_B_TIME, SPAWN_TIME = 1.4, 1.5, 0.9
GROUND_FROM = {"death_a": 0.70, "death_b": 0.85, "spawn": 0.0}   # bu andan sonra en alt nokta = zemin


def fk(rig, pose):
    return wp.solve_arms(rig, wp.solve_legs(rig, {k: dict(v) for k, v in pose.items()}))


def two_phase(t, rig, ik_keys, fk_keys):
    if t <= ik_keys[-1][0]:
        return track(t, ik_keys)
    return track(t, [(k, fk(rig, p)) for k, p in ik_keys[-2:]] + fk_keys)


def _jolt(rig, roll):
    s = rig.s
    pose = merge(stand(rig, 0.03), {
        "pelvis": {"loc": (0.0, 0.06 * s, -0.03 * s), "rot": (-8.0, roll * 0.3, roll * 0.2)},
        "spine_01": {"rot": (-12.0, 0.0, 0.0)}, "spine_02": {"rot": (-8.0, roll * 0.5, 0.0)},
        "Head": {"rot": (-24.0, roll, roll * 0.5)}, "jaw": {"rot": (26.0, 0.0, 0.0)}})
    side(pose, "upperarm", (-4.0, -16.0, 0.0))     # gövde 28° geri savrulur; kol ona eklenmesin
    return side(pose, "lowerarm", (-14.0, 0.0, 0.0))


def _lying(rig, z, y, pitch, roll, legs, arm, head, spine=0.0):
    """Yerde yatan FK poz (ayak hedefi yok). Dinlenmede omurga ~45° öne kambur: yatışta `spine`
    (derece, üç omurga kemiğine bölünür) gövde eksenini yere paralel getirir."""
    s = rig.s
    pose = {"pelvis": {"loc": (0.0, y * s, z * s), "rot": (pitch, roll, 0.0)},
            "spine_01": {"rot": (spine * 0.35, 0.0, 0.0)}, "spine_02": {"rot": (spine * 0.40, 0.0, 0.0)},
            "spine_03": {"rot": (spine * 0.25, 0.0, 0.0)}, "neck_01": {"rot": (head[0] * 0.4, 0.0, 0.0)},
            "Head": {"rot": head}, "jaw": {"rot": (28.0, 0.0, 0.0)}}
    for bone, rot in legs.items():
        side(pose, bone, rot)
    side(pose, "clavicle", (0.0, 0.0, 0.0))
    side(pose, "upperarm", arm[0])
    side(pose, "lowerarm", arm[1])
    return side(pose, "hand", (0.0, 0.0, 0.0))


def death_a(t, rig):
    s = rig.s
    buckle = merge(stand(rig, 0.30), {
        "pelvis": {"loc": (0.0, 0.0, -0.30 * s), "rot": (30.0, 0.0, 0.0)},
        "spine_01": {"rot": (12.0, 0.0, 0.0)}, "Head": {"rot": (14.0, 0.0, 0.0)}, "jaw": {"rot": (16.0, 0.0, 0.0)}})
    buckle.update(feet(rig, 0.0, 22.0, 0.0, 0.02))
    side(buckle, "upperarm", (-20.0, 0.0, 0.0))
    # yüzüstü: pelvis 70° + omurga -24° → gövde ekseni yatay. Uyluk +56° ile geriye yatay, baldır düzleşir;
    # kollar dinlenmede gövdeye 135° (yere batar) → +45° geriye: gövde boyunca yerde.
    legs = {"thigh": (56.0, 0.0, 0.0), "calf": (-60.0, 0.0, 0.0), "foot": (40.0, 0.0, 0.0)}
    fall = _lying(rig, -0.50, -0.30, 60.0, 0.0, legs, ((10.0, 8.0, 0.0), (-25.0, 0.0, 0.0)), (-20.0, 0.0, 0.0), -16.0)
    bounce = _lying(rig, -0.60, -0.38, 72.0, 3.0, legs, ((40.0, 8.0, 0.0), (35.0, 0.0, 0.0)), (-35.0, 6.0, 25.0), -26.0)
    rest = _lying(rig, -0.64, -0.40, 70.0, 2.0, legs, ((48.0, 10.0, 0.0), (45.0, 0.0, 0.0)), (-32.0, 8.0, 35.0), -24.0)
    return two_phase(t, rig, [(0.0, idle(0.0, rig)), (0.10, _jolt(rig, 6.0)), (0.40, buckle)],
                     [(0.70, fall), (0.92, bounce), (DEATH_A_TIME, rest)])


def death_b(t, rig):
    s = rig.s
    twist = merge(_jolt(rig, -22.0), {"pelvis": {"loc": (0.0, 0.05 * s, -0.08 * s), "rot": (-6.0, -6.0, -24.0)}})
    sit = merge(stand(rig, 0.40), {"pelvis": {"loc": (0.0, 0.18 * s, -0.42 * s), "rot": (-18.0, -4.0, -30.0)},
                                   "spine_01": {"rot": (-10.0, 0.0, 0.0)}, "Head": {"rot": (-20.0, -14.0, 0.0)},
                                   "jaw": {"rot": (24.0, 0.0, 0.0)}})
    sit.update(feet(rig, -0.10, -10.0, 0.0, 0.06))
    side(sit, "upperarm", (-40.0, -30.0, 0.0))
    # sırtüstü (pelvis ~-88°): yerel aşağı = dünya önü; uyluk dinlenmede dizler yukarı, ayak tabanı yere
    # iner (bükük bacak), kollar yana açılıp yere düşer.
    legs = {"thigh": (24.0, 0.0, 0.0), "calf": (-30.0, 0.0, 0.0), "foot": (0.0, 0.0, 0.0)}
    back = _lying(rig, -0.55, 0.30, -70.0, -6.0, legs, ((10.0, -10.0, 0.0), (20.0, 0.0, 0.0)),
                  (6.0, -20.0, -20.0), -30.0)
    rest = _lying(rig, -0.62, 0.36, -78.0, -4.0, {"thigh": (34.0, 0.0, -8.0), "calf": (-62.0, 0.0, 0.0),
                                                  "foot": (-10.0, 0.0, 0.0)},
                  ((30.0, -12.0, 0.0), (40.0, 0.0, 0.0)), (12.0, -24.0, -40.0), -38.0)
    return two_phase(t, rig, [(0.0, idle(0.0, rig)), (0.12, twist), (0.50, sit)],
                     [(0.85, back), (1.05, rest), (DEATH_B_TIME, rest)])


def _ground_crouch(rig, z, pitch, head):
    s = rig.s
    pose = merge({"pelvis": {"loc": (0.0, 0.10 * s, z * s), "rot": (pitch, 0.0, 0.0)},
                  "spine_01": {"rot": (16.0, 0.0, 0.0)}, "spine_02": {"rot": (10.0, 0.0, 0.0)},
                  "neck_01": {"rot": (head * 0.5, 0.0, 0.0)}, "Head": {"rot": (head, 0.0, 0.0)},
                  "jaw": {"rot": (10.0, 0.0, 0.0)}}, feet(rig, 0.03, 18.0, 0.0, 0.04))
    side(pose, "hand", (-35.0, 0.0, 0.0))
    return hand_at(rig, pose, (0.18, -0.34, 0.075))


def spawn(t, rig):
    """Yerden doğrulma: eller yerde kıvrık → ellerle itip kalkar → kafa en son kalkar."""
    curl = _ground_crouch(rig, -0.48, 58.0, 30.0)
    push = _ground_crouch(rig, -0.40, 44.0, 10.0)
    up = merge(stand(rig, 0.12), {"pelvis": {"loc": (0.0, 0.03 * rig.s, -0.14 * rig.s), "rot": (16.0, 0.0, 0.0)},
                                  "spine_01": {"rot": (8.0, 0.0, 0.0)}, "Head": {"rot": (20.0, 0.0, 0.0)}})
    side(up, "upperarm", (-10.0, 0.0, 0.0))
    return track(t, [(0.0, curl), (0.25, push), (0.58, up), (SPAWN_TIME, idle(0.0, rig))])


CLIPS = [("death_a", death_a, DEATH_A_TIME), ("death_b", death_b, DEATH_B_TIME), ("spawn", spawn, SPAWN_TIME)]


def ground_fix(arm, mesh, action, t_ground, frames):
    """Kare kare ağın en alt noktasını ölçer, pelvis konumunu düzeltir: her karede gömülme yok,
    t_ground'dan sonra en alt nokta tam zeminde. Düzeltme 3 karelik ortalamayla yumuşatılır."""
    import bpy
    scene = bpy.context.scene
    arm.animation_data.action = action
    pb = arm.pose.bones["pelvis"]
    rest = arm.data.bones["pelvis"].matrix_local.to_quaternion()
    lows, locs = [], []
    for f in range(frames + 1):
        scene.frame_set(f)
        dg = bpy.context.evaluated_depsgraph_get()
        ev = mesh.evaluated_get(dg)
        mw = ev.matrix_world
        lows.append(min((mw @ v.co).z for v in ev.data.vertices))
        locs.append(rest @ pb.location.copy())
    fix = [(-lo if f / wp.FPS >= t_ground else max(0.0, -lo)) for f, lo in enumerate(lows)]
    fix = [sum(fix[max(0, i - 1):i + 2]) / len(fix[max(0, i - 1):i + 2]) for i in range(len(fix))]
    for f, (loc, c) in enumerate(zip(locs, fix)):
        loc.z += c / arm.matrix_world.to_scale().z
        pb.location = rest.inverted() @ loc
        pb.keyframe_insert("location", frame=f, group="pelvis")
    return max(abs(c) for c in fix)
