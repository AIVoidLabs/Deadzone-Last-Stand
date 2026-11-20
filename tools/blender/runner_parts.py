"""Koşucu (Pençeli) parçaları: uzun parmaklı el, kıvrık pençeler, kemik çıkıntıları, kıyafet.

build_runner.py içe aktarır. Kıyafet kuralları walker_clothes.py'den uyarlandı (kopya): yürüyen
yüksekliğe (z) göre keser; koşucu çömelince gövde alçaldığı için burada kesim iskelet parçası
boyunca (t) yapılır, böylece aynı kıyafet her pozda aynı yere düşer.
"""
import math

import bmesh
import bpy
from mathutils import Matrix, Vector, noise

import zombie_kit as kit

CLOTH_EDGE_SMOOTH = 20
FINGER_SEGS = ((0.054, 10.0), (0.042, 18.0), (0.032, 22.0))   # (boy m, kıvrılma derece)
FINGER_LEN = (0.86, 1.0, 0.96, 0.78)                           # işaret .. serçe
FINGER_RADII = (0.0110, 0.0098, 0.0088, 0.0080)                # kök .. uç boğum
CLAW_LEN = 0.085                                               # pençe boyu (orta parmak)


# ---------------------------------------------------------------- el ve pençe

def _toward(d, cup, deg):
    """d yönünü cup'a doğru deg derece büker."""
    axis = d.cross(cup)
    if axis.length < 1e-5:
        return d.copy()
    return (Matrix.Rotation(math.radians(deg), 3, axis.normalized()) @ d).normalized()


def hand(pts, side, spec, t):
    """Uzun dört parmak + başparmak (skin düğümleri) ve her ucun pençe tarifi.
    spec: fdir (parmak kök yönü; None = bilekten avuca), cup (kıvrılma yönü), fan (derece)."""
    wrist, palm = pts[f"wrist_{side}"][0], pts[f"palm_{side}"][0]
    d = Vector(spec["fdir"]).normalized() if spec.get("fdir") else (palm - wrist).normalized()
    cup = Vector(spec["cup"]).normalized()
    across = d.cross(cup).normalized()
    inward = Vector((-1.0 if palm.x > 0 else 1.0, 0.0, 0.0))
    if across.dot(inward) < 0.0:
        across = -across
    extra, edges, claws = {}, [], []
    for i in range(4):
        off = (1.5 - i) * 0.021 * t                    # i=0 başparmağa yakın (içte)
        p = palm + across * off + d * 0.012
        fd = (Matrix.Rotation(math.radians((1.5 - i) * spec["fan"]), 3, d.cross(across)) @ d).normalized()
        prev = f"palm_{side}"
        for j, (seg, curl) in enumerate(FINGER_SEGS):
            fd = _toward(fd, cup, curl * spec.get("curl", 1.0))
            p = p + fd * seg * FINGER_LEN[i] * spec.get("len", 1.0)
            name = f"f{i}{j}_{side}"
            extra[name] = (p.copy(), FINGER_RADII[j + 1] * t)
            edges.append((prev, name))
            prev = name
        claws.append((p, fd, cup, CLAW_LEN * FINGER_LEN[i] ** 0.5, FINGER_RADII[3] * t * 1.15))
    td = (d * 0.35 + across * 0.75 + cup * 0.35).normalized()
    p = palm + across * 0.030 * t
    prev = f"palm_{side}"
    for j in range(2):
        td = _toward(td, cup, 18.0)
        p = p + td * 0.036
        extra[f"th{j}_{side}"] = (p.copy(), 0.0102 * t)
        edges.append((prev, f"th{j}_{side}"))
        prev = f"th{j}_{side}"
    claws.append((p, td, cup, CLAW_LEN * 0.65, 0.0100 * t))
    return extra, edges, claws


def claw_mesh(bm, base, d, cup, length, radius, bend=55.0, steps=6, ring=8):
    """Yaydan geçen, yanlardan basık (yüksek, dar), uca doğru sivrilen pençe/kemik dikeni."""
    p = base - d * radius * 0.8                        # kök parmağın içine gömülü
    seg = length / steps
    axis = d.cross(cup)                                 # bükülme ekseni: tüm halkalarda sabit
    axis = axis.normalized() if axis.length > 1e-4 else d.orthogonal().normalized()
    step_rot = Matrix.Rotation(math.radians(bend / steps), 3, axis)
    rings = []
    for k in range(steps):
        f = k / steps
        up = axis.cross(d).normalized()                 # bükülmenin dış sırtı
        r = radius * (1.0 - f) ** 0.75
        rings.append([bm.verts.new(p + up * math.sin(a) * r + axis * math.cos(a) * r * 0.62)
                      for a in (2.0 * math.pi * q / ring for q in range(ring))])
        p = p + d * seg
        d = (step_rot @ d).normalized()
    tip = bm.verts.new(p)
    for r0, r1 in zip(rings, rings[1:]):
        for q in range(ring):
            bm.faces.new((r0[q], r0[(q + 1) % ring], r1[(q + 1) % ring], r1[q]))
    for q in range(ring):
        bm.faces.new((rings[-1][q], rings[-1][(q + 1) % ring], tip))
    bm.faces.new(list(reversed(rings[0])))


