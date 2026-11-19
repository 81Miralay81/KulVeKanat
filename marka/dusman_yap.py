"""Gerçek oranlı düşman modelleri: Quaternius Universal Animation Library mankeni (CC0) üstüne
kodla giysi, zırh ve silah. Çıktı: assets/karakter/<ad>.glb (animasyonlarıyla).
Kullanım: python3 dusman_yap.py olu|haydut|sovalye|kultcu
"""
import bpy, math, sys
from mathutils import Vector

TUR = sys.argv[-1] if sys.argv[-1] in ("olu", "haydut", "sovalye", "kultcu") else "olu"
UAL = "/tmp/varlik2/gltf-universal-animation-library/glTF/AnimationLibrary_Godot_Standard.gltf"
CIKTI = "/home/claude/kulvekanat/assets/karakter/%s.glb" % {"olu": "KulOlusu", "haydut": "Haydut", "sovalye": "KaraSovalye", "kultcu": "Kultcu"}[TUR]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=UAL)
for o in list(bpy.data.objects):
    if o.name.startswith("Icosphere"):
        bpy.data.objects.remove(o, do_unlink=True)
arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
govde = [o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith("Mannequin")][0]


def malzeme(ad, renk, metal=0.0, puruz=0.7, isik=None, guc=2.0):
    m = bpy.data.materials.new(ad)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*renk, 1)
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = puruz
    if isik:
        b.inputs["Emission Color"].default_value = (*isik, 1)
        b.inputs["Emission Strength"].default_value = guc
    return m


KUL_TEN = malzeme("kul_ten", (0.16, 0.15, 0.14), 0.0, 0.85)
KUL_ACIK = malzeme("kul_acik", (0.3, 0.28, 0.26), 0.0, 0.85)
KOR = malzeme("kor", (0.9, 0.3, 0.05), 0.0, 0.5, (1.0, 0.35, 0.05), 3.0)
PACAVRA = malzeme("pacavra", (0.12, 0.1, 0.09), 0.0, 0.95)
PAS = malzeme("pas", (0.36, 0.22, 0.14), 0.6, 0.7)
TEN = malzeme("ten", (0.52, 0.34, 0.24), 0.0, 0.6)
DERI = malzeme("deri", (0.22, 0.13, 0.07), 0.0, 0.75)
DERI_ACIK = malzeme("deri_acik", (0.4, 0.26, 0.14), 0.0, 0.7)
KUMAS_KOYU = malzeme("kumas_koyu", (0.08, 0.09, 0.07), 0.0, 0.9)
KUMAS_YESIL = malzeme("kumas_yesil", (0.13, 0.17, 0.1), 0.0, 0.9)
CELIK = malzeme("celik", (0.6, 0.6, 0.62), 0.9, 0.3)
KARA_CELIK = malzeme("kara_celik", (0.12, 0.12, 0.13), 0.9, 0.35)
KIRMIZI = malzeme("kirmizi", (0.35, 0.03, 0.03), 0.0, 0.7)
BORDO = malzeme("bordo", (0.22, 0.02, 0.04), 0.0, 0.8)
SIYAH = malzeme("siyah", (0.03, 0.03, 0.03), 0.0, 0.8)
ALTIN = malzeme("altin", (0.8, 0.6, 0.22), 0.9, 0.3)
TAHTA = malzeme("tahta", (0.28, 0.17, 0.08), 0.0, 0.8)
MOR_ISIK = malzeme("mor_isik", (0.6, 0.2, 1.0), 0.0, 0.3, (0.7, 0.25, 1.0), 4.0)
GOZ_KOR = malzeme("goz_kor", (1.0, 0.45, 0.1), 0.0, 0.3, (1.0, 0.45, 0.1), 6.0)
GOZ = malzeme("goz", (0.04, 0.04, 0.05), 0.0, 0.3)


def kemik_poz(ad):
    b = arm.data.bones[ad]
    return arm.matrix_world @ b.head_local, arm.matrix_world @ b.tail_local


