"""Zırhlı klipleri — elle anahtarlanmış anahtar pozlar, kodla yeniden üretilir (7.3).

İmza: kalkanı önde tutarak ağır, kambur yürüyüş; saldırı = kalkanla omuz darbesi (sol omuz öne yüklenir).
Poz çekirdeği, IK ve açı sözleşmesi walker_pose.py'de (iskelet uzayı, derece; X+ öne eğilme, Y+ sola
yatma, Z+ sola dönme). Kalkan kolu ("arm_l") her klipte IK ile: bilek hedefi göğüs çerçevesinde dinlenme
yerinden kayma olarak verilir (kalkan gövdeyle döner, önde kalır). Sağ kol FK.
Döngüler `_Loop` ekiyle (Godot eki atar: `idle`, `walk`).
Değerler kemik ve ağ ölçülerek bulundu (armored_check.py: basan ayağın kayması, vuruş anında kalkan
yüzünün ileri yeri, ağın en alt noktası, IK sınırı) ve kare özetiyle yinelendi.

Oyun sözleşmesi (s73_design.md §1; GAME_PACE sonrası):
  walk   : 1.0 sn döngü, referans hız WALK_REF_SPEED = 1.6 m/sn (oyun gerçek hız / ref ile oynatır).
  attack : 1.4 sn; 0.0–0.7 hazırlık (kalkanı göğse çek, sol omzu geri bük, çömel → ileri adım),
           VURUŞ 0.7 sn (sol ayak önde basmış, kalkan önde, gövde öne yüklenmiş), 0.7–1.4 toparlanma.
  stagger: 0.4 sn. idle 2.0 sn döngü. Ölüm ve doğma: armored_falls.py.
"""
import math

import bpy
from mathutils import Vector

import walker_pose as wp
from walker_pose import cyc, merge, track

TAU = math.tau

# --- yürüyüş ---------------------------------------------------------------------
WALK_REF_SPEED = 1.6
WALK_FRAMES = 30
WALK_CYCLE = WALK_FRAMES / wp.FPS
DUTY = 0.52               # basış payı
R_STANCE = (0.0, DUTY)
L_STANCE = (0.5, 0.5 + DUTY)
LIFT = 0.085              # salınımda ayak kalkışı (m)
CROUCH = 0.10             # kalkanın arkasına sinmiş: dizler kırık (m)
LEAN = 10.0               # pelvis öne eğimi (derece)
SWAY = 0.035
LIFTOFF_FOLLOW = 0.9       # salınım başında ayak basıştaki hızla devam eder (kalkışta kayma yok)


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
    for side, rng, dx in (("r", R_STANCE, -0.012), ("l", L_STANCE, 0.012)):
        y, u, down = foot_track(phi, rng)
        if down:
            pitch, lift = _ease(u, [(0.0, -9.0), (0.12, 0.0), (0.60, 0.0), (0.86, 12.0), (1.0, 28.0)]), 0.0
        else:
            pitch = _ease(u, [(0.0, 28.0), (0.35, 16.0), (0.75, -4.0), (1.0, -9.0)])
            lift = LIFT * rig.s * math.sin(math.pi * u) ** 1.3 * (1.0 - 0.2 * u)
        feet[side] = (y, pitch, lift, dx * rig.s)
    return feet["l"], feet["r"]


def shield(pose, dx=0.0, dy=0.0, dz=0.0, out=0.0, rot=(0.0, 0.0, 0.0)):
    """Kalkan kolu: bilek dinlenme yerinden kayma (göğüs çerçevesi, m); rot kalkanın göğse göre dönüşü
    (derece). Kalkan hand_l'ye bağlı; el dönüşü her karede çözülür ki kalkan göğüsle aynı yöne baksın
    (kol uzayıp kısalınca önkolun burulması kalkanı yan çevirmesin)."""
    pose["arm_l"] = {"hand": (dx, dy, dz), "out": out}
    pose["_shield"] = {"rot": tuple(rot)}
    return pose


def lock_shield(rig, pose):
    """IK sonrası: hand_l = (önkolun mutlak dönüşü)^-1 · göğüs · kalkan dönüşü."""
    lock = pose.pop("_shield", None)
    if lock is None or "lowerarm_l" not in pose:
        return pose
    q03, _h = wp._fk_chest(rig, pose)
    q_l = q03
    for bone in ("clavicle_l", "upperarm_l", "lowerarm_l"):
        q_l = q_l @ wp._q(pose.get(bone, {}).get("rot", (0, 0, 0)))
    q_h = q_l.inverted() @ q03 @ wp._q(lock["rot"])
    pose["hand_l"] = {"rot": tuple(math.degrees(a) for a in q_h.to_euler("XYZ"))}
    return pose


