"""Patlayıcı (bloater) klipleri — elle anahtarlanmış anahtar pozlar, kodla yeniden üretilir (7.3).

İmza `swell`: durur, ayaklarını açıp yere çakılır, gövde şişer (spine_01 ölçek anahtarı), kollar şişen
gövdeyle dışa itilir, kafa geriye düşer, ağız açılır; sona doğru gövde titrer (sık, artan genlikli ölçek ve
dönüş anahtarları) ve 0.9 sn'de (son kare) en şiş haldedir = PATLAMA anı (oyun BloatAttack bu anda patlatır).
Ölçek sözleşmesi: yalnız spine_01 ölçeklenir (gövde küresi bu kemiğe ağırlıklı); çocuklarına geçen ölçek
neck_01 ve clavicle_l/r'de 1/k ile geri alınır (kafa ve kollar boyut değiştirmez, yalnız dışa itilir).
Bu dört kemiğin ölçeği her klipte anahtarlanır (tek tip, kesmesiz; glTF/Godot taşır).

Poz çekirdeği, bacak IK'sı ve açı sözleşmesi walker_pose.py'de (iskelet uzayı, derece; X+ öne eğilme,
Y+ sola yatma, Z+ sola dönme). Kollar FK (ölçekli gövdede kol IK'sı kullanılmaz). Döngüler `_Loop` ekli.

Oyun sözleşmesi (s73_design, GAME_PACE sonrası):
  walk   : 1.1 sn döngü, referans hız 1.92 m/sn (oyun boyu 1.75 m'de; model uzayında mesh_h/1.75 ile).
  swell  : 0.9 sn, patlama anı = 0.9 sn (son kare). idle 2.0 (döngü), stagger 0.4.
  death_a 1.6 ve spawn 1.2: bloater_falls.py.
"""
import math

import bpy

import walker_pose as wp
from walker_pose import cyc, merge, track

TAU = math.tau
SCALE_BONES = ("spine_01", "neck_01", "clavicle_l", "clavicle_r")

# --- yürüyüş (paytak, ağır) -------------------------------------------------------
GAME_SPEED = 1.92         # = 2.4 * GAME_PACE (m/sn)
GAME_HEIGHT = 1.75        # = EnemyData bloater height
WALK_FRAMES = 33
WALK_CYCLE = WALK_FRAMES / wp.FPS      # 1.1 sn, iki adım
DUTY = 0.36               # basış payı: adım uzun, kısa bir uçuş evresi (ağır sıçrayış)
R_STANCE = (0.0, DUTY)
L_STANCE = (0.5, 0.5 + DUTY)
CENTER = -0.09            # basış ortası dinlenmeye göre önde (m, rig.s ile): arka bacak erimi kalsın
LIFT = 0.10
CROUCH = 0.10
SPREAD = 0.045            # ayaklar dışa (paytak)
SWAY = 0.075              # yana yük aktarma (m)
LIFTOFF_FOLLOW = 0.9


def walk_speed(rig):
    h = getattr(rig, "mesh_h", None) or GAME_HEIGHT
    return GAME_SPEED * h / GAME_HEIGHT


def _hermite(p0, p1, m0, m1, u):
    u2, u3 = u * u, u * u * u
    return (2 * u3 - 3 * u2 + 1) * p0 + (u3 - 2 * u2 + u) * m0 + (-2 * u3 + 3 * u2) * p1 + (u3 - u2) * m1


def _ease(u, keys):
    return track(u, [(k, {"v": {"x": val}}) for k, val in keys])["v"]["x"]


def foot_track(phi, rng, rig):
    v = walk_speed(rig) * WALK_CYCLE
    dur = rng[1] - rng[0]
    reach = v * dur
    c = CENTER * rig.s
    u = ((phi - rng[0]) % 1.0) / dur
    if u <= 1.0:
        return c - reach / 2 + reach * u, u, True
    w = (u - 1.0) * dur / (1.0 - dur)
    m = v * (1.0 - dur)
    return _hermite(c + reach / 2, c - reach / 2, LIFTOFF_FOLLOW * m, m, w), w, False


