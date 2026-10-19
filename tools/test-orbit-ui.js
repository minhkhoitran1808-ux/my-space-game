#!/usr/bin/env node
// Kiểm thử giao diện Orbit Lab bằng Chromium headless.
// Cách dùng: node tools/test-orbit-ui.js [thư-mục-ảnh-chụp]
'use strict';
const fs = require('fs');
const path = require('path');
const { openPage } = require('./lib/browser');

const shotDir = process.argv[2];
if (shotDir) fs.mkdirSync(shotDir, { recursive: true });
let pass = 0, fail = 0;
const check = (c, m) => { c ? pass++ : fail++; console.log(`  ${c ? '✓' : '✗'} ${m}`); };
const shot = async (page, name, full) => { if (shotDir) await page.screenshot({ path: path.join(shotDir, name + '.png'), fullPage: !!full }); };

(async () => {
  const PAGE = 'projects/02-orbit-lab/index.html';
  const { browser, page, problems } = await openPage(PAGE);
  try {
    await page.waitForSelector('#readout tr');
    const status = () => page.locator('#status').innerText();
    const setWarp = w => page.selectOption('#warp', String(w));

    console.log('== Mô phỏng quỹ đạo ==');
    await page.click('[data-preset="iss"]');
    await page.waitForTimeout(1500);
    check(/tròn/i.test(await status()), `ISS: ${await status()}`);
    const drift = await page.evaluate(() => {
      const O = window.OrbitCore, sb = window.OrbitLab.sb;
      return Math.abs((O.elements(sb.body.mu, sb.s).energy - sb.E0) / sb.E0);
    });
    check(drift < 1e-6, `sai số năng lượng sau khi chạy: ${drift.toExponential(2)}`);
    await shot(page, 'orbit-1-iss');

    for (const [id, re, label] of [['ellipse', /elip/i, 'elip'], ['escape', /parabol/i, 'parabol'], ['hyper', /hypebol|thoát/i, 'hypebol']]) {
      await page.click(`[data-preset="${id}"]`);
      await page.waitForTimeout(500);
      check(re.test(await status()), `${id}: trạng thái "${await status()}" (kỳ vọng ${label})`);
    }
    await page.click('[data-preset="hel"]');
    await page.waitForTimeout(2500);
    await shot(page, 'orbit-2-ellipse');

    await page.click('[data-preset="fall"]');
    await setWarp(3000);
    await page.waitForTimeout(2500);
    check(/Va chạm/.test(await status()), `rơi xuống: "${await status()}"`);
    await shot(page, 'orbit-3-crash');

    // Đốt động cơ: từ quỹ đạo tròn, tăng tốc 500 m/s → elip có viễn điểm cao hơn
    await page.click('[data-preset="iss"]');
    await page.waitForTimeout(300);
    await page.fill('#in-dv', '500');
    await page.click('#btn-pro');
    await page.waitForTimeout(300);
    const el = await page.evaluate(() => { const O = window.OrbitCore, sb = window.OrbitLab.sb; return O.elements(sb.body.mu, sb.s); });
    check(/elip/i.test(await status()) && el.ra > el.rp * 1.2, `tăng tốc 500 m/s → elip, viễn điểm ${(el.ra / 1e3 - 6371).toFixed(0)} km`);

    // Định luật II Kepler: chạy hơn một chu kì, các quạt phải bằng nhau
    await page.click('[data-preset="ellipse"]');
    await page.check('#t-kepler');
    await setWarp(3000);
    await page.waitForTimeout(3500);
    const ratios = await page.$$eval('#kbars span', s => s.map(x => parseFloat(x.textContent.replace(',', '.'))));
    check(ratios.length >= 6 && ratios.every(r => Math.abs(r - 1) < 0.01), `Kepler II: ${ratios.length} quạt, tỉ lệ diện tích ${ratios.join(' ')}`);
    await shot(page, 'orbit-4-kepler');
    await page.uncheck('#t-kepler');

    // Đổi vật trung tâm
    await page.selectOption('#body', 'moon');
    await page.waitForTimeout(800);
    check(/tròn/i.test(await status()), `Mặt Trăng, preset đầu: "${await status()}"`);
    await page.selectOption('#body', 'earth');

    console.log('\n== Hohmann ==');
    await page.click('a[data-tab="hohmann"]');
    await page.waitForSelector('#hoh-table tr');
    const table = await page.locator('#hoh-table').innerText();
    check(table.includes('+2,945 km/s') && table.includes('+2,649 km/s'), 'bảng Trái Đất→Sao Hỏa: Δv₁ = 2,945 & Δv₂ = 2,649 km/s');
    check(/258,9 ngày/.test(table) && /44,3°/.test(table), 'thời gian 258,9 ngày, góc pha 44,3°');
    await shot(page, 'orbit-5-hohmann-start');
    await page.fill('#hoh-speed', '100');
    await page.click('#hoh-play');
    await page.waitForTimeout(4200);
    check(/Tới nơi đúng lúc/.test(await page.locator('#hoh-status').innerText()), `phóng đúng pha: "${await page.locator('#hoh-status').innerText()}"`);
    await shot(page, 'orbit-6-hohmann-arrive');
    await page.locator('#hoh-off').evaluate(e => { e.value = 10; e.dispatchEvent(new Event('input', { bubbles: true })); });
    await page.click('#hoh-play');
    await page.waitForTimeout(4200);
    const miss = await page.locator('#hoh-status').innerText();
    check(/Trượt/.test(miss) && /10,0°/.test(miss), `lệch pha +10°: "${miss}"`);
    await page.selectOption('#hoh-mode', 'earth');
    await page.waitForTimeout(200);
    const t2 = await page.locator('#hoh-table').innerText();
    check(/3,89\d km\/s/.test(t2), 'LEO 300 km → GEO: tổng Δv ≈ 3,89 km/s');
    await shot(page, 'orbit-7-hohmann-geo');

    console.log('\n== Tên lửa ==');
    await page.click('a[data-tab="rocket"]');
    await page.click('[data-rk="two"]');
    const rtext = await page.locator('#rk-result').innerText();
    const expected = await page.evaluate(() => window.OrbitCore.rocketStages([{ mProp: 400, mDry: 25, isp: 300 }, { mProp: 100, mDry: 6, isp: 345 }], 10).total / 1000);
    check(rtext.includes(expected.toFixed(2).replace('.', ',') + ' km/s'), `2 tầng: tổng Δv ${expected.toFixed(2)} km/s hiển thị đúng`);
    check(/một tầng/.test(rtext), 'có so sánh với tên lửa một tầng');
    await page.fill('#rk-payload', '60');
    await page.waitForTimeout(100);
    check(/Chưa đủ/.test(await page.locator('#rk-result').innerText()), 'tải 60 t → cảnh báo chưa đủ Δv');
    await shot(page, 'orbit-8-rocket', true);

    console.log('\n== Bài tập ==');
    await page.click('a[data-tab="exercises"]');
    check((await page.locator('.ex').count()) === 9, '9 bài tập');
    check((await page.locator('.katex-error').count()) === 0, 'không có công thức lỗi');
    await page.locator('.ex details').nth(1).evaluate(d => { d.open = true; });
    await shot(page, 'orbit-9-exercises', true);
    await page.locator('[data-go]').nth(2).click();
    await page.waitForTimeout(500);
    check(!(await page.locator('#tab-sandbox').isHidden()) && /tròn/i.test(await status()), 'nút "Thử trong mô phỏng" mở đúng kịch bản GEO');

    // Điện thoại
    const ctx2 = await page.context().browser().newContext({ viewport: { width: 375, height: 800 }, colorScheme: 'light' });
    const m = await ctx2.newPage();
    m.on('pageerror', e => problems.push('[pageerror mobile] ' + e.message));
    await m.goto('file://' + path.resolve(PAGE));
    await m.waitForTimeout(1200);
    const ov = await m.evaluate(() => document.documentElement.scrollWidth - innerWidth);
    check(ov <= 1, `không tràn ngang trên 375px (lệch ${ov}px)`);
    if (shotDir) await m.screenshot({ path: path.join(shotDir, 'orbit-mobile.png'), fullPage: true });
    await ctx2.close();

    check(problems.length === 0, 'console sạch' + (problems.length ? ': ' + problems.slice(0, 5).join(' | ') : ''));
  } catch (e) {
    fail++; console.log('  ✗ Lỗi: ' + e.message);
    await shot(page, 'orbit-error', true);
  } finally {
    await browser.close();
  }
  console.log(`\nKết quả: ${pass} đạt, ${fail} lỗi.`);
  process.exit(fail ? 1 : 0);
})();
