"""Silah modelleri: low-poly, düz renkli, tek palet dokusu. Her silah ayrı nesne, tek dosyada.

Çalıştırma (repo kökünden, Blender penceresi açılmaz):
    blender --background --python tools/blender/build_weapons.py

Çıktı : assets/models/weapons/weapons.glb (nesneler: Pistol, Shotgun ...)
        build/blender/weapons.blend

Silahlar gerçek boyutta kurulur (oyunda veri satırındaki model_scale ile büyütülür), namlu -Y yönüne
bakar (Godot'da +Z), kökeni sınır kutusunun ortasıdır. Yeni silah = WEAPONS'a bir parça listesi.
Parça: ("box", merkez, boyut, renk) ya da ("tube", merkez, yarıçap, uzunluk, renk) — tüp Y ekseninde.
"""

import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

REPO: str = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUTPUT: str = os.path.join(REPO, "assets", "models", "weapons", "weapons.glb")
BLEND_OUTPUT: str = os.path.join(REPO, "build", "blender", "weapons.blend")
PALETTE_FILE: str = os.path.join(REPO, "build", "blender", "weapon_palette.png")
PALETTE_CELL_PIXELS: int = 4
TUBE_SIDES: int = 8

# Askerin renkleriyle uyumlu: koyu metal, lacivert, turuncu vurgu.
COLORS: dict = {
    "metal": (0.24, 0.26, 0.29),
    "dark": (0.11, 0.12, 0.14),
    "navy": (0.14, 0.20, 0.36),
    "orange": (0.95, 0.50, 0.15),
    "wood": (0.36, 0.23, 0.13),
    "steel": (0.55, 0.57, 0.60),
    # Yakın dövüş (7.1)
    "edge": (0.86, 0.89, 0.93),
    "gold": (0.78, 0.60, 0.20),
    "cyan": (0.30, 0.78, 1.00),
    "white": (0.92, 0.97, 1.00),
    "yellow": (1.00, 0.78, 0.18),
    "ember": (1.00, 0.36, 0.06),
    "leather": (0.20, 0.12, 0.08),
    "violet": (0.62, 0.38, 1.00),
    "olive": (0.24, 0.30, 0.19),
}

# Yakın dövüş silahlarının kökeni kabzanın tuttuğu nokta (savururken buradan döner); kılıç -Y'ye (Godot +Z) uzanır.
GRIP_ORIGIN: set = {"Knife", "Katana", "Lightsaber", "FlameSword"}


def flame_blade() -> list:
    """Ateşli kılıç ağzı: üst üste dizilmiş, dalgalı genişlikte kor ve sarı dilimler."""
    widths: list = [0.050, 0.074, 0.054, 0.078, 0.050, 0.064, 0.036]
    parts: list = []
    y: float = -0.06
    for index, width in enumerate(widths):
        length: float = 0.115
        color: str = "ember" if index % 2 == 0 else "yellow"
        parts.append(("box", (0.0, y - length * 0.5, 0.0), (width, length, 0.012), color))
        y -= length
    parts.append(("box", (0.0, -0.45, 0.0), (0.016, 0.80, 0.016), "white"))  # sıcak çekirdek
    parts.append(("box", (0.0, y - 0.02, 0.0), (0.018, 0.04, 0.010), "yellow"))  # uç
    return parts

