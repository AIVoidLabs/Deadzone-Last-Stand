"""Zombi modelleri: low-poly, 25 kemikli ortak iskelette, tek dosyada birçok gövde çeşidi.
Üç takım var: walker (yürüyen), runner (koşucu: ince, çevik), tank (iri, zırhlı omuzlu).

Çalıştırma (repo kökünden, Blender penceresi açılmaz; takım adı verilmezse walker):
    blender --background --python tools/blender/build_zombie.py [-- walker|runner|tank|all]

Girdi : assets/models/characters/mannequin.glb (iskelet ve dinlenme pozu kaynağı)
Çıktı : assets/models/characters/zombie_<takım>.glb (her çeşit ayrı ağ: Variant_A, Variant_B ...)
        build/blender/zombie_<takım>.blend

Gövde, kemik hizalarına dizilen halkaların birleştirilmesiyle (loft) kurulur; ağırlıklar
halka başına elle verilir. Yüzler renk değil ROL taşır (ten, üst, alt ...); palet dokusunun her
satırı bir renk şemasıdır ve oyunda örnek başına seçilir. Görünüm sayısı = çeşit x şema.
Yeni gövde = VARIANTS'a satır, yeni renk = SCHEMES'e satır.
"""

import math
import os
import sys

import bmesh
import bpy
from mathutils import Vector

REPO: str = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SKELETON_SOURCE: str = os.path.join(REPO, "assets", "models", "characters", "mannequin.glb")
CHARACTER_DIR: str = os.path.join(REPO, "assets", "models", "characters")
BLEND_DIR: str = os.path.join(REPO, "build", "blender")
# Takıma göre build_set() içinde ayarlanır.
OUTPUT: str = ""
BLEND_OUTPUT: str = ""
PALETTE_FILE: str = ""

# Palet: sütun = rol, satır = renk şeması. Oyun tarafı (ZombieLook) aynı sütun sayısını bilir.
PALETTE_COLUMNS: int = 16
PALETTE_CELL_PIXELS: int = 4
ROLES: list = ["skin", "skin_dark", "top", "bottom", "shoes", "hair", "eye", "blood", "mouth", "bone"]
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
BONE_WHITE: tuple = (0.85, 0.82, 0.72)
EYE_YELLOW: tuple = (0.98, 0.92, 0.45)
EYE_RED: tuple = (0.95, 0.22, 0.12)
EYE_PALE: tuple = (0.80, 0.96, 0.92)
SKIN_SHADE: float = 0.8

