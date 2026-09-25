#!/usr/bin/env python3
"""Genera proceduralmente tutti gli effetti sonori e la musica del gioco.
Output: ../audio/*.wav (22050 Hz, 16 bit, mono). Solo stdlib."""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
random.seed(42)


def save(name, samples):
    samples = [max(-1.0, min(1.0, s)) for s in samples]
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(s * 32000)) for s in samples))
    print(name, len(samples) / SR, "s")


def env(i, n, attack=0.01, release=0.3):
    t = i / n
    a = min(1.0, (i / SR) / max(attack, 1e-5))
    r = min(1.0, (1.0 - t) / max(release, 1e-5))
    return a * min(1.0, r)


def tone(freq, dur, kind="sine", vol=0.8, release=0.5, vib=0.0, vib_hz=6.0):
    n = int(SR * dur)
    out = []
    phase = 0.0
    for i in range(n):
        f = freq * (1.0 + vib * math.sin(2 * math.pi * vib_hz * i / SR))
        phase += 2 * math.pi * f / SR
        if kind == "sine":
            s = math.sin(phase)
        elif kind == "square":
            s = 1.0 if math.sin(phase) > 0 else -1.0
        elif kind == "saw":
            s = 2.0 * ((phase / (2 * math.pi)) % 1.0) - 1.0
        out.append(s * vol * env(i, n, release=release))
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] if i < len(t) else 0.0 for t in tracks) for i in range(n)]


def noise(dur, vol=0.8, lowpass=0.2, release=0.4):
    n = int(SR * dur)
    out = []
    prev = 0.0
    for i in range(n):
        prev += lowpass * (random.uniform(-1, 1) - prev)
        out.append(prev * vol * env(i, n, release=release))
    return out


def pluck(freq, dur, vol=0.6):
    """Karplus-Strong: corda pizzicata."""
    n = int(SR * dur)
    buf_len = max(2, int(SR / freq))
    buf = [random.uniform(-1, 1) for _ in range(buf_len)]
    out = []
    idx = 0
    for i in range(n):
        cur = buf[idx]
        nxt = buf[(idx + 1) % buf_len]
        buf[idx] = 0.996 * 0.5 * (cur + nxt)
        idx = (idx + 1) % buf_len
        out.append(cur * vol * min(1.0, (n - i) / (SR * 0.05)))
    return out


os.makedirs(OUT, exist_ok=True)

# Clacson: bitonale, un po' sguaiato
save("honk", mix(tone(392, 0.3, "sine", 0.16, 0.35, vib=0.01, vib_hz=8),
                 tone(494, 0.3, "sine", 0.13, 0.35, vib=0.01, vib_hz=8)))

# Urto: botto sordo + ferraglia
save("bump", mix(tone(70, 0.22, "sine", 0.5, 0.8),
                 noise(0.14, 0.22, 0.4, 0.7)))

# Pugno: thud secco
save("punch", mix(tone(85, 0.13, "sine", 0.55, 0.9),
                  noise(0.04, 0.3, 0.6, 0.9)))

# Moneta: ding ding brillante
coin = tone(1319, 0.1, "sine", 0.28, 0.6) + tone(1760, 0.16, "sine", 0.26, 0.5)
save("coin", coin)

# Registratore di cassa: KA-CHING
save("kaching", noise(0.04, 0.3, 0.8, 0.9) + mix(tone(1568, 0.26, "sine", 0.24, 0.4),
                                                 tone(2093, 0.26, "sine", 0.2, 0.4)))

# Parcheggio riuscito: tre note in su
save("success", pluck(659, 0.14, 0.4) + pluck(880, 0.14, 0.4) + pluck(1047, 0.3, 0.45))

# Fallimento / rifiuto: due note in giù, sgangherate
save("fail", tone(415, 0.16, "sine", 0.22, 0.35) + tone(311, 0.3, "sine", 0.24, 0.45))

# Fischietto del vigile: trillo
save("whistle", tone(1750, 0.4, "sine", 0.3, 0.35, vib=0.05, vib_hz=18))

# Furto: zip veloce verso l'alto
n = int(SR * 0.16)
steal = []
ph = 0.0
for i in range(n):
    f = 700 + 2000 * (i / n)
    ph += 2 * math.pi * f / SR
    steal.append(math.sin(ph) * 0.3 * env(i, n, release=0.3))
save("steal", steal)

# "Pop" del gesto gridato: colpetto di ottoni
save("pop", mix(tone(523, 0.09, "sine", 0.2, 0.5), tone(659, 0.09, "sine", 0.14, 0.5)))

# Portiera: clack
save("door", mix(tone(150, 0.1, "sine", 0.45, 0.9), noise(0.05, 0.22, 0.55, 0.9)))

# Motore che riparte: brontolio in salita
n = int(SR * 0.4)
rev = []
ph = 0.0
for i in range(n):
    f = 85 + 70 * (i / n)
    ph += 2 * math.pi * f / SR
    s = 2.0 * ((ph / (2 * math.pi)) % 1.0) - 1.0
    rev.append(s * 0.16 * env(i, n, release=0.4))
save("rev", rev)

# Miao del gatto
n = int(SR * 0.35)
meow = []
ph = 0.0
for i in range(n):
    t = i / n
    f = 750 - 250 * t + 60 * math.sin(2 * math.pi * 9 * t)
    ph += 2 * math.pi * f / SR
    meow.append(math.sin(ph) * 0.22 * env(i, n, attack=0.04, release=0.35))
save("meow", meow)

# Musica: giro pizzicato in La minore, aria da quartiere (loop)
NOTE = {"A3": 220.0, "B3": 246.9, "C4": 261.6, "D4": 293.7, "E4": 329.6,
        "F4": 349.2, "G4": 392.0, "A4": 440.0, "B4": 493.9, "C5": 523.3,
        "D5": 587.3, "E5": 659.3, "A2": 110.0, "E3": 164.8, "G3": 196.0, "F3": 174.6}
melody = ["A4", "C5", "E5", "D5", "C5", "B4", "A4", "B4", "C5", "B4", "A4", "G4",
          "A4", "C5", "E5", "D5", "C5", "B4", "C5", "D5", "E5", "D5", "C5", "B4",
          "A4", "E4", "A4", "C5", "B4", "A4", "G4", "B4", "D5", "C5", "B4", "A4",
          "A4", "C5", "B4", "G4", "A4", "B4", "C5", "B4", "A4", "G4", "E4", "A4"]
bass_seq = ["A2", "E3", "A2", "E3", "F3", "G3", "A2", "E3",
            "A2", "E3", "F3", "G3", "A2", "E3", "G3", "A2"]
STEP = 0.165
total = int(SR * STEP * len(melody)) + int(SR * 0.5)
music = [0.0] * total
for i, name in enumerate(melody):
    p = pluck(NOTE[name], 0.45, 0.20)
    start = int(SR * STEP * i)
    for j, s in enumerate(p):
        if start + j < total:
            music[start + j] += s
for i, name in enumerate(bass_seq):
    p = pluck(NOTE[name], 0.6, 0.20)
    start = int(SR * STEP * 3 * i)
    for j, s in enumerate(p):
        if start + j < total:
            music[start + j] += s
# eco leggera
delay = int(SR * 0.22)
for i in range(delay, total):
    music[i] += music[i - delay] * 0.22
loop_len = int(SR * STEP * len(melody))
save("music", music[:loop_len])
print("done")
