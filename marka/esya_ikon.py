"""Gerçekçi eşya resimleri: Blender Cycles ile kodla modellenmiş silah, zırh, kask, eldiven, çizme,
yüzük, kanat, mana taşı ve Eliksir. Çıktı: assets/esya_ikon/*.png (256x256, saydam arka plan).
Kullanım: python3 esya_ikon.py [filtre]
"""
import bpy, math, sys, os
from mathutils import Vector

CIKTI = "/home/claude/kulvekanat/assets/esya_ikon/"
os.makedirs(CIKTI, exist_ok=True)
FILTRE = sys.argv[-1] if len(sys.argv) > 1 and not sys.argv[-1].endswith(".py") else ""

# kademe malzemeleri: [metal rengi, pürüz, vurgu rengi, vurgu ışığı, deri/kumaş rengi]
KADEME = [
    ((0.42, 0.40, 0.38), 0.55, (0.35, 0.22, 0.12), None, (0.25, 0.15, 0.08)),          # demir
    ((0.78, 0.78, 0.80), 0.28, (0.55, 0.12, 0.10), None, (0.30, 0.18, 0.09)),          # çelik
    ((0.70, 0.80, 0.92), 0.22, (0.35, 0.75, 1.00), (0.3, 0.7, 1.0), (0.18, 0.24, 0.38)), # ayaz
    ((0.18, 0.15, 0.14), 0.35, (1.00, 0.40, 0.08), (1.0, 0.35, 0.05), (0.30, 0.06, 0.04)), # kor
    ((0.95, 0.80, 0.45), 0.2, (0.75, 0.35, 1.00), (0.7, 0.3, 1.0), (0.92, 0.9, 0.86)),   # son kanatlı
]


def temizle():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    s = bpy.context.scene
    s.render.engine = "CYCLES"
    s.cycles.device = "CPU"
    s.cycles.samples = 48
    s.cycles.use_denoising = True
    s.render.resolution_x = 256
    s.render.resolution_y = 256
    s.render.film_transparent = True
    s.render.image_settings.file_format = "PNG"
    s.render.image_settings.color_mode = "RGBA"
    s.view_settings.view_transform = "AgX"
    s.view_settings.look = "AgX - Medium High Contrast"
    w = bpy.data.worlds.new("dunya")
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.18, 0.17, 0.16, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 0.6
    s.world = w
    # üç nokta ışık
    for ad, poz, guc, renk, boy in (("ana", (2.5, -3, 4), 900, (1, 0.95, 0.88), 2.5), ("dolgu", (-3.5, -2, 1.5), 250, (0.75, 0.82, 1.0), 3),
                                    ("arka", (0, 4, 3), 700, (1, 0.9, 0.8), 1.5)):
        l = bpy.data.lights.new(ad, "AREA")
        l.energy = guc
        l.color = renk
        l.size = boy
        o = bpy.data.objects.new(ad, l)
        o.location = poz
        s.collection.objects.link(o)
        o.rotation_euler = (Vector((0, 0, 0)) - Vector(poz)).to_track_quat("-Z", "Y").to_euler()
    cam = bpy.data.cameras.new("kam")
    cam.lens = 85
    co = bpy.data.objects.new("kam", cam)
    s.collection.objects.link(co)
    s.camera = co
    return co


