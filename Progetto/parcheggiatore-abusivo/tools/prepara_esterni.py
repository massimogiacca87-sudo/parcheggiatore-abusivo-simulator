#!/usr/bin/env python3
"""'A robba 'e fore, pronta pe' 'o joco (0.62, asset esterni).

La cartella `assets/esterni/` è la **biblioteca** preparata dall'altra
sessione: materiali Poly Haven a 2K, decalcomanie ambientCG a 2K con
l'opacità in un file a parte, graffiti. Sta fuori dall'esportazione
(`exclude_filter`) e non si tocca.

Questo script ne ricava le copie **da gioco**, piccole e già montate:

* i materiali PBR a 1024 px (albedo, normale, ruvidezza) in
  `assets/textures/pbr/` — il 2K in una città vista in prima persona non si
  vede, e pesa quattro volte tanto nella build web;
* le decalcomanie in un PNG solo con l'alfa dentro (colore + opacità
  uniti) a 512 px in `assets/textures/decal/`, più la normale dove serve
  (tombini, rattoppi).

Si rilancia così, dalla cartella del progetto:

    python3 tools/prepara_esterni.py

e poi si importa (`godot4 --headless --path . --import`). Gli originali non
cambiano; se un giorno si vuole un'altra misura basta cambiare `LATO`.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageEnhance

RADICE = Path(__file__).resolve().parent.parent
EST = RADICE / "assets/esterni/materiali"
PBR = RADICE / "assets/textures/pbr"
DEC = RADICE / "assets/textures/decal"

LATO = 1024          # i materiali
LATO_DECAL = 512     # le decalcomanie


def _salva_jpg(im: Image.Image, dove: Path, q: int = 90) -> None:
    dove.parent.mkdir(parents=True, exist_ok=True)
    im.save(dove, quality=q, optimize=True)
    print(f"  {dove.relative_to(RADICE)}  {im.size[0]}x{im.size[1]}")


def materiale(sorgente: str, nome: str) -> None:
    """Albedo, normale e ruvidezza di un materiale Poly Haven."""
    cartella = EST / sorgente
    stelo = cartella.name
    for suff, dest, modo in (("diff", "albedo", "RGB"),
                             ("nor_gl", "normale", "RGB"),
                             ("rough", "ruvidezza", "L")):
        im = Image.open(cartella / f"{stelo}_{suff}_2k.jpg").convert(modo)
        im = im.resize((LATO, LATO), Image.LANCZOS)
        _salva_jpg(im, PBR / f"{nome}_{dest}.jpg", 92 if suff == "nor_gl" else 88)


def _con_alfa(colore: Path, opacita: Path | None, lato: int,
              ritaglio: tuple | None = None) -> Image.Image:
    im = Image.open(colore).convert("RGBA")
    if opacita is not None and opacita.exists():
        a = Image.open(opacita).convert("L")
        im.putalpha(a)
    if ritaglio is not None:
        w, h = im.size
        im = im.crop((int(ritaglio[0] * w), int(ritaglio[1] * h),
                      int(ritaglio[2] * w), int(ritaglio[3] * h)))
    if isinstance(lato, tuple):
        return im.resize(lato, Image.LANCZOS)
    return im.resize((lato, lato), Image.LANCZOS)


def _salva_png(im: Image.Image, dove: Path) -> None:
    dove.parent.mkdir(parents=True, exist_ok=True)
    im.save(dove, optimize=True)
    print(f"  {dove.relative_to(RADICE)}  {im.size[0]}x{im.size[1]}")


def decal(cartella: str, nome: str, normale: bool = False, lato=LATO_DECAL,
          ritaglio=None, ritocco=None) -> None:
    d = EST / "decals" / cartella
    stelo = d.name
    col = d / f"{stelo}_2K-PNG_Color.png"
    opa = d / f"{stelo}_2K-PNG_Opacity.png"
    im = _con_alfa(col, opa, lato, ritaglio)
    if ritocco is not None:
        im = ritocco(im)
    _salva_png(im, DEC / f"{nome}.png")
    if normale:
        n = Image.open(d / f"{stelo}_2K-PNG_NormalGL.png").convert("RGB")
        if ritaglio is not None:
            w, h = n.size
            n = n.crop((int(ritaglio[0] * w), int(ritaglio[1] * h),
                        int(ritaglio[2] * w), int(ritaglio[3] * h)))
        n = n.resize(im.size, Image.LANCZOS)
        _salva_png(n, DEC / f"{nome}_n.png")


def _olio(im: Image.Image) -> Image.Image:
    """La macchia di `Leaking006` è color ruggine: l'olio sotto a una
    macchina è quasi nero e appena iridescente. Si toglie il colore, si
    scurisce e si abbassa l'alfa, così resta un alone e non una pozza."""
    a = np.asarray(im).astype(np.float32)
    lum = (a[..., 0] * 0.3 + a[..., 1] * 0.59 + a[..., 2] * 0.11)
    scuro = lum * 0.32
    a[..., 0] = scuro * 0.95
    a[..., 1] = scuro * 0.93
    a[..., 2] = scuro * 1.0
    a[..., 3] *= 0.82
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")


