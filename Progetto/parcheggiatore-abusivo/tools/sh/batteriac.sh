#!/bin/bash
# Tutte le prove su una copia (/home/claude/copia2), così il progetto resta
# libero per le fotografie. Scrive /tmp/batteriac.txt.
rm -rf /home/claude/copia2 && cp -a /home/claude/parcheggiatore-abusivo /home/claude/copia2 || exit 1
cd /home/claude/copia2 || exit 1
: > /tmp/batteriac.txt
for f in tools/prova_*.gd; do
  p=$(basename $f .gd)
  [ "$p" = "prova_scopa" ] && continue
  t=240
  case $p in prova_furto|prova_mure|prova_giurnate|prova_signora|prova_lotto|prova_partite|prova_borrelli|prova_guagliune_vere|prova_perzone_nove) t=420;; esac
  cp project.godot /tmp/pgc2.bak
  cp tools/$p.gd scripts/_$p.gd
  python3 - "$p" <<'PY'
import sys, io
p = sys.argv[1]
s = io.open("project.godot", encoding="utf-8").read()
s = s.replace('SoundManager="*res://scripts/autoload/sound_manager.gd"',
              'SoundManager="*res://scripts/autoload/sound_manager.gd"\nProva="*res://scripts/_%s.gd"' % p)
io.open("project.godot", "w", encoding="utf-8").write(s)
PY
  if [ "$p" = "prova_vascio_fondale" ]; then
    timeout $t xvfb-run -a -s "-screen 0 1280x760x24" /home/claude/godot4 --path . --rendering-driver opengl3 --resolution 640x380 > /tmp/outb_$p.txt 2>&1
  else
    timeout $t /home/claude/godot4 --headless --path . > /tmp/outb_$p.txt 2>&1
  fi
  cp /tmp/pgc2.bak project.godot
  rm -f scripts/_$p.gd
  r=$(grep -aE "storte|raggi so' scappate|=== fernuto" /tmp/outb_$p.txt | tail -1)
  e=$(grep -ac "SCRIPT ERROR" /tmp/outb_$p.txt)
  printf "%-22s %s  [SCRIPT ERROR: %s]\n" "$p" "${r:-(nisciun risultato)}" "$e" >> /tmp/batteriac.txt
done
timeout 200 /home/claude/godot4 --headless --path . --script res://tools/prova_scopa.gd > /tmp/outb_prova_scopa.txt 2>&1
r=$(grep -aE "storte" /tmp/outb_prova_scopa.txt | tail -1)
printf "%-22s %s\n" "prova_scopa" "${r:-(nisciun risultato)}" >> /tmp/batteriac.txt
echo "=== FERNUTA ===" >> /tmp/batteriac.txt
