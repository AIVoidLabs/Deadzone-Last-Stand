"""Zombi kiti: Blender MCP ile zombi üretiminin ortak parçaları (Aşama V).

Operatörsüz çalışır (MCP bağlamında bpy.ops güvenilmez). Tür betikleri (`build_<tür>.py`)
bunu içe aktarır: gövde (skin modifier + voxel remesh), metaball kütleleri, gövde yüzeyinden
kıyafet, malzemeler, stüdyo ışığı.
"""
import math

import bmesh
import bpy
from mathutils import Vector, noise

def reset_scene() -> None:
    """Sahneyi operatörsüz boşaltır (MCP bağlamında read_homefile sonrası bağlam bozuluyor)."""
    for coll in (bpy.data.objects, bpy.data.meshes, bpy.data.curves, bpy.data.armatures,
                 bpy.data.materials, bpy.data.lights, bpy.data.cameras, bpy.data.textures,
                 bpy.data.images, bpy.data.actions, bpy.data.worlds):
        for block in list(coll):
            coll.remove(block)
    bpy.context.scene.unit_settings.system = "METRIC"


def primitive(name, kind, location=(0.0, 0.0, 0.0), **kw):
    """bmesh ile ilkel ağ nesnesi (bpy.ops yerine)."""
    bm = bmesh.new()
    if kind == "sphere":
        bmesh.ops.create_uvsphere(bm, u_segments=kw.get("segments", 32),
                                  v_segments=kw.get("rings", 24), radius=kw.get("radius", 1.0))
    elif kind == "cone":
        bmesh.ops.create_cone(bm, cap_ends=True, segments=kw.get("segments", 8),
                              radius1=kw["radius1"], radius2=0.0, depth=kw["depth"])
    elif kind == "plane":
        bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=kw["size"] * 0.5)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    obj.location = location
    bpy.context.collection.objects.link(obj)
    return obj


def material(name, base, rough=0.6, sss=0.0, coat=0.0, emission=None, strength=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*base, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Subsurface Weight"].default_value = sss
    bsdf.inputs["Subsurface Radius"].default_value = (0.08, 0.03, 0.02)
    bsdf.inputs["Coat Weight"].default_value = coat
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = strength
    return mat, bsdf




def _mottle(nt, scale, dark, light, low=0.42, high=0.68):
    """Gürültüden iki renk arasında alaca (ten morlukları, kumaş lekeleri)."""
    tex = nt.nodes.new("ShaderNodeTexNoise")
    tex.inputs["Scale"].default_value = scale
    tex.inputs["Detail"].default_value = 8.0
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = low
    ramp.color_ramp.elements[0].color = (*light, 1.0)
    ramp.color_ramp.elements[1].position = high
    ramp.color_ramp.elements[1].color = (*dark, 1.0)
    nt.links.new(tex.outputs["Fac"], ramp.inputs["Fac"])
    return ramp


def _ao_darken(nt, color_socket, bsdf, crevice=(0.10, 0.08, 0.08)):
    """Oyuklarda (AO düşük) koyulaşma."""
    ao = nt.nodes.new("ShaderNodeAmbientOcclusion")
    ao.inputs["Distance"].default_value = 0.05
    lerp = nt.nodes.new("ShaderNodeMix")
    lerp.data_type = "RGBA"
    nt.links.new(ao.outputs["AO"], lerp.inputs["Factor"])
    lerp.inputs["A"].default_value = (*crevice, 1.0)
    nt.links.new(color_socket, lerp.inputs["B"])
    nt.links.new(lerp.outputs["Result"], bsdf.inputs["Base Color"])


def _bump(nt, bsdf, scale, strength):
    tex = nt.nodes.new("ShaderNodeTexNoise")
    tex.inputs["Scale"].default_value = scale
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = strength
    nt.links.new(tex.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])


def skin_material(name, tone=(0.26, 0.29, 0.22), bruise=(0.22, 0.13, 0.16)):
    """Ten: renk tonu + çürük morluklar + oyuklarda koyulaşma + ince yumru."""
    mat, bsdf = material(name, tone, rough=0.55, sss=0.12)
    nt = mat.node_tree
    ramp = _mottle(nt, 6.0, bruise, tone)
    _ao_darken(nt, ramp.outputs["Color"], bsdf)
    _bump(nt, bsdf, 40.0, 0.25)
    return mat


def cloth_material(name, color, stain=(0.10, 0.07, 0.05), blood=0.0):
    """Eski kumaş: soluk renk, kir lekeleri, isteğe bağlı koyu kan lekesi; dokuma pürüzü."""
    mat, bsdf = material(name, color, rough=0.9)
    nt = mat.node_tree
    ramp = _mottle(nt, 4.0, stain, color, low=0.45, high=0.75)
    color_socket = ramp.outputs["Color"]
    if blood > 0.0:
        blood_ramp = _mottle(nt, 2.5, (0.16, 0.015, 0.02), (1, 1, 1), low=0.62 - blood * 0.2, high=0.66)
        mul = nt.nodes.new("ShaderNodeMix")
        mul.data_type = "RGBA"
        mul.blend_type = "MULTIPLY"
        mul.inputs["Factor"].default_value = 1.0
        nt.links.new(color_socket, mul.inputs["A"])
        nt.links.new(blood_ramp.outputs["Color"], mul.inputs["B"])
        color_socket = mul.outputs["Result"]
    _ao_darken(nt, color_socket, bsdf, crevice=(0.03, 0.03, 0.03))
    _bump(nt, bsdf, 120.0, 0.15)
    return mat