def malz(ad, renk, metal=0.0, puruz=0.5, isik=None, guc=4.0, cizik=0.0, doku=None):
    m = bpy.data.materials.new(ad)
    m.use_nodes = True
    n = m.node_tree.nodes
    l = m.node_tree.links
    b = n["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*renk, 1)
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = puruz
    if isik:
        b.inputs["Emission Color"].default_value = (*isik, 1)
        b.inputs["Emission Strength"].default_value = guc
    if cizik > 0 or doku:
        tc = n.new("ShaderNodeTexCoord")
        g = n.new("ShaderNodeTexNoise")
        g.inputs["Scale"].default_value = 18.0 if doku != "ahsap" else 6.0
        g.inputs["Detail"].default_value = 10.0
        if doku == "ahsap":
            mp = n.new("ShaderNodeMapping")
            mp.inputs["Scale"].default_value = (1, 1, 14)
            l.new(tc.outputs["Object"], mp.inputs["Vector"])
            l.new(mp.outputs["Vector"], g.inputs["Vector"])
        else:
            l.new(tc.outputs["Object"], g.inputs["Vector"])
        r = n.new("ShaderNodeMapRange")
        r.inputs["To Min"].default_value = puruz - cizik * 0.25
        r.inputs["To Max"].default_value = puruz + cizik * 0.35
        l.new(g.outputs["Fac"], r.inputs["Value"])
        l.new(r.outputs["Result"], b.inputs["Roughness"])
        bm = n.new("ShaderNodeBump")
        bm.inputs["Strength"].default_value = 0.25 if doku != "kumas" else 0.5
        l.new(g.outputs["Fac"], bm.inputs["Height"])
        l.new(bm.outputs["Normal"], b.inputs["Normal"])
        if doku in ("ahsap", "deri", "kumas"):
            cr = n.new("ShaderNodeMixRGB")
            cr.blend_type = "MULTIPLY"
            cr.inputs["Fac"].default_value = 0.5
            cr.inputs["Color1"].default_value = (*renk, 1)
            l.new(g.outputs["Color"], cr.inputs["Color2"])
            l.new(cr.outputs["Color"], b.inputs["Base Color"])
    return m


def ekle(o, m, yumusak=True, bevel=0.0, alt=0):
    o.data.materials.append(m)
    if bevel > 0:
        md = o.modifiers.new("b", "BEVEL")
        md.width = bevel
        md.segments = 2
    if alt > 0:
        md = o.modifiers.new("s", "SUBSURF")
        md.levels = alt
        md.render_levels = alt
    if yumusak:
        for p in o.data.polygons:
            p.use_smooth = True
    return o


def kutu(boyut, poz, m, don=(0, 0, 0), bevel=0.01, alt=0):
    bpy.ops.mesh.primitive_cube_add(location=poz, rotation=don)
    o = bpy.context.object
    o.scale = (boyut[0] / 2, boyut[1] / 2, boyut[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    return ekle(o, m, alt > 0, bevel, alt)


def silindir(r, boy, poz, m, don=(0, 0, 0), r2=None, seg=32, bevel=0.0):
    bpy.ops.mesh.primitive_cone_add(vertices=seg, radius1=r, radius2=r if r2 is None else r2, depth=boy, location=poz, rotation=don)
    return ekle(bpy.context.object, m, True, bevel)


def kure(r, poz, m, olcek=(1, 1, 1), seg=32):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2, radius=r, location=poz)
    o = bpy.context.object
    o.scale = olcek
    bpy.ops.object.transform_apply(scale=True)
    return ekle(o, m)


def halka(R, r, poz, m, don=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, location=poz, rotation=don, major_segments=48, minor_segments=16)
    return ekle(bpy.context.object, m)


def tas_kristal(r, poz, m, uzun=1.6):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=r, location=poz)
    o = bpy.context.object
    o.scale = (1, 1, uzun)
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(m)
    return o


def grupla(objeler, don):
    bpy.ops.object.empty_add(location=(0, 0, 0))
    e = bpy.context.object
    for ob in objeler:
        ob.parent = e
    e.rotation_euler = don
    return objeler


def cerceve(co, objeler, aci=(62, 0, 28), pay=0.86):
    # tüm nesneleri kapsayan küre: kamerayı ona göre yerleştir
    pts = []
    bpy.context.view_layer.update()
    for o in objeler:
        for c in o.bound_box:
            pts.append(o.matrix_world @ Vector(c))
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    mer = (mn + mx) / 2
    r = (mx - mn).length / 2
    a = [math.radians(x) for x in aci]
    yon = Vector((math.sin(a[2]) * math.sin(a[0]), -math.cos(a[2]) * math.sin(a[0]), math.cos(a[0])))
    mesafe = r * pay / math.tan(math.radians(12.0))
    co.location = mer + yon * mesafe
    co.rotation_euler = (mer - co.location).to_track_quat("-Z", "Y").to_euler()
    co.data.clip_end = mesafe * 3


def kaydet(ad):
    bpy.context.scene.render.filepath = CIKTI + ad + ".png"
    bpy.ops.render.render(write_still=True)
    print("IKON", ad)


# ------------------------------------------------------------------ modeller
def malzemeler(k):
    metal_r, pur, vurgu, isik, deri = KADEME[k]
    return {
        "metal": malz("metal", metal_r, 1.0, pur, cizik=0.6),
        "vurgu": malz("vurgu", vurgu, 0.9 if not isik else 0.2, 0.3, isik, 6.0),
        "deri": malz("deri", deri, 0.0, 0.6, doku="deri", cizik=0.4),
        "ahsap": malz("ahsap", (0.35, 0.2, 0.09) if k != 3 else (0.12, 0.08, 0.06), 0.0, 0.55, doku="ahsap", cizik=0.3),
        "kumas": malz("kumas", deri, 0.0, 0.85, doku="kumas", cizik=0.2),
        "altin": malz("altin", (0.85, 0.62, 0.25), 1.0, 0.25, cizik=0.3),
    }


def kilic(M, k):
    o = []
    uz = 1.5 + k * 0.08
    gen = 0.11 + (0.03 if k >= 3 else 0)
    o.append(kutu((gen, 0.025, uz), (0, 0, uz / 2 + 0.05), M["metal"], bevel=0.008))
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=gen * 0.71, radius2=0, depth=0.22, location=(0, 0, uz + 0.16), rotation=(0, 0, math.pi / 4))
    uc = bpy.context.object
    uc.scale = (1, 0.18, 1)
    o.append(ekle(uc, M["metal"], False))
    o.append(kutu((0.018, 0.03, uz * 0.75), (0, 0, uz * 0.42), M["vurgu"] if k >= 2 else M["metal"], bevel=0.004))
    o.append(kutu((0.42 + k * 0.03, 0.06, 0.06), (0, 0, 0.03), M["altin"] if k in (1, 4) else M["metal"], bevel=0.015))
    o.append(silindir(0.032, 0.34, (0, 0, -0.17), M["deri"]))
    o.append(kure(0.055, (0, 0, -0.36), M["vurgu"] if k >= 2 else M["altin"]))
    return grupla(o, (0, math.radians(-40), 0))


