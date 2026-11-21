"""Çığlıkçı klipleri ölçümü ve kare özeti (7.3).

Ölçüm: basan ayağın dünyadaki kayması (kök WALK_REF_SPEED ile ilerler); çığlıkta çene açıklığı (Head'e
göre jaw açısı, üst diş sırası ile çene ucu arası), bileklerin yana açıklığı, kafa yüksekliği; klip başına
ağın en alt noktası (yere gömülme / havada kalma); IK sınırı; boy.
Kare özeti: her klipten 7 kare, yandan (ya da --front ile önden), zemin ızgaralı (Workbench, köşe rengi)
→ build/shots/screamer_clips_sheet*.png

    blender --background --python tools/blender/screamer_check.py [-- Gown] [--no-sheet] [--front]
"""
import importlib
import math
import os
import sys

import bpy
from mathutils import Vector

_HERE = globals().get("__file__", "")
sys.path.insert(0, os.path.dirname(os.path.abspath(_HERE)) if _HERE else
                os.path.join(r"C:\Users\pekta\projeler\Deadzone-Last-Stand", "tools", "blender"))
import zombie_kit as kit  # noqa: E402
import zombie_game as zg  # noqa: E402
import screamer_game as sg  # noqa: E402
import screamer_anims as sa  # noqa: E402
import walker_pose as wp  # noqa: E402

importlib.reload(sg)
SHOTS = os.path.join(sg.REPO, "build", "shots")
COLS = 7
CELL = 300
SHEET_FRAMES = {"scream": [0, 7, 13, 17, 23, 30, 36]}


def _mesh_low(mesh, who=False):
    """Ağın en alt noktası; who=True ise o köşenin en ağır kemiği de döner."""
    dg = bpy.context.evaluated_depsgraph_get()
    ev = mesh.evaluated_get(dg)
    me = ev.to_mesh()
    mw = mesh.matrix_world
    z, i = min(((mw @ v.co).z, v.index) for v in me.vertices)
    ev.to_mesh_clear()
    if not who:
        return z
    groups = mesh.data.vertices[i].groups
    g = max(groups, key=lambda ge: ge.weight).group if len(groups) else -1
    return z, mesh.vertex_groups[g].name if g >= 0 else "?"


def walk_slip(arm):
    act = bpy.data.actions["walk_Loop"]
    arm.animation_data.action = act
    scene = bpy.context.scene
    v = sa.WALK_REF_SPEED
    rest = {sd: arm.data.bones["ball_" + sd].head_local.z for sd in ("l", "r")}
    worst = 0.0
    last = int(act.frame_range[1])
    for sd in ("l", "r"):
        run, best = [], 0.0
        for f in range(0, last * 2 + 1):
            scene.frame_set(f % last)
            p = arm.pose.bones["ball_" + sd].head
            if p.z < rest[sd] + 0.006:
                run.append(p.y - v * f / wp.FPS)
            elif run:
                best = max(best, max(run) - min(run))
                run = []
        worst = max(worst, best)
        print("SCREAMER SLIP", sd, "%.1f cm" % (best * 100))
    return worst


def scream_marks(arm):
    scene = bpy.context.scene
    arm.animation_data.action = bpy.data.actions["scream"]
    hb, jb = arm.data.bones["Head"], arm.data.bones["jaw"]
    rest_rel = (hb.matrix_local.inverted() @ jb.matrix_local).to_quaternion()
    lip = hb.matrix_local.inverted() @ (jb.head_local + Vector((0.0, -0.07, 0.005)))
    for f in (0, 7, 13, 16, 20, 24, 30, 33, 36):
        scene.frame_set(f)
        ph, pj = arm.pose.bones["Head"], arm.pose.bones["jaw"]
        rel = (ph.matrix.inverted() @ pj.matrix).to_quaternion()
        ang = math.degrees(rest_rel.rotation_difference(rel).angle)
        ang = min(ang, 360.0 - ang)
        chin = arm.matrix_world @ pj.tail
        top = arm.matrix_world @ (ph.matrix @ lip)
        wl, wr = (arm.matrix_world @ arm.pose.bones["hand_" + sd].head for sd in ("l", "r"))
        print("SCREAMER SCREAM f%02d t=%.2f jaw +%.0f deg (toplam %.0f) gap %.3f m wrists span %.2f m head z %.2f" %
              (f, f / wp.FPS, ang, ang + 14.0, (chin - top).length, (wl - wr).length,
               (arm.matrix_world @ ph.tail).z))


def clip_lows(arm, mesh, names):
    scene = bpy.context.scene
    for name in names:
        act = bpy.data.actions[name]
        arm.animation_data.action = act
        lows = []
        for f in range(0, int(act.frame_range[1]) + 1, 2):
            scene.frame_set(f)
            lows.append(_mesh_low(mesh))
        worst = lows.index(min(lows)) * 2
        scene.frame_set(int(act.frame_range[1]))
        _z, end_bone = _mesh_low(mesh, True)
        scene.frame_set(worst)
        _z, bone = _mesh_low(mesh, True)
        print("SCREAMER LOW", name, "frames", int(act.frame_range[1]),
              "min %.3f (f%d %s) max %.3f end %.3f (%s)" % (min(lows), worst, bone, max(lows), lows[-1], end_bone))


# ---------------------------------------------------------------- kare özeti

def _grid():
    mat, _ = kit.material("M_Grid", (0.2, 0.2, 0.2))
    for i in range(-12, 13):
        for axis in (0, 1):
            o = kit.primitive("Grid", "plane", size=1.0)
            o.scale = (6.0, 0.006, 1.0) if axis == 0 else (0.006, 6.0, 1.0)
            o.location = (0.0, i * 0.25, 0.001) if axis == 0 else (i * 0.25, 0.0, 0.001)
            o.data.materials.append(mat)


