"""Taş fırlatan klipleri ölçümü ve kare özeti (7.3).

Ölçüm: basan ayağın dünyadaki kayması (kök WALK_REF_SPEED ile ilerler); yürürken dev elin en alt noktası
(yere sürtmesin); kavrama anında kayanın tabanı (yere değsin), bırakış anında kayanın yeri; swat vuruşunda
elin önde olduğu mesafe; klip başına ağın en alt noktası; IK sınırı. Kaya, `hand_r` kemiğine ROCK_LOCAL
ofsetiyle bağlıdır (oyun prop'u da aynı kemiğe bağlanır; Godot karşılığı raporda).
Kare özeti: her klipten 7 kare, yandan, zemin ızgaralı (Workbench, köşe rengi) → build/shots/thrower_clips_sheet*.png

    blender --background --python tools/blender/thrower_check.py [-- Vest] [--no-sheet]
"""
import importlib
import os
import sys

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(globals().get("__file__", ""))) if globals().get("__file__")
                else r"C:\Users\pekta\projeler\Deadzone-Last-Stand\tools\blender")
import zombie_kit as kit  # noqa: E402
import zombie_game as zg  # noqa: E402
import thrower_game as tg  # noqa: E402
import thrower_anims as ta  # noqa: E402
import thrower_parts as thp  # noqa: E402
import thrower_rock as rock  # noqa: E402
import walker_pose as wp  # noqa: E402

importlib.reload(tg)
SHOTS = os.path.join(tg.REPO, "build", "shots")
COLS = 7
CELL = 300
GRIP_DEPTH = rock.ROCK_RADIUS * 0.80     # kaya merkezi avuç yüzeyinden bu kadar içeride (avuca gömülü tutuş)


def rock_local(v, arm):
    """Kaya merkezi hand_r kemiğinin yerel uzayında (Blender kemik ekseni: Y kemik boyunca)."""
    b = arm.data.bones["hand_r"]
    k = v["body"].get("arm", 1.0) * tg.bt.HAND_SCALE["R"] * v["body"]["s"]
    p = thp.palm_point(b.head_local, b.tail_local, -1.0, k, GRIP_DEPTH)
    return b.matrix_local.inverted() @ p, p


def rock_matrix(arm, local):
    pb = arm.pose.bones["hand_r"]
    return arm.matrix_world @ pb.matrix @ Matrix.Translation(local)


def _mesh_low(mesh, mask=None):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = mesh.evaluated_get(dg)
    me = ev.to_mesh()
    mw = mesh.matrix_world
    zs = [(mw @ v.co).z for v in me.vertices if mask is None or mask[v.index]]
    ev.to_mesh_clear()
    return min(zs)


def hand_mask(mesh, side="r"):
    g = mesh.vertex_groups.get("hand_" + side).index
    return [any(ge.group == g and ge.weight > 0.5 for ge in v.groups) for v in mesh.data.vertices]


def walk_slip(arm, mesh):
    act = bpy.data.actions["walk_Loop"]
    arm.animation_data.action = act
    scene = bpy.context.scene
    v = ta.WALK_REF_SPEED
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
        print("THROWER SLIP", sd, "%.1f cm" % (best * 100))
    mask = hand_mask(mesh)
    lows = []
    for f in range(0, last + 1, 2):
        scene.frame_set(f)
        lows.append(_mesh_low(mesh, mask))
    print("THROWER WALK hand low %.3f m" % min(lows))
    return worst


def throw_marks(arm, mesh, rock_obj, local):
    scene = bpy.context.scene
    arm.animation_data.action = bpy.data.actions["throw"]
    out = {}
    for name, t in (("grab", ta.GRAB_TIME), ("release", ta.RELEASE_TIME)):
        scene.frame_set(round(t * wp.FPS))
        rock_obj.matrix_world = rock_matrix(arm, local)
        bpy.context.view_layer.update()
        c = rock_obj.matrix_world.translation
        low = min((rock_obj.matrix_world @ vv.co).z for vv in rock_obj.data.vertices)
        out[name] = (tuple(round(x, 3) for x in c), round(low, 3))
        print("THROWER", name.upper(), "frame", round(t * wp.FPS), "rock center", out[name][0], "rock low",
              out[name][1], "hand low %.3f" % _mesh_low(mesh, hand_mask(mesh)))
    arm.animation_data.action = bpy.data.actions["swat"]
    scene.frame_set(round(ta.SWAT_HIT * wp.FPS))
    p = arm.matrix_world @ arm.pose.bones["hand_r"].tail
    print("THROWER SWAT hit frame", round(ta.SWAT_HIT * wp.FPS), "hand tip", tuple(round(x, 3) for x in p))
    return out


