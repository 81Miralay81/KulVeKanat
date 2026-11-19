"""Gerçek oranlı kahraman modelleri: Quaternius Universal Animation Library mankeni (CC0)
üstüne kodla zırh, miğfer, pelerin, saç, yüz. Çıktı: assets/karakter/<ad>.glb (animasyonlarıyla).
Kullanım: python3 karakter_yap.py gladyator|elf|buyucu
"""
import bpy, bmesh, math, sys
from mathutils import Vector, Matrix

SINIF = sys.argv[-1] if sys.argv[-1] in ("gladyator", "elf", "buyucu") else "gladyator"
UAL = "/tmp/varlik2/gltf-universal-animation-library/glTF/AnimationLibrary_Godot_Standard.gltf"
CIKTI = "/home/claude/kulvekanat/assets/karakter/%s.glb" % {"gladyator": "Gladyator", "elf": "ElfOkcu", "buyucu": "InsanBuyucu"}[SINIF]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=UAL)
for o in list(bpy.data.objects):
    if o.name.startswith("Icosphere"):
        bpy.data.objects.remove(o, do_unlink=True)
arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
govde = [o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith("Mannequin")][0]


def malzeme(ad, renk, metal=0.0, puruz=0.7, isik=None):
    m = bpy.data.materials.new(ad)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*renk, 1)
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = puruz
    if isik:
        b.inputs["Emission Color"].default_value = (*isik, 1)
        b.inputs["Emission Strength"].default_value = 2.0
    return m


TEN = malzeme("ten", (0.50, 0.31, 0.21), 0.0, 0.6)
TEN_ELF = malzeme("ten_elf", (0.68, 0.5, 0.39), 0.0, 0.55)
DERI = malzeme("deri", (0.30, 0.17, 0.08), 0.0, 0.75)
DERI_ACIK = malzeme("deri_acik", (0.48, 0.30, 0.15), 0.0, 0.7)
METAL = malzeme("metal", (0.72, 0.70, 0.66), 0.85, 0.32)
ALTIN = malzeme("altin", (0.85, 0.62, 0.22), 0.9, 0.3)
KIRMIZI = malzeme("kirmizi", (0.40, 0.04, 0.03), 0.0, 0.65)
YESIL = malzeme("yesil", (0.12, 0.30, 0.12), 0.0, 0.7)
YESIL_KOYU = malzeme("yesil_koyu", (0.07, 0.17, 0.08), 0.0, 0.75)
MAVI = malzeme("mavi", (0.10, 0.16, 0.42), 0.0, 0.65)
MAVI_ACIK = malzeme("mavi_acik", (0.25, 0.35, 0.70), 0.0, 0.6)
GRI_KUMAS = malzeme("gri", (0.55, 0.52, 0.48), 0.0, 0.8)
SAC_SARI = malzeme("sac_sari", (0.85, 0.75, 0.45), 0.0, 0.55)
SAC_GRI = malzeme("sac_gri", (0.78, 0.78, 0.76), 0.0, 0.6)
GOZ = malzeme("goz", (0.04, 0.04, 0.05), 0.0, 0.3)
GOZ_BEYAZ = malzeme("goz_beyaz", (0.95, 0.95, 0.92), 0.0, 0.4)
DUDAK = malzeme("dudak", (0.55, 0.28, 0.24), 0.0, 0.6)


def kemik_poz(ad):
    b = arm.data.bones[ad]
    return arm.matrix_world @ b.head_local, arm.matrix_world @ b.tail_local


# ------------------------------------------------------------------ gövdeyi bölgelere göre boya
BOLGE = {
    "gladyator": {"head": TEN, "neck": TEN, "spine.003": DERI, "spine.002": DERI, "spine.001": DERI, "hips": DERI,
                  "shoulder": TEN, "upper_arm": TEN, "forearm": DERI_ACIK, "hand": TEN, "f_": TEN, "thumb": TEN,
                  "thigh": TEN, "shin": TEN, "foot": DERI, "toe": DERI},
    "elf": {"head": TEN_ELF, "neck": TEN_ELF, "spine": YESIL, "hips": DERI, "shoulder": YESIL, "upper_arm": YESIL,
            "forearm": DERI_ACIK, "hand": TEN_ELF, "f_": TEN_ELF, "thumb": TEN_ELF, "thigh": YESIL_KOYU, "shin": DERI, "foot": DERI, "toe": DERI},
    "buyucu": {"head": TEN, "neck": TEN, "spine": MAVI, "hips": MAVI, "shoulder": MAVI, "upper_arm": MAVI,
               "forearm": MAVI_ACIK, "hand": TEN, "f_": TEN, "thumb": TEN, "thigh": MAVI, "shin": MAVI, "foot": DERI, "toe": DERI},
}[SINIF]
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
        m = bolge_malz(grup_ad.get(en, ""))
        poly.material_index = mlist.index(m.name)

