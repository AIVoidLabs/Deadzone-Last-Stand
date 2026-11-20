"""Koşucu ölüm ve doğma klipleri (Aşama V.5) — runner_anims.py'nin devamı, aynı sözleşme.

death_a: koşarken tökezler, öne dalar, yüzüstü yere çarpar, uzun ekseni boyunca yuvarlanıp sırtüstü kalır.
death_b: kafası geri savrulur, dizlerinin üstüne çöker, sallanır, sol yanına devrilir.
spawn  : dört ayak üstünde yere yapışık; kalkar, baş en son askere döner (0.9 sn).
Yerde geçen anahtar pozlar ÖLÇÜLEREK yere oturtulur (prepare): poz uygulanır, ağın en alt köşesi
bulunur, pelvis yüksekliği bu kadar düzeltilir (ground). Havadaki pozlar yalnız yere girmeyecek kadar
kaldırılır. Ayaklar yerdeyken IK (kaymaz), yere yığılırken kemik dönüşü (walker_falls.two_phase).
"""
import bpy

import walker_check as wk
import walker_pose as wp
from walker_anims import hands, rest_arms, side, stand
from walker_falls import fk, two_phase
from walker_pose import merge, track
from runner_anims import hands_ground

DEATH_A_TIME = 1.5
DEATH_B_TIME = 1.4
SPAWN_TIME = 0.9
CLEAR = 0.004            # yerde yatan pozda ağın en alt noktası (m)


def _mesh(arm):
    return next(o for o in bpy.data.objects if o.type == "MESH"
                and any(m.type == "ARMATURE" and m.object == arm for m in o.modifiers))


def ground(rig, pose, air=False):
    """FK pozu ölçerek yere oturtur (air: yalnız yere giriyorsa kaldırır). Düzeltmeyi rig.fits'e yazar."""
    pose = fk(rig, pose)
    rig.arm.animation_data.action = None
    wk.set_pose(rig, pose)
    low, bone = wk.low_where(rig.mesh)
    dz = CLEAR - low if (not air or low < CLEAR) else 0.0
    pel = pose.setdefault("pelvis", {})
    x, y, z = pel.get("loc", (0.0, 0.0, 0.0))
    pel["loc"] = (x, y, z + dz)
    rig.fits.append((round(low, 3), bone, round(dz, 3)))
    return pose


def _jolt(rig, back):
    s = rig.s
    pose = merge(stand(rig, 0.03), {
        "pelvis": {"loc": (0.0, 0.04 * s, -0.03 * s), "rot": (-4.0, back * 0.2, 0.0)},
        "spine_01": {"rot": (-10.0, 0.0, 0.0)}, "spine_02": {"rot": (-8.0, back * 0.5, 0.0)},
        "Head": {"rot": (-28.0, back, back * 0.4)}, "jaw": {"rot": (36.0, 0.0, 0.0)},
    })
    return hands(rig, pose, (0.28, 0.0, -0.42), out=0.4)


