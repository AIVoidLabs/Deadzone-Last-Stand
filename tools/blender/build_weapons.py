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
}

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
    low: Vector = Vector((min(v.co.x for v in mesh.verts), min(v.co.y for v in mesh.verts), min(v.co.z for v in mesh.verts)))
    high: Vector = Vector((max(v.co.x for v in mesh.verts), max(v.co.y for v in mesh.verts), max(v.co.z for v in mesh.verts)))
    bmesh.ops.translate(mesh, verts=mesh.verts, vec=-(low + high) * 0.5)
    data = bpy.data.meshes.new(name)
    mesh.to_mesh(data)
    mesh.free()
    data.materials.append(material)
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    data.calc_loop_triangles()
    log("%s: %d üçgen, boy %.2f m" % (name, len(data.loop_triangles), high.y - low.y))
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
