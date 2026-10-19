/* ==========================================================================
   Orbit Lab — lõi vật lý (không phụ thuộc giao diện, chạy được cả trong Node)
   Đơn vị SI: mét, giây, kg. Bài toán 2 vật, vật trung tâm cố định, phẳng (2D).
   ========================================================================== */
(function (root) {
  'use strict';

  var G0 = 9.80665;               // gia tốc trọng trường chuẩn (m/s²) — dùng trong Tsiolkovsky
  var AU = 1.495978707e11;        // đơn vị thiên văn (m)
  var DAY = 86400;
  var SIDEREAL_DAY = 86164.0905;  // ngày sao (s)

  /* Vật trung tâm. μ = GM (m³/s²) — giá trị chuẩn (IAU/NASA), bán kính trung bình. */
  var BODIES = {
    earth: { name: 'Trái Đất', mu: 3.986004418e14, R: 6.371e6, color: '#4f8fe6', atm: 1.0e5 },
    moon: { name: 'Mặt Trăng', mu: 4.9048695e12, R: 1.7374e6, color: '#b9b9b9', atm: 0 },
    mars: { name: 'Sao Hỏa', mu: 4.282837e13, R: 3.3895e6, color: '#d0643a', atm: 1.1e5 },
    sun: { name: 'Mặt Trời', mu: 1.32712440018e20, R: 6.957e8, color: '#f6c344', atm: 0 }
  };

  /* Bán trục lớn quỹ đạo các hành tinh (AU) — coi gần đúng là quỹ đạo tròn, đồng phẳng. */
  var PLANETS = {
    mercury: { name: 'Sao Thủy', a: 0.387098, color: '#a9a29a' },
    venus: { name: 'Sao Kim', a: 0.723332, color: '#e3c27a' },
    earth: { name: 'Trái Đất', a: 1.000000, color: '#4f8fe6' },
    mars: { name: 'Sao Hỏa', a: 1.523679, color: '#d0643a' },
    jupiter: { name: 'Sao Mộc', a: 5.2026, color: '#d8a46a' },
    saturn: { name: 'Sao Thổ', a: 9.5549, color: '#e6d08f' }
  };

  /* ---------------- Công thức giải tích ---------------- */
  function vCircular(mu, r) { return Math.sqrt(mu / r); }               // vận tốc vũ trụ cấp I (ở bán kính r)
  function vEscape(mu, r) { return Math.sqrt(2 * mu / r); }             // vận tốc vũ trụ cấp II
  function period(mu, a) { return 2 * Math.PI * Math.sqrt(a * a * a / mu); } // định luật III Kepler
  function semiMajorFromPeriod(mu, T) { return Math.cbrt(mu * T * T / (4 * Math.PI * Math.PI)); }
  function visViva(mu, r, a) { return Math.sqrt(mu * (2 / r - 1 / a)); } // vis-viva

  /* Phần tử quỹ đạo từ trạng thái (x, y, vx, vy) */
  function elements(mu, s) {
    var r = Math.hypot(s.x, s.y);
    var v2 = s.vx * s.vx + s.vy * s.vy;
    var h = s.x * s.vy - s.y * s.vx;                 // mômen động lượng riêng (thành phần z)
    var energy = v2 / 2 - mu / r;                    // cơ năng riêng (J/kg)
    var rv = s.x * s.vx + s.y * s.vy;
    var ex = ((v2 - mu / r) * s.x - rv * s.vx) / mu;  // vectơ lệch tâm
    var ey = ((v2 - mu / r) * s.y - rv * s.vy) / mu;
    var e = Math.hypot(ex, ey);
    var p = h * h / mu;                              // tham số tiêu (semi-latus rectum)
    var out = { r: r, v: Math.sqrt(v2), h: h, energy: energy, e: e, ex: ex, ey: ey, p: p,
      omega: Math.atan2(ey, ex), bound: energy < 0 };
    out.rp = p / (1 + e);                            // bán kính cận điểm
    if (energy < 0) {
      out.a = -mu / (2 * energy);
      out.ra = e < 1 ? p / (1 - e) : Infinity;
      out.T = period(mu, out.a);
    } else {
      out.a = energy > 0 ? -mu / (2 * energy) : Infinity; // a < 0 với hypebol
      out.ra = Infinity;
      out.T = Infinity;
    }
    return out;
  }

  /* Gia tốc hấp dẫn */
  function accel(mu, x, y) {
    var r2 = x * x + y * y, r = Math.sqrt(r2), k = -mu / (r2 * r);
    return { ax: k * x, ay: k * y };
  }

  /* Một bước velocity-Verlet (đối xứng thời gian, bảo toàn năng lượng tốt) */
  function verletStep(mu, s, dt) {
    var a0 = s.ax == null ? accel(mu, s.x, s.y) : { ax: s.ax, ay: s.ay };
    var vxh = s.vx + 0.5 * dt * a0.ax, vyh = s.vy + 0.5 * dt * a0.ay;
    var x = s.x + dt * vxh, y = s.y + dt * vyh;
    var a1 = accel(mu, x, y);
    return { x: x, y: y, vx: vxh + 0.5 * dt * a1.ax, vy: vyh + 0.5 * dt * a1.ay, ax: a1.ax, ay: a1.ay, t: (s.t || 0) + dt };
  }

  /* Bước thời gian thích nghi: một phần nhỏ của "thời gian động lực" địa phương √(r³/μ).
     Gần cận điểm vật chạy nhanh → bước nhỏ; xa → bước lớn. */
  function adaptiveDt(mu, s, eta) {
    var r = Math.hypot(s.x, s.y);
    return (eta || 0.002) * Math.sqrt(r * r * r / mu);
  }

  /* Tích phân tới thời điểm t + duration. Trả về trạng thái mới.
     opts: { eta, maxSteps, stopRadius, onStep(s) } */
  function propagate(mu, s, duration, opts) {
    opts = opts || {};
    var t = 0, n = 0, maxSteps = opts.maxSteps || 2e6, cur = s;
    while (t < duration && n < maxSteps) {
      var dt = Math.min(adaptiveDt(mu, cur, opts.eta), duration - t);
      cur = verletStep(mu, cur, dt);
      t += dt; n++;
      if (opts.stopRadius && Math.hypot(cur.x, cur.y) <= opts.stopRadius) { cur.crashed = true; break; }
      if (opts.onStep) opts.onStep(cur);
    }
    cur.steps = n;
    return cur;
  }

  /* Phương trình Kepler M = E − e·sinE (elip), giải bằng Newton */
  function solveKepler(M, e) {
    M = ((M % (2 * Math.PI)) + 2 * Math.PI) % (2 * Math.PI);
    var E = e < 0.8 ? M : Math.PI;
    for (var i = 0; i < 50; i++) {
      var f = E - e * Math.sin(E) - M;
      var d = f / (1 - e * Math.cos(E));
      E -= d;
      if (Math.abs(d) < 1e-13) break;
    }
    return E;
  }
  /* Vị trí trên elip (tiêu điểm ở gốc, cận điểm theo trục +x) sau thời gian t kể từ cận điểm */
  function positionOnEllipse(mu, a, e, t) {
    var n = Math.sqrt(mu / (a * a * a));
    var E = solveKepler(n * t, e);
    var x = a * (Math.cos(E) - e);
    var y = a * Math.sqrt(1 - e * e) * Math.sin(E);
    return { x: x, y: y, E: E };
  }

  /* ---------------- Chuyển quỹ đạo Hohmann (2 quỹ đạo tròn đồng phẳng) ---------------- */
  function hohmann(mu, r1, r2) {
    var at = (r1 + r2) / 2;
    var v1 = vCircular(mu, r1), v2 = vCircular(mu, r2);
    var vp = visViva(mu, r1, at), va = visViva(mu, r2, at);   // vận tốc tại hai đầu elip chuyển
    var dv1 = vp - v1, dv2 = v2 - va;                          // có dấu: >0 tăng tốc
    var tt = period(mu, at) / 2;
    var n2 = Math.sqrt(mu / (r2 * r2 * r2));
    var phase = Math.PI - n2 * tt;                             // góc mục tiêu đi trước lúc phóng (rad)
    var n1 = Math.sqrt(mu / (r1 * r1 * r1));
    var synodic = 2 * Math.PI / Math.abs(n1 - n2);             // chu kì giao hội (cửa sổ phóng lặp lại)
    return { at: at, e: Math.abs(r2 - r1) / (r1 + r2), v1: v1, v2: v2, vp: vp, va: va,
      dv1: dv1, dv2: dv2, dvTotal: Math.abs(dv1) + Math.abs(dv2), tTransfer: tt,
      phase: phase, synodic: synodic };
  }

  /* Δv cần từ quỹ đạo đỗ tròn bán kính r quanh hành tinh để đạt v∞ khi thoát (hiệu ứng Oberth) */
  function departureDv(muPlanet, rPark, vInf) {
    return Math.sqrt(vInf * vInf + 2 * muPlanet / rPark) - Math.sqrt(muPlanet / rPark);
  }

  /* ---------------- Phương trình tên lửa Tsiolkovsky ----------------
     stages: [{ mProp, mDry, isp }] tính từ tầng 1 (dưới cùng) lên; payload: khối lượng tải. */
  function rocketStages(stages, payload) {
    var res = [], total = 0;
    for (var i = 0; i < stages.length; i++) {
      var above = payload;
      for (var j = i + 1; j < stages.length; j++) above += stages[j].mProp + stages[j].mDry;
      var m0 = above + stages[i].mProp + stages[i].mDry;
      var mf = m0 - stages[i].mProp;
      var dv = stages[i].isp * G0 * Math.log(m0 / mf);
      res.push({ m0: m0, mf: mf, ratio: m0 / mf, dv: dv });
      total += dv;
    }
    return { stages: res, total: total, liftoffMass: res.length ? res[0].m0 : payload };
  }
  function tsiolkovsky(isp, m0, mf) { return isp * G0 * Math.log(m0 / mf); }

  var api = {
    G0: G0, AU: AU, DAY: DAY, SIDEREAL_DAY: SIDEREAL_DAY, BODIES: BODIES, PLANETS: PLANETS,
    vCircular: vCircular, vEscape: vEscape, period: period, semiMajorFromPeriod: semiMajorFromPeriod,
    visViva: visViva, elements: elements, accel: accel, verletStep: verletStep, adaptiveDt: adaptiveDt,
    propagate: propagate, solveKepler: solveKepler, positionOnEllipse: positionOnEllipse,
    hohmann: hohmann, departureDv: departureDv, rocketStages: rocketStages, tsiolkovsky: tsiolkovsky
  };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.OrbitCore = api;
})(this);
