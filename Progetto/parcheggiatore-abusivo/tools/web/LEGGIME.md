# 'A prova d''o mouse ncopp'ô browser (0.56b)

Il banco di prova headless non può dire se il mouse funziona su itch.io:
**il browser lì non c'è**. Il Pointer Lock è un patto fra la pagina e
Chrome, e un patto non si prova senza le due parti.

Qui dentro c'è la prova che lo chiede al browser vero. Non gira la città —
la città sotto a swiftshader fa crollare la scheda in tre minuti — gira un
progetto Godot di quattro righe che fa **le due cose che faceva il gioco**:
chiedere il mouse dentro a `_ready()` (come prima) e dentro al manico del
click (come adesso).

```bash
# 1. si esporta il progettino (una volta)
mkdir -p /tmp/mini && cp mini_pointer_lock.gd /tmp/mini/scripts/
#    (project.godot, Main.tscn ed export_presets.cfg: vedi la 0.56b)
godot4 --headless --path /tmp/mini --export-release "Web" /tmp/mini/build/index.html

# 2. si serve con le intestazioni che Godot vuole
python3 serve.py &

# 3. si chiede al browser
node prova_mouse_browser.js
```

Quello che ha stampato, il giorno in cui è stata scritta:

```
doppo _ready(): mouse_mode = 0 (CAPTURED = 2)
doppo 'o click: mouse_mode = 2 (CAPTURED = 2)
movimento relativo arrivato (movementX) -> 10440 px
```

Zero e due. **'O bug e 'a cura, uno sotto a ll'ato.**

Una nota che vale più della prova: `document.pointerLockElement` in Chrome
headless risponde «sì» **pure prima del click**, e se il giudizio si fosse
appoggiato a quello la prova avrebbe detto che andava tutto bene tutte e
due le volte. Il numero giusto da guardare è quello che guarda il gioco —
`Input.get_mouse_mode()` — perché è quello che decide se la testa gira.
