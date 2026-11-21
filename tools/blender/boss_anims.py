"""Boss "Yığın" klipleri (7.4) — elle anahtarlanmış anahtar pozlar, kodla yeniden üretilir.

Poz çekirdeği, bacak IK'sı, kol IK'sı ve açı sözleşmesi walker_pose.py'de (iskelet uzayı, derece; X+ öne
eğilme / sarkan uzuvda geriye savrulma, Y+ sola yatma, Z+ sola dönme; loc yalnız pelvis'te, metre).
Ek kemikler: `hump` (kambur; X+ öne yığılma), `claw_r` (pençe parmakları; X+ açılma, X- kenetlenme).
Döngüler `_Loop` ekli (Godot eki atar: idle, walk, charge). Bu dosya: ortak yardımcılar, idle, walk,
charge_windup, charge. Yer Dövme, kükreme, çağrı, sersemleme: boss_moves.py. Ölüm ve doğma: boss_falls.py.

Oyun sözleşmesi (s74_boss.md, tempo sonrası; model boyu ~3.6 m = EnemyData height):
  walk          : 1.4 sn döngü (iki adım), referans 1.28 m/sn (model uzayında mesh_h / 3.6 ile).
  charge_windup : 1.0 sn; son kare = charge döngüsünün ilk karesi (yumuşak geçiş).
  charge        : 0.6 sn döngü, referans 8.8 m/sn: kısa basış, uçuş evreli ağır sıçrayış (dörtnala).
  idle 2.4 (döngü).
"""
import math

from mathutils import Vector

import walker_pose as wp
from walker_pose import cyc, merge, track

TAU = math.tau
GAME_HEIGHT = 3.6

# --- yürüyüş ---------------------------------------------------------------------
WALK_SPEED = 1.28
WALK_FRAMES = 42
WALK_CYCLE = WALK_FRAMES / wp.FPS          # 1.4 sn
WALK_DUTY = 0.56
WALK_CROUCH = 0.18                         # m
WALK_LIFT = 0.16
WALK_CENTER = -0.06                        # basış ortası dinlenmeye göre önde (m)
WALK_SPREAD = 0.06                         # ayaklar dışa (geniş, ağır duruş)
# --- hücum -----------------------------------------------------------------------
CHARGE_SPEED = 8.8
CHARGE_FRAMES = 18
CHARGE_CYCLE = CHARGE_FRAMES / wp.FPS      # 0.6 sn
CHARGE_DUTY = 0.22
CHARGE_CROUCH = 0.40
CHARGE_LIFT = 0.30
CHARGE_CENTER = -0.10
CHARGE_LEAN = 24.0


def speed(rig, v):
    """Oyun hızını model uzayına çevirir (oyun modeli EnemyData boyuna ölçekler)."""
    h = getattr(rig, "mesh_h", None) or GAME_HEIGHT
    return v * h / GAME_HEIGHT


def _hermite(p0, p1, m0, m1, u):
    u2, u3 = u * u, u * u * u
    return (2 * u3 - 3 * u2 + 1) * p0 + (u3 - 2 * u2 + u) * m0 + (-2 * u3 + 3 * u2) * p1 + (u3 - u2) * m1


def _ease(u, keys):
    return track(u, [(k, {"v": {"x": val}}) for k, val in keys])["v"]["x"]


def foot_track(phi, start, duty, v, cycle, center, follow=0.6):
    """Basışta ayak v ile geri kayar (dünyada durur); salınımda Hermite ile öne. (y, u, yerde)"""
    dist = v * cycle
    reach = dist * duty
    u = ((phi - start) % 1.0) / duty
    if u <= 1.0:
        return center - reach / 2 + reach * u, u, True
    w = (u - 1.0) * duty / (1.0 - duty)
    m = dist * (1.0 - duty)
    return _hermite(center + reach / 2, center - reach / 2, follow * m, m, w), w, False


def side(pose, base, rot_l, **extra):
    pose[base + "_l"] = {"rot": tuple(rot_l), **extra}
    pose[base + "_r"] = {"rot": (rot_l[0], -rot_l[1], -rot_l[2]), **extra}
    return pose


def stand(rig, crouch=0.04, spread=0.0, lean=4.0):
    return {"pelvis": {"loc": (0.0, 0.0, -crouch), "rot": (lean, 0.0, 0.0)},
            "ik_l": {"foot": (0.0, 0.0, 0.0, spread)}, "ik_r": {"foot": (0.0, 0.0, 0.0, -spread)}}