def claw_material(name):
    """Sarı-kahve boynuz; kökte ten tonuna yakın açık, uçta koyu (nesne uzayı değil, AO + alaca)."""
    mat, bsdf = kit.material(name, (0.30, 0.23, 0.12), rough=0.38)
    nt = mat.node_tree
    ramp = kit._mottle(nt, 30.0, (0.06, 0.045, 0.03), (0.34, 0.27, 0.15), low=0.35, high=0.75)
    kit._ao_darken(nt, ramp.outputs["Color"], bsdf, crevice=(0.03, 0.02, 0.015))
    bsdf.inputs["Specular IOR Level"].default_value = 0.55
    return mat


def build_claws(name, claws, mat, bend=55.0):
    bm = bmesh.new()
    for base, d, cup, length, radius in claws:
        claw_mesh(bm, base, d.normalized(), cup.normalized(), length, radius, bend)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def bone_spurs(pts, spine_ridge):
    """Dirsekten geriye kemik dikeni; çıplak gövdede omurga boyunca küçük çıkıntılar."""
    spurs = []
    for s in ("L", "R"):
        sh, el, wr = (pts[f"{k}_{s}"][0] for k in ("shoulder", "elbow", "wrist"))
        back = ((el - wr).normalized() + (el - sh).normalized()).normalized()
        out = Vector((1.0 if el.x > 0 else -1.0, 0.0, 0.0))
        spurs.append((el + back * pts[f"elbow_{s}"][1] * 0.5, back, out, 0.040, 0.010))
    if spine_ridge:
        chain = [pts[n][0] for n in ("belly", "spine", "chest", "upchest")]
        for a, b in zip(chain, chain[1:]):
            axis = (b - a).normalized()
            back = Vector((0.0, 1.0, 0.0))
            back = (back - axis * back.dot(axis)).normalized()
            for f in (0.25, 0.75):
                c = a.lerp(b, f)
                r = pts["spine"][1]
                spurs.append((c + back * r * 0.80, back, -axis, 0.022, 0.011))
    return spurs


# ---------------------------------------------------------------- kıyafet

def _ragged(co, amp, seed, scale=11.0):
    return amp * noise.noise(co * scale + Vector((seed, 0.0, 0.0)))


def _leg_frac(cls, t):
    return t * 0.5 if cls == "thigh" else (0.5 + t * 0.5 if cls == "shin" else None)


def build_clothes(body_obj, part, v, suffix):
    """part(co) -> (sınıf, t, radyal). Üst: track / torn / tank / None. Alt: hem bacak oranı."""
    seed, sm, top = v["seed"], CLOTH_EDGE_SMOOTH, v["top"]
    if top:
        sleeve_end = {"track": ("forearm", 0.92), "torn": ("forearm", 0.40), "tank": (None, 0.0)}[top]

        def keep_top(co):
            cls, t, _r = part(co)
            if cls.startswith("torso"):
                return True
            if cls == "hips":
                return t > 0.30 + _ragged(co, 0.25 if top == "torn" else 0.05, seed)
            if cls == "clav":
                return top != "tank" or t < 0.40
            if cls == "neck":
                return top == "track" and t < 0.25
            if sleeve_end[0] is None:
                return False
            if cls == "uparm":
                return True
            if cls == "forearm":
                return t < sleeve_end[1] + _ragged(co, 0.18 if top == "torn" else 0.0, seed)
            return False
        mat = kit.cloth_material("M_Runner_Top" + suffix, v["top_color"], blood=v["blood"])
        kit.garment(body_obj, "Runner_Top", keep_top, mat, offset=0.010,
                    holes=v.get("holes", 0.25), seed=seed, smooth_edges=sm)
    if v.get("stripe"):
        def keep_stripe(co):
            cls, t, r = part(co)
            frac = _leg_frac(cls, t)
            out = Vector((1.0 if co.x > 0 else -1.0, 0.0, 0.0))
            if cls in ("uparm", "forearm") or (frac is not None and frac < v["hem"] - 0.03):
                return r.dot(out) > 0.86 and not (cls == "forearm" and t > 0.88)
            return False
        mat = kit.cloth_material("M_Runner_Stripe" + suffix, v["stripe"])
        kit.garment(body_obj, "Runner_Stripe", keep_stripe, mat, offset=0.016, thickness=0.002,
                    seed=seed + 5.0, smooth_edges=sm)
    if v.get("bib"):
        def keep_bib(co):
            cls, t, r = part(co)
            return cls == "torso_mid" and r.y < -0.78 and 0.10 < t < 0.95
        mat = kit.cloth_material("M_Runner_Bib" + suffix, v["bib"], stain=(0.20, 0.18, 0.14), blood=0.5)
        kit.garment(body_obj, "Runner_Bib", keep_bib, mat, offset=0.017, thickness=0.0015,
                    seed=seed + 6.0, smooth_edges=sm)
    hem = v["hem"]

    def keep_bottom(co):
        cls, t, _r = part(co)
        if cls == "pelvis":
            return True
        if cls == "hips":
            return t < 0.62
        frac = _leg_frac(cls, t)
        return frac is not None and frac < hem + _ragged(co, v.get("hem_rag", 0.05), seed)
    mat = kit.cloth_material("M_Runner_Bottom" + suffix, v["bottom_color"], stain=(0.05, 0.04, 0.03))
    kit.garment(body_obj, "Runner_Bottom", keep_bottom, mat, offset=0.008, holes=0.18,
                seed=seed + 1.0, smooth_edges=sm)
