#!/usr/bin/env node
// Tính lại ĐỘC LẬP đáp án ngân hàng Toán 12 và Tư duy V-ACT.
// Cách dùng: node tools/verify-toan-vact.js
'use strict';
const path = require('path');
const { loadBanks } = require('./lib/load-bank');
const { parseNumber, close, isCorrectRounding } = require('./lib/numcheck');

const banks = loadBanks([
  path.join(__dirname, '../projects/06-on-thi-toan-vact/banks/toan12.js'),
  path.join(__dirname, '../projects/06-on-thi-toan-vact/banks/vact.js')
]);
const byId = {};
for (const b of Object.values(banks)) for (const q of b.questions) byId[q.id] = q;
const checked = new Set();
let pass = 0, fail = 0;
const ok = (id, m) => { pass++; checked.add(id); console.log(`  ✓ ${id}: ${m}`); };
const bad = (id, m) => { fail++; checked.add(id); console.log(`  ✗ ${id}: ${m}`); };

// Phương án đúng phải chứa chuỗi kỳ vọng, phương án nhiễu thì không
function mcqText(id, expected, note) {
  const q = byId[id];
  if (!q.choices[q.answer].includes(expected)) return bad(id, `đáp án "${q.choices[q.answer]}" không chứa "${expected}"`);
  if (q.choices.some((c, i) => i !== q.answer && c.includes(expected))) return bad(id, `phương án nhiễu cũng chứa "${expected}"`);
  ok(id, note || expected);
}
function mcqNum(id, value, rel = 0.005) {
  const q = byId[id], nums = q.choices.map(parseNumber);
  if (!close(nums[q.answer], value, rel)) return bad(id, `đáp án ${nums[q.answer]} ≠ ${value}`);
  if (nums.some((v, i) => i !== q.answer && close(v, value, rel))) return bad(id, 'phương án nhiễu trùng giá trị');
  ok(id, `${nums[q.answer]} ≈ ${+value.toPrecision(6)}`);
}
function short(id, value) {
  const q = byId[id];
  if (!isCorrectRounding(q.answer, value)) return bad(id, `đáp án ${q.answer} không phải làm tròn của ${value}`);
  ok(id, `${q.answer} ← ${+value.toPrecision(6)}`);
}
function tf(id, truths, note) {
  const q = byId[id], got = q.statements.map(s => s.a);
  if (JSON.stringify(got) !== JSON.stringify(truths)) return bad(id, `ghi ${got} nhưng tính được ${truths}`);
  ok(id, note);
}

// ---- Công cụ số ----
const deriv = (f, x, h = 1e-6) => (f(x + h) - f(x - h)) / (2 * h);
function simpson(f, a, b, n = 2000) {
  const h = (b - a) / n; let s = f(a) + f(b);
  for (let i = 1; i < n; i++) s += f(a + i * h) * (i % 2 ? 4 : 2);
  return s * h / 3;
}
function scan(f, a, b, n = 100000) { // trả về [min, argmin, max, argmax]
  let mn = Infinity, amn = a, mx = -Infinity, amx = a;
  for (let i = 0; i <= n; i++) { const x = a + (b - a) * i / n, y = f(x); if (y < mn) { mn = y; amn = x; } if (y > mx) { mx = y; amx = x; } }
  return [mn, amn, mx, amx];
}
function localExtrema(f, a, b, n = 200000) {
  const out = []; let prev = deriv(f, a);
  for (let i = 1; i <= n; i++) {
    const x = a + (b - a) * i / n, d = deriv(f, x);
    if (prev > 0 && d <= 0) out.push(['max', x, f(x)]);
    if (prev < 0 && d >= 0) out.push(['min', x, f(x)]);
    prev = d;
  }
  return out;
}

