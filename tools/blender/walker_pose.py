"""Yürüyen klipleri için poz çekirdeği (Aşama V.5): anahtar poz aradeğerleme, bacak IK'sı, anahtarlama, ölçüm.

Sözleşme dilci_anims.py ile aynı: açılar İSKELET uzayında derece, kemiğin ebeveynine göre (dinlenme
pozundan). Karakter -Y'ye bakar, sol +X, yukarı +Z. X+: yukarı uzanan kemikte öne eğilme, aşağı sarkan
kol/bacakta geriye savrulma. Y+: sola yatma. Z+: sola dönme. loc yalnız pelvis'te (metre).

Bacaklar ayak hedefiyle verilir ("ik_l"/"ik_r": {"foot": (y, pitch, lift, dx)}):
  y     : ayak tabanının (parmak eklemi) ileri-geri yeri, dinlenmedeki yerine göre (m, +Y geri)
  pitch : topuk kalkıklığı (derece). >0 parmak ekleminde döner (topuk havada), <0 topukta döner (parmak havada)
  lift  : yerden yükseklik (m). 0 = temas
  dx    : yana kayma (m)
Uyluk, baldır, ayak ve parmak dönüşleri her karede iki kemikli IK ile çözülür, sonra yalnız dönüş olarak
anahtarlanır. Böylece basan ayak yerde kaymaz (konumu doğrudan verilir) ve ölçülebilir.
"""
import math

import bpy
from mathutils import Euler, Matrix, Quaternion, Vector

FPS = 30
X_AXIS = Vector((1.0, 0.0, 0.0))
REF_LEG = 0.88        # Office bacak boyu (m): mesafeler bununla ölçeklenir
REF_SHOULDERS = 0.418 # Office omuz eklemleri arası (m)
HEEL_BACK = 0.035     # topuk, ayak bileğinin izdüşümünden bu kadar geride (m, ölçekli)


def clamp01(x: float) -> float:
    return min(max(x, 0.0), 1.0)


def smooth(x: float) -> float:
    x = clamp01(x)
    return x * x * (3.0 - 2.0 * x)


def lerp(a, b, t):
    return a + (b - a) * t


# --------------------------------------------------------------------------- iskelet bilgisi

class Rig:
    """Bir çeşidin dinlenme ölçüleri: kemik yönleri, bacak boyları, düz ayak geometrisi."""

    def __init__(self, arm):
        self.arm = arm
        bones = arm.data.bones
        self.rest_q = {b.name: b.matrix_local.to_quaternion() for b in bones}
        self.head = {b.name: b.head_local.copy() for b in bones}
        self.tail = {b.name: b.tail_local.copy() for b in bones}
        r = self.head
        self.leg_len = (r["calf_r"] - r["thigh_r"]).length + (r["foot_r"] - r["calf_r"]).length
        self.s = self.leg_len / REF_LEG
        # omuz genişliği oranı (Office = 1): yan yatışta gövde bu kadar yüksekte kalır
        self.w = (r["upperarm_l"] - r["upperarm_r"]).length / REF_SHOULDERS
        # düz ayak: sağ ayağın dinlenmesi (sol dinlenmede topuk kalkık)
        af = r["foot_r"] - r["ball_r"]
        self.ball_h = r["ball_r"].z
        self.flat_angle = math.atan2(af.z, af.y)
        self.legs = {}
        for side in ("l", "r"):
            ankle, ball = r["foot_" + side], r["ball_" + side]
            d = (ankle - ball)
            self.legs[side] = {
                "a": (r["calf_" + side] - r["thigh_" + side]).length,
                "b": (ankle - r["calf_" + side]).length,
                "af_len": Vector((0.0, d.y, d.z)).length,
                "af_dx": d.x,
                "ball0": ball.copy(),
                "rest_pitch": math.degrees(math.atan2(d.z, d.y) - self.flat_angle),
                "toe_len": (self.tail["ball_" + side] - ball).length,
            }
        self.clamped = 0


# --------------------------------------------------------------------------- aradeğerleme

def _cr(p0, p1, p2, p3, u):
    """Catmull-Rom (eğri anahtar pozlardan geçer)."""
    u2, u3 = u * u, u * u * u
    return 0.5 * (2 * p1 + (p2 - p0) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u2 + (3 * p1 - p0 - 3 * p2 + p3) * u3)


