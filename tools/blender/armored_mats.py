"""Zırhlı zombinin konsept malzemeleri (7.3): plastik zırh, metal, vizör. Oyunda köşe rengi (armored_game).

Plastik: renkli, yarı mat, kenarlarda (pointiness) açık sürtünme izi, kir alacası.
Metal: metalik, parlak; kenarda parlak aşınma, yüzeyde pas lekeleri.
Vizör: koyu dumanlı, parlak kaplama; çatlak çizgileri 'crack' köşe özniteliğinden açık renk.
"""
import zombie_kit as kit

GRIME = (0.025, 0.022, 0.018)
RUST = (0.16, 0.06, 0.025)


def _edge_wear(nt, color_socket, wear_color, lo=0.52, hi=0.58):
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    edge = nt.nodes.new("ShaderNodeMapRange")
    edge.inputs["From Min"].default_value = lo
    edge.inputs["From Max"].default_value = hi
    nt.links.new(geo.outputs["Pointiness"], edge.inputs["Value"])
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.inputs["B"].default_value = (*wear_color, 1.0)
    nt.links.new(edge.outputs["Result"], mix.inputs["Factor"])
    nt.links.new(color_socket, mix.inputs["A"])
    return mix.outputs["Result"]


def plastic(name, color, rough=0.48):
    mat, bsdf = kit.material(name, color, rough=rough)
    bsdf.inputs["Specular IOR Level"].default_value = 0.45
    nt = mat.node_tree
    grime = tuple(c * 0.45 + g * 0.3 for c, g in zip(color, GRIME))
    ramp = kit._mottle(nt, 5.0, grime, color, low=0.50, high=0.80)
    wear = tuple(min(1.0, c * 2.2 + 0.07) for c in color)
    out = _edge_wear(nt, ramp.outputs["Color"], wear)
    kit._ao_darken(nt, out, bsdf, crevice=(0.01, 0.01, 0.01))
    kit._bump(nt, bsdf, 90.0, 0.06)
    return mat


def metal(name, color, rough=0.38):
    mat, bsdf = kit.material(name, color, rough=rough)
    bsdf.inputs["Metallic"].default_value = 1.0
    nt = mat.node_tree
    ramp = kit._mottle(nt, 7.0, RUST, color, low=0.55, high=0.78)
    bright = tuple(min(1.0, c * 2.0 + 0.25) for c in color)
    out = _edge_wear(nt, ramp.outputs["Color"], bright, 0.51, 0.56)
    kit._ao_darken(nt, out, bsdf, crevice=(0.02, 0.015, 0.01))
    kit._bump(nt, bsdf, 140.0, 0.08)
    return mat


def visor(name, color=(0.035, 0.042, 0.05), crack=(0.30, 0.32, 0.34)):
    mat, bsdf = kit.material(name, color, rough=0.12, coat=1.0)
    nt = mat.node_tree
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "crack"
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.inputs["A"].default_value = (*color, 1.0)
    mix.inputs["B"].default_value = (*crack, 1.0)
    nt.links.new(attr.outputs["Fac"], mix.inputs["Factor"])
    nt.links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
    return mat


def cloth(name, color, blood=0.0, stain=(0.06, 0.05, 0.04)):
    return kit.cloth_material(name, color, stain=stain, blood=blood)


def make(kind, color, name):
    """Yuva türünden konsept malzemesi: plastic / metal / visor / rubber / cloth."""
    if kind == "metal":
        return metal(name, color)
    if kind == "visor":
        return visor(name, color)
    if kind == "rubber":
        return plastic(name, color, rough=0.8)
    if kind == "cloth":
        return cloth(name, color)
    return plastic(name, color)


def assign(obj, slots, name):
    """Nesneye yuva malzemelerini ve oyun boyaması için yuva tablosunu (özellik) yazar."""
    import json
    idx = [p.material_index for p in obj.data.polygons]      # clear() yuva indislerini sıfırlıyor
    obj.data.materials.clear()
    for i, (kind, color) in enumerate(slots):
        obj.data.materials.append(make(kind, color, "%s_%d" % (name, i)))
    for p, i in zip(obj.data.polygons, idx):
        p.material_index = min(i, len(slots) - 1)
    obj["slots"] = json.dumps([[k, list(c)] for k, c in slots])
    return obj