def apply(rig, pose, frame):
    """wp.apply + kalkan kilidi (walker_pose'a dokunmadan)."""
    pose = wp.solve_arms(rig, wp.solve_legs(rig, {k: dict(v) for k, v in pose.items()}))
    pose = lock_shield(rig, pose)
    for pb in rig.arm.pose.bones:
        ch = pose.get(pb.name, {})
        rest = rig.rest_q[pb.name]
        pb.rotation_quaternion = rest.inverted() @ wp._q(ch.get("rot", (0, 0, 0))) @ rest
        pb.keyframe_insert("rotation_quaternion", frame=frame, group=pb.name)
        if pb.name == "pelvis":
            pb.location = rest.inverted() @ Vector(ch.get("loc", (0, 0, 0)))
            pb.keyframe_insert("location", frame=frame, group=pb.name)
        else:
            pb.location = (0.0, 0.0, 0.0)
        pb.scale = (1.0, 1.0, 1.0)


def build_clip(rig, name, fn, length):
    """wp.build_clip ile aynı (her kare anahtarlanır, kareler 0'dan), anahtarlama kalkan kilitli apply ile."""
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    rig.arm.animation_data.action = action
    last = round(length * wp.FPS)
    for f in range(last + 1):
        apply(rig, fn(f / wp.FPS, rig), f)
    action.use_frame_range = True
    action.frame_start, action.frame_end = 0, last
    return action


def walk(t, rig):
    phi = (t / WALK_CYCLE) % 1.0
    s = rig.s
    dz = cyc(phi, [(0.04, -0.030), (0.26, 0.012), (0.54, -0.030), (0.76, 0.012)])
    sway = cyc(phi, [(0.0, -0.4), (0.22, -1.0), (0.5, 0.4), (0.72, 1.0)]) * SWAY
    roll = cyc(phi, [(0.05, -4.0), (0.3, 0.0), (0.55, 4.0), (0.8, 0.0)])
    yaw = cyc(phi, [(0.0, 7.0), (0.25, 0.0), (0.5, -7.0), (0.75, 0.0)])
    nod = cyc(phi - 0.1, [(0.04, 3.0), (0.25, -2.0), (0.54, 3.0), (0.75, -2.0)])
    l_foot, r_foot = walk_feet(phi, rig)
    pose = {
        "pelvis": {"loc": (sway * s, 0.0, (dz - CROUCH) * s), "rot": (LEAN, roll, yaw)},
        "spine_01": {"rot": (4.0, -0.4 * roll, -0.7 * yaw)},     # gövde kalkanı önde tutmak için kalçaya karşı döner
        "spine_02": {"rot": (3.0, 0.0, -0.5 * yaw)},
        "spine_03": {"rot": (1.0, 0.0, -0.2 * yaw)},
        "neck_01": {"rot": (-8.0 - 0.5 * nod, 0.0, 0.0)},
        "Head": {"rot": (-5.0 + nod, 0.0, 0.3 * yaw)},
        "jaw": {"rot": (cyc(phi, [(0.0, 8.0), (0.3, 4.0), (0.5, 10.0), (0.8, 4.0)]), 0.0, 0.0)},
        "ik_l": {"foot": l_foot},
        "ik_r": {"foot": r_foot},
    }
    # kalkan önde: adımla hafif iner-kalkar (ağırlık), yana çok az
    shield(pose, 0.01 * math.sin(TAU * phi) * s, -0.02 * s, cyc(phi, [(0.06, -0.022), (0.3, 0.008),
                                                                       (0.56, -0.022), (0.8, 0.008)]) * s)
    sw = cyc(phi - 0.12, [(0.0, -14.0), (0.5, 14.0)])               # sağ kol sol bacakla
    pose["upperarm_r"] = {"rot": (-LEAN - 4.0 + sw, -4.0, 0.0)}
    pose["lowerarm_r"] = {"rot": (0.7 * cyc(phi - 0.25, [(0.0, -10.0), (0.5, 14.0)]), 0.0, 0.0)}
    pose["hand_r"] = {"rot": (cyc(phi - 0.35, [(0.0, -8.0), (0.5, 8.0)]), 0.0, 0.0)}
    return pose


def stand(rig, crouch=0.04):
    return {"pelvis": {"loc": (0.0, 0.0, -crouch * rig.s), "rot": (4.0, 0.0, 0.0)},
            "ik_l": {"foot": (0.0, 0.0, 0.0, 0.0)}, "ik_r": {"foot": (0.0, 0.0, 0.0, 0.0)}}


def guard(rig, crouch=0.04):
    return shield(stand(rig, crouch))


IDLE_CYCLE = 2.0


