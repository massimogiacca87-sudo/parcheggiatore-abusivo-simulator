#!/bin/bash
# uso: /tmp/provac.sh nome_prova [secondi]  — gira nella copia /home/claude/copia
cd /home/claude/copia || exit 1
P="$1"; T="${2:-90}"
cp project.godot /tmp/pgc.bak
cp tools/$P.gd scripts/_$P.gd
python3 - "$P" <<'PY'
import sys, io
p = sys.argv[1]
s = io.open("project.godot", encoding="utf-8").read()
s = s.replace('SoundManager="*res://scripts/autoload/sound_manager.gd"',
              'SoundManager="*res://scripts/autoload/sound_manager.gd"\nProva="*res://scripts/_%s.gd"' % p)
io.open("project.godot", "w", encoding="utf-8").write(s)
PY
if [ "$P" = "prova_vascio_fondale" ]; then
  timeout $T xvfb-run -a -s "-screen 0 1280x760x24" /home/claude/godot4 --path . --rendering-driver opengl3 --resolution 640x380 > /tmp/outc_$P.txt 2>&1
else
  timeout $T /home/claude/godot4 --headless --path . > /tmp/outc_$P.txt 2>&1
fi
cp /tmp/pgc.bak project.godot
rm -f scripts/_$P.gd
