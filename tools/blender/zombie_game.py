"""Zombi oyun hattı (Aşama V.4): görünüş modelini oyuna hazırlar.

incelt → köşe rengi (renk fonksiyonları, oyuk koyulaşması, alfa = parıltı maskesi) → parça başına
kemik ağırlığı → tek ağda birleştir → iskelet → GLB. Prosedürel malzemeler GLB'ye geçmediği için
renk köşelere yazılır; Godot tarafı COLOR ile boyar, (1 - COLOR.a) parıltıdır (göz, kese).
Operatör yalnız nesne modunda ve temp_override ile (MCP bağlamı).
"""
import math

import bmesh
import bpy
from mathutils import Matrix, Vector, noise

import zombie_kit as kit

COLOR_ATTR = "Col"


def decimate(obj, target_tris: int) -> None:
    """Collapse ile üçgen hedefine indirir (oran üçgen sayısına göre; dörtgenler 2 üçgen sayılır)."""
    tris = tri_count(obj)
    if tris > target_tris:
        mod = obj.modifiers.new("Dec", "DECIMATE")
        mod.ratio = target_tris / tris
        kit.apply_all(obj)


def _smooth(lo: float, hi: float, x: float) -> float:
    t = min(max((x - lo) / (hi - lo), 0.0), 1.0)
    return t * t * (3.0 - 2.0 * t)


def _mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def fbm(p: Vector, scale: float) -> float:
    """Blender Noise dokusuna yakın 0..1 değer."""
    q = p * scale
    return 0.5 + 0.38 * noise.noise(q) + 0.16 * noise.noise(q * 2.1) + 0.08 * noise.noise(q * 4.3)


def skin_color(tone, bruise):
    return lambda p: _mix(tone, bruise, _smooth(0.42, 0.68, fbm(p, 6.0)))


def cloth_color(color, stain=(0.10, 0.07, 0.05), blood=0.0):
    def fn(p):
        c = _mix(color, stain, _smooth(0.45, 0.75, fbm(p, 4.0)))
        if blood > 0.0:
            b = _smooth(0.62 - blood * 0.2, 0.66, fbm(p + Vector((5.0, 1.0, 2.0)), 2.5))
            c = _mix(c, (c[0] * 0.16, c[1] * 0.015, c[2] * 0.02), b)
        return c
    return fn


def flat_color(color):
    return lambda p: color


def vein_color(base=(0.42, 0.37, 0.20), vein=(0.22, 0.03, 0.05)):
    def fn(p):
        dist, _pts = noise.voronoi(p * 9.0, distance_metric="DISTANCE", exponent=2.5)
        return _mix(vein, base, _smooth(0.0, 0.06, dist[1] - dist[0]))
    return fn


def layered_color(regions, fallback):
    """Kabuk bölgeleri: regions = [(BVHTree, erişim_m, renk_fn)] öncelik sırasıyla. Nokta bir
    kabuğa erişimden yakınsa onun rengi, değilse fallback. Kıyafeti ayrı kabuk yerine gövdenin
    kendi köşelerine boyamak için (kabuk sonra silinir)."""
    def fn(p):
        for tree, reach, color_fn in regions:
            if tree.find_nearest(p, reach)[0] is not None:
                return color_fn(p)
        return fallback(p)
    return fn


def world_bvh(obj):
    """Nesnenin dünya koordinatlı BVH ağacı (kabuk bölgesi için)."""
    from mathutils.bvhtree import BVHTree
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.transform(obj.matrix_world)
    tree = BVHTree.FromBMesh(bm)
    bm.free()
    return tree


def paint_slots(obj, color_fns, glow: float = 0.0, dirt: float = 0.45) -> None:
    """Malzeme yuvasına göre köşe rengi (ör. ayakkabı üstü / taban): köşe, bağlı yüzlerinin
    çoğunluk yuvasının renk fonksiyonunu alır."""
    votes = [[0] * len(color_fns) for _ in obj.data.vertices]
    for poly in obj.data.polygons:
        slot = min(poly.material_index, len(color_fns) - 1)
        for vi in poly.vertices:
            votes[vi][slot] += 1
    slots = [max(range(len(color_fns)), key=lambda s, row=row: row[s]) for row in votes]
    _paint_verts(obj, lambda i, p: color_fns[slots[i]](p), glow, dirt)


