"""Yürüyen klipleri ölçümü (Blender MCP içinde): ağın en alt noktası, ayak/el/çene konumları, ayak kayması.

    import walker_check as wk; wk.report(rig, mesh)
"""
import bpy

import walker_pose as wp


def measure(rig, mesh, action, frames=None) -> list:
    """Kare kare: ağın en alt noktası, parmak eklemleri, bilekler, kafa ucu, çene ucu (iskelet uzayı)."""
    arm = rig.arm
    arm.animation_data.action = action
    scene = bpy.context.scene
    start, end = int(action.frame_range[0]), int(action.frame_range[1])
    out = []
    for f in frames or range(start, end + 1):
        scene.frame_set(f)
        dg = bpy.context.evaluated_depsgraph_get()
        ev = mesh.evaluated_get(dg)
        me = ev.to_mesh()
        mw = mesh.matrix_world
        low = min((mw @ v.co).z for v in me.vertices)
        ev.to_mesh_clear()
        pb = arm.pose.bones
        out.append({"f": f, "low": low, "ball_l": pb["ball_l"].head.copy(), "ball_r": pb["ball_r"].head.copy(),
                    "hand_l": pb["hand_l"].head.copy(), "hand_r": pb["hand_r"].head.copy(),
                    "head": pb["Head"].tail.copy(), "jaw": pb["jaw"].tail.copy(),
                    "pelvis": pb["pelvis"].head.copy()})
    return out


def report(rig, mesh, names=None) -> dict:
    """Her klip: kare aralığı, ağın en alt noktası (min/max), en düşük el yüksekliği."""
    res = {}
    for act in bpy.data.actions:
        if names and act.name not in names:
            continue
        m = measure(rig, mesh, act)
        res[act.name] = (act.frame_range[:], min(r["low"] for r in m), max(r["low"] for r in m),
                         min(min(r["hand_l"].z, r["hand_r"].z) for r in m))
        print("CHECK %-10s frames %s low %.3f..%.3f hand_min_z %.3f" % ((act.name,) + res[act.name]))
    return res


def set_pose(rig, pose: dict) -> None:
    """Pozu anahtarlamadan uygular (ölçüm ve deneme için)."""
    pose = wp.solve_arms(rig, wp.solve_legs(rig, {k: dict(v) for k, v in pose.items()}))
    for pb in rig.arm.pose.bones:
        ch = pose.get(pb.name, {})
        rest = rig.rest_q[pb.name]
        pb.rotation_quaternion = rest.inverted() @ wp._q(ch.get("rot", (0, 0, 0))) @ rest
        pb.location = rest.inverted() @ wp.Vector(ch.get("loc", (0, 0, 0))) if pb.name == "pelvis" else (0, 0, 0)
    bpy.context.view_layer.update()


def low_where(mesh) -> tuple:
    """Ağın en alt köşesi: (z, baskın kemik)."""
    dg = bpy.context.evaluated_depsgraph_get()
    ev = mesh.evaluated_get(dg)
    me = ev.to_mesh()
    z, i = min(((mesh.matrix_world @ v.co).z, v.index) for v in me.vertices)
    ev.to_mesh_clear()
    v = mesh.data.vertices[i]
    g = max(v.groups, key=lambda g: g.weight)
    return round(z, 3), mesh.vertex_groups[g.group].name


def scan(rig, mesh, fn, times) -> list:
    rig.arm.animation_data.action = None
    out = []
    for t in times:
        set_pose(rig, fn(t, rig))
        out.append((t,) + low_where(mesh))
    return out
