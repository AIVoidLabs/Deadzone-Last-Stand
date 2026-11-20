"""Koşucu (Pençeli) klipleri — elle anahtarlanmış, kodla yeniden üretilir (Aşama V.5).

İmza: sinsi yaklaşır, çömelip öne uzanarak çığlık atar, alçak gövdeyle koşar, pençe savurur.
Poz çekirdeği ve IK walker_pose.py'de (aynı sözleşme: iskelet uzayında derece, ebeveyne göre; X+ yukarı
uzanan kemikte öne eğilme, sarkan uzuvda geriye savrulma; Y+ sola yatma; Z+ sola dönme; loc yalnız
pelviste, metre). Bacaklar ayak hedefiyle ("ik_*": (y, pitch, lift, dx)), kollar bilek hedefiyle (hands).
Dinlenme pozu konseptin "stalk" duruşu. Döngü klipleri `_Loop` ekiyle (Godot eki atıp döngü yapar).

Hız sözleşmesi: oyunda kök gerçek hızla ilerler, model GAME_HEIGHT boyuna ölçeklenir. Basan ayak model
uzayında hız × ağ boyu / GAME_HEIGHT ile geri kayar (dünyada durur). Oyun klibi gerçek hız / referans hız
oranıyla oynatır. Referanslar: walk 3.0 m/sn, sprint 5.2 m/sn (GAME_PACE 0.8 sonrası).
Ayak kayması: walker_check.walk_slip ile ölçülür (build_all çıktısı "SLIP").
"""
import math

import walker_pose as wp
from walker_anims import hands, rest_arms, side, stand
from walker_pose import cyc, merge, track

TAU = math.tau
GAME_HEIGHT = 1.30        # önerilen EnemyData runner height (= ağ boyu, ölçek ~1)
WALK_SPEED = 3.0          # walk referans hızı (m/sn)
SPRINT_SPEED = 5.2        # sprint referans hızı (m/sn)
WALK_CYCLE = 0.60         # 18 kare, iki adım
SPRINT_CYCLE = 0.50       # 15 kare, iki adım (havada evre var)
GAITS = {   # stance: (sağ basış evresi, sol basış evresi), center: basış ortasında parmak eklemi (iskelet y, m)
    "walk": {"speed": WALK_SPEED, "cycle": WALK_CYCLE, "stance": ((0.0, 0.42), (0.5, 0.92)),
             "center": (0.02, 0.02), "lift": 0.10, "follow": 0.35, "crouch": 0.08,
             "pitch_down": [(0.0, 14.0), (0.3, 10.0), (0.7, 22.0), (1.0, 48.0)],
             "pitch_up": [(0.0, 48.0), (0.4, 40.0), (0.8, 20.0), (1.0, 14.0)]},
    "sprint": {"speed": SPRINT_SPEED, "cycle": SPRINT_CYCLE, "stance": ((0.0, 0.30), (0.5, 0.80)),
               "center": (-0.02, -0.02), "lift": 0.20, "follow": 0.30, "crouch": 0.13,
               "pitch_down": [(0.0, 18.0), (0.35, 12.0), (0.7, 30.0), (1.0, 60.0)],
               "pitch_up": [(0.0, 60.0), (0.35, 55.0), (0.75, 30.0), (1.0, 18.0)]},
}


def model_speed(rig, speed):
    h = getattr(rig, "mesh_h", None) or GAME_HEIGHT
    return speed * h / GAME_HEIGHT


def _hermite(p0, p1, m0, m1, u):
    u2, u3 = u * u, u * u * u
    return (2 * u3 - 3 * u2 + 1) * p0 + (u3 - 2 * u2 + u) * m0 + (-2 * u3 + 3 * u2) * p1 + (u3 - u2) * m1


def _ease(u, keys):
    return track(u, [(k, {"v": {"x": val}}) for k, val in keys])["v"]["x"]


def _foot(phi, rig, g, idx):
    """(y, pitch, lift): basışta sabit hızla geri (dünyada durur), salınımda Hermite ile öne, yüksek diz."""
    rng = g["stance"][idx]
    v = model_speed(rig, g["speed"]) * g["cycle"]
    dur = rng[1] - rng[0]
    reach = v * dur
    c = g["center"][idx] * rig.s
    u = ((phi - rng[0]) % 1.0) / dur
    if u <= 1.0:
        return c - reach / 2 + reach * u, _ease(u, g["pitch_down"]), 0.0
    w = (u - 1.0) * dur / (1.0 - dur)
    m = v * (1.0 - dur)
    y = _hermite(c + reach / 2, c - reach / 2, g["follow"] * m, m, w)
    lift = g["lift"] * rig.s * math.sin(math.pi * w) ** 1.1 * (1.0 - 0.3 * w)
    return y, _ease(w, g["pitch_up"]), lift


