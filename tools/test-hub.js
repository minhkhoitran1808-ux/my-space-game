#!/usr/bin/env node
// Kiểm thử trang hub + lộ trình du học + mọi liên kết nội bộ giữa các trang.
// Cách dùng: node tools/test-hub.js [thư-mục-ảnh]
'use strict';
const fs = require('fs');
const path = require('path');
const { openPage } = require('./lib/browser');
const shotDir = process.argv[2];
if (shotDir) fs.mkdirSync(shotDir, { recursive: true });
let pass = 0, fail = 0;
const check = (c, m) => { c ? pass++ : fail++; console.log(`  ${c ? '✓' : '✗'} ${m}`); };
const ROOT = path.resolve(__dirname, '..');
const PAGES = ['projects/index.html', 'projects/01-on-thi-vat-ly-12/index.html', 'projects/02-orbit-lab/index.html', 'projects/03-so-tay-cong-thuc/index.html',
  'projects/04-phong-thi-nghiem-ao/index.html', 'projects/05-bang-dieu-khien/index.html', 'projects/06-on-thi-toan-vact/index.html', 'projects/07-lo-trinh-du-hoc-duc/index.html'];

(async () => {
  const { browser, page, problems, context } = await openPage('projects/index.html');
  try {
    console.log('== Liên kết nội bộ ==');
    for (const p of PAGES) {
      await page.goto('file://' + path.join(ROOT, p));
      await page.waitForTimeout(300);
      const refs = await page.evaluate(() => [...document.querySelectorAll('a[href], img[src], script[src], link[href]')]
        .map(e => e.getAttribute('href') || e.getAttribute('src')));
      const local = refs.filter(r => r && !/^(https?:|#|mailto:)/.test(r)).map(r => r.split('#')[0]).filter(Boolean);
      const missing = local.filter(r => !fs.existsSync(path.resolve(path.dirname(path.join(ROOT, p)), r)));
      check(missing.length === 0, `${p}: ${local.length} liên kết nội bộ${missing.length ? ' — THIẾU: ' + missing.join(', ') : ' đều tồn tại'}`);
    }

    console.log('\n== Hub ==');
    await page.goto('file://' + path.join(ROOT, 'projects/index.html'));
    await page.waitForTimeout(500);
    const imgs = await page.$$eval('img', a => a.map(i => [i.getAttribute('src'), i.naturalWidth]));
    check(imgs.length === 8 && imgs.every(i => i[1] > 0), `${imgs.length} ảnh thu nhỏ tải được`);
    if (shotDir) await page.screenshot({ path: path.join(shotDir, 'hub.png'), fullPage: true });

    console.log('\n== Lộ trình du học ==');
    await page.goto('file://' + path.join(ROOT, 'projects/07-lo-trinh-du-hoc-duc/index.html'));
    const n = await page.locator('#ck input').count();
    await page.locator('#ck input').nth(2).check();
    await page.reload();
    check(n === 17 && await page.locator('#ck input').nth(2).isChecked(), `checklist ${n} mục, đánh dấu được lưu sau khi tải lại`);
    const verify = await page.locator('.verify').count();
    check(verify >= 10, `có ${verify} nhãn "cần xác minh"`);
    if (shotDir) await page.screenshot({ path: path.join(shotDir, 'roadmap.png'), fullPage: true });

    const m = await context.browser().newContext({ viewport: { width: 375, height: 800 } });
    const mp = await m.newPage();
    for (const p of ['projects/index.html', 'projects/07-lo-trinh-du-hoc-duc/index.html']) {
      await mp.goto('file://' + path.join(ROOT, p)); await mp.waitForTimeout(300);
      const ov = await mp.evaluate(() => document.documentElement.scrollWidth - innerWidth);
      check(ov <= 1, `${p}: không tràn ngang trên 375px (lệch ${ov}px)`);
    }
    await m.close();
    check(problems.length === 0, 'console sạch' + (problems.length ? ': ' + problems.slice(0, 4).join(' | ') : ''));
  } catch (e) { fail++; console.log('  ✗ Lỗi: ' + e.message); } finally { await browser.close(); }
  console.log(`\nKết quả: ${pass} đạt, ${fail} lỗi.`);
  process.exit(fail ? 1 : 0);
})();