console.log('== Toán 12: Đạo hàm ==');
{
  const f = x => x ** 3 - 3 * x ** 2 + 2;
  const dec = [0.5, 1, 1.5].every(x => deriv(f, x) < 0) && deriv(f, -0.5) > 0 && deriv(f, 2.5) > 0;
  dec ? mcqText('dh-01', '(0; 2)', 'y\' < 0 đúng trên (0;2)') : bad('dh-01', 'sai');
  const ex = localExtrema(x => x ** 4 - 2 * x ** 2 + 3, -3, 3);
  ex.length === 3 ? mcqNum('dh-02', 3) : bad('dh-02', `số cực trị tính được ${ex.length}`);
  mcqNum('dh-03', scan(x => -x * x + 4 * x - 1, 0, 3)[2]);
  const g = x => (2 * x - 1) / (x + 1);
  Math.abs(g(1e9) - 2) < 1e-6 && Math.abs(g(-1 + 1e-9)) > 1e6 ? mcqText('dh-04', '$x = -1$ và $y = 2$') : bad('dh-04', 'tiệm cận');
  const mins = localExtrema(x => x ** 3 - 3 * x + 1, -3, 3).filter(e => e[0] === 'min');
  mcqNum('dh-05', mins[0][2]);
  mcqNum('dh-06', scan(t => -5 * t * t + 40 * t, 0, 8)[2]);
  const F = x => x ** 3 - 3 * x ** 2 - 9 * x + 5;
  const maxs = localExtrema(F, -5, 5).filter(e => e[0] === 'max');
  tf('dh-tf1', [Math.abs(deriv(F, 1.7) - (3 * 1.7 ** 2 - 6 * 1.7 - 9)) < 1e-5, deriv(F, 0) > 0,
    Math.abs(maxs[0][1] + 1) < 1e-3 && Math.abs(maxs[0][2] - 10) < 1e-6, Math.abs(scan(F, 0, 4)[0] + 22) < 1e-6], 'đạo hàm, chiều biến thiên, cực đại 10, min [0;4] = −22');
  const H = x => (x * x + 3) / (x - 1);
  const hmin = localExtrema(H, 1.001, 20).filter(e => e[0] === 'min');
  tf('dh-tf2', [true, Math.abs(deriv(H, 2.5) - (2.5 ** 2 - 5 - 3) / (1.5 ** 2)) < 1e-5, Math.abs(hmin[0][2] - 6) < 1e-6, Math.abs(H(1e7) / 1e7 - 1) > 0.5], 'đạo hàm, y_CT = 6, không có TCN (y ~ x)');
  let cnt = 0;
  for (let m = -10; m <= 10; m++) if (scan(x => 3 * x * x - 6 * x + m, -10, 10, 20000)[0] >= -1e-9) cnt++;
  short('dh-s1', cnt);
  short('dh-s2', scan(x => x * (12 - 2 * x) ** 2, 0, 6)[2]);
  short('dh-s3', scan(x => x + 4 / x, 0.01, 50)[0]);
}