BOLGE = {
    "olu": {"head": KUL_TEN, "neck": KUL_TEN, "spine": KUL_TEN, "hips": PACAVRA, "shoulder": KUL_TEN, "upper_arm": KUL_ACIK,
            "forearm": KUL_TEN, "hand": KUL_TEN, "f_": KUL_TEN, "thumb": KUL_TEN, "thigh": PACAVRA, "shin": KUL_TEN, "foot": KUL_TEN, "toe": KUL_TEN},
    "haydut": {"head": TEN, "neck": TEN, "spine": KUMAS_YESIL, "hips": DERI, "shoulder": KUMAS_YESIL, "upper_arm": KUMAS_YESIL,
               "forearm": DERI_ACIK, "hand": DERI, "f_": DERI, "thumb": DERI, "thigh": KUMAS_KOYU, "shin": DERI, "foot": DERI, "toe": DERI},
    "sovalye": {"head": KARA_CELIK, "neck": KARA_CELIK, "spine": KARA_CELIK, "hips": KARA_CELIK, "shoulder": KARA_CELIK, "upper_arm": KARA_CELIK,
                "forearm": KARA_CELIK, "hand": SIYAH, "f_": SIYAH, "thumb": SIYAH, "thigh": KARA_CELIK, "shin": KARA_CELIK, "foot": KARA_CELIK, "toe": KARA_CELIK},
    "kultcu": {"head": TEN, "neck": BORDO, "spine": BORDO, "hips": BORDO, "shoulder": BORDO, "upper_arm": BORDO,
               "forearm": BORDO, "hand": TEN, "f_": TEN, "thumb": TEN, "thigh": BORDO, "shin": BORDO, "foot": SIYAH, "toe": SIYAH},
}[TUR]
govde.data.materials.clear()
mlist = []
for m in set(BOLGE.values()):
    govde.data.materials.append(m)
    mlist.append(m.name)
grup_ad = {g.index: g.name for g in govde.vertex_groups}


def bolge_malz(kemik):
    k = kemik.replace("DEF-", "")
    for anahtar, m in BOLGE.items():
        if k.startswith(anahtar):
            return m
    return list(BOLGE.values())[0]


me = govde.data
for poly in me.polygons:
    oy = {}
    for vi in poly.vertices:
        for g in me.vertices[vi].groups:
            oy[g.group] = oy.get(g.group, 0) + g.weight
    if oy:
        en = max(oy, key=oy.get)
        poly.material_index = mlist.index(bolge_malz(grup_ad.get(en, "")).name)

parcalar = []


def bagla(obj, kemik):
    mw = obj.matrix_world.copy()
    obj.parent = arm
    obj.parent_type = "BONE"
    obj.parent_bone = kemik
    obj.matrix_world = mw
    parcalar.append(obj)
    return obj


def kure(ad, merkez, olcek, malz, kemik, seg=18):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2, location=merkez)
    o = bpy.context.object
    o.name = ad
    o.scale = olcek
    o.data.materials.append(malz)
    bpy.ops.object.transform_apply(scale=True)
    bpy.ops.object.shade_smooth()
    return bagla(o, kemik)


def kutu(ad, merkez, boyut, malz, kemik, don=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=merkez, rotation=don)
    o = bpy.context.object
    o.name = ad
    o.scale = (boyut[0] / 2, boyut[1] / 2, boyut[2] / 2)
    o.data.materials.append(malz)
    bpy.ops.object.transform_apply(scale=True)
    return bagla(o, kemik)


def silindir(ad, merkez, r, boy, malz, kemik, don=(0, 0, 0), seg=14, r2=None):
    bpy.ops.mesh.primitive_cone_add(vertices=seg, radius1=r, radius2=r2 if r2 is not None else r, depth=boy, location=merkez, rotation=don)
    o = bpy.context.object
    o.name = ad
    o.data.materials.append(malz)
    bpy.ops.object.shade_smooth()
    return bagla(o, kemik)


def kol_boyunca(ad, kemik, r, bas=0.1, son=0.9, malz=None, adet=1, aralik=0.0):
    h, t = kemik_poz(kemik)
    yon = (t - h)
    boy = yon.length
    rot = yon.to_track_quat("Z", "Y").to_euler()
    for i in range(adet):
        u = bas + (son - bas) * (i + 0.5) / adet
        silindir(f"{ad}{i}", h + yon * u, r * (1.0 - 0.06 * i), boy * (son - bas) / adet - aralik, malz, kemik, rot)


def etek(kemik, malz, adet, r, boy, renk2=None):
    kh, _ = kemik_poz(kemik)
    for i in range(adet):
        a = math.tau * i / adet
        p = kh + Vector((math.sin(a) * r, -math.cos(a) * r * 0.82, -boy * 0.45))
        kutu(f"etek{i}", p, (r * 0.55, 0.012, boy * (0.8 + 0.4 * ((i * 7) % 5) / 5)), renk2 if renk2 and i % 2 else malz, kemik,
             (math.radians(6) * math.cos(a), math.radians(-6) * math.sin(a), -a))


def pelerin(malz, gen, boy, kemik="DEF-spine.003"):
    gh, _ = kemik_poz(kemik)
    bpy.ops.mesh.primitive_plane_add(size=1, location=gh + Vector((0, 0.13, -boy * 0.45)))
    o = bpy.context.object
    o.name = "pelerin"
    o.scale = (gen, 1, boy)
    o.rotation_euler = (math.radians(93), 0, 0)
    o.data.materials.append(malz)
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    bagla(o, kemik)