def yay(M, k):
    o = []
    bpy.ops.curve.primitive_bezier_curve_add()
    c = bpy.context.object
    sp = c.data.splines[0]
    sp.bezier_points[0].co = (0, 0, -1.0)
    sp.bezier_points[0].handle_left = (0.0, 0, -1.2)
    sp.bezier_points[0].handle_right = (-0.55 - k * 0.05, 0, -0.5)
    sp.bezier_points[1].co = (0, 0, 1.0)
    sp.bezier_points[1].handle_left = (-0.55 - k * 0.05, 0, 0.5)
    sp.bezier_points[1].handle_right = (0.0, 0, 1.2)
    c.data.bevel_depth = 0.035
    c.data.bevel_resolution = 4
    c.data.resolution_u = 32
    c.data.materials.append(M["ahsap"] if k < 2 else M["metal"])
    o.append(c)
    o.append(silindir(0.006, 2.0, (0.02, 0, 0), malz("ip", (0.9, 0.88, 0.8), 0.0, 0.6)))
    o.append(silindir(0.05, 0.3, (-0.36 - k * 0.03, 0, 0), M["deri"]))
    for z in (-0.95, 0.95):
        o.append(kure(0.045, (0.0, 0, z), M["vurgu"] if k >= 2 else M["metal"]))
    return grupla(o, (0, math.radians(-35), 0))


def asa(M, k):
    o = [silindir(0.04, 2.0, (0, 0, 0), M["ahsap"], r2=0.03)]
    o.append(halka(0.06, 0.018, (0, 0, 0.82), M["altin"] if k != 3 else M["metal"]))
    for i in range(3 if k >= 1 else 0):
        a = math.tau * i / 3
        o.append(silindir(0.015, 0.35, (math.cos(a) * 0.08, math.sin(a) * 0.08, 1.05), M["altin"] if k != 3 else M["metal"], (math.sin(a) * 0.4, -math.cos(a) * 0.4, 0)))
    tm = malz("tas", KADEME[k][2] if k >= 1 else (0.3, 0.6, 1.0), 0.0, 0.05, KADEME[k][3] or (0.3, 0.6, 1.0), 5.0)
    o.append(kure(0.12 + k * 0.012, (0, 0, 1.18), tm))
    return grupla(o, (0, math.radians(-35), 0))


