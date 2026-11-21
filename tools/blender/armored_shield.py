"""Zırhlı zombinin imza parçası: sol önkola bağlı kırık kalkan (7.3).

Büyük düz plaka (üstten kameradan okunur): kavisli (dikey eksende), alt-üst dikdörtgen; bir üst köşesi
tırtıklı kırık, alt dış köşesinde küçük kopuk. Çerçeve (dış halka) öne kabarık ve ayrı yuva: metal ya da
kauçuk; yüz plastik (çevik kuvvet, güvenlik) ya da metal (SWAT balistik); vurgu yuvası şerit / gözetleme
yarığı. Kalkan önkolun önünde, üst kenarı gövdeye doğru TILT derece yatık (kambur zombi arkasına siner).
Yerel uzay: x enine (+ sola), y derinlik (- öne), z yukarı.
"""
import math

import bmesh
import bpy
from mathutils import Matrix, Vector, noise

import armored_mats as am
import zombie_kit as kit

HALF_W = 0.31             # yarı en (m)
HALF_H = 0.44             # yarı boy (m)
CELLS = (16, 23)
BEND_R = 0.95             # enine kavis yarıçapı (m)
THICK = 0.018
RIM_RAISE = 0.007         # çerçeve öne kabarık (m)
TILT = 12.0               # üst kenar gövdeye yatık (derece)
FRONT_GAP = 0.110         # önkol ekseninden plakanın arka yüzüne (m)
DROP = 0.10               # plaka merkezi önkolun bu kadar altında (m)
INSET = 0.06              # plaka merkezi önkol ortasından içe (m, önkol yönünde)


def _broken(x, z, brk, seed):
    """Kırık bölgesi mi: üst iç köşe (x<0 tarafı) çizginin üstü + alt dış köşede küçük kopuk."""
    (x0, z0), (x1, z1) = brk
    jag = 0.035 * noise.noise(Vector((x * 9.0, z * 9.0, seed))) + 0.02 * noise.noise(Vector((x * 31.0, z * 31.0, seed)))
    side = (x1 - x0) * (z - z0) - (z1 - z0) * (x - x0)
    if side + jag * 0.5 < 0.0:
        return True
    return (x - HALF_W) ** 2 + (z + HALF_H) ** 2 < (0.07 + jag) ** 2


def _slot(x, z, accent):
    rim = 0.85 * (2.0 * HALF_W / CELLS[0])
    if abs(x) > HALF_W - rim or abs(z) > HALF_H - rim:
        return 1
    if accent == "band" and 0.07 < z < 0.15:
        return 2
    if accent == "low_band" and -0.02 < z < 0.07:
        return 2
    if accent == "window" and abs(x) < 0.12 and 0.23 < z < 0.30:
        return 2
    return 0


def shield_mesh(name, sh, seed):
    bm = bmesh.new()
    nx, nz = CELLS
    grid = [[bm.verts.new((-HALF_W + 2 * HALF_W * i / nx, 0.0, -HALF_H + 2 * HALF_H * j / nz))
             for j in range(nz + 1)] for i in range(nx + 1)]
    for i in range(nx):
        for j in range(nz):
            cx = -HALF_W + 2 * HALF_W * (i + 0.5) / nx
            cz = -HALF_H + 2 * HALF_H * (j + 0.5) / nz
            if _broken(cx, cz, sh["break"], seed):
                continue
            f = bm.faces.new((grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]))
            f.material_index = _slot(cx, cz, sh.get("accent"))
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.normal_update()
    # kırık kenarın merdivenini yumuşat, sonra tırtıkla (dış dikdörtgen kenarı yerinde kalır)
    edge = [v for v in bm.verts if v.is_boundary and abs(v.co.x) < HALF_W - 1e-4 and abs(v.co.z) < HALF_H - 1e-4]
    for _ in range(4):
        moved = {}
        for v in edge:
            nb = [e.other_vert(v) for e in v.link_edges if e.is_boundary]
            if len(nb) == 2:
                moved[v] = v.co.lerp((nb[0].co + nb[1].co) * 0.5, 0.5)
        for v, co in moved.items():
            v.co = co
    for v in edge:
        n = 0.012 * noise.noise(v.co * 40.0 + Vector((seed, 0.0, 0.0)))
        v.co.x += n
        v.co.z += n * 0.7
    rim_faces = {f for f in bm.faces if f.material_index == 1}
    raise_v = {v for f in rim_faces for v in f.verts}
    for v in bm.verts:
        v.co.y = v.co.x ** 2 / (2.0 * BEND_R)                     # kenarlar gövdeye kıvrılır
        if v in raise_v and all(f.material_index == 1 for f in v.link_faces):
            v.co.y -= RIM_RAISE
        elif v in raise_v:
            v.co.y -= RIM_RAISE * 0.5
        if sh.get("accent") == "window" and all(f.material_index == 2 for f in v.link_faces):
            v.co.y += 0.010                                       # gözetleme yarığı içe gömük
    mesh = bpy.data.meshes.new(name)
    for _ in range(3):           # yuvalar önce: yoksa yüz yuva indisleri kırpılıyor
        mesh.materials.append(bpy.data.materials.new("M_Tmp"))
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    solid = obj.modifiers.new("Solid", "SOLIDIFY")
    solid.thickness = THICK
    solid.offset = -1.0           # kalınlık arkaya (gövdeye doğru)
    kit.apply_all(obj)
    return obj


def frame_from_arm(pts):
    """Kalkan yerleşimi sol önkoldan: (merkez, eksenler x/y/z)."""
    el, wr = pts["elbow_L"][0], pts["wrist_L"][0]
    d = wr - el
    d.z = 0.0
    d.normalize()
    up = Vector((0.0, 0.0, 1.0))
    front = up.cross(d).normalized()                 # önkol -X'e bakarken öne (-Y)
    if front.y > 0.0:
        front = -front
    x = -d                                           # yerel +x sola
    tilt = Matrix.Rotation(math.radians(TILT), 3, x)
    y = tilt @ (-front)                              # yerel +y gövdeye
    z = tilt @ up
    mid = el.lerp(wr, 0.5) + d * INSET
    center = mid + front * FRONT_GAP - z * DROP
    return center, (x, y, z)


def build_shield(pts, v, suffix):
    sh = v["shield"]
    obj = shield_mesh("Armored_Shield", sh, v["seed"])
    center, (x, y, z) = frame_from_arm(pts)
    obj.data.transform(Matrix.Translation(center) @ Matrix((x, y, z)).transposed().to_4x4())
    for p in obj.data.polygons:
        p.use_smooth = False
    slots = [tuple(s) for s in sh["slots"]]
    return am.assign(obj, slots, "M_Armored_Shield" + suffix)