# ---------------------------------------------------------------- death_a: yuvarlanma
def _death_a_keys(rig):
    s = rig.s
    trip = merge(stand(rig, 0.10), {
        "pelvis": {"loc": (0.0, -0.18 * s, -0.10 * s), "rot": (34.0, 0.0, 4.0)},
        "spine_01": {"rot": (8.0, 0.0, 0.0)}, "neck_01": {"rot": (-24.0, 0.0, 0.0)},
        "Head": {"rot": (-18.0, 0.0, 0.0)}, "jaw": {"rot": (34.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.02 * s, 40.0, 0.0, 0.0)}, "ik_r": {"foot": (0.12 * s, 60.0, 0.0, 0.0)},
    })
    hands(rig, trip, (0.22, -0.45, -0.40), out=0.4)
    legs_trail = {"thigh_l": {"rot": (10.0, 0.0, 4.0)}, "calf_l": {"rot": (30.0, 0.0, 0.0)},
                  "thigh_r": {"rot": (24.0, 0.0, -4.0)}, "calf_r": {"rot": (50.0, 0.0, 0.0)},
                  "foot_l": {"rot": (30.0, 0.0, 0.0)}, "foot_r": {"rot": (30.0, 0.0, 0.0)}}
    dive = merge(legs_trail, {"pelvis": {"loc": (0.0, -0.60 * s, -0.36 * s), "rot": (50.0, 0.0, 6.0)},
                              "neck_01": {"rot": (-30.0, 0.0, 0.0)}, "Head": {"rot": (-20.0, 0.0, 0.0)},
                              "jaw": {"rot": (30.0, 0.0, 0.0)}})
    hands_ground(rig, dive, ((0.20, -0.30), (0.22, -0.26)), 0.16)
    impact = merge(legs_trail, {"pelvis": {"loc": (0.0, -0.90 * s, -0.60 * s), "rot": (60.0, 0.0, 8.0)},
                                "spine_01": {"rot": (-4.0, 0.0, 0.0)}, "neck_01": {"rot": (-34.0, 0.0, 0.0)},
                                "Head": {"rot": (-24.0, 0.0, 40.0)}, "jaw": {"rot": (24.0, 0.0, 0.0)}})
    hands_ground(rig, impact, ((0.26, -0.22), (0.30, -0.05)), 0.05)
    roll_side = merge(impact, {"pelvis": {"loc": (0.08 * s, -1.00 * s, -0.55 * s), "rot": (60.0, 85.0, 10.0)},
                               "thigh_l": {"rot": (40.0, 0.0, 10.0)}, "calf_l": {"rot": (50.0, 0.0, 0.0)},
                               "thigh_r": {"rot": (60.0, 0.0, -6.0)}, "calf_r": {"rot": (30.0, 0.0, 0.0)},
                               "Head": {"rot": (-6.0, 10.0, 10.0)}})
    hands_ground(rig, roll_side, ((0.30, -0.15), (0.10, -0.25)), (0.05, 0.28))
    back = {"pelvis": {"loc": (0.14 * s, -1.08 * s, -0.62 * s), "rot": (70.0, 170.0, 12.0)},
            "spine_01": {"rot": (-12.0, 0.0, 0.0)}, "spine_02": {"rot": (-10.0, 0.0, 0.0)},
            "neck_01": {"rot": (6.0, 0.0, 0.0)}, "Head": {"rot": (10.0, 0.0, -30.0)},
            "jaw": {"rot": (34.0, 0.0, 0.0)},
            "thigh_l": {"rot": (42.0, 0.0, 12.0)}, "calf_l": {"rot": (40.0, 0.0, 0.0)},
            "thigh_r": {"rot": (60.0, 0.0, -8.0)}, "calf_r": {"rot": (10.0, 0.0, 0.0)},
            "foot_l": {"rot": (20.0, 0.0, 0.0)}, "foot_r": {"rot": (20.0, 0.0, 0.0)}}
    hands_ground(rig, back, ((0.34, -0.10), (0.30, 0.15)), 0.05)
    bounce = merge(back, {"pelvis": {"loc": (0.14 * s, -1.08 * s, -0.58 * s), "rot": (66.0, 166.0, 12.0)},
                          "Head": {"rot": (16.0, 0.0, -24.0)}})
    ik_keys = [(0.0, rest_arms(stand(rig))), (0.12, _jolt(rig, 0.0)), (0.24, trip)]
    fk_keys = [(0.40, ground(rig, dive, air=True)), (0.55, ground(rig, impact)), (0.82, ground(rig, roll_side)),
               (1.06, ground(rig, back)), (1.20, ground(rig, bounce, air=True)), (DEATH_A_TIME, ground(rig, back))]
    return ik_keys, fk_keys


