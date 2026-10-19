// Mở trang bằng Playwright (Chromium cài sẵn), gom lỗi console để kiểm thử.
'use strict';
const path = require('path');

function requirePlaywright() {
  const candidates = ['playwright', '/opt/node-tools/node_modules/playwright', '/opt/node22/lib/node_modules/playwright'];
  for (const c of candidates) {
    try { return require(c); } catch (e) { /* thử đường dẫn khác */ }
  }
  throw new Error('Không tìm thấy Playwright. Cài bằng: npm i -D playwright');
}

async function openPage(relPath, opts = {}) {
  const { chromium } = requirePlaywright();
  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: opts.viewport || { width: 1200, height: 900 },
    deviceScaleFactor: 1,
    colorScheme: opts.colorScheme || 'dark'
  });
  const page = await context.newPage();
  const problems = [];
  page.on('console', m => { if (m.type() === 'error' || m.type() === 'warning') problems.push(`[console.${m.type()}] ${m.text()}`); });
  page.on('pageerror', e => problems.push(`[pageerror] ${e.message}`));
  page.on('dialog', d => d.accept());   // tự đồng ý các hộp thoại confirm()
  const url = 'file://' + path.resolve(__dirname, '../..', relPath) + (opts.hash || '');
  await page.goto(url);
  return { browser, context, page, problems };
}

module.exports = { openPage, requirePlaywright };
