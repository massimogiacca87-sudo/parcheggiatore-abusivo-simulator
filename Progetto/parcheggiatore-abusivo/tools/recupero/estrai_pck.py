#!/usr/bin/env python3
"""Estrae un .pck di Godot 4 (formato 2) in una cartella.

Serve a ricostruire il progetto quando il container è stato riciclato: gli
asset elaborati (modelli rinominati, root_scale, texture, audio) vivono
solo dentro la build. Il formato è semplice e documentato nei sorgenti di
Godot (core/io/file_access_pack.cpp):

    "GDPC" | u32 versione | u32 maj,min,patch | [v2+: u32 flags, u64 base]
    | 16 × u32 riservati | u32 n_file
    per file: u32 len, path (paddato a 4) | u64 offset | u64 size
              | 16 byte md5 | [v2+: u32 flags]
"""
import os, struct, sys, hashlib

def estrai(pck, dest):
    f = open(pck, "rb")
    assert f.read(4) == b"GDPC", "non è un pck"
    ver, maj, mi, pa = struct.unpack("<4I", f.read(16))
    flags = 0; base = 0
    if ver >= 2:
        flags, = struct.unpack("<I", f.read(4))
        base, = struct.unpack("<Q", f.read(8))
    f.read(16 * 4)
    n, = struct.unpack("<I", f.read(4))
    print("pck v%d, godot %d.%d.%d, flags %d, base %d, %d file" % (ver, maj, mi, pa, flags, base, n))
    voci = []
    for _ in range(n):
        l, = struct.unpack("<I", f.read(4))
        p = f.read(l).rstrip(b"\0").decode("utf-8")
        off, size = struct.unpack("<QQ", f.read(16))
        md5 = f.read(16)
        ff = 0
        if ver >= 2:
            ff, = struct.unpack("<I", f.read(4))
        voci.append((p, off, size, md5, ff))
    male = 0
    for p, off, size, md5, ff in voci:
        rel = p[len("res://"):] if p.startswith("res://") else p
        out = os.path.join(dest, rel)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        f.seek(base + off)
        dati = f.read(size)
        if hashlib.md5(dati).digest() != md5:
            male += 1
        open(out, "wb").write(dati)
    print("estratti %d file, md5 sbagliati: %d" % (len(voci), male))
    return voci

if __name__ == "__main__":
    estrai(sys.argv[1], sys.argv[2])
