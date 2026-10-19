#!/usr/bin/env node
// Kiểm thử Bảng điều khiển ôn thi. Cách dùng: node tools/test-dash.js [thư-mục-ảnh]
'use strict';
const fs = require('fs');
const path = require('path');
const { openPage } = require('./lib/browser');
const shotDir = process.argv[2];
if (shotDir) fs.mkdirSync(shotDir, { recursive: true });
let pass = 0, fail = 0;
const check = (c, m) => { c ? pass++ : fail++; console.log(`  ${c ? '✓' : '✗'} ${m}`); };
const shot = async (p, n) => { if (shotDir) await p.screenshot({ path: path.join(shotDir, n + '.png'), fullPage: true }); };

(async () => {
  const PAGE = 'projects/05-bang-dieu-khien/index.html';
  const { browser, page, problems } = await openPage(PAGE);
  const dash = () => page.evaluate(() => JSON.parse(localStorage.getItem('sl.dash.v1')));
  try {
    await page.waitForSelector('.countdown');
    // Giả lập tiến độ một bộ ôn thi để kiểm tra phần đọc thống kê
    await page.evaluate(() => {
      const now = Date.now();
      localStorage.setItem('sl.quiz.vatly12.v1', JSON.stringify({ v: 1, q: { a: { box: 3, due: now - 1, seen: 2, right: 1, wrong: 1, wb: true, last: now }, b: { box: 4, due: now + 9e8, seen: 1, right: 1, wrong: 0, wb: false, last: now } },
        exams: [{ t: now, total: 7.35, max: 10, parts: [] }], log: [], daily: {} }));
    });
    await page.reload();
    await page.waitForSelector('.countdown');
    const big = await page.$$eval('.countdown .big', e => e.map(x => parseInt(x.textContent)));
    const expect = await page.evaluate(() => {
      const d = JSON.parse(localStorage.getItem('sl.dash.v1')).exams.map(e => e.date).sort();
      const t = new Date(); const t0 = new Date(t.getFullYear(), t.getMonth(), t.getDate());
      return d.map(s => { const p = s.split('-'); return Math.round((new Date(+p[0], p[1] - 1, +p[2]) - t0) / 864e5); });
    });
    check(JSON.stringify(big) === JSON.stringify(expect), `đếm ngược đúng số ngày (${big.join(', ')})`);
    const qs = await page.locator('table').first().innerText();
    check(/Ôn thi Vật lý 12/.test(qs) && /67%/.test(qs) && /7,35\/10/.test(qs), 'đọc được thống kê từ bộ Ôn thi Vật lý 12 (2 đúng/1 sai = 67 %, thi 7,35/10)');
    await shot(page, 'dash-1-home');

    // Việc hôm nay
    const first = page.locator('[data-act="toggle-task"]').first();
    if (await first.count()) {
      await first.check();
      const d = await dash();
      check((d.plan.done[await page.evaluate(() => SL.today())] || []).length === 1, 'đánh dấu xong 1 việc hôm nay');
    } else check(true, '(hôm nay không có việc mẫu)');

    // Kế hoạch tuần: thêm & xóa việc
    await page.click('a[data-tab="plan"]');
    await page.waitForSelector('.add-task');
    const before = (await dash()).plan.template[0].length;
    await page.fill('.add-task[data-day="0"] input[name=text]', 'Hóa: ôn chương este');
    await page.selectOption('.add-task[data-day="0"] select', 'Hóa học');
    await page.click('.add-task[data-day="0"] button');
    check((await dash()).plan.template[0].length === before + 1, 'thêm việc vào Thứ 2');
    await page.locator('.day-col').first().locator('[data-act="del-task"]').last().click();
    check((await dash()).plan.template[0].length === before, 'xóa việc');
    await shot(page, 'dash-2-plan');

    // Nhật ký: thêm tay + Pomodoro hoàn tất
    await page.click('a[data-tab="focus"]');
    await page.fill('#add-log input[name=min]', '50');
    await page.fill('#add-log input[name=note]', 'Thi thử Vật lý');
    await page.click('#add-log button');
    check((await dash()).log.some(e => e.min === 50 && e.note === 'Thi thử Vật lý'), 'thêm giờ học thủ công');
    await page.evaluate(() => localStorage.setItem('sl.dash.pomo-run', JSON.stringify({ mode: 'work', start: Date.now() - 25 * 60000 - 2000, dur: 25, subject: 'Vật lý' })));
    await page.waitForTimeout(1200);
    const d2 = await dash();
    check(d2.log.some(e => e.src === 'pomodoro' && e.min === 25), 'hết phiên Pomodoro → tự ghi 25 phút');
    check(JSON.parse(await page.evaluate(() => localStorage.getItem('sl.dash.pomo-run'))).mode === 'break', 'tự chuyển sang giờ nghỉ');
    await page.click('[data-act="pm-stop"]');
    await shot(page, 'dash-3-focus');

    // Sổ lỗi sai: thêm, đến hạn, ôn
    await page.click('a[data-tab="mistakes"]');
    await page.fill('#add-mistake input[name=topic]', 'Từ thông — góc α');
    await page.selectOption('#add-mistake select[name=type]', 'Hiểu sai khái niệm');
    await page.fill('#add-mistake textarea[name=wrong]', 'Dùng cos 30° vì nhầm góc với mặt phẳng khung');
    await page.fill('#add-mistake textarea[name=right]', 'α là góc giữa B và pháp tuyến: 60°');
    await page.click('#add-mistake button');
    check((await dash()).mistakes.length === 1, 'lưu lỗi sai mới');
    await page.evaluate(() => { const d = JSON.parse(localStorage.getItem('sl.dash.v1')); d.mistakes[0].due = Date.now() - 1000; localStorage.setItem('sl.dash.v1', JSON.stringify(d)); });
    await page.reload(); await page.waitForSelector('[data-act="review"]');
    await page.click('[data-act="review"]');
    await page.click('[data-act="rv-ok"]');
    const m = (await dash()).mistakes[0];
    check(m.stage === 1 && m.due > Date.now() + 2.9 * 864e5, 'ôn "Nhớ rồi" → lên bậc 1, hẹn 3 ngày sau');
    await shot(page, 'dash-4-mistakes');

    // Xuất dữ liệu
    await page.click('a[data-tab="data"]');
    const [dl] = await Promise.all([page.waitForEvent('download'), page.click('[data-act="export"]')]);
    const file = await dl.path();
    const exp = JSON.parse(fs.readFileSync(file, 'utf8'));
    check(exp.app === 'study-lab-dashboard' && exp.dash.mistakes.length === 1 && exp.quiz['sl.quiz.vatly12.v1'], 'xuất tệp sao lưu gồm cả tiến độ ôn thi');

    const ctx2 = await page.context().browser().newContext({ viewport: { width: 375, height: 800 } });
    const mp = await ctx2.newPage();
    for (const h of ['#home', '#plan', '#focus', '#mistakes']) {
      await mp.goto('file://' + path.resolve(PAGE) + h); await mp.waitForTimeout(300);
      const ov = await mp.evaluate(() => document.documentElement.scrollWidth - innerWidth);
      check(ov <= 1, `${h}: không tràn ngang trên 375px (lệch ${ov}px)`);
    }
    if (shotDir) await mp.screenshot({ path: path.join(shotDir, 'dash-mobile.png'), fullPage: true });
    await ctx2.close();
    check(problems.length === 0, 'console sạch' + (problems.length ? ': ' + problems.slice(0, 4).join(' | ') : ''));
  } catch (e) {
    fail++; console.log('  ✗ Lỗi: ' + e.message); await shot(page, 'dash-error');
  } finally { await browser.close(); }
  console.log(`\nKết quả: ${pass} đạt, ${fail} lỗi.`);
  process.exit(fail ? 1 : 0);
})();