WEAPONS: dict = {
    "Pistol": [
        ("box", (0.0, -0.045, 0.030), (0.030, 0.190, 0.034), "metal"),  # kızak
        ("box", (0.0, -0.040, 0.000), (0.027, 0.165, 0.026), "navy"),  # gövde
        ("box", (0.0, 0.035, -0.055), (0.026, 0.045, 0.095), "dark"),  # kabza
        ("box", (0.0, -0.020, -0.030), (0.010, 0.040, 0.008), "dark"),  # tetik korkuluğu
        ("box", (0.016, -0.060, 0.030), (0.003, 0.110, 0.010), "orange"),  # yan şerit
        ("box", (-0.016, -0.060, 0.030), (0.003, 0.110, 0.010), "orange"),
        ("tube", (0.0, -0.145, 0.030), 0.008, 0.012, "steel"),  # namlu ağzı
    ],
    "Shotgun": [
        ("tube", (0.0, -0.360, 0.040), 0.014, 0.560, "metal"),  # namlu
        ("tube", (0.0, -0.300, 0.012), 0.013, 0.440, "dark"),  # şarjör tüpü
        ("box", (0.0, -0.300, 0.020), (0.040, 0.150, 0.045), "wood"),  # pompa
        ("box", (0.0, -0.035, 0.025), (0.040, 0.170, 0.070), "navy"),  # mekanizma
        ("box", (0.0, -0.010, -0.030), (0.012, 0.050, 0.012), "dark"),  # tetik korkuluğu
        ("box", (0.0, 0.110, 0.005), (0.036, 0.130, 0.055), "wood"),  # kabza boynu
        ("box", (0.0, 0.230, -0.020), (0.040, 0.140, 0.085), "wood"),  # dipçik
        ("box", (0.0, 0.302, -0.020), (0.042, 0.010, 0.090), "dark"),  # dipçik tabanı
        ("box", (0.021, -0.040, 0.025), (0.003, 0.120, 0.014), "orange"),  # yan şerit
        ("box", (-0.021, -0.040, 0.025), (0.003, 0.120, 0.014), "orange"),
        ("tube", (0.0, -0.645, 0.040), 0.016, 0.012, "orange"),  # namlu bileziği
    ],
    "Smg": [
        ("box", (0.0, -0.030, 0.010), (0.032, 0.240, 0.046), "metal"),  # gövde
        ("box", (0.0, -0.140, 0.020), (0.028, 0.100, 0.032), "navy"),  # namlu kılıfı
        ("tube", (0.0, -0.205, 0.020), 0.010, 0.060, "dark"),  # namlu
        ("box", (0.0, -0.020, -0.070), (0.022, 0.045, 0.110), "dark"),  # şarjör
        ("box", (0.0, 0.060, -0.045), (0.026, 0.040, 0.080), "dark"),  # kabza
        ("box", (0.0, 0.170, 0.000), (0.020, 0.100, 0.030), "metal"),  # dipçik
        ("box", (0.0, -0.050, 0.046), (0.010, 0.050, 0.012), "orange"),  # nişangah
        ("box", (0.018, -0.050, 0.020), (0.003, 0.120, 0.010), "orange"),  # yan şerit
        ("box", (-0.018, -0.050, 0.020), (0.003, 0.120, 0.010), "orange"),
    ],
    "PlasmaRifle": [
        ("box", (0.0, -0.020, 0.020), (0.050, 0.340, 0.060), "navy"),  # gövde
        ("tube", (0.0, -0.300, 0.030), 0.016, 0.220, "metal"),  # namlu
        ("tube", (0.0, -0.225, 0.030), 0.024, 0.030, "cyan"),  # bobinler
        ("tube", (0.0, -0.300, 0.030), 0.024, 0.030, "cyan"),
        ("tube", (0.0, -0.425, 0.030), 0.026, 0.024, "cyan"),  # yayıcı halka
        ("box", (0.0, -0.090, 0.052), (0.030, 0.170, 0.010), "cyan"),  # çekirdek şeridi
        ("box", (0.0, 0.000, 0.075), (0.010, 0.200, 0.030), "cyan"),  # üst yüzgeç
        ("box", (0.0, 0.080, -0.050), (0.030, 0.050, 0.100), "dark"),  # kabza
        ("box", (0.0, 0.200, 0.000), (0.045, 0.140, 0.060), "navy"),  # dipçik
        ("box", (0.026, -0.030, 0.020), (0.003, 0.200, 0.014), "orange"),  # yan şerit
        ("box", (-0.026, -0.030, 0.020), (0.003, 0.200, 0.014), "orange"),
    ],
    "GravityGun": [
        ("tube", (0.0, -0.050, 0.020), 0.034, 0.200, "metal"),  # gövde
        ("tube", (0.0, -0.120, 0.020), 0.040, 0.030, "violet"),  # çekirdek halkası
        ("tube", (0.0, -0.200, 0.020), 0.062, 0.030, "violet"),  # tabak
        ("tube", (0.0, -0.228, 0.020), 0.046, 0.024, "white"),  # tabak içi
        ("box", (0.0, 0.070, 0.020), (0.050, 0.080, 0.050), "navy"),  # arka blok
        ("box", (0.0, 0.080, -0.050), (0.030, 0.050, 0.100), "dark"),  # kabza
        ("box", (0.0, -0.050, 0.062), (0.010, 0.160, 0.022), "violet"),  # üst yüzgeç
        ("box", (0.036, -0.050, 0.020), (0.003, 0.130, 0.012), "orange"),  # yan şerit
        ("box", (-0.036, -0.050, 0.020), (0.003, 0.130, 0.012), "orange"),
    ],
    "GrenadeLauncher": [
        ("tube", (0.0, -0.220, 0.030), 0.040, 0.340, "olive"),  # namlu
        ("tube", (0.0, -0.400, 0.030), 0.046, 0.020, "dark"),  # ağız halkası
        ("tube", (0.0, -0.120, 0.030), 0.042, 0.015, "orange"),  # uyarı halkası
        ("tube", (0.0, -0.020, 0.000), 0.052, 0.070, "metal"),  # tambur
        ("box", (0.0, 0.050, 0.000), (0.050, 0.140, 0.060), "navy"),  # gövde
        ("box", (0.0, 0.060, -0.060), (0.030, 0.050, 0.100), "dark"),  # kabza
        ("box", (0.0, 0.200, 0.000), (0.040, 0.140, 0.070), "olive"),  # dipçik
        ("box", (0.0, -0.100, 0.080), (0.010, 0.060, 0.030), "orange"),  # nişangah
    ],
    "Knife": [
        ("box", (0.0, 0.060, 0.0), (0.030, 0.120, 0.034), "leather"),  # sap
        ("tube", (0.0, 0.125, 0.0), 0.019, 0.016, "metal"),  # sap başı
        ("box", (0.0, -0.005, 0.0), (0.074, 0.016, 0.030), "metal"),  # siper
        ("box", (0.0, -0.125, 0.0), (0.032, 0.230, 0.008), "steel"),  # ağız
        ("box", (0.0, -0.125, 0.0), (0.006, 0.230, 0.010), "edge"),  # sırt çizgisi
        ("box", (0.0, -0.250, 0.0), (0.022, 0.030, 0.007), "steel"),  # uç
        ("box", (0.0, -0.272, 0.0), (0.010, 0.016, 0.006), "edge"),
    ],
    "Katana": [
        ("box", (0.0, 0.100, 0.0), (0.032, 0.200, 0.034), "navy"),  # tsuka (sap)
        ("box", (0.0, 0.060, 0.0), (0.036, 0.016, 0.038), "orange"),  # sargı bantları
        ("box", (0.0, 0.110, 0.0), (0.036, 0.016, 0.038), "orange"),
        ("box", (0.0, 0.160, 0.0), (0.036, 0.016, 0.038), "orange"),
        ("tube", (0.0, 0.205, 0.0), 0.020, 0.018, "gold"),  # kabza ucu
        ("tube", (0.0, -0.008, 0.0), 0.046, 0.014, "gold"),  # tsuba (siper)
        ("box", (0.0, -0.460, 0.0), (0.046, 0.900, 0.009), "steel"),  # ağız
        ("box", (0.0, -0.460, 0.0), (0.012, 0.900, 0.011), "edge"),  # hamon çizgisi
        ("box", (0.0, -0.930, 0.0), (0.022, 0.040, 0.007), "steel"),  # uç
        ("box", (0.0, -0.960, 0.0), (0.010, 0.020, 0.006), "edge"),
    ],
    "Lightsaber": [
        ("tube", (0.0, 0.130, 0.0), 0.024, 0.300, "metal"),  # kabza
        ("tube", (0.0, 0.200, 0.0), 0.027, 0.024, "dark"),  # tutuş halkaları
        ("tube", (0.0, 0.140, 0.0), 0.027, 0.024, "dark"),
        ("tube", (0.0, 0.080, 0.0), 0.027, 0.024, "dark"),
        ("box", (0.0, 0.150, 0.026), (0.016, 0.040, 0.008), "orange"),  # düğme
        ("tube", (0.0, -0.030, 0.0), 0.032, 0.050, "steel"),  # yayıcı
        ("tube", (0.0, -0.560, 0.0), 0.030, 1.020, "cyan"),  # ışın
        ("tube", (0.0, -0.560, 0.0), 0.016, 1.030, "white"),  # ışın çekirdeği
        ("tube", (0.0, -1.075, 0.0), 0.024, 0.020, "cyan"),  # uç
    ],
    "FlameSword": [
        ("box", (0.0, 0.100, 0.0), (0.034, 0.200, 0.034), "leather"),  # sap
        ("tube", (0.0, 0.205, 0.0), 0.022, 0.020, "gold"),
        ("box", (0.0, -0.012, 0.0), (0.120, 0.020, 0.036), "gold"),  # siper
        ("box", (0.050, -0.040, 0.0), (0.026, 0.050, 0.030), "gold"),  # siper pençeleri
        ("box", (-0.050, -0.040, 0.0), (0.026, 0.050, 0.030), "gold"),
    ] + flame_blade(),
}