def idle(t, rig):
    """Kalkanın arkasında nefes: göğüs kalkar, kalkan nefesle iner-kalkar, kafa kalkanın üstünden bakar."""
    phi = (t / IDLE_CYCLE) % 1.0
    w = TAU * phi
    s = rig.s
    breath = cyc(phi, [(0.0, 0.0), (0.38, 1.0), (0.52, 0.9), (0.85, 0.0)])
    pose = merge(stand(rig, 0.05 + 0.01 * breath), {
        "pelvis": {"loc": (0.006 * s * math.sin(w), 0.0, -(0.05 + 0.01 * (1 - breath)) * s),
                   "rot": (5.0, 1.0 * math.sin(w), 1.5 * math.sin(w))},
        "spine_01": {"rot": (2.0 - 1.5 * breath, -0.5 * math.sin(w), 0.0)},
        "spine_02": {"rot": (2.0 - 2.5 * breath, 0.0, -1.0 * math.sin(w))},
        "spine_03": {"rot": (-2.0 * breath, 0.0, 0.0)},
        "neck_01": {"rot": (-4.0 + 1.5 * breath, 0.0, 0.0)},
        "Head": {"rot": (-4.0 + 3.0 * breath, 2.0 * math.sin(w + 0.6), 5.0 * math.sin(w + 0.3))},
        "jaw": {"rot": (6.0 + 9.0 * (1.0 - breath), 0.0, 0.0)},
    })
    shield(pose, 0.0, -0.01 * s, (0.012 * breath - 0.006) * s)
    pose["upperarm_r"] = {"rot": (3.0 * math.sin(w + 1.1), 0.0, 0.0)}
    pose["lowerarm_r"] = {"rot": (4.0 * math.sin(w + 0.5), 0.0, 0.0)}
    pose["hand_r"] = {"rot": (6.0 * math.sin(w - 0.1), 0.0, 0.0)}
    return pose


# --- kalkan darbesi ------------------------------------------------------------------
HIT_TIME = 0.7            # = attack_windup / attack_anim_hit_time (EnemyData), vuruş karesi 21
ATTACK_TIME = 1.4
STEP = 0.36               # vuruşta sol ayak öne (m, rig.s ile)
DRIVE = 0.22              # vuruşta pelvis öne (m)
PUSH = 0.20               # vuruşta kalkan göğüs çerçevesinde öne (m)


def _coil(rig, k=1.0):
    """Hazırlık: çömel, sol omzu geri bük (gövde sola döner), kalkanı göğse çek, kafa kalkanın arkasına."""
    s = rig.s
    pose = merge(stand(rig, 0.10 + 0.06 * k), {
        "pelvis": {"loc": (0.0, 0.06 * k * s, -(0.10 + 0.06 * k) * s), "rot": (8.0, -2.0 * k, 12.0 * k)},
        "spine_01": {"rot": (4.0, 0.0, 8.0 * k)}, "spine_02": {"rot": (4.0, 0.0, 6.0 * k)},
        "spine_03": {"rot": (2.0, 0.0, 2.0 * k)},
        "neck_01": {"rot": (6.0 * k, 0.0, -6.0 * k)}, "Head": {"rot": (4.0 * k, 0.0, -10.0 * k)},
        "jaw": {"rot": (6.0, 0.0, 0.0)},
        "ik_r": {"foot": (0.10 * k * s, 6.0 * k, 0.0, 0.0)},
    })
    shield(pose, 0.0, 0.04 * k * s, 0.02 * k * s, out=0.1, rot=(0.0, 0.0, -4.0 * k))
    pose["upperarm_r"] = {"rot": (-18.0 * k, -10.0 * k, 0.0)}
    pose["lowerarm_r"] = {"rot": (-30.0 * k, 0.0, 0.0)}
    return pose


def _bash(rig, follow=0.0):
    """Vuruş: sol ayak önde basmış, gövde öne yüklenmiş ve sağa dönmüş (sol omuz önde), kalkan önde."""
    s = rig.s
    pose = merge(stand(rig, 0.16), {
        "pelvis": {"loc": (0.02 * s, -(DRIVE + 0.03 * follow) * s, -0.16 * s), "rot": (20.0 + 3 * follow, 3.0, -16.0)},
        "spine_01": {"rot": (10.0 + 2 * follow, 0.0, -10.0)}, "spine_02": {"rot": (6.0, 0.0, -6.0)},
        "spine_03": {"rot": (2.0, 0.0, 0.0)},
        "neck_01": {"rot": (-16.0, 0.0, 6.0)}, "Head": {"rot": (-12.0, 0.0, 10.0)},
        "jaw": {"rot": (22.0, 0.0, 0.0)},
        "ik_l": {"foot": (-STEP * s, -6.0, 0.0, 0.03 * s)},
        "ik_r": {"foot": (0.12 * s, 30.0, 0.0, -0.02 * s)},
    })
    shield(pose, -0.02 * s, -(PUSH + 0.03 * follow) * s, 0.02 * s, out=0.15, rot=(-30.0, 0.0, 10.0))   # göğüs öne yüklenir, kalkan dik kalır
    pose["upperarm_r"] = {"rot": (28.0, -14.0, 0.0)}
    pose["lowerarm_r"] = {"rot": (-24.0, 0.0, 0.0)}
    return pose