# ---------------------------------------------------------------- death_b: diz çöküp devrilme
def _death_b_keys(rig):
    s = rig.s
    kneel = {"pelvis": {"loc": (0.0, 0.10 * s, -0.40 * s), "rot": (16.0, 0.0, 0.0)},
             "spine_01": {"rot": (10.0, 0.0, 0.0)}, "spine_02": {"rot": (6.0, 4.0, 0.0)},
             "neck_01": {"rot": (10.0, 0.0, 0.0)}, "Head": {"rot": (24.0, 10.0, 0.0)}, "jaw": {"rot": (26.0, 0.0, 0.0)},
             "thigh_l": {"rot": (-40.0, 0.0, 6.0)}, "calf_l": {"rot": (100.0, 0.0, 0.0)},
             "thigh_r": {"rot": (-36.0, 0.0, -6.0)}, "calf_r": {"rot": (96.0, 0.0, 0.0)},
             "foot_l": {"rot": (40.0, 0.0, 0.0)}, "foot_r": {"rot": (40.0, 0.0, 0.0)}}
    hands_ground(rig, kneel, ((0.12, -0.26), (0.12, -0.22)), 0.07)
    sway = merge(kneel, {"pelvis": {"loc": (0.0, 0.10 * s, -0.40 * s), "rot": (12.0, 6.0, 0.0)},
                         "spine_02": {"rot": (2.0, 8.0, 0.0)}, "Head": {"rot": (6.0, 24.0, 6.0)}})
    hands_ground(rig, sway, ((0.16, -0.24), (0.08, -0.22)), (0.07, 0.10))
    tilt = merge(kneel, {"pelvis": {"loc": (0.12 * s, 0.10 * s, -0.48 * s), "rot": (12.0, 40.0, 6.0)},
                         "thigh_l": {"rot": (-30.0, 0.0, 10.0)}, "calf_l": {"rot": (80.0, 0.0, 0.0)}})
    hands_ground(rig, tilt, ((0.30, -0.10), (0.05, -0.25)), (0.06, 0.30))
    down = {"pelvis": {"loc": (0.28 * s, 0.10 * s, -0.62 * s), "rot": (10.0, 86.0, 10.0)},
            "spine_01": {"rot": (6.0, 0.0, 0.0)}, "spine_02": {"rot": (4.0, -2.0, 0.0)},
            "neck_01": {"rot": (0.0, -8.0, 0.0)}, "Head": {"rot": (6.0, -14.0, 10.0)}, "jaw": {"rot": (32.0, 0.0, 0.0)},
            "thigh_l": {"rot": (-50.0, 0.0, 0.0)}, "calf_l": {"rot": (70.0, 0.0, 0.0)},
            "thigh_r": {"rot": (-30.0, 0.0, 0.0)}, "calf_r": {"rot": (60.0, 0.0, 0.0)},
            "foot_l": {"rot": (20.0, 0.0, 0.0)}, "foot_r": {"rot": (20.0, 0.0, 0.0)}}
    hands_ground(rig, down, ((0.05, -0.35), (-0.05, -0.30)), (0.05, 0.12))
    bounce = merge(down, {"pelvis": {"loc": (0.28 * s, 0.10 * s, -0.58 * s), "rot": (10.0, 82.0, 10.0)}})
    ik_keys = [(0.0, rest_arms(stand(rig))), (0.12, _jolt(rig, -16.0))]
    fk_keys = [(0.42, ground(rig, kneel)), (0.66, ground(rig, sway)), (0.92, ground(rig, tilt, air=True)),
               (1.10, ground(rig, down)), (1.22, ground(rig, bounce, air=True)), (DEATH_B_TIME, ground(rig, down))]
    return ik_keys, fk_keys


# ---------------------------------------------------------------- spawn
def _spawn_keys(rig):
    s = rig.s
    low = merge(stand(rig, 0.34), {
        "pelvis": {"loc": (0.0, 0.10 * s, -0.34 * s), "rot": (30.0, 0.0, 0.0)},
        "spine_01": {"rot": (10.0, 0.0, 0.0)}, "spine_02": {"rot": (6.0, 0.0, 0.0)},
        "neck_01": {"rot": (14.0, 0.0, 0.0)}, "Head": {"rot": (20.0, 0.0, 0.0)},
        "ik_l": {"foot": (0.02 * s, 40.0, 0.0, 0.03 * s)}, "ik_r": {"foot": (0.0, 30.0, 0.0, -0.03 * s)},
    })
    side(low, "hand", (-50.0, 0.0, 0.0))
    hands_ground(rig, low, ((0.16, -0.30), (0.16, -0.26)), 0.10, out=0.5)
    half = merge(stand(rig, 0.16), {
        "pelvis": {"loc": (0.0, 0.05 * s, -0.16 * s), "rot": (18.0, 0.0, 0.0)},
        "spine_01": {"rot": (6.0, 0.0, 0.0)}, "neck_01": {"rot": (10.0, 0.0, 0.0)}, "Head": {"rot": (16.0, 6.0, 0.0)},
    })
    hands_ground(rig, half, ((0.12, -0.22), (0.12, -0.20)), 0.20)
    snap = merge(stand(rig, 0.04), {"neck_01": {"rot": (-10.0, 0.0, 0.0)}, "Head": {"rot": (-12.0, -6.0, 4.0)},
                                    "jaw": {"rot": (30.0, 0.0, 0.0)}})
    rest_arms(snap)
    return [(0.0, low), (0.15, low), (0.48, half), (0.74, snap), (SPAWN_TIME, rest_arms(stand(rig)))]


