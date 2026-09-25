#!/usr/bin/env python3
"""Ricostruisce file .ogg dalle pagine di pacchetti che Godot conserva in
AudioStreamOggVorbis.packet_sequence (dump JSON fatto da converti.gd).

Pagina Ogg: "OggS" | ver 0 | flag | granule i64 | serial u32 | seq u32
            | crc u32 | n segmenti u8 | tabella segmenti | dati
CRC: polinomio 0x04C11DB7, non riflesso, init 0, niente xor finale,
calcolato sulla pagina intera col campo crc a zero.
"""
import base64, json, os, struct, sys

TAB = []
for i in range(256):
    r = i << 24
    for _ in range(8):
        r = ((r << 1) ^ 0x04C11DB7) if (r & 0x80000000) else (r << 1)
    TAB.append(r & 0xFFFFFFFF)

def crc(b):
    c = 0
    for x in b:
        c = ((c << 8) & 0xFFFFFFFF) ^ TAB[((c >> 24) & 0xFF) ^ x]
    return c

def lacing(n):
    s = [255] * (n // 255)
    s.append(n % 255)
    return s

def pagina(flag, gran, serial, seq, segs, dati):
    h = b"OggS" + struct.pack("<BBqIII", 0, flag, gran, serial, seq, 0)
    h += struct.pack("<B", len(segs)) + bytes(segs)
    p = bytearray(h + dati)
    struct.pack_into("<I", p, 22, crc(p))
    return bytes(p)

def muxa(dump, out):
    serial = 0x50415300  # "PAS"
    seq = 0
    pagine = [pg for pg in dump["pagine"] if pg["p"]]
    uscita = bytearray()
    for ip, pg in enumerate(pagine):
        pacchetti = [base64.b64decode(x) for x in pg["p"]]
        # Segmenti di tutta la pagina originale, con dove finisce ogni pacchetto.
        segs, dati = [], bytearray()
        for pk in pacchetti:
            segs += lacing(len(pk))
            dati += pk
        # Se sfora i 255 segmenti si spezza in più pagine con il flag di
        # continuazione (in pratica non succede: Godot tiene le pagine
        # originali, ma meglio non romperlo).
        pos_seg, pos_dati = 0, 0
        prima = True
        continua = False
        while pos_seg < len(segs):
            chunk = segs[pos_seg:pos_seg + 255]
            n_byte = sum(chunk)
            ultimo = pos_seg + len(chunk) >= len(segs)
            flag = 0
            if continua:
                flag |= 0x01
            if ip == 0 and prima:
                flag |= 0x02
            if ip == len(pagine) - 1 and ultimo:
                flag |= 0x04
            gran = pg["g"] if ultimo else -1
            uscita += pagina(flag, gran, serial, seq,
                             chunk, bytes(dati[pos_dati:pos_dati + n_byte]))
            seq += 1
            # Il pacchetto continua sulla pagina dopo se l'ultimo segmento
            # di questo pezzo vale 255.
            continua = (chunk[-1] == 255)
            pos_seg += len(chunk)
            pos_dati += n_byte
            prima = False
    open(out, "wb").write(uscita)

def main(radice):
    n = 0
    for dirpath, _, files in os.walk(radice):
        for f in files:
            if f.endswith(".dump.json"):
                p = os.path.join(dirpath, f)
                d = json.load(open(p))
                ogg = p[:-len(".dump.json")]
                muxa(d, ogg)
                imp = "[remap]\n\nimporter=\"oggvorbisstr\"\ntype=\"AudioStreamOggVorbis\"\n"
                if d.get("uid"):
                    imp += "uid=\"%s\"\n" % d["uid"]
                imp += "\n[params]\n\nloop=%s\nloop_offset=%s\n" % (
                    "true" if d["loop"] else "false", d["loop_offset"])
                open(ogg + ".import", "w").write(imp)
                os.remove(p)
                n += 1
    print("ogg ricostruiti:", n)

if __name__ == "__main__":
    main(sys.argv[1])