# Renk şemaları (sRGB): ten, üst, alt, ayakkabı, saç/şapka, göz. İlk sekiz açık, son sekiz koyu tonlar.
WALKER_SCHEMES: list = [
    ((0.47, 0.58, 0.42), (0.72, 0.70, 0.62), (0.20, 0.21, 0.26), (0.12, 0.10, 0.09), (0.20, 0.15, 0.10), EYE_YELLOW),
    ((0.55, 0.60, 0.38), (0.62, 0.52, 0.22), (0.33, 0.24, 0.17), (0.15, 0.12, 0.10), (0.16, 0.12, 0.09), EYE_YELLOW),
    ((0.56, 0.62, 0.55), (0.36, 0.40, 0.44), (0.36, 0.37, 0.36), (0.20, 0.18, 0.16), (0.22, 0.20, 0.17), EYE_YELLOW),
    ((0.40, 0.52, 0.46), (0.42, 0.14, 0.15), (0.13, 0.13, 0.15), (0.75, 0.73, 0.68), (0.10, 0.10, 0.10), EYE_YELLOW),
    ((0.62, 0.66, 0.50), (0.50, 0.50, 0.52), (0.22, 0.28, 0.20), (0.14, 0.12, 0.10), (0.45, 0.40, 0.30), EYE_PALE),
    ((0.50, 0.56, 0.60), (0.18, 0.28, 0.36), (0.25, 0.25, 0.28), (0.10, 0.10, 0.10), (0.30, 0.22, 0.14), EYE_YELLOW),
    ((0.58, 0.52, 0.50), (0.40, 0.36, 0.50), (0.16, 0.14, 0.12), (0.30, 0.26, 0.22), (0.50, 0.48, 0.44), EYE_PALE),
    ((0.36, 0.46, 0.34), (0.55, 0.30, 0.16), (0.15, 0.17, 0.22), (0.10, 0.09, 0.08), (0.12, 0.08, 0.06), EYE_YELLOW),
    ((0.30, 0.38, 0.30), (0.16, 0.18, 0.20), (0.10, 0.10, 0.12), (0.08, 0.08, 0.08), (0.05, 0.05, 0.05), EYE_RED),
    ((0.34, 0.33, 0.40), (0.20, 0.14, 0.26), (0.14, 0.12, 0.16), (0.09, 0.08, 0.10), (0.08, 0.07, 0.10), EYE_PALE),
    ((0.42, 0.36, 0.28), (0.22, 0.26, 0.18), (0.18, 0.15, 0.12), (0.10, 0.08, 0.07), (0.10, 0.08, 0.06), EYE_YELLOW),
    ((0.48, 0.50, 0.44), (0.12, 0.12, 0.13), (0.30, 0.30, 0.34), (0.08, 0.08, 0.09), (0.06, 0.06, 0.06), EYE_RED),
    ((0.26, 0.32, 0.34), (0.30, 0.10, 0.10), (0.09, 0.09, 0.10), (0.07, 0.07, 0.07), (0.04, 0.04, 0.05), EYE_YELLOW),
    ((0.38, 0.42, 0.30), (0.14, 0.20, 0.16), (0.20, 0.17, 0.10), (0.09, 0.08, 0.06), (0.14, 0.10, 0.06), EYE_RED),
    ((0.44, 0.44, 0.48), (0.24, 0.24, 0.27), (0.12, 0.13, 0.17), (0.20, 0.20, 0.22), (0.30, 0.30, 0.32), EYE_PALE),
    ((0.33, 0.28, 0.26), (0.34, 0.24, 0.12), (0.11, 0.10, 0.09), (0.07, 0.06, 0.06), (0.05, 0.04, 0.04), EYE_YELLOW),
]

# Koşucu: soluk, kuru ten; parlak kırmızı ve rengi atmış spor giysiler (uzaktan "tehlikeli" okunur).
RUNNER_SCHEMES: list = [
    ((0.66, 0.62, 0.54), (0.72, 0.16, 0.14), (0.16, 0.16, 0.20), (0.85, 0.85, 0.82), (0.12, 0.08, 0.06), EYE_RED),
    ((0.60, 0.64, 0.52), (0.85, 0.55, 0.12), (0.12, 0.14, 0.20), (0.10, 0.10, 0.10), (0.30, 0.20, 0.10), EYE_YELLOW),
    ((0.70, 0.60, 0.55), (0.20, 0.20, 0.24), (0.50, 0.12, 0.12), (0.12, 0.10, 0.10), (0.06, 0.06, 0.06), EYE_RED),
    ((0.58, 0.66, 0.60), (0.70, 0.70, 0.30), (0.14, 0.18, 0.26), (0.16, 0.14, 0.12), (0.22, 0.18, 0.10), EYE_YELLOW),
    ((0.64, 0.58, 0.60), (0.55, 0.12, 0.30), (0.10, 0.10, 0.12), (0.70, 0.68, 0.64), (0.40, 0.12, 0.30), EYE_PALE),
    ((0.52, 0.60, 0.56), (0.12, 0.34, 0.52), (0.18, 0.16, 0.14), (0.85, 0.82, 0.76), (0.10, 0.10, 0.12), EYE_RED),
    ((0.72, 0.68, 0.62), (0.38, 0.10, 0.10), (0.26, 0.26, 0.28), (0.08, 0.08, 0.08), (0.80, 0.78, 0.74), EYE_RED),
    ((0.56, 0.54, 0.50), (0.88, 0.80, 0.70), (0.30, 0.10, 0.08), (0.12, 0.10, 0.08), (0.14, 0.10, 0.06), EYE_YELLOW),
]

