"""Zırhlı klipleri ölçümü ve kare özeti (7.3). tank_check.py'den uyarlandı.

Ölçüm: basan ayağın dünyadaki kayması (kök WALK_REF_SPEED ile ilerler), klip başına ağın en alt noktası
(yere gömülme / havada kalma), vuruş anında kalkan yüzünün kökten ileri mesafesi, yürüyüşte kalkanın
gövdenin önünde kalması (kalkan merkezi ile pelvis arası ileri mesafe, en az), IK sınırı.
Kare özeti: her klipten 7 kare, yandan, zemin ızgaralı (Workbench, köşe rengi) → build/shots/armored_clips_sheet*.png

    blender --background --python tools/blender/armored_check.py [-- Riot] [--no-sheet]
"""
import importlib
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(globals().get("__file__", ""))) if globals().get("__file__")
                else r"C:\Users\pekta\projeler\Deadzone-Last-Stand\tools\blender")
import zombie_kit as kit  # noqa: E402
import zombie_game as zg  # noqa: E402
import armored_game as tg  # noqa: E402
import armored_anims as ta  # noqa: E402
import walker_pose as wp  # noqa: E402

importlib.reload(tg)
SHOTS = os.path.join(tg.REPO, "build", "shots")
COLS = 7
CELL = 300


def _mesh_low(mesh, part_prefix=None):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = mesh.evaluated_get(dg)
    me = ev.to_mesh()
    mw = mesh.matrix_world
    zs = [(mw @ v.co).z for v in me.vertices if part_prefix is None or part_prefix[v.index]]
    ev.to_mesh_clear()
    return min(zs)


def walk_slip(arm):
    """Basan ayağın (parmak eklemi) dünyadaki kayması: m. Temas = eklem yüksekliği dinlenmenin ±6 mm'si."""
    act = bpy.data.actions["walk_Loop"]
    arm.animation_data.action = act
    scene = bpy.context.scene
    v = ta.WALK_REF_SPEED
    rest = {sd: arm.data.bones["ball_" + sd].head_local.z for sd in ("l", "r")}
    worst = 0.0
    for sd in ("l", "r"):
        run, best = [], 0.0
        for f in range(0, int(act.frame_range[1]) * 2 + 1):     # iki tur: basış sarabilir
            scene.frame_set(f % int(act.frame_range[1]))
            p = arm.pose.bones["ball_" + sd].head
            if p.z < rest[sd] + 0.006:
                run.append(p.y - v * f / wp.FPS)
            elif run:
                best = max(best, max(run) - min(run))
                run = []
        worst = max(worst, best)
        print("ARMORED SLIP", sd, "%.1f cm" % (best * 100))
    return worst


def clip_lows(arm, mesh, names):
    scene = bpy.context.scene
    out = {}
    for name in names:
        act = bpy.data.actions[name]
        arm.animation_data.action = act
        lows = []
        for f in range(0, int(act.frame_range[1]) + 1, 2):
            scene.frame_set(f)
            lows.append(_mesh_low(mesh))
        out[name] = (min(lows), max(lows), lows[-1])
        print("ARMORED LOW", name, "frames", int(act.frame_range[1]), "min %.3f max %.3f end %.3f" % out[name])
    return out


def _shield_verts(mesh):
    g = mesh.vertex_groups["hand_l"].index
    return [v.index for v in mesh.data.vertices
            if len(v.groups) == 1 and v.groups[0].group == g]


def _eval_pts(mesh, idx):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = mesh.evaluated_get(dg)
    me = ev.to_mesh()
    mw = mesh.matrix_world
    out = [mw @ me.vertices[i].co for i in idx]
    ev.to_mesh_clear()
    return out


