"""Taş fırlatanın kıyafetleri (7.3): inşaat işçisi. build_thrower.py içe aktarır.

Kumaş yöntemi tank_clothes.garment (içe aktarılır, düzenlenmez): kıvrım, yırtık kenar halkası gevşetilir,
dışa kıvrılıp kalınlaşır. Hikâye: sağ kol şişip kolunu patlatmış — sağ kol her çeşitte çıplak, kumaş
omuzda yırtık bir yaka gibi biter; sol kolda kol yeni sağlam (sıska kol bol kolun içinde kaybolur).
- vest : gri tişört + açık önlü turuncu yelek, iki gümüş yansıtıcı şerit; kargo pantolon, bot.
- flannel: ekose (kırmızı-siyah) gömlek, sol kol uzun ve bol; kot, bot.
- bare : çıplak üst, kemerli koyu iş pantolonu, yalın ayak (parmaklı).
"""
import bmesh

import tank_clothes as tc
import walker_clothes as wc
import zombie_kit as kit

STRIPE = (0.55, 0.56, 0.52)          # yansıtıcı şerit (doğrusal)
STRIPE_Z = (-0.03, -0.20)            # göğüs noktasına göre şerit yükseklikleri (m)
STRIPE_HALF = 0.030
PLAID_A, PLAID_B = (0.30, 0.025, 0.02), (0.02, 0.018, 0.02)
PLAID_STEP = 0.075                   # ekose kare boyu (m)


def plaid_material(name, blood):
    """Ekose: iki yönde dalga bantları çarpılır (kırmızı zemin, koyu çizgiler)."""
    mat = kit.cloth_material(name, PLAID_A, stain=(0.06, 0.03, 0.02), blood=blood)
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    link = next(lk for lk in nt.links if lk.to_socket == bsdf.inputs["Base Color"])
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(coord.outputs["Object"], sep.inputs["Vector"])
    bands = []
    for axis in ("X", "Z"):
        m = nt.nodes.new("ShaderNodeMath")
        m.operation = "PINGPONG"
        m.inputs[1].default_value = PLAID_STEP * 0.5
        nt.links.new(sep.outputs[axis], m.inputs[0])
        g = nt.nodes.new("ShaderNodeMath")
        g.operation = "GREATER_THAN"
        g.inputs[1].default_value = PLAID_STEP * 0.30
        nt.links.new(m.outputs[0], g.inputs[0])
        bands.append(g)
    mx = nt.nodes.new("ShaderNodeMath")
    mx.operation = "MAXIMUM"
    nt.links.new(bands[0].outputs[0], mx.inputs[0])
    nt.links.new(bands[1].outputs[0], mx.inputs[1])
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    nt.links.new(mx.outputs[0], mix.inputs["Factor"])
    nt.links.new(link.from_socket, mix.inputs["A"])
    mix.inputs["B"].default_value = (0.12, 0.12, 0.14, 1.0)
    nt.links.remove(link)
    nt.links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
    return mat


def plaid_dark(p) -> bool:
    """Oyun köşe rengi için aynı ekose deseni (dünya x, z)."""
    def band(x):
        u = (x / PLAID_STEP) % 1.0
        return abs(u - 0.5) * PLAID_STEP > PLAID_STEP * 0.30 - 1e-9
    return band(p.x) or band(p.z)