# Tank: koyu gri-yeşil, çamurlu ten; zırh parçaları koyu çelik (alt rolü) tonlarında.
TANK_SCHEMES: list = [
    ((0.34, 0.40, 0.32), (0.22, 0.24, 0.20), (0.30, 0.32, 0.36), (0.08, 0.08, 0.08), (0.10, 0.08, 0.06), EYE_RED),
    ((0.40, 0.42, 0.36), (0.36, 0.20, 0.12), (0.22, 0.24, 0.28), (0.10, 0.09, 0.08), (0.06, 0.05, 0.05), EYE_YELLOW),
    ((0.30, 0.34, 0.36), (0.16, 0.18, 0.22), (0.40, 0.34, 0.20), (0.07, 0.07, 0.08), (0.18, 0.18, 0.20), EYE_PALE),
    ((0.44, 0.38, 0.34), (0.26, 0.10, 0.10), (0.26, 0.26, 0.30), (0.09, 0.08, 0.08), (0.12, 0.08, 0.06), EYE_RED),
    ((0.28, 0.32, 0.26), (0.14, 0.18, 0.14), (0.34, 0.36, 0.32), (0.06, 0.06, 0.06), (0.05, 0.06, 0.05), EYE_YELLOW),
    ((0.36, 0.36, 0.42), (0.28, 0.28, 0.32), (0.44, 0.22, 0.12), (0.08, 0.08, 0.10), (0.22, 0.22, 0.26), EYE_RED),
]

# Etkin renk şemaları (takıma göre build_set() ayarlar).
SCHEMES: list = WALKER_SCHEMES


def variant(name: str, **overrides) -> dict:
    """Gövde çeşidi. Ölçüler çarpan. arm_cut: dirsekten kopuk kol (+1 sol, -1 sağ, 0 yok).
    sleeve: kol giysisi (0 kolsuz, 1 bileğe kadar). pants_end: paça (0 bilek, 1 diz).
    headgear: None, "hair", "long_hair", "mohawk", "cap", "hood". pads: omuz zırhı + göğüs plakası (tank).
    legs: bacak kalınlığı çarpanı (zıplayan: güçlü uyluklar). jaw: iri çene, açık ağız ve sarkan dil (dilci)."""
    row: dict = {
        "name": name, "torso": 1.0, "belly": 1.0, "limb": 1.0, "head": 1.25, "arm_cut": 0, "sleeve": 0.5,
        "pants_end": 0.2, "bare_chest": False, "bloody_top": False, "headgear": None, "skirt": False,
        "barefoot": False, "head_wound": False, "pads": False, "legs": 1.0, "jaw": False,
    }
    row.update(overrides)
    return row


WALKER_VARIANTS: list = [
    variant("Variant_A", bloody_top=True, sleeve=0.55),
    variant("Variant_B", torso=1.18, belly=1.45, limb=1.2, head=1.22, sleeve=0.3, pants_end=0.32, headgear="hair"),
    variant("Variant_C", torso=0.86, belly=0.8, limb=0.82, head=1.22, arm_cut=1, sleeve=0.0, pants_end=0.42,
            bare_chest=True, barefoot=True, headgear="hair"),
    variant("Variant_D", torso=1.04, sleeve=1.0, pants_end=0.12, headgear="hood"),
    variant("Variant_E", torso=1.08, limb=1.1, sleeve=1.0, pants_end=0.05, headgear="cap"),
    variant("Variant_F", torso=0.92, belly=0.9, limb=0.85, sleeve=0.2, pants_end=1.0, skirt=True, headgear="long_hair"),
    variant("Variant_G", torso=1.16, limb=1.18, head=1.2, arm_cut=-1, sleeve=0.0, pants_end=0.95, bare_chest=True,
            head_wound=True),
    variant("Variant_H", torso=0.95, limb=0.92, sleeve=0.0, pants_end=0.08, headgear="mohawk"),
    variant("Variant_I", torso=1.2, belly=1.55, limb=1.15, head=1.2, sleeve=0.0, pants_end=0.6, bare_chest=True,
            barefoot=True),
    variant("Variant_J", torso=0.94, limb=0.9, arm_cut=1, sleeve=0.8, pants_end=0.3, bloody_top=True,
            headgear="long_hair", head_wound=True),
]