def world_hands(rig, pose, target_l, target_r, out=0.0):
    """Bilek hedefleri iskelet uzayında (tank_anims kopyası): göğüs çerçevesine çevrilir."""
    q03, h03 = wp._fk_chest(rig, pose)
    inv = q03.inverted()
    for sd, t in (("l", target_l), ("r", target_r)):
        if t is None:
            continue
        rel = inv @ (Vector(t) - h03) + rig.head["spine_03"] - rig.head["hand_" + sd]
        pose["arm_" + sd] = {"hand": tuple(rel), "out": out}
    return pose


def base_pose(rig):
    """Klip başı/sonu ortak duruş (idle'ın ilk karesi): döngüsüz kliplerin sonu buna oturur."""
    return idle(0.0, rig)


# --- bekleme ------------------------------------------------------------------------------
IDLE_CYCLE = 2.4


def idle(t, rig):
    """Ağır hırıltılı nefes: kambur kabarır, omuzlar kalkar, kollar sarkık salınır, pençe kıpırdar."""
    phi = (t / IDLE_CYCLE) % 1.0
    w = TAU * phi
    breath = cyc(phi, [(0.0, 0.0), (0.38, 1.0), (0.52, 0.9), (0.85, 0.0)])
    pose = merge(stand(rig, 0.04 + 0.02 * (1.0 - breath), 0.03), {
        "pelvis": {"loc": (0.012 * math.sin(w), 0.0, -(0.04 + 0.02 * (1.0 - breath))),
                   "rot": (4.0, 1.2 * math.sin(w), 1.5 * math.sin(w))},
        "spine_01": {"rot": (2.0 - 1.5 * breath, -0.6 * math.sin(w), 0.0)},
        "spine_02": {"rot": (2.0 - 3.0 * breath, 0.0, -1.0 * math.sin(w))},
        "spine_03": {"rot": (-2.0 * breath, 0.0, 0.0)},
        "hump": {"rot": (-4.0 * breath, 1.5 * math.sin(w + 1.0), 0.0)},
        "neck_01": {"rot": (2.0 * breath, 0.0, 0.0)},
        "Head": {"rot": (-2.0 + 4.0 * breath, 2.0 * math.sin(w + 0.6), 5.0 * math.sin(w + 0.3))},
        "jaw": {"rot": (8.0 + 14.0 * (1.0 - breath), 0.0, 0.0)},
        "claw_r": {"rot": (6.0 * math.sin(2 * w), 0.0, 0.0)},
    })
    side(pose, "clavicle", (0.0, -4.0 * breath, 0.0))
    for sd, ph in (("l", 0.0), ("r", 1.1)):
        pose["upperarm_" + sd] = {"rot": (3.0 * math.sin(w + ph), 0.0, 0.0)}
        pose["lowerarm_" + sd] = {"rot": (-4.0 + 4.0 * math.sin(w + ph - 0.6), 0.0, 0.0)}
        pose["hand_" + sd] = {"rot": (5.0 * math.sin(w + ph - 1.2), 0.0, 0.0)}
    return pose


# --- yürüyüş ------------------------------------------------------------------------------