def paint(obj, color_fn, glow: float = 0.0, dirt: float = 0.45) -> None:
    """Köşe rengi: renk fonksiyonu × oyuk koyulaşması; alfa = 1 - parıltı."""
    _paint_verts(obj, lambda _i, p: color_fn(p), glow, dirt)


def _paint_verts(obj, color_at, glow: float, dirt: float) -> None:
    """color_at(köşe_indeksi, dünya_konumu) × oyuk koyulaşması; alfa = 1 - parıltı."""
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.normal_update()
    matrix = obj.matrix_world
    shades = []
    for v in bm.verts:
        if v.link_edges:
            avg = sum((e.other_vert(v).co for e in v.link_edges), Vector()) / len(v.link_edges)
            concave = (avg - v.co).dot(v.normal)
        else:
            concave = 0.0
        shades.append(1.0 - dirt * min(max(concave * 120.0, 0.0), 1.0))
    bm.free()
    attr = mesh.color_attributes.get(COLOR_ATTR) or mesh.color_attributes.new(COLOR_ATTR, "FLOAT_COLOR", "POINT")
    for i, v in enumerate(mesh.vertices):
        c = color_at(i, matrix @ v.co)
        s = shades[i]
        attr.data[i].color = (c[0] * s, c[1] * s, c[2] * s, 1.0 - glow)


def weight_to(obj, bone: str) -> None:
    """Tüm ağı tek kemiğe bağlar (kafa, çene yarısı, kese, dişler)."""
    group = obj.vertex_groups.get(bone) or obj.vertex_groups.new(name=bone)
    group.add(range(len(obj.data.vertices)), 1.0, "REPLACE")


def weight_by_distance(obj, segments: dict, keep: int = 3, power: float = 4.0) -> None:
    """Gövde ve kıyafet: kemik parçalarına uzaklıkla yumuşak ağırlık (skin modifier gövdesi
    zaten bu parçalar boyunca kurulduğu için doğal oturur). segments: kemik -> (baş, uç)."""
    groups = {name: obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name) for name in segments}
    matrix = obj.matrix_world
    for v in obj.data.vertices:
        p = matrix @ v.co
        scored = []
        for name, (a, b) in segments.items():
            ab = b - a
            t = min(max((p - a).dot(ab) / max(ab.length_squared, 1e-9), 0.0), 1.0)
            d = (p - (a + ab * t)).length
            scored.append((1.0 / max(d, 0.004) ** power, name))
        scored.sort(reverse=True)
        top = scored[:keep]
        total = sum(w for w, _ in top)
        for w, name in top:
            groups[name].add([v.index], w / total, "REPLACE")


def smooth_weights(obj, iterations: int = 3, keep: int = 4, factor: float = 0.5) -> None:
    """Ağ komşuluğuyla ağırlık yumuşatma: uzaklık ağırlığının eklem çevresindeki sert geçişini
    (bükülünce yırtılma bandı) açar. Köşe başına en çok `keep` kemik, toplam 1."""
    mesh = obj.data
    names = [g.name for g in obj.vertex_groups]
    count = len(mesh.vertices)
    weights = [dict() for _ in range(count)]
    for v in mesh.vertices:
        for ge in v.groups:
            if ge.weight > 0.0:
                weights[v.index][ge.group] = ge.weight
    neighbors = [[] for _ in range(count)]
    for e in mesh.edges:
        a, b = e.vertices
        neighbors[a].append(b)
        neighbors[b].append(a)
    for _ in range(iterations):
        new = []
        for i in range(count):
            if not neighbors[i]:
                new.append(weights[i])
                continue
            acc = {}
            for j in neighbors[i]:
                for g, w in weights[j].items():
                    acc[g] = acc.get(g, 0.0) + w
            n = len(neighbors[i])
            mixed = {g: w * (1.0 - factor) for g, w in weights[i].items()}
            for g, w in acc.items():
                mixed[g] = mixed.get(g, 0.0) + factor * w / n
            new.append(mixed)
        weights = new
    for i, row in enumerate(weights):
        top = sorted(row.items(), key=lambda gw: gw[1], reverse=True)[:keep]
        total = sum(w for _, w in top) or 1.0
        for g in range(len(names)):
            obj.vertex_groups[g].remove([i])
        for g, w in top:
            obj.vertex_groups[g].add([i], w / total, "REPLACE")