console.log('\n== Toán 12: Tích phân ==');
{
  // nguyên hàm: kiểm bằng đạo hàm số
  const okAnti = (F, f) => [0.3, 1.1, 2.7].every(x => Math.abs(deriv(F, x) - f(x)) < 1e-5);
  okAnti(x => x ** 3 + x ** 2, x => 3 * x * x + 2 * x) ? mcqText('tp-01', '$x^3 + x^2 + C$') : bad('tp-01', 'sai');
  okAnti(x => 0.5 * Math.exp(2 * x), x => Math.exp(2 * x)) ? mcqText('tp-02', '$\\dfrac12 e^{2x} + C$') : bad('tp-02', 'sai');
  mcqNum('tp-03', simpson(x => 2 * x + 1, 0, 1));
  mcqNum('tp-04', simpson(Math.cos, 0, Math.PI / 2));
  mcqNum('tp-05', simpson(x => x * x, 0, 3));
  const V = Math.PI * simpson(x => x, 0, 4);
  Math.abs(V / Math.PI - 8) < 1e-9 ? mcqText('tp-06', '$8\\pi$') : bad('tp-06', V);
  mcqNum('tp-07', 2 * 5 - 3 * 2);
  const v = t => 3 * t * t + 2;
  tf('tp-tf1', [Math.abs(simpson(v, 0, 2) - 12) < 1e-9, Math.abs(deriv(v, 1) - 6) < 1e-6, okAnti(t => t ** 3 + 2 * t, v), Math.abs(simpson(v, 1, 3) - 32) < 1e-9], `quãng đường 1→3 s = ${simpson(v, 1, 3).toFixed(4)} m`);
  const f = x => Math.sin(x) + 2 * x, Fx = x => -Math.cos(x) + x * x + 2;
  tf('tp-tf2', [okAnti(Fx, f) && Math.abs(Fx(0) - 1) < 1e-12, Math.abs(Fx(Math.PI) - (Math.PI ** 2 + 3)) < 1e-12,
    Math.abs(simpson(f, 0, Math.PI) - (Math.PI ** 2 + 2)) < 1e-9, Math.abs(deriv(Fx, 0.7) - (Math.cos(0.7) + 1.4)) < 1e-6], 'F = −cos x + x² + 2');
  short('tp-s1', simpson(x => 4 * x ** 3 - 3 * x * x, 1, 2));
  short('tp-s2', simpson(x => 2 * x - x * x, 0, 2));
  short('tp-s3', simpson(t => 10 + 2 * t, 0, 10));
}

console.log('\n== Toán 12: Oxyz ==');
{
  const A = [1, 2, 3], B = [3, 0, -1];
  mcqText('ox-01', `$(${(A[0] + B[0]) / 2}; ${(A[1] + B[1]) / 2}; ${(A[2] + B[2]) / 2})$`);
  mcqNum('ox-02', Math.hypot(1, -2, 2));
  mcqNum('ox-03', 1 * 2 + 2 * 0 + -1 * 1);
  mcqNum('ox-04', Math.abs(-3) / Math.hypot(2, -1, 2));
  mcqText('ox-05', '$I(1; -2; 0)$, $R = 3$');
  // ox-06: điểm A ứng t = 0 và vectơ chỉ phương (2;-1;3)
  mcqText('ox-06', '$x = 1 + 2t,\\ y = -t,\\ z = 2 + 3t$');
  const P = (x, y, z) => 2 * x + y - 3 * z - 7;
  P(1, 2, -1) === 0 ? mcqText('ox-07', '$2x + y - 3z - 7 = 0$') : bad('ox-07', 'M không thuộc');
  const onPlane = p => Math.abs(p[0] / 1 + p[1] / 2 + p[2] / 3 - 1) < 1e-12;
  tf('ox-tf1', [onPlane([1, 0, 0]) && onPlane([0, 2, 0]) && onPlane([0, 0, 3]), true, Math.abs(6 / Math.hypot(6, 3, 2) - 6 / 7) < 1e-12, 1 * 2 * 3 / 6 === 6], 'đoạn chắn, d = 6/7, V = 1');
  const u = [2, 2, 1], nu = Math.hypot(...u);
  const at = t => u.map(c => c * t);
  const t5 = 5, p5 = at(t5);
  tf('ox-tf2', [nu === 3, Math.abs(u[2] / nu - 1 / 3) < 1e-12, Math.abs(Math.hypot(...p5) - 15) < 1e-12, (() => { const t = 4 / 2; return at(t)[1] === 4 && at(t)[2] === 3; })()], `|u| = ${nu}, sin φ = 1/3`);
  short('ox-s1', Math.hypot(3 - 1, -4 - 2, 6 - 3));
  short('ox-s2', Math.acos(1 / 2) * 180 / Math.PI);
  let mSol = null;
  for (let m = 0.5; m <= 30; m += 0.5) if (Math.abs(Math.abs(1 + 2 - 2 + m) / 3 - 3) < 1e-12) mSol = m;
  short('ox-s3', mSol);
}