def garment(body, name, keep, mat, offset=0.009, thickness=0.004,
            hems=(), holes=0.0, hole_scale=9.0, seed=0.0, smooth_edges=0):
    """Gövde yüzeyinden kıyafet: `keep(co)` doğru olan yüzler kopyalanır, dışa itilir.
    hems: [(eksen, sınır, yön, genlik, ölçek)] — yırtık kenar: yön>0 ise sınırın üstü kalır.
    holes: 0..1 yırtık delik yoğunluğu (gürültü eşiği).
    smooth_edges: kesik kenar halkasını bu kadar tur gevşetir (voxel merdiveni yumuşar; 0 = eski)."""
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bm.transform(body.matrix_world)
    shift = Vector((seed, seed * 1.7, seed * 0.3))

    def torn(co):
        for axis, limit, direction, amp, scale in hems:
            edge = limit + amp * noise.noise(co * scale + shift)
            if (co[axis] - edge) * direction < 0.0:
                return True
        return holes > 0.0 and noise.noise(co * hole_scale + shift * 3.0) > 0.62 - holes * 0.3

    dead = [f for f in bm.faces if not keep(f.calc_center_median()) or torn(f.calc_center_median())]
    bmesh.ops.delete(bm, geom=dead, context="FACES")
    bm.normal_update()
    if smooth_edges > 0:
        _relax_boundary(bm, smooth_edges)
    for v in bm.verts:
        v.co += v.normal * offset
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    solid = obj.modifiers.new("Solid", "SOLIDIFY")
    solid.thickness = thickness
    solid.offset = 1.0
    apply_all(obj)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def _relax_boundary(bm, iterations, weight=0.5) -> None:
    """Açık kenar halkasındaki köşeleri komşu kenar köşelerinin ortasına çeker; iç köşelerin
    ilk halkası da yarı oranda izler ki kenar boyunca kırışık kalmasın."""
    ring = [v for v in bm.verts if v.is_boundary]
    for _ in range(iterations):
        moved = {}
        for v in ring:
            nbrs = [e.other_vert(v) for e in v.link_edges if e.is_boundary]
            if len(nbrs) == 2:
                avg = (nbrs[0].co + nbrs[1].co) * 0.5
                moved[v] = v.co.lerp(avg, weight)
        for v, co in moved.items():
            v.co = co
    inner = {e.other_vert(v) for v in ring for e in v.link_edges if not e.other_vert(v).is_boundary}
    for v in inner:
        nbrs = [e.other_vert(v) for e in v.link_edges]
        avg = sum((n.co for n in nbrs), Vector()) / len(nbrs)
        v.co = v.co.lerp(avg, 0.5)


def metaball_oriented(name, blobs, mat, resolution=0.003, smooth=4):
    """Döndürülmüş elipsoidlerden ağ (saç tutamı, ayakkabı gibi eğik kütleler).
    blobs: [(merkez, (yarıçap_x, y, z), dönüş_quaternion, negatif_mi)]"""
    mb = bpy.data.metaballs.new(name + "_mb")
    mb.resolution = resolution
    mb.render_resolution = resolution
    for center, radii, quat, negative in blobs:
        el = mb.elements.new(type="ELLIPSOID")
        el.co = center
        r = max(radii) / METABALL_SURFACE
        el.radius = r
        el.size_x, el.size_y, el.size_z = (q / (METABALL_SURFACE * r) for q in radii)
        el.rotation = quat
        el.use_negative = negative
        el.stiffness = 1.8 if not negative else 3.0
    tmp = bpy.data.objects.new(name + "_tmp", mb)
    bpy.context.collection.objects.link(tmp)
    depsgraph = bpy.context.evaluated_depsgraph_get()
    depsgraph.update()
    mesh = bpy.data.meshes.new_from_object(tmp.evaluated_get(depsgraph))
    bpy.data.objects.remove(tmp)
    bpy.data.metaballs.remove(mb)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    if smooth:
        mod = obj.modifiers.new("Smooth", "CORRECTIVE_SMOOTH")
        mod.iterations = smooth
        apply_all(obj)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def skin_object(name, points, edges, mat):
    """Nokta + kenar listesinden skin modifier'lı organik ağ; uygulanmış ve yumuşatılmış döner."""
    names = list(points)
    verts = [points[n][0] for n in names]
    index = {n: i for i, n in enumerate(names)}
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [(index[a], index[b]) for a, b in edges], [])
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    skin = obj.modifiers.new("Skin", "SKIN")
    skin.use_smooth_shade = True
    for i, n in enumerate(names):
        r = points[n][1]
        obj.data.skin_vertices[0].data[i].radius = (r, r * 0.85)
    obj.data.skin_vertices[0].data[0].use_root = True
    sub = obj.modifiers.new("Sub", "SUBSURF")
    sub.levels = 2
    obj.data.materials.append(mat)
    apply_all(obj)
    return obj