def cyc(phi: float, keys) -> float:
    """Döngü eğrisi: keys [(evre 0..1, değer)], evre sıralı. Son anahtardan ilkine sarar."""
    phi %= 1.0
    n = len(keys)
    i = max(k for k in range(n) if keys[k][0] <= phi) if phi >= keys[0][0] else n - 1
    p1, v1 = keys[i]
    p2, v2 = keys[(i + 1) % n]
    span = (p2 - p1) % 1.0 or 1.0
    u = ((phi - p1) % 1.0) / span
    return _cr(keys[(i - 1) % n][1], v1, v2, keys[(i + 2) % n][1], u)


def _channels(poses):
    out = {}
    for pose in poses:
        for name, ch in pose.items():
            for key, val in ch.items():
                out.setdefault((name, key), len(val) if isinstance(val, tuple) else 1)
    return out


def _value(pose, name, key, size):
    ch = pose.get(name, {})
    if key in ch:
        v = ch[key]
        return v if isinstance(v, tuple) else (v,)
    return (0.0,) * size


def track(t: float, keys) -> dict:
    """Anahtar pozlardan (zaman, poz) Catmull-Rom; uçlarda tutar. Eksik kanal sıfırdır."""
    times = [k[0] for k in keys]
    poses = [k[1] for k in keys]
    if t <= times[0]:
        i, u = 0, 0.0
    elif t >= times[-1]:
        i, u = len(keys) - 2, 1.0
    else:
        i = max(k for k in range(len(keys) - 1) if times[k] <= t)
        u = (t - times[i]) / (times[i + 1] - times[i])
    idx = [max(i - 1, 0), i, i + 1, min(i + 2, len(keys) - 1)]
    out = {}
    for (name, key), size in _channels(poses).items():
        vals = [_value(poses[j], name, key, size) for j in idx]
        res = tuple(_cr(vals[0][c], vals[1][c], vals[2][c], vals[3][c], u) for c in range(size))
        out.setdefault(name, {})[key] = res if size > 1 else res[0]
    return out


def blend(a: dict, b: dict, t: float) -> dict:
    out = {}
    for name in set(a) | set(b):
        ca, cb = a.get(name, {}), b.get(name, {})
        ch = {}
        for key in set(ca) | set(cb):
            va, vb = ca.get(key), cb.get(key)
            if va is None or vb is None:
                ch[key] = va if vb is None else vb
            elif isinstance(va, tuple):
                ch[key] = tuple(lerp(va[i], vb[i], t) for i in range(len(va)))
            else:
                ch[key] = lerp(va, vb, t)
        out[name] = ch
    return out


def merge(base: dict, over: dict) -> dict:
    """Pozu kopyalayıp kanal kanal üstüne yazar."""
    out = {k: dict(v) for k, v in base.items()}
    for name, ch in over.items():
        out.setdefault(name, {}).update(ch)
    return out


# --------------------------------------------------------------------------- bacak IK

def _q(rot) -> Quaternion:
    return Euler(tuple(math.radians(a) for a in rot), "XYZ").to_quaternion()


def _frame(d: Vector, lat: Vector) -> Matrix:
    d = d.normalized()
    n = (lat - d * lat.dot(d)).normalized()
    return Matrix((d, n, d.cross(n))).transposed()


def _aim(rest_dir: Vector, new_dir: Vector) -> Quaternion:
    """Kemik yönünü çevirir; yanal eksen (X) korunur, burulma eklemez."""
    return (_frame(new_dir, X_AXIS) @ _frame(rest_dir, X_AXIS).inverted()).to_quaternion()


