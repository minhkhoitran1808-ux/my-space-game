#!/usr/bin/env node
// Kiểm thử lõi vật lý Orbit Lab: so với giá trị tham chiếu và kiểm tra độ chính xác số.
// Cách dùng: node tools/test-orbit.js
'use strict';
const path = require('path');
const O = require(path.join(__dirname, '../projects/02-orbit-lab/orbit.js'));

let pass = 0, fail = 0;
function near(name, got, want, tolRel) {
  const ok = Math.abs(got - want) <= Math.abs(want) * tolRel;
  ok ? pass++ : fail++;
  console.log(`  ${ok ? '✓' : '✗'} ${name}: ${+got.toPrecision(6)} (kỳ vọng ${want} ±${(tolRel * 100).toFixed(2)}%)`);
}
function truthy(name, cond, extra) {
  cond ? pass++ : fail++;
  console.log(`  ${cond ? '✓' : '✗'} ${name}${extra ? ' — ' + extra : ''}`);
}

const E = O.BODIES.earth, S = O.BODIES.sun;

console.log('== Công thức giải tích (so với giá trị tham chiếu) ==');
near('v₁ tại mặt đất (km/s)', O.vCircular(E.mu, E.R) / 1e3, 7.91, 0.002);
near('v₂ tại mặt đất (km/s)', O.vEscape(E.mu, E.R) / 1e3, 11.19, 0.002);
near('v tròn ở độ cao 400 km (km/s)', O.vCircular(E.mu, E.R + 400e3) / 1e3, 7.67, 0.002);
near('chu kì ở độ cao 400 km (phút)', O.period(E.mu, E.R + 400e3) / 60, 92.4, 0.003);
near('bán kính quỹ đạo địa tĩnh (km)', O.semiMajorFromPeriod(E.mu, O.SIDEREAL_DAY) / 1e3, 42164, 0.0005);
near('chu kì Sao Hỏa (năm) — Kepler III', O.period(S.mu, 1.523679 * O.AU) / O.period(S.mu, O.AU), 1.8808, 0.001);

console.log('\n== Hohmann ==');
const em = O.hohmann(S.mu, O.AU, 1.523679 * O.AU);
near('Trái Đất→Sao Hỏa Δv₁ (km/s)', em.dv1 / 1e3, 2.94, 0.01);
near('Trái Đất→Sao Hỏa Δv₂ (km/s)', em.dv2 / 1e3, 2.65, 0.01);
near('Trái Đất→Sao Hỏa thời gian bay (ngày)', em.tTransfer / O.DAY, 259, 0.005);
near('Trái Đất→Sao Hỏa góc pha lúc phóng (độ)', em.phase * 180 / Math.PI, 44.3, 0.01);
near('chu kì giao hội Trái Đất–Sao Hỏa (ngày)', em.synodic / O.DAY, 780, 0.005);
near('Δv thoát từ LEO 300 km để đi Sao Hỏa (km/s)', O.departureDv(E.mu, E.R + 300e3, em.dv1) / 1e3, 3.6, 0.02);
const lg = O.hohmann(E.mu, 6678e3, 42164e3);
near('LEO 300 km→GEO tổng Δv (km/s)', lg.dvTotal / 1e3, 3.89, 0.005);
near('LEO 300 km→GEO thời gian (giờ)', lg.tTransfer / 3600, 5.27, 0.005);
const inward = O.hohmann(S.mu, O.AU, 0.723332 * O.AU);
truthy('Hohmann vào trong (đi Sao Kim): Δv₁ < 0 (phải hãm tốc)', inward.dv1 < 0, `Δv₁ = ${(inward.dv1 / 1e3).toFixed(3)} km/s`);

console.log('\n== Tsiolkovsky ==');
near('Isp 300 s, m0/mf = e → Δv (m/s)', O.tsiolkovsky(300, Math.E, 1), 300 * 9.80665, 1e-12);
const st = O.rocketStages([{ mProp: 90, mDry: 10, isp: 300 }, { mProp: 18, mDry: 2, isp: 350 }], 5);
// Tầng 1: m0 = 125, mf = 35 ; tầng 2: m0 = 25, mf = 7
near('tên lửa 2 tầng: Δv tầng 1', st.stages[0].dv, 300 * 9.80665 * Math.log(125 / 35), 1e-12);
near('tên lửa 2 tầng: Δv tầng 2', st.stages[1].dv, 350 * 9.80665 * Math.log(25 / 7), 1e-12);
near('tên lửa 2 tầng: khối lượng cất cánh', st.liftoffMass, 125, 1e-12);

