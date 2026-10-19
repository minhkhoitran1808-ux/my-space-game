#!/usr/bin/env node
// Kiểm thử Sổ tay công thức: công thức render được, tìm kiếm, chế độ tự kiểm tra,
// bản in A4, và hằng số khớp với ngân hàng câu hỏi P1.
// Cách dùng: node tools/test-formulas.js [thư-mục-ảnh]
'use strict';
const fs = require('fs');
const path = require('path');
const { openPage } = require('./lib/browser');

const shotDir = process.argv[2];
if (shotDir) fs.mkdirSync(shotDir, { recursive: true });
let pass = 0, fail = 0;
const check = (c, m) => { c ? pass++ : fail++; console.log(`  ${c ? '✓' : '✗'} ${m}`); };

(async () => {
  const { browser, page, problems } = await openPage('projects/03-so-tay-cong-thuc/index.html');
  try {
    await page.waitForSelector('.item .katex');
    const nItems = await page.locator('.item').count();
    check(nItems >= 40, `${nItems} mục công thức`);
    check((await page.locator('.katex-error').count()) === 0, 'mọi công thức KaTeX render không lỗi');
    const rendered = await page.locator('.item .f .katex-display, .item .f.ft').count();
    check(rendered === nItems, `mỗi mục đều có công thức hiển thị (${rendered}/${nItems})`);
    if (shotDir) await page.screenshot({ path: path.join(shotDir, 'formulas-top.png') });

    await page.fill('#q', 'ban ra');
    const visible = await page.locator('.item:not(.hide)').count();
    check(visible >= 1 && visible <= 4, `tìm không dấu "ban ra" còn ${visible} mục`);
    check((await page.locator('#book .chap:not(.hide)').count()) === 1, 'chỉ hiện chương có kết quả');
    await page.fill('#q', '');
    await page.dispatchEvent('#q', 'input');

    await page.check('#quiz');
    const first = page.locator('.item').first();
    check(!(await first.locator('.n').isVisible()), 'chế độ tự kiểm tra ẩn ghi chú');
    await first.click();
    check(await first.locator('.n').isVisible(), 'bấm vào thì hiện lại');
    if (shotDir) await page.screenshot({ path: path.join(shotDir, 'formulas-quiz.png') });
    await page.uncheck('#quiz');

    // Hằng số khớp ngân hàng P1
    const txt = fs.readFileSync(path.join(__dirname, '../projects/03-so-tay-cong-thuc/formulas.js'), 'utf8');
    for (const s of ['6{,}02\\cdot10^{23}', '8{,}31', '1{,}38\\cdot10^{-23}', '931{,}5', '1{,}0073', '1{,}0087', '1{,}6\\cdot10^{-13}']) {
      check(txt.includes(s), `hằng số ${s.replace(/[{}\\]/g, '').replace('cdot', '·')} có trong sổ tay (khớp ngân hàng P1)`);
    }

    // Bản in A4
    await page.emulateMedia({ media: 'print' });
    const pdfPath = path.join(shotDir || require('os').tmpdir(), 'so-tay-cong-thuc.pdf');
    await page.pdf({ path: pdfPath, format: 'A4', printBackground: true });
    const pdf = fs.readFileSync(pdfPath, 'latin1');
    const pages = (pdf.match(/\/Type\s*\/Page[^s]/g) || []).length;
    check(pages >= 2 && pages <= 5, `bản in A4: ${pages} trang`);
    if (shotDir) await page.screenshot({ path: path.join(shotDir, 'formulas-print.png'), fullPage: true });
    await page.emulateMedia({ media: 'screen' });

    check(problems.length === 0, 'console sạch' + (problems.length ? ': ' + problems.slice(0, 3).join(' | ') : ''));
  } catch (e) {
    fail++; console.log('  ✗ Lỗi: ' + e.message);
  } finally {
    await browser.close();
  }
  console.log(`\nKết quả: ${pass} đạt, ${fail} lỗi.`);
  process.exit(fail ? 1 : 0);
})();