def walk_feet(phi, rig):
    feet = {}
    for side, rng, sx in (("r", R_STANCE, -1.0), ("l", L_STANCE, 1.0)):
        y, u, down = foot_track(phi, rng, rig)
        if down:      # düz tabanla tok basar, sonra topuk kalkıp parmaktan iter
            pitch, lift = _ease(u, [(0.0, -6.0), (0.10, 0.0), (0.55, 0.0), (0.80, 10.0), (1.0, 24.0)]), 0.0
        else:         # ayak dışa savrulup (paytak yay) öne gelir
            pitch = _ease(u, [(0.0, 24.0), (0.2, 40.0), (0.45, 22.0), (0.75, -2.0), (1.0, -6.0)])
            lift = LIFT * rig.s * math.sin(math.pi * u) ** 0.7
        arc = 0.035 * rig.s * math.sin(math.pi * u) if not down else 0.0
        feet[side] = (y, pitch, lift, sx * (SPREAD * rig.s + arc))
    return feet["l"], feet["r"]


def walk(t, rig):
    phi = (t / WALK_CYCLE) % 1.0
    s = rig.s
    # basış 0 (sağ) ve 0.5 (sol): ayak inince gövde çöker ve göbek sarsılır; basış ortasında kalkar
    dz = cyc(phi, [(0.03, -0.040), (0.24, 0.020), (0.53, -0.040), (0.74, 0.020)])
    sway = cyc(phi, [(0.0, -0.3), (0.2, -1.0), (0.5, 0.3), (0.7, 1.0)]) * SWAY
    roll = cyc(phi, [(0.05, -8.0), (0.30, -1.0), (0.55, 8.0), (0.80, 1.0)])     # basan yana yatar
    yaw = cyc(phi, [(0.0, 8.0), (0.25, 0.0), (0.5, -8.0), (0.75, 0.0)])
    jiggle = cyc(phi - 0.06, [(0.0, 0.0), (0.06, -1.0), (0.16, 0.6), (0.30, 0.0),
                              (0.5, 0.0), (0.56, -1.0), (0.66, 0.6), (0.80, 0.0)])
    l_foot, r_foot = walk_feet(phi, rig)
    pose = {
        "pelvis": {"loc": (sway * s, 0.0, (dz - CROUCH) * s), "rot": (2.0, roll, yaw)},
        "spine_01": {"rot": (3.0 + 2.5 * jiggle, -0.5 * roll, -0.7 * yaw), "scale": 1.0 + 0.012 * jiggle},
        "spine_02": {"rot": (-2.0 - 2.0 * jiggle, -0.3 * roll, -0.2 * yaw)},
        "spine_03": {"rot": (-1.0, -0.2 * roll, 0.0)},
        "neck_01": {"rot": (4.0 - 2.0 * jiggle, 0.4 * roll, 0.3 * yaw)},
        "Head": {"rot": (-2.0 + 4.0 * jiggle, 0.3 * roll, 0.4 * yaw)},
        "jaw": {"rot": (cyc(phi, [(0.05, 16.0), (0.3, 8.0), (0.55, 16.0), (0.8, 8.0)]), 0.0, 0.0)},
        "ik_l": {"foot": l_foot},
        "ik_r": {"foot": r_foot},
    }
    for sd, ph, sy in (("l", 0.5, 1.0), ("r", 0.0, -1.0)):   # kollar göbeğin yanında dışa savrulur
        sw = cyc(phi - 0.10 + ph, [(0.0, -14.0), (0.5, 14.0)])
        flap = cyc(phi - 0.08, [(0.0, -6.0), (0.25, 2.0), (0.5, -6.0), (0.75, 2.0)])
        pose["clavicle_" + sd] = {"rot": (0.0, sy * 0.3 * roll, 0.0)}
        pose["upperarm_" + sd] = {"rot": (sw, sy * (-6.0 + flap), 0.0)}
        pose["lowerarm_" + sd] = {"rot": (cyc(phi - 0.25 + ph, [(0.0, -12.0), (0.5, 8.0)]), 0.0, 0.0)}
        pose["hand_" + sd] = {"rot": (cyc(phi - 0.35 + ph, [(0.0, -10.0), (0.5, 10.0)]), 0.0, 0.0)}
    return pose


def side(pose, base, rot_l, **extra):
    pose[base + "_l"] = {"rot": tuple(rot_l), **extra}
    pose[base + "_r"] = {"rot": (rot_l[0], -rot_l[1], -rot_l[2]), **extra}
    return pose


def stand(rig, crouch=0.02, spread=0.0):
    sp = spread * rig.s
    return {"pelvis": {"loc": (0.0, 0.0, -crouch * rig.s), "rot": (0.0, 0.0, 0.0)},
            "ik_l": {"foot": (0.0, 0.0, 0.0, sp)}, "ik_r": {"foot": (0.0, 0.0, 0.0, -sp)}}


