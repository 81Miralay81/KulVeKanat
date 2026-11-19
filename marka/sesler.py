"""Oyun sesleri (assets/ses/*.wav) sentezle. Çalıştırma: python marka/sesler.py"""
import os, wave
import numpy as np
SR = 22050
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "ses")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(5)

def t(d): return np.linspace(0, d, int(SR*d), endpoint=False)
def env(n, a=0.005, r=0.2, d=None):
    x = np.arange(n)/SR; e = np.minimum(1, x/max(a,1e-4)); e *= np.exp(-x/max(r,1e-4)); return e
def lp(x, k):  # basit alçak geçiren
    y = np.convolve(x, np.ones(k)/k, mode="same"); return y
def save(name, x, vol=0.9):
    x = x/ (np.max(np.abs(x))+1e-9) * vol
    with wave.open(os.path.join(OUT, name+".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x*32000).astype(np.int16).tobytes())

def noise(n): return rng.uniform(-1, 1, n)

# kılıç savurma: süpürülen gürültü
n = int(SR*0.28); x = noise(n); k = np.linspace(40, 4, n).astype(int)
y = np.array([x[max(0,i-k[i]):i+1].mean() for i in range(n)]); y *= np.sin(np.linspace(0, np.pi, n))**2
save("savurma", y, 0.7)
# vuruş: kısa darbe + kemik çatırtısı
d = t(0.18); y = np.sin(2*np.pi*(120 - 300*d)*d)*env(len(d), 0.001, 0.05) + lp(noise(len(d)), 3)*env(len(d), 0.001, 0.03)*0.8
save("vurus", y, 0.85)
# kritik: daha parlak
d = t(0.25); y = np.sin(2*np.pi*(180-200*d)*d)*env(len(d),0.001,0.07) + noise(len(d))*env(len(d),0.001,0.05)*0.9 + np.sin(2*np.pi*1800*d)*env(len(d),0.001,0.06)*0.3
save("kritik", y, 0.9)
# patlama
d = t(1.1); y = lp(noise(len(d)), 12)*env(len(d), 0.005, 0.35) + np.sin(2*np.pi*(55-20*d)*d)*env(len(d),0.002,0.4)*1.2
save("patlama", y, 0.95)
# ateş uğultusu (döngü)
d = t(2.0); y = lp(noise(len(d)), 20)*(0.6+0.4*np.sin(2*np.pi*3*d)) + lp(noise(len(d)), 4)*0.15
y[:400] *= np.linspace(0,1,400); y[-400:] *= np.linspace(1,0,400)
save("ates", y, 0.6)
# atılım: yükselen süpürme
n = int(SR*0.35); x = noise(n); k = np.linspace(4, 40, n).astype(int)
y = np.array([x[max(0,i-k[i]):i+1].mean() for i in range(n)]) * np.sin(np.linspace(0,np.pi,n)); y += np.sin(2*np.pi*np.cumsum(np.linspace(300,900,n))/SR)*np.sin(np.linspace(0,np.pi,n))*0.25
save("atilim", y, 0.75)
# seviye atlama: yükselen akor
d = t(1.2); y = np.zeros(len(d))
for i, f in enumerate([523.25, 659.25, 783.99, 1046.5]):
    s = int(i*0.09*SR); seg = d[:len(d)-s]
    y[s:] += (np.sin(2*np.pi*f*seg)+0.3*np.sin(4*np.pi*f*seg))*env(len(seg), 0.01, 0.5)
save("seviye", y, 0.75)
# altın
d = t(0.25); y = (np.sin(2*np.pi*1800*d)+np.sin(2*np.pi*2400*d))*env(len(d),0.001,0.08)
save("altin", y, 0.5)
# eşya düştü (efsanevi)
d = t(1.0); y = sum(np.sin(2*np.pi*f*d)*env(len(d),0.02,0.6) for f in (392, 587.3, 784, 1175))
save("esya", y, 0.6)
# ölüm (kemik dağılması)
d = t(0.5); y = np.zeros(len(d))
for i in range(7):
    s = int(rng.uniform(0, 0.3)*SR); L = int(0.05*SR)
    if s+L < len(d): y[s:s+L] += noise(L)*env(L, 0.001, 0.015)
y += np.sin(2*np.pi*90*d)*env(len(d),0.001,0.08)*0.5
save("olum", y, 0.7)
# hasar aldı
d = t(0.2); y = np.sin(2*np.pi*(200-250*d)*d)*env(len(d),0.001,0.08) + lp(noise(len(d)),6)*env(len(d),0.001,0.05)
save("aci", y, 0.7)
# büyü mermisi
d = t(0.4); y = np.sin(2*np.pi*(600+400*np.sin(30*d))*d)*env(len(d),0.01,0.2)*0.6 + lp(noise(len(d)),8)*env(len(d),0.01,0.15)
save("buyu", y, 0.5)
# düğme
d = t(0.08); y = np.sin(2*np.pi*900*d)*env(len(d),0.001,0.02)
save("dugme", y, 0.4)

# arka plan müziği: karanlık, yavaş (40 sn döngü)
L = 40.0; d = t(L); y = np.zeros(len(d))
chords = [(55.0, 65.41, 82.41), (49.0, 58.27, 73.42), (43.65, 55.0, 65.41), (49.0, 61.74, 73.42)]
seg = L/len(chords)
for i, ch in enumerate(chords):
    s, e = int(i*seg*SR), int((i+1)*seg*SR); tt = d[s:e]-d[s]
    a = np.minimum(1, tt/2.5)*np.minimum(1, (seg-tt)/2.5)
    for f in ch:
        y[s:e] += (np.sin(2*np.pi*f*tt) + 0.5*np.sin(2*np.pi*f*2.003*tt) + 0.25*np.sin(2*np.pi*f*3.01*tt))*a*0.3
y += lp(noise(len(d)), 60)*0.25
for b in np.arange(0, L, 2.5):  # davul
    s = int(b*SR); n = int(0.6*SR)
    if s+n < len(y):
        tt = d[:n]; y[s:s+n] += np.sin(2*np.pi*(60-30*tt)*tt)*env(n, 0.002, 0.25)*0.9
save("muzik", y, 0.55)
print("sesler tamam")
