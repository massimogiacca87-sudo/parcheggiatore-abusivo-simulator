#!/usr/bin/env python3
# Filtro d'indice per sincro.sh (0.62): porta a LF gli a-capo di TUTTI i
# file di testo dell'indice, come li tiene il repo del PC (autocrlf=true).
# Tiene una cache blob → blob normalizzato in /tmp, così ogni commit dopo
# il primo costa poco.
import json, os, subprocess, sys
TESTO = ('.gd', '.gdshader', '.cfg', '.godot', '.tres', '.tscn', '.import',
         '.py', '.sh', '.md', '.txt', '.json', '.csv', '.gdextension', '.svg',
         '.glsl', '.html', '.js', '.gdignore', '.remap', '.ps1', '.bat')
CACHE = '/tmp/sincro_lf_cache.json'
cache = json.load(open(CACHE)) if os.path.exists(CACHE) else {}
righe = subprocess.run(['git', 'ls-files', '-s', '-z'], capture_output=True).stdout.split(b'\0')
nuove = []
for r in righe:
    if not r:
        continue
    meta, path = r.split(b'\t', 1)
    mode, sha, stage = meta.decode().split()
    p = path.decode('utf-8', 'surrogateescape')
    if not p.lower().endswith(TESTO):
        continue
    if sha not in cache:
        b = subprocess.run(['git', 'cat-file', 'blob', sha], capture_output=True).stdout
        if b'\r\n' in b:
            n = subprocess.run(['git', 'hash-object', '-w', '--stdin'],
                               input=b.replace(b'\r\n', b'\n'), capture_output=True).stdout.decode().strip()
            cache[sha] = n
        else:
            cache[sha] = sha
    if cache[sha] != sha:
        nuove.append(f"{mode} {cache[sha]}\t".encode() + path + b'\0')
if nuove:
    subprocess.run(['git', 'update-index', '-z', '--index-info'], input=b''.join(nuove), check=True)
json.dump(cache, open(CACHE, 'w'))
