#!/usr/bin/env node
// Tái hiện các lỗi nêu trong projects/08-review-game/REVIEW.md (không sửa game).
// Cách dùng: node tools/probe-game-bugs.js
'use strict';
const { openPage } = require('./lib/browser');
(async () => {
  const { browser, page, problems } = await openPage('index.html');
  await page.waitForTimeout(300);
  await page.evaluate(() => { const o = startGame; window.__n = 0; window.startGame = function () { window.__n++; return o.apply(this, arguments); }; });
  await page.click('.btn-play');
  await page.keyboard.press('Space'); await page.keyboard.press('Space');
  console.log('Space sau khi bấm PLAY — số lần startGame:', await page.evaluate(() => window.__n), '(1 = không phải lỗi)');
  const r = await page.evaluate(() => {
    gameRunning = false;
    enemies = []; player.bullets = []; energyBalls = []; activeLaser = null;
    player.currentHp = 3; player.invincibleTime = 0; frameCount = 1;
    const mk = (x, y, hp) => ({ id: 'basic', hp, maxHp: hp, exp: 10, score: 10, speed: 0, color: '#0f0', x, y, w: 40, h: 40, flash: 0 });
    const victim = mk(player.x, player.y, 1), other = mk(10, 10, 5);
    enemies.push(victim, other);
    player.bullets.push({ x: victim.x + 10, y: victim.y + 20, w: 4, h: 15, speed: 10 });
    update();
    return player.currentHp;
  });
  console.log('Lỗi 2 — HP sau khi đạn giết quái đang chồng lên phi thuyền:', r, '(3 = đúng, 2 = lỗi)');
  const lv = await page.evaluate(() => { player.level = 1; player.exp = 0; player.nextLevelExp = 100; gainExp(400); return [player.level, player.exp, player.nextLevelExp]; });
  console.log('gainExp(400) ở cấp 1 → cấp', lv[0], ', EXP', lv[1] + '/' + lv[2], '(chỉ lên 1 cấp)');
  const shoot = await page.evaluate(() => { autoShootInt = 123; gameOver(); return autoShootInt; });
  console.log('Sau gameOver, autoShootInt =', shoot, '(khác null = lần chạm đầu ván sau không tự bắn)');
  console.log('Lỗi console:', problems.length);
  await browser.close();
})();