def _sporca(im: Image.Image) -> Image.Image:
    """Mezza tinta di muschio in meno, e i bordi che sfumano: il ritaglio
    della colonna centrale taglia la colatura a metà, e un rettangolo con
    lo spigolo netto su un muro si vede da lontano (prima foto della 0.62).
    L'alfa si spegne verso i lati (a campana) e negli ultimi due quinti in
    basso, dove l'acqua si asciuga."""
    a = np.asarray(im).astype(np.float32)
    lum = (a[..., 0] * 0.3 + a[..., 1] * 0.59 + a[..., 2] * 0.11)
    for k in range(3):
        a[..., k] = a[..., k] * 0.45 + lum * 0.55 * (0.92 if k == 2 else 1.0)
    h, w = lum.shape
    u = np.linspace(-1.0, 1.0, w)[None, :]
    v = np.linspace(0.0, 1.0, h)[:, None]
    lati = np.clip(1.0 - u ** 2, 0.0, 1.0) ** 1.5
    sotto = np.clip((1.0 - v) / 0.4, 0.0, 1.0)
    sopra = np.clip(v / 0.04, 0.0, 1.0)
    a[..., 3] *= lati * sotto * sopra * 1.25
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")


def _alfa_minima(im: Image.Image, soglia: int = 8) -> Image.Image:
    """Ritaglia sul contenuto (i graffiti stanno in mezzo a un quadrato
    vuoto: a tenerlo tutto, il muro si prende un rettangolo invisibile
    grande il triplo)."""
    box = im.getchannel("A").point(lambda v: 255 if v > soglia else 0).getbbox()
    return im.crop(box) if box else im


def graffito() -> None:
    im = Image.open(EST / "decals/graffiti/graffiti_00.png").convert("RGBA")
    im = _alfa_minima(im)
    w, h = im.size
    k = 512 / max(w, h)
    im = im.resize((int(w * k), int(h * k)), Image.LANCZOS)
    # Un poco stinto: è vernice spray al sole di Napoli, non un adesivo.
    rgb = ImageEnhance.Color(im.convert("RGB")).enhance(0.82)
    rgb.putalpha(im.getchannel("A"))
    _salva_png(rgb, DEC / "graffito_tag.png")


def main() -> None:
    print("=== materiali PBR ===")
    materiale("asfalto/asphalt_02", "asfalto")
    materiale("intonaco/concrete_wall_003", "muffa")
    print("=== decalcomanie ===")
    decal("tombini/ManholeCover001", "tombino_ghisa", normale=True)
    decal("tombini/ManholeCover005", "tombino_grata", normale=True)
    decal("crepe_asfalto/AsphaltDamage001", "rattoppo", normale=True)
    decal("chewing_gum/ChewingGum001", "gomme")
    decal("macchie_olio_perdite/Leaking006", "macchia_olio", ritocco=_olio)
    # La colatura del condizionatore: una striscia scura sotto allo split.
    # `Leaking010A` (il foro col filo d'acqua) a 512 px sparisce: il filo è
    # largo tre pixel. Si prende la colonna centrale di `Leaking008`, che è
    # una colatura larga e scura, e le si toglie metà del verde (è acqua
    # sporca, non muschio).
    decal("macchie_olio_perdite/Leaking008", "colatura_split",
          lato=(160, 512), ritaglio=(0.32, 0.0, 0.62, 1.0),
          ritocco=_sporca)
    decal("macchie_olio_perdite/Leaking003", "colatura_muro")
    graffito()


if __name__ == "__main__":
    main()