def bloat(pose, k):
    """Gövde ölçeği k: spine_01 şişer, kafa ve kollar 1/k ile eski boyunda kalır."""
    pose.setdefault("spine_01", {})["scale"] = k
    return pose


# --- bekleme ------------------------------------------------------------------------------
IDLE_CYCLE = 2.0


def idle(t, rig):
    """Ağır, hırıltılı nefes: göbek kabarıp iner (ölçek), kafa sallanır, kollar sarkık salınır."""
    phi = (t / IDLE_CYCLE) % 1.0
    w = TAU * phi
    breath = cyc(phi, [(0.0, 0.0), (0.40, 1.0), (0.55, 0.9), (0.85, 0.0)])
    pose = merge(stand(rig, 0.02 + 0.01 * (1 - breath)), {
        "pelvis": {"loc": (0.006 * rig.s * math.sin(w), 0.0, -(0.02 + 0.01 * (1 - breath)) * rig.s),
                   "rot": (0.0, 1.5 * math.sin(w), 2.0 * math.sin(w))},
        "spine_01": {"rot": (1.0 - 2.0 * breath, -0.8 * math.sin(w), 0.0), "scale": 1.0 + 0.03 * breath},
        "spine_02": {"rot": (-2.0 * breath, 0.0, -1.0 * math.sin(w))},
        "neck_01": {"rot": (2.0 * breath, 0.0, 0.0)},
        "Head": {"rot": (2.0 - 6.0 * breath, 3.0 * math.sin(w + 0.6), 5.0 * math.sin(w + 0.3))},
        "jaw": {"rot": (10.0 + 14.0 * (1.0 - breath), 0.0, 0.0)},
    })
    for sd, ph, sy in (("l", 0.0, 1.0), ("r", 1.3, -1.0)):
        pose["upperarm_" + sd] = {"rot": (4.0 * math.sin(w + ph), sy * -3.0 * breath, 0.0)}
        pose["lowerarm_" + sd] = {"rot": (-6.0 + 5.0 * math.sin(w + ph - 0.6), 0.0, 0.0)}
        pose["hand_" + sd] = {"rot": (8.0 * math.sin(w + ph - 1.2), 0.0, 0.0)}
    return pose


# --- imza: şişme ---------------------------------------------------------------------------
SWELL_TIME = 0.9          # = bloat_prime_time; patlama anı son kare (27)
SWELL_PEAK = 1.30


def _brace(rig, k, arch, arms, jaw, jit=0.0):
    """Ayaklar geniş, dizler kırık; gövde geriye gerilir; kollar dışa açılır; titreme payı `jit` (derece)."""
    s = rig.s
    pose = merge(stand(rig, 0.07, 0.07), {
        "pelvis": {"loc": (0.0, 0.03 * s, -0.07 * s), "rot": (-0.3 * arch, 0.6 * jit, 0.4 * jit)},
        "spine_01": {"rot": (-0.4 * arch, -0.8 * jit, 0.5 * jit)},
        "spine_02": {"rot": (-0.4 * arch, jit, 0.0)},
        "spine_03": {"rot": (-0.2 * arch, 0.0, 0.0)},
        "neck_01": {"rot": (-0.3 * arch, -jit, 0.0)},
        "Head": {"rot": (-0.6 * arch, 1.5 * jit, -jit)},
        "jaw": {"rot": (jaw + 1.5 * abs(jit), 0.0, 0.0)},
    })
    side(pose, "clavicle", (0.0, -0.25 * arms, 0.0))
    side(pose, "upperarm", (-0.2 * arms, -arms, 0.0))
    side(pose, "lowerarm", (-0.5 * arms, 0.0, 0.0))
    side(pose, "hand", (-0.6 * arms + 2.0 * jit, 0.0, 0.0))
    return bloat(pose, k)


def swell(t, rig):
    """0 duruş → 0.15 yere çakılır (ayaklar açık) → 0.45 şişer, geriye gerilir, kollar açılır →
    0.6'dan sonra artan titreme → 0.9 en şiş an (PATLAMA)."""
    keys = [(0.0, bloat(stand(rig), 1.0)), (0.15, _brace(rig, 1.03, 4.0, 10.0, 18.0)),
            (0.45, _brace(rig, 1.14, 12.0, 22.0, 30.0)), (0.60, _brace(rig, 1.19, 15.0, 26.0, 34.0))]
    # titreme: elle verilmiş sık anahtarlar (ölçek ileri-geri, yana sarsılma), genlik artar
    shakes = [(0.633, 1.17, 3.0), (0.667, 1.23, -3.5), (0.700, 1.20, 4.0), (0.733, 1.26, -4.5),
              (0.767, 1.22, 5.0), (0.800, 1.28, -5.5), (0.833, 1.24, 6.0), (0.867, 1.29, -6.0)]
    for tk, k, jit in shakes:
        keys.append((tk, _brace(rig, k, 16.0 + 4.0 * (tk - 0.6) / 0.3, 28.0, 36.0, jit)))
    keys.append((SWELL_TIME, _brace(rig, SWELL_PEAK, 20.0, 30.0, 40.0, 0.0)))
    return track(t, keys)


