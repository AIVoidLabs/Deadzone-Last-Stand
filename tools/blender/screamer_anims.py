"""Çığlıkçı klipleri — elle anahtarlanmış, kodla yeniden üretilir (7.3).

İmza `scream`: önce içine kapanır (nefes toplar, baş öne, kollar göğse), sonra baş geriye atılır, göğüs
şişer (omurga geriye kavislenir, omuzlar geride), kollar yana açılır, çene sonuna dek düşer; tepe boyunca
(0.55–1.0 sn) titreyerek öne doğru çığlık atar, sonra toparlanır.
Poz çekirdeği, IK ve açı sözleşmesi walker_pose.py'de (iskelet uzayı, derece; X+ öne eğilme / sarkan
uzuvda geriye savrulma, Y+ sola yatma, Z+ sola dönme). Kol hedefleri iskelet (dünya) uzayında bilek konumu
olarak verilir (world_hands, tasarım ölçüsünde metre × rig.k), IK ile çözülüp dönüş olarak yazılır.
Döngü klipleri `_Loop` ekiyle: Godot eki atar, adlar `idle`, `walk` olur. Değerler kemik ve ağ ölçülerek
bulundu (screamer_check.py: basan ayağın kayması, çene açıklığı, ağın en alt noktası, IK sınırı).

Oyun sözleşmesi (s73_design, GAME_PACE 0.8 sonrası):
  idle   : 2.0 sn döngü.
  walk   : 1.0 sn döngü, referans hız WALK_REF_SPEED = 1.76 m/sn (model ölçeği 1, boy ~1.95 m).
  scream : 1.2 sn; hazırlık 0–0.40, ÇIĞLIK TEPESİ 0.55–1.0 (çene tam açık, kollar yana), toparlanma 1.0–1.2.
  stagger: 0.33 sn. Ölüm ve doğma: screamer_falls.py.
"""
import math

from mathutils import Vector

import walker_pose as wp
from walker_pose import cyc, merge, track

TAU = math.tau
LEG0 = 0.94               # tasarım bacak boyu (build_screamer, ölçek 1): kol hedefleri bununla ölçeklenir

# --- yürüyüş ---------------------------------------------------------------------
WALK_REF_SPEED = 1.76
WALK_FRAMES = 30
WALK_CYCLE = WALK_FRAMES / wp.FPS
DUTY = 0.54
R_STANCE = (0.0, DUTY)
L_STANCE = (0.5, 0.5 + DUTY)
LIFT = 0.10
CROUCH = 0.075            # yürürken pelvis alçak (m): uzun adımda bacak yetişsin
LEAN = 7.0
SWAY = 0.022
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
    for side, rng, dx in (("r", R_STANCE, -0.01), ("l", L_STANCE, 0.01)):
        y, u, down = foot_track(phi, rng)
        if down:
            pitch, lift = _ease(u, [(0.0, -10.0), (0.12, 0.0), (0.60, 0.0), (0.86, 14.0), (1.0, 30.0)]), 0.0
        else:
            pitch = _ease(u, [(0.0, 30.0), (0.35, 20.0), (0.75, -4.0), (1.0, -10.0)])
            lift = LIFT * rig.s * math.sin(math.pi * u) ** 1.3 * (1.0 - 0.2 * u)
        feet[side] = (y, pitch, lift, dx * rig.s)
    return feet["l"], feet["r"]


