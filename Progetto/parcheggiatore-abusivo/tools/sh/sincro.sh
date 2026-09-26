#!/bin/bash
# Prepara le patch dei commit nuovi (dal tag pc_sync) per il repo sul PC.
#
# (0.62, asset esterni) Il repo del capo ha `core.autocrlf=true`: dentro a
# Git i file stanno con gli a-capo LF, nella cartella alcuni hanno CRLF
# (quelli che Git ha scritto). Il contenitore parte dal tar della cartella,
# quindi qui certi .gd hanno CRLF: una patch fatta così non combacia con
# quello che c'è nel repo del PC, e se un attrezzo riscrive il file in LF la
# patch diventa «tutto il file tolto e rimesso». Per questo le patch si
# fanno su una copia in cui, in TUTTI i commit (base compresa), i file di
# testo toccati sono portati a LF: la stessa forma che ha il repo del PC.
#
# Fuori dalle patch: `.godot/` e i file che sul PC non sono tracciati
# (ESCLUSI qui sotto: si sistemano a mano, per esempio i vecchi
# `assets/models/condizionatore*` si mandano nel Cestino).
#
# Uso: tools/sh/sincro.sh  →  /mnt/user-data/outputs/_claude_tmp/000N-*.patch
set -e
SRC=/home/claude/parcheggiatore-abusivo
TMP=/tmp/sincro_norm
OUT=/mnt/user-data/outputs/_claude_tmp
ESCLUSI=(':!.godot' ':!assets/models/condizionatore*')

cd $SRC
git rev-parse -q --verify pc_sync >/dev/null || { echo "manca il tag pc_sync"; exit 1; }
# I file di testo toccati dai commit nuovi.
git diff --name-only --no-renames pc_sync HEAD -- . "${ESCLUSI[@]}" \
  | grep -E '\.(gd|gdshader|cfg|godot|tres|tscn|import|py|sh|md|txt|json|csv)$' > /tmp/sincro_testi.txt || true

rm -rf $TMP
git clone -q $SRC $TMP
cd $TMP
git tag -f pc_sync $(cd $SRC && git rev-parse pc_sync) >/dev/null
cat > /tmp/sincro_lf.sh <<'EOF'
#!/bin/bash
while read -r f; do
  line=$(git ls-files -s -- "$f")
  [ -z "$line" ] && continue
  mode=${line%% *}; rest=${line#* }; sha=${rest%% *}
  if git cat-file blob $sha | grep -q $'\r'; then
    new=$(git cat-file blob $sha | tr -d '\r' | git hash-object -w --stdin)
    git update-index --cacheinfo $mode,$new,"$f"
  fi
done < /tmp/sincro_testi.txt
EOF
chmod +x /tmp/sincro_lf.sh
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --index-filter /tmp/sincro_lf.sh \
  --tag-name-filter cat -- --all >/dev/null 2>&1
rm -rf $OUT; mkdir -p $OUT
git format-patch --binary --no-renames -o $OUT pc_sync..HEAD -- . "${ESCLUSI[@]}"
echo "patch in $OUT; albero scripts (LF) = $(git rev-parse HEAD:scripts)"
