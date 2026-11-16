"""Yürüyen zombi: low-poly, 25 kemikli ortak iskelette, tek dosyada birkaç çeşit.

Çalıştırma (repo kökünden, Blender penceresi açılmaz):
    blender --background --python tools/blender/build_zombie.py

Girdi : assets/models/characters/mannequin.glb (iskelet ve dinlenme pozu kaynağı)
Çıktı : assets/models/characters/zombie_walker.glb (her çeşit ayrı ağ: Variant_A, Variant_B ...)
        build/blender/zombie_walker.blend

Gövde, kemik hizalarına dizilen halkaların birleştirilmesiyle (loft) kurulur; ağırlıklar
halka başına elle verilir, renkler tek bir palet dokusundan gelir. Yeni çeşit = VARIANTS'a satır.
"""

import math
import os
import sys

import bmesh
import bpy
from mathutils import Vector

REPO: str = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SKELETON_SOURCE: str = os.path.join(REPO, "assets", "models", "characters", "mannequin.glb")
OUTPUT: str = os.path.join(REPO, "assets", "models", "characters", "zombie_walker.glb")
BLEND_OUTPUT: str = os.path.join(REPO, "build", "blender", "zombie_walker.blend")
PALETTE_FILE: str = os.path.join(REPO, "build", "blender", "zombie_palette.png")

PALETTE_CELLS: int = 8
PALETTE_CELL_PIXELS: int = 4
TORSO_SIDES: int = 8
LIMB_SIDES: int = 6

# Ortak iskeletin eklem hizaları (m; x: sola +, y: öne -, z: yukarı). Kaynak: mannequin.glb.
HIP_X: float = 0.089
HIP_Z: float = 0.93
KNEE_Z: float = 0.532
ANKLE_Z: float = 0.104
SHOULDER_X: float = 0.20
ELBOW_X: float = 0.466
WRIST_X: float = 0.739
ARM_Y: float = 0.065
ARM_Z: float = 1.441
NECK_Z: float = 1.50
HEAD_Z: float = 1.56

BLOOD: tuple = (0.45, 0.05, 0.05)
MOUTH: tuple = (0.12, 0.03, 0.03)
EYE: tuple = (0.98, 0.92, 0.45)
BONE_WHITE: tuple = (0.85, 0.82, 0.72)

# Çeşitler. Ölçüler çarpan; renkler sRGB. arm_cut: o kolun dirsekten kopuk olduğu taraf (+1 sol, -1 sağ, 0 yok).
VARIANTS: list = [
    {
        "name": "Variant_A",  # gömlekli, kel
        "skin": (0.47, 0.58, 0.42), "shirt": (0.72, 0.70, 0.62), "pants": (0.20, 0.21, 0.26),
        "shoes": (0.12, 0.10, 0.09), "hair": None, "torso": 1.0, "belly": 1.0, "limb": 1.0, "head": 1.25,
        "arm_cut": 0, "sleeve": 0.55, "pants_end": 0.20, "bare_chest": False, "hood": False, "bloody_shirt": True,
    },
    {
        "name": "Variant_B",  # iri, göbekli
        "skin": (0.55, 0.60, 0.38), "shirt": (0.62, 0.52, 0.22), "pants": (0.33, 0.24, 0.17),
        "shoes": (0.15, 0.12, 0.10), "hair": (0.16, 0.12, 0.09), "torso": 1.18, "belly": 1.45, "limb": 1.2, "head": 1.22,
        "arm_cut": 0, "sleeve": 0.3, "pants_end": 0.32, "bare_chest": False, "hood": False, "bloody_shirt": False,
    },
    {
        "name": "Variant_C",  # sıska, çıplak gövde, tek kol kopuk
        "skin": (0.56, 0.62, 0.55), "shirt": (0.56, 0.62, 0.55), "pants": (0.36, 0.37, 0.36),
        "shoes": (0.56, 0.62, 0.55), "hair": (0.22, 0.20, 0.17), "torso": 0.86, "belly": 0.8, "limb": 0.82, "head": 1.22,
        "arm_cut": 1, "sleeve": 0.0, "pants_end": 0.42, "bare_chest": True, "hood": False, "bloody_shirt": False,
    },
    {
        "name": "Variant_D",  # kapüşonlu
        "skin": (0.40, 0.52, 0.46), "shirt": (0.42, 0.14, 0.15), "pants": (0.13, 0.13, 0.15),
        "shoes": (0.75, 0.73, 0.68), "hair": None, "torso": 1.04, "belly": 1.0, "limb": 1.0, "head": 1.25,
        "arm_cut": 0, "sleeve": 1.0, "pants_end": 0.12, "bare_chest": False, "hood": True, "bloody_shirt": False,
    },
]