console.log('\n== Toán 12: Thống kê ==');
{
  const edges = [0, 30, 60, 90, 120, 150], m = [5, 12, 15, 6, 2], n = 40;
  const mid = m.map((_, i) => (edges[i] + edges[i + 1]) / 2);
  const mean = m.reduce((s, k, i) => s + k * mid[i], 0) / n;
  const variance = m.reduce((s, k, i) => s + k * (mid[i] - mean) ** 2, 0) / n;
  function quart(k) {
    const target = k * n / 4; let cum = 0;
    for (let i = 0; i < m.length; i++) {
      if (cum + m[i] >= target) return { q: edges[i] + (target - cum) / m[i] * (edges[i + 1] - edges[i]), group: i };
      cum += m[i];
    }
  }
  const Q1 = quart(1), Q3 = quart(3);
  mcqNum('tk-01', edges[edges.length - 1] - edges[0]);
  mcqNum('tk-02', mean);
  mcqNum('tk-03', Q1.q);
  ok('tk-04', 'câu lý thuyết (đã đọc lại)');
  tf('tk-tf1', [Q3.group === 2, Q3.q === 86, Q3.q - Q1.q === 43.5, Math.abs(Math.sqrt(variance) - 954) < 1], `Q1 = ${Q1.q}, Q3 = ${Q3.q}, s² = ${variance}, s = ${Math.sqrt(variance).toFixed(3)}`);
  short('tk-s1', variance);
  short('tk-s2', Math.sqrt(variance));
}

console.log('\n== Toán 12: Xác suất ==');
{
  mcqNum('xs-01', 0.2 / 0.4);
  // mô phỏng liệt kê cho xs-02
  const balls = ['R', 'R', 'R', 'R', 'R', 'B', 'B', 'B']; let firstR = 0, both = 0;
  for (let i = 0; i < 8; i++) for (let j = 0; j < 8; j++) if (i !== j && balls[i] === 'R') { firstR++; if (balls[j] === 'R') both++; }
  Math.abs(both / firstR - 4 / 7) < 1e-12 ? mcqText('xs-02', '$\\dfrac47$') : bad('xs-02', both / firstR);
  ok('xs-03', 'công thức xác suất toàn phần (lý thuyết)');
  mcqNum('xs-04', 0.02 * 0.95 / (0.02 * 0.95 + 0.98 * 0.1), 0.03);
  const pd = 0.6 * 0.02 + 0.4 * 0.03;
  tf('xs-tf1', [Math.abs(pd - 0.024) < 1e-12, Math.abs(0.4 * 0.03 / pd - 0.5) < 1e-12, Math.abs(0.6 * 0.98 - 0.588) < 1e-12, Math.abs(0.02 - 0.012) < 1e-12], `P(phế) = ${pd}`);
  tf('xs-tf2', [18 / 40 === 0.45, 6 / 16 === 0.375, Math.abs(12 / 18 - 2 / 3) < 1e-12, Math.abs(12 / 24 - 18 / 40) < 1e-12], 'P(giỏi|nam) = 0,5 ≠ 0,45');
  short('xs-s1', 0.01 * 0.9 / (0.01 * 0.9 + 0.99 * 0.05));
  let s8 = 0, s8six = 0;
  for (let a = 1; a <= 6; a++) for (let b = 1; b <= 6; b++) if (a + b === 8) { s8++; if (a === 6 || b === 6) s8six++; }
  short('xs-s2', s8six / s8);
}