def walk(t, rig):
    """Uzun, sarsak adımlar: gövde dik ama boyun öne uzanmış; kafa her basışta kuş gibi öne itilir
    (boyun ileri-geri), uzun kollar gevşek ve gecikmeli sallanır, eller dizlerin hizasında sarkar."""
    phi = (t / WALK_CYCLE) % 1.0
    s = rig.s
    dz = cyc(phi, [(0.04, -0.032), (0.27, 0.014), (0.54, -0.032), (0.77, 0.014)])
    sway = cyc(phi, [(0.0, -0.6), (0.25, -1.0), (0.5, 0.6), (0.75, 1.0)]) * SWAY
    roll = cyc(phi, [(0.06, -4.0), (0.3, 0.0), (0.56, 4.0), (0.8, 0.0)])
    yaw = cyc(phi, [(0.0, 6.0), (0.25, 0.0), (0.5, -6.0), (0.75, 0.0)])
    peck = cyc(phi, [(0.02, 7.0), (0.20, -4.0), (0.52, 7.0), (0.70, -4.0)])   # kuş gibi baş itişi
    l_foot, r_foot = walk_feet(phi, rig)
    pose = {
        "pelvis": {"loc": (sway * s, 0.0, (dz - CROUCH) * s), "rot": (LEAN, roll, yaw)},
        "spine_01": {"rot": (2.0, -0.4 * roll, -0.5 * yaw)},
        "spine_02": {"rot": (2.0, -0.3 * roll, -0.5 * yaw)},
        "spine_03": {"rot": (1.0, 0.0, -0.3 * yaw)},
        "neck_01": {"rot": (peck, 0.0, 0.3 * yaw)},
        "Head": {"rot": (-LEAN - 1.4 * peck, -0.4 * roll, -0.3 * yaw)},
        "jaw": {"rot": (cyc(phi, [(0.0, -4.0), (0.3, 4.0), (0.5, -2.0), (0.8, 6.0)]), 0.0, 0.0)},
        "ik_l": {"foot": l_foot},
        "ik_r": {"foot": r_foot},
    }
    for sd, off in (("l", 0.0), ("r", 0.5)):
        sw = cyc(phi - 0.16 + off, [(0.0, 16.0), (0.5, -18.0)])     # sol kol sağ bacakla (karşı)
        pose["upperarm_" + sd] = {"rot": (-LEAN * 0.5 + sw, (3.0 if sd == "l" else -3.0), 0.0)}
        pose["lowerarm_" + sd] = {"rot": (-12.0 + 0.5 * cyc(phi - 0.30 + off, [(0.0, 10.0), (0.5, -14.0)]), 0.0, 0.0)}
        pose["hand_" + sd] = {"rot": (cyc(phi - 0.42 + off, [(0.0, 14.0), (0.5, -10.0)]), 0.0, 0.0)}
    return pose


def side(pose, base, rot_l, **extra):
    pose[base + "_l"] = {"rot": tuple(rot_l), **extra}
    pose[base + "_r"] = {"rot": (rot_l[0], -rot_l[1], -rot_l[2]), **extra}
    return pose


def stand(rig, crouch=0.015):
    return {"pelvis": {"loc": (0.0, 0.0, -crouch * rig.s), "rot": (2.0, 0.0, 0.0)},
            "ik_l": {"foot": (0.0, 0.0, 0.0, 0.0)}, "ik_r": {"foot": (0.0, 0.0, 0.0, 0.0)}}


IDLE_CYCLE = 2.0


def idle(t, rig):
    """Sığ, hırıltılı nefes; boyun yavaşça sağa sola sallanır, baş kuş gibi küçük sarsıntılarla döner,
    çene nefesle açılıp kapanır, uzun parmaklar seğirir."""
    phi = (t / IDLE_CYCLE) % 1.0
    w = TAU * phi
    breath = cyc(phi, [(0.0, 0.0), (0.35, 1.0), (0.50, 0.9), (0.80, 0.0)])
    jerk = cyc(phi, [(0.0, 0.0), (0.58, 0.0), (0.62, 1.0), (0.80, 1.0), (0.86, 0.0)])   # ani baş dönüşü
    pose = merge(stand(rig, 0.02), {
        "pelvis": {"loc": (0.008 * rig.s * math.sin(w), 0.0, -(0.02 + 0.006 * breath) * rig.s),
                   "rot": (2.0, 1.2 * math.sin(w), 1.0 * math.sin(w))},
        "spine_01": {"rot": (1.0 - 1.0 * breath, -0.6 * math.sin(w), 0.0)},
        "spine_02": {"rot": (1.0 - 2.5 * breath, 0.0, -0.8 * math.sin(w))},
        "spine_03": {"rot": (-2.0 * breath, 0.0, 0.0)},
        "neck_01": {"rot": (2.0 + 2.0 * breath, 3.0 * math.sin(w + 0.4), 4.0 * math.sin(w))},
        "Head": {"rot": (-3.0 - 3.0 * breath, 2.0 * math.sin(w + 1.0), 4.0 * math.sin(w + 0.3) + 16.0 * jerk)},
        "jaw": {"rot": (-6.0 + 12.0 * breath, 0.0, 0.0)},
    })
    side(pose, "clavicle", (0.0, -2.0 * breath, 0.0))
    for sd, ph in (("l", 0.0), ("r", 1.7)):
        pose["upperarm_" + sd] = {"rot": (3.0 * math.sin(w + ph), (2.0 if sd == "l" else -2.0), 0.0)}
        pose["lowerarm_" + sd] = {"rot": (-8.0 + 3.0 * math.sin(w + 0.4 + ph), 0.0, 0.0)}
        pose["hand_" + sd] = {"rot": (6.0 * math.sin(w * 3.0 + ph), 0.0, 0.0)}
    return pose


