#!/usr/bin/env node
// Tính lại ĐỘC LẬP mọi đáp số trong ngân hàng Vật lý 12 và so với đáp án đã soạn.
// Cách dùng: node tools/verify-vatly12.js
'use strict';
const path = require('path');
const { loadBanks } = require('./lib/load-bank');
const { parseNumber, close, isCorrectRounding } = require('./lib/numcheck');

const bank = loadBanks([path.join(__dirname, '../projects/01-on-thi-vat-ly-12/banks/vatly12.js')]).vatly12;
const byId = Object.fromEntries(bank.questions.map(q => [q.id, q]));

// Hằng số (đúng như ghi trong đề)
const R = 8.31, k = 1.38e-23, NA = 6.02e23, u = 931.5, mp = 1.0073, mn = 1.0087, MeV = 1.6e-13;
const DAY = 86400, LN2 = Math.LN2;

let pass = 0, fail = 0;
const ok = (id, msg) => { pass++; console.log(`  ✓ ${id}: ${msg}`); };
const bad = (id, msg) => { fail++; console.log(`  ✗ ${id}: ${msg}`); };

// MCQ: phương án đúng phải khớp giá trị tính được (sai số tương đối rel),
// và KHÔNG phương án nhiễu nào được khớp.
// mustInclude: khi phương án nhiễu cùng con số nhưng khác chữ (tăng/giảm, tỏa/thu),
// phương án đúng phải chứa cụm từ này.
function mcq(id, value, rel = 0.01, mustInclude) {
  const q = byId[id];
  if (!q) return bad(id, 'không tìm thấy');
  const nums = q.choices.map(parseNumber);
  const right = nums[q.answer];
  if (!close(right, value, rel)) return bad(id, `phương án đúng ${right} ≠ tính được ${value}`);
  const clash = q.choices.filter((c, i) => i !== q.answer && close(nums[i], value, rel));
  if (clash.length && !mustInclude) return bad(id, `phương án nhiễu trùng giá trị đúng (${clash})`);
  if (mustInclude && !q.choices[q.answer].includes(mustInclude)) return bad(id, `phương án đúng thiếu "${mustInclude}"`);
  if (mustInclude && clash.some(c => c.includes(mustInclude))) return bad(id, `phương án nhiễu cũng chứa "${mustInclude}"`);
  ok(id, `${right} ≈ ${+value.toPrecision(5)}${mustInclude ? ` + "${mustInclude}"` : ''}`);
}
// Kiểm phương án đúng chứa đúng chuỗi kỳ vọng (câu có nhiều con số / kí hiệu hạt nhân)
function mcqText(id, expected, note) {
  const q = byId[id];
  if (!q) return bad(id, 'không tìm thấy');
  if (!q.choices[q.answer].includes(expected)) return bad(id, `phương án đúng "${q.choices[q.answer]}" không chứa "${expected}"`);
  if (q.choices.some((c, i) => i !== q.answer && c.includes(expected))) return bad(id, `phương án nhiễu cũng chứa "${expected}"`);
  ok(id, note);
}
// Trả lời ngắn: đáp án là giá trị làm tròn đúng; nằm trong tol.
function short(id, value) {
  const q = byId[id];
  if (!q) return bad(id, 'không tìm thấy');
  const a = parseFloat(String(q.answer).replace(',', '.'));
  if (!isCorrectRounding(q.answer, value)) return bad(id, `đáp án ${q.answer} không phải làm tròn của ${value}`);
  ok(id, `${q.answer} ← ${+value.toPrecision(6)}${q.tol ? ` (tol ±${q.tol})` : ''}`);
  return a;
}
// Đúng/Sai: so mệnh đề với kết quả tính
function tf(id, i, truth, note) {
  const q = byId[id];
  const st = q && q.statements[i];
  if (!st) return bad(`${id}[${i}]`, 'không tìm thấy');
  if (st.a !== truth) return bad(`${id}[${'abcd'[i]}]`, `đáp án ghi ${st.a} nhưng tính được ${truth} (${note})`);
  ok(`${id}[${'abcd'[i]}]`, `${truth ? 'Đúng' : 'Sai'} — ${note}`);
}
const approx = (a, b, rel = 0.01) => close(a, b, rel);