def gait_feet(phi, rig, g):
    """walker_check.walk_slip için (sol, sağ) ayak hedefi."""
    out = []
    for idx, side_ in ((1, "l"), (0, "r")):
        y, pitch, lift = _foot(phi, rig, g, idx)
        out.append((y - rig.legs[side_]["ball0"].y, pitch, lift, 0.0))
    return tuple(out)


def walk_feet(phi, rig):
    return gait_feet(phi, rig, GAITS["walk"])


def sprint_feet(phi, rig):
    return gait_feet(phi, rig, GAITS["sprint"])


def _arms_swing(rig, pose, phi, fwd, back, lag=0.1):
    """Bilekler göğüs çerçevesinde ileri/geri uç arasında, bacağa karşı evrede salınır."""
    for sd, ph in (("l", 0.0), ("r", 0.5)):
        k = 0.5 + 0.5 * math.cos(TAU * (phi - lag + ph))      # sol kol sağ bacakla öne
        rel = tuple(back[i] + (fwd[i] - back[i]) * k for i in range(3))
        sx = 1.0 if sd == "l" else -1.0
        target = rig.head["upperarm_" + sd] + wp.Vector((sx * rel[0], rel[1], rel[2])) * rig.s
        pose["arm_" + sd] = {"hand": tuple(target - rig.head["hand_" + sd]), "out": 0.25}
    return pose


def hands_ground(rig, pose, offs, z, out=0.3):
    """Bilek hedefi iskelet (dünya) uzayında: omzun pozdaki yerinden yatay (dışa, ileri) kayma ve mutlak
    yükseklik z (m). Gövde yatınca göğüs çerçevesi döndüğü için yerdeki eller böyle verilir.
    offs: ((dışa_l, y_l), (dışa_r, y_r)) bacak boyuyla ölçekli; z: tek değer ya da (z_l, z_r)."""
    q03, h03 = wp._fk_chest(rig, pose)
    h = rig.head
    zs = z if isinstance(z, tuple) else (z, z)
    for i, (sd, sx) in enumerate((("l", 1.0), ("r", -1.0))):
        sh = h03 + q03 @ (h["upperarm_" + sd] - h["spine_03"])
        dx, dy = offs[i]
        target = wp.Vector((sh.x + sx * dx * rig.s, sh.y + dy * rig.s, zs[i]))
        hand = q03.inverted() @ (target - h03) + h["spine_03"] - h["hand_" + sd]
        pose["arm_" + sd] = {"hand": tuple(hand), "out": out}
    return pose


def walk(t, rig):
    """Sinsi yaklaşma: alçak, öne eğik, parmak ucunda uzun adımlar; kollar sarkık, pençeler diz altında."""
    g = GAITS["walk"]
    phi = (t / g["cycle"]) % 1.0
    s = rig.s
    l_foot, r_foot = walk_feet(phi, rig)
    dz = cyc(phi, [(0.05, -0.03), (0.25, 0.01), (0.55, -0.03), (0.75, 0.01)])
    sway = cyc(phi, [(0.1, -0.025), (0.6, 0.025)])
    roll = cyc(phi, [(0.1, -4.0), (0.6, 4.0)])
    yaw = cyc(phi, [(0.0, 8.0), (0.5, -8.0)])
    nod = cyc(phi - 0.1, [(0.05, 4.0), (0.3, -3.0), (0.55, 4.0), (0.8, -3.0)])
    pose = {
        "pelvis": {"loc": (sway * s, 0.0, (dz - g["crouch"]) * s), "rot": (10.0, roll, yaw)},
        "spine_01": {"rot": (4.0, -0.5 * roll, -0.4 * yaw)},
        "spine_02": {"rot": (3.0, -0.3 * roll, -0.4 * yaw)},
        "spine_03": {"rot": (0.0, 0.0, -0.2 * yaw)},
        "neck_01": {"rot": (-10.0 - 0.5 * nod, 0.0, 0.0)},
        "Head": {"rot": (-8.0 + nod, -roll * 0.5, 0.2 * yaw)},
        "jaw": {"rot": (14.0 + 4.0 * math.sin(TAU * phi * 2), 0.0, 0.0)},
        "ik_l": {"foot": l_foot}, "ik_r": {"foot": r_foot},
    }
    _arms_swing(rig, pose, phi, (0.10, -0.30, -0.62), (0.10, -0.05, -0.64), lag=0.15)
    side(pose, "hand", (-10.0, 0.0, 0.0))
    return pose