# ------------------------------------------------------------------ parça yardımcıları
parcalar = []


def bagla(obj, kemik):
    mw = obj.matrix_world.copy()
    obj.parent = arm
    obj.parent_type = "BONE"
    obj.parent_bone = kemik
    obj.matrix_world = mw
    parcalar.append(obj)
    return obj


def kure(ad, merkez, olcek, malz, kemik, seg=20):
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


def silindir(ad, merkez, r, boy, malz, kemik, don=(0, 0, 0), seg=16, r2=None):
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


bas_h, bas_t = kemik_poz("DEF-head")
bas_merkez = bas_h + Vector((0, -0.01, 0.10))
ileri = Vector((0, -1, 0))   # karakter -Y'ye bakıyor

# ------------------------------------------------------------------ YÜZ (gözler, kaşlar, burun) — miğfer açık olanlar için
def yuz(ten, sakal=None, kas_renk=None):
    for s in (-1, 1):
        kure(f"goz_beyaz{s}", bas_merkez + Vector((s * 0.035, -0.088, 0.015)), (0.016, 0.008, 0.012), GOZ_BEYAZ, "DEF-head", 12)
        kure(f"goz{s}", bas_merkez + Vector((s * 0.035, -0.095, 0.015)), (0.008, 0.004, 0.009), GOZ, "DEF-head", 10)
        kutu(f"kas{s}", bas_merkez + Vector((s * 0.037, -0.094, 0.038)), (0.032, 0.008, 0.008), kas_renk or DERI, "DEF-head", (0, s * 0.15, 0))
    silindir("burun", bas_merkez + Vector((0, -0.1, -0.005)), 0.012, 0.035, ten, "DEF-head", (math.radians(-70), 0, 0), 8, 0.004)
    kutu("agiz", bas_merkez + Vector((0, -0.092, -0.045)), (0.03, 0.006, 0.006), DUDAK, "DEF-head")
    if sakal:
        kure("sakal", bas_merkez + Vector((0, -0.065, -0.07)), (0.07, 0.05, 0.07), sakal, "DEF-head", 16)
        kure("biyik", bas_merkez + Vector((0, -0.095, -0.03)), (0.035, 0.012, 0.01), sakal, "DEF-head", 10)