## Elde silah: el kemiğinin ucundan aşağı (kabza elde)
el_h, el_t = kemik_poz("DEF-hand.R")
el = el_t + (el_t - el_h).normalized() * 0.02
asagi = Vector((0, 0, -1))


def kilic(uzun=0.75, gen=0.05, malz=CELIK, kabza=DERI):
    silindir("kabza", el + Vector((0, 0, 0.02)), 0.017, 0.16, kabza, "DEF-hand.R", (0, 0, 0), 8)
    kutu("koruma", el + Vector((0, 0, -0.07)), (0.18, 0.035, 0.03), malz, "DEF-hand.R")
    kutu("bicak", el + Vector((0, 0, -0.07 - uzun / 2)), (gen, 0.012, uzun), malz, "DEF-hand.R")
    silindir("uc", el + Vector((0, 0, -0.07 - uzun - 0.035)), gen / 2, 0.07, malz, "DEF-hand.R", (math.pi, 0, 0), 4, 0.0)


bas_h, bas_t = kemik_poz("DEF-head")
bas_merkez = bas_h + Vector((0, -0.01, 0.10))
gh, gt = kemik_poz("DEF-spine.003")
kh, kt = kemik_poz("DEF-hips")

# ================================================================== KÜL ÖLÜSÜ (iskelet yerine)
if TUR == "olu":
    for s in (-1, 1):
        kure(f"goz{s}", bas_merkez + Vector((s * 0.035, -0.093, 0.015)), (0.014, 0.006, 0.01), GOZ_KOR, "DEF-head", 10)
    # göğüste ve kollarda kor çatlakları
    for i, (x, z) in enumerate([(-0.05, 0.05), (0.06, -0.02), (0.0, -0.1), (-0.07, -0.12)]):
        kutu(f"catlak{i}", gh + Vector((x, -0.125, z)), (0.06, 0.006, 0.012), KOR, "DEF-spine.003", (0, 0.5 * (i - 1.5), 0))
    kol_boyunca("catlak_kol", "DEF-forearm.L", 0.044, 0.3, 0.42, KOR, 1)
    etek("DEF-hips", PACAVRA, 10, 0.16, 0.3, KUL_ACIK)
    pelerin(PACAVRA, 0.32, 0.5)
    kutu("omuz_pacavra", gh + Vector((0.12, 0, 0.12)), (0.12, 0.14, 0.04), PACAVRA, "DEF-spine.003", (0, 0.3, 0))
    kilic(0.62, 0.05, PAS, PACAVRA)

# ================================================================== HAYDUT
elif TUR == "haydut":
    for s in (-1, 1):
        kure(f"goz{s}", bas_merkez + Vector((s * 0.035, -0.095, 0.015)), (0.009, 0.004, 0.009), GOZ, "DEF-head", 10)
    kure("kukuleta", bas_merkez + Vector((0, 0.01, 0.02)), (0.13, 0.135, 0.135), KUMAS_KOYU, "DEF-head", 20)
    kutu("maske", bas_merkez + Vector((0, -0.1, -0.04)), (0.15, 0.03, 0.08), KUMAS_KOYU, "DEF-head")
    kure("yelek", gh + Vector((0, -0.01, -0.05)), (0.17, 0.13, 0.2), DERI, "DEF-spine.003", 16)
    for s in (-1, 1):
        kutu(f"kayis{s}", gh + Vector((0, -0.12, -0.02)), (0.04, 0.02, 0.45), DERI_ACIK, "DEF-spine.003", (0, s * 0.5, 0))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.15, minor_radius=0.022, location=kh + Vector((0, 0, 0.04)))
    o = bpy.context.object
    o.name = "kemer"
    o.scale = (1.0, 0.82, 1.0)
    o.data.materials.append(DERI_ACIK)
    bagla(o, "DEF-hips")
    pelerin(KUMAS_KOYU, 0.36, 0.6)
    for s in ("L", "R"):
        kol_boyunca(f"bileklik{s}", f"DEF-forearm.{s}", 0.047, 0.45, 0.95, DERI, 1)
        kol_boyunca(f"cizme{s}", f"DEF-shin.{s}", 0.058, 0.35, 1.0, DERI, 1)
    kilic(0.42, 0.04, CELIK, DERI)