def sprint(t, rig):
    """Alçak koşu: gövde neredeyse yatay, baş askere bakar, pençeler önde, havada evreli iki ayak."""
    g = GAITS["sprint"]
    phi = (t / g["cycle"]) % 1.0
    s = rig.s
    l_foot, r_foot = sprint_feet(phi, rig)
    dz = cyc(phi, [(0.12, -0.05), (0.38, 0.03), (0.62, -0.05), (0.88, 0.03)])
    surge = cyc(phi, [(0.1, 0.02), (0.35, -0.02), (0.6, 0.02), (0.85, -0.02)])
    roll = cyc(phi, [(0.15, -5.0), (0.65, 5.0)])
    yaw = cyc(phi, [(0.0, 10.0), (0.5, -10.0)])
    pump = cyc(phi - 0.05, [(0.12, 4.0), (0.38, -3.0), (0.62, 4.0), (0.88, -3.0)])
    pose = {
        "pelvis": {"loc": (0.0, surge * s, (dz - g["crouch"]) * s), "rot": (26.0 + pump, roll, yaw)},
        "spine_01": {"rot": (8.0, -0.4 * roll, -0.5 * yaw)},
        "spine_02": {"rot": (6.0, -0.3 * roll, -0.5 * yaw)},
        "spine_03": {"rot": (2.0, 0.0, -0.3 * yaw)},
        "neck_01": {"rot": (-26.0 - 0.6 * pump, 0.0, 0.0)},
        "Head": {"rot": (-20.0 - 0.4 * pump, -0.4 * roll, 0.3 * yaw)},
        "jaw": {"rot": (24.0 + 6.0 * math.sin(TAU * phi * 2), 0.0, 0.0)},
        "ik_l": {"foot": l_foot}, "ik_r": {"foot": r_foot},
    }
    _arms_swing(rig, pose, phi, (0.12, -0.56, -0.28), (0.16, 0.02, -0.40), lag=0.05)
    side(pose, "hand", (-30.0, 0.0, 0.0))     # pençeler öne bakar
    return pose


IDLE_CYCLE = 2.4


def idle(t, rig):
    """Çömelik bekleme: soluk alıp verir, ağırlığını kaydırır, başı kuşla gibi seğirir, pençeler kasılır."""
    phi = (t / IDLE_CYCLE) % 1.0
    w = TAU * phi
    s = rig.s
    breath = math.sin(2 * w)
    twitch = cyc(phi, [(0.0, 0.0), (0.30, 0.0), (0.33, 14.0), (0.45, 12.0), (0.50, 0.0), (0.72, 0.0),
                       (0.75, -10.0), (0.85, -9.0), (0.9, 0.0)])
    shift = math.sin(w) * 0.02
    pose = merge(stand(rig, 0.03 + 0.008 * breath), {
        "pelvis": {"loc": (shift * s, 0.0, -(0.03 + 0.008 * breath) * s), "rot": (2.0, 40 * shift, 0.0)},
        "spine_01": {"rot": (1.5 * breath, -30 * shift, 0.0)},
        "spine_02": {"rot": (-2.0 * breath, 0.0, 0.0)},
        "neck_01": {"rot": (-4.0, 0.0, 0.3 * twitch)},
        "Head": {"rot": (-4.0 + 2 * math.sin(w + 1.0), 0.4 * twitch, twitch)},
        "jaw": {"rot": (cyc(phi, [(0.0, 10.0), (0.35, 22.0), (0.5, 12.0), (0.8, 16.0)]), 0.0, 0.0)},
    })
    for sd, ph in (("l", 0.0), ("r", 1.7)):
        pose["upperarm_" + sd] = {"rot": (3 * math.sin(w + ph), 0.0, 0.0)}
        pose["lowerarm_" + sd] = {"rot": (4 * math.sin(w + ph - 0.6), 0.0, 0.0)}
        pose["hand_" + sd] = {"rot": (-8 + 10 * math.sin(2 * w + ph), 0.0, 0.0)}
    return pose


# --- çığlık (lunge hazırlığı) ----------------------------------------------------
SCREAM_TIME = 0.6


