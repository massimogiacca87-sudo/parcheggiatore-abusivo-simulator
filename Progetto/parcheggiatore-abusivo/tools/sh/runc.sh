#!/bin/bash
# uso: /tmp/runc.sh nome_copia prova [secondi] — headless, su /home/claude/<nome_copia>
# sincronizzata col progetto (così più prove girano insieme senza pestarsi).
# VELOCE=20 → --fixed-fps 20: tre passi di fisica per fotogramma e niente
# attesa del tempo vero (circa 3,5 volte il vero nella città headless).
# Uscita in /tmp/outr_<prova>.txt.
SRC=/home/claude/parcheggiatore-abusivo
C=/home/claude/$1
mkdir -p $C
rsync -a --delete --exclude .git --exclude 'scripts/_prova_*' --exclude 'scripts/_foto_*' --exclude 'scripts/_sonda_*' $SRC/ $C/
python3 - $C/project.godot <<'PY'
import sys,io
p=sys.argv[1]; s=io.open(p,encoding='utf-8').read()
s='\n'.join(l for l in s.split('\n') if not (l.startswith('Prova=') or l.startswith('Foto=')))
io.open(p,'w',encoding='utf-8').write(s)
PY
cd $C || exit 1
P="$2"; T="${3:-120}"
cp tools/$P.gd scripts/_$P.gd
python3 - "$P" <<'PY'
import sys, io
p = sys.argv[1]
s = io.open("project.godot", encoding="utf-8").read()
s = s.replace('SoundManager="*res://scripts/autoload/sound_manager.gd"',
              'SoundManager="*res://scripts/autoload/sound_manager.gd"\nProva="*res://scripts/_%s.gd"' % p)
io.open("project.godot", "w", encoding="utf-8").write(s)
PY
EXTRA=""
[ -n "$VELOCE" ] && EXTRA="--fixed-fps $VELOCE"
timeout $T /home/claude/godot4 --headless --path . $EXTRA > /tmp/outr_$P.txt 2>&1
rm -f scripts/_$P.gd
python3 - project.godot <<'PY'
import sys,io
p=sys.argv[1]; s=io.open(p,encoding='utf-8').read()
s='\n'.join(l for l in s.split('\n') if not (l.startswith('Prova=') or l.startswith('Foto=')))
io.open(p,'w',encoding='utf-8').write(s)
PY