console.log('\n== Phần tử quỹ đạo từ trạng thái ==');
const r0 = E.R + 400e3, vc = O.vCircular(E.mu, r0);
const elC = O.elements(E.mu, { x: r0, y: 0, vx: 0, vy: vc });
truthy('quỹ đạo tròn có e ≈ 0', elC.e < 1e-12, `e = ${elC.e.toExponential(2)}`);
const elEsc = O.elements(E.mu, { x: r0, y: 0, vx: 0, vy: O.vEscape(E.mu, r0) });
truthy('v = v₂ → cơ năng ≈ 0, e ≈ 1', Math.abs(elEsc.energy) < 1e-6 * Math.abs(elC.energy) && Math.abs(elEsc.e - 1) < 1e-12);
const elE = O.elements(E.mu, { x: r0, y: 0, vx: 0, vy: 1.1 * vc });
near('elip v = 1,1·v₁: cận điểm = r₀', elE.rp, r0, 1e-12);
near('elip v = 1,1·v₁: e = 1,1² − 1', elE.e, 0.21, 1e-12);

console.log('\n== Tích phân số (velocity-Verlet, bước thích nghi) ==');
function runOrbits(v0factor, orbits, eta) {
  const s0 = { x: r0, y: 0, vx: 0, vy: v0factor * vc, t: 0 };
  const el0 = O.elements(E.mu, s0);
  const s = O.propagate(E.mu, s0, orbits * el0.T, { eta });
  const el1 = O.elements(E.mu, s);
  return { el0, el1, s, dE: Math.abs((el1.energy - el0.energy) / el0.energy), dh: Math.abs((el1.h - el0.h) / el0.h),
    dPos: Math.hypot(s.x - s0.x, s.y - s0.y) / r0 };
}
let res = runOrbits(1.0, 10, 0.002);
truthy('tròn, 10 vòng: sai lệch năng lượng < 1e-6', res.dE < 1e-6, `|ΔE/E| = ${res.dE.toExponential(2)}, ${res.s.steps} bước`);
truthy('tròn, 10 vòng: về đúng điểm xuất phát (< 0,1 % r)', res.dPos < 1e-3, `lệch ${(res.dPos * 100).toExponential(2)} %`);
res = runOrbits(1.3, 10, 0.002);
truthy(`elip e = ${res.el0.e.toFixed(2)}, 10 vòng: |ΔE/E| < 1e-3`, res.dE < 1e-3, `|ΔE/E| = ${res.dE.toExponential(2)}, ${res.s.steps} bước`);
truthy('elip, 10 vòng: bảo toàn mômen động lượng < 1e-9', res.dh < 1e-9, `|Δh/h| = ${res.dh.toExponential(2)}`);
truthy('elip, 10 vòng: quay về gần điểm xuất phát (chu kì số khớp Kepler III, < 1 % r)', res.dPos < 1e-2, `lệch ${(res.dPos * 100).toFixed(3)} %`);
// Định luật II Kepler: diện tích quét trong các khoảng thời gian bằng nhau
{
  const s0 = { x: r0, y: 0, vx: 0, vy: 1.3 * vc, t: 0 };
  const T = O.elements(E.mu, s0).T, N = 8;
  let s = s0; const areas = [];
  for (let i = 0; i < N; i++) {
    let A = 0, prev = s;
    s = O.propagate(E.mu, s, T / N, { onStep: c => { A += 0.5 * (prev.x * c.y - prev.y * c.x); prev = c; } });
    areas.push(A);
  }
  const mean = areas.reduce((a, b) => a + b) / N;
  const spread = Math.max(...areas.map(a => Math.abs(a / mean - 1)));
  truthy('Kepler II: 8 hình quạt cùng Δt có diện tích bằng nhau (< 0,1 %)', spread < 1e-3, `lệch tối đa ${(spread * 100).toFixed(4)} %`);
}
// Va chạm
{
  const s = O.propagate(E.mu, { x: r0, y: 0, vx: 0, vy: 0.5 * vc, t: 0 }, 1e5, { stopRadius: E.R });
  truthy('vận tốc quá nhỏ → rơi xuống, phát hiện va chạm', !!s.crashed);
}
// Kepler equation
{
  let worst = 0;
  for (const e of [0, 0.1, 0.5, 0.9, 0.99]) for (let M = 0; M < 6.28; M += 0.37) {
    const Ek = O.solveKepler(M, e);
    worst = Math.max(worst, Math.abs(Ek - e * Math.sin(Ek) - M));
  }
  truthy('giải phương trình Kepler (e tới 0,99): sai số < 1e-10', worst < 1e-10, `max ${worst.toExponential(2)}`);
}

console.log(`\nKết quả: ${pass} đạt, ${fail} lỗi.`);
process.exit(fail ? 1 : 0);
