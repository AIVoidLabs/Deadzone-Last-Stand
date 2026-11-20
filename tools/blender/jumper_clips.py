"""Zıplayan klip denetimi (V.5 v2): yürüyüşte basan ayak kayması + klip kare özeti.

jumper_game.py'nin kaydettiği build/blender/jumper_game.blend üstünde çalışır (ilk çeşidin klipleri orada).
    blender --background build/blender/jumper_game.blend --python tools/blender/jumper_clips.py
Çıktı: stdout'ta SLIP satırları; build/shots/jumper_clips_sheet_<n>.png (her klipten 7 kare, yandan,
zemin ızgaralı, karede klip adı + sn). Video yok.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import jumper_anims as ja  # noqa: E402
import walker_pose as wp  # noqa: E402
import walker_render as wr  # noqa: E402

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
SHOTS = os.path.join(REPO, "build", "shots")
CLIPS = [c[0] for c in ja.CLIPS] + ["death_a", "death_b", "spawn"]
COLS, ROWS_PER_SHEET = 7, 5
TILE = 300


def rig():
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE" and o.animation_data
               and o.animation_data.action)
    return arm


def measure_slip(arm) -> None:
    """Basış evresinde parmak ekleminin dünya konumu (model y - REF_SPEED*t) ne kadar oynuyor."""
    arm.animation_data.action = bpy.data.actions["walk_Loop"]
    frames = round(ja.WALK_CYCLE * wp.FPS)
    for sd, rng in (("l", ja.L_STANCE), ("r", ja.R_STANCE)):
        ys, zs = [], []
        for f in range(frames * 2 + 1):
            phi = (f / wp.FPS / ja.WALK_CYCLE) % 1.0
            u = ((phi - rng[0]) % 1.0) / (rng[1] - rng[0])
            if not (0.05 <= u <= 0.95) or f / wp.FPS > ja.WALK_CYCLE * 2:
                continue
            bpy.context.scene.frame_set(f % frames)
            p = arm.pose.bones["ball_" + sd].head
            ys.append((u, p.y - ja.REF_SPEED * (u * (rng[1] - rng[0]) * ja.WALK_CYCLE)))
            zs.append(p.z)
        dy = max(y for _u, y in ys) - min(y for _u, y in ys)
        dz = max(zs) - min(zs)
        print("SLIP %s: stance world drift %.1f mm (y), %.1f mm (z), samples %d" % (sd, dy * 1000, dz * 1000, len(ys)))


def setup_scene(arm):
    for o in list(bpy.data.objects):
        if o.type == "ARMATURE" and o != arm:
            for child in o.children:
                child.hide_render = True
            o.hide_render = True
    arm.location = (0.0, 0.0, 0.0)
    ground = bpy.data.objects.get("Ground")
    mat = bpy.data.materials.new("M_Grid")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    chk = nt.nodes.new("ShaderNodeTexChecker")
    chk.inputs["Scale"].default_value = 4.0                    # nesne uzayı: 25 cm kare
    chk.inputs["Color1"].default_value = (0.09, 0.09, 0.10, 1.0)
    chk.inputs["Color2"].default_value = (0.05, 0.05, 0.055, 1.0)
    coord = nt.nodes.new("ShaderNodeTexCoord")
    nt.links.new(coord.outputs["Object"], chk.inputs["Vector"])
    nt.links.new(chk.outputs["Color"], bsdf.inputs["Base Color"])
    if ground is not None:
        ground.data.materials.clear()
        ground.data.materials.append(mat)
    scene = bpy.context.scene
    try:
        scene.render.engine = "BLENDER_EEVEE"
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = scene.render.resolution_y = TILE
    cam = scene.camera
    cam.data.lens = 40
    wr._aim(cam, (2.7, -0.25, 0.8), (0.0, -0.25, 0.62))
    txt = bpy.data.curves.new("Label", "FONT")
    label = bpy.data.objects.new("Label", txt)
    scene.collection.objects.link(label)
    label.location = (-0.3, 0.75, 1.32)
    label.rotation_euler = (math.radians(90), 0.0, math.radians(90))
    txt.size = 0.11
    tmat = bpy.data.materials.new("M_Label")
    tmat.use_nodes = True
    tb = next(n for n in tmat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    tb.inputs["Emission Color"].default_value = (1.0, 0.85, 0.4, 1.0)
    tb.inputs["Emission Strength"].default_value = 3.0
    txt.materials.append(tmat)
    return txt


def render_sheets(arm, txt):
    os.makedirs(SHOTS, exist_ok=True)
    tiles = []
    for clip in CLIPS:
        act = bpy.data.actions[clip]
        arm.animation_data.action = act
        last = int(act.frame_range[1])
        row = []
        for i in range(COLS):
            f = round(last * i / (COLS - 1))
            bpy.context.scene.frame_set(f)
            txt.body = "%s %.2fs" % (clip.replace("_Loop", ""), f / wp.FPS)
            path = os.path.join(SHOTS, "_jc_%s_%d.png" % (clip, i))
            row.append(wr._render_to(path))
        tiles.append(row)
    outs = []
    for n in range(0, len(tiles), ROWS_PER_SHEET):
        rows = [wr._side_by_side(r, os.path.join(SHOTS, "_jc_row_%d.png" % (n + k)))
                for k, r in enumerate(tiles[n:n + ROWS_PER_SHEET])]
        outs.append(stack(rows, os.path.join(SHOTS, "jumper_clips_sheet_%d.png" % (n // ROWS_PER_SHEET + 1))))
    return outs


def stack(paths, out):
    import numpy as np
    imgs = [bpy.data.images.load(p, check_existing=False) for p in paths]
    w, h = imgs[0].size[0], sum(i.size[1] for i in imgs)
    canvas = np.zeros((h, w, 4), dtype=np.float32)
    y = h
    for img in imgs:          # Blender piksel dizisi alttan başlar: ilk satır en üste
        iw, ih = img.size
        px = np.empty(iw * ih * 4, dtype=np.float32)
        img.pixels.foreach_get(px)
        y -= ih
        canvas[y:y + ih, :iw] = px.reshape(ih, iw, 4)
    res = bpy.data.images.new("stack", w, h, alpha=True)
    res.pixels.foreach_set(canvas.ravel())
    res.filepath_raw, res.file_format = out, "PNG"
    res.save()
    return out


arm_obj = rig()
if "--rebuild" in sys.argv:      # klipleri betikten yeniden üret (model yeniden kurulmadan poz yinelemesi)
    for _c in CLIPS:
        if _c in bpy.data.actions:
            bpy.data.actions.remove(bpy.data.actions[_c])
    ja.build_all(arm_obj)
measure_slip(arm_obj)
label_curve = setup_scene(arm_obj)
print("CLIPS sheets:", render_sheets(arm_obj, label_curve))