# Koşucu: ince, uzun uzuvlu, çıplak göğüslü ya da yırtık giysili; siluet "kuru ve çevik".
RUNNER_VARIANTS: list = [
    variant("Variant_A", torso=0.80, belly=0.75, limb=0.78, head=1.18, sleeve=0.0, pants_end=0.5, bare_chest=True,
            barefoot=True, headgear="hair"),
    variant("Variant_B", torso=0.82, belly=0.8, limb=0.8, head=1.15, sleeve=0.3, pants_end=0.25, bloody_top=True,
            headgear="mohawk"),
    variant("Variant_C", torso=0.84, belly=0.85, limb=0.8, head=1.2, sleeve=1.0, pants_end=0.1, headgear="hood"),
    variant("Variant_D", torso=0.80, belly=0.78, limb=0.78, head=1.18, arm_cut=-1, sleeve=0.0, pants_end=0.35,
            bare_chest=True, head_wound=True, headgear="cap"),
]

# Zıplayan: dar gövde, güçlü uyluk ve baldır (sıçrama gücü), uzun ve çevik; turuncu-sarı-camgöbeği tonları.
JUMPER_VARIANTS: list = [
    variant("Variant_A", torso=0.84, belly=0.78, limb=0.85, legs=1.4, head=1.15, sleeve=0.0, pants_end=0.55,
            bare_chest=True, barefoot=True, headgear="hair"),
    variant("Variant_B", torso=0.86, belly=0.8, limb=0.85, legs=1.35, head=1.15, sleeve=0.2, pants_end=0.3,
            bloody_top=True, headgear="mohawk"),
    variant("Variant_C", torso=0.88, belly=0.85, limb=0.88, legs=1.35, head=1.18, sleeve=0.0, pants_end=0.25,
            headgear="cap"),
    variant("Variant_D", torso=0.84, belly=0.78, limb=0.84, legs=1.45, head=1.15, arm_cut=1, sleeve=0.0,
            pants_end=0.6, bare_chest=True, head_wound=True),
]

JUMPER_SCHEMES: list = [
    ((0.62, 0.56, 0.42), (0.90, 0.58, 0.12), (0.14, 0.16, 0.22), (0.10, 0.10, 0.10), (0.20, 0.14, 0.08), EYE_YELLOW),
    ((0.56, 0.62, 0.50), (0.14, 0.62, 0.62), (0.18, 0.16, 0.14), (0.90, 0.88, 0.80), (0.10, 0.10, 0.10), EYE_YELLOW),
    ((0.66, 0.56, 0.48), (0.92, 0.82, 0.20), (0.20, 0.22, 0.30), (0.12, 0.10, 0.10), (0.30, 0.20, 0.10), EYE_RED),
    ((0.52, 0.58, 0.60), (0.80, 0.30, 0.10), (0.12, 0.12, 0.14), (0.82, 0.80, 0.76), (0.08, 0.08, 0.10), EYE_PALE),
    ((0.60, 0.52, 0.50), (0.30, 0.70, 0.30), (0.24, 0.18, 0.14), (0.10, 0.09, 0.08), (0.14, 0.10, 0.06), EYE_YELLOW),
    ((0.68, 0.64, 0.56), (0.62, 0.20, 0.50), (0.14, 0.14, 0.18), (0.12, 0.12, 0.12), (0.06, 0.06, 0.06), EYE_RED),
]

# Dilci: iri kafa ve açık çene, ince gövde; soluk pembe-mor ve çürük tonlar (dil parlak kırmızı).
TONGUE_VARIANTS: list = [
    variant("Variant_A", torso=0.82, belly=0.7, limb=0.85, head=1.6, sleeve=0.0, pants_end=0.3, bare_chest=True,
            jaw=True),
    variant("Variant_B", torso=0.86, belly=0.8, limb=0.88, head=1.55, sleeve=0.4, pants_end=0.2, bloody_top=True,
            headgear="cap", jaw=True),
    variant("Variant_C", torso=0.8, belly=0.7, limb=0.82, head=1.62, sleeve=1.0, pants_end=0.1, headgear="hood",
            jaw=True),
    variant("Variant_D", torso=0.84, belly=0.75, limb=0.86, head=1.58, arm_cut=-1, sleeve=0.0, pants_end=0.5,
            bare_chest=True, head_wound=True, jaw=True),
]