# --- tepki ----------------------------------------------------------------------------------
STAGGER_TIME = 0.4


def stagger(t, rig):
    """Göbeğe darbe: gövde geri sarsılır, göbek içe çöker ve dalgalanır (ölçek), kollar açılır."""
    s = rig.s
    hit = merge(stand(rig, 0.03), {
        "pelvis": {"loc": (0.0, 0.03 * s, -0.03 * s), "rot": (-4.0, 2.0, -4.0)},
        "spine_01": {"rot": (-5.0, 0.0, 0.0), "scale": 0.96},
        "spine_02": {"rot": (-4.0, 3.0, 0.0)},
        "Head": {"rot": (-14.0, 6.0, 5.0)}, "jaw": {"rot": (28.0, 0.0, 0.0)},
    })
    side(hit, "upperarm", (-10.0, -12.0, 0.0))
    side(hit, "lowerarm", (-12.0, 0.0, 0.0))
    wobble = merge(stand(rig, 0.03), {"spine_01": {"rot": (3.0, 0.0, 0.0), "scale": 1.035},
                                      "Head": {"rot": (5.0, -2.0, 0.0)}, "jaw": {"rot": (14.0, 0.0, 0.0)}})
    settle = merge(stand(rig, 0.02), {"spine_01": {"rot": (0.0, 0.0, 0.0), "scale": 0.99}})
    return track(t, [(0.0, bloat(stand(rig), 1.0)), (0.07, hit), (0.19, wobble), (0.29, settle),
                     (STAGGER_TIME, bloat(stand(rig), 1.0))])


CLIPS = [("idle_Loop", idle, IDLE_CYCLE), ("walk_Loop", walk, WALK_CYCLE), ("swell", swell, SWELL_TIME),
         ("stagger", stagger, STAGGER_TIME)]


# --- anahtarlama (ölçekli) ----------------------------------------------------------------

def apply(rig, pose, frame):
    """walker_pose.apply + ölçek anahtarları (SCALE_BONES her karede)."""
    k = pose.get("spine_01", {}).get("scale", 1.0)
    clean = {n: {c: v for c, v in ch.items() if c != "scale"} for n, ch in pose.items()}
    wp.apply(rig, clean, frame)
    for name in SCALE_BONES:
        pb = rig.arm.pose.bones[name]
        f = k if name == "spine_01" else 1.0 / k
        pb.scale = (f, f, f)
        pb.keyframe_insert("scale", frame=frame, group=pb.name)


def build_clip(rig, name, fn, length):
    arm = rig.arm
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    arm.animation_data.action = action
    last = round(length * wp.FPS)
    for f in range(last + 1):
        apply(rig, fn(f / wp.FPS, rig), f)
    action.use_frame_range = True
    action.frame_start, action.frame_end = 0, last
    for pb in arm.pose.bones:
        pb.scale = (1.0, 1.0, 1.0)
    return action


def mesh_height(arm):
    for obj in bpy.data.objects:
        if obj.type == "MESH" and any(m.type == "ARMATURE" and m.object == arm for m in obj.modifiers):
            mw = arm.matrix_world.inverted() @ obj.matrix_world
            return max((mw @ v.co).z for v in obj.data.vertices)
    return 0.0


def build_all(arm) -> list:
    import importlib
    import bloater_falls
    importlib.reload(bloater_falls)
    bpy.context.scene.render.fps = wp.FPS
    bpy.context.scene.render.fps_base = 1.0
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.data.pose_position = "REST"
    rig = wp.Rig(arm)
    rig.mesh_h = mesh_height(arm)
    arm.data.pose_position = "POSE"
    names = []
    for name, fn, length in CLIPS + bloater_falls.CLIPS:
        build_clip(rig, name, fn, length)
        names.append(name)
    arm.animation_data.action = bpy.data.actions[CLIPS[0][0]]
    print("BLOATER ANIMS", names, "IK clamped frames:", rig.clamped, "rig.s %.3f" % rig.s,
          "mesh_h %.3f" % rig.mesh_h)
    return names