# --- kol IK yardımcıları ----------------------------------------------------------------

def k_of(rig):
    return rig.leg_len / LEG0


def world_hands(rig, pose, targets, out=0.0):
    """Bilek hedefleri iskelet uzayında (tasarım ölçüsünde m, × k): göğüs çerçevesine çevrilir."""
    q03, h03 = wp._fk_chest(rig, pose)
    inv = q03.inverted()
    k = k_of(rig)
    for sd, t in targets.items():
        rel = inv @ (Vector(t) * k - h03) + rig.head["spine_03"] - rig.head["hand_" + sd]
        pose["arm_" + sd] = {"hand": tuple(rel), "out": out}
    return pose


def both(x, y, z):
    return {"l": (x, y, z), "r": (-x, y, z)}


def rest_arms(pose):
    pose["arm_l"] = {"hand": (0.0, 0.0, 0.0), "out": 0.0}
    pose["arm_r"] = {"hand": (0.0, 0.0, 0.0), "out": 0.0}
    return pose


def _body(rig, crouch, pel, sp1, sp2=(0, 0, 0), sp3=(0, 0, 0), neck=(0, 0, 0), head=(0, 0, 0), jaw=0.0,
          feet=None, loc=(0.0, 0.0)):
    """Gövde anahtarı: pelvis/omurga/boyun/kafa dönüşleri (derece), çömelme (m), ayak hedefleri."""
    s = rig.s
    pose = merge(stand(rig, crouch), {
        "pelvis": {"loc": (loc[0] * s, loc[1] * s, -crouch * s), "rot": pel},
        "spine_01": {"rot": sp1}, "spine_02": {"rot": sp2}, "spine_03": {"rot": sp3},
        "neck_01": {"rot": neck}, "Head": {"rot": head}, "jaw": {"rot": (jaw, 0.0, 0.0)}})
    for sd, f in (feet or {}).items():
        pose["ik_" + sd] = {"foot": (f[0] * s, f[1], f[2] * s, f[3] * s)}
    return pose


# --- çığlık -------------------------------------------------------------------------------
SCREAM_TIME = 1.2
PEAK_START = 0.55
PEAK_END = 1.0
JAW_FULL = 50.0           # dinlenmeye (14°) ek: toplam 64° (screamer_head.JAW_SCREAM_DEG)
SPREAD_WRIST = (0.74, 0.14, 1.50)    # tepe: bilekler omuz hizasında, yana ve hafif geride
FEET = {"l": (0.02, 0.0, 0.0, 0.03), "r": (-0.06, 0.0, 0.0, -0.03)}   # sağ ayak geri, duruş genişler


def _peak(rig, shake=0.0, fwd=0.0):
    """Tepe pozu: omurga geriye kavisli (göğüs şişer), boyun ve kafa geride, çene sonuna dek açık.
    shake: titreme evresi (rad), fwd 0..1: çığlığın öne itilmesi (baş biraz öne gelir)."""
    tr = math.sin(shake)
    tr2 = math.sin(shake * 1.7 + 0.8)
    pose = _body(rig, 0.05, (-4.0 + 3.0 * fwd, 0.0, 0.0), (-8.0 + 2.0 * fwd, 0.0, 0.0),
                 (-9.0 + 3.0 * fwd, 0.6 * tr, 0.0), (-6.0 + 4.0 * fwd, 0.0, 0.0),
                 neck=(-16.0 + 10.0 * fwd + 1.5 * tr, 1.5 * tr2, 0.0),
                 head=(-26.0 + 8.0 * fwd + 2.5 * tr2, 2.5 * tr, 2.0 * tr2),
                 jaw=JAW_FULL + 2.0 * tr, feet=FEET, loc=(0.0, -0.01 - 0.02 * fwd))
    side(pose, "clavicle", (0.0, -4.0, 10.0))       # omuzlar geride ve kalkık (göğüs açılır)
    world_hands(rig, pose, {"l": (SPREAD_WRIST[0], SPREAD_WRIST[1] - 0.04 * fwd, SPREAD_WRIST[2] + 0.012 * tr2),
                            "r": (-SPREAD_WRIST[0], SPREAD_WRIST[1] - 0.04 * fwd, SPREAD_WRIST[2] - 0.012 * tr)},
                out=0.15)
    for sd in ("l", "r"):
        pose["hand_" + sd] = {"rot": (-24.0 + 4.0 * tr, 0.0, 0.0)}     # avuç öne, parmaklar gergin
    return pose


