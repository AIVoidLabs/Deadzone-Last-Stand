"""Prop önizleme görüntüleri (arka planda): gün (nötr) ve oyun (gece, 60 derece yukarıdan).

blender --background --python tools/blender/wreck_render.py -- <mod> <çıktı.png> <glb1> <glb2> ...
mod: day | game ; glb yolları yan yana dizilir (X ekseni boyunca), araç uzunluğu Y.
"""
import math
import sys

import bpy
from mathutils import Vector


def clear() -> None:
    for coll in (bpy.data.objects, bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.worlds):
        for block in list(coll):
            coll.remove(block)


def add_light(kind, loc, energy, color, size=1.0, rot=None):
    data = bpy.data.lights.new(kind, kind)
    data.energy = energy
    data.color = color
    if kind == "SUN":
        data.angle = 0.2
    elif kind == "POINT":
        data.shadow_soft_size = size
    ob = bpy.data.objects.new(kind, data)
    ob.location = loc
    if rot:
        ob.rotation_euler = rot
    bpy.context.scene.collection.objects.link(ob)
    return ob


def main() -> None:
    args = sys.argv[sys.argv.index("--") + 1:]
    mode, out, paths = args[0], args[1], args[2:]
    clear()
    scene = bpy.context.scene
    try:
        scene.render.engine = "BLENDER_EEVEE"
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 700 if mode == "day" else 900
    scene.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    scene.world = world
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    xs = []
    x = 0.0
    for p in paths:
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=p)
        new = [o for o in bpy.data.objects if o not in before]
        for o in new:
            if o.type == "MESH" and len(o.data.color_attributes):
                an = o.data.color_attributes[0].name
                for slot in o.material_slots:
                    nt = slot.material.node_tree
                    bs = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
                    if slot.material.name.startswith("wreck_body") and not bs.inputs["Base Color"].links:
                        vc = nt.nodes.new("ShaderNodeVertexColor")
                        vc.layer_name = an
                        nt.links.new(vc.outputs["Color"], bs.inputs["Base Color"])
        root = bpy.data.objects.new("root", None)
        scene.collection.objects.link(root)
        for o in new:
            if o.parent is None:
                o.parent = root
        bpy.context.view_layer.update()
        pts = [o.matrix_world @ Vector(c) for o in new if o.type == "MESH" for c in o.bound_box]
        w = max(pt.x for pt in pts) - min(pt.x for pt in pts)
        ln = max(pt.y for pt in pts) - min(pt.y for pt in pts)
        if ln > w:
            root.rotation_euler = (0, 0, math.radians(90 if mode == "day" else 62))
        bpy.context.view_layer.update()
        pts = [o.matrix_world @ Vector(c) for o in new if o.type == "MESH" for c in o.bound_box]
        lo = Vector((min(pt.x for pt in pts), min(pt.y for pt in pts), min(pt.z for pt in pts)))
        hi = Vector((max(pt.x for pt in pts), max(pt.y for pt in pts), max(pt.z for pt in pts)))
        step = (hi.x - lo.x) + 1.2
        root.location = (x - (lo.x + hi.x) / 2 + (hi.x - lo.x) / 2, -(lo.y + hi.y) / 2, -lo.z)
        xs.append(x)
        x += step
    total = x
    mid = (total - 1.2) / 2
    # zemin
    bpy.ops.mesh.primitive_plane_add(size=60, location=(mid, 0, 0))
    ground = bpy.context.object
    gm = bpy.data.materials.new("g")
    gm.use_nodes = True
    gb = next(n for n in gm.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    gb.inputs["Base Color"].default_value = (0.1, 0.1, 0.105, 1) if mode == "game" else (0.45, 0.45, 0.45, 1)
    gb.inputs["Roughness"].default_value = 0.95
    ground.data.materials.append(gm)
    cam_data = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    span = max(total, 6.0)
    if mode == "day":
        bg.inputs["Color"].default_value = (0.6, 0.62, 0.65, 1)
        bg.inputs["Strength"].default_value = 1.0
        add_light("SUN", (0, 0, 10), 3.0, (1, 0.97, 0.92), rot=(math.radians(50), 0, math.radians(-35)))
        cam_data.type = "ORTHO"
        cam_data.ortho_scale = span * 1.05
        cam.location = (mid, -20, 9)
        cam.rotation_euler = (math.radians(68), 0, 0)
    else:
        bg.inputs["Color"].default_value = (0.02, 0.035, 0.08, 1)
        bg.inputs["Strength"].default_value = 1.0
        add_light("SUN", (0, 0, 10), 0.6, (0.5, 0.6, 1.0), rot=(math.radians(40), 0, math.radians(30)))
        add_light("POINT", (mid - span * 0.25, -2.0, 1.6), 260, (1.0, 0.45, 0.08), 0.4)
        add_light("POINT", (mid + span * 0.2, -3.0, 4.5), 160, (1.0, 0.85, 0.3), 0.4)
        cam_data.type = "PERSP"
        cam_data.lens = 50
        d = span * 1.1 + 6
        cam.location = (mid, -d * math.sin(math.radians(60)) * -1 * -1, d * math.sin(math.radians(60)))
        cam.location = (mid, -d * math.cos(math.radians(60)), d * math.sin(math.radians(60)))
        cam.rotation_euler = (math.radians(30), 0, 0)
    scene.render.filepath = out
    bpy.ops.render.render(write_still=True)


main()