def walk(t, rig):
    """Ağır, geniş adımlı yürüyüş: basan yana yük aktarır, gövde çöker; kambur gecikmeli sallanır,
    topuz ve pençe sarkık ve ağır salınır (karşı bacakla)."""
    phi = (t / WALK_CYCLE) % 1.0
    v = speed(rig, WALK_SPEED)
    dz = cyc(phi, [(0.04, -0.07), (0.26, 0.02), (0.54, -0.07), (0.76, 0.02)])
    sway = cyc(phi, [(0.0, -0.4), (0.22, -1.0), (0.5, 0.4), (0.72, 1.0)]) * 0.09
    roll = cyc(phi, [(0.06, -6.0), (0.3, -1.0), (0.56, 6.0), (0.8, 1.0)])
    yaw = cyc(phi, [(0.0, 7.0), (0.25, 0.0), (0.5, -7.0), (0.75, 0.0)])
    lag = cyc(phi - 0.10, [(0.04, 1.0), (0.26, -0.6), (0.54, 1.0), (0.76, -0.6)])
    feet = {}
    for sd, start, sx in (("r", 0.0, -1.0), ("l", 0.5, 1.0)):
        y, u, down = foot_track(phi, start, WALK_DUTY, v, WALK_CYCLE, WALK_CENTER, 1.0)
        if down:
            pitch, lift = _ease(u, [(0.0, -4.0), (0.10, 0.0), (0.62, 0.0), (0.88, 10.0), (1.0, 22.0)]), 0.0
        else:
            pitch = _ease(u, [(0.0, 22.0), (0.35, 16.0), (0.75, -4.0), (1.0, -8.0)])
            lift = WALK_LIFT * math.sin(math.pi * u) ** 0.8
        arc = 0.05 * math.sin(math.pi * u) if not down else 0.0
        feet[sd] = (y, pitch, lift, sx * (WALK_SPREAD + arc))
    pose = {
        "pelvis": {"loc": (sway, 0.0, dz - WALK_CROUCH), "rot": (8.0, roll, yaw)},
        "spine_01": {"rot": (3.0 + 1.5 * lag, -0.5 * roll, -0.6 * yaw)},
        "spine_02": {"rot": (2.0, -0.3 * roll, -0.4 * yaw)},
        "spine_03": {"rot": (1.0 - 1.0 * lag, 0.2 * roll, 0.0)},
        "hump": {"rot": (3.0 * lag, 0.5 * roll, 0.3 * yaw)},
        "neck_01": {"rot": (-6.0, -0.3 * roll, 0.0)},
        "Head": {"rot": (-4.0 + 3.0 * lag, 0.3 * roll, 0.5 * yaw)},
        "jaw": {"rot": (cyc(phi, [(0.05, 16.0), (0.3, 8.0), (0.55, 16.0), (0.8, 8.0)]), 0.0, 0.0)},
        "claw_r": {"rot": (cyc(phi, [(0.0, 8.0), (0.5, -6.0)]), 0.0, 0.0)},
        "ik_l": {"foot": feet["l"]}, "ik_r": {"foot": feet["r"]},
    }
    for sd, ph, sy in (("l", 0.5, 1.0), ("r", 0.0, -1.0)):
        sw = cyc(phi - 0.12 + ph, [(0.0, -14.0), (0.5, 14.0)])
        pose["clavicle_" + sd] = {"rot": (0.0, sy * 0.4 * roll, 0.0)}
        pose["upperarm_" + sd] = {"rot": (-8.0 + sw, sy * -4.0, 0.0)}
        pose["lowerarm_" + sd] = {"rot": (-18.0 + 0.6 * cyc(phi - 0.25 + ph, [(0.0, -10.0), (0.5, 10.0)]), 0.0, 0.0)}
        pose["hand_" + sd] = {"rot": (cyc(phi - 0.35 + ph, [(0.0, -10.0), (0.5, 10.0)]), 0.0, 0.0)}
    return pose


# --- hücum --------------------------------------------------------------------------------

def charge(t, rig):
    """Dörtnala ağır hücum: kısa basış, uçuş evresi; gövde öne kapanmış, kafa aşağıda, kollar
    gorilin koşusu gibi büyük yaylarla savrulur (topuz karşı bacakla öne). Kambur her inişte sarsılır."""
    phi = (t / CHARGE_CYCLE) % 1.0
    v = speed(rig, CHARGE_SPEED)
    # basış 0 (sağ) ve 0.5 (sol): basış ortasında en alçak, uçuşta en yüksek
    dz = cyc(phi, [(0.12, -0.12), (0.37, 0.10), (0.62, -0.12), (0.87, 0.10)])
    pitch = cyc(phi, [(0.10, 4.0), (0.35, -3.0), (0.60, 4.0), (0.85, -3.0)])
    roll = cyc(phi, [(0.12, -7.0), (0.62, 7.0)])
    yaw = cyc(phi, [(0.0, 9.0), (0.5, -9.0)])
    jolt = cyc(phi - 0.06, [(0.06, 1.0), (0.30, -0.5), (0.56, 1.0), (0.80, -0.5)])
    feet = {}
    for sd, start, sx in (("r", 0.0, -1.0), ("l", 0.5, 1.0)):
        y, u, down = foot_track(phi, start, CHARGE_DUTY, v, CHARGE_CYCLE, CHARGE_CENTER, 1.0)
        if down:
            fp, lift = _ease(u, [(0.0, -4.0), (0.15, 0.0), (0.6, 4.0), (1.0, 30.0)]), 0.0
        else:
            fp = _ease(u, [(0.0, 30.0), (0.3, 50.0), (0.65, 10.0), (1.0, -4.0)])
            lift = CHARGE_LIFT * math.sin(math.pi * u) ** 0.8
        feet[sd] = (y, fp, lift, sx * 0.07)
    pose = {
        "pelvis": {"loc": (0.0, 0.0, dz - CHARGE_CROUCH), "rot": (CHARGE_LEAN + pitch, roll, yaw)},
        "spine_01": {"rot": (8.0 + 2.0 * jolt, -0.4 * roll, -0.6 * yaw)},
        "spine_02": {"rot": (6.0, -0.3 * roll, -0.4 * yaw)},
        "spine_03": {"rot": (2.0 - 2.0 * jolt, 0.0, 0.0)},
        "hump": {"rot": (6.0 * jolt, 0.6 * roll, 0.0)},
        "neck_01": {"rot": (-22.0, 0.0, 0.0)},
        "Head": {"rot": (-16.0 + 4.0 * jolt, 0.3 * roll, 0.4 * yaw)},
        "jaw": {"rot": (26.0 + 6.0 * jolt, 0.0, 0.0)},
        "claw_r": {"rot": (14.0, 0.0, 0.0)},
        "ik_l": {"foot": feet["l"]}, "ik_r": {"foot": feet["r"]},
    }
    for sd, ph, sy in (("l", 0.5, 1.0), ("r", 0.0, -1.0)):
        sw = cyc(phi - 0.05 + ph, [(0.0, -30.0), (0.5, 16.0)])
        pose["clavicle_" + sd] = {"rot": (0.0, sy * -12.0, 0.0)}
        pose["upperarm_" + sd] = {"rot": (-CHARGE_LEAN + sw, sy * -14.0, 0.0)}
        pose["lowerarm_" + sd] = {"rot": (cyc(phi - 0.15 + ph, [(0.0, -80.0), (0.5, -62.0)]), 0.0, 0.0)}
        pose["hand_" + sd] = {"rot": (cyc(phi - 0.25 + ph, [(0.0, -10.0), (0.5, 46.0)]), 0.0, 0.0)}
    return pose


