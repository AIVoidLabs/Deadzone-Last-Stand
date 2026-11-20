"""Koşucu (Pençeli) kıyafet kuralları (V.5 v2). Kumaş yapımı runner_parts.garment'te.

Kesim iskelet parçası boyunca (t) yapılır: koşucu çömelince gövde alçalır, aynı kıyafet her pozda
aynı yere düşer. part(co) -> (sınıf, t, radyal, ...). Üst: track (eşofman) / torn (yırtık gömlek) /
tank (atlet) / None. Alt: hem = paçanın bacak oranı (0 kalça .. 1 bilek).
"""
from mathutils import Vector, noise

import zombie_kit as kit
import runner_parts as rp


def _ragged(co, amp, seed, scale=11.0):
    return amp * noise.noise(co * scale + Vector((seed, 0.0, 0.0)))


def _leg_frac(cls, t):
    return t * 0.5 if cls == "thigh" else (0.5 + t * 0.5 if cls == "shin" else None)


def _top(body_obj, part, v, suffix):
    seed, top = v["seed"], v["top"]
    sleeve = {"track": 0.90, "torn": 0.45, "tank": None}[top]

    def keep(co):
        cls, t, _r = part(co)[:3]
        if cls.startswith("torso"):
            return True
        if cls == "hips":
            return t > 0.30 + _ragged(co, 0.25 if top == "torn" else 0.04, seed)
        if cls == "clav":
            return top != "tank" or t < 0.45
        if cls == "neck":
            return top == "track" and t < 0.30
        if sleeve is None:
            return False
        if cls == "uparm":
            return True
        if cls == "forearm":
            return t < sleeve + _ragged(co, 0.16 if top == "torn" else 0.0, seed)
        return False
    mat = kit.cloth_material("M_Runner_Top" + suffix, v["top_color"], blood=v["blood"])
    return rp.garment(body_obj, "Runner_Top", keep, mat, part, base=0.004, loose=0.009, thickness=0.0028,
                      holes=v.get("holes", 0.2), seed=seed, hem=0.0015 if top == "torn" else 0.003)


def _stripe(body_obj, part, v, suffix):
    def keep(co):
        cls, t, r = part(co)[:3]
        frac = _leg_frac(cls, t)
        out = Vector((1.0 if co.x > 0 else -1.0, 0.0, 0.0))
        if cls in ("uparm", "forearm") or (frac is not None and frac < v["hem"] - 0.04):
            return r.dot(out) > 0.88 and not (cls == "forearm" and t > 0.86)
        return False
    mat = kit.cloth_material("M_Runner_Stripe" + suffix, v["stripe"])
    return rp.garment(body_obj, "Runner_Stripe", keep, mat, part, base=0.011, loose=0.014,
                      thickness=0.0015, seed=v["seed"] + 5.0, hem=0.0)


def _bib(body_obj, part, v, suffix):
    def keep(co):
        cls, t, r = part(co)[:3]
        return cls == "torso_mid" and r.y < -0.78 and 0.15 < t < 0.95
    mat = kit.cloth_material("M_Runner_Bib" + suffix, v["bib"], stain=(0.20, 0.18, 0.14), blood=0.5)
    return rp.garment(body_obj, "Runner_Bib", keep, mat, part, base=0.016, loose=0.0,
                      thickness=0.0015, seed=v["seed"] + 6.0, hem=0.0)


def _bottom(body_obj, part, v, suffix):
    hem, seed = v["hem"], v["seed"]

    def keep(co):
        cls, t, _r = part(co)[:3]
        if cls == "pelvis":
            return True
        if cls == "hips":
            return t < 0.62
        frac = _leg_frac(cls, t)
        return frac is not None and frac < hem + _ragged(co, v.get("hem_rag", 0.04), seed)
    mat = kit.cloth_material("M_Runner_Bottom" + suffix, v["bottom_color"], stain=(0.05, 0.04, 0.03))
    return rp.garment(body_obj, "Runner_Bottom", keep, mat, part, base=0.006, loose=0.004,
                      holes=0.15, seed=seed + 1.0, hem=0.004)


def build_clothes(body_obj, part, v, suffix):
    """Kıyafet nesneleri (üst, şerit, numara, alt)."""
    out = []
    if v["top"]:
        out.append(_top(body_obj, part, v, suffix))
    if v.get("stripe"):
        out.append(_stripe(body_obj, part, v, suffix))
    if v.get("bib"):
        out.append(_bib(body_obj, part, v, suffix))
    out.append(_bottom(body_obj, part, v, suffix))
    return out