def clip_lows(arm, mesh, names):
    scene = bpy.context.scene
    for name in names:
        act = bpy.data.actions[name]
        arm.animation_data.action = act
        lows = []
        for f in range(0, int(act.frame_range[1]) + 1, 2):
            scene.frame_set(f)
            lows.append(_mesh_low(mesh))
        print("THROWER LOW", name, "frames", int(act.frame_range[1]),
              "min %.3f max %.3f end %.3f" % (min(lows), max(lows), lows[-1]))


# ---------------------------------------------------------------- kare özeti

def _grid():
    mat, _ = kit.material("M_Grid", (0.2, 0.2, 0.2))
    for i in range(-12, 13):
        for axis in (0, 1):
            o = kit.primitive("Grid", "plane", size=1.0)
            o.scale = (6.0, 0.006, 1.0) if axis == 0 else (0.006, 6.0, 1.0)
            o.location = (0.0, i * 0.25, 0.001) if axis == 0 else (i * 0.25, 0.0, 0.001)
            o.data.materials.append(mat)


SHEET_FRAMES = {"throw": [0, 6, 9, 15, 22, 27, 33], "swat": [0, 10, 15, 18, 22, 26, 30]}
ROCK_SHOWN = (round(ta.GRAB_TIME * wp.FPS), round(ta.RELEASE_TIME * wp.FPS))


def render_sheet(arm, names, out, rock_obj, local, cam_x=-6.0):
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
    cam.data.ortho_scale = 3.0
    cam.location = (cam_x, -0.35, 2.4)
    cam.rotation_euler = (Vector((0.0, -0.35, 0.95)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    label = bpy.data.curves.new("Label", "FONT")
    label.size = 0.15
    lab = bpy.data.objects.new("Label", label)
    scene.collection.objects.link(lab)
    lab.location = (0.0, 1.05, 2.25)
    lab.rotation_euler = (1.5708, 0.0, -1.5708 if cam_x < 0 else 1.5708)
    rows = []
    for name in names:
        act = bpy.data.actions[name]
        arm.animation_data.action = act
        last = int(act.frame_range[1])
        frames = SHEET_FRAMES.get(name) or sorted({round(last * i / (COLS - 1)) for i in range(COLS)})
        row = []
        for f in frames:
            scene.frame_set(f)
            rock_obj.hide_render = not (name == "throw" and ROCK_SHOWN[0] <= f <= ROCK_SHOWN[1])
            rock_obj.matrix_world = rock_matrix(arm, local)
            label.body = "%s %.2fs" % (name.replace("_Loop", ""), f / wp.FPS)
            path = os.path.join(SHOTS, "thrower_cell.png")
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
    print("THROWER SHEET", out)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    names = [a for a in argv if not a.startswith("-")] or ["Vest"]
    kit.reset_scene()
    mat = zg.vertex_color_material("M_Zombie_VC", glow_strength=0.0)
    v = next(x for x in tg.bt.VARIANTS if x["name"] == names[0])
    arm, mesh = tg.build_variant_game(v, mat)
    clips = ta.build_all(arm)
    print("THROWER", v["name"], "tris", zg.tri_count(mesh), "bones", len(arm.data.bones),
          "height %.3f" % ta.mesh_height(arm))
    local, rest_p = rock_local(v, arm)
    print("THROWER ROCK_LOCAL (hand_r, Blender bone space) %s, rest model-space %s" %
          (tuple(round(x, 4) for x in local), tuple(round(x, 4) for x in rest_p)))
    rock_obj = rock.build_rock("Check_Rock")
    walk_slip(arm, mesh)
    throw_marks(arm, mesh, rock_obj, local)
    clip_lows(arm, mesh, clips)
    if "--no-sheet" not in argv:
        kit.setup_look()
        render_sheet(arm, clips[:4], os.path.join(SHOTS, "thrower_clips_sheet.png"), rock_obj, local)
        render_sheet(arm, clips[4:], os.path.join(SHOTS, "thrower_clips_sheet2.png"), rock_obj, local)


if __name__ != "thrower_check":
    main()