console.log('== Chương I. Vật lí nhiệt ==');
mcq('nhiet-03', 27 + 273);
mcq('nhiet-06', 100 - 40);
mcq('nhiet-09', 2 * 4200 * 80 / 1000);
mcq('nhiet-10', 3.34e5 * 0.5 / 1000);
{ const t = (0.2 * 380 * 100 + 0.5 * 4200 * 20) / (0.2 * 380 + 0.5 * 4200); mcq('nhiet-11', t, 0.002); }
mcq('nhiet-12', 500 - 200, 0.01, 'tăng');
{ const P_over_m = 3.34e5 / 334; mcq('nhiet-14', 4180 * 100 / P_over_m); }
{
  const Q1 = 3.34e5 * 0.1, Q2 = 0.3 * 4180 * 30;
  const t = (0.3 * 4180 * 30 - Q1) / (0.3 * 4180 + 0.1 * 4180);
  tf('nhiet-tf3', 0, approx(Q1, 33400, 1e-6), `Q1 = ${Q1}`);
  tf('nhiet-tf3', 1, approx(Q2, 37620, 1e-6), `Q2 = ${Q2}`);
  tf('nhiet-tf3', 2, !(Q2 > Q1), `Q2 > Q1 nên tan hết`);
  tf('nhiet-tf3', 3, Math.abs(t - 2.5) < 0.05, `t = ${t.toFixed(3)} °C`);
}
tf('nhiet-tf2', 2, 800 - 300 === 500, 'ΔU = 500 J');
tf('nhiet-tf4', 3, (40 + 273) / (20 + 273) === 2, `313/293 = ${(313 / 293).toFixed(3)}`);
short('nhiet-s1', 2 * 4200 * 75 / 1000);
short('nhiet-s2', 2.3e6 * 0.2 / 1000);
short('nhiet-s3', 150 - 60);
short('nhiet-s4', 11400 / (0.5 * 60));
short('nhiet-s5', (1 * 4200 * 80 / 0.8) / 1000 / 60);
short('nhiet-s6', (0.4 * 460 * 200 + 4200 * 25) / (0.4 * 460 + 4200));

console.log('\n== Chương II. Khí lí tưởng ==');
mcq('khi-04', 0.75 * 4 / (6 - 4));
mcq('khi-05', 2 * 300 - 273);
mcq('khi-09', 1.5 * k * 300);
mcq('khi-10', 3e5 * 8.31e-3 / (R * 300));
mcq('khi-11', 1 * 10 / 4 * 360 / 300);
mcq('khi-13', (1e5 + 1000 * 10 * 10) / 1e5, 0.01, 'tăng');
mcq('khi-14', Math.sqrt(3 * 1e5 / 1.2));
mcq('khi-15', 1.01e5 / (k * 273), 0.005);
mcq('khi-12', Math.sqrt(4), 0.01, 'tăng 2');
{
  const V2 = 2 * 400 / 300, n = 1.5e5 * 2e-3 / (R * 300);
  tf('khi-tf2', 0, Math.abs(V2 - 2.67) < 0.005, `V2 = ${V2.toFixed(4)} L`);
  tf('khi-tf2', 2, Math.abs(n - 0.12) < 0.005, `n = ${n.toFixed(4)} mol`);
}
{
  const p2 = 2 * 450 / 300, Tmax = 300 * 3.5 / 2;
  tf('khi-tf4', 1, p2 === 3, `p2 = ${p2} atm`);
  tf('khi-tf4', 3, Tmax - 273 === 525, `Tmax = ${Tmax} K = ${Tmax - 273} °C`);
}
short('khi-s1', 1 * 12 / 3);
short('khi-s2', 0.5 * R * 300 / 10e-3 / 1e5);
short('khi-s3', 10 * 360 / 300);
short('khi-s4', 2 * 8.28e-21 / (3 * k));
short('khi-s5', 2.0 * 315 / 300);
short('khi-s6', (1.5e5 - 1e5) / (1000 * 10));

console.log('\n== Chương III. Từ trường ==');
mcq('tu-05', 0.04 * 5 * 0.2);
mcq('tu-07', 0.1 * 20e-4 * Math.cos(Math.PI / 3));
mcq('tu-09', 100 * 0.5 * 50e-4 / 0.1);
mcq('tu-12', 200 * 0.2 * 100e-4 * 100 * Math.PI, 0.001);
mcq('tu-14', 220 * Math.SQRT2, 0.002);
mcq('tu-15', 3e8 / 100e6);
mcqText('tu-10', `$${2 * Math.SQRT2 / Math.SQRT2 | 0}\\unit{A}$; $${100 * Math.PI / (2 * Math.PI)}\\unit{Hz}$`, 'I = 2 A, f = 50 Hz');
{
  const F = 0.2 * 4 * 0.5;
  tf('tu-tf1', 0, approx(F, 0.4, 1e-9), `F = ${F} N`);
  tf('tu-tf1', 1, approx(F * Math.sin(Math.PI / 6), 0.2, 1e-9), `F = ${F * 0.5} N`);
  const u0 = 220 * Math.SQRT2 * Math.cos(Math.PI / 3);
  tf('tu-tf3', 1, 100 * Math.PI / (2 * Math.PI) === 100, `f = 50 Hz`);
  tf('tu-tf3', 2, approx(1 / 50, 0.02, 1e-9), 'T = 0,02 s');
  tf('tu-tf3', 3, approx(u0, 110 * Math.SQRT2, 1e-9), `u(0) = ${u0.toFixed(2)} V`);
}
short('tu-s1', 0.05 * 10 * 0.2);
short('tu-s2', 0.5 * 0.04 * Math.cos(Math.PI / 3) * 1000);
short('tu-s3', 500 * 4e-3 / 0.1);
short('tu-s4', 100 * 0.1 * 400e-4 * 2 * Math.PI * 50 / Math.SQRT2);
short('tu-s5', Math.pow(4 / Math.SQRT2, 2) * 10);
short('tu-s6', 3e8 / 25 / 1e6);

