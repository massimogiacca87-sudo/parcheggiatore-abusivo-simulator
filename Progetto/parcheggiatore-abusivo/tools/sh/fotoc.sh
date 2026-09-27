#!/bin/bash
# uso: /tmp/fotoc.sh foto_x [secondi] — gira nella copia /home/claude/copia3 (xvfb, 1280x760)
SRC=/home/claude/parcheggiatore-abusivo
C=/home/claude/copia3
if [ "$FRESCA" = "1" ] || [ ! -d $C ]; then rm -rf $C && cp -a $SRC $C || exit 1; else rsync -a --delete --exclude .git --exclude "scripts/_prova_*" --exclude "scripts/_foto_*" --exclude "scripts/_sonda_*" $SRC/ $C/ ; fi
cd $C || exit 1
P="$1"; T="${2:-120}"
cp project.godot /tmp/pgf.bak
cp tools/$P.gd scripts/_$P.gd
python3 - "$P" <<'PY'
import sys, io
p = sys.argv[1]
s = io.open("project.godot", encoding="utf-8").read()
s = s.replace('SoundManager="*res://scripts/autoload/sound_manager.gd"',
              'SoundManager="*res://scripts/autoload/sound_manager.gd"\nFoto="*res://scripts/_%s.gd"' % p)
io.open("project.godot", "w", encoding="utf-8").write(s)
PY
timeout $T xvfb-run -a -s "-screen 0 1280x760x24" /home/claude/godot4 --path . \
  --rendering-driver opengl3 --resolution 1280x760 > /tmp/out_$P.txt 2>&1
cp /tmp/pgf.bak project.godot
rm -f scripts/_$P.gd
