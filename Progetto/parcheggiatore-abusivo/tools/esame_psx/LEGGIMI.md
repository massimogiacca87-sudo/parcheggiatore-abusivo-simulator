# Il progettino per esaminare i modelli PSX (0.60)

Non fa parte del gioco: è il banco di lavoro con cui la 0.60 ha scelto,
misurato e orientato i cinquantotto modelli nuovi del PSX Mega Pack prima di
copiarli in `assets/models/`.

Per rifarlo:

```bash
mkdir -p /home/claude/esame_psx/psx
cp tools/esame_psx/project.godot.txt /home/claude/esame_psx/project.godot
cp tools/esame_psx/*.gd /home/claude/esame_psx/
# copiare in /home/claude/esame_psx/psx/ i .glb (con le loro texture) presi
# dal pacchetto del capo, poi:
cd /home/claude/esame_psx && /home/claude/godot4 --headless --path . --import
```

- `misura.gd` — `godot4 --headless --path . --script misura.gd`: per ogni
  `.glb` in `psx/` stampa l'ingombro (x, y, z), il centro e i triangoli. Il
  pacchetto è **1,52 volte il vero** (vedi `prova_psx`): una sedia deve
  venire alta un metro.
- `foglio.gd` — con xvfb: il foglio dei provini, tutti i modelli in fila
  con il nome, in `/tmp/psx_foglio_N.png`. Serve a **guardarli prima di
  usarli** (trappola 34: il nome non è la cosa).
- `verso.gd`, `verso2.gd` — con xvfb: una fila di modelli con una freccia
  che indica il +Z, per sapere da che parte hanno il davanti
  (`/tmp/psx_verso*.png`). Nel PSX è quasi sempre +Z, ma molti hanno
  l'origine fuori centro: per quelli in città si usa `_panda_c`.