# ================================================================== GLADYATÖR
if SINIF == "gladyator":
    # miğfer (murmillo): kubbe, geniş siper, ızgaralı yüz plakası, kırmızı tepe
    kure("migfer", bas_merkez + Vector((0, 0, 0.01)), (0.125, 0.13, 0.13), METAL, "DEF-head", 24)
    silindir("siper", bas_merkez + Vector((0, 0, -0.035)), 0.16, 0.012, METAL, "DEF-head")
    kutu("yuz_plaka", bas_merkez + Vector((0, -0.11, -0.01)), (0.15, 0.02, 0.15), METAL, "DEF-head")
    for i in range(5):
        kutu(f"izgara{i}", bas_merkez + Vector((-0.05 + i * 0.025, -0.123, 0.0)), (0.008, 0.012, 0.09), GOZ, "DEF-head")
    for i in range(9):
        a = math.radians(-70 + i * 17.5)
        p = bas_merkez + Vector((0, math.sin(a) * 0.14, 0.02 + math.cos(a) * 0.15))
        kutu(f"tepe{i}", p, (0.025, 0.05, 0.06), KIRMIZI, "DEF-head", (a, 0, 0))
    # sağ kolda manika (zırh halkaları), sol omuzda omuzluk
    kol_boyunca("manika_ust", "DEF-upper_arm.R", 0.062, 0.05, 0.95, METAL, 4, 0.006)
    kol_boyunca("manika_alt", "DEF-forearm.R", 0.052, 0.05, 0.9, METAL, 4, 0.006)
    sh, st = kemik_poz("DEF-upper_arm.L")
    kure("omuzluk", sh + Vector((0.03, 0, 0.04)), (0.11, 0.1, 0.07), METAL, "DEF-upper_arm.L", 16)
    kol_boyunca("bileklik_sol", "DEF-forearm.L", 0.05, 0.5, 0.95, DERI, 1)
    # göğüste çapraz kayışlar + madalyon
    gh, gt = kemik_poz("DEF-spine.003")
    for s in (-1, 1):
        kutu(f"kayis{s}", gh + Vector((0, -0.11, 0.0)), (0.05, 0.02, 0.5), DERI_ACIK, "DEF-spine.003", (0, s * 0.55, 0))
    kure("madalyon", gh + Vector((0, -0.125, 0.02)), (0.035, 0.012, 0.035), ALTIN, "DEF-spine.003", 14)
    # kemer ve etek (pteruges)
    kh, kt = kemik_poz("DEF-hips")
    bpy.ops.mesh.primitive_torus_add(major_radius=0.165, minor_radius=0.03, location=kh + Vector((0, 0, 0.04)))
    o = bpy.context.object
    o.name = "kemer"
    o.scale = (1.0, 0.8, 1.0)
    o.data.materials.append(DERI)
    bagla(o, "DEF-hips")
    kutu("toka", kh + Vector((0, -0.14, 0.04)), (0.07, 0.02, 0.06), ALTIN, "DEF-hips")
    for i in range(12):
        a = TAU = math.tau * i / 12
        p = kh + Vector((math.sin(a) * 0.16, -math.cos(a) * 0.13, -0.09))
        kutu(f"etek{i}", p, (0.07, 0.015, 0.2), KIRMIZI if i % 2 else DERI_ACIK, "DEF-hips", (math.radians(8) * math.cos(a), math.radians(-8) * math.sin(a), -a))
    # bacak koruyucular, sandalet bağları
    for s in ("L", "R"):
        kol_boyunca(f"tozluk{s}", f"DEF-shin.{s}", 0.06, 0.1, 0.85, METAL, 1)
    # kırmızı pelerin
    bpy.ops.mesh.primitive_plane_add(size=1, location=gh + Vector((0, 0.13, -0.22)))
    o = bpy.context.object
    o.name = "pelerin"
    o.scale = (0.36, 1, 0.6)
    o.rotation_euler = (math.radians(95), 0, 0)
    o.data.materials.append(KIRMIZI)
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    bagla(o, "DEF-spine.003")

# ================================================================== ELF OKÇU
elif SINIF == "elf":
    yuz(TEN_ELF, None, SAC_SARI)
    # saç (sarı, uzun), sivri kulaklar
    kure("sac", bas_merkez + Vector((0, 0.015, 0.025)), (0.115, 0.12, 0.115), SAC_SARI, "DEF-head", 20)
    kure("sac_arka", bas_merkez + Vector((0, 0.07, -0.1)), (0.08, 0.05, 0.16), SAC_SARI, "DEF-head", 16)
    for s in (-1, 1):
        silindir(f"kulak{s}", bas_merkez + Vector((s * 0.105, 0.0, 0.02)), 0.02, 0.09, TEN_ELF, "DEF-head", (0, math.radians(s * 70), math.radians(s * -10)), 8, 0.003)
    # başlık (kukuleta) arkaya düşmüş + yeşil pelerin
    gh, gt = kemik_poz("DEF-spine.003")
    kure("kukuleta", gh + Vector((0, 0.1, 0.17)), (0.12, 0.08, 0.09), YESIL_KOYU, "DEF-spine.003", 16)
    bpy.ops.mesh.primitive_plane_add(size=1, location=gh + Vector((0, 0.12, -0.28)))
    o = bpy.context.object
    o.name = "pelerin"
    o.scale = (0.4, 1, 0.75)
    o.rotation_euler = (math.radians(93), 0, 0)
    o.data.materials.append(YESIL_KOYU)
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    bagla(o, "DEF-spine.003")
    # deri yelek, kemer, ok kılıfı (sırtta)
    kure("yelek", gh + Vector((0, -0.01, -0.05)), (0.17, 0.13, 0.2), DERI_ACIK, "DEF-spine.003", 16)
    kh, kt = kemik_poz("DEF-hips")
    bpy.ops.mesh.primitive_torus_add(major_radius=0.15, minor_radius=0.022, location=kh + Vector((0, 0, 0.04)))
    o = bpy.context.object
    o.name = "kemer"
    o.scale = (1.0, 0.82, 1.0)
    o.data.materials.append(DERI)
    bagla(o, "DEF-hips")
    silindir("ok_kilifi", gh + Vector((0.08, 0.15, 0.0)), 0.05, 0.5, DERI, "DEF-spine.003", (0, math.radians(20), 0))
    for i in range(4):
        silindir(f"ok_ucu{i}", gh + Vector((0.12 + i * 0.012, 0.16, 0.27)), 0.006, 0.12, GRI_KUMAS, "DEF-spine.003", (0, math.radians(20), 0))
    for s in ("L", "R"):
        kol_boyunca(f"bileklik{s}", f"DEF-forearm.{s}", 0.047, 0.45, 0.95, DERI, 1)
        kol_boyunca(f"cizme{s}", f"DEF-shin.{s}", 0.058, 0.35, 1.0, DERI, 1)