# ================================================================== KARA ŞÖVALYE (muhafız)
elif TUR == "sovalye":
    kure("migfer", bas_merkez + Vector((0, 0, 0.01)), (0.13, 0.135, 0.14), KARA_CELIK, "DEF-head", 22)
    kutu("siperlik", bas_merkez + Vector((0, -0.11, 0.0)), (0.16, 0.03, 0.06), KARA_CELIK, "DEF-head")
    kutu("goz_yarigi", bas_merkez + Vector((0, -0.125, 0.015)), (0.12, 0.01, 0.012), GOZ_KOR, "DEF-head")
    for i in range(7):
        a = math.radians(-60 + i * 20)
        kutu(f"tepe{i}", bas_merkez + Vector((0, math.sin(a) * 0.14, 0.03 + math.cos(a) * 0.15)), (0.02, 0.05, 0.05), KIRMIZI, "DEF-head", (a, 0, 0))
    for s, k in ((1, "DEF-upper_arm.R"), (-1, "DEF-upper_arm.L")):
        sh, _ = kemik_poz(k)
        kure(f"omuzluk{s}", sh + Vector((s * 0.03, 0, 0.04)), (0.12, 0.11, 0.08), KARA_CELIK, k, 16)
    kure("gogus", gh + Vector((0, -0.02, -0.04)), (0.19, 0.15, 0.22), KARA_CELIK, "DEF-spine.003", 18)
    kutu("tabard", gh + Vector((0, -0.15, -0.35)), (0.2, 0.012, 0.6), KIRMIZI, "DEF-spine.003")
    kutu("arma", gh + Vector((0, -0.16, -0.08)), (0.07, 0.01, 0.09), ALTIN, "DEF-spine.003")
    etek("DEF-hips", KARA_CELIK, 8, 0.17, 0.22)
    for s in ("L", "R"):
        kol_boyunca(f"kol_ust{s}", f"DEF-upper_arm.{s}", 0.06, 0.15, 0.95, KARA_CELIK, 3, 0.005)
        kol_boyunca(f"kol_alt{s}", f"DEF-forearm.{s}", 0.052, 0.1, 0.95, KARA_CELIK, 3, 0.005)
        kol_boyunca(f"bacak{s}", f"DEF-thigh.{s}", 0.075, 0.2, 0.95, KARA_CELIK, 2, 0.005)
        kol_boyunca(f"tozluk{s}", f"DEF-shin.{s}", 0.062, 0.1, 0.95, KARA_CELIK, 2, 0.005)
    pelerin(KIRMIZI, 0.42, 0.75)
    # iki elli savaş baltası
    silindir("sap", el + Vector((0, 0, -0.25)), 0.02, 1.0, TAHTA, "DEF-hand.R", (0, 0, 0), 8)
    kutu("balta", el + Vector((0.1, 0, -0.68)), (0.2, 0.02, 0.22), CELIK, "DEF-hand.R")
    kutu("balta2", el + Vector((-0.07, 0, -0.68)), (0.12, 0.02, 0.12), CELIK, "DEF-hand.R")

# ================================================================== KÜLTÇÜ (büyücü)
else:
    for s in (-1, 1):
        kure(f"goz{s}", bas_merkez + Vector((s * 0.035, -0.093, 0.015)), (0.012, 0.005, 0.01), MOR_ISIK, "DEF-head", 10)
    kure("kukuleta", bas_merkez + Vector((0, 0.01, 0.03)), (0.135, 0.14, 0.15), BORDO, "DEF-head", 20)
    silindir("kukuleta_uc", bas_merkez + Vector((0, 0.06, 0.13)), 0.06, 0.12, BORDO, "DEF-head", (math.radians(-35), 0, 0), 12, 0.0)
    kutu("yuz_golge", bas_merkez + Vector((0, -0.105, 0.0)), (0.13, 0.01, 0.14), SIYAH, "DEF-head")
    silindir("cuppe_etek", kh + Vector((0, 0.0, -0.38)), 0.17, 0.85, BORDO, "DEF-hips", (0, 0, 0), 20, 0.32)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.16, minor_radius=0.02, location=kh + Vector((0, 0, 0.06)))
    o = bpy.context.object
    o.name = "kusak"
    o.scale = (1.0, 0.82, 1.0)
    o.data.materials.append(SIYAH)
    bagla(o, "DEF-hips")
    for s in ("L", "R"):
        kol_boyunca(f"yen{s}", f"DEF-forearm.{s}", 0.066, 0.45, 1.0, BORDO, 1)
    kure("kolye", gh + Vector((0, -0.12, 0.0)), (0.03, 0.012, 0.035), MOR_ISIK, "DEF-spine.003", 12)
    pelerin(SIYAH, 0.42, 0.85)
    silindir("asa", el + Vector((0, 0, -0.1)), 0.018, 1.5, TAHTA, "DEF-hand.R", (0, 0, 0), 8)
    kure("asa_tas", el + Vector((0, 0, 0.68)), (0.05, 0.05, 0.06), MOR_ISIK, "DEF-hand.R", 12)

bpy.ops.object.select_all(action="DESELECT")
for o in [arm, govde] + parcalar:
    o.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.gltf(filepath=CIKTI, export_format="GLB", use_selection=True, export_animations=True,
                          export_animation_mode="ACTIONS", export_yup=True)
print("TAMAM", CIKTI, len(parcalar))