TONGUE_SCHEMES: list = [
    ((0.62, 0.50, 0.56), (0.30, 0.22, 0.32), (0.16, 0.14, 0.18), (0.10, 0.08, 0.10), (0.10, 0.08, 0.10), EYE_PALE),
    ((0.56, 0.54, 0.50), (0.46, 0.26, 0.30), (0.20, 0.18, 0.16), (0.10, 0.09, 0.08), (0.14, 0.10, 0.08), EYE_YELLOW),
    ((0.52, 0.48, 0.58), (0.20, 0.30, 0.34), (0.14, 0.16, 0.20), (0.08, 0.08, 0.10), (0.20, 0.18, 0.24), EYE_PALE),
    ((0.64, 0.54, 0.50), (0.36, 0.34, 0.22), (0.22, 0.18, 0.14), (0.12, 0.10, 0.08), (0.08, 0.06, 0.06), EYE_RED),
    ((0.48, 0.52, 0.46), (0.40, 0.18, 0.40), (0.12, 0.12, 0.14), (0.08, 0.08, 0.08), (0.06, 0.06, 0.06), EYE_YELLOW),
    ((0.58, 0.56, 0.62), (0.24, 0.24, 0.28), (0.34, 0.20, 0.20), (0.10, 0.10, 0.12), (0.30, 0.26, 0.34), EYE_PALE),
]

# Tank: geniş gövde, kalın uzuvlar, küçük baş; omuz zırhı ve göğüs plakası siluetini ayırır.
TANK_VARIANTS: list = [
    variant("Variant_A", torso=1.42, belly=1.2, limb=1.4, head=0.95, sleeve=0.5, pants_end=0.15, bloody_top=True,
            headgear="cap", pads=True),
    variant("Variant_B", torso=1.5, belly=1.45, limb=1.45, head=0.92, arm_cut=1, sleeve=0.0, pants_end=0.55,
            bare_chest=True, barefoot=True, head_wound=True),
    variant("Variant_C", torso=1.38, belly=1.15, limb=1.35, head=0.98, sleeve=1.0, pants_end=0.1, headgear="hood",
            pads=True),
    variant("Variant_D", torso=1.46, belly=1.3, limb=1.42, head=0.94, sleeve=0.0, pants_end=0.6, bare_chest=True,
            headgear="mohawk", pads=True),
]

SETS: dict = {
    "walker": {"variants": WALKER_VARIANTS, "schemes": WALKER_SCHEMES},
    "runner": {"variants": RUNNER_VARIANTS, "schemes": RUNNER_SCHEMES},
    "tank": {"variants": TANK_VARIANTS, "schemes": TANK_SCHEMES},
    "jumper": {"variants": JUMPER_VARIANTS, "schemes": JUMPER_SCHEMES},
    "tongue": {"variants": TONGUE_VARIANTS, "schemes": TONGUE_SCHEMES},
}


def log(message: str) -> None:
    print("[build_zombie] " + message)
    sys.stdout.flush()


def role_uv(role: str) -> tuple:
    """Yüz, rolünün hücresinin ortasını ilk satırda örnekler; satırı (şemayı) oyun kaydırır."""
    return ((ROLES.index(role) + 0.5) / PALETTE_COLUMNS, 0.5 / len(SCHEMES))