console.log('\n== Chương IV. Vật lí hạt nhân ==');
{
  const dm = 2 * mp + 2 * mn - 4.0015;
  mcq('hn-08', dm * u, 0.005);
  console.log(`    (He-4: Δm = ${dm.toFixed(4)} u, W/A = ${(dm * u / 4).toFixed(3)} MeV/nucleon)`);
}
mcq('hn-09', ((2.0136 + 3.0155) - (4.0015 + 1.0087)) * u, 0.005, 'tỏa');
mcq('hn-10', 100 / 8);
mcq('hn-12', LN2 / (138 * DAY), 0.005);
mcq('hn-14', 1 / 235 * NA * 200 * MeV, 0.01);
{
  const dm = 26 * mp + 30 * mn - 55.9207, W = dm * u, eps = W / 56;
  tf('hn-tf1', 1, Math.abs(dm - 0.530) < 0.0005, `Δm = ${dm.toFixed(4)} u`);
  tf('hn-tf1', 2, Math.abs(eps - 8.8) < 0.05, `ε = ${eps.toFixed(3)} MeV/nucleon`);
  tf('hn-tf1', 3, eps < 7.1, `ε_Fe = ${eps.toFixed(2)} > 7,1`);
}
{
  const Pth = 1000e6 / 0.33, rate = Pth / (200 * MeV), perDay = rate * DAY, kg = perDay / NA * 235 / 1000;
  tf('hn-tf4', 1, approx(Pth, 330e6, 0.01), `P = ${(Pth / 1e6).toFixed(0)} MW`);
  tf('hn-tf4', 2, approx(rate, 9.5e19, 0.01), `${rate.toExponential(3)} phân hạch/s`);
  tf('hn-tf4', 3, approx(kg, 32, 0.05), `${kg.toFixed(2)} kg/ngày`);
}
tf('hn-tf3', 0, (14 + 4 - 17 === 1) && (7 + 2 - 8 === 1), 'A = 1, Z = 1');
short('hn-s1', 238 - 92);
mcqText('hn-01', `${235 - 92} neutron`, 'N = 235 − 92 = 143');
mcqText('hn-05', `\\nuc{${226 - 4}}{${88 - 2}}{Rn}`, 'α: A − 4, Z − 2 → Rn-222');
{ const dm = 6 * mp + 6 * mn - 11.9967; short('hn-s2', dm * u / 12); }
short('hn-s3', 100 * Math.pow(2, -15 / 5));
short('hn-s4', 2 * 3.8);
short('hn-s5', LN2 / (3.8 * DAY) * 2.0e15 / 1e9);
short('hn-s6', ((7.0144 + 1.0073) - 2 * 4.0015) * u);

// Mọi câu trả lời ngắn và mọi câu MCQ có số liệu đều phải được kiểm ở trên
const numericMcq = bank.questions.filter(q => q.type === 'mcq' && q.choices.every(c => !isNaN(parseNumber(c))));
const checkedIds = new Set(require('fs').readFileSync(__filename, 'utf8').match(/'(nhiet|khi|tu|hn)-[\w]+'/g).map(s => s.slice(1, -1)));
const missing = bank.questions
  .filter(q => q.type === 'short' || numericMcq.includes(q))
  .filter(q => !checkedIds.has(q.id))
  .map(q => q.id);
// Các câu MCQ có số nhưng là kiến thức thuần (không cần tính) được liệt kê ở đây
const conceptual = new Set(['nhiet-08', 'hn-07', 'tu-02']);
const reallyMissing = missing.filter(id => !conceptual.has(id));
if (reallyMissing.length) { fail++; console.log(`\n✗ Chưa có kiểm tra cho: ${reallyMissing.join(', ')}`); }

console.log(`\nKết quả: ${pass} đạt, ${fail} lỗi.`);
process.exit(fail ? 1 : 0);
