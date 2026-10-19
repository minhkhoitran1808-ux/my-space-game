#!/usr/bin/env node
// Chụp ảnh thu nhỏ cho trang hub. Cách dùng: node tools/make-thumbs.js
'use strict';
const path = require('path');
const { execFileSync } = require('child_process');
const { requirePlaywright } = require('./lib/browser');
const SHOTS = [
  ['p1-vatly', 'projects/01-on-thi-vat-ly-12/index.html', '#/', 0],
  ['p2-orbit', 'projects/02-orbit-lab/index.html', '#sandbox', 2500],
  ['p3-congthuc', 'projects/03-so-tay-cong-thuc/index.html', '', 0],
  ['p4-lab', 'projects/04-phong-thi-nghiem-ao/index.html', '#gas', 2500],
  ['p5-dash', 'projects/05-bang-dieu-khien/index.html', '#home', 0],
  ['p6-toan', 'projects/06-on-thi-toan-vact/index.html', '#/', 0],
  ['p7-duc', 'projects/07-lo-trinh-du-hoc-duc/index.html', '', 0],
  ['game', 'index.html', '', 800]
];
(async () => {
  const { chromium } = requirePlaywright();
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 1200, height: 750 }, colorScheme: 'dark' });
  const page = await ctx.newPage();
  for (const [name, file, hash, wait] of SHOTS) {
    try {
      await page.goto('file://' + path.resolve(file) + hash);
      if (name === 'p2-orbit') await page.evaluate(() => window.OrbitLab && window.OrbitLab.applyPreset('hel'));
      await page.waitForTimeout(wait + 500);
      const png = path.resolve('projects/assets/thumbs', name + '.png');
      await page.screenshot({ path: png });
      execFileSync('python3', ['-c', `from PIL import Image; im=Image.open(${JSON.stringify(png)}).convert('RGB').resize((600,375), Image.LANCZOS); im.save(${JSON.stringify(png.replace('.png', '.jpg'))}, quality=82)`]);
      require('fs').unlinkSync(png);
      console.log('✓', name);
    } catch (e) { console.log('✗', name, e.message.split('\n')[0]); }
  }
  await browser.close();
})();