# ================================================================== İNSAN BÜYÜCÜ
else:
    yuz(TEN, SAC_GRI, SAC_GRI)
    kure("sac", bas_merkez + Vector((0, 0.02, 0.03)), (0.112, 0.115, 0.11), SAC_GRI, "DEF-head", 20)
    gh, gt = kemik_poz("DEF-spine.003")
    kh, kt = kemik_poz("DEF-hips")
    # uzun cüppe eteği (koni), omuz yakası, kemer
    silindir("cuppe_etek", kh + Vector((0, 0.0, -0.38)), 0.17, 0.85, MAVI, "DEF-hips", (0, 0, 0), 20, 0.3)
    bpy.data.objects["cuppe_etek"].scale = (1, 1, 1)
    silindir("yaka", gh + Vector((0, 0, 0.13)), 0.13, 0.06, MAVI_ACIK, "DEF-spine.003", (0, 0, 0), 18, 0.2)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.16, minor_radius=0.022, location=kh + Vector((0, 0, 0.06)))
    o = bpy.context.object
    o.name = "kusak"
    o.scale = (1.0, 0.82, 1.0)
    o.data.materials.append(ALTIN)
    bagla(o, "DEF-hips")
    for s in ("L", "R"):
        kol_boyunca(f"yen{s}", f"DEF-forearm.{s}", 0.065, 0.45, 1.0, MAVI_ACIK, 1)
    kure("kolye", gh + Vector((0, -0.12, 0.0)), (0.03, 0.012, 0.03), malzeme("kolye_tas", (0.3, 0.7, 1.0), 0.2, 0.2, (0.3, 0.7, 1.0)), "DEF-spine.003", 12)
    bpy.ops.mesh.primitive_plane_add(size=1, location=gh + Vector((0, 0.13, -0.3)))
    o = bpy.context.object
    o.name = "pelerin"
    o.scale = (0.42, 1, 0.85)
    o.rotation_euler = (math.radians(92), 0, 0)
    o.data.materials.append(MAVI)
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    bagla(o, "DEF-spine.003")

# ------------------------------------------------------------------ silah yuvaları (oyun bunlara silah takar)
for ad, kemik, kaydir in (("handslot_r", "DEF-hand.R", Vector((-0.08, -0.02, -0.02))), ("handslot_l", "DEF-hand.L", Vector((0.08, -0.02, -0.02)))):
    h, t = kemik_poz(kemik)
    bpy.ops.object.empty_add(location=h + kaydir)
    e = bpy.context.object
    e.name = ad
    e.scale = (0.55, 0.55, 0.55)     # KayKit silahları iri: gerçek orana küçült
    bagla(e, kemik)

# ------------------------------------------------------------------ dışa aktar
bpy.ops.object.select_all(action="DESELECT")
for o in [arm, govde] + parcalar:
    o.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.gltf(filepath=CIKTI, export_format="GLB", use_selection=True, export_animations=True,
                          export_animation_mode="ACTIONS", export_yup=True)
print("TAMAM", CIKTI, len(parcalar))