WINDUP_TIME = 1.0


def charge_windup(t, rig):
    """0 duruş → 0.25 yere çöker, kollar geriye açılır → 0.55 en alçak: boğa gibi sağ ayağıyla eşelenir,
    pençe yeri tırmalar, kafa askere kilitli → 0.8 öne yaylanır → 1.0 = hücum döngüsünün ilk karesi."""
    first = charge(0.0, rig)
    crouch = merge(stand(rig, 0.30, 0.10, 20.0), {
        "spine_01": {"rot": (10.0, 0.0, 0.0)}, "spine_02": {"rot": (8.0, 0.0, 0.0)},
        "hump": {"rot": (8.0, 0.0, 0.0)}, "neck_01": {"rot": (-24.0, 0.0, 0.0)},
        "Head": {"rot": (-14.0, 0.0, 0.0)}, "jaw": {"rot": (30.0, 0.0, 0.0)}, "claw_r": {"rot": (24.0, 0.0, 0.0)},
    })
    side(crouch, "upperarm", (30.0, -22.0, 0.0))
    side(crouch, "lowerarm", (-20.0, 0.0, 0.0))
    paw = merge(crouch, {"pelvis": {"loc": (0.0, 0.04, -0.40), "rot": (24.0, 0.0, 0.0)},
                         "ik_r": {"foot": (0.10, 20.0, 0.10, -0.10)},
                         "claw_r": {"rot": (-10.0, 0.0, 0.0)}})
    scrape = merge(paw, {"ik_r": {"foot": (0.30, 30.0, 0.0, -0.10)}, "claw_r": {"rot": (20.0, 0.0, 0.0)}})
    load = merge(wp.blend(scrape, first, 0.4), {"pelvis": {"loc": (0.0, 0.06, -0.42), "rot": (26.0, 0.0, 0.0)}})
    return track(t, [(0.0, base_pose(rig)), (0.25, crouch), (0.42, paw), (0.58, scrape), (0.68, paw),
                     (0.84, load), (WINDUP_TIME, first)])


CLIPS = [("idle_Loop", idle, IDLE_CYCLE), ("walk_Loop", walk, WALK_CYCLE),
         ("charge_windup", charge_windup, WINDUP_TIME), ("charge_Loop", charge, CHARGE_CYCLE)]


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
    import boss_moves
    import boss_falls
    importlib.reload(boss_moves)
    importlib.reload(boss_falls)
    bpy.context.scene.render.fps = wp.FPS
    bpy.context.scene.render.fps_base = 1.0
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.data.pose_position = "REST"
    rig = wp.Rig(arm)
    rig.mesh_h = mesh_height(arm)
    arm.data.pose_position = "POSE"
    names = []
    for name, fn, length in CLIPS + boss_moves.CLIPS + boss_falls.CLIPS:
        before = rig.clamped
        wp.build_clip(rig, name, fn, length)
        names.append(name)
        if rig.clamped > before:
            print("BOSS IK clamp", name, rig.clamped - before)
    arm.animation_data.action = bpy.data.actions[CLIPS[0][0]]
    print("BOSS ANIMS", names, "IK clamped frames:", rig.clamped, "rig.s %.3f" % rig.s, "mesh_h %.3f" % rig.mesh_h)
    return names
