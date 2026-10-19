#!/usr/bin/env node
// Kiểm thử đầu-cuối cho engine ôn thi bằng trình duyệt thật (Chromium headless).
// Cách dùng: node tools/test-quiz.js <đường-dẫn-trang> [thư-mục-ảnh-chụp]
//   vd: node tools/test-quiz.js projects/01-on-thi-vat-ly-12/index.html /tmp/shots
'use strict';
const fs = require('fs');
const path = require('path');
const { openPage } = require('./lib/browser');

const pagePath = process.argv[2] || 'projects/01-on-thi-vat-ly-12/index.html';
const shotDir = process.argv[3];
if (shotDir) fs.mkdirSync(shotDir, { recursive: true });

let pass = 0, fail = 0;
function check(cond, msg) {
  if (cond) { pass++; console.log('  ✓ ' + msg); } else { fail++; console.log('  ✗ ' + msg); }
}
async function shot(page, name) {
  if (shotDir) await page.screenshot({ path: path.join(shotDir, name + '.png'), fullPage: true });
}

(async () => {
  const { browser, page, problems, context } = await openPage(pagePath);
  try {
    console.log('Trang: ' + pagePath);
    await page.waitForSelector('h1');
    const bankIds = await page.evaluate(() => (window.QUIZ_APP && window.QUIZ_APP.bankIds) || Object.keys(window.QBANKS));

    for (const bankId of bankIds) {
      console.log(`\n== Ngân hàng ${bankId} ==`);
      if (bankIds.length > 1) {
        await page.selectOption('#bank-switch', bankId);
        await page.waitForTimeout(100);
      }
      const bank = await page.evaluate(id => {
        const b = window.QBANKS[id];
        return { title: b.title, chapters: b.chapters.length, exam: b.exam, n: b.questions.length };
      }, bankId);

      // 1. Trang chủ
      await page.evaluate(() => { location.hash = '#/'; });
      await page.waitForSelector('.chapter-card');
      check((await page.locator('.chapter-card').count()) === bank.chapters, `trang chủ hiển thị ${bank.chapters} chương`);
      check((await page.locator('.katex-error').count()) === 0, 'không có công thức KaTeX lỗi ở trang chủ');
      await shot(page, `${bankId}-1-home`);

      // 2. Luyện một chương: trả lời từng câu (cố tình chọn ngẫu nhiên) rồi kiểm tra
      await page.locator('[data-act="start-chapter"]').first().click();
      await page.waitForSelector('#qcard');
      let answered = 0;
      for (let i = 0; i < 12; i++) {
        if (!(await page.locator('#qcard').count())) break;
        const type = await page.evaluate(() => {
          if (document.querySelector('#qcard .choices')) return 'mcq';
          if (document.querySelector('#qcard .tf')) return 'tf';
          return 'short';
        });
        if (type === 'mcq') await page.locator('#qcard .choice').nth(i % 4).click();
        else if (type === 'tf') {
          for (let s = 0; s < 4; s++) await page.locator(`#qcard .tf-btn[data-i="${s}"][data-v="${(s + i) % 2}"]`).click();
        } else await page.fill('#qcard .short input', '1');
        if (i === 0) await shot(page, `${bankId}-2-question`);
        await page.click('#btn-check');
        await page.waitForSelector('#qcard .feedback');
        check((await page.locator('#qcard .katex-error').count()) === 0, `câu ${i + 1} (${type}): có lời giải, KaTeX không lỗi`);
        if (i === 0) await shot(page, `${bankId}-3-feedback`);
        answered++;
        await page.click('#btn-next');
      }
      await page.waitForSelector('text=Kết quả');
      check(answered >= 5, `đã làm ${answered} câu và tới trang kết quả phiên`);
      await shot(page, `${bankId}-4-session-summary`);

      // 3. Bàn phím: phím 1 chọn, Enter kiểm tra, Enter sang câu
      await page.evaluate(() => { location.hash = '#/practice'; });
      await page.waitForSelector('[data-act="start-practice"]');
      // chỉ lấy trắc nghiệm
      for (const t of ['tf', 'short']) {
        const box = page.locator(`input[data-group="type"][value="${t}"]`);
        if (await box.count() && await box.isChecked()) await box.uncheck();
      }
      await page.click('[data-act="start-practice"]');
      await page.waitForSelector('#qcard .choices');
      await page.keyboard.press('1');
      check((await page.locator('#qcard .choice.sel').count()) === 1, 'phím 1 chọn phương án');
      await page.keyboard.press('Enter');
      await page.waitForSelector('#qcard .feedback');
      check(true, 'Enter để kiểm tra');
      await page.keyboard.press('Enter');
      await page.waitForTimeout(50);
      check(await page.evaluate(() => /Câu 2\//.test(document.querySelector('.session-top').textContent)), 'Enter lần nữa sang câu 2');

      // 4. Sổ câu sai phải có câu (vì đã cố tình làm sai)
      await page.evaluate(() => { location.hash = '#/wrong'; });
      await page.waitForSelector('h1');
      const nWrong = await page.locator('.qitem').count();
      check(nWrong > 0, `sổ câu sai có ${nWrong} câu`);
      await shot(page, `${bankId}-5-wrong-book`);

      // 5. Thi thử: làm ĐÚNG hết → phải được điểm tối đa
      await page.evaluate(() => { location.hash = '#/exam'; });
      await page.click('[data-act="start-exam"]');
      await page.waitForSelector('.exam-q');
      const totalQ = bank.exam.parts.reduce((s, p) => s + p.count, 0);
      check((await page.locator('.exam-q').count()) === totalQ, `đề có đủ ${totalQ} câu`);
      const exam = await page.evaluate(id => JSON.parse(localStorage.getItem('sl.quiz.' + id + '.exam-inprogress')), bankId);
      const keys = await page.evaluate(ids => ids.map(id => {
        for (const b of Object.values(window.QBANKS)) {
          const q = b.questions.find(x => x.id === id);
          if (q) return { type: q.type, answer: q.answer, st: q.statements ? q.statements.map(s => s.a) : null };
        }
        return null;
      }), exam.ids);
      check(new Set(exam.ids).size === exam.ids.length, 'đề không có câu trùng');
      await shot(page, `${bankId}-6-exam`);
      for (let k = 0; k < keys.length; k++) {
        const q = keys[k], sel = `#eq-${k}`;
        if (q.type === 'mcq') await page.click(`${sel} .choice[data-v="${q.answer}"]`);
        else if (q.type === 'tf') { for (let s = 0; s < 4; s++) await page.click(`${sel} .tf-btn[data-i="${s}"][data-v="${q.st[s] ? 1 : 0}"]`); }
        else await page.fill(`${sel} .short input`, String(q.answer));
      }
      check(await page.evaluate(() => /Đã làm (\d+)\/\1/.test(document.getElementById('answered').textContent)), 'bộ đếm "đã làm" = tổng số câu');
      await page.locator('[data-act="submit-exam"]').first().click();
      await page.waitForSelector('.score-big');
      const score = await page.locator('.score-big').innerText();
      check(score.replace(/\s/g, '').startsWith(String(bank.exam.max || 10) + '/'), `làm đúng hết được điểm tối đa (${score.replace(/\s+/g, '')})`);
      await shot(page, `${bankId}-7-exam-result`);

      // 6. Thi thử để trống → 0 điểm
      await page.click('[data-act="start-exam"]');
      await page.waitForSelector('.exam-q');
      await page.locator('[data-act="submit-exam"]').first().click();
      await page.waitForSelector('.score-big');
      check((await page.locator('.score-big').innerText()).trim().startsWith('0/'), 'để trống được 0 điểm');

      // 7. Đúng/Sai được chấm theo thang (đúng 3/4 ý)
      const partial = await page.evaluate(id => {
        const b = window.QBANKS[id];
        const q = b.questions.find(x => x.type === 'tf');
        if (!q) return 3;   // ngân hàng không có câu Đúng/Sai
        const a = q.statements.map(s => s.a); a[0] = !a[0];
        return window.QuizEngine.evaluate(q, a).n;
      }, bankId);
      check(partial === 3, 'Đúng/Sai: sai 1 ý → đếm đúng 3 ý');

      // 8. Ngân hàng + tìm kiếm
      await page.evaluate(() => { location.hash = '#/bank'; });
      await page.waitForSelector('#bank-list .qitem');
      const before = await page.locator('#bank-list .qitem').count();
      await page.fill('#f-text', 'zzzz-không-có');
      await page.keyboard.press('Space');
      await page.waitForTimeout(100);
      const after = await page.locator('#bank-list .qitem').count();
      check(before > 0 && after === 0, `ngân hàng lọc theo nội dung (${before} → ${after})`);
      await page.fill('#f-text', '');
      await page.keyboard.press('Backspace');

      // 9. Trang chủ cập nhật lịch sử thi
      await page.evaluate(() => { location.hash = '#/'; });
      await page.waitForSelector('.spark');
      check(true, 'trang chủ hiển thị biểu đồ lịch sử thi');
      await shot(page, `${bankId}-8-home-after`);

      // 10. Xóa tiến độ
      await page.evaluate(() => { location.hash = '#/data'; });
      await page.click('[data-act="reset"]');
      const cleared = await page.evaluate(id => JSON.parse(localStorage.getItem('sl.quiz.' + id + '.v1')), bankId);
      check(cleared && Object.keys(cleared.q).length === 0 && cleared.exams.length === 0, 'xóa tiến độ hoạt động');
    }

    // 11. Màn hình điện thoại, giao diện sáng
    const mobile = await context.browser().newContext({ viewport: { width: 375, height: 800 }, colorScheme: 'light' });
    const mp = await mobile.newPage();
    mp.on('pageerror', e => problems.push('[pageerror mobile] ' + e.message));
    await mp.goto('file://' + path.resolve(pagePath));
    await mp.waitForSelector('.chapter-card');
    const overflow = await mp.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
    check(overflow <= 1, `không tràn ngang trên màn hình 375px (lệch ${overflow}px)`);
    if (shotDir) await mp.screenshot({ path: path.join(shotDir, 'mobile-home.png'), fullPage: true });
    await mp.locator('[data-act="start-chapter"]').nth(1).click();
    await mp.waitForSelector('#qcard');
    const overflow2 = await mp.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
    check(overflow2 <= 1, `trang làm bài không tràn ngang trên điện thoại (lệch ${overflow2}px)`);
    if (shotDir) await mp.screenshot({ path: path.join(shotDir, 'mobile-question.png'), fullPage: true });
    await mobile.close();

    check(problems.length === 0, 'không có lỗi/cảnh báo console' + (problems.length ? ':\n     ' + problems.join('\n     ') : ''));
  } catch (e) {
    fail++;
    console.log('  ✗ Lỗi khi chạy kiểm thử: ' + e.message);
    await shot(page, 'error');
  } finally {
    await browser.close();
  }
  console.log(`\nKết quả: ${pass} đạt, ${fail} lỗi.`);
  process.exit(fail ? 1 : 0);
})();