def zirh(M, k, sinif):
    o = []
    if sinif == "muhafiz":
        o.append(kure(0.5, (0, 0, 0), M["metal"], (1.0, 0.62, 1.15)))
        o.append(kutu((0.9, 0.5, 0.06), (0, -0.05, -0.62), M["metal"], bevel=0.02))
        for s in (-1, 1):
            o.append(kure(0.3, (s * 0.46, 0, 0.36), M["metal"], (1.0, 0.95, 0.5)))
        o.append(silindir(0.2, 0.12, (0, 0, 0.62), M["metal"], r2=0.17))
        o.append(kutu((0.08, 0.03, 0.8), (0, -0.33, 0.05), M["vurgu"] if k >= 2 else M["altin"], bevel=0.01))
    elif sinif == "avci":
        o.append(kure(0.5, (0, 0, 0), M["deri"], (0.95, 0.6, 1.15)))
        for s in (-1, 1):
            o.append(kutu((0.08, 0.04, 1.1), (s * 0.18, -0.3, 0), M["kumas"] if k < 2 else M["metal"], (0, s * 0.35, 0), bevel=0.01))
        o.append(halka(0.42, 0.04, (0, 0, -0.45), M["deri"], (0, 0, 0)))
        o.append(kure(0.05, (0, -0.32, 0.1), M["vurgu"]))
    else:
        o.append(silindir(0.42, 1.5, (0, 0, -0.2), M["kumas"], r2=0.28))
        o.append(kure(0.45, (0, 0, 0.5), M["kumas"], (1.15, 0.75, 0.38)))
        o.append(silindir(0.3, 0.12, (0, 0, 0.6), M["altin"] if k != 3 else M["metal"], r2=0.22))
        o.append(kure(0.06, (0, -0.3, 0.45), M["vurgu"]))
        o.append(halka(0.36, 0.03, (0, 0, 0.0), M["altin"] if k != 3 else M["vurgu"]))
    return o


def kask(M, k, sinif):
    o = []
    if sinif == "muhafiz":
        o.append(kure(0.5, (0, 0, 0), M["metal"], (0.95, 1.0, 1.05)))
        o.append(kutu((0.72, 0.1, 0.42), (0, -0.44, -0.18), M["metal"], bevel=0.03))
        o.append(kutu((0.55, 0.05, 0.05), (0, -0.5, -0.05), malz("yarik", (0.01, 0.01, 0.01), 0, 0.9)))
        for i in range(7):
            a = math.radians(-60 + i * 20)
            o.append(kutu((0.05, 0.16, 0.15), (0, math.sin(a) * 0.5, 0.05 + math.cos(a) * 0.52), M["vurgu"] if k >= 2 else malz("tepe", (0.5, 0.05, 0.04), 0, 0.8), (a, 0, 0)))
    elif sinif == "avci":
        o.append(kure(0.5, (0, 0.05, 0), M["kumas"], (0.95, 1.05, 1.1)))
        bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=0.25, radius2=0, depth=0.6, location=(0, 0.45, 0.25), rotation=(math.radians(-60), 0, 0))
        o.append(ekle(bpy.context.object, M["kumas"]))
        o.append(kure(0.42, (0, -0.3, -0.06), malz("ic", (0.015, 0.012, 0.01), 0, 0.95), (0.62, 0.45, 0.78)))
        o.append(halka(0.27, 0.035, (0, -0.4, -0.06), M["kumas"], (math.radians(90), 0, 0)))
        if k >= 2:
            o.append(halka(0.47, 0.025, (0, 0, 0.12), M["vurgu"], (math.radians(10), 0, 0)))
    else:
        o.append(halka(0.42, 0.05, (0, 0, 0), M["altin"] if k != 3 else M["metal"]))
        for i in range(5):
            a = math.radians(-60 + i * 30)
            boy = 0.22 if i != 2 else 0.4
            o.append(silindir(0.045, boy, (math.sin(a) * 0.42, -math.cos(a) * 0.42, boy / 2), M["altin"] if k != 3 else M["metal"], r2=0.0))
        o.append(kure(0.08, (0, -0.45, 0.06), malz("tas", KADEME[k][2], 0, 0.05, KADEME[k][3] or KADEME[k][2], 4.0)))
    return o


