"""Koşucu klip kare özeti (V.5): her klipten 8 kare, yandan, ızgaralı zeminde → build/shots/runner_clips_sheet*.png.

runner_game.py'nin kaydettiği build/blender/runner_game.blend açılır; bir çeşidin iskeleti başa alınır.
    blender --background build/blender/runner_game.blend --python tools/blender/runner_sheet.py -- [Torn] [--side=x|front]
Satır = klip (adı ve kare zamanı görüntüde), sütun = eşit aralıklı kareler (ilk ve son dahil).
Izgara 10 cm (kalın çizgi 50 cm): basan ayağın kayması ve yere girme buradan okunur.
"""
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Vector

REPO = r"C:\Users\pekta\projeler\Deadzone-Last-Stand"
OUT_DIR = os.path.join(REPO, "build", "shots")
CLIPS = ["idle_Loop", "walk_Loop", "scream", "sprint_Loop", "strike", "stagger", "death_a", "death_b", "spawn"]
COLS = 8
CELL = (320, 300)
ROWS_PER_PAGE = 5


def _grid_material():
    mat = bpy.data.materials.new("M_Grid")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    coord = nt.nodes.new("ShaderNodeTexCoord")
    fine = nt.nodes.new("ShaderNodeTexBrick")
    for brick, scale, mortar in ((fine, 10.0, 0.04),):
        brick.offset = 0.0
        brick.squash = 1.0
        brick.inputs["Scale"].default_value = scale
        brick.inputs["Mortar Size"].default_value = mortar
        brick.inputs["Brick Width"].default_value = 1.0
        brick.inputs["Row Height"].default_value = 1.0
        brick.inputs["Color1"].default_value = (0.20, 0.21, 0.23, 1)
        brick.inputs["Color2"].default_value = (0.20, 0.21, 0.23, 1)
        brick.inputs["Mortar"].default_value = (0.03, 0.03, 0.035, 1)
        nt.links.new(coord.outputs["Object"], brick.inputs["Vector"])
    nt.links.new(fine.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.9
    return mat


def setup(variant, view):
    scene = bpy.context.scene
    arm = None
    for obj in bpy.data.objects:
        if obj.type == "ARMATURE":
            if obj.name == "Runner_Rig_" + variant:
                arm = obj
                obj.location = (0.0, 0.0, 0.0)
            else:
                obj.hide_render = True
                for ch in obj.children_recursive:
                    ch.hide_render = True
    ground = bpy.data.objects.get("Ground")
    if ground is not None:
        ground.data.materials.clear()
        ground.data.materials.append(_grid_material())
    try:
        scene.render.engine = "BLENDER_EEVEE"
    except TypeError as err:
        print("engine:", err)
    scene.render.resolution_x, scene.render.resolution_y = CELL
    scene.render.image_settings.file_format = "PNG"
    cam = scene.camera
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = 2.5
    target = Vector((0.0, -0.40, 0.50))
    eye = target + (Vector((5.0, 0.0, 1.9)) if view == "side" else Vector((1.6, -5.0, 0.8)))
    cam.location = eye
    cam.rotation_euler = (target - eye).to_track_quat("-Z", "Y").to_euler()
    for name in ("Key", "Rim", "Fill"):
        light = bpy.data.objects.get(name)
        if light is not None:
            light.data.energy *= 1.2
    text = bpy.data.curves.new("Label", "FONT")
    label = bpy.data.objects.new("Label", text)
    scene.collection.objects.link(label)
    text.size = 0.16
    label.parent = cam
    label.location = (-1.18, 1.00, -2.0)
    mat = bpy.data.materials.new("M_Label")
    mat.use_nodes = True
    em = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    em.inputs["Base Color"].default_value = (0, 0, 0, 1)
    em.inputs["Emission Color"].default_value = (1.0, 0.85, 0.2, 1)
    em.inputs["Emission Strength"].default_value = 4.0
    text.materials.append(mat)
    return arm, text


def render_cells(arm, text, variant):
    scene = bpy.context.scene
    rows = []
    tmp = os.path.join(OUT_DIR, "_runner_cell.png")
    for clip in CLIPS:
        act = bpy.data.actions["%s_%s" % (clip, variant)]
        arm.animation_data.action = act
        a, b = int(act.frame_range[0]), int(act.frame_range[1])
        frames = [round(a + (b - a) * i / (COLS - 1)) for i in range(COLS)]
        row = []
        for f in frames:
            scene.frame_set(f)
            text.body = "%s  %.2fs" % (clip.replace("_Loop", ""), f / 30.0)
            scene.render.filepath = tmp
            bpy.ops.render.render(write_still=True)
            img = bpy.data.images.load(tmp, check_existing=False)
            px = np.empty(CELL[0] * CELL[1] * 4, dtype=np.float32)
            img.pixels.foreach_get(px)
            row.append(px.reshape(CELL[1], CELL[0], 4))
            bpy.data.images.remove(img)
        rows.append(np.concatenate(row, axis=1))
    return rows


def save_pages(rows, view):
    paths = []
    for p in range(0, len(rows), ROWS_PER_PAGE):
        chunk = rows[p:p + ROWS_PER_PAGE][::-1]            # Blender pikselleri alttan başlar
        canvas = np.concatenate(chunk, axis=0)
        h, w = canvas.shape[:2]
        img = bpy.data.images.new("sheet", w, h, alpha=True)
        img.pixels.foreach_set(canvas.ravel())
        suffix = "" if p == 0 else "_%d" % (p // ROWS_PER_PAGE + 1)
        path = os.path.join(OUT_DIR, "runner_clips_sheet%s%s.png" % ("" if view == "side" else "_front", suffix))
        img.filepath_raw = path
        img.file_format = "PNG"
        img.save()
        bpy.data.images.remove(img)
        paths.append(path)
    return paths


def main(argv):
    args = argv[argv.index("--") + 1:] if "--" in argv else []
    variant = next((a for a in args if not a.startswith("--")), "Torn")
    view = next((a.split("=")[1] for a in args if a.startswith("--side=")), "side")
    os.makedirs(OUT_DIR, exist_ok=True)
    arm, text = setup(variant, view)
    print("RUNNER SHEET", save_pages(render_cells(arm, text, variant), view))


main(sys.argv)
