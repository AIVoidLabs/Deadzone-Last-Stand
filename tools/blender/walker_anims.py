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
# Oyunda kök GAME_SPEED ile ilerler ve model GAME_HEIGHT boyuna ölçeklenir (ZombieVisual: scale = boy / ağ
# boyu). Basan ayak model uzayında GAME_SPEED * ağ boyu / GAME_HEIGHT hızla geri kayar; dünyada durur.
# Bu hız bacakları için koşu hızıdır (Froude ~0.85): uzun adımlı, öne düşer gibi bir sendeleme. Derin
# çöküş ve öne eğik gövde erimi açar; sağ ayak topuktan basıp uzun iter, sol ayak parmak ucunda kısa basar
# ve salınımda yerde sürünür (aksak). Döngü kare sayısı tam sayıdır (0.70 sn = 21 kare), son kare ilk kare.
GAME_SPEED = 2.6          # = EnemyData walker speed (m/sn)
GAME_HEIGHT = 1.6         # = EnemyData walker height (m)
REF_HEIGHT = 1.731        # Office ağ boyu; ağ bulunamazsa rig.s ile ölçeklenir
WALK_CYCLE = 0.70         # sn, iki adım
R_STANCE = (0.0, 0.53)    # sağ ayağın yerde kaldığı evre aralığı (topuk -> parmak)
L_STANCE = (0.48, 0.98)   # sol ayağın basışı (parmak ucunda); gerisi sürünen salınım
R_CENTER = 0.04           # basış ortası, parmak ekleminin dinlenmeye göre yeri (m, +Y geri): eğik gövde
L_CENTER = 0.05           # ayağı geride bırakır
R_LIFT = 0.13             # sağ salınımda kalkış (m)
L_SCRAPE = 0.034          # sol salınımda kalkış: parmak ucu yere sürtünür
CROUCH = 0.10             # yürürken pelvis bu kadar alçak (dizler bükük, erim açılır)
LIFTOFF_FOLLOW = 0.4      # kalkışta ayak basış hızının bu payıyla geri gitmeye devam eder (diz aşırı açılmasın)
LEAN = 14.0               # pelvisin öne eğimi (derece); omurga üstüne ekler


def walk_speed(rig) -> float:
    """Basan ayağın model uzayındaki geri kayma hızı (m/sn): dünyada kök hızına eşit."""
    h = getattr(rig, "mesh_h", None) or REF_HEIGHT * rig.s
    return GAME_SPEED * h / GAME_HEIGHT


def _span(phi: float, rng) -> float:
    """Evrenin aralıktaki yeri 0..1 (aralık dışındaysa <0 ya da >1); 1'i aşan aralık sarar."""
    return ((phi - rng[0]) % 1.0) / (rng[1] - rng[0])


def _hermite(p0: float, p1: float, m0: float, m1: float, u: float) -> float:
    """Salınım yolu, uç hızları m0/m1. İnişte m1 = basışın hızı: ayak dünyada durarak yere değer."""
    u2, u3 = u * u, u * u * u
    return (2 * u3 - 3 * u2 + 1) * p0 + (u3 - 2 * u2 + u) * m0 + (-2 * u3 + 3 * u2) * p1 + (u3 - u2) * m1


def _foot_track(phi: float, rig, rng, center: float) -> tuple:
    """Basışta ayak sabit hızla geri kayar (dünyada durur); salınımda Hermite ile öne döner. (y, u, yerde)."""
    v = walk_speed(rig) * WALK_CYCLE              # bir döngüde kat edilen yol (model uzayı)
    dur = rng[1] - rng[0]
    reach = v * dur
    u = _span(phi, rng)
    if u <= 1.0:
        return center * rig.s - reach / 2 + reach * u, u, True
    w = (u - 1.0) * dur / (1.0 - dur)             # salınım 0..1
    m = v * (1.0 - dur)                           # basış hızı salınım biriminde
    return _hermite(center * rig.s + reach / 2, center * rig.s - reach / 2, LIFTOFF_FOLLOW * m, m, w), w, False


def walk_feet(phi: float, rig) -> tuple:
    s = rig.s
    ry, ru, r_down = _foot_track(phi, rig, R_STANCE, R_CENTER)
    if r_down:      # topuktan basar, tabana iner, topuğu kaldırıp parmaktan iter
        r_pitch, rl = _ease(ru, [(0.0, -16.0), (0.14, 0.0), (0.42, 0.0), (0.78, 14.0), (1.0, 40.0)]), 0.0
    else:           # parmak önde kalkar, diz yüksek, inişe doğru parmak kalkık
        r_pitch = _ease(ru, [(0.0, 40.0), (0.3, 30.0), (0.7, -4.0), (1.0, -16.0)])
        rl = R_LIFT * s * math.sin(math.pi * ru) ** 1.2 * (1.0 - 0.25 * ru)
    ly, lu, l_down = _foot_track(phi, rig, L_STANCE, L_CENTER)
    if l_down:      # parmak ucunda basar, topuk hiç tam inmez
        l_pitch, ll, ldx = _ease(lu, [(0.0, 26.0), (0.35, 20.0), (0.7, 26.0), (1.0, 44.0)]), 0.0, 0.0
    else:           # sürünen salınım: parmak aşağıda, yere sürtünür, ayak hafif içe savrulur
        l_pitch = _ease(lu, [(0.0, 44.0), (0.4, 42.0), (0.8, 32.0), (1.0, 26.0)])
        ll = L_SCRAPE * s * math.sin(math.pi * lu) ** 1.5
        ldx = -0.03 * s * math.sin(math.pi * lu)
    r_foot = (ry - rig.legs["r"]["ball0"].y, r_pitch, rl, -0.02 * s)
    l_foot = (ly - rig.legs["l"]["ball0"].y, l_pitch, ll, 0.02 * s + ldx)
    return l_foot, r_foot


