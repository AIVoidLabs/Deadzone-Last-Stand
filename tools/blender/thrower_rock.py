"""Fırlatılan kaya (7.3 taş fırlatan prop'u): kırık beton/asfalt parçası, ≤300 üçgen, köşe rengi.

Köken merkezde, çap ~0.45 m. Kırık beton: düzensiz çokyüzlü (ikosfer + gürültü + birkaç düz kırık yüz),
üst yüzünde koyu asfalt tabakası, kırık yüzlerde açık agrega, kenarlarda kir; bir paslı demir filizi.
build_thrower (konsept, eldeki kaya) ve thrower_game (prop GLB) kullanır.

Tek başına:  blender --background --python tools/blender/thrower_rock.py
Çıktı: assets/models/props/thrown_rock.glb
"""
import os
import random
import sys

import bmesh
import bpy
from mathutils import Vector, noise

ROCK_DIAMETER = 0.45
ROCK_RADIUS = ROCK_DIAMETER * 0.5
TRI_LIMIT = 300
CONCRETE = (0.30, 0.29, 0.26)
AGGREGATE = (0.42, 0.40, 0.35)
ASPHALT = (0.035, 0.035, 0.038)
DIRT = (0.10, 0.08, 0.06)
REBAR = (0.16, 0.06, 0.025)
# kırık düzlemleri: (normal, kesme mesafesi oranı) — yaşlı beton parçası köşeli okunsun
CUTS = (((0.0, 0.0, 1.0), 0.62), ((0.9, 0.2, -0.3), 0.78), ((-0.6, 0.7, 0.1), 0.80),
        ((-0.3, -0.9, -0.2), 0.84), ((0.2, -0.3, -1.0), 0.72))


def _mesh(name):
    rng = random.Random(7)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=3, radius=1.0)
    for v in bm.verts:
        d = v.co.normalized()
        v.co = d * (1.0 + 0.16 * noise.noise(d * 2.3 + Vector((3.1, 1.7, 0.4))))
        v.co.x *= 1.12
        v.co.z *= 0.86
    for n, k in CUTS:     # kırık yüzler: düzlemin ötesindeki köşeler düzleme izdüşer
        n = Vector(n).normalized()
        for v in bm.verts:
            d = v.co.dot(n) - k
            if d > 0.0:
                v.co -= n * d * (1.0 + rng.uniform(-0.05, 0.05))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.02)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    size = max((max(v.co[i] for v in bm.verts) - min(v.co[i] for v in bm.verts)) for i in range(3))
    center = Vector([(max(v.co[i] for v in bm.verts) + min(v.co[i] for v in bm.verts)) * 0.5 for i in range(3)])
    for v in bm.verts:
        v.co = (v.co - center) * (ROCK_DIAMETER / size)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    return mesh


def _paint(mesh):
    """Köşe rengi (yüz köşesi başına: kırık yüz keskin okunsun): üst = asfalt, düz kırık = agrega."""
    attr = mesh.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
    top = Vector(CUTS[0][0])
    for poly in mesh.polygons:
        n = poly.normal
        flat = max(abs(n.dot(Vector(c).normalized())) for c, _k in CUTS[1:])
        for li in poly.loop_indices:
            p = mesh.vertices[mesh.loops[li].vertex_index].co
            g = 0.5 + 0.5 * noise.noise(p * 18.0)
            c = tuple(CONCRETE[i] + (AGGREGATE[i] - CONCRETE[i]) * g for i in range(3))
            if flat > 0.93:
                c = tuple(c[i] * 1.15 for i in range(3))
            if n.dot(top) > 0.85:
                c = ASPHALT if g > 0.25 else tuple(ASPHALT[i] * 1.8 for i in range(3))
            dirt = max(0.0, -p.z / ROCK_RADIUS) * 0.5
            c = tuple(c[i] + (DIRT[i] - c[i]) * dirt for i in range(3))
            attr.data[li].color = (*c, 1.0)


def _rebar(mesh):
    """Kırık yüzden çıkan kısa paslı demir filizi (6 kenarlı çubuk)."""
    bm = bmesh.new()
    bm.from_mesh(mesh)
    first = len(bm.verts)
    start = Vector((0.10, 0.02, -0.02))
    tip = start + Vector((0.9, 0.25, -0.2)).normalized() * 0.13
    res = bmesh.ops.create_cone(bm, cap_ends=True, segments=6, radius1=0.011, radius2=0.009, depth=0.13)
    axis = (tip - start).normalized()
    rot = Vector((0.0, 0.0, 1.0)).rotation_difference(axis)
    for v in res["verts"]:
        v.co = rot @ v.co + (start + tip) * 0.5
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    return set(range(first, len(mesh.vertices)))


def build_rock(name="Thrown_Rock"):
    """Kaya nesnesini kurar (köken merkezde) ve döner."""
    mesh = _mesh(name)
    tmp = bpy.data.objects.new(name + "_tmp", mesh)
    bpy.context.collection.objects.link(tmp)
    dec = tmp.modifiers.new("Dec", "DECIMATE")
    dec.ratio = (TRI_LIMIT - 40) / len(mesh.polygons)
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    mesh = bpy.data.meshes.new_from_object(tmp.evaluated_get(dg))
    bpy.data.objects.remove(tmp)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    rebar = _rebar(mesh)
    _paint(mesh)
    attr = mesh.color_attributes["Col"]
    for poly in mesh.polygons:
        if all(v in rebar for v in poly.vertices):
            for li in poly.loop_indices:
                attr.data[li].color = (*REBAR, 1.0)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    for p in mesh.polygons:
        p.use_smooth = False
    return obj


def rock_material(name="M_Rock_VC"):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Roughness"].default_value = 0.9
    col = nt.nodes.new("ShaderNodeVertexColor")
    col.layer_name = "Col"
    nt.links.new(col.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def tri_count(obj) -> int:
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def export(path):
    obj = build_rock()
    obj.data.materials.append(rock_material())
    tris = tri_count(obj)
    assert tris <= TRI_LIMIT, tris
    bpy.context.view_layer.update()
    for o in bpy.context.scene.objects:
        o.select_set(o is obj)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with bpy.context.temp_override(active_object=obj, object=obj, selected_objects=[obj]):
        bpy.ops.export_scene.gltf(filepath=path, use_selection=True, export_format="GLB", export_yup=True,
                                  export_apply=True, export_animations=False)
    size = obj.dimensions
    print("ROCK tris %d size %.3f x %.3f x %.3f" % (tris, size.x, size.y, size.z), "->", path)
    return obj


if __name__ not in ("thrower_rock",):
    _repo = os.path.abspath(os.path.join(os.path.dirname(globals().get("__file__", ".")), "..", ".."))
    sys.path.insert(0, os.path.join(_repo, "tools", "blender"))
    for _o in list(bpy.data.objects):
        bpy.data.objects.remove(_o)
    export(os.path.join(_repo, "assets", "models", "props", "thrown_rock.glb"))
