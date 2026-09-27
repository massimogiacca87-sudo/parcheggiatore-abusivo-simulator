#!/usr/bin/env python3
"""L'icona della pittura janca c''o pennello (0.64), nello stile delle altre
di assets/icone/: figure piatte col contorno scuro. Si disegna a 512 e si
rimpicciolisce a 128 (così i bordi vengono morbidi)."""
import os
from PIL import Image, ImageDraw

S = 512
K = (32, 27, 26, 255)          # contorno
W = 14                          # spessore del contorno
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# --- 'O barattolo -----------------------------------------------------------
x0, x1 = 70, 330
top, bot = 190, 450
# corpo
d.rounded_rectangle([x0, top, x1, bot], radius=26, fill=(214, 218, 222, 255),
                    outline=K, width=W)
# fascia dell'etichetta, blu (la pittura è del Comune... ma janca)
d.rectangle([x0 + W // 2, top + 90, x1 - W // 2, top + 190], fill=(40, 96, 190, 255))
d.line([x0, top + 90, x1, top + 90], fill=K, width=W - 4)
d.line([x0, top + 190, x1, top + 190], fill=K, width=W - 4)
# la P bianca sull'etichetta... no: una goccia bianca, che è pittura
d.ellipse([x0 + 95, top + 108, x0 + 165, top + 172], fill=(250, 250, 248, 255),
          outline=K, width=8)
# il bordo di sopra, ovale
d.ellipse([x0 - 6, top - 40, x1 + 6, top + 40], fill=(245, 245, 242, 255),
          outline=K, width=W)
# la pittura dentro
d.ellipse([x0 + 16, top - 24, x1 - 16, top + 24], fill=(255, 255, 255, 255),
          outline=(150, 150, 150, 255), width=5)
# le colature bianche sul fianco
for cx, lung in [(110, 70), (170, 110), (250, 55)]:
    d.rounded_rectangle([cx - 13, top + 20, cx + 13, top + 20 + lung], radius=13,
                        fill=(255, 255, 255, 255), outline=K, width=7)
    d.ellipse([cx - 16, top + lung, cx + 16, top + lung + 32],
              fill=(255, 255, 255, 255), outline=K, width=7)
# il manico del barattolo
d.arc([x0 + 20, top - 150, x1 - 20, top + 70], start=200, end=340, fill=K, width=W)

# --- 'O pennello, appoggiato di traverso ----------------------------------
import math
ang = math.radians(-38)
def ruota(px, py, cx, cy):
    dx, dy = px - cx, py - cy
    return (cx + dx * math.cos(ang) - dy * math.sin(ang),
            cy + dx * math.sin(ang) + dy * math.cos(ang))
cx, cy = 318, 262
def poly(pts, fill):
    q = [ruota(x, y, cx, cy) for x, y in pts]
    d.polygon(q, fill=fill, outline=K)
    d.line(q + [q[0]], fill=K, width=W - 2, joint="curve")
# manico di legno
poly([(302, 60), (358, 60), (352, 250), (308, 250)], (176, 106, 52, 255))
# ghiera di metallo
poly([(290, 250), (370, 250), (374, 330), (286, 330)], (170, 176, 184, 255))
# setole, con la punta bianca
poly([(282, 330), (378, 330), (392, 430), (268, 430)], (70, 55, 45, 255))
poly([(270, 405), (390, 405), (396, 470), (264, 470)], (255, 255, 255, 255))

img = img.resize((128, 128), Image.LANCZOS)
dove = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                    "assets", "icone", "pittura.png")
img.save(dove)
print("scritto", dove)