def scream(t, rig):
    """0 duruş → 0.22 içine kapanma (baş öne, kollar göğse, dizler kırık, çene kapalı) → 0.42 doğrulma,
    göğüs dolar → 0.55 TEPE BAŞI (baş geride, kollar yanda, çene tam açık) → 0.55–1.0 titreyen çığlık,
    baş biraz öne itilir → 1.0 TEPE SONU → 1.2 duruş."""
    gather = _body(rig, 0.09, (12.0, 0.0, 0.0), (8.0, 0.0, 0.0), (6.0, 0, 0), (4.0, 0, 0),
                   neck=(10.0, 0, 0), head=(12.0, 0, 0), jaw=-12.0, feet=FEET)
    side(gather, "clavicle", (0.0, 3.0, -8.0))
    world_hands(rig, gather, both(0.10, -0.24, 1.30), out=0.2)
    rise = _body(rig, 0.04, (-2.0, 0.0, 0.0), (-4.0, 0.0, 0.0), (-4.0, 0, 0), (-2.0, 0, 0),
                 neck=(-8.0, 0, 0), head=(-10.0, 0, 0), jaw=18.0, feet=FEET)
    side(rise, "clavicle", (0.0, -2.0, 5.0))
    world_hands(rig, rise, both(0.46, -0.04, 1.30), out=0.2)
    keys = [(0.0, rest_arms(stand(rig))), (0.22, gather), (0.42, rise)]
    n = 6
    for i in range(n + 1):                       # tepe boyunca titreme (anahtar başına)
        tt = PEAK_START + (PEAK_END - PEAK_START) * i / n
        fwd = min(1.0, max(0.0, (tt - PEAK_START) / 0.25))
        keys.append((tt, _peak(rig, shake=i * 2.3, fwd=fwd)))
    settle = _body(rig, 0.04, (6.0, 0.0, 0.0), (3.0, 0, 0), (2.0, 0, 0), neck=(4.0, 0, 0), head=(2.0, 0, 0),
                   jaw=6.0, feet={"l": (0.0, 0.0, 0.0, 0.01), "r": (-0.03, 0.0, 0.0, -0.01)})
    world_hands(rig, settle, both(0.26, -0.10, 0.98), out=0.1)
    keys += [(1.10, settle), (SCREAM_TIME, rest_arms(stand(rig)))]
    return track(t, keys)


# --- tepki ------------------------------------------------------------------------------
STAGGER_TIME = 0.33


def stagger(t, rig):
    """Göğse darbe: ince gövde geri bükülür, uzun boyun kırbaç gibi gecikir, kollar savrulur."""
    hit = merge(stand(rig, 0.03), {
        "pelvis": {"loc": (0.0, 0.03 * rig.s, -0.03 * rig.s), "rot": (-3.0, 0.0, 2.0)},
        "spine_01": {"rot": (-5.0, 0.0, 0.0)}, "spine_02": {"rot": (-7.0, 2.0, 0.0)},
        "neck_01": {"rot": (8.0, 0.0, 0.0)}, "Head": {"rot": (6.0, 4.0, 3.0)}, "jaw": {"rot": (16.0, 0.0, 0.0)}})
    side(hit, "upperarm", (-16.0, 10.0, 0.0))
    side(hit, "lowerarm", (-14.0, 0.0, 0.0))
    whip = merge(stand(rig, 0.03), {"spine_02": {"rot": (-2.0, 0.0, 0.0)}, "neck_01": {"rot": (-12.0, -2.0, 0.0)},
                                    "Head": {"rot": (-14.0, -3.0, 0.0)}, "jaw": {"rot": (20.0, 0.0, 0.0)}})
    side(whip, "upperarm", (8.0, 6.0, 0.0))
    return track(t, [(0.0, stand(rig)), (0.07, hit), (0.19, whip), (STAGGER_TIME, stand(rig))])


CLIPS = [("idle_Loop", idle, IDLE_CYCLE), ("walk_Loop", walk, WALK_CYCLE), ("scream", scream, SCREAM_TIME),
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
    import screamer_falls
    importlib.reload(screamer_falls)
    bpy.context.scene.render.fps = wp.FPS
    bpy.context.scene.render.fps_base = 1.0
    if arm.animation_data is None:
        arm.animation_data_create()
    rig = wp.Rig(arm)
    names = []
    for name, fn, length in CLIPS + screamer_falls.CLIPS:
        wp.build_clip(rig, name, fn, length)
        names.append(name)
    arm.animation_data.action = bpy.data.actions[CLIPS[0][0]]
    print("SCREAMER ANIMS", names, "IK clamped frames:", rig.clamped, "rig.s %.3f k %.3f" % (rig.s, k_of(rig)))
    return names
