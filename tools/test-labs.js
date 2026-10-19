#!/usr/bin/env node
// Kiểm thử lõi Phòng thí nghiệm ảo: khí 2D tuân theo pS = NkT, định luật Boyle,
// phân bố Maxwell, phân rã phóng xạ theo 2^(-t/T), máy phát & từ thông lưỡng cực.
'use strict';
const path = require('path');
const L = require(path.join(__dirname, '../projects/04-phong-thi-nghiem-ao/labs-core.js'));
let pass = 0, fail = 0;
const check = (c, m) => { c ? pass++ : fail++; console.log(`  ${c ? '✓' : '✗'} ${m}`); };

console.log('== Khí lí tưởng 2D ==');
function measure(opts, warm, run) {
  const g = new L.Gas(opts);
  const dt = 0.002;
  for (let t = 0; t < warm; t += dt) g.step(dt);
  g.window = run;
  for (let t = 0; t < run; t += dt) { g.step(dt); }
  return { g, p: g.pressure(), T: g.temperature() };
}
{
  // Không ổn nhiệt: năng lượng phải bảo toàn (va chạm đàn hồi)
  const g = new L.Gas({ N: 200, thermostat: false, seed: 3 });
  const T0 = g.temperature();
  for (let i = 0; i < 2000; i++) g.step(0.002);
  check(Math.abs(g.temperature() / T0 - 1) < 1e-9, `không ổn nhiệt: bảo toàn năng lượng (ΔT/T = ${(g.temperature() / T0 - 1).toExponential(1)})`);
  const out = g.p.filter(a => a.x < 0 || a.x > g.W || a.y < 0 || a.y > g.H).length;
  check(out === 0, 'không phân tử nào thoát khỏi hộp');
}
{
  const m = measure({ N: 200, T: 1, W: 1, seed: 5 }, 2, 6);
  const ratio = m.p * m.g.area() / (m.g.p.length * m.T);
  check(Math.abs(ratio - 1) < 0.06, `pS/(NkT) = ${ratio.toFixed(3)} (≈ 1, lệch nhỏ do kích thước phân tử)`);
}
{
  // Boyle: giữ T, đổi diện tích → pS không đổi
  const a = measure({ N: 200, T: 1, W: 1.4, seed: 8 }, 2, 6), b = measure({ N: 200, T: 1, W: 0.7, seed: 9 }, 2, 6);
  const pa = a.p * a.g.area(), pb = b.p * b.g.area();
  check(Math.abs(pa / pb - 1) < 0.08, `Boyle: pS ở S = 1,4 và 0,7 lần lượt ${pa.toFixed(1)} và ${pb.toFixed(1)} (lệch ${(100 * Math.abs(pa / pb - 1)).toFixed(1)} %)`);
  check(b.p / a.p > 1.8 && b.p / a.p < 2.25, `giảm S một nửa → p tăng ${(b.p / a.p).toFixed(2)} lần (≈ 2)`);
}
{
  // Đẳng tích: p tỉ lệ T
  const a = measure({ N: 200, T: 1, W: 1, seed: 11 }, 2, 6), b = measure({ N: 200, T: 2, W: 1, seed: 12 }, 2, 6);
  check(Math.abs(b.p / a.p - 2) < 0.15, `T tăng gấp đôi → p tăng ${(b.p / a.p).toFixed(2)} lần (≈ 2)`);
}
{
  // Phân bố tốc độ sau khi thả tất cả với cùng tốc độ (không ổn nhiệt) → tiến về Maxwell 2D
  const g = new L.Gas({ N: 300, thermostat: false, seed: 21 });
  g.p.forEach((a, i) => { const ang = i * 2.4; a.vx = Math.cos(ang) * Math.SQRT2; a.vy = Math.sin(ang) * Math.SQRT2; });
  for (let i = 0; i < 6000; i++) g.step(0.002);
  const T = g.temperature();
  const speeds = g.p.map(a => Math.hypot(a.vx, a.vy));
  // so sánh tỉ lệ có tốc độ < v_mp = sqrt(T): lý thuyết 1 - e^{-1/2} ≈ 0,393
  const frac = speeds.filter(v => v < Math.sqrt(T)).length / speeds.length;
  check(Math.abs(frac - (1 - Math.exp(-0.5))) < 0.08, `va chạm làm tốc độ phân bố theo Maxwell 2D: tỉ lệ v < √(kT/m) = ${frac.toFixed(3)} (lý thuyết 0,393)`);
  let integral = 0; for (let v = 0; v < 10; v += 0.001) integral += L.maxwell2D(v, T) * 0.001;
  check(Math.abs(integral - 1) < 1e-3, `hàm phân bố chuẩn hóa: ∫f dv = ${integral.toFixed(4)}`);
}
{
  // Nén nhanh không ổn nhiệt → nóng lên (đoạn nhiệt)
  const g = new L.Gas({ N: 200, thermostat: false, W: 1.4, seed: 30 });
  const T0 = g.temperature();
  g.wallU = -0.5;
  for (let t = 0; t < 1.2; t += 0.002) g.step(0.002);
  g.wallU = 0;
  check(g.temperature() > T0 * 1.2, `nén đoạn nhiệt (S: 1,4 → ${g.W.toFixed(2)}): T tăng ${(g.temperature() / T0).toFixed(2)} lần`);
}