def _lunge(rig):
    """Vuruştan hemen önce: sol ayak havada önde, gövde ileri atılıyor."""
    s = rig.s
    pose = merge(_bash(rig), {
        "pelvis": {"loc": (0.01 * s, -0.10 * s, -0.12 * s), "rot": (16.0, 1.0, -6.0)},
        "ik_l": {"foot": (-0.22 * s, -14.0, 0.07 * s, 0.02 * s)},
        "ik_r": {"foot": (0.06 * s, 12.0, 0.0, -0.01 * s)},
    })
    shield(pose, 0.0, -0.06 * s, 0.04 * s, out=0.12, rot=(-22.0, 0.0, 6.0))
    return pose


def attack(t, rig):
    """0 duruş → 0.35 kıvrılmış hazırlık → 0.55 ileri atılış → 0.7 VURUŞ → 0.82 itiş sonu → 1.4 duruş."""
    s = rig.s
    back = merge(_bash(rig, 1.0), {"pelvis": {"loc": (0.0, -0.14 * s, -0.12 * s), "rot": (12.0, 1.0, -8.0)},
                                   "ik_l": {"foot": (-0.20 * s, 0.0, 0.0, 0.02 * s)},
                                   "ik_r": {"foot": (0.05 * s, 6.0, 0.0, 0.0)}})
    shield(back, 0.0, -0.06 * s, 0.0, rot=(-16.0, 0.0, 4.0))
    return track(t, [(0.0, guard(rig)), (0.22, _coil(rig, 0.8)), (0.38, _coil(rig, 1.0)), (0.56, _lunge(rig)),
                     (HIT_TIME, _bash(rig)), (0.82, _bash(rig, 1.0)), (1.08, back), (ATTACK_TIME, guard(rig))])


# --- tepki ------------------------------------------------------------------------------
STAGGER_TIME = 0.4


def stagger(t, rig):
    """Kalkana darbe: kalkan göğse ve yukarı çarpar, gövde ve kafa geri, sağ kol açılır; ayaklar yerinde."""
    s = rig.s
    hit = merge(stand(rig, 0.06), {
        "pelvis": {"loc": (0.0, 0.05 * s, -0.06 * s), "rot": (-2.0, 2.0, 4.0)},
        "spine_01": {"rot": (-5.0, 0.0, 3.0)}, "spine_02": {"rot": (-6.0, 2.0, 0.0)},
        "Head": {"rot": (-16.0, 6.0, -6.0)}, "jaw": {"rot": (20.0, 0.0, 0.0)},
    })
    shield(hit, 0.0, 0.05 * s, 0.04 * s, out=0.1, rot=(-12.0, 0.0, 6.0))
    hit["upperarm_r"] = {"rot": (-10.0, -14.0, 0.0)}
    hit["lowerarm_r"] = {"rot": (-10.0, 0.0, 0.0)}
    settle = merge(guard(rig, 0.06), {"spine_01": {"rot": (4.0, 0.0, 0.0)}, "Head": {"rot": (3.0, -2.0, 0.0)}})
    return track(t, [(0.0, guard(rig)), (0.08, hit), (0.22, settle), (STAGGER_TIME, guard(rig))])


CLIPS = [("idle_Loop", idle, IDLE_CYCLE), ("walk_Loop", walk, WALK_CYCLE), ("attack", attack, ATTACK_TIME),
         ("stagger", stagger, STAGGER_TIME)]


def mesh_height(arm):
    for obj in bpy.data.objects:
        if obj.type == "MESH" and any(m.type == "ARMATURE" and m.object == arm for m in obj.modifiers):
            mw = arm.matrix_world.inverted() @ obj.matrix_world
            return max((mw @ v.co).z for v in obj.data.vertices)
    return 0.0


def build_all(arm):
    import importlib
    import armored_falls
    importlib.reload(armored_falls)
    bpy.context.scene.render.fps = wp.FPS
    bpy.context.scene.render.fps_base = 1.0
    if arm.animation_data is None:
        arm.animation_data_create()
    rig = wp.Rig(arm)
    names = []
    for name, fn, length in CLIPS + armored_falls.CLIPS:
        build_clip(rig, name, fn, length)
        names.append(name)
    arm.animation_data.action = bpy.data.actions[CLIPS[0][0]]
    print("ARMORED ANIMS", names, "IK clamped frames:", rig.clamped, "rig.s %.3f" % rig.s)
    return names