def eldiven(M, k, sinif):
    ana = M["metal"] if sinif == "muhafiz" else (M["deri"] if sinif == "avci" else M["kumas"])
    o = [kutu((0.42, 0.18, 0.45), (0, 0, 0), ana, bevel=0.05, alt=1)]
    for i in range(4):
        o.append(kutu((0.085, 0.13, 0.32), (-0.15 + i * 0.1, 0, 0.36), ana, bevel=0.03, alt=1))
    o.append(kutu((0.1, 0.12, 0.25), (0.27, 0, 0.12), ana, (0, math.radians(-35), 0), bevel=0.03, alt=1))
    o.append(silindir(0.26, 0.35, (0, 0, -0.38), M["deri"] if sinif != "muhafiz" else M["metal"], r2=0.22))
    o.append(halka(0.25, 0.025, (0, 0, -0.22), M["vurgu"] if k >= 2 else M["altin"]))
    return grupla(o, (0, math.radians(15), math.radians(-20)))


def cizme(M, k, sinif):
    ana = M["metal"] if sinif == "muhafiz" else (M["deri"])
    o = [silindir(0.2, 0.7, (0, 0, 0.35), ana, r2=0.22)]
    o.append(kutu((0.3, 0.6, 0.2), (0, -0.2, -0.05), ana, bevel=0.06, alt=1))
    o.append(kutu((0.32, 0.62, 0.05), (0, -0.2, -0.16), malz("taban", (0.06, 0.05, 0.04), 0, 0.8), bevel=0.02))
    o.append(halka(0.215, 0.03, (0, 0, 0.66), M["vurgu"] if k >= 2 else M["altin"] if k in (1, 4) else M["deri"]))
    if sinif == "muhafiz":
        o.append(kure(0.2, (0, -0.1, 0.25), M["metal"], (1, 0.6, 1.3)))
    return grupla(o, (0, 0, math.radians(30)))


def yuzuk(M, k):
    o = [halka(0.4, 0.07, (0, 0, 0), M["altin"] if k != 0 else malz("bakir", (0.75, 0.4, 0.25), 1.0, 0.3, cizik=0.4), (math.radians(75), 0, 0))]
    tas = [(0.2, 0.3, 0.9), (0.85, 0.85, 0.9), (0.15, 0.3, 1.0), (0.9, 0.08, 0.1), (0.7, 0.3, 1.0)][k]
    o.append(tas_kristal(0.16, (0, -0.1, 0.42), malz("tas", tas, 0.0, 0.02, tas if k >= 2 else None, 2.0), 1.0))
    o.append(silindir(0.13, 0.08, (0, -0.08, 0.33), M["altin"], (math.radians(-15), 0, 0)))
    return o


def kanat(M, k):
    o = []
    tuy = malz("tuy", [(0.85, 0.82, 0.78), (0.95, 0.95, 0.95), (0.7, 0.85, 1.0), (0.9, 0.35, 0.1), (1.0, 0.95, 0.8)][k], 0.0, 0.6,
               KADEME[k][3] if k >= 2 else None, 2.5)
    for s in (-1, 1):
        for i in range(7):
            a = math.radians(20 + i * 14)
            uz = 1.0 - i * 0.08
            bpy.ops.mesh.primitive_plane_add(size=1, location=(s * (0.15 + math.cos(a) * uz * 0.5), 0, math.sin(a) * uz * 0.5))
            p = bpy.context.object
            p.scale = (uz, 0.16, 1)
            p.rotation_euler = (math.radians(90), -s * a, 0)
            bpy.ops.object.transform_apply(scale=True)
            md = p.modifiers.new("k", "SOLIDIFY")
            md.thickness = 0.01
            o.append(ekle(p, tuy, False))
    o.append(kure(0.1, (0, 0, 0.05), M["vurgu"] if k >= 2 else M["altin"]))
    return o


