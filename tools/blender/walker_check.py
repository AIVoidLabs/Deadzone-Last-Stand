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


def walk_slip(rig, mesh, walk_fn, feet_fn, cycle: float, speed: float) -> dict:
    """Yürüyüşte basan ayağın kayması (m/döngü, ayak başına): kök `speed` ile -Y'ye ilerlerken, yerdeki
    ayağın en alt köşesinin bir sonraki karedeki dünya yer değişimi toplanır. feet_fn(evre, rig) -> (sol, sağ)
    ayak hedefi; lift > 0 olan kareler salınımdır, sayılmaz. Örnek:
        wk.walk_slip(rig, mesh, wa.walk, wa.walk_feet, wa.WALK_CYCLE, wa.walk_speed(rig))"""
    rig.arm.animation_data.action = None
    inv = rig.arm.matrix_world.inverted() @ mesh.matrix_world
    side_of = {}
    for v in mesh.data.vertices:
        if v.groups:
            name = mesh.vertex_groups[max(v.groups, key=lambda g: g.weight).group].name
            if name[:-2] in ("foot", "ball", "calf"):
                side_of.setdefault(name[-1], []).append(v.index)
    frames = []
    for f in range(round(cycle * wp.FPS) + 1):
        t = f / wp.FPS
        set_pose(rig, walk_fn(t, rig))
        lf, rf = feet_fn((t / cycle) % 1.0, rig)
        ev = mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
        me = ev.to_mesh()
        co = [inv @ v.co for v in me.vertices]
        ev.to_mesh_clear()
        frames.append((t, co, {"l": lf[2], "r": rf[2]}))
    out = {}
    for side, idx in side_of.items():
        slip = 0.0
        for (ta, ca, la), (tb, cb, lb) in zip(frames[:-1], frames[1:]):
            if la[side] > 1e-6 or lb[side] > 1e-6:
                continue
            i = min(idx, key=lambda i: ca[i].z)
            slip += wp.Vector((cb[i].x - ca[i].x, (cb[i].y - speed * tb) - (ca[i].y - speed * ta), 0.0)).length
        out[side] = slip
    print("WALK SLIP", {k: "%.1f cm" % (v * 100) for k, v in out.items()})
    return out
