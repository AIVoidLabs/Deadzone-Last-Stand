"""Boss "Yığın" klip ölçümü ve kare özeti (7.4). bloater_check.py kopyası, uyarlandı.

Ölçüm: walk ve charge döngüsünde basan ayağın dünyadaki kayması (kök ref hızla ilerler), slam'de topuz ve
pençenin en alt noktası (0.8 doruk, 1.1 iniş), charge_windup son karesi ile charge ilk karesinin farkı,
klip başına ağın en alt noktası (yere gömülme), GLB COLOR_0 tipi (VEC4 = alfa taşınıyor) ve kemik adları.
Kare özeti: her klipten 7 kare, yandan, zemin ızgaralı (Workbench, köşe rengi) → build/shots/boss_clips_sheet*.png

    blender --background --python tools/blender/boss_check.py [-- --no-sheet]
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
import boss_game as bg  # noqa: E402
import boss_anims as ba  # noqa: E402
import walker_pose as wp  # noqa: E402

importlib.reload(bg)
SHOTS = os.path.join(bg.REPO, "build", "shots")
COLS = 7
CELL = 300
FRAMES = {"slam": [0, 10, 18, 24, 29, 33, 36, 44, 52, 63], "charge_windup": [0, 8, 13, 17, 21, 26, 30]}


def _verts(mesh):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = mesh.evaluated_get(dg)
    me = ev.to_mesh()
    mw = mesh.matrix_world
    out = [mw @ v.co for v in me.vertices]
    ev.to_mesh_clear()
    return out


def group_verts(mesh, name, min_w=0.5):
    g = mesh.vertex_groups[name].index
    return [v.index for v in mesh.data.vertices if any(ge.group == g and ge.weight >= min_w for ge in v.groups)]


def contact(arm, sd):
    """Tabanın yer temas noktası: parmak ekleminin altındaki zemin noktası (walker_pose ayak dönüşünün
    ekseni). Topuk kalkıp parmaktan iterken eklem bu nokta çevresinde döner; temas noktası yerinde kalır."""
    pb = arm.pose.bones["foot_" + sd]
    rel = pb.matrix.to_quaternion() @ arm.data.bones["foot_" + sd].matrix_local.to_quaternion().inverted()
    ball = arm.pose.bones["ball_" + sd].head
    return ball - rel @ Vector((0.0, 0.0, arm.data.bones["ball_" + sd].head_local.z))


def slip(arm, rig, clip, v):
    """Basan ayağın kayması (m): parmak eklemi ve zemin temas noktası. Temas = eklem dinlenmenin +8 mm altı."""
    act = bpy.data.actions[clip]
    arm.animation_data.action = act
    scene = bpy.context.scene
    n = int(act.frame_range[1])
    rest = {sd: arm.data.bones["ball_" + sd].head_local.z for sd in ("l", "r")}
    worst = 0.0
    for sd in ("l", "r"):
        run, runc, best, bestc = [], [], 0.0, 0.0
        for f in range(0, n * 2 + 1):
            scene.frame_set(f % n)
            p = arm.pose.bones["ball_" + sd].head
            if p.z < rest[sd] + 0.008:
                run.append(p.y - v * f / wp.FPS)
                runc.append(contact(arm, sd).y - v * f / wp.FPS)
            elif run:
                best = max(best, max(run) - min(run))
                bestc = max(bestc, max(runc) - min(runc))
                run, runc = [], []
        worst = max(worst, bestc)
        print("BOSS SLIP", clip, sd, "ball %.1f cm, contact %.1f cm" % (best * 100, bestc * 100))
    return worst


def slam_report(arm, mesh):
    act = bpy.data.actions["slam"]
    arm.animation_data.action = act
    mace = group_verts(mesh, "hand_l", 0.9)
    claw = group_verts(mesh, "claw_r", 0.9)
    for f in (21, 24, 27, 30, 31, 32, 33, 34, 36, 40):
        bpy.context.scene.frame_set(f)
        vs = _verts(mesh)
        print("BOSS SLAM f%02d %.2fs mace_low %.3f claw_low %.3f mace_y %.2f" % (
            f, f / wp.FPS, min(vs[i].z for i in mace), min(vs[i].z for i in claw),
            sum(vs[i].y for i in mace) / len(mace)))


def windup_join(arm):
    """charge_windup son karesi ile charge ilk karesi arasındaki en büyük kemik farkı (derece)."""
    import math
    diffs = []
    for clip, frame in (("charge_windup", 30), ("charge_Loop", 0)):
        arm.animation_data.action = bpy.data.actions[clip]
        bpy.context.scene.frame_set(frame)
        diffs.append({pb.name: pb.matrix.copy() for pb in arm.pose.bones})
    worst = max(math.degrees(diffs[0][n].to_quaternion().rotation_difference(diffs[1][n].to_quaternion()).angle)
                for n in diffs[0])
    move = max((diffs[0][n].translation - diffs[1][n].translation).length for n in diffs[0])
    print("BOSS WINDUP->CHARGE max rot %.2f deg, max move %.3f m" % (worst, move))


def _part_sets(mesh):
    """Köşe -> parça (en ağır kemiğe göre): topuz, pençe, ayak, gövde."""
    names = {g.index: g.name for g in mesh.vertex_groups}
    part = {"mace": ("hand_l",), "claw": ("hand_r", "claw_r"), "feet": ("foot_l", "foot_r", "ball_l", "ball_r"),
            "arm": ("lowerarm_l", "lowerarm_r", "upperarm_l", "upperarm_r")}
    out = {k: [] for k in list(part) + ["body"]}
    for v in mesh.data.vertices:
        top = max(v.groups, key=lambda ge: ge.weight, default=None)
        n = names[top.group] if top else ""
        out[next((k for k, bs in part.items() if n in bs), "body")].append(v.index)
    return out


def clip_lows(arm, mesh, names):
    scene = bpy.context.scene
    parts = _part_sets(mesh)
    for name in names:
        act = bpy.data.actions[name]
        arm.animation_data.action = act
        lows = {k: [] for k in parts}
        for f in range(0, int(act.frame_range[1]) + 1, 2):
            scene.frame_set(f)
            vs = _verts(mesh)
            for k, idx in parts.items():
                lows[k].append((min(vs[i].z for i in idx), f))
        txt = " ".join("%s %.2f@%d" % (k, *min(v)) for k, v in lows.items())
        end = min(v[-1][0] for v in lows.values())
        print("BOSS LOW", name, txt, "end %.3f" % end)


def glb_report(path):
    import json
    import struct
    with open(path, "rb") as f:
        data = f.read()
    n = struct.unpack("<I", data[12:16])[0]
    j = json.loads(data[20:20 + n])
    for m in j["meshes"]:
        for pr in m["primitives"]:
            acc = j["accessors"][pr["attributes"]["COLOR_0"]] if "COLOR_0" in pr["attributes"] else None
            print("BOSS GLB COLOR_0", acc["type"] if acc else "YOK", acc.get("componentType") if acc else "")
    print("BOSS GLB joints", len(j["skins"][0]["joints"]), [j["nodes"][i]["name"] for i in j["skins"][0]["joints"]])
    for an in j.get("animations", []):
        ch = an["channels"]
        sampler = an["samplers"][ch[0]["sampler"]]
        print("BOSS GLB anim", an["name"], "len %.3f" % j["accessors"][sampler["input"]]["max"][0])


# ---------------------------------------------------------------- kare özeti

def _grid():
    mat, _ = kit.material("M_Grid", (0.2, 0.2, 0.2))
    for i in range(-14, 15):
        for axis in (0, 1):
            o = kit.primitive("Grid", "plane", size=1.0)
            o.scale = (14.0, 0.012, 1.0) if axis == 0 else (0.012, 14.0, 1.0)
            o.location = (0.0, i * 0.5, 0.001) if axis == 0 else (i * 0.5, 0.0, 0.001)
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
    sh = scene.display.shading
    sh.light = "STUDIO"
    sh.color_type = "VERTEX"
    sh.show_cavity = True
    scene.render.resolution_x = scene.render.resolution_y = CELL
    scene.view_settings.view_transform = "Standard"
    cam = scene.camera
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = 6.4
    cam.location = (0.6, -14.0, 4.6) if front else (-14.0, -0.6, 4.6)
    cam.rotation_euler = (Vector((0.0, -0.6, 1.8)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    label = bpy.data.curves.new("Label", "FONT")
    label.size = 0.34
    lab = bpy.data.objects.new("Label", label)
    scene.collection.objects.link(lab)
    lab.location = (-2.6, 1.0, 4.5) if front else (-1.0, 2.2, 4.5)
    lab.rotation_euler = (1.5708, 0.0, 0.0) if front else (1.5708, 0.0, -1.5708)
    rows = []
    for name in names:
        act = bpy.data.actions[name]
        arm.animation_data.action = act
        last = int(act.frame_range[1])
        frames = FRAMES.get(name) or sorted({round(last * i / (COLS - 1)) for i in range(COLS)})
        frames = frames[:COLS] if name != "slam" else [0, 18, 24, 29, 33, 44, 63]
        row = []
        for f in frames:
            scene.frame_set(f)
            label.body = "%s %.2fs" % (name.replace("_Loop", ""), f / wp.FPS)
            path = os.path.join(SHOTS, "boss_cell.png")
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
    print("BOSS SHEET", out)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    kit.reset_scene()
    mat = zg.vertex_color_material("M_Zombie_VC", glow_strength=0.0)
    arm, mesh = bg.build_game_model(mat)
    clips = ba.build_all(arm)
    rig = wp.Rig(arm)
    rig.mesh_h = ba.mesh_height(arm)
    print("BOSS tris", zg.tri_count(mesh), "bones", len(arm.data.bones), "height %.3f" % rig.mesh_h)
    slip(arm, rig, "walk_Loop", ba.speed(rig, ba.WALK_SPEED))
    slip(arm, rig, "charge_Loop", ba.speed(rig, ba.CHARGE_SPEED))
    slam_report(arm, mesh)
    windup_join(arm)
    glb_report(bg.OUT_PATH)
    clip_lows(arm, mesh, clips)
    if "--no-sheet" not in argv:
        kit.setup_look()
        render_sheet(arm, clips[:5], os.path.join(SHOTS, "boss_clips_sheet.png"))
        render_sheet(arm, clips[5:], os.path.join(SHOTS, "boss_clips_sheet2.png"))
        render_sheet(arm, ["walk_Loop", "charge_Loop", "slam"], os.path.join(SHOTS, "boss_clips_front.png"), front=True)


if __name__ != "boss_check":
    main()
