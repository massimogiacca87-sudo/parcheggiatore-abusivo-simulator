// **'A build web ncopp'ô browser overo** (0.62, asset esterni).
//
// Apre build/web (servita da serve_build.py) in Chromium senza finestra,
// raccoglie tutta la console per SECONDI secondi, clicca «Accummenciamo»
// a metà, e fa due fotografie. Serve a vedere quello che nessuna prova
// GDScript vede: se la libreria di LimboAI (che il web senza «dlink» non
// sa caricare) o l'autoload di Dialogic rompono l'avvio nel browser.
// Uso: node tools/web/prova_build_web.js  → /tmp/web_*.png, riassunto a video.
const { chromium } = require('/home/claude/.npm-global/lib/node_modules/playwright');
const SECONDI = parseInt(process.env.SECONDI || '150');
(async () => {
  const browser = await chromium.launch({
    headless: true,
    args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader',
           '--disable-gpu-sandbox', '--no-sandbox', '--ignore-gpu-blocklist'],
  });
  const page = await browser.newPage({ viewport: { width: 1152, height: 648 } });
  const righe = [];
  const t0 = Date.now();
  const scrivi = (r) => { righe.push(r); console.log(((Date.now() - t0) / 1000).toFixed(0).padStart(4) + 's ' + r.slice(0, 240)); };
  page.on('console', m => scrivi('[' + m.type() + '] ' + m.text()));
  page.on('pageerror', e => scrivi('[pageerror] ' + e.message));
  page.on('crash', () => scrivi('[crash] la pagina è morta (memoria? SwiftShader?)'));
  await page.goto('http://127.0.0.1:' + (process.env.PORTA || '8767') + '/index.html',
    { waitUntil: 'domcontentloaded', timeout: 120000 });
  for (let t = 0; t < SECONDI; t += 5) {
    try { await page.waitForTimeout(5000); } catch (e) { scrivi('[fine] ' + e.message); break; }
    if (t % 30 === 0) {
      try { await page.screenshot({ path: '/tmp/web_' + String(t).padStart(3, '0') + '.png' }); } catch (e) {}
    }
    if (t === Math.floor(SECONDI / 2 / 5) * 5) {
      await page.screenshot({ path: '/tmp/web_meta.png' });
      const box = await page.locator('canvas').boundingBox();
      if (box) await page.mouse.click(box.x + box.width / 2, box.y + box.height * 0.8);
    }
  }
  try { await page.screenshot({ path: '/tmp/web_fine.png' }); } catch (e) {}
  const brutte = righe.filter(r => /error|ERROR|SCRIPT|limbo|GDExtension|dynamic/i.test(r));
  console.log('righe di console: ' + righe.length + ', con errori: ' + brutte.length);
  for (const r of brutte.slice(0, 40)) console.log('  ' + r.slice(0, 300));
  console.log('--- ultime 15 righe ---');
  for (const r of righe.slice(-15)) console.log('  ' + r.slice(0, 200));
  try { await browser.close(); } catch (e) {}
})();
