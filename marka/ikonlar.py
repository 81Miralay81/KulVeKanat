"""Yetenek simgeleri (assets/ikon/*.png). Çalıştırma: python marka/ikonlar.py"""
import math, os
from PIL import Image, ImageDraw, ImageFilter
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "ikon")
os.makedirs(OUT, exist_ok=True)

def rgrad(size, inner, outer):
    g = Image.new("RGBA", (size, size)); d = ImageDraw.Draw(g)
    for r in range(size // 2, 0, -1):
        t = r / (size / 2)
        d.ellipse([size/2-r, size/2-r, size/2+r, size/2+r], fill=tuple(int(inner[i]+(outer[i]-inner[i])*t) for i in range(4)))
    return g

PAL = {"kilic": ((180,200,230,255),(30,40,70,255)), "kasirga": ((255,200,90,255),(140,30,5,255)),
       "yarik": ((255,110,50,255),(50,8,4,255)), "kanat": ((255,170,70,255),(90,30,5,255)),
       "meteor": ((255,150,60,255),(60,10,30,255)), "son": ((255,225,140,255),(150,60,0,255)),
       "iksir": ((255,90,90,255),(60,8,12,255))}

def icon(kind, size=128):
    im = rgrad(size*2, *PAL[kind]).resize((size, size), Image.LANCZOS)
    s = size*4; c = s/2; G = Image.new("RGBA", (s, s), (0,0,0,0)); g = ImageDraw.Draw(G); w = (255,250,240,255)
    k = s/320
    def P(pts): return [(c+x*k, c+y*k) for x, y in pts]
    if kind == "kilic":
        g.polygon(P([(-60,70),(70,-60),(92,-92),(60,-70),(-70,60)]), fill=w)
        g.line(P([(-95,35),(-35,95)]), fill=w, width=int(22*k)); g.line(P([(-70,70),(-110,110)]), fill=(90,60,30,255), width=int(24*k))
    elif kind == "kasirga":
        for j in range(3):
            pts = []
            for i in range(60):
                u = i/59; a = j*2.09+u*5.2; r = 18+u*105; pts.append((math.cos(a)*r, math.sin(a)*r))
            g.line(P(pts), fill=(255,245,200,255), width=int(19*k))
    elif kind == "yarik":
        g.line(P([(-20,-115),(15,-40),(-25,-10),(30,50),(-5,115)]), fill=(255,240,180,255), width=int(30*k), joint="curve")
        g.line(P([(15,-40),(80,-70)]), fill=(255,210,140,255), width=int(14*k)); g.line(P([(-25,-10),(-90,20)]), fill=(255,210,140,255), width=int(14*k))
    elif kind in ("kanat", "son"):
        for sg in (-1, 1):
            for i in range(5):
                a = math.radians(30+i*22); L = 120-i*14
                g.line(P([(sg*8,25),(sg*math.sin(a)*L, -math.cos(a)*L+20)]), fill=w if kind=="kanat" else (255,255,230,255), width=int((26-i*2)*k))
        if kind == "son":
            g.ellipse(P([(-26,0),(26,52)]), fill=(255,120,20,255))
    elif kind == "meteor":
        for i in range(4):
            g.line(P([(-110+i*14,-110+i*4),(10,10)]), fill=(255,220,150,200), width=int((10+i*4)*k))
        g.ellipse(P([(-15,-15),(75,75)]), fill=w); g.ellipse(P([(5,5),(55,55)]), fill=(255,140,40,255))
    elif kind == "iksir":
        g.ellipse(P([(-70,-30),(70,110)]), fill=w); g.rectangle(P([(-28,-100),(28,-20)]), fill=w); g.ellipse(P([(-52,5),(52,95)]), fill=(220,30,40,255))
    G = G.resize((size, size), Image.LANCZOS)
    sh = Image.merge("RGBA", (*[Image.new("L", G.size, 0)]*3, G.getchannel("A").point(lambda v: v//2))).filter(ImageFilter.GaussianBlur(3))
    im.alpha_composite(sh, (3, 3)); im.alpha_composite(G)
    m = Image.new("RGBA", (size, size), (0,0,0,0)); ImageDraw.Draw(m).rectangle([0,0,size-1,size-1], outline=(0,0,0,170), width=8)
    im.alpha_composite(m.filter(ImageFilter.GaussianBlur(5)))
    mask = Image.new("L", (size, size), 0); ImageDraw.Draw(mask).ellipse([0,0,size-1,size-1], fill=255)
    out = Image.new("RGBA", (size, size), (0,0,0,0)); out.paste(im, (0,0), mask)
    return out

for kname in PAL:
    icon(kname).save(os.path.join(OUT, kname + ".png"))
print("ikonlar tamam")

# Eşya yuvası simgeleri (beyaz, saydam zemin): assets/ikon/yuva_*.png
def yuva(kind, size=96):
    s = size * 4; c = s / 2; G = Image.new("RGBA", (s, s), (0, 0, 0, 0)); g = ImageDraw.Draw(G); w = (255, 255, 255, 255)
    k = s / 320
    def P(pts): return [(c + x * k, c + y * k) for x, y in pts]
    if kind == "Silah":
        g.polygon(P([(-60, 70), (70, -60), (92, -92), (60, -70), (-70, 60)]), fill=w)
        g.line(P([(-95, 35), (-35, 95)]), fill=w, width=int(22 * k)); g.line(P([(-70, 70), (-110, 110)]), fill=w, width=int(24 * k))
    elif kind == "Zırh":
        g.polygon(P([(-90, -80), (-40, -100), (0, -70), (40, -100), (90, -80), (75, 10), (60, 100), (-60, 100), (-75, 10)]), fill=w)
    elif kind == "Kask":
        g.pieslice(P([(-90, -100), (90, 80)]), 180, 360, fill=w); g.rectangle(P([(-90, -12), (90, 30)]), fill=w)
        g.rectangle(P([(-70, 30), (-30, 100)]), fill=w); g.rectangle(P([(30, 30), (70, 100)]), fill=w)
    elif kind == "Yüzük":
        g.ellipse(P([(-80, -40), (80, 110)]), outline=w, width=int(26 * k)); g.polygon(P([(-30, -60), (0, -105), (30, -60), (0, -35)]), fill=w)
    elif kind == "Kanat":
        for sg in (-1, 1):
            for i in range(5):
                a = math.radians(30 + i * 22); L = 120 - i * 14
                g.line(P([(sg * 8, 25), (sg * math.sin(a) * L, -math.cos(a) * L + 20)]), fill=w, width=int((26 - i * 2) * k))
    elif kind == "Canta":
        g.rounded_rectangle(P([(-95, -40), (95, 110)]), radius=int(30 * k), fill=w)
        g.arc(P([(-55, -110), (55, 10)]), 180, 360, fill=w, width=int(22 * k))
        g.rectangle(P([(-95, 10), (95, 26)]), fill=(0, 0, 0, 0))
    return G.resize((size, size), Image.LANCZOS)

for yname, dosya in [("Silah", "silah"), ("Zırh", "zirh"), ("Kask", "kask"), ("Yüzük", "yuzuk"), ("Kanat", "kanat"), ("Canta", "canta")]:
    yuva(yname).save(os.path.join(OUT, "yuva_" + dosya + ".png"))
print("yuva simgeleri tamam")
