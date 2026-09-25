const { chromium } = require('/home/claude/.npm-global/lib/node_modules/playwright');

const ok = (b) => (b ? 'SÌ' : 'NO');

(async () => {
  const browser = await chromium.launch({
    headless: true,
    args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader',
           '--disable-gpu-sandbox', '--no-sandbox'],
  });
  const page = await browser.newPage({ viewport: { width: 700, height: 440 } });
  const righe = [];
  page.on('console', m => { if (m.type() === 'log') righe.push(m.text()); });
  await page.goto('http://127.0.0.1:8766/index.html',
    { waitUntil: 'domcontentloaded', timeout: 90000 });

  // Si aspetta che Godot sia partito davvero.
  for (let t = 0; t < 40; t++) {
    await page.waitForTimeout(1000);
    if (righe.some(r => r.includes('doppo _ready()'))) break;
  }

  const primma = await page.evaluate(() => document.pointerLockElement !== null);
  console.log("1) 'a richiesta 'e dint'ô _ready(), senza gesto  -> lock: " + ok(primma));

  const box = await page.locator('canvas').boundingBox();
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  await page.waitForTimeout(2500);
  const doppo = await page.evaluate(() => document.pointerLockElement !== null);
  console.log("2) 'a richiesta 'e dint'ô click                  -> lock: " + ok(doppo));

  // E che il movimento arrivi davvero come relativo (è quello che gira la
  // testa): col lock, `movementX` non è zero.
  let movimento = 0;
  if (doppo) {
    await page.evaluate(() => {
      window.__mov = 0;
      document.addEventListener('mousemove', e => {
        window.__mov += Math.abs(e.movementX || 0);
      });
    });
    for (let k = 0; k < 15; k++) {
      await page.mouse.move(box.x + box.width / 2 + 30 * (k % 2 ? 1 : -1),
                            box.y + box.height / 2);
      await page.waitForTimeout(80);
    }
    movimento = await page.evaluate(() => window.__mov || 0);
  }
  console.log('3) movimento relativo arrivato (movementX)      -> ' + movimento + ' px');

  console.log('');
  console.log('quello che ha stampato il gioco:');
  righe.filter(r => r.includes('mouse_mode')).forEach(r => console.log('   ' + r));

  await page.screenshot({ path: '/tmp/mini_lock.png' });
  await browser.close();
  // **'O giudizio 'o dà Godot, no `pointerLockElement`.** In headless
  // Chromium quella proprietà risponde "sì" pure prima del click, e non
  // è quello che guarda il gioco: `player_fps` fa girare la testa solo se
  // `Input.get_mouse_mode() == CAPTURED`. Quindi si legge quello — ed è
  // anche il numero che fa vedere il bug in faccia.
  const dopo_ready = righe.find(r => r.includes('doppo _ready()')) || '';
  const dopo_click = righe.find(r => r.includes("doppo 'o click")) || '';
  const ready_preso = dopo_ready.includes('mouse_mode = 2');
  const click_preso = dopo_click.includes('mouse_mode = 2');
  console.log('');
  console.log("4) Godot doppo _ready(): pigliato? " + ok(ready_preso)
    + "   (chisto era 'o guaio)");
  console.log('5) Godot doppo \'o click:  pigliato? ' + ok(click_preso)
    + '   (chesta è \'a cura)');
  const bene = !ready_preso && click_preso && movimento > 0;
  console.log('');
  console.log(bene ? '=== storte: 0 ===' : '=== storte: 1 ===');
  process.exit(bene ? 0 : 1);
})().catch(e => { console.log('CRASH ' + e.message.slice(0, 200)); process.exit(2); });