def log(message: str) -> None:
    print("[build_weapons] " + message)
    sys.stdout.flush()


def color_uv(name: str) -> tuple:
    names: list = list(COLORS)
    return ((names.index(name) + 0.5) / len(names), 0.5)


def build_palette_image():
    names: list = list(COLORS)
    cell: int = PALETTE_CELL_PIXELS
    width: int = len(names) * cell
    image = bpy.data.images.new("weapon_palette", width, cell, alpha=False)
    pixels: list = []
    for _y in range(cell):
        for x in range(width):
            pixels += list(COLORS[names[x // cell]]) + [1.0]
    image.pixels = pixels
    os.makedirs(os.path.dirname(PALETTE_FILE), exist_ok=True)
    image.filepath_raw = PALETTE_FILE
    image.file_format = "PNG"
    image.save()
    image.pack()
    return image


def add_part(mesh, uv_layer, part: tuple) -> None:
    kind: str = part[0]
    before: set = set(mesh.faces)
    if kind == "box":
        _, center, size, color = part
        matrix: Matrix = Matrix.Translation(Vector(center)) @ Matrix.Diagonal(Vector(size).to_4d())
        bmesh.ops.create_cube(mesh, size=1.0, matrix=matrix)
    else:
        _, center, radius, length, color = part
        # Koni Z ekseninde üretilir; X etrafında 90 derece çevrilip Y eksenine yatırılır.
        matrix = Matrix.Translation(Vector(center)) @ Matrix.Rotation(1.5707963, 4, "X")
        bmesh.ops.create_cone(mesh, cap_ends=True, segments=TUBE_SIDES, radius1=radius, radius2=radius,
                              depth=length, matrix=matrix)
    uv: tuple = color_uv(color)
    for face in set(mesh.faces) - before:
        face.smooth = False
        for loop in face.loops:
            loop[uv_layer].uv = uv


def build_weapon(name: str, parts: list, material):
    mesh = bmesh.new()
    uv_layer = mesh.loops.layers.uv.new("UVMap")
    for part in parts:
        add_part(mesh, uv_layer, part)
    # Kökeni sınır kutusunun ortasına al: süzülen silah kendi merkezi etrafında döner.
    if name in GRIP_ORIGIN:
        return finish_weapon(name, mesh, material, None)
    low: Vector = Vector((min(v.co.x for v in mesh.verts), min(v.co.y for v in mesh.verts), min(v.co.z for v in mesh.verts)))
    high: Vector = Vector((max(v.co.x for v in mesh.verts), max(v.co.y for v in mesh.verts), max(v.co.z for v in mesh.verts)))
    bmesh.ops.translate(mesh, verts=mesh.verts, vec=-(low + high) * 0.5)
    return finish_weapon(name, mesh, material, (low, high))


def finish_weapon(name: str, mesh, material, bounds):
    data = bpy.data.meshes.new(name)
    mesh.to_mesh(data)
    mesh.free()
    data.materials.append(material)
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    data.calc_loop_triangles()
    length: float = (bounds[1].y - bounds[0].y) if bounds is not None else (max(v.co.y for v in data.vertices) - min(v.co.y for v in data.vertices))
    log("%s: %d üçgen, boy %.2f m" % (name, len(data.loop_triangles), length))
    return obj


def build_material():
    material = bpy.data.materials.new("WeaponMaterial")
    tree = material.node_tree
    if tree is None:
        material.use_nodes = True
        tree = material.node_tree
    shader = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
    shader.inputs["Roughness"].default_value = 0.6
    shader.inputs["Metallic"].default_value = 0.0
    texture = tree.nodes.new("ShaderNodeTexImage")
    texture.interpolation = "Closest"
    tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])
    return material, texture


def export(objects: list) -> None:
    os.makedirs(os.path.dirname(BLEND_OUTPUT), exist_ok=True)
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUTPUT)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=OUTPUT, export_format="GLB", use_selection=True,
                              export_animations=False, export_yup=True, export_image_format="AUTO")
    log("yazıldı: %s (%.0f KB)" % (os.path.relpath(OUTPUT, REPO), os.path.getsize(OUTPUT) / 1024.0))


def main() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    material, texture = build_material()
    objects: list = [build_weapon(name, parts, material) for name, parts in WEAPONS.items()]
    texture.image = build_palette_image()
    export(objects)
    log("bitti")


main()