def apply_all(obj) -> None:
    """Modifier'ları değerlendirilmiş ağa çevirir (operatörsüz; MCP bağlamında da çalışır)."""
    depsgraph = bpy.context.evaluated_depsgraph_get()
    depsgraph.update()
    mesh = bpy.data.meshes.new_from_object(obj.evaluated_get(depsgraph))
    old = obj.data
    if obj.type == "MESH":
        obj.modifiers.clear()
        obj.data = mesh
        if old.users == 0:
            bpy.data.meshes.remove(old)
        return
    # eğri: ağ nesnesiyle değiştir
    name, matrix = obj.name, obj.matrix_world.copy()
    bpy.data.objects.remove(obj)
    new_obj = bpy.data.objects.new(name, mesh)
    new_obj.matrix_world = matrix
    bpy.context.collection.objects.link(new_obj)
    return new_obj


def organic_pass(obj, voxel=0.008, lump=0.006) -> None:
    """Voxel remesh ile birleşim yerlerini eritir, sonra hafif yumrulu ten."""
    rem = obj.modifiers.new("Remesh", "REMESH")
    rem.mode = "VOXEL"
    rem.voxel_size = voxel
    smooth = obj.modifiers.new("Smooth", "CORRECTIVE_SMOOTH")
    smooth.iterations = 6
    tex = bpy.data.textures.new(obj.name + "_lump", "CLOUDS")
    tex.noise_scale = 0.06
    disp = obj.modifiers.new("Lump", "DISPLACE")
    disp.texture = tex
    disp.strength = lump
    disp.mid_level = 0.5
    apply_all(obj)
    for poly in obj.data.polygons:
        poly.use_smooth = True




METABALL_SURFACE = 0.57  # eşik 0.6'da yüzey, etki yarıçapının ~0.57 katında oluşur


def metaball_mesh(name, blobs, mat, resolution=0.0035):
    """Elipsoid kütlelerden (negatifler oyar) organik ağ: heykel yerine kütle birleştirme.
    blobs: [(merkez, (yarıçap_x, y, z), negatif_mi)]"""
    mb = bpy.data.metaballs.new(name + "_mb")
    mb.resolution = resolution
    mb.render_resolution = resolution
    for center, radii, negative in blobs:
        el = mb.elements.new(type="ELLIPSOID")
        el.co = center
        r = max(radii) / METABALL_SURFACE
        el.radius = r
        el.size_x, el.size_y, el.size_z = (radii[0] / (METABALL_SURFACE * r) * 1.0,
                                           radii[1] / (METABALL_SURFACE * r),
                                           radii[2] / (METABALL_SURFACE * r))
        el.use_negative = negative
        el.stiffness = 1.8 if not negative else 3.0
    tmp = bpy.data.objects.new(name + "_tmp", mb)
    bpy.context.collection.objects.link(tmp)
    depsgraph = bpy.context.evaluated_depsgraph_get()
    depsgraph.update()
    mesh = bpy.data.meshes.new_from_object(tmp.evaluated_get(depsgraph))
    bpy.data.objects.remove(tmp)
    bpy.data.metaballs.remove(mb)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    smooth = obj.modifiers.new("Smooth", "CORRECTIVE_SMOOTH")
    smooth.iterations = 4
    apply_all(obj)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def mirrored(center, radii, negative=False):
    x, y, z = center
    return [((x, y, z), radii, negative), ((-x, y, z), radii, negative)]


# Kafa yerel uzayı: köken boyun üstü, yüz -Y.


def setup_look(target_height=1.2) -> None:
    scene = bpy.context.scene
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (0.02, 0.022, 0.028, 1.0)
    scene.world = world
    ground, _ = material("M_Ground", (0.05, 0.05, 0.055), rough=0.9)
    primitive("Ground", "plane", size=40).data.materials.append(ground)
    try:
        scene.view_settings.view_transform = "AgX"
    except TypeError as err:
        print("view transform:", err)

    def area(name, loc, energy, color, size):
        light = bpy.data.lights.new(name, "AREA")
        light.energy = energy
        light.color = color
        light.size = size
        obj = bpy.data.objects.new(name, light)
        obj.location = loc
        scene.collection.objects.link(obj)
        direction = Vector((0, -0.3, target_height)) - Vector(loc)
        obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

    area("Key", (1.6, -2.0, 2.4), 80, (1.0, 0.85, 0.7), 1.2)
    area("Rim", (-1.4, 1.6, 2.2), 220, (0.45, 0.75, 1.0), 0.8)
    area("Fill", (-1.8, -1.5, 1.0), 20, (0.7, 0.75, 0.9), 2.0)
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.lens = 55
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    cam.location = (1.5, -3.2, 1.55)
    cam.rotation_euler = (Vector((0, -0.3, 1.05)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    scene.render.resolution_x = 1080
    scene.render.resolution_y = 1350