def build_palette_image():
    cell: int = PALETTE_CELL_PIXELS
    width: int = PALETTE_COLUMNS * cell
    height: int = len(SCHEMES) * cell
    image = bpy.data.images.new("zombie_palette", width, height, alpha=False)
    pixels: list = [0.0] * (width * height * 4)
    for row, (skin, top, bottom, shoes, hair, eye) in enumerate(SCHEMES):
        colors: dict = {
            "skin": skin, "skin_dark": tuple(c * SKIN_SHADE for c in skin), "top": top, "bottom": bottom,
            "shoes": shoes, "hair": hair, "eye": eye, "blood": BLOOD, "mouth": MOUTH, "bone": BONE_WHITE,
        }
        for column in range(PALETTE_COLUMNS):
            color: tuple = colors[ROLES[column]] if column < len(ROLES) else (1.0, 0.0, 1.0)
            for y in range(row * cell, (row + 1) * cell):
                for x in range(column * cell, (column + 1) * cell):
                    offset: int = (y * width + x) * 4
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
    """Bir çeşidin ağı: halkalardan gövde parçaları, köşe başına kemik ağırlığı, yüz başına rol."""

    def __init__(self) -> None:
        self.mesh = bmesh.new()
        self.uv_layer = self.mesh.loops.layers.uv.new("UVMap")
        self.weights: dict = {}

    def loft(self, rings: list, bands: list, sides: int, cap_start=None, cap_end=None) -> None:
        """rings: (merkez, u, v, {kemik: ağırlık}); bands: ardışık halkalar arasındaki yüzlerin rolü."""
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

    def box(self, center: tuple, half: tuple, role: str, weights: dict) -> None:
        """Eksenlere hizalı küçük kutu (göz, ağız, saç gibi ayrıntılar)."""
        cx, cy, cz = center
        hx, hy, hz = half
        diagonal: float = math.sqrt(2.0)
        self.loft(
            [((cx, cy - hy, cz), (hx * diagonal, 0, 0), (0, 0, hz * diagonal), weights),
             ((cx, cy + hy, cz), (hx * diagonal, 0, 0), (0, 0, hz * diagonal), weights)],
            [role], 4)

    def _face(self, verts: list, role: str):
        face = self.mesh.faces.new(verts)
        uv: tuple = role_uv(role)
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


def top_role(v: dict) -> str:
    return "skin" if v["bare_chest"] else "top"


def build_torso(body: Body, v: dict) -> None:
    wide: float = v["torso"]
    belly: float = v["belly"]
    top: str = top_role(v)
    lower_top: str = "blood" if v["bloody_top"] else top
    ribs: str = "skin_dark" if v["bare_chest"] else top
    hips: str = top if v["skirt"] else "bottom"

    def ring(z: float, rx: float, ry: float, weights: dict, y: float = 0.01) -> tuple:
        return ((0.0, y, z), (rx * wide, 0, 0), (0, ry * wide, 0), weights)

    rings: list = [
        ring(0.85, 0.13, 0.10, {"pelvis": 1.0}),
        ring(0.95, 0.185, 0.125, {"pelvis": 1.0}),
        ring(1.05, 0.17 * belly, 0.12 * belly, {"pelvis": 0.5, "spine_01": 0.5}, 0.01 - 0.03 * (belly - 1.0)),
        ring(1.17, 0.17 * belly, 0.12 * belly, {"spine_01": 0.5, "spine_02": 0.5}, 0.01 - 0.04 * (belly - 1.0)),
        ring(1.32, 0.20, 0.135, {"spine_02": 0.5, "spine_03": 0.5}),
        ring(1.45, 0.21, 0.125, {"spine_03": 1.0}),
        ring(NECK_Z, 0.09, 0.08, {"spine_03": 0.6, "neck_01": 0.4}),
    ]
    if v["skirt"]:
        # Etek: kalçadan dize doğru genişleyen, kalçaya bağlı çan.
        rings[0] = ring(0.62, 0.25, 0.20, {"pelvis": 1.0})
    body.loft(rings, [hips, hips, lower_top, ribs, top, top], TORSO_SIDES)
    if v["pads"]:
        build_armor(body, wide)


def build_armor(body: Body, wide: float) -> None:
    """Omuz zırhı (üzerinde küçük sivri çıkıntı) ve göğüs plakası; rol: koyu çelik (bottom) + kemik."""
    for side in (1.0, -1.0):
        upper: str = "upperarm_l" if side > 0.0 else "upperarm_r"
        weights: dict = {"spine_03": 0.5, upper: 0.5}
        body.box((side * 0.25 * wide, 0.01, 1.50), (0.11, 0.085, 0.04), "shoes", weights)
        body.box((side * 0.25 * wide, 0.01, 1.565), (0.016, 0.016, 0.04), "bone", weights)
    front: float = 0.01 - 0.135 * wide - 0.02
    body.box((0.0, front, 1.22), (0.11 * wide, 0.022, 0.085), "shoes", {"spine_02": 0.5, "spine_03": 0.5})