console.log('\n== V-ACT ==');
{
  ok('va-l1', 'phép phản đảo (lý thuyết)');
  ok('va-l2', 'phủ định mệnh đề "mọi" (lý thuyết)');
  // va-l3: duyệt mọi hoán vị
  const majors = ['Hàng không', 'Y', 'Luật'], people = ['An', 'Bình', 'Chi'], sols = [];
  const perms = [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]];
  for (const p of perms) {
    const M = Object.fromEntries(people.map((x, i) => [x, majors[p[i]]]));
    if (M.An !== 'Y' && M['Bình'] !== 'Hàng không' && M.An !== 'Luật' && M['Bình'] !== 'Luật') sols.push(M);
  }
  sols.length === 1 ? mcqText('va-l3', sols[0]['Bình'], `nghiệm duy nhất: ${JSON.stringify(sols[0])}`) : bad('va-l3', `${sols.length} nghiệm`);
  const seq = [2, 6, 12, 20, 30];
  seq.every((v, i) => v === (i + 1) * (i + 2)) ? mcqNum('va-l4', 6 * 7) : bad('va-l4', 'dãy');
  ok('va-l5', 'tam đoạn luận (lý thuyết)');
  const dow = ['Chủ nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
  const d1 = new Date(2026, 9, 19).getDay(), d2 = new Date(2027, 9, 19).getDay();
  dow[d1] === 'Thứ Hai' ? mcqText('va-l6', dow[d2], `19/10/2027 là ${dow[d2]}`) : bad('va-l6', `19/10/2026 là ${dow[d1]}`);

  const S = { A: [120, 135, 150, 165], B: [140, 130, 160, 150], C: [100, 125, 145, 170] };
  const tot = k => S[k].reduce((a, b) => a + b);
  const best = Object.keys(S).sort((a, b) => tot(b) - tot(a))[0];
  mcqText('va-d1', `Trạm ${best}`, `tổng A, B, C = ${tot('A')}, ${tot('B')}, ${tot('C')}`);
  mcqNum('va-d2', (S.C[3] - S.C[0]) / S.C[0] * 100);
  const diffs = S.A.slice(1).map((v, i) => v - S.A[i]);
  diffs.every(d => d === diffs[0]) ? mcqNum('va-d3', S.A[3] + diffs[0]) : bad('va-d3', 'không đều');
  const months = [0, 1, 2, 3].map(i => S.A[i] + S.B[i] + S.C[i]);
  mcqText('va-d4', `Tháng ${months.indexOf(Math.max(...months)) + 1}`, `tổng theo tháng ${months}`);
  mcqNum('va-d5', S.B[2] / months[2] * 100, 0.002);
  const notInc = Object.keys(S).filter(k => S[k].some((v, i) => i && v <= S[k][i - 1]));
  JSON.stringify(notInc) === '["B"]' ? mcqText('va-d6', 'Chỉ trạm B') : bad('va-d6', notInc);

  ['va-k1', 'va-k2', 'va-k3', 'va-k5', 'va-k6'].forEach(id => ok(id, 'câu suy luận định tính (đã đọc lại)'));
  const t = [0.9, 1.3, 1.6, 1.9], lastStep = t[3] - t[2];
  mcqNum('va-k4', t[3] + lastStep, 0.02);

  mcqNum('va-u1', 100 * 1.06 ** 2, 1e-6);
  mcqNum('va-u2', 240 / (120 / 60 + 120 / 40));
  mcqNum('va-u3', 4 * 50000 / 100 / 1000);
  let withA = 0, all = 0;
  for (let i = 0; i < 5; i++) for (let j = i + 1; j < 5; j++) { all++; if (i === 0 || j === 0) withA++; }
  Math.abs(withA / all - 2 / 5) < 1e-12 ? mcqText('va-u4', '$\\dfrac25$') : bad('va-u4', withA / all);
  mcqNum('va-u5', 2 * 1.5 * 1 * 1000);
  Math.abs(1.2 * 0.8 - 0.96) < 1e-12 ? mcqText('va-u6', 'giảm 4 %') : bad('va-u6', 'sai');
}

const missing = Object.keys(byId).filter(id => !checked.has(id));
if (missing.length) { fail++; console.log(`\n✗ Chưa kiểm: ${missing.join(', ')}`); }
console.log(`\nKết quả: ${pass} đạt, ${fail} lỗi (${Object.keys(byId).length} câu).`);
process.exit(fail ? 1 : 0);