def mana_tasi(tur):
    renk = {"hasar": (0.9, 0.1, 0.08), "can": (0.15, 0.85, 0.25), "kritik": (1.0, 0.8, 0.1), "hiz": (0.1, 0.9, 0.9),
            "zirh": (0.6, 0.65, 0.75), "mana": (0.25, 0.35, 1.0)}[tur]
    m = malz("tas", renk, 0.0, 0.03, renk, 1.6)
    m.node_tree.nodes["Principled BSDF"].inputs["Transmission Weight"].default_value = 0.0
    m.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 0.12
    m.node_tree.nodes["Principled BSDF"].inputs["Coat Weight"].default_value = 1.0
    o = [tas_kristal(0.45, (0, 0, 0), m, 1.7)]
    o.append(tas_kristal(0.22, (0.38, 0.1, -0.35), m, 1.5))
    o.append(tas_kristal(0.18, (-0.33, -0.05, -0.4), m, 1.4))
    return o


def eliksir():
    cam = malz("cam", (0.9, 0.95, 1.0), 0.0, 0.02)
    cam.node_tree.nodes["Principled BSDF"].inputs["Transmission Weight"].default_value = 1.0
    sivi = malz("sivi", (0.1, 0.9, 0.7), 0.0, 0.1, (0.15, 1.0, 0.75), 3.0)
    o = [kure(0.42, (0, 0, -0.1), cam), silindir(0.1, 0.45, (0, 0, 0.45), cam)]
    o.append(kure(0.38, (0, 0, -0.14), sivi, (1, 1, 0.8)))
    o.append(silindir(0.12, 0.14, (0, 0, 0.72), malz("mantar", (0.45, 0.3, 0.15), 0, 0.8, doku="ahsap")))
    o.append(halka(0.11, 0.025, (0, 0, 0.56), malz("altin", (0.85, 0.62, 0.25), 1.0, 0.25)))
    return o


# ------------------------------------------------------------------ işler
if __name__ == "__main__":
    isler = []
    for sinif in ("muhafiz", "avci", "buyucu"):
        for k in range(5):
            isler.append((f"{sinif}_silah_{k}", sinif, "silah", k))
            isler.append((f"{sinif}_zirh_{k}", sinif, "zirh", k))
            isler.append((f"{sinif}_kask_{k}", sinif, "kask", k))
            isler.append((f"{sinif}_eldiven_{k}", sinif, "eldiven", k))
            isler.append((f"{sinif}_cizme_{k}", sinif, "cizme", k))
    for k in range(5):
        isler.append((f"ortak_yuzuk_{k}", "", "yuzuk", k))
        isler.append((f"ortak_kanat_{k}", "", "kanat", k))
    for t in ("hasar", "can", "kritik", "hiz", "zirh", "mana"):
        isler.append((f"tas_{t}", "", "tas", t))
    isler.append(("eliksir", "", "eliksir", 0))

    for ad, sinif, tur, k in isler:
        if FILTRE and FILTRE not in ad:
            continue
        co = temizle()
        M = malzemeler(k) if isinstance(k, int) else {}
        aci = (62, 0, 28)
        if tur == "silah":
            obj = {"muhafiz": kilic, "avci": yay, "buyucu": asa}[sinif](M, k)
            aci = (88, 0, 0)
        elif tur == "zirh":
            obj = zirh(M, k, sinif)
            aci = (78, 0, 20)
        elif tur == "kask":
            obj = kask(M, k, sinif)
            aci = (75, 0, 35)
        elif tur == "eldiven":
            obj = eldiven(M, k, sinif)
            aci = (80, 0, 15)
        elif tur == "cizme":
            obj = cizme(M, k, sinif)
            aci = (75, 0, 40)
        elif tur == "yuzuk":
            obj = yuzuk(M, k)
            aci = (70, 0, 20)
        elif tur == "kanat":
            obj = kanat(M, k)
            aci = (88, 0, 0)
        elif tur == "tas":
            obj = mana_tasi(k)
        else:
            obj = eliksir()
            aci = (80, 0, 10)
        cerceve(co, obj, aci)
        kaydet(ad)