def build_head(body: Body, v: dict) -> None:
    s: float = v["head"]
    gear = v["headgear"]
    top: str = "blood" if v["head_wound"] else "skin"
    if gear in ("hair", "long_hair"):
        top = "hair"
    head: dict = {"Head": 1.0}
    y: float = -0.015
    body.loft(
        [((0.0, 0.0, NECK_Z - 0.03), (0.055, 0, 0), (0, 0.055, 0), {"neck_01": 1.0}),
         ((0.0, y, HEAD_Z + 0.02), (0.055, 0, 0), (0, 0.055, 0), {"neck_01": 0.4, "Head": 0.6})],
        ["skin"], LIMB_SIDES)

    def ring(height: float, rx: float, ry: float) -> tuple:
        return ((0.0, y, HEAD_Z + height * s), (rx * s, 0, 0), (0, ry * s, 0), head)

    body.loft(
        [ring(0.0, 0.07, 0.08), ring(0.07, 0.10, 0.108), ring(0.17, 0.105, 0.112), ring(0.25, 0.07, 0.08)],
        ["skin", "skin", top], TORSO_SIDES, cap_end=top)
    front: float = y - 0.108 * s * math.cos(math.pi / TORSO_SIDES)
    for side in (1.0, -1.0):
        body.box((side * 0.043 * s, front, HEAD_Z + 0.135 * s), (0.02 * s, 0.012, 0.016 * s), "eye", head)
    body.box((0.0, front + 0.004, HEAD_Z + 0.055 * s), (0.04 * s, 0.014, 0.018 * s), "mouth", head)
    if v["jaw"]:
        # Açık ağız (koyu) ve sarkan dil: ağız büyük, dil önde aşağı uzanır.
        body.box((0.0, front + 0.006, HEAD_Z + 0.045 * s), (0.062 * s, 0.016, 0.04 * s), "mouth", head)
        body.box((0.0, front - 0.012, HEAD_Z + 0.02 * s), (0.026 * s, 0.014, 0.075 * s), "blood", head)
    if gear in ("hair", "long_hair"):
        body.box((0.0, y + 0.065 * s, HEAD_Z + 0.15 * s), (0.098 * s, 0.05 * s, 0.085 * s), "hair", head)
    if gear == "long_hair":
        body.box((0.0, y + 0.10 * s, HEAD_Z + 0.02 * s), (0.085 * s, 0.03 * s, 0.11 * s), "hair", head)
    if gear == "mohawk":
        body.box((0.0, y + 0.01 * s, HEAD_Z + 0.25 * s), (0.014 * s, 0.085 * s, 0.045 * s), "hair", head)
    if gear == "cap":
        body.box((0.0, y, HEAD_Z + 0.235 * s), (0.10 * s, 0.105 * s, 0.03 * s), "hair", head)
        body.box((0.0, y - 0.14 * s, HEAD_Z + 0.215 * s), (0.075 * s, 0.05 * s, 0.01 * s), "hair", head)
    if gear == "hood":
        body.box((0.0, y + 0.03 * s, HEAD_Z + 0.15 * s), (0.112 * s, 0.085 * s, 0.108 * s), "top", head)
        body.box((0.0, 0.07, NECK_Z - 0.01), (0.10, 0.05, 0.06), "top", {"spine_03": 1.0})


def build_arm(body: Body, v: dict, side: float) -> None:
    suffix: str = "_l" if side > 0.0 else "_r"
    upper, lower, hand = "upperarm" + suffix, "lowerarm" + suffix, "hand" + suffix
    thick: float = v["limb"]
    cloth: str = top_role(v)
    # Kol boyunca giysinin bittiği yer (0: kolsuz, 1: bileğe kadar).
    sleeve_x: float = SHOULDER_X + (WRIST_X - SHOULDER_X) * v["sleeve"]

    def role(x_from: float, x_to: float) -> str:
        return cloth if (x_from + x_to) * 0.5 < sleeve_x else "skin"

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
        bands: list = [role(stations[i][0], stations[i + 1][0]) for i in range(len(stations) - 2)] + ["blood"]
        body.loft(rings, bands, LIMB_SIDES, cap_start=bands[0], cap_end="blood")
        body.box((side * (ELBOW_X + 0.09), ARM_Y, ARM_Z), (0.03, 0.012, 0.012), "bone", {lower: 1.0})
        return
    stations += [
        (0.60, 0.047, {lower: 1.0}),
        (WRIST_X, 0.038, {lower: 0.5, hand: 0.5}),
    ]
    rings = [ring(*s) for s in stations]
    bands = [role(stations[i][0], stations[i + 1][0]) for i in range(len(stations) - 1)]
    body.loft(rings, bands, LIMB_SIDES)
    hand_weights: dict = {hand: 1.0}
    body.loft(
        [((side * (WRIST_X - 0.01), ARM_Y, ARM_Z), (0, 0.045 * thick, 0), (0, 0, 0.028), hand_weights),
         ((side * (WRIST_X + 0.09), ARM_Y, ARM_Z), (0, 0.06 * thick, 0), (0, 0, 0.03), hand_weights),
         ((side * (WRIST_X + 0.17), ARM_Y, ARM_Z), (0, 0.04 * thick, 0), (0, 0, 0.018), hand_weights)],
        ["skin", "blood"], LIMB_SIDES)


