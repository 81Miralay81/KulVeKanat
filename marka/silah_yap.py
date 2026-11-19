"""Elde ve yerde görünen gerçekçi silah modelleri (kılıç ve asa, 5 kademe) -> assets/silah/*.glb"""
import sys, bpy
sys.path.insert(0, "/home/claude/kulvekanat/marka")
import esya_ikon as E

for tur, fn in ((("kilic", E.kilic), ("asa", E.asa)) if "--kalkan" not in sys.argv else ()):
    for k in range(5):
        E.temizle()
        M = E.malzemeler(k)
        objs = fn(M, k)
        kok = objs[0].parent
        kok.rotation_euler = (0, 0, 0)
        for o in objs:
            if o.type == "CURVE":
                continue
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
        yol = "/home/claude/kulvekanat/assets/silah/%s_%d.glb" % (tur, k)
        bpy.ops.export_scene.gltf(filepath=yol, export_format="GLB", use_selection=True, export_yup=True, export_apply=True)
        print("SILAH", yol)

# kalkan: ahşap gövde, metal kenar ve ortada metal göbek (ön yüz -Y = oyunda +Z)
import math
E.temizle()
M = E.malzemeler(1)
objs = [E.silindir(0.8, 0.06, (0, 0, 0), M["ahsap"], (math.radians(90), 0, 0), seg=48),
        E.halka(0.8, 0.045, (0, 0, 0), M["metal"], (math.radians(90), 0, 0)),
        E.kure(0.2, (0, -0.03, 0), M["metal"], (1, 0.6, 1))]
for i in range(8):
    a = math.tau * i / 8
    objs.append(E.kure(0.035, (math.cos(a) * 0.65, -0.04, math.sin(a) * 0.65), M["metal"]))
bpy.ops.object.select_all(action="DESELECT")
for o in objs:
    o.select_set(True)
bpy.ops.export_scene.gltf(filepath="/home/claude/kulvekanat/assets/silah/kalkan_0.glb", export_format="GLB", use_selection=True, export_yup=True, export_apply=True)
print("SILAH kalkan")