def shield_at_hit(arm, mesh):
    """Vuruş karesinde kalkanın en ön noktası (kökten -Y, m) ve yürüyüşte kalkan-pelvis ileri farkı (en az)."""
    idx = _shield_verts(mesh)
    arm.animation_data.action = bpy.data.actions["attack"]
    bpy.context.scene.frame_set(round(ta.HIT_TIME * wp.FPS))
    front = -min(p.y for p in _eval_pts(mesh, idx))
    act = bpy.data.actions["walk_Loop"]
    arm.animation_data.action = act
    lead = 9.0
    for f in range(int(act.frame_range[1]) + 1):
        bpy.context.scene.frame_set(f)
        pts = _eval_pts(mesh, idx)
        c = sum(pts, Vector()) / len(pts)
        lead = min(lead, arm.pose.bones["pelvis"].head.y - c.y)
    print("ARMORED HIT shield front %.3f m (verts %d); walk shield ahead of pelvis min %.3f m" % (front, len(idx), lead))
    return front, lead


# ---------------------------------------------------------------- kare özeti

def _grid():
    mat, _ = kit.material("M_Grid", (0.2, 0.2, 0.2))
    for i in range(-12, 13):
        for axis in (0, 1):
            o = kit.primitive("Grid", "plane", size=1.0)
            o.scale = (6.0, 0.006, 1.0) if axis == 0 else (0.006, 6.0, 1.0)
            o.location = (0.0, i * 0.25, 0.001) if axis == 0 else (i * 0.25, 0.0, 0.001)
            o.data.materials.append(mat)


def render_sheet(arm, mesh, names, out):
    scene = bpy.context.scene
    for o in list(bpy.data.objects):
        if o.type in ("LIGHT",) or o.name.startswith(("Ground", "Grid", "Label")):
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
    cam.location = (-6.0, -0.35, 2.6)
    cam.rotation_euler = (Vector((0.0, -0.35, 0.95)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    label = bpy.data.curves.new("Label", "FONT")
    label.size = 0.16
    lab = bpy.data.objects.new("Label", label)
    scene.collection.objects.link(lab)
    lab.location = (-1.0, 1.05, 2.3)
    lab.rotation_euler = (1.5708, 0.0, -1.5708)
    import numpy as np
    rows = []
    for name in names:
        act = bpy.data.actions[name]
        arm.animation_data.action = act
        last = int(act.frame_range[1])
        frames = sorted({round(last * i / (COLS - 1)) for i in range(COLS)})
        if name == "attack":
            frames = [0, 7, 11, 17, 21, 25, 42]
        row = []
        for f in frames:
            scene.frame_set(f)
            label.body = "%s %.2fs" % (name.replace("_Loop", ""), f / wp.FPS)
            path = os.path.join(SHOTS, "armored_cell.png")
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
    canvas = np.concatenate(rows[::-1], axis=0)      # Blender pikselleri alttan başlar
    result = bpy.data.images.new("sheet", canvas.shape[1], canvas.shape[0], alpha=True)
    result.pixels.foreach_set(canvas.ravel())
    result.filepath_raw = out
    result.file_format = "PNG"
    result.save()
    print("ARMORED SHEET", out)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    names = [a for a in argv if not a.startswith("-")] or ["Riot"]
    kit.reset_scene()
    mat = zg.vertex_color_material("M_Zombie_VC", glow_strength=0.0)
    v = next(x for x in tg.ba.VARIANTS if x["name"] == names[0])
    arm, mesh = tg.build_variant_game(v, mat)
    clips = ta.build_all(arm)
    print("TANK", v["name"], "tris", zg.tri_count(mesh), "bones", len(arm.data.bones),
          "height %.3f" % ta.mesh_height(arm))
    walk_slip(arm)
    shield_at_hit(arm, mesh)
    clip_lows(arm, mesh, clips)
    if "--no-sheet" not in argv:
        kit.setup_look()
        render_sheet(arm, mesh, clips[:4], os.path.join(SHOTS, "armored_clips_sheet.png"))
        render_sheet(arm, mesh, clips[4:], os.path.join(SHOTS, "armored_clips_sheet2.png"))


if __name__ != "armored_check":
    main()
