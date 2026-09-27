#!/usr/bin/env python3
"""I suoni nuovi della 0.64, fatti a codice (numpy → wav → ogg con ffmpeg).

  audio/pennellata.ogg      'a passata d''o pennello sulle strisce blu
  audio/tic.ogg, tac.ogg    'o tic tac d''a sfida d''o Rre
  audio/gong_sfida.ogg      'a campana 'e fine sfida (tre colpi, come al pugilato)
  audio/musica/sfida.ogg    'na tarantella a 160, in la minore, 32 battute
                            (24 secondi che girano in tondo: mandolino col
                            tremolo, chitarra "oom-pa-pa", basso e tammorra)

La melodia è scritta qui sotto, nota per nota: non è la Tarantella
Napoletana, è una fatta apposta nello stesso stile (6/8, minore armonico).

Uso: python3 tools/genera_suoni_064.py   (poi si reimporta il progetto)
"""
import os
import subprocess
import numpy as np

SR = 44100
QUI = os.path.dirname(os.path.abspath(__file__))
PROG = os.path.dirname(QUI)
rng = np.random.default_rng(64)


def scrivi_ogg(nome, y, stereo=None, qualita=5):
    """y mono (o stereo = (L, R)) in float −1..1 → .ogg nel progetto."""
    import wave
    if stereo is not None:
        dati = np.stack(stereo, axis=1)
    else:
        dati = y[:, None]
    dati = np.clip(dati, -1.0, 1.0)
    pcm = (dati * 32767.0).astype(np.int16)
    tmp = "/tmp/_suono064.wav"
    with wave.open(tmp, "wb") as w:
        w.setnchannels(pcm.shape[1])
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    dove = os.path.join(PROG, nome)
    os.makedirs(os.path.dirname(dove), exist_ok=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp,
                    "-c:a", "libvorbis", "-q:a", str(qualita), dove], check=True)
    print("  scritto", nome, "%.2fs" % (len(pcm) / SR))


def normalizza(y, picco=0.89):
    m = np.max(np.abs(y)) + 1e-9
    return y * (picco / m)


# ---------------------------------------------------------------------------
# Effetti
# ---------------------------------------------------------------------------

def passa_banda(x, lo, hi):
    """Filtro passa-banda nel dominio della frequenza (va bene per rumori corti)."""
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1.0 / SR)
    m = ((f >= lo) & (f <= hi)).astype(float)
    # bordi morbidi
    m = np.convolve(m, np.hanning(31) / np.hanning(31).sum(), mode="same")
    return np.fft.irfft(X * m, n=len(x))


def pennellata():
    n = int(0.46 * SR)
    t = np.arange(n) / SR
    rumore = rng.standard_normal(n)
    # rumore rosa-ish: integrazione leggera
    rosa = np.cumsum(rumore) * 0.02 + rumore * 0.6
    rosa -= np.convolve(rosa, np.ones(400) / 400, mode="same")
    corpo = passa_banda(rosa, 900, 5200)
    inv = np.sin(np.pi * np.clip(t / 0.46, 0, 1)) ** 0.8
    # le setole che crepitano
    crepitii = np.zeros(n)
    for _ in range(38):
        i = rng.integers(int(0.03 * SR), n - 400)
        crepitii[i:i + 60] += rng.standard_normal(60) * np.exp(-np.arange(60) / 12.0) * 0.8
    crepitii = passa_banda(crepitii, 2500, 9000)
    y = corpo * inv + crepitii * inv * 0.5
    return normalizza(y, 0.7)


def legnetto(freq, durata=0.09):
    n = int(durata * SR)
    t = np.arange(n) / SR
    tono = np.sin(2 * np.pi * freq * t) * np.exp(-t / 0.018)
    tono += 0.45 * np.sin(2 * np.pi * freq * 2.71 * t) * np.exp(-t / 0.009)
    click = rng.standard_normal(n) * np.exp(-t / 0.0025) * 0.6
    y = tono + passa_banda(click, 1500, 9000)
    return normalizza(y, 0.8)


def campana(durata=1.9, colpi=3):
    n = int(durata * SR)
    t = np.arange(n) / SR
    y = np.zeros(n)
    parziali = [(1.0, 1.0, 1.4), (2.76, 0.55, 0.7), (5.40, 0.30, 0.35),
                (8.93, 0.18, 0.18), (1.5, 0.25, 1.0)]
    f0 = 880.0
    for k in range(colpi):
        t0 = int(k * 0.2 * SR)
        tt = t[: n - t0]
        colpo = np.zeros(len(tt))
        for r, a, dec in parziali:
            colpo += a * np.sin(2 * np.pi * f0 * r * tt + rng.random()) * np.exp(-tt / dec)
        colpo *= (1.0 - np.exp(-tt / 0.002))
        y[t0:] += colpo * (0.9 if k < colpi - 1 else 1.0)
    return normalizza(y, 0.85)