def _ease(u: float, keys) -> float:
    """Açık uçlu eğri (sarmaz): keys [(0..1, değer)] arasında Catmull-Rom, uçlarda tutar."""
    return track(u, [(k, {"v": {"x": val}}) for k, val in keys])["v"]["x"]


def walk(t: float, rig) -> dict:
    phi = (t / WALK_CYCLE) % 1.0
    s = rig.s
    # iki adım: sağ basış 0, sol basış ~0.47. Basışta çöker (düşüşü yakalar), basış ortasında kalkar;
    # sol (aksak) basışta daha derin çöker.
    dz = cyc(phi, [(0.02, -0.035), (0.22, 0.012), (0.42, -0.01), (0.52, -0.05), (0.72, -0.008), (0.92, -0.012)])
    sway = cyc(phi, [(0.05, -0.012), (0.28, -0.04), (0.5, -0.005), (0.75, 0.04), (0.97, 0.01)])
    surge = cyc(phi, [(0.0, 0.02), (0.25, -0.02), (0.5, 0.025), (0.75, -0.025)])   # öne düşüp yakalanma
    roll = cyc(phi, [(0.0, 1.0), (0.25, -5.0), (0.5, 1.0), (0.75, 7.0)])
    yaw = cyc(phi, [(0.0, 10.0), (0.28, 0.0), (0.5, -9.0), (0.78, 0.0)])
    fall = cyc(phi - 0.04, [(0.0, 5.0), (0.25, -2.0), (0.5, 7.0), (0.75, -2.0)])      # basışta gövde öne düşer
    lurch = cyc(phi - 0.08, [(0.1, 3.0), (0.4, -3.0), (0.8, 9.0)])                  # düşük omuza yalpalar
    nod = cyc(phi - 0.1, [(0.05, 7.0), (0.3, -3.0), (0.55, 9.0), (0.8, -2.0)])
    flop = cyc(phi - 0.14, [(0.15, -7.0), (0.6, 2.0), (0.9, 11.0)])
    l_foot, r_foot = walk_feet(phi, rig)
    pose = {
        "pelvis": {"loc": (sway * s, surge * s, (dz - CROUCH) * s), "rot": (LEAN + 0.4 * fall, roll, yaw)},
        "spine_01": {"rot": (8.0 + 0.4 * fall, -0.5 * roll, -0.5 * cyc(phi - 0.06, [(0.0, 10.0), (0.28, 0.0), (0.5, -9.0), (0.78, 0.0)]))},
        "spine_02": {"rot": (6.0 + 0.3 * fall, lurch, -0.3 * yaw)},
        "spine_03": {"rot": (3.0, 0.6 * lurch, 0.0)},
        "neck_01": {"rot": (-10.0 - 0.4 * nod, 0.3 * flop, 0.0)},
        "Head": {"rot": (-8.0 + nod, flop, 3.0 * math.sin(TAU * phi))},
        "jaw": {"rot": (cyc(phi - 0.1, [(0.05, 8.0), (0.3, 2.0), (0.55, 11.0), (0.8, 3.0)]), 0.0, 0.0)},
        "ik_l": {"foot": l_foot},
        "ik_r": {"foot": r_foot},
    }
    # kollar öne uzanık kalır: gövdenin öne eğimi omuzda geri alınır (imza duruşu), gevşek ve gecikmeli salınır
    lean = LEAN + 8.0 + 6.0 + 3.0
    for side, ph, sy in (("l", 0.0, 1.0), ("r", 0.5, -1.0)):
        sw = cyc(phi - 0.15 + ph, [(0.0, -6.0), (0.35, 3.0), (0.6, 7.0), (0.9, -5.0)])
        bob = 0.5 * cyc(phi - 0.1, [(0.0, 6.0), (0.25, -3.0), (0.5, 6.0), (0.75, -3.0)])   # basışta kollar sarkar
        pose["clavicle_" + side] = {"rot": (0.0, -sy * 0.4 * lurch, 0.0)}
        pose["upperarm_" + side] = {"rot": (-0.75 * lean + sw + bob, 0.0, 0.0)}
        pose["lowerarm_" + side] = {"rot": (0.6 * cyc(phi - 0.3 + ph, [(0.0, -7.0), (0.35, 3.0), (0.6, 8.0), (0.9, -6.0)]), 0.0, 0.0)}
        pose["hand_" + side] = {"rot": (cyc(phi - 0.4 + ph, [(0.0, -10.0), (0.5, 10.0)]), 0.0, 0.0)}
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


def mesh_height(arm):
    """İskelete bağlı ağın dinlenme boyu (m; Godot'taki AABB üstü). Ağ yoksa None."""
    import bpy
    for obj in bpy.data.objects:
        if obj.type == "MESH" and any(m.type == "ARMATURE" and m.object == arm for m in obj.modifiers):
            mw = arm.matrix_world.inverted() @ obj.matrix_world
            return max((mw @ v.co).z for v in obj.data.vertices)
    return None


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
    rig.mesh_h = mesh_height(arm)
    names = []
    for name, fn, length in CLIPS + walker_falls.CLIPS:
        wp.build_clip(rig, name, fn, length)
        names.append(name)
    arm.animation_data.action = bpy.data.actions[CLIPS[0][0]]
    print("WALKER ANIMS", names, "IK clamped frames:", rig.clamped, "walk speed %.3f" % walk_speed(rig))
    return names