def foot_points(rig: Rig, side: str, foot) -> tuple:
    """Ayak hedefinden (y, pitch, lift, dx) iskelet uzayında bilek ve parmak eklemi."""
    y, pitch, lift, dx = foot
    leg = rig.legs[side]
    s = rig.s
    ball = Vector((leg["ball0"].x + dx, leg["ball0"].y + y, rig.ball_h))
    fa = rig.flat_angle
    ankle = ball + Vector((leg["af_dx"], leg["af_len"] * math.cos(fa), leg["af_len"] * math.sin(fa)))
    if pitch >= 0.0:
        pivot = Vector((ball.x, ball.y, 0.0))
    else:
        pivot = Vector((ball.x, ankle.y + HEEL_BACK * s, 0.0))
    rot = Quaternion(X_AXIS, math.radians(pitch))
    ball = pivot + rot @ (ball - pivot)
    ankle = pivot + rot @ (ankle - pivot)
    up = Vector((0.0, 0.0, lift))
    return ankle + up, ball + up


def solve_legs(rig: Rig, pose: dict) -> dict:
    """"ik_*" girdilerini uyluk/baldır/ayak/parmak dönüşlerine çevirir (pose yerinde güncellenir)."""
    pel = pose.get("pelvis", {})
    q_pel = _q(pel.get("rot", (0, 0, 0)))
    p_head = rig.head["pelvis"]
    p_loc = Vector(pel.get("loc", (0, 0, 0)))
    for side in ("l", "r"):
        ik = pose.pop("ik_" + side, None)
        if ik is None:
            continue
        foot = ik["foot"]
        leg = rig.legs[side]
        hip = p_head + p_loc + q_pel @ (rig.head["thigh_" + side] - p_head)
        ankle, ball = foot_points(rig, side, foot)
        a, b = leg["a"], leg["b"]
        to = ankle - hip
        c = to.length
        if c > (a + b) * 0.995:
            rig.clamped += 1
            c = (a + b) * 0.995
        u = to.normalized()
        pole = Vector((0.0, -1.0, 0.0))
        w = (pole - u * pole.dot(u)).normalized()
        cos_a = (a * a + c * c - b * b) / (2 * a * c)
        knee = hip + a * (cos_a * u + math.sqrt(max(0.0, 1 - cos_a * cos_a)) * w)
        ankle = hip + u * c
        h = rig.head
        q_t = _aim(h["calf_" + side] - h["thigh_" + side], knee - hip)
        q_c = _aim(h["foot_" + side] - h["calf_" + side], ankle - knee)
        q_f = _aim(h["ball_" + side] - h["foot_" + side], ball - ankle)
        # parmak: tabanla yere basarken yatay kalır; havadayken ayakla birlikte döner
        y, pitch, lift, dx = foot
        rigid = q_f @ (h["ball_leaf_" + side] - h["ball_" + side])
        flat = Vector((0.0, -1.0, -0.07)) * rigid.length
        k = 1.0 if pitch < 0.0 else smooth(lift / (0.03 * rig.s))
        toe = flat.lerp(rigid, k)
        q_b = _aim(h["ball_leaf_" + side] - h["ball_" + side], toe)
        for bone, q in (("thigh_", q_pel.inverted() @ q_t), ("calf_", q_t.inverted() @ q_c),
                        ("foot_", q_c.inverted() @ q_f), ("ball_", q_f.inverted() @ q_b)):
            e = q.to_euler("XYZ")
            pose.setdefault(bone + side, {})["rot"] = tuple(math.degrees(v) for v in e)
    return pose


# --------------------------------------------------------------------------- kol IK

ARM_CHAIN = ("pelvis", "spine_01", "spine_02", "spine_03")


def _fk_chest(rig: Rig, pose: dict) -> tuple:
    """spine_03'ün iskelet uzayında mutlak dönüşü ve baş konumu (pelvis loc dahil)."""
    q_abs = Quaternion()
    head = None
    prev = None
    for name in ARM_CHAIN:
        ch = pose.get(name, {})
        if prev is None:
            head = rig.head[name] + Vector(ch.get("loc", (0, 0, 0)))
        else:
            head = head + q_abs @ (rig.head[name] - rig.head[prev])
        q_abs = q_abs @ _q(ch.get("rot", (0, 0, 0)))
        prev = name
    return q_abs, head


def _arm_frame(d: Vector, n: Vector) -> Matrix:
    d = d.normalized()
    n = (n - d * n.dot(d)).normalized()
    return Matrix((d, n, d.cross(n))).transposed()