def render_sheet(arm, names, out, front=False):
    import numpy as np
    scene = bpy.context.scene
    for o in list(bpy.data.objects):
        if o.type == "LIGHT" or o.name.startswith(("Ground", "Grid", "Label")):
            bpy.data.objects.remove(o)
    _grid()
    try:
        scene.render.engine = "BLENDER_WORKBENCH"
    except TypeError as err:
        print("engine:", err)
    shading = scene.display.shading
    shading.light = "STUDIO"
    shading.color_type = "VERTEX"
    shading.show_cavity = True
    scene.render.resolution_x = scene.render.resolution_y = CELL
    scene.view_settings.view_transform = "Standard"
    cam = scene.camera
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = 3.2
    eye, target = ((0.0, -6.0, 2.6), (0.0, 0.0, 1.05)) if front else ((-6.0, 0.15, 2.6), (0.0, 0.15, 1.05))
    cam.location = eye
    cam.rotation_euler = (Vector(target) - Vector(eye)).to_track_quat("-Z", "Y").to_euler()
    label = bpy.data.curves.new("Label", "FONT")
    label.size = 0.15
    lab = bpy.data.objects.new("Label", label)
    scene.collection.objects.link(lab)
    lab.location = (-1.45, 0.0, 2.45) if front else (0.0, 1.55, 2.45)
    lab.rotation_euler = (1.5708, 0.0, 0.0) if front else (1.5708, 0.0, -1.5708)
    rows = []
    for name in names:
        act = bpy.data.actions[name]
        arm.animation_data.action = act
        last = int(act.frame_range[1])
        frames = SHEET_FRAMES.get(name) or sorted({round(last * i / (COLS - 1)) for i in range(COLS)})
        row = []
        for f in frames:
            scene.frame_set(f)
            label.body = "%s %.2fs" % (name.replace("_Loop", ""), f / wp.FPS)
            path = os.path.join(SHOTS, "screamer_cell.png")
            scene.render.filepath = path
            bpy.ops.render.render(write_still=True)
            img = bpy.data.images.load(path, check_existing=False)
            px = np.empty(CELL * CELL * 4, dtype=np.float32)
            img.pixels.foreach_get(px)
            bpy.data.images.remove(img)
            row.append(px.reshape(CELL, CELL, 4))
        while len(row) < COLS:
            row.append(np.ones((CELL, CELL, 4), dtype=np.float32))
        rows.append(np.concatenate(row, axis=1))
    canvas = np.concatenate(rows[::-1], axis=0)
    result = bpy.data.images.new("sheet", canvas.shape[1], canvas.shape[0], alpha=True)
    result.pixels.foreach_set(canvas.ravel())
    result.filepath_raw = out
    result.file_format = "PNG"
    result.save()
    print("SCREAMER SHEET", out)


def render_gamecam(arm, out):
    """Oyun kamerası açısı (55°, 17 m) Workbench köşe rengi, yakın kırpım (uzun odak = 85 mm görüntünün
    büyütülmüş parçası): idle, walk, çığlık tepesi (t 0.73) yan yana."""
    import numpy as np
    scene = bpy.context.scene
    for o in [o for o in bpy.data.objects if o.name.startswith("Label")]:
        bpy.data.objects.remove(o)
    cam = scene.camera
    cam.data.type = "PERSP"
    cam.data.lens = 260
    pitch = math.radians(55.0)
    target = Vector((0.0, 0.0, 0.9))
    cam.location = target + Vector((0.0, -math.cos(pitch), math.sin(pitch))) * 17.0
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.resolution_x, scene.render.resolution_y = 360, 360
    tiles = []
    for name, f in (("idle_Loop", 0), ("walk_Loop", 8), ("scream", 22)):
        arm.animation_data.action = bpy.data.actions[name]
        scene.frame_set(f)
        path = os.path.join(SHOTS, "screamer_cell.png")
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        img = bpy.data.images.load(path, check_existing=False)
        px = np.empty(360 * 360 * 4, dtype=np.float32)
        img.pixels.foreach_get(px)
        bpy.data.images.remove(img)
        tiles.append(px.reshape(360, 360, 4))
    canvas = np.concatenate(tiles, axis=1)
    result = bpy.data.images.new("gc", canvas.shape[1], canvas.shape[0], alpha=True)
    result.pixels.foreach_set(canvas.ravel())
    result.filepath_raw = out
    result.file_format = "PNG"
    result.save()
    print("SCREAMER GAMECAM", out)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    names = [a for a in argv if not a.startswith("-")] or ["Gown"]
    kit.reset_scene()
    mat = zg.vertex_color_material("M_Zombie_VC", glow_strength=0.0)
    v = next(x for x in sg.bs.VARIANTS if x["name"] == names[0])
    arm, mesh = sg.build_variant_game(v, mat)
    clips = sa.build_all(arm)
    print("SCREAMER", v["name"], "tris", zg.tri_count(mesh), "bones", len(arm.data.bones),
          "height %.3f" % sa.mesh_height(arm))
    walk_slip(arm)
    scream_marks(arm)
    clip_lows(arm, mesh, clips)
    if "--no-sheet" not in argv:
        kit.setup_look()
        front = "--front" in argv
        tag = "_front" if front else ""
        render_sheet(arm, clips[:4], os.path.join(SHOTS, "screamer_clips_sheet%s.png" % tag), front)
        render_sheet(arm, clips[4:], os.path.join(SHOTS, "screamer_clips_sheet2%s.png" % tag), front)
        render_gamecam(arm, os.path.join(SHOTS, "screamer_game_gamecam_%s.png" % v["name"].lower()))


if __name__ != "screamer_check":
    main()