def log(message: str) -> None:
    print("[build_zombie] " + message)
    sys.stdout.flush()


class Palette:
    """Kullanılan renkleri hücrelere dizer; her yüz kendi hücresinin ortasını örnekler."""

    def __init__(self) -> None:
        self.colors: list = []

    def uv(self, color: tuple) -> tuple:
        if color not in self.colors:
            self.colors.append(color)
        index: int = self.colors.index(color)
        if index >= PALETTE_CELLS * PALETTE_CELLS:
            raise RuntimeError("Palet doldu; PALETTE_CELLS büyütülmeli.")
        return ((index % PALETTE_CELLS + 0.5) / PALETTE_CELLS, (index // PALETTE_CELLS + 0.5) / PALETTE_CELLS)

    def build_image(self):
        size: int = PALETTE_CELLS * PALETTE_CELL_PIXELS
        image = bpy.data.images.new("zombie_palette", size, size, alpha=False)
        pixels: list = [0.0] * (size * size * 4)
        for y in range(size):
            for x in range(size):
                index: int = (y // PALETTE_CELL_PIXELS) * PALETTE_CELLS + x // PALETTE_CELL_PIXELS
                color: tuple = self.colors[index] if index < len(self.colors) else (1.0, 0.0, 1.0)
                offset: int = (y * size + x) * 4
                # 8 bitlik görüntüde pikseller sRGB olarak saklanır; değerler çevrilmeden yazılır.
                pixels[offset:offset + 4] = list(color) + [1.0]
        image.pixels = pixels
        os.makedirs(os.path.dirname(PALETTE_FILE), exist_ok=True)
        image.filepath_raw = PALETTE_FILE
        image.file_format = "PNG"
        image.save()
        image.pack()
        return image


class Body:
    """Bir çeşidin ağı: halkalardan gövde parçaları, köşe başına kemik ağırlığı, yüz başına renk."""

    def __init__(self, palette: Palette) -> None:
        self.mesh = bmesh.new()
        self.uv_layer = self.mesh.loops.layers.uv.new("UVMap")
        self.palette: Palette = palette
        self.weights: dict = {}

    def loft(self, rings: list, bands: list, sides: int, cap_start=None, cap_end=None) -> None:
        """rings: (merkez, u, v, {kemik: ağırlık}); bands: ardışık halkalar arasındaki yüzlerin rengi."""
        rows: list = []
        phase: float = math.pi / sides
        for center, u, v, weights in rings:
            row: list = []
            for k in range(sides):
                angle: float = phase + 2.0 * math.pi * k / sides
                vert = self.mesh.verts.new(Vector(center) + math.cos(angle) * Vector(u) + math.sin(angle) * Vector(v))
                self.weights[vert] = weights
                row.append(vert)
            rows.append(row)
        faces: list = []
        for i in range(len(rows) - 1):
            for k in range(sides):
                n: int = (k + 1) % sides
                faces.append(self._face([rows[i][k], rows[i][n], rows[i + 1][n], rows[i + 1][k]], bands[i]))
        faces.append(self._face(rows[0], cap_start or bands[0]))
        faces.append(self._face(rows[-1], cap_end or bands[-1]))
        bmesh.ops.recalc_face_normals(self.mesh, faces=faces)

    def box(self, center: tuple, half: tuple, color: tuple, weights: dict) -> None:
        """Eksenlere hizalı küçük kutu (göz, ağız, saç gibi ayrıntılar)."""
        cx, cy, cz = center
        hx, hy, hz = half
        diagonal: float = math.sqrt(2.0)
        self.loft(
            [((cx, cy - hy, cz), (hx * diagonal, 0, 0), (0, 0, hz * diagonal), weights),
             ((cx, cy + hy, cz), (hx * diagonal, 0, 0), (0, 0, hz * diagonal), weights)],
            [color], 4)

    def _face(self, verts: list, color: tuple):
        face = self.mesh.faces.new(verts)
        uv: tuple = self.palette.uv(color)
        for loop in face.loops:
            loop[self.uv_layer].uv = uv
        return face

    def to_object(self, name: str, armature, material):
        self.mesh.verts.index_update()
        data = bpy.data.meshes.new(name)
        ordered: list = list(self.mesh.verts)
        self.mesh.to_mesh(data)
        obj = bpy.data.objects.new(name, data)
        bpy.context.scene.collection.objects.link(obj)
        for vert in ordered:
            for bone, weight in self.weights[vert].items():
                group = obj.vertex_groups.get(bone) or obj.vertex_groups.new(name=bone)
                group.add([vert.index], weight, "REPLACE")
        data.materials.append(material)
        for polygon in data.polygons:
            polygon.use_smooth = False
        obj.parent = armature
        obj.modifiers.new("Armature", "ARMATURE").object = armature
        data.calc_loop_triangles()
        log("%s: %d üçgen" % (name, len(data.loop_triangles)))
        self.mesh.free()
        return obj


def build_torso(body: Body, v: dict) -> None:
    wide: float = v["torso"]
    belly: float = v["belly"]
    shirt: tuple = v["shirt"]
    lower_shirt: tuple = BLOOD if v["bloody_shirt"] else shirt
    ribs: tuple = tuple(c * 0.8 for c in v["skin"]) if v["bare_chest"] else shirt

    def ring(z: float, rx: float, ry: float, weights: dict, y: float = 0.01) -> tuple:
        return ((0.0, y, z), (rx * wide, 0, 0), (0, ry * wide, 0), weights)

    body.loft(
        [
            ring(0.85, 0.13, 0.10, {"pelvis": 1.0}),
            ring(0.95, 0.185, 0.125, {"pelvis": 1.0}),
            ring(1.05, 0.17 * belly, 0.12 * belly, {"pelvis": 0.5, "spine_01": 0.5}, 0.01 - 0.03 * (belly - 1.0)),
            ring(1.17, 0.17 * belly, 0.12 * belly, {"spine_01": 0.5, "spine_02": 0.5}, 0.01 - 0.04 * (belly - 1.0)),
            ring(1.32, 0.20, 0.135, {"spine_02": 0.5, "spine_03": 0.5}),
            ring(1.45, 0.21, 0.125, {"spine_03": 1.0}),
            ring(NECK_Z, 0.09, 0.08, {"spine_03": 0.6, "neck_01": 0.4}),
        ],
        [v["pants"], v["pants"], lower_shirt, ribs, shirt, shirt], TORSO_SIDES)


def build_head(body: Body, v: dict) -> None:
    s: float = v["head"]
    skin: tuple = v["skin"]
    top: tuple = v["shirt"] if v["hood"] else (v["hair"] or skin)
    head: dict = {"Head": 1.0}
    y: float = -0.015
    body.loft(
        [((0.0, 0.0, NECK_Z - 0.03), (0.055, 0, 0), (0, 0.055, 0), {"neck_01": 1.0}),
         ((0.0, y, HEAD_Z + 0.02), (0.055, 0, 0), (0, 0.055, 0), {"neck_01": 0.4, "Head": 0.6})],
        [skin], LIMB_SIDES)

    def ring(height: float, rx: float, ry: float) -> tuple:
        return ((0.0, y, HEAD_Z + height * s), (rx * s, 0, 0), (0, ry * s, 0), head)

    body.loft(
        [ring(0.0, 0.07, 0.08), ring(0.07, 0.10, 0.108), ring(0.17, 0.105, 0.112), ring(0.25, 0.07, 0.08)],
        [skin, skin, top], TORSO_SIDES, cap_end=top)
    front: float = y - 0.108 * s * math.cos(math.pi / TORSO_SIDES)
    for side in (1.0, -1.0):
        body.box((side * 0.043 * s, front, HEAD_Z + 0.135 * s), (0.02 * s, 0.012, 0.016 * s), EYE, head)
    body.box((0.0, front + 0.004, HEAD_Z + 0.055 * s), (0.04 * s, 0.014, 0.018 * s), MOUTH, head)
    if v["hair"] is not None:
        body.box((0.0, y + 0.065 * s, HEAD_Z + 0.15 * s), (0.098 * s, 0.05 * s, 0.085 * s), v["hair"], head)
    if v["hood"]:
        body.box((0.0, y + 0.03 * s, HEAD_Z + 0.15 * s), (0.112 * s, 0.085 * s, 0.108 * s), v["shirt"], head)
        body.box((0.0, 0.07, NECK_Z - 0.01), (0.10, 0.05, 0.06), v["shirt"], {"spine_03": 1.0})


def build_arm(body: Body, v: dict, side: float) -> None:
    suffix: str = "_l" if side > 0.0 else "_r"
    upper, lower, hand = "upperarm" + suffix, "lowerarm" + suffix, "hand" + suffix
    thick: float = v["limb"]
    skin: tuple = v["skin"]
    cloth: tuple = v["shirt"]
    # Kol boyunca giysinin bittiği yer (0: kolsuz, 1: bileğe kadar).
    sleeve_x: float = SHOULDER_X + (WRIST_X - SHOULDER_X) * v["sleeve"]

    def color(x_from: float, x_to: float) -> tuple:
        return cloth if (x_from + x_to) * 0.5 < sleeve_x else skin

    def ring(x: float, radius: float, weights: dict) -> tuple:
        r: float = radius * thick
        return ((side * x, ARM_Y, ARM_Z), (0, r, 0), (0, 0, r), weights)

    stations: list = [
        (SHOULDER_X - 0.04, 0.060, {"spine_03": 0.5, upper: 0.5}),
        (SHOULDER_X + 0.03, 0.068, {upper: 1.0}),
        (0.34, 0.058, {upper: 1.0}),
        (ELBOW_X, 0.052, {upper: 0.5, lower: 0.5}),
    ]
    if v["arm_cut"] == side:
        stations.append((ELBOW_X + 0.07, 0.04, {lower: 1.0}))
        rings: list = [ring(*s) for s in stations]
        bands: list = [color(stations[i][0], stations[i + 1][0]) for i in range(len(stations) - 2)] + [BLOOD]
        body.loft(rings, bands, LIMB_SIDES, cap_start=bands[0], cap_end=BLOOD)
        body.box((side * (ELBOW_X + 0.09), ARM_Y, ARM_Z), (0.03, 0.012, 0.012), BONE_WHITE, {lower: 1.0})
        return
    stations += [
        (0.60, 0.047, {lower: 1.0}),
        (WRIST_X, 0.038, {lower: 0.5, hand: 0.5}),
    ]
    rings = [ring(*s) for s in stations]
    bands = [color(stations[i][0], stations[i + 1][0]) for i in range(len(stations) - 1)]
    body.loft(rings, bands, LIMB_SIDES)
    hand_weights: dict = {hand: 1.0}
    body.loft(
        [((side * (WRIST_X - 0.01), ARM_Y, ARM_Z), (0, 0.045 * thick, 0), (0, 0, 0.028), hand_weights),
         ((side * (WRIST_X + 0.09), ARM_Y, ARM_Z), (0, 0.06 * thick, 0), (0, 0, 0.03), hand_weights),
         ((side * (WRIST_X + 0.17), ARM_Y, ARM_Z), (0, 0.04 * thick, 0), (0, 0, 0.018), hand_weights)],
        [skin, BLOOD], LIMB_SIDES)


def build_leg(body: Body, v: dict, side: float) -> None:
    suffix: str = "_l" if side > 0.0 else "_r"
    thigh, calf, foot, ball = "thigh" + suffix, "calf" + suffix, "foot" + suffix, "ball" + suffix
    thick: float = v["limb"]
    x: float = side * HIP_X * (1.0 + 0.25 * (v["torso"] - 1.0))
    # Paçanın bittiği yükseklik (bilek ile diz arası oran).
    pants_z: float = ANKLE_Z + (KNEE_Z - ANKLE_Z) * v["pants_end"]

    def color(z_from: float, z_to: float) -> tuple:
        return v["pants"] if (z_from + z_to) * 0.5 > pants_z else v["skin"]

    stations: list = [
        (HIP_Z + 0.02, 0.085, {"pelvis": 0.5, thigh: 0.5}),
        (0.80, 0.088, {thigh: 1.0}),
        (KNEE_Z, 0.064, {thigh: 0.5, calf: 0.5}),
        (0.36, 0.062, {calf: 1.0}),
        (0.22, 0.05, {calf: 1.0}),
        (ANKLE_Z, 0.044, {calf: 0.5, foot: 0.5}),
    ]
    rings: list = [((x, 0.01 + (0.025 if z < KNEE_Z else 0.0), z), (r * thick, 0, 0), (0, r * thick, 0), w) for z, r, w in stations]
    bands: list = [color(stations[i][0], stations[i + 1][0]) for i in range(len(stations) - 1)]
    body.loft(rings, bands, LIMB_SIDES)
    width: float = 0.052 * thick
    body.loft(
        [((x, 0.10, 0.055), (width, 0, 0), (0, 0, 0.055), {foot: 1.0}),
         ((x, -0.09, 0.05), (width * 1.1, 0, 0), (0, 0, 0.05), {foot: 0.5, ball: 0.5}),
         ((x, -0.21, 0.035), (width, 0, 0), (0, 0, 0.035), {ball: 1.0})],
        [v["shoes"], v["shoes"]], LIMB_SIDES)


def build_variant(v: dict, palette: Palette, armature, material):
    body: Body = Body(palette)
    build_torso(body, v)
    build_head(body, v)
    for side in (1.0, -1.0):
        build_arm(body, v, side)
        build_leg(body, v, side)
    return body.to_object(v["name"], armature, material)


def load_skeleton():
    before: set = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=SKELETON_SOURCE)
    imported: list = [o for o in bpy.data.objects if o not in before]
    armature = next(o for o in imported if o.type == "ARMATURE")
    for other in [o for o in imported if o != armature]:
        bpy.data.objects.remove(other)
    armature.name = "Armature"
    return armature


def build_material():
    material = bpy.data.materials.new("ZombieMaterial")
    material.use_nodes = True
    tree = material.node_tree
    shader = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
    shader.inputs["Roughness"].default_value = 0.85
    shader.inputs["Metallic"].default_value = 0.0
    texture = tree.nodes.new("ShaderNodeTexImage")
    texture.interpolation = "Closest"
    tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])
    return material, texture


def export(objects: list, armature) -> None:
    os.makedirs(os.path.dirname(BLEND_OUTPUT), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUTPUT)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects + [armature]:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=OUTPUT,
        export_format="GLB",
        use_selection=True,
        export_animations=False,
        export_skins=True,
        export_yup=True,
        export_image_format="AUTO",
    )
    log("yazıldı: %s (%.0f KB)" % (os.path.relpath(OUTPUT, REPO), os.path.getsize(OUTPUT) / 1024.0))


def main() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    armature = load_skeleton()
    material, texture = build_material()
    palette: Palette = Palette()
    objects: list = [build_variant(v, palette, armature, material) for v in VARIANTS]
    texture.image = palette.build_image()
    log("palet: %d renk" % len(palette.colors))
    export(objects, armature)
    log("bitti")


main()