def build_clothes(body_obj, part, pts, v, suffix):
    seed = v["seed"]
    w = v["body"]["w"]
    waist = pts["pelvis"][0].z + 0.17
    chest = pts["chest"][0]
    made = []
    top = v["top"]
    if top:
        def keep_top(co):
            cls, t = part(co)
            right = co.x < 0.0
            if cls in ("torso", "neck"):
                return cls == "torso" and co.z < pts["upchest"][0].z - 0.03
            if cls == "hips":
                return co.z > waist - 0.10
            if cls == "clav":
                return t < (0.55 if right else 1.0)
            if cls == "uparm" and not right:
                return t < v["sleeve"] + 0.06 * tc._n(co, 9.0, seed)
            if cls == "forearm" and not right and v["sleeve"] > 1.0:
                return t < v["sleeve"] - 1.0 + 0.06 * tc._n(co, 9.0, seed)
            return False
        mat = (plaid_material("M_Thrower_Top" + suffix, v["blood"]) if top == "flannel"
               else kit.cloth_material("M_Thrower_Top" + suffix, v["top_color"], blood=v["blood"]))
        made.append(tc.garment(body_obj, "Thrower_Top", keep_top, mat, part, "shirt", seed,
                               offset=0.010, holes=v.get("holes", 0.2), loose=0.0))
    if v.get("vest"):
        def keep_vest(co):
            cls, t = part(co)
            if cls not in ("torso", "clav", "hips"):
                return False
            if cls == "clav" and t > 0.45:
                return False
            if cls == "hips" and co.z < waist - 0.06:
                return False
            return not (co.y < 0.0 and abs(co.x + 0.02) < 0.055)      # açık ön
        vmat = kit.cloth_material("M_Thrower_Vest" + suffix, v["vest"], stain=(0.12, 0.06, 0.02), blood=0.3)
        made.append(tc.garment(body_obj, "Thrower_Vest", keep_vest, vmat, part, "vest", seed + 3.0,
                               offset=0.024, thickness=0.009, holes=0.08, smooth_edges=10))
        smat, _ = kit.material("M_Thrower_Stripe" + suffix, STRIPE, rough=0.35)
        for dz in STRIPE_Z:
            def keep_stripe(co, dz=dz):
                return keep_vest(co) and abs(co.z - chest.z - dz) < STRIPE_HALF
            made.append(tc.garment(body_obj, "Thrower_Stripe", keep_stripe, smat, part, "stripe", seed,
                                   offset=0.036, thickness=0.004, smooth_edges=2))
    if v.get("belt"):
        def keep_belt(co):
            return part(co)[0] in ("hips", "torso") and abs(co.z - waist + 0.02) < 0.035
        bmat, _ = kit.material("M_Thrower_Belt" + suffix, v["belt"], rough=0.5)
        made.append(tc.garment(body_obj, "Thrower_Belt", keep_belt, bmat, part, "belt", seed,
                               offset=0.024, thickness=0.012, smooth_edges=6))
    hem = v["hem"]

    def keep_bottom(co):
        cls, t = part(co)
        if cls in ("hips", "torso"):
            return co.z < waist
        if cls == "thigh":
            return True
        if cls == "shin":
            return t < hem + 0.06 * tc._n(co, 9.0, seed)
        return False
    mat = kit.cloth_material("M_Thrower_Bottom" + suffix, v["bottom_color"], stain=(0.06, 0.05, 0.03))
    made.append(tc.garment(body_obj, "Thrower_Bottom", keep_bottom, mat, part, "pants", seed + 1.0,
                           offset=0.010, holes=0.18, loose=0.010))
    return made


def build_shoes(body_obj, pts, part, v, suffix):
    """İş botu: walker_clothes.build_shoe (ölçekli, bilek yakası yüksek değil) + gövdede ayak silinir."""
    mat, _ = kit.material("M_Thrower_Shoes" + suffix, v["shoes"], rough=0.6)
    sole, _ = kit.material("M_Thrower_Sole" + suffix, (0.015, 0.014, 0.013), rough=0.8)
    shoes = [wc.build_shoe(pts, side, mat, sole, 1.25) for side in ("L", "R")]
    bm = bmesh.new()
    bm.from_mesh(body_obj.data)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if part(f.calc_center_median())[0] == "foot"],
                     context="FACES")
    bm.to_mesh(body_obj.data)
    bm.free()
    return shoes


def stripe_hit(p, chest_z) -> bool:
    return any(abs(p.z - chest_z - dz) < STRIPE_HALF + 0.004 for dz in STRIPE_Z)