# ---------------------------------------------------------------------------
# 'A tarantella
# ---------------------------------------------------------------------------

NOTE = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7,
        "G#": 8, "A": 9, "A#": 10, "B": 11}


def hz(nome):
    nota, ott = nome[:-1], int(nome[-1])
    midi = 12 * (ott + 1) + NOTE[nota]
    return 440.0 * 2 ** ((midi - 69) / 12.0)


def corda(freq, durata, lucentezza=0.5, smorzo=0.996):
    """Karplus-Strong: una corda pizzicata, accordata col passa-tutto.

    Il giro della corda dev'essere SR/f campioni: la parte intera sta nel
    buffer, quella frazionaria in un filtro passa-tutto (Jaffe e Smith).
    Senza, le note alte stonavano fino a un quarto di tono.
    """
    n = int(durata * SR)
    # Il buffer fa p campioni, ma la media guarda avanti di mezzo: il giro
    # vero è p − 0,5 + d. Perché sia SR/f, p + d = SR/f + 0,5.
    ritardo = SR / freq + 0.5
    p = max(2, int(np.floor(ritardo)))
    d = ritardo - p
    if d < 0.1:
        p -= 1
        d += 1.0
    c = (1.0 - d) / (1.0 + d)
    buf = rng.uniform(-1, 1, p)
    # un pizzico più morbido o più brillante
    if lucentezza < 1.0:
        buf = np.convolve(buf, [lucentezza, 1.0 - lucentezza], mode="same")
    buf = buf.tolist()
    out = np.zeros(n)
    x_prec = 0.0
    y_prec = 0.0
    i = 0
    for k in range(n):
        a = buf[i]
        b = buf[(i + 1) % p]
        out[k] = a
        nuovo = smorzo * 0.5 * (a + b)
        ap = c * nuovo + x_prec - c * y_prec
        x_prec = nuovo
        y_prec = ap
        buf[i] = ap
        i = (i + 1) % p
    return out


_cache_corde = {}


def corda_c(freq, durata, lucentezza, smorzo):
    k = (round(freq, 2), round(durata, 3), lucentezza, smorzo)
    if k not in _cache_corde:
        _cache_corde[k] = corda(freq, durata, lucentezza, smorzo)
    return _cache_corde[k]


BPM = 160.0                    # semiminima puntata
OTTAVO = 60.0 / BPM / 3.0      # 0,125 s
BATTUTA = OTTAVO * 6

# Gli accordi, una battuta per voce (32 battute).
ACCORDI = ["Am", "Am", "E", "E", "Am", "Am", "E", "Am",
           "Dm", "Dm", "Am", "Am", "E", "E", "Am", "Am",
           "C", "C", "G", "G", "Am", "Am", "E", "E",
           "Dm", "Dm", "Am", "Am", "E7", "E7", "Am", "E"]
TRIADI = {"Am": ["A3", "C4", "E4"], "E": ["G#3", "B3", "E4"], "E7": ["G#3", "B3", "D4"],
          "Dm": ["A3", "D4", "F4"], "C": ["G3", "C4", "E4"], "G": ["G3", "B3", "D4"]}
BASSI = {"Am": ("A2", "E2"), "E": ("E2", "B1"), "E7": ("E2", "B1"), "Dm": ("D2", "A2"),
         "C": ("C2", "G2"), "G": ("G2", "D2")}

# La melodia: sei ottavi a battuta, "-" tiene la nota di prima.
MELODIA = """
E5 A5 A5 A5 G#5 A5 | B5 C6 B5 A5 G#5 A5 | B4 E5 E5 E5 D5 E5 | F5 E5 D5 C5 B4 G#4 |
E5 A5 A5 A5 G#5 A5 | B5 C6 D6 C6 B5 A5 | G#5 B5 A5 G#5 F5 E5 | A5 - - E5 - - |
D5 F5 A5 F5 D5 F5 | E5 F5 G5 F5 E5 D5 | C5 E5 A5 E5 C5 E5 | B4 C5 D5 C5 B4 A4 |
G#4 B4 E5 B4 G#4 B4 | D5 C5 B4 A4 G#4 B4 | A4 C5 E5 A5 E5 C5 | A4 - - A5 - - |
G5 E5 C5 E5 G5 C6 | B5 C6 D6 C6 B5 G5 | B5 G5 D5 G5 B5 D6 | C6 B5 A5 G5 F5 D5 |
E5 A5 C6 A5 E5 A5 | C6 B5 A5 G#5 A5 B5 | G#5 E5 B4 E5 G#5 B5 | D6 C6 B5 A5 G#5 E5 |
F5 A5 D6 A5 F5 A5 | E5 F5 A5 G5 F5 E5 | E5 C5 A4 C5 E5 A5 | C6 B5 A5 E5 C5 E5 |
D5 E5 G#5 B5 D6 B5 | G#5 B5 D6 E6 D6 B5 | A5 E5 C5 A4 C5 E5 | E5 G#5 B5 E6 - - |
"""


