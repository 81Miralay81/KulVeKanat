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
       "iksir": ((255,90,90,255),(60,8,12,255)),
       "yay": ((200,170,255,255),(40,20,70,255)), "coklu": ((210,150,255,255),(50,15,80,255)),
       "okyagmuru": ((170,140,255,255),(30,15,70,255)), "golge": ((150,110,220,255),(20,10,40,255)),
       "zehir": ((150,255,120,255),(10,60,20,255)), "golgefirtina": ((230,180,255,255),(70,20,110,255)),
       "atestopu": ((255,170,80,255),(90,20,5,255)), "alevhalkasi": ((255,140,60,255),(80,10,5,255)),
       "buz": ((170,230,255,255),(10,40,90,255)), "isinlanma": ((180,210,255,255),(30,30,90,255)),
       "kiyamet": ((255,200,120,255),(120,20,10,255))}

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
    elif kind == "yay":
        g.arc(P([(-110,-120),(40,120)]), -70, 70, fill=w, width=int(18*k)); g.line(P([(-8,-112),(-8,112)]), fill=w, width=int(6*k))
        g.line(P([(-60,0),(110,0)]), fill=w, width=int(10*k)); g.polygon(P([(110,0),(80,-18),(80,18)]), fill=w)
    elif kind == "coklu":
        for a2 in (-35,-17,0,17,35):
            r = math.radians(a2); x2, y2 = math.cos(r)*115, math.sin(r)*115
            g.line(P([(-90,0),(x2,y2)]), fill=w, width=int(8*k)); g.polygon(P([(x2,y2),(x2-22*math.cos(r)+10*math.sin(r), y2-22*math.sin(r)-10*math.cos(r)),(x2-22*math.cos(r)-10*math.sin(r), y2-22*math.sin(r)+10*math.cos(r))]), fill=w)
    elif kind == "okyagmuru":
        for x2 in (-80,-35,10,55,95):
            g.line(P([(x2-30,-110),(x2,60)]), fill=w, width=int(8*k)); g.polygon(P([(x2,80),(x2-14,50),(x2+10,48)]), fill=w)
    elif kind == "golge":
        for i in range(3):
            g.ellipse(P([(-70+i*45,-60),(10+i*45,90)]), fill=(255,255,255,90+i*80))
    elif kind == "zehir":
        g.ellipse(P([(-70,-40),(70,100)]), fill=w); g.rectangle(P([(-20,-90),(20,-30)]), fill=w)
        for (x2,y2) in ((-20,30),(25,55),(0,0)): g.ellipse(P([(x2-14,y2-14),(x2+14,y2+14)]), fill=(60,170,60,255))
    elif kind == "golgefirtina":
        for i in range(10):
            a2 = i*36; r = math.radians(a2)
            g.line(P([(math.cos(r)*30, math.sin(r)*30),(math.cos(r)*115, math.sin(r)*115)]), fill=w, width=int(10*k))
    elif kind == "atestopu":
        g.ellipse(P([(-10,-60),(110,60)]), fill=w)
        for i in range(4): g.line(P([(-110,-40+i*26),(10,-30+i*20)]), fill=(255,230,180,200), width=int((14-i*2)*k))
        g.ellipse(P([(15,-35),(85,35)]), fill=(255,140,40,255))
    elif kind == "alevhalkasi":
        g.ellipse(P([(-110,-110),(110,110)]), outline=w, width=int(26*k)); g.ellipse(P([(-55,-55),(55,55)]), outline=(255,220,160,255), width=int(14*k))
    elif kind == "buz":
        for a2 in (0,60,120):
            r = math.radians(a2); g.line(P([(math.cos(r)*-110, math.sin(r)*-110),(math.cos(r)*110, math.sin(r)*110)]), fill=w, width=int(16*k))
        g.ellipse(P([(-24,-24),(24,24)]), fill=w)
    elif kind == "isinlanma":
        g.ellipse(P([(-110,-40),(-30,40)]), outline=w, width=int(12*k)); g.ellipse(P([(30,-40),(110,40)]), fill=w)
        g.line(P([(-30,0),(30,0)]), fill=(255,255,255,150), width=int(10*k))
    elif kind == "kiyamet":
        for (x2,y2,r2) in ((-55,-45,32),(50,-60,26),(5,40,44)):
            g.line(P([(x2-80,y2-80),(x2,y2)]), fill=(255,230,170,200), width=int(r2*0.6*k)); g.ellipse(P([(x2-r2,y2-r2),(x2+r2,y2+r2)]), fill=w)
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