def _override(active, selected):
    return bpy.context.temp_override(active_object=active, object=active, selected_objects=selected,
                                     selected_editable_objects=selected)


def join(objects, name: str):
    """Parçaları tek ağda birleştirir (köşe grupları ve renkler korunur)."""
    target = objects[0]
    bpy.context.view_layer.update()
    worlds = [obj.matrix_world.copy() for obj in objects]
    for obj, world in zip(objects, worlds):
        # dönüşümü ağa göm, nesneyi kimliğe al (birleşik ağ dünya koordinatında kalır)
        obj.parent = None
        obj.data.transform(world)
        obj.matrix_world = Matrix.Identity(4)
    with _override(target, objects):
        bpy.ops.object.join()
    target.name = name
    target.data.name = name
    return target


def build_armature(name: str, bones: list):
    """bones: [(ad, baş, uç, ebeveyn_adı|None)] dünya koordinatlarında."""
    arm = bpy.data.armatures.new(name)
    obj = bpy.data.objects.new(name, arm)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    with _override(obj, [obj]):
        bpy.ops.object.mode_set(mode="EDIT")
        made = {}
        for bone_name, head, tail, parent in bones:
            eb = arm.edit_bones.new(bone_name)
            eb.head = head
            eb.tail = tail
            eb.roll = 0.0
            if parent:
                eb.parent = made[parent]
            made[bone_name] = eb
        bpy.ops.object.mode_set(mode="OBJECT")
    for pb in obj.pose.bones:
        pb.rotation_mode = "QUATERNION"
    return obj


def bind(mesh_obj, arm_obj) -> None:
    mesh_obj.parent = arm_obj
    mod = mesh_obj.modifiers.new("Armature", "ARMATURE")
    mod.object = arm_obj


def vertex_color_material(name: str, glow_strength: float = 3.0):
    """Blender önizlemesi için: COLOR rengi, (1 - alfa) parıltı. Godot kendi shader'ını kullanır."""
    mat, bsdf = kit.material(name, (1.0, 1.0, 1.0), rough=0.6, sss=0.08)
    nt = mat.node_tree
    col = nt.nodes.new("ShaderNodeVertexColor")
    col.layer_name = COLOR_ATTR
    nt.links.new(col.outputs["Color"], bsdf.inputs["Base Color"])
    inv = nt.nodes.new("ShaderNodeMath")
    inv.operation = "SUBTRACT"
    inv.inputs[0].default_value = 1.0
    nt.links.new(col.outputs["Alpha"], inv.inputs[1])
    nt.links.new(col.outputs["Color"], bsdf.inputs["Emission Color"])
    mul = nt.nodes.new("ShaderNodeMath")
    mul.operation = "MULTIPLY"
    mul.inputs[1].default_value = glow_strength
    nt.links.new(inv.outputs[0], mul.inputs[0])
    nt.links.new(mul.outputs[0], bsdf.inputs["Emission Strength"])
    return mat


def export_glb(path: str, objects, **extra) -> None:
    # use_selection gerçek seçim durumuna bakar (override listesine değil); extra: ek gltf seçenekleri
    for obj in bpy.context.view_layer.objects:
        obj.select_set(obj in objects)
    with _override(objects[0], objects):
        bpy.ops.export_scene.gltf(filepath=path, use_selection=True, export_format="GLB",
                                  export_animation_mode="ACTIONS", export_yup=True,
                                  export_apply=False, export_skins=True, **extra)


def tri_count(obj) -> int:
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def deg(v) -> float:
    return math.radians(v)