def tarantella():
    battute = [b.split() for b in MELODIA.replace("\n", " ").split("|") if b.strip()]
    assert len(battute) == 32 and all(len(b) == 6 for b in battute), \
        [len(b) for b in battute]
    lungo = 32 * BATTUTA
    n = int((lungo + 2.0) * SR)
    L = np.zeros(n)
    R = np.zeros(n)

    def metti(dove, y, sin, des):
        i = int(dove * SR)
        m = min(len(y), n - i)
        L[i:i + m] += y[:m] * sin
        R[i:i + m] += y[:m] * des

    # Mandolino: la nota tenuta col tremolo (quattro pizzichi a ottavo),
    # due corde appena scordate.
    note_lunghe = []
    for b, batt in enumerate(battute):
        for k, nota in enumerate(batt):
            t0 = b * BATTUTA + k * OTTAVO
            if nota == "-":
                note_lunghe[-1][1] += OTTAVO
            else:
                note_lunghe.append([t0, OTTAVO, nota])
    for t0, dur, nota in note_lunghe:
        f = hz(nota)
        colpi = max(1, int(round(dur / (OTTAVO / 4.0))))
        for c in range(colpi):
            tt = t0 + c * (OTTAVO / 4.0)
            forza = 0.55 + 0.45 * (1.0 if c % 4 == 0 else 0.6) * rng.uniform(0.85, 1.0)
            y = corda_c(f, 0.22, 0.35, 0.994) + 0.7 * corda_c(f * 1.004, 0.22, 0.35, 0.994)
            metti(tt, y * forza * 0.30, 0.75, 0.45)

    # Chitarra e basso: oom-pa-pa, oom-pa-pa.
    for b, acc in enumerate(ACCORDI):
        t0 = b * BATTUTA
        b1, b2 = BASSI[acc]
        metti(t0, corda_c(hz(b1), 0.5, 0.2, 0.997) * 0.55, 0.6, 0.6)
        metti(t0 + 3 * OTTAVO, corda_c(hz(b2), 0.5, 0.2, 0.997) * 0.5, 0.6, 0.6)
        for k in (1, 2, 4, 5):
            y = np.zeros(int(0.3 * SR))
            for nota in TRIADI[acc]:
                y += corda_c(hz(nota), 0.3, 0.5, 0.99)
            metti(t0 + k * OTTAVO + 0.004, y * (0.16 if k in (1, 4) else 0.12), 0.4, 0.8)

    # 'A tammorra: sonagli su ogni ottavo, accento sull'uno e sul quattro,
    # e 'o colpo 'e mano (pelle) sull'uno.
    sonaglio = np.zeros(int(0.12 * SR))
    ts = np.arange(len(sonaglio)) / SR
    for fr in (6900, 7700, 8600, 9900):
        sonaglio += np.sin(2 * np.pi * fr * ts + rng.random() * 6) * np.exp(-ts / 0.05)
    sonaglio += passa_banda(rng.standard_normal(len(ts)), 5000, 12000) * np.exp(-ts / 0.03) * 2.5
    sonaglio = normalizza(sonaglio, 1.0)
    pelle = np.sin(2 * np.pi * 110 * ts * (1 - ts * 2)) * np.exp(-ts / 0.06)
    for b in range(32):
        for k in range(6):
            t0 = b * BATTUTA + k * OTTAVO
            forte = k in (0, 3)
            metti(t0, sonaglio * (0.11 if forte else 0.055), 0.55, 0.65)
            if k == 0:
                metti(t0, pelle * 0.35, 0.6, 0.6)

    # Il giro: la coda che sborda oltre le 32 battute si rimette in testa,
    # così il loop non ha lo scalino.
    fine = int(lungo * SR)
    L[:n - fine] += L[fine:]
    R[:n - fine] += R[fine:]
    L = L[:fine]
    R = R[:fine]
    picco = max(np.max(np.abs(L)), np.max(np.abs(R))) + 1e-9
    return L * (0.89 / picco), R * (0.89 / picco)


if __name__ == "__main__":
    scrivi_ogg("audio/pennellata.ogg", pennellata())
    scrivi_ogg("audio/tic.ogg", legnetto(1850.0))
    scrivi_ogg("audio/tac.ogg", legnetto(1320.0))
    scrivi_ogg("audio/gong_sfida.ogg", campana())
    L, R = tarantella()
    scrivi_ogg("audio/musica/sfida.ogg", None, stereo=(L, R), qualita=5)
