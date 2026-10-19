#!/usr/bin/env node
// Kiểm thử giao diện Phòng thí nghiệm ảo. Cách dùng: node tools/test-labs-ui.js [thư-mục-ảnh]
'use strict';
const fs = require('fs');
const path = require('path');
const { openPage } = require('./lib/browser');
const shotDir = process.argv[2];
if (shotDir) fs.mkdirSync(shotDir, { recursive: true });
let pass = 0, fail = 0;
const check = (c, m) => { c ? pass++ : fail++; console.log(`  ${c ? '✓' : '✗'} ${m}`); };
const shot = async (p, n, full) => { if (shotDir) await p.screenshot({ path: path.join(shotDir, n + '.png'), fullPage: !!full }); };
const num = s => parseFloat(String(s).replace(/\s/g, '').replace(',', '.'));

(async () => {
  const PAGE = 'projects/04-phong-thi-nghiem-ao/index.html';
  const { browser, page, problems } = await openPage(PAGE);
  try {
    console.log('== Khí lí tưởng ==');
    await page.waitForSelector('#gas-read tr');
    await page.waitForTimeout(3500);
    const ratio = num(await page.locator('#gas-read tr:last-child td:last-child').innerText());
    check(Math.abs(ratio - 1) < 0.12, `pS/(NkT) hiển thị ${ratio}`);
    await page.click('#gas-rec');
    await page.locator('#gas-S').evaluate(e => { e.value = 0.6; e.dispatchEvent(new Event('input', { bubbles: true })); });
    await page.waitForTimeout(4000);
    await page.click('#gas-rec');
    const rows = await page.$$eval('#gas-table tr', r => r.slice(1).map(x => [...x.children].map(td => td.textContent)));
    check(rows.length === 2, 'ghi được 2 điểm đo');
    if (rows.length === 2) {
      const pS1 = num(rows[0][4]), pS2 = num(rows[1][4]);
      check(Math.abs(pS1 / pS2 - 1) < 0.12, `Boyle trên giao diện: pS = ${pS1} và ${pS2}`);
      check(num(rows[1][3]) > num(rows[0][3]) * 1.4, 'nén lại thì áp suất tăng');
    }
    await shot(page, 'labs-1-gas', true);

    console.log('\n== Phóng xạ ==');
    await page.click('a[data-tab="decay"]');
    await page.selectOption('#dc-n', '10000');
    await page.locator('#dc-speed').evaluate(e => { e.value = 1; e.dispatchEvent(new Event('input', { bubbles: true })); });
    await page.click('#dc-run');
    await page.waitForTimeout(2600);
    const st = await page.evaluate(() => ({ t: window.Labs.dc.d.t, N: window.Labs.dc.d.N, N0: window.Labs.dc.d.N0 }));
    const theory = Math.pow(2, -st.t);
    check(st.t > 1.5 && Math.abs(st.N / st.N0 - theory) < 0.03, `t = ${st.t.toFixed(2)}T: còn ${(100 * st.N / st.N0).toFixed(1)} % (lý thuyết ${(100 * theory).toFixed(1)} %)`);
    await page.click('[data-rep="100"]');
    check(/trung bình/.test(await page.locator('#rep-out').innerText()), 'đo chu kì bán rã 20 lần có kết quả');
    await shot(page, 'labs-2-decay', true);

    console.log('\n== Lenz ==');
    await page.click('a[data-tab="lenz"]');
    await page.check('#lz-auto');
    await page.waitForTimeout(1500);
    const lzs = await page.evaluate(() => window.Labs.lz.hist.length);
    check(lzs > 30, 'đồ thị Φ, e có dữ liệu');
    // kiểm tra Lenz: đặt nam châm (N hướng vào vòng) đi lại gần → e < 0 → mặt trái thành N, lời giải thích nói "đẩy"
    await page.uncheck('#lz-auto');
    await page.evaluate(() => { const lz = window.Labs.lz; lz.auto = false; lz.x = -4; lz.lastPhi = null; lz.e = 0; });
    for (let i = 0; i < 20; i++) { await page.evaluate(() => { window.Labs.lz.x += 0.08; }); await page.waitForTimeout(30); }
    const say = await page.locator('#lz-say').innerText();
    const eNow = await page.evaluate(() => window.Labs.lz.e);
    check(eNow < 0 && /tăng/.test(say) && /cực N/.test(say) && /đẩy/.test(say), `lại gần: e = ${eNow.toFixed(2)}, "${say.slice(0, 90)}…"`);
    for (let i = 0; i < 20; i++) { await page.evaluate(() => { window.Labs.lz.x -= 0.08; }); await page.waitForTimeout(30); }
    const say2 = await page.locator('#lz-say').innerText();
    check(/giảm/.test(say2) && /hút/.test(say2), 'ra xa: từ thông giảm, vòng dây hút nam châm');
    await shot(page, 'labs-3-lenz', true);

    console.log('\n== Máy phát ==');
    await page.click('a[data-tab="gen"]');
    await page.click('#g-50');
    await page.waitForTimeout(500);
    const g = await page.locator('#g-read').innerText();
    check(/88,8[56]\d V/.test(g), 'N=100, B=0,1 T, S=400 cm², n=50 → E ≈ 88,86 V (khớp câu tu-s4)');
    await shot(page, 'labs-4-gen', true);

    check((await page.locator('.katex-error').count()) === 0, 'KaTeX không lỗi');
    const ctx2 = await page.context().browser().newContext({ viewport: { width: 375, height: 800 } });
    const m = await ctx2.newPage();
    for (const h of ['#gas', '#decay', '#lenz', '#gen']) {
      await m.goto('file://' + path.resolve(PAGE) + h);
      await m.waitForTimeout(600);
      const ov = await m.evaluate(() => document.documentElement.scrollWidth - innerWidth);
      check(ov <= 1, `${h}: không tràn ngang trên 375px (lệch ${ov}px)`);
    }
    if (shotDir) await m.screenshot({ path: path.join(shotDir, 'labs-mobile.png'), fullPage: true });
    await ctx2.close();
    check(problems.length === 0, 'console sạch' + (problems.length ? ': ' + problems.slice(0, 4).join(' | ') : ''));
  } catch (e) {
    fail++; console.log('  ✗ Lỗi: ' + e.message); await shot(page, 'labs-error', true);
  } finally { await browser.close(); }
  console.log(`\nKết quả: ${pass} đạt, ${fail} lỗi.`);
  process.exit(fail ? 1 : 0);
})();
