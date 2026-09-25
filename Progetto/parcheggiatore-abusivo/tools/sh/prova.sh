#!/bin/bash
# uso: /tmp/prova.sh nome_prova [secondi]
cd /home/claude/parcheggiatore-abusivo
P="$1"; T="${2:-90}"
cp project.godot /tmp/pg.bak
cp tools/$P.gd scripts/_$P.gd
python3 - "$P" <<'PY'
import sys, io
p = sys.argv[1]
s = io.open("project.godot", encoding="utf-8").read()
s = s.replace('SoundManager="*res://scripts/autoload/sound_manager.gd"',
              'SoundManager="*res://scripts/autoload/sound_manager.gd"\nProva="*res://scripts/_%s.gd"' % p)
io.open("project.godot", "w", encoding="utf-8").write(s)
PY
timeout $T /home/claude/godot4 --headless --path . > /tmp/out_$P.txt 2>&1
cp /tmp/pg.bak project.godot
rm -f scripts/_$P.gd
