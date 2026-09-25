#!/bin/bash
# Tutte le prove, una dopo l'altra. Scrive /tmp/batteria.txt.
cd /home/claude/parcheggiatore-abusivo
: > /tmp/batteria.txt
for f in tools/prova_*.gd; do
  p=$(basename $f .gd)
  [ "$p" = "prova_scopa" ] && continue
  t=240
  case $p in prova_furto|prova_mure|prova_giurnate|prova_signora|prova_lotto|prova_partite|prova_borrelli|prova_guagliune_vere|prova_perzone_nove) t=420;; esac
  /tmp/prova.sh $p $t >/dev/null 2>&1
  r=$(grep -aE "storte|raggi so' scappate|=== fernuto" /tmp/out_$p.txt | tail -1)
  e=$(grep -ac "SCRIPT ERROR" /tmp/out_$p.txt)
  printf "%-22s %s  [SCRIPT ERROR: %s]\n" "$p" "${r:-(nisciun risultato)}" "$e" >> /tmp/batteria.txt
done
# 'a scopa è 'n'eccezione: SceneTree, se fa girà cu --script
timeout 200 /home/claude/godot4 --headless --path . --script res://tools/prova_scopa.gd > /tmp/out_prova_scopa.txt 2>&1
r=$(grep -aE "storte" /tmp/out_prova_scopa.txt | tail -1)
printf "%-22s %s\n" "prova_scopa" "${r:-(nisciun risultato)}" >> /tmp/batteria.txt
echo "=== FERNUTA ===" >> /tmp/batteria.txt