def solve_arms(rig: Rig, pose: dict) -> dict:
    """"arm_*" girdileri: {"hand": (dx, dy, dz)} bileğin dinlenme yerinden kayması, göğüs (spine_03)
    çerçevesinde; dirsek dinlenmedeki düzleminde kalır ("out": dirseği dışa/aşağı iten pay, m)."""
    if "arm_l" not in pose and "arm_r" not in pose:
        return pose
    q03, h03 = _fk_chest(rig, pose)
    h = rig.head
    for side, sx in (("l", 1.0), ("r", -1.0)):
        arm = pose.pop("arm_" + side, None)
        if arm is None:
            continue
        cl = pose.get("clavicle_" + side, {}).get("rot", (0, 0, 0))
        q_cl = q03 @ _q(cl)
        sh0, el0, wr0 = h["upperarm_" + side], h["lowerarm_" + side], h["hand_" + side]
        sh = h03 + q03 @ (h["clavicle_" + side] - h["spine_03"]) + q_cl @ (sh0 - h["clavicle_" + side])
        target = h03 + q03 @ (wr0 + Vector(arm["hand"]) - h["spine_03"])
        a, b = (el0 - sh0).length, (wr0 - el0).length
        to = target - sh
        c = min(to.length, (a + b) * 0.995)
        u = to.normalized()
        mid0 = sh0 + (wr0 - sh0).normalized() * (el0 - sh0).dot((wr0 - sh0).normalized())
        out = arm.get("out", 0.0)
        pole = q03 @ ((el0 - mid0).normalized() + Vector((sx * out, 0.0, -out)))
        w = (pole - u * pole.dot(u)).normalized()
        cos_a = max(-1.0, min(1.0, (a * a + c * c - b * b) / (2 * a * c)))
        el = sh + a * (cos_a * u + math.sqrt(1 - cos_a * cos_a) * w)
        wr = sh + u * c
        n0 = (el0 - sh0).cross(wr0 - el0)
        n0 = n0 if n0.length > 1e-6 else (el0 - sh0).cross(el0 - mid0)
        n = (el - sh).cross(wr - el)
        n = n if n.length > 1e-6 else u.cross(w)
        q_u = (_arm_frame(el - sh, n) @ _arm_frame(el0 - sh0, n0).inverted()).to_quaternion()
        q_l = (_arm_frame(wr - el, n) @ _arm_frame(wr0 - el0, n0).inverted()).to_quaternion()
        for bone, q in (("upperarm_", q_cl.inverted() @ q_u), ("lowerarm_", q_u.inverted() @ q_l)):
            pose.setdefault(bone + side, {})["rot"] = tuple(math.degrees(v) for v in q.to_euler("XYZ"))
    return pose


# --------------------------------------------------------------------------- anahtarlama

def apply(rig: Rig, pose: dict, frame: int) -> None:
    pose = solve_arms(rig, solve_legs(rig, {k: dict(v) for k, v in pose.items()}))
    for pb in rig.arm.pose.bones:
        ch = pose.get(pb.name, {})
        rest = rig.rest_q[pb.name]
        pb.rotation_quaternion = rest.inverted() @ _q(ch.get("rot", (0, 0, 0))) @ rest
        pb.keyframe_insert("rotation_quaternion", frame=frame, group=pb.name)
        if pb.name == "pelvis":
            pb.location = rest.inverted() @ Vector(ch.get("loc", (0, 0, 0)))
            pb.keyframe_insert("location", frame=frame, group=pb.name)
        else:
            pb.location = (0.0, 0.0, 0.0)
        pb.scale = (1.0, 1.0, 1.0)


def build_clip(rig: Rig, name: str, fn, length: float):
    """Her kare anahtarlanır (IK hassas kalsın). Kareler 0'dan başlar: GLB'de ilk anahtar 0 sn, son anahtar
    tam length sn olur (1'den başlayınca klip 1 kare uzuyor ve başta 1 kare tutuyordu). Döngüde son kare
    ilk kareyle aynı pozdur; Godot sararken çift tutma olmaz."""
    arm = rig.arm
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    arm.animation_data.action = action
    last = round(length * FPS)
    for f in range(last + 1):
        apply(rig, fn(f / FPS, rig), f)
    action.use_frame_range = True
    action.frame_start, action.frame_end = 0, last
    return action
