"""Kül ve Kanat simgesi: Kanatix ortak logosu (marka/uret.py) + alev rozeti.
Çalıştırma: python marka/kulkanat.py  ->  icon.png, icon.ico, assets/logo_mark.png
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import uret  # noqa: E402

ROZET = "#E2541C"
uret.GLYPH["alev"] = ('<path fill="#FFFFFF" d="M0,-44 C14,-22 34,-12 30,14 C27,36 12,46 0,46 C-12,46 -27,36 -30,14 '
                      'C-32,-4 -18,-14 -12,-30 C-8,-18 -4,-12 0,-10 C2,-22 0,-34 0,-44 Z"/>'
                      '<path fill="#E2541C" d="M0,0 C8,10 14,18 12,28 C10,38 4,40 0,40 C-4,40 -10,38 -12,28 C-13,18 -6,10 0,0 Z"/>')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def mark_svg(size=512):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="-256 -256 512 512"><defs>{uret.DEFS}</defs>
<g transform="scale(1.25)"><use href="#mark"/></g></svg>'''

if __name__ == "__main__":
    svg = uret.icon_svg("#2A1610", "#0E0806", "alev", ROZET)
    uret.png(svg, 512, os.path.join(ROOT, "icon.png"))
    uret.ico(svg, os.path.join(ROOT, "icon.ico"))
    uret.png(mark_svg(), 512, os.path.join(ROOT, "assets", "logo_mark.png"))
    print("Kül ve Kanat simgesi üretildi")