def prepare(rig) -> None:
    """Anahtar pozları bir kez kurar ve yere oturtur (klip anahtarlanırken ölçüm yapılmaz)."""
    rig.mesh = _mesh(rig.arm)
    rig.fits = []
    rig.keys = {"death_a": _death_a_keys(rig), "death_b": _death_b_keys(rig), "spawn": _spawn_keys(rig)}
    rig.lift = {}
    for name, length in (("death_a", DEATH_A_TIME), ("death_b", DEATH_B_TIME)):
        rig.lift[name] = _lift_table(rig, name, length)
    wp_reset(rig)
    print("RUNNER GROUND FITS (low, kemik, dz):", rig.fits)
    print("RUNNER LIFT max (m):", {k: round(max(v), 3) for k, v in rig.lift.items()})


def _lift_table(rig, name, length):
    """Kare başına ölçülen kaldırma: anahtarlar arası aradeğerleme ağı yere sokarsa pelvis o kadar kalkar."""
    out = []
    for f in range(round(length * wp.FPS) + 1):
        pose = fk(rig, _two(rig, name, f / wp.FPS))
        wk.set_pose(rig, pose)
        low, _bone = wk.low_where(rig.mesh)
        out.append(max(0.0, CLEAR - low))
    return out


def wp_reset(rig):
    for pb in rig.arm.pose.bones:
        pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
        pb.location = (0.0, 0.0, 0.0)


def _two(rig, name, t):
    ik_keys, fk_keys = rig.keys[name]
    return two_phase(t, rig, ik_keys, fk_keys)


def _lifted(rig, name, t):
    pose = _two(rig, name, t)
    table = getattr(rig, "lift", {}).get(name)
    if table:
        pose = fk(rig, pose)
        pel = pose.setdefault("pelvis", {})
        x, y, z = pel.get("loc", (0.0, 0.0, 0.0))
        pel["loc"] = (x, y, z + table[min(round(t * wp.FPS), len(table) - 1)])
    return pose


def death_a(t, rig):
    return _lifted(rig, "death_a", t)


def death_b(t, rig):
    return _lifted(rig, "death_b", t)


def spawn(t, rig):
    return track(t, rig.keys["spawn"])


CLIPS = [("death_a", death_a, DEATH_A_TIME), ("death_b", death_b, DEATH_B_TIME), ("spawn", spawn, SPAWN_TIME)]


def report_slip(rig, sys_feet) -> dict:
    """Döngü kliplerinde basan ayağın kayması (cm/döngü) ve tüm kliplerde ağın en alt noktası."""
    import runner_anims as ra
    out = {}
    for name, (fn, feet, cycle, speed) in sys_feet.items():
        out[name] = wk.walk_slip(rig, rig.mesh, fn, feet, cycle, ra.model_speed(rig, speed))
    names = [n for n, _f, _l in ra.CLIPS + CLIPS]
    wk.report(rig, rig.mesh, names=names)
    scene = bpy.context.scene
    worst = {}
    for name in names:          # en derin karenin kemiği (yere giren parça)
        act = bpy.data.actions[name]
        rig.arm.animation_data.action = act
        rows = []
        for f in range(int(act.frame_range[0]), int(act.frame_range[1]) + 1):
            scene.frame_set(f)
            rows.append((wk.low_where(rig.mesh), f))
        (z, bone), f = min(rows)
        worst[name] = (f, z, bone)
    print("RUNNER LOWEST (kare, z, kemik):", worst)
    print("RUNNER SLIP", {k: {s: "%.1f cm" % (v * 100) for s, v in d.items()} for k, d in out.items()})
    return out