def coil(rig, jaw=40.0):
    """Çığlığın doruğu (konsept imza pozu): dizler derin, gövde yere yakın, boyun öne uzanmış, yüz askere,
    kollar iki yana açık, pençeler yerde ve açık, çene sonuna kadar açık."""
    s = rig.s
    pose = merge(stand(rig, 0.24), {
        "pelvis": {"loc": (0.0, 0.08 * s, -0.24 * s), "rot": (14.0, 0.0, 0.0)},
        "spine_01": {"rot": (6.0, 0.0, 0.0)}, "spine_02": {"rot": (2.0, 0.0, 0.0)},
        "spine_03": {"rot": (-6.0, 0.0, 0.0)},
        "neck_01": {"rot": (-30.0, 0.0, 0.0)}, "Head": {"rot": (-22.0, 0.0, 0.0)},
        "jaw": {"rot": (jaw, 0.0, 0.0)},
        "ik_l": {"foot": (0.04 * s, 32.0, 0.0, 0.03 * s)}, "ik_r": {"foot": (-0.06 * s, 18.0, 0.0, -0.03 * s)},
    })
    side(pose, "clavicle", (0.0, -6.0, 6.0))
    side(pose, "hand", (-40.0, 0.0, 12.0))
    return hands_ground(rig, pose, ((0.18, -0.30), (0.18, -0.36)), 0.17, out=0.5)


def scream(t, rig):
    """0–0.15 çöküş, 0.15–0.35 boyun öne fırlar ve çene açılır, 0.35–0.6 titreyen çığlık (doruk tutulur)."""
    s = rig.s
    dip = merge(stand(rig, 0.16), {
        "pelvis": {"loc": (0.0, 0.05 * s, -0.16 * s), "rot": (18.0, 0.0, 0.0)},
        "spine_01": {"rot": (8.0, 0.0, 0.0)}, "neck_01": {"rot": (4.0, 0.0, 0.0)},
        "Head": {"rot": (10.0, 0.0, 0.0)}, "jaw": {"rot": (6.0, 0.0, 0.0)},
    })
    hands_ground(rig, dip, ((0.14, -0.20), (0.14, -0.22)), 0.24)
    thrust = coil(rig, 44.0)
    thrust["neck_01"] = {"rot": (-36.0, 0.0, 0.0)}
    shake = merge(coil(rig, 40.0), {"Head": {"rot": (-24.0, 3.0, 2.0)}})
    keys = [(0.0, rest_arms(stand(rig))), (0.15, dip), (0.32, thrust),
            (0.46, shake), (SCREAM_TIME, coil(rig, 42.0))]
    return track(t, keys)


# --- pençe savurma ----------------------------------------------------------------
STRIKE_TIME = 0.6
STRIKE_HIT = 0.25


def _strike_pose(rig, phase):
    """phase: 'push' itiş, 'air' havada sağ kol arkada yüksek, 'hit' sağ pençe önden çaprazlama aşağı,
    'land' iniş çömelmesi."""
    s = rig.s
    if phase == "push":
        pose = merge(coil(rig, 30.0), {"pelvis": {"loc": (0.0, -0.06 * s, -0.18 * s), "rot": (24.0, 0.0, 0.0)},
                                        "ik_r": {"foot": (0.10 * s, 50.0, 0.0, -0.03 * s)}})
        return hands_ground(rig, pose, ((0.14, -0.10), (0.22, 0.12)), (0.12, 0.40), out=0.4)
    if phase == "air":
        pose = merge(stand(rig, 0.0), {
            "pelvis": {"loc": (0.0, -0.20 * s, 0.02 * s), "rot": (30.0, -8.0, 14.0)},
            "spine_01": {"rot": (4.0, 0.0, 10.0)}, "spine_02": {"rot": (0.0, 0.0, 14.0)},
            "neck_01": {"rot": (-30.0, 0.0, -12.0)}, "Head": {"rot": (-24.0, 0.0, -14.0)},
            "jaw": {"rot": (42.0, 0.0, 0.0)},
            "ik_l": {"foot": (-0.10 * s, 30.0, 0.16 * s, 0.0)}, "ik_r": {"foot": (0.20 * s, 60.0, 0.12 * s, 0.0)},
        })
        return hands(rig, pose, (0.20, -0.55, -0.30), (0.34, 0.10, 0.05), out=0.5)
    if phase == "hit":
        pose = merge(stand(rig, 0.0), {
            "pelvis": {"loc": (0.0, -0.32 * s, -0.04 * s), "rot": (34.0, 6.0, -16.0)},
            "spine_01": {"rot": (6.0, 0.0, -12.0)}, "spine_02": {"rot": (6.0, 0.0, -16.0)},
            "neck_01": {"rot": (-30.0, 0.0, 14.0)}, "Head": {"rot": (-20.0, 0.0, 16.0)},
            "jaw": {"rot": (30.0, 0.0, 0.0)},
            "ik_l": {"foot": (-0.22 * s, 20.0, 0.10 * s, 0.0)}, "ik_r": {"foot": (0.12 * s, 50.0, 0.10 * s, 0.0)},
        })
        side(pose, "hand", (-30.0, 0.0, 0.0))
        return hands_ground(rig, pose, ((0.26, 0.10), (-0.14, -0.42)), (0.55, 0.30), out=0.4)
    pose = merge(coil(rig, 16.0), {"pelvis": {"loc": (0.0, -0.10 * s, -0.20 * s), "rot": (20.0, 0.0, -6.0)},
                                   "ik_l": {"foot": (-0.16 * s, 10.0, 0.0, 0.0)}})
    return hands_ground(rig, pose, ((0.18, -0.34), (0.10, -0.40)), 0.12, out=0.4)