console.log('\n== Phân rã phóng xạ ==');
{
  const d = new L.Decay(20000, 1, 99);
  for (let i = 0; i < 100; i++) d.step(0.01);   // t = 1 = T
  check(Math.abs(d.N / 20000 - 0.5) < 0.015, `sau 1 chu kì còn ${(100 * d.N / 20000).toFixed(1)} % (≈ 50 %)`);
  for (let i = 0; i < 200; i++) d.step(0.01);   // t = 3T
  check(Math.abs(d.N / 20000 - 0.125) < 0.01, `sau 3 chu kì còn ${(100 * d.N / 20000).toFixed(1)} % (≈ 12,5 %)`);
  check(d.history.length === 301 && Math.abs(d.theory(3) - 2500) < 1e-9, 'lưu lịch sử và đường lý thuyết đúng');
  // Kết quả không phụ thuộc bước thời gian
  const e = new L.Decay(20000, 1, 5);
  for (let i = 0; i < 4; i++) e.step(0.25);
  check(Math.abs(e.N / 20000 - 0.5) < 0.015, `bước thời gian lớn (0,25T) vẫn cho ${(100 * e.N / 20000).toFixed(1)} % sau 1 chu kì`);
}

console.log('\n== Cảm ứng điện từ ==');
{
  const g = L.generator(100, 0.1, 0.04, 50, 0.003);
  check(Math.abs(g.E0 - 40 * Math.PI) < 1e-9, `E₀ = NBSω = ${g.E0.toFixed(2)} V (khớp câu tu-s4 của P1)`);
  check(Math.abs(g.E - 88.86) < 0.01, `E hiệu dụng = ${g.E.toFixed(2)} V`);
  // e = -dΦ/dt kiểm bằng sai phân
  const h = 1e-7, d = -(L.generator(100, 0.1, 0.04, 50, 0.003 + h).phi - L.generator(100, 0.1, 0.04, 50, 0.003 - h).phi) / (2 * h);
  check(Math.abs(d - g.e) < 1e-4, 'e(t) = −dΦ/dt (kiểm bằng đạo hàm số)');
  check(L.dipoleFlux(0, 1, 5) === 5 && L.dipoleFlux(2, 1, 5) < L.dipoleFlux(1, 1, 5), 'từ thông lưỡng cực lớn nhất ở tâm, giảm khi ra xa');
}
console.log(`\nKết quả: ${pass} đạt, ${fail} lỗi.`);
process.exit(fail ? 1 : 0);