def build_leg(body: Body, v: dict, side: float) -> None:
    suffix: str = "_l" if side > 0.0 else "_r"
    thigh, calf, foot, ball = "thigh" + suffix, "calf" + suffix, "foot" + suffix, "ball" + suffix
    thick: float = v["limb"] * v["legs"]
    x: float = side * HIP_X * (1.0 + 0.25 * (v["torso"] - 1.0))
    # Paçanın bittiği yükseklik (bilek ile diz arası oran).
    pants_z: float = ANKLE_Z + (KNEE_Z - ANKLE_Z) * v["pants_end"]

    def role(z_from: float, z_to: float) -> str:
        return "bottom" if (z_from + z_to) * 0.5 > pants_z and not v["skirt"] else "skin"

    stations: list = [
        (HIP_Z + 0.02, 0.085, {"pelvis": 0.5, thigh: 0.5}),
        (0.80, 0.088, {thigh: 1.0}),
        (KNEE_Z, 0.064, {thigh: 0.5, calf: 0.5}),
        (0.36, 0.062, {calf: 1.0}),
        (0.22, 0.05, {calf: 1.0}),
        (ANKLE_Z, 0.044, {calf: 0.5, foot: 0.5}),
    ]
    rings: list = [((x, 0.01 + (0.025 if z < KNEE_Z else 0.0), z), (r * thick, 0, 0), (0, r * thick, 0), w) for z, r, w in stations]
    bands: list = [role(stations[i][0], stations[i + 1][0]) for i in range(len(stations) - 1)]
    body.loft(rings, bands, LIMB_SIDES)
    width: float = 0.052 * thick
    body.loft(
        [((x, 0.10, 0.055), (width, 0, 0), (0, 0, 0.055), {foot: 1.0}),
         ((x, -0.09, 0.05), (width * 1.1, 0, 0), (0, 0, 0.05), {foot: 0.5, ball: 0.5}),
         ((x, -0.21, 0.035), (width, 0, 0), (0, 0, 0.035), {ball: 1.0})],
        ["skin" if v["barefoot"] else "shoes"] * 2, LIMB_SIDES)


def build_variant(v: dict, armature, material):
    body: Body = Body()
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


def build_set(name: str) -> None:
    global OUTPUT, BLEND_OUTPUT, PALETTE_FILE, SCHEMES
    row: dict = SETS[name]
    SCHEMES = row["schemes"]
    OUTPUT = os.path.join(CHARACTER_DIR, "zombie_%s.glb" % name)
    BLEND_OUTPUT = os.path.join(BLEND_DIR, "zombie_%s.blend" % name)
    PALETTE_FILE = os.path.join(BLEND_DIR, "zombie_%s_palette.png" % name)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    armature = load_skeleton()
    material, texture = build_material()
    objects: list = [build_variant(v, armature, material) for v in row["variants"]]
    texture.image = build_palette_image()
    log("%s: %d çeşit x %d şema = %d görünüm" % (name, len(row["variants"]), len(SCHEMES), len(row["variants"]) * len(SCHEMES)))
    export(objects, armature)


def main() -> None:
    args: list = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    choice: str = args[0] if args else "walker"
    names: list = list(SETS) if choice == "all" else [choice]
    for name in names:
        build_set(name)
    log("bitti")


main()