def strike(t, rig):
    """0–0.08 itiş, 0.08–0.42 havada, 0.25 vuruş (sağ pençe), 0.45 iniş, 0.6 sinsi duruşa dönüş."""
    rest = rest_arms(stand(rig))
    keys = [(0.0, _strike_pose(rig, "push")), (0.12, _strike_pose(rig, "air")),
            (STRIKE_HIT, _strike_pose(rig, "hit")), (0.45, _strike_pose(rig, "land")), (STRIKE_TIME, rest)]
    return track(t, keys)


# --- tepki ------------------------------------------------------------------------
STAGGER_TIME = 0.4


def stagger(t, rig):
    s = rig.s
    hit = merge(stand(rig, 0.05), {
        "pelvis": {"loc": (0.0, 0.08 * s, -0.03 * s), "rot": (-10.0, 4.0, -8.0)},
        "spine_01": {"rot": (-12.0, 0.0, 0.0)}, "spine_02": {"rot": (-10.0, 5.0, 0.0)},
        "neck_01": {"rot": (-10.0, 0.0, 0.0)}, "Head": {"rot": (-26.0, 12.0, 8.0)},
        "jaw": {"rot": (30.0, 0.0, 0.0)},
    })
    hands(rig, hit, (0.30, 0.02, -0.45), out=0.4)
    settle = merge(stand(rig, 0.06), {"spine_01": {"rot": (6.0, 0.0, 0.0)}, "Head": {"rot": (8.0, -4.0, 0.0)},
                                      "jaw": {"rot": (14.0, 0.0, 0.0)}})
    rest = rest_arms(stand(rig))
    hands(rig, settle, (0.12, -0.20, -0.70))
    return track(t, [(0.0, rest), (0.07, hit), (0.22, settle), (STAGGER_TIME, rest)])


CLIPS = [("idle_Loop", idle, IDLE_CYCLE), ("walk_Loop", walk, WALK_CYCLE), ("scream", scream, SCREAM_TIME),
         ("sprint_Loop", sprint, SPRINT_CYCLE), ("strike", strike, STRIKE_TIME), ("stagger", stagger, STAGGER_TIME)]


def build_all(arm) -> list:
    import importlib
    import bpy
    import runner_moves
    import walker_anims
    importlib.reload(runner_moves)
    bpy.context.scene.render.fps = wp.FPS
    bpy.context.scene.render.fps_base = 1.0
    if arm.animation_data is None:
        arm.animation_data_create()
    rig = wp.Rig(arm)
    rig.mesh_h = walker_anims.mesh_height(arm)
    runner_moves.prepare(rig)            # ölçülerek yere oturtulan anahtar pozlar (ölümler, doğma)
    names = []
    for name, fn, length in CLIPS + runner_moves.CLIPS:
        wp.build_clip(rig, name, fn, length)
        names.append(name)
    print("RUNNER ANIMS", names, "IK clamped frames:", rig.clamped, "mesh_h %.3f" % rig.mesh_h,
          "walk %.3f sprint %.3f m/s model" % (model_speed(rig, WALK_SPEED), model_speed(rig, SPRINT_SPEED)))
    runner_moves.report_slip(rig, sys_feet={"walk_Loop": (walk, walk_feet, WALK_CYCLE, WALK_SPEED),
                                            "sprint_Loop": (sprint, sprint_feet, SPRINT_CYCLE, SPRINT_SPEED)})
    arm.animation_data.action = bpy.data.actions[CLIPS[0][0]]
    return names
