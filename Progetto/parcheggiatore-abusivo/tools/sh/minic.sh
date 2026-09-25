#!/bin/bash
# uso: /tmp/minic.sh prova1 prova2 ... → /tmp/minic.txt (gira su una copia fotografata adesso)
rm -rf /home/claude/copia && cp -a /home/claude/parcheggiatore-abusivo /home/claude/copia || exit 1
: > /tmp/minic.txt
for p in "$@"; do
  t=260
  case $p in prova_furto|prova_mure|prova_giurnate|prova_signora|prova_lotto|prova_partite|prova_borrelli|prova_guagliune_vere|prova_perzone_nove) t=420;; esac
  /tmp/provac.sh $p $t >/dev/null 2>&1
  r=$(grep -aE "storte|raggi so' scappate|=== fernuto" /tmp/outc_$p.txt | tail -1)
  e=$(grep -ac "SCRIPT ERROR" /tmp/outc_$p.txt)
  cp /tmp/outc_$p.txt /tmp/outc_${p}_$(date +%s).txt
  printf "%-22s %s  [SCRIPT ERROR: %s]\n" "$p" "${r:-(nisciun risultato)}" "$e" >> /tmp/minic.txt
done
echo "=== FERNUTA ===" >> /tmp/minic.txt
