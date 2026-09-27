#!/bin/bash
# Tutte le prove su una copia, così il progetto resta libero per le
# fotografie. Scrive /tmp/batteriac.txt.
#
# (0.64) Si può spezzare in due metà che girano insieme sui due processori
# del contenitore:  PARTE=1 nohup /tmp/batteriac.sh &   PARTE=2 nohup /tmp/batteriac.sh &
# (ognuna sulla sua copia, /home/claude/copia2_<parte>, e col suo
# /tmp/batteriac_<parte>.txt). Senza PARTE gira tutto, come prima.
# prova_dieci_giornate sta fuori: gioca dieci giornate e va lanciata a
# parte (VELOCE=20 /tmp/runc.sh copiaA prova_dieci_giornate 2400).
PARTE="${PARTE:-}"
C=/home/claude/copia2${PARTE:+_$PARTE}
OUT=/tmp/batteriac${PARTE:+_$PARTE}.txt
rm -rf $C && cp -a /home/claude/parcheggiatore-abusivo $C || exit 1
cd $C || exit 1
: > $OUT
i=0
for f in tools/prova_*.gd; do
  p=$(basename $f .gd)
  [ "$p" = "prova_scopa" ] && continue
  [ "$p" = "prova_dieci_giornate" ] && continue
  i=$((i + 1))
  if [ -n "$PARTE" ]; then
    [ $(( (i + PARTE) % 2 )) -ne 0 ] && continue
  fi
  t=240
  case $p in prova_furto|prova_mure|prova_giurnate|prova_signora|prova_lotto|prova_partite|prova_borrelli|prova_guagliune_vere|prova_perzone_nove|prova_strisce_blu|prova_borrelli_gioca) t=420;; esac
  case $p in prova_conquista|prova_re_parcheggi) t=720;; esac
  cp project.godot /tmp/pgc2${PARTE}.bak
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
  cp /tmp/pgc2${PARTE}.bak project.godot
  rm -f scripts/_$p.gd
  r=$(grep -aE "storte|raggi so' scappate|=== fernuto" /tmp/outb_$p.txt | tail -1)
  e=$(grep -ac "SCRIPT ERROR" /tmp/outb_$p.txt)
  printf "%-22s %s  [SCRIPT ERROR: %s]\n" "$p" "${r:-(nisciun risultato)}" "$e" >> $OUT
done
if [ -z "$PARTE" ] || [ "$PARTE" = "2" ]; then
  timeout 200 /home/claude/godot4 --headless --path . --script res://tools/prova_scopa.gd > /tmp/outb_prova_scopa.txt 2>&1
  r=$(grep -aE "storte" /tmp/outb_prova_scopa.txt | tail -1)
  printf "%-22s %s\n" "prova_scopa" "${r:-(nisciun risultato)}" >> $OUT
fi
echo "=== FERNUTA ===" >> $OUT
