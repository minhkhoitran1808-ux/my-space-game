/* ==========================================================================
   Orbit Lab — giao diện (canvas + bảng điều khiển). Vật lý nằm trong orbit.js.
   ========================================================================== */
(function () {
  'use strict';

  var O = window.OrbitCore, SL = window.SL;
  var $ = function (id) { return document.getElementById(id); };
  var KM = 1000;

  SL.initThemeToggle($('theme-btn'));

  /* ---------------- Định dạng số ---------------- */
  function n(x, d) { return SL.num(x, d == null ? 2 : d); }
  function fixed(x, d) { return Number(x).toFixed(d).replace('.', ','); }
  function thousands(x, d) {
    var s = Number(x).toFixed(d || 0).split('.');
    s[0] = s[0].replace(/\B(?=(\d{3})+(?!\d))/g, '\u202f');
    return s.join(',');
  }
  function dur(sec) {
    if (!isFinite(sec)) return '∞';
    if (sec < 120) return fixed(sec, 1) + ' s';
    if (sec < 3 * 3600) return Math.floor(sec / 60) + ' ph ' + String(Math.round(sec % 60)).padStart(2, '0') + ' s';
    if (sec < 3 * 86400) return Math.floor(sec / 3600) + ' h ' + String(Math.round((sec % 3600) / 60)).padStart(2, '0') + ' ph';
    return thousands(sec / 86400, 1) + ' ngày';
  }
  function clock(sec) {
    var d = Math.floor(sec / 86400), h = Math.floor((sec % 86400) / 3600), m = Math.floor((sec % 3600) / 60), s = Math.floor(sec % 60);
    return (d ? d + 'd ' : '') + String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
  }

  /* ---------------- Tab ---------------- */
  var TABS = ['sandbox', 'hohmann', 'rocket', 'exercises'];
  var current = null;
  function showTab(name) {
    if (TABS.indexOf(name) < 0) name = 'sandbox';
    current = name;
    TABS.forEach(function (t) { $('tab-' + t).hidden = t !== name; });
    document.querySelectorAll('.nav a[data-tab]').forEach(function (a) { a.classList.toggle('active', a.getAttribute('data-tab') === name); });
    if (name === 'sandbox') { sizeCanvas(sb.cv); drawSandbox(); }
    if (name === 'hohmann') { sizeCanvas(hh.cv); drawHohmann(); }
    if (name === 'rocket') renderRocket();
  }
  window.addEventListener('hashchange', function () {
    var name = location.hash.slice(1).split('-')[0];
    if (TABS.indexOf(name) >= 0) showTab(name);
  });

  /* ---------------- Canvas ---------------- */
  function sizeCanvas(cv) {
    var dpr = Math.min(window.devicePixelRatio || 1, 2);
    var r = cv.getBoundingClientRect();
    if (!r.width) return false;
    var w = Math.round(r.width * dpr), h = Math.round(r.height * dpr);
    if (cv.width !== w || cv.height !== h) { cv.width = w; cv.height = h; }
    cv._dpr = dpr;
    return true;
  }
  // Sao nền (cố định, sinh giả ngẫu nhiên có hạt giống để không nhấp nháy)
  var STARS = (function () {
    var s = 12345, out = [];
    function rnd() { s = (s * 16807) % 2147483647; return s / 2147483647; }
    for (var i = 0; i < 260; i++) out.push([rnd(), rnd(), rnd() * 1.3 + 0.2, rnd() * 0.6 + 0.25]);
    return out;
  })();
  function drawStars(ctx, w, h) {
    ctx.fillStyle = '#050814';
    ctx.fillRect(0, 0, w, h);
    STARS.forEach(function (st) {
      ctx.globalAlpha = st[3];
      ctx.fillStyle = '#dfe6ff';
      ctx.fillRect(st[0] * w, st[1] * h, st[2], st[2]);
    });
    ctx.globalAlpha = 1;
  }
  function drawBody(ctx, x, y, rpx, color) {
    rpx = Math.max(rpx, 3);
    var g = ctx.createRadialGradient(x - rpx * 0.35, y - rpx * 0.35, rpx * 0.1, x, y, rpx);
    g.addColorStop(0, shade(color, 0.35));
    g.addColorStop(0.35, color);
    g.addColorStop(1, shade(color, -0.55));
    ctx.fillStyle = g;
    ctx.beginPath(); ctx.arc(x, y, rpx, 0, 2 * Math.PI); ctx.fill();
  }
  function shade(hex, k) {
    var c = parseInt(hex.slice(1), 16), r = c >> 16, g = (c >> 8) & 255, b = c & 255;
    var f = function (v) { return Math.max(0, Math.min(255, Math.round(k < 0 ? v * (1 + k) : v + (255 - v) * k))); };
    return 'rgb(' + f(r) + ',' + f(g) + ',' + f(b) + ')';
  }
  function cssVar(name) { return getComputedStyle(document.documentElement).getPropertyValue(name).trim(); }
  function arrow(ctx, x1, y1, x2, y2, color, width) {
    var a = Math.atan2(y2 - y1, x2 - x1), L = 9;
    ctx.strokeStyle = ctx.fillStyle = color; ctx.lineWidth = width || 2;
    ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(x2, y2);
    ctx.lineTo(x2 - L * Math.cos(a - 0.4), y2 - L * Math.sin(a - 0.4));
    ctx.lineTo(x2 - L * Math.cos(a + 0.4), y2 - L * Math.sin(a + 0.4));
    ctx.closePath(); ctx.fill();
  }
  function label(ctx, text, x, y, color, align) {
    ctx.font = '12px system-ui, sans-serif';
    ctx.textAlign = align || 'left';
    ctx.fillStyle = 'rgba(5,8,20,0.7)';
    var w = ctx.measureText(text).width;
    var bx = align === 'center' ? x - w / 2 - 4 : align === 'right' ? x - w - 4 : x - 4;
    ctx.fillRect(bx, y - 12, w + 8, 16);
    ctx.fillStyle = color || '#e7ecfb';
    ctx.fillText(text, x, y);
  }

  /* Phóng to/thu nhỏ & kéo bằng chuột / ngón tay (dùng chung cho 2 canvas) */
  function attachPanZoom(cv, view, redraw, onUserMove) {
    var pointers = {}, lastDist = 0;
    cv.addEventListener('wheel', function (e) {
      e.preventDefault();
      zoomAt(view, cv, e.offsetX, e.offsetY, e.deltaY < 0 ? 1 / 1.15 : 1.15);
      if (onUserMove) onUserMove();
      redraw();
    }, { passive: false });
    cv.addEventListener('pointerdown', function (e) { cv.setPointerCapture(e.pointerId); pointers[e.pointerId] = { x: e.offsetX, y: e.offsetY }; });
    cv.addEventListener('pointermove', function (e) {
      var p = pointers[e.pointerId];
      if (!p) return;
      var ids = Object.keys(pointers);
      var dpr = cv._dpr || 1;
      if (ids.length === 1) {
        view.cx -= (e.offsetX - p.x) * dpr * view.scale;
        view.cy += (e.offsetY - p.y) * dpr * view.scale;
      } else if (ids.length === 2) {
        var o = pointers[ids[0] === String(e.pointerId) ? ids[1] : ids[0]];
        var d = Math.hypot(e.offsetX - o.x, e.offsetY - o.y);
        if (lastDist) zoomAt(view, cv, (e.offsetX + o.x) / 2, (e.offsetY + o.y) / 2, lastDist / d);
        lastDist = d;
      }
      pointers[e.pointerId] = { x: e.offsetX, y: e.offsetY };
      if (onUserMove) onUserMove();
      redraw();
    });
    var up = function (e) { delete pointers[e.pointerId]; lastDist = 0; };
    cv.addEventListener('pointerup', up);
    cv.addEventListener('pointercancel', up);
  }
  function zoomAt(view, cv, ox, oy, f) {
    var dpr = cv._dpr || 1, px = ox * dpr, py = oy * dpr;
    var wx = view.cx + (px - cv.width / 2) * view.scale;
    var wy = view.cy - (py - cv.height / 2) * view.scale;
    view.scale *= f;
    view.cx = wx - (px - cv.width / 2) * view.scale;
    view.cy = wy + (py - cv.height / 2) * view.scale;
  }

  /* =====================================================================
     1. MÔ PHỎNG QUỸ ĐẠO
     ===================================================================== */
  var WARPS = [1, 10, 60, 100, 300, 1000, 3000, 10000, 30000];
  var sb = {
    cv: $('cv-orbit'), bodyKey: 'earth', body: O.BODIES.earth,
    s: null, E0: 0, t: 0, running: false, crashed: false, escaped: false,
    trail: [], view: { scale: 1, cx: 0, cy: 0 }, follow: true,
    kepler: null, last: 0
  };
  sb.ctx = sb.cv.getContext('2d');

  function presetsFor(body) {
    var R = body.R / KM, mu = body.mu;
    var vc = function (h) { return O.vCircular(mu, (R + h) * KM) / KM; };
    var ve = function (h) { return O.vEscape(mu, (R + h) * KM) / KM; };
    var vpe = function (hp, ha) { return O.visViva(mu, (R + hp) * KM, ((R + hp) + (R + ha)) * KM / 2) / KM; };
    if (body === O.BODIES.earth) {
      var hGeo = O.semiMajorFromPeriod(mu, O.SIDEREAL_DAY) / KM - R;
      return [
        { id: 'iss', name: 'Tròn 400 km (ISS)', h: 400, v: vc(400), g: 0 },
        { id: 'ellipse', name: 'Elip 400 × 4 000 km', h: 400, v: vpe(400, 4000), g: 0 },
        { id: 'hel', name: 'Elip dẹt (e ≈ 0,72)', h: 500, v: vpe(500, 40000), g: 0 },
        { id: 'geo', name: 'Địa tĩnh (GEO)', h: hGeo, v: vc(hGeo), g: 0 },
        { id: 'escape', name: 'Đúng vận tốc thoát v₂', h: 400, v: ve(400), g: 0 },
        { id: 'hyper', name: 'Hypebol (1,2 v₂)', h: 400, v: 1.2 * ve(400), g: 0 },
        { id: 'fall', name: 'Rơi xuống (0,8 v₁)', h: 400, v: 0.8 * vc(400), g: 0 },
        { id: 'ballistic', name: 'Đạn đạo 6 km/s, 45°', h: 0, v: 6, g: 45 }
      ];
    }
    return [
      { id: 'low', name: 'Tròn 100 km', h: 100, v: vc(100), g: 0 },
      { id: 'ellipse', name: 'Elip 100 × 2 000 km', h: 100, v: vpe(100, 2000), g: 0 },
      { id: 'escape', name: 'Vận tốc thoát v₂', h: 100, v: ve(100), g: 0 },
      { id: 'fall', name: 'Rơi xuống (0,8 v₁)', h: 100, v: 0.8 * vc(100), g: 0 }
    ];
  }
  function renderPresets() {
    $('presets').innerHTML = presetsFor(sb.body).map(function (p) {
      return '<button class="btn sm" data-preset="' + p.id + '">' + SL.esc(p.name) + '</button>';
    }).join('');
  }
  $('presets').addEventListener('click', function (e) {
    var b = e.target.closest('[data-preset]');
    if (b) applyPreset(b.getAttribute('data-preset'));
  });
  function applyPreset(id, noLaunch) {
    var p = presetsFor(sb.body).filter(function (x) { return x.id === id; })[0];
    if (!p) return;
    $('in-h').value = Math.round(p.h);
    $('in-v').value = fixed(p.v, 3).replace(',', '.');
    $('in-g').value = p.g;
    sb.presetWarp = p.id === 'geo' || p.id === 'hel' ? 3000 : p.id === 'hyper' || p.id === 'escape' ? 1000 : 100;
    updateRefSpeeds();
    if (!noLaunch) launch();
  }
  function updateRefSpeeds() {
    var h = parseFloat($('in-h').value) || 0;
    var r = sb.body.R + h * KM;
    $('ref-speeds').innerHTML = 'Ở độ cao này: <a href="#" data-setv="1">v₁ = ' + fixed(O.vCircular(sb.body.mu, r) / KM, 3) + ' km/s</a> (tròn) · ' +
      '<a href="#" data-setv="2">v₂ = ' + fixed(O.vEscape(sb.body.mu, r) / KM, 3) + ' km/s</a> (thoát). Bấm để điền.';
  }
  $('ref-speeds').addEventListener('click', function (e) {
    var a = e.target.closest('[data-setv]');
    if (!a) return;
    e.preventDefault();
    var r = sb.body.R + (parseFloat($('in-h').value) || 0) * KM;
    var v = a.getAttribute('data-setv') === '1' ? O.vCircular(sb.body.mu, r) : O.vEscape(sb.body.mu, r);
    $('in-v').value = (v / KM).toFixed(3);
    $('in-g').value = 0;
  });
  $('in-h').addEventListener('input', updateRefSpeeds);

  $('warp').innerHTML = WARPS.map(function (w) { return '<option value="' + w + '">' + thousands(w) + '×</option>'; }).join('');
  $('warp').value = '100';

  $('body').addEventListener('change', function () {
    sb.bodyKey = $('body').value;
    sb.body = O.BODIES[sb.bodyKey];
    renderPresets();
    applyPreset(presetsFor(sb.body)[0].id);
  });

  function launch() {
    var h = parseFloat($('in-h').value), v = parseFloat($('in-v').value), g = parseFloat($('in-g').value) || 0;
    if (!(h >= 0) || !(v >= 0)) { SL.toast('Nhập độ cao ≥ 0 và vận tốc ≥ 0.'); return; }
    g = Math.max(-89, Math.min(89, g)) * Math.PI / 180;
    var r = sb.body.R + h * KM;
    // Xuất phát ở "đỉnh" (0, r), chuyển động ngược chiều kim đồng hồ: phương ngang = (−1, 0)
    var vm = v * KM;
    sb.s = { x: 0, y: r, vx: -vm * Math.cos(g), vy: vm * Math.sin(g), t: 0 };
    sb.t = 0; sb.crashed = false; sb.escaped = false;
    sb.trail = [{ x: sb.s.x, y: sb.s.y }];
    sb.E0 = O.elements(sb.body.mu, sb.s).energy;
    resetKepler();
    if (sb.presetWarp) { $('warp').value = String(sb.presetWarp); sb.presetWarp = null; }
    if (h === 0 && g <= 0) { SL.toast('Phóng từ mặt đất cần góc bay > 0° để không cắm ngay xuống đất.'); }
    fitView();
    sb.running = true;
    $('btn-pause').textContent = '⏸ Tạm dừng';
    updateReadout();
    drawSandbox();
  }
  function fitView() {
    var el = O.elements(sb.body.mu, sb.s);
    var ext = el.bound && isFinite(el.ra) ? Math.max(el.ra, sb.body.R * 1.2) : Math.max(el.r * 3.2, sb.body.R * 4);
    if (!el.bound && el.r < sb.body.R * 1.05) ext = Math.max(el.r * 2, sb.body.R * 2.5);
    var cv = sb.cv;
    if (!sizeCanvas(cv)) { sb.needFit = true; return; }   // canvas đang ẩn → căn khung khi hiện ra
    sb.needFit = false;
    // tâm khung: giữa cận điểm & viễn điểm cho elip
    if (el.bound && isFinite(el.ra)) {
      // tâm elip cách tiêu điểm một đoạn a·e, ngược hướng vectơ lệch tâm
      sb.view.cx = -el.a * el.ex; sb.view.cy = -el.a * el.ey;
      ext = Math.max(el.a * 1.1, sb.body.R * 1.3);
    } else { sb.view.cx = 0; sb.view.cy = 0; }
    sb.view.scale = (2.1 * ext) / Math.min(cv.width, cv.height);
    sb.follow = true;
  }
  $('btn-launch').addEventListener('click', launch);
  $('btn-pause').addEventListener('click', function () {
    if (!sb.s) return;
    if (sb.crashed) { launch(); return; }
    sb.running = !sb.running;
    $('btn-pause').textContent = sb.running ? '⏸ Tạm dừng' : '▶ Tiếp tục';
  });
  function burn(sign) {
    if (!sb.s || sb.crashed) return;
    var dv = (parseFloat($('in-dv').value) || 0) * sign;
    var v = Math.hypot(sb.s.vx, sb.s.vy);
    if (!v) return;
    sb.s = { x: sb.s.x, y: sb.s.y, vx: sb.s.vx * (1 + dv / v), vy: sb.s.vy * (1 + dv / v), t: sb.s.t };
    sb.E0 = O.elements(sb.body.mu, sb.s).energy;
    resetKepler();
    updateReadout(); drawSandbox();
    SL.toast((sign > 0 ? 'Tăng tốc ' : 'Hãm ') + Math.abs(dv) + ' m/s');
  }
  $('btn-pro').addEventListener('click', function () { burn(1); });
  $('btn-retro').addEventListener('click', function () { burn(-1); });
  ['t-conic', 't-vec'].forEach(function (id) { $(id).addEventListener('change', drawSandbox); });
  $('t-kepler').addEventListener('change', function () { resetKepler(); drawSandbox(); });

  $('zoom-in').addEventListener('click', function () { zoomAt(sb.view, sb.cv, sb.cv.clientWidth / 2, sb.cv.clientHeight / 2, 1 / 1.4); drawSandbox(); });
  $('zoom-out').addEventListener('click', function () { zoomAt(sb.view, sb.cv, sb.cv.clientWidth / 2, sb.cv.clientHeight / 2, 1.4); drawSandbox(); });
  $('zoom-fit').addEventListener('click', function () { if (sb.s) { fitView(); drawSandbox(); } });
  attachPanZoom(sb.cv, sb.view, function () { drawSandbox(); });

  /* Định luật II Kepler: cộng dồn diện tích quét trong 12 khoảng Δt = T/12 */
  function resetKepler() {
    sb.kepler = null;
    if (!$('t-kepler').checked || !sb.s) { $('kepler-box').hidden = true; return; }
    var el = O.elements(sb.body.mu, sb.s);
    if (!el.bound) { $('kepler-box').hidden = true; SL.toast('Định luật II Kepler chỉ minh họa cho quỹ đạo kín (elip).'); return; }
    sb.kepler = { t0: sb.s.t, dt: el.T / 12, idx: 0, areas: [0], polys: [[{ x: sb.s.x, y: sb.s.y }]], prev: { x: sb.s.x, y: sb.s.y } };
    $('kepler-box').hidden = false;
  }
  function keplerAccumulate(c) {
    var K = sb.kepler;
    if (!K) return;
    var idx = Math.floor((c.t - K.t0) / K.dt), k = idx % 12;
    if (idx !== K.idx) {   // sang quạt mới: quạt cùng vị trí của vòng trước được thay thế
      K.idx = idx; K.areas[k] = 0; K.polys[k] = [{ x: K.prev.x, y: K.prev.y }];
    }
    K.areas[k] += 0.5 * (K.prev.x * c.y - K.prev.y * c.x);
    var poly = K.polys[k], lp = poly[poly.length - 1];
    if (Math.hypot(c.x - lp.x, c.y - lp.y) > 0.004 * Math.hypot(c.x, c.y)) poly.push({ x: c.x, y: c.y });
    K.prev = { x: c.x, y: c.y };
  }

  function stepSim(simDt) {
    var mu = sb.body.mu, R = sb.body.R, remaining = simDt, steps = 0, s = sb.s;
    while (remaining > 1e-9 && steps < 40000) {
      var dt = Math.min(O.adaptiveDt(mu, s, 0.002), remaining);
      s = O.verletStep(mu, s, dt);
      remaining -= dt; steps++;
      var r = Math.hypot(s.x, s.y);
      if (r <= R) {
        // lùi về đúng bề mặt cho đẹp
        s.x *= R / r; s.y *= R / r;
        sb.crashed = true; sb.running = false;
        $('btn-pause').textContent = '↺ Phóng lại';
        break;
      }
      keplerAccumulate(s);
      var lt = sb.trail[sb.trail.length - 1];
      if (Math.hypot(s.x - lt.x, s.y - lt.y) > 0.003 * r) {
        sb.trail.push({ x: s.x, y: s.y });
        if (sb.trail.length > 6000) sb.trail.splice(0, sb.trail.length - 6000);
      }
    }
    sb.s = s;
    var el = O.elements(mu, s);
    if (!el.bound && el.r > 60 * Math.max(R, el.rp)) {
      sb.escaped = true; sb.running = false;
      $('btn-pause').textContent = '▶ Tiếp tục';
    }
  }

  function updateReadout() {
    if (!sb.s) return;
    var mu = sb.body.mu, R = sb.body.R, el = O.elements(mu, sb.s);
    var drift = sb.E0 ? Math.abs((el.energy - sb.E0) / sb.E0) : 0;
    var rows = [
      ['Thời gian bay', clock(sb.s.t)],
      ['Độ cao', thousands((el.r - R) / KM, 0) + ' km'],
      ['Tốc độ v', fixed(el.v / KM, 3) + ' km/s'],
      ['v₁ ở độ cao này', fixed(O.vCircular(mu, el.r) / KM, 3) + ' km/s'],
      ['Cơ năng riêng ε = v²/2 − μ/r', fixed(el.energy / 1e6, 3) + ' MJ/kg', el.energy >= 0],
      ['Độ lệch tâm e', fixed(el.e, 4)],
      ['Bán trục lớn a', el.bound ? thousands(el.a / KM, 0) + ' km' : '— (không kín)'],
      ['Chu kì T', el.bound ? dur(el.T) : '∞'],
      ['Độ cao cận điểm', thousands((el.rp - R) / KM, 0) + ' km', el.rp < R],
      ['Độ cao viễn điểm', el.bound ? thousands((el.ra - R) / KM, 0) + ' km' : '∞'],
      ['Sai số năng lượng |ΔE/E₀|', drift < 1e-12 ? '< 1e-12' : drift.toExponential(1)]
    ];
    $('readout').innerHTML = rows.map(function (r) {
      return '<tr' + (r[2] ? ' class="hl"' : '') + '><td>' + r[0] + '</td><td>' + r[1] + '</td></tr>';
    }).join('');

    var st;
    if (sb.crashed) st = '💥 Va chạm bề mặt sau ' + dur(sb.s.t);
    else if (sb.escaped) st = '🚀 Đã thoát khỏi lực hút (quỹ đạo không kín)';
    else if (!el.bound) st = el.e < 1.0005 ? 'Quỹ đạo parabol — vừa đủ thoát (ε ≈ 0)' : 'Quỹ đạo hypebol — sẽ thoát (ε > 0)';
    else if (el.rp < R) st = '⚠ Quỹ đạo cắt bề mặt — sẽ rơi xuống';
    else if (el.e < 2e-3) st = 'Quỹ đạo tròn (e ≈ 0)';
    else st = 'Quỹ đạo elip (e = ' + fixed(el.e, 3) + ')';
    if (!sb.crashed && el.bound && el.rp >= R && el.rp < R + sb.body.atm) st += ' · cận điểm trong khí quyển (mô phỏng bỏ qua lực cản)';
    $('status').textContent = st;
    $('simtime').textContent = 't = ' + clock(sb.s.t) + '  ·  ' + thousands(+$('warp').value) + '×';

    if (sb.kepler) {
      var K = sb.kepler, cur = K.idx % 12;
      var done = K.areas.map(function (a, i) { return i !== cur && a != null; });
      var full = K.areas.filter(function (a, i) { return done[i]; });
      var mean = full.length ? full.reduce(function (a, b) { return a + b; }) / full.length : (K.areas[cur] || 1);
      $('kbars').innerHTML = K.areas.map(function (a, i) {
        var ratio = a / mean;
        return '<div style="height:' + Math.min(100, ratio * 70).toFixed(1) + '%;opacity:' + (done[i] ? 1 : 0.4) + '" title="Quạt ' + (i + 1) + '">' +
          (done[i] ? '<span>' + fixed(ratio, 3) + '</span>' : '') + '</div>';
      }).join('');
    }
  }

  function w2s(view, cv, x, y) {
    return [cv.width / 2 + (x - view.cx) / view.scale, cv.height / 2 - (y - view.cy) / view.scale];
  }
  function drawSandbox() {
    var cv = sb.cv, ctx = sb.ctx;
    if (!sizeCanvas(cv)) return;
    if (sb.needFit && sb.s) fitView();
    var W = cv.width, H = cv.height, dpr = cv._dpr, v = sb.view, body = sb.body;
    drawStars(ctx, W, H);
    var c = w2s(v, cv, 0, 0);
    var accent = '#5eead4', accent2 = '#a78bfa', warn = '#fbbf24';

    // Bầu khí quyển (mỏng)
    if (body.atm) {
      ctx.strokeStyle = 'rgba(120,170,255,0.25)'; ctx.lineWidth = 1 * dpr;
      ctx.setLineDash([3 * dpr, 4 * dpr]);
      ctx.beginPath(); ctx.arc(c[0], c[1], (body.R + body.atm) / v.scale, 0, 2 * Math.PI); ctx.stroke();
      ctx.setLineDash([]);
    }
    if (!sb.s) { drawBody(ctx, c[0], c[1], body.R / v.scale, body.color); return; }
    var mu = body.mu, el = O.elements(mu, sb.s);

    // Quạt Kepler
    if (sb.kepler) {
      sb.kepler.polys.forEach(function (poly, i) {
        if (!poly || poly.length < 2) return;
        ctx.fillStyle = i % 2 ? 'rgba(167,139,250,0.28)' : 'rgba(94,234,212,0.28)';
        ctx.beginPath(); ctx.moveTo(c[0], c[1]);
        poly.forEach(function (p) { var q = w2s(v, cv, p.x, p.y); ctx.lineTo(q[0], q[1]); });
        ctx.closePath(); ctx.fill();
      });
    }

    drawBody(ctx, c[0], c[1], body.R / v.scale, body.color);

    // Quỹ đạo dự đoán (conic giải tích từ trạng thái hiện tại)
    if ($('t-conic').checked && !sb.crashed) {
      ctx.strokeStyle = 'rgba(167,139,250,0.85)'; ctx.lineWidth = 1.5 * dpr;
      ctx.setLineDash([6 * dpr, 6 * dpr]);
      ctx.beginPath();
      var maxR = 4 * Math.hypot(W, H) * v.scale + el.r, first = true;
      var lim = el.e < 1 ? Math.PI : Math.acos(-1 / el.e) - 1e-3;
      var N = 720;
      for (var i = 0; i <= N; i++) {
        var nu = -lim + (2 * lim * i) / N;
        var rr = el.p / (1 + el.e * Math.cos(nu));
        if (!(rr > 0) || rr > maxR) { first = true; continue; }
        var ang = nu + el.omega;
        var q = w2s(v, cv, rr * Math.cos(ang), rr * Math.sin(ang));
        if (first) { ctx.moveTo(q[0], q[1]); first = false; } else ctx.lineTo(q[0], q[1]);
      }
      ctx.stroke(); ctx.setLineDash([]);
      // Cận điểm / viễn điểm
      if (el.e > 2e-3) {
        var pp = w2s(v, cv, el.rp * Math.cos(el.omega), el.rp * Math.sin(el.omega));
        ctx.fillStyle = warn; ctx.beginPath(); ctx.arc(pp[0], pp[1], 4 * dpr, 0, 7); ctx.fill();
        label(ctx, 'Cận điểm ' + thousands((el.rp - body.R) / KM) + ' km', pp[0] + 8 * dpr, pp[1] - 6 * dpr, warn);
        if (el.bound) {
          var ap = w2s(v, cv, -el.ra * Math.cos(el.omega), -el.ra * Math.sin(el.omega));
          ctx.fillStyle = warn; ctx.beginPath(); ctx.arc(ap[0], ap[1], 4 * dpr, 0, 7); ctx.fill();
          label(ctx, 'Viễn điểm ' + thousands((el.ra - body.R) / KM) + ' km', ap[0] + 8 * dpr, ap[1] - 6 * dpr, warn);
        }
      }
    }

    // Vết bay
    if (sb.trail.length > 1) {
      ctx.lineWidth = 2 * dpr; ctx.strokeStyle = accent;
      ctx.beginPath();
      sb.trail.forEach(function (p, i) { var q = w2s(v, cv, p.x, p.y); if (i) ctx.lineTo(q[0], q[1]); else ctx.moveTo(q[0], q[1]); });
      var qs = w2s(v, cv, sb.s.x, sb.s.y); ctx.lineTo(qs[0], qs[1]);
      ctx.stroke();
    }

    // Tàu
    var sp = w2s(v, cv, sb.s.x, sb.s.y);
    var heading = Math.atan2(-sb.s.vy, sb.s.vx);
    ctx.save(); ctx.translate(sp[0], sp[1]); ctx.rotate(heading);
    ctx.fillStyle = sb.crashed ? '#fb923c' : '#ffffff';
    ctx.beginPath(); ctx.moveTo(9 * dpr, 0); ctx.lineTo(-6 * dpr, 5 * dpr); ctx.lineTo(-3 * dpr, 0); ctx.lineTo(-6 * dpr, -5 * dpr); ctx.closePath(); ctx.fill();
    ctx.restore();
    if ($('t-vec').checked && !sb.crashed) {
      var vref = O.vCircular(mu, body.R);
      var L = (el.v / vref) * 70 * dpr;
      arrow(ctx, sp[0], sp[1], sp[0] + L * Math.cos(heading), sp[1] + L * Math.sin(heading), accent2, 2 * dpr);
    }
    // Thước tỉ lệ
    var bar = niceLength(120 * dpr * v.scale);
    ctx.strokeStyle = '#c9d3f2'; ctx.lineWidth = 2 * dpr;
    ctx.beginPath(); ctx.moveTo(12 * dpr, H - 16 * dpr); ctx.lineTo(12 * dpr + bar / v.scale, H - 16 * dpr); ctx.stroke();
    ctx.font = (11 * dpr) + 'px system-ui'; ctx.fillStyle = '#c9d3f2'; ctx.textAlign = 'left';
    ctx.fillText(thousands(bar / KM) + ' km', 12 * dpr, H - 22 * dpr);
  }
  function niceLength(x) {
    var p = Math.pow(10, Math.floor(Math.log10(x))), m = x / p;
    return (m < 2 ? 1 : m < 5 ? 2 : 5) * p;
  }

  function loop(ts) {
    var dtReal = sb.last ? Math.min(0.05, (ts - sb.last) / 1000) : 0;
    sb.last = ts;
    if (current === 'sandbox' && sb.s && sb.running && !sb.crashed) {
      stepSim(dtReal * (+$('warp').value));
      updateReadout();
      drawSandbox();
    } else if (current === 'sandbox' && sb.s && !sb.running) {
      // vẫn cập nhật nhãn khi tạm dừng
    }
    if (current === 'hohmann' && hh.playing) hohmannTick(dtReal);
    requestAnimationFrame(loop);
  }

  $('sandbox-theory').innerHTML = '<h2>Bạn đang thấy gì?</h2>' + SL.fmtBlock(
    'Mô phỏng giải **bài toán hai vật**: tàu chỉ chịu lực hấp dẫn của vật trung tâm $\\vec F = -\\dfrac{GMm}{r^2}\\hat r$. Máy tính tích phân phương trình chuyển động bằng phương pháp **velocity-Verlet** với bước thời gian tự co giãn (nhỏ khi tàu ở gần, lớn khi ở xa). Dòng "sai số năng lượng" cho biết độ chính xác: cơ năng phải được bảo toàn, nên con số này càng nhỏ càng tốt.'
  ) +
    '<div class="formula-grid">' +
    '<div><b>Vận tốc vũ trụ cấp I</b> (quỹ đạo tròn)<br>$v_1 = \\sqrt{\\dfrac{GM}{r}}$</div>' +
    '<div><b>Vận tốc vũ trụ cấp II</b> (thoát)<br>$v_2 = \\sqrt{\\dfrac{2GM}{r}} = \\sqrt2\\,v_1$</div>' +
    '<div><b>Định luật III Kepler</b><br>$T = 2\\pi\\sqrt{\\dfrac{a^3}{GM}}$</div>' +
    '<div><b>Phương trình vis-viva</b><br>$v^2 = GM\\left(\\dfrac{2}{r} - \\dfrac{1}{a}\\right)$</div>' +
    '<div><b>Cơ năng riêng</b><br>$\\varepsilon = \\dfrac{v^2}{2} - \\dfrac{GM}{r} = -\\dfrac{GM}{2a}$<br><span class="small muted">ε &lt; 0: elip · ε = 0: parabol · ε &gt; 0: hypebol</span></div>' +
    '<div><b>Định luật II Kepler</b><br>$\\dfrac{dA}{dt} = \\dfrac{h}{2} = $ hằng số, với $h = rv_\\perp$<br><span class="small muted">Bật "Định luật II Kepler" để thấy 12 hình quạt có diện tích bằng nhau.</span></div>' +
    '</div><p class="small muted" style="margin-top:10px">Giả thiết đơn giản hóa: vật trung tâm là khối cầu đứng yên, không có khí quyển (bỏ qua lực cản), không có Mặt Trăng/Mặt Trời nhiễu loạn, quỹ đạo nằm trong một mặt phẳng. Hằng số: $GM_{\\oplus} = 3{,}986\\cdot10^{14}\\ \\mathrm{m^3/s^2}$, $R_{\\oplus} = 6371\\ \\mathrm{km}$ (bán kính trung bình).</p>';

  /* =====================================================================
     2. HOHMANN
     ===================================================================== */
  var hh = { cv: $('cv-hoh'), view: { scale: 1, cx: 0, cy: 0 }, tau: 0, playing: false, H: null, trail: [] };
  hh.ctx = hh.cv.getContext('2d');
  var PLANET_KEYS = Object.keys(O.PLANETS);
  $('hoh-from').innerHTML = PLANET_KEYS.map(function (k) { return '<option value="' + k + '">' + O.PLANETS[k].name + '</option>'; }).join('');
  $('hoh-to').innerHTML = $('hoh-from').innerHTML;
  $('hoh-from').value = 'earth'; $('hoh-to').value = 'mars';

  function hohmannSetup() {
    var mode = $('hoh-mode').value;
    $('hoh-sun-inputs').hidden = mode !== 'sun';
    $('hoh-earth-inputs').hidden = mode !== 'earth';
    if (mode === 'sun') {
      var a = O.PLANETS[$('hoh-from').value], b = O.PLANETS[$('hoh-to').value];
      if (a === b) { SL.toast('Chọn hai hành tinh khác nhau.'); $('hoh-to').value = $('hoh-from').value === 'mars' ? 'earth' : 'mars'; b = O.PLANETS[$('hoh-to').value]; }
      hh.mu = O.BODIES.sun.mu; hh.r1 = a.a * O.AU; hh.r2 = b.a * O.AU; hh.from = a; hh.to = b; hh.center = O.BODIES.sun;
    } else {
      var h1 = Math.max(100, parseFloat($('hoh-h1').value) || 300), h2 = Math.max(100, parseFloat($('hoh-h2').value) || 35786);
      if (Math.abs(h1 - h2) < 1) h2 = h1 + 1000;
      hh.mu = O.BODIES.earth.mu; hh.center = O.BODIES.earth;
      hh.r1 = O.BODIES.earth.R + h1 * KM; hh.r2 = O.BODIES.earth.R + h2 * KM;
      hh.from = { name: 'Quỹ đạo đầu', color: '#5eead4' }; hh.to = { name: 'Quỹ đạo đích', color: '#fbbf24' };
    }
    hh.H = O.hohmann(hh.mu, hh.r1, hh.r2);
    hh.outward = hh.r2 > hh.r1;
    hh.tau = 0; hh.playing = false; hh.trail = [];
    $('hoh-play').textContent = '▶ Chạy';
    hh.needFit = true;
    renderHohmannTable();
    drawHohmann();
  }
  ['hoh-mode', 'hoh-from', 'hoh-to'].forEach(function (id) { $(id).addEventListener('change', hohmannSetup); });
  ['hoh-h1', 'hoh-h2'].forEach(function (id) { $(id).addEventListener('change', hohmannSetup); });
  $('hoh-off').addEventListener('input', function () {
    $('hoh-off-val').textContent = (this.value > 0 ? '+' : '') + this.value + '°';
    hh.tau = 0; hh.trail = []; hh.playing = false; $('hoh-play').textContent = '▶ Chạy';
    drawHohmann();
  });
  $('hoh-play').addEventListener('click', function () {
    if (hh.tau >= hh.H.tTransfer) { hh.tau = 0; hh.trail = []; }
    hh.playing = !hh.playing;
    this.textContent = hh.playing ? '⏸ Dừng' : '▶ Chạy';
  });
  $('hoh-reset').addEventListener('click', function () {
    hh.tau = 0; hh.trail = []; hh.playing = false; $('hoh-play').textContent = '▶ Chạy'; drawHohmann();
  });
  attachPanZoom(hh.cv, hh.view, function () { drawHohmann(); });

  function hohSpeed() {
    // tốc độ mô phỏng: thời gian bay chuyển quỹ đạo diễn ra trong khoảng 3–40 giây thực
    var f = +$('hoh-speed').value / 100;
    var secondsReal = 40 * Math.pow(3 / 40, f);
    return hh.H.tTransfer / secondsReal;
  }
  function hohmannTick(dtReal) {
    hh.tau += dtReal * hohSpeed();
    if (hh.tau >= hh.H.tTransfer) { hh.tau = hh.H.tTransfer; hh.playing = false; $('hoh-play').textContent = '▶ Chạy lại'; }
    drawHohmann();
  }
  function hohPositions(tau) {
    var H = hh.H, mu = hh.mu;
    var n1 = Math.sqrt(mu / Math.pow(hh.r1, 3)), n2 = Math.sqrt(mu / Math.pow(hh.r2, 3));
    var off = (+$('hoh-off').value) * Math.PI / 180;
    var th1 = n1 * tau, th2 = H.phase + off + n2 * tau;
    var sc;
    if (hh.outward) sc = O.positionOnEllipse(mu, H.at, H.e, tau);
    else {
      var p = O.positionOnEllipse(mu, H.at, H.e, H.tTransfer + tau);
      sc = { x: -p.x, y: -p.y };
    }
    return { p1: [hh.r1 * Math.cos(th1), hh.r1 * Math.sin(th1)], p2: [hh.r2 * Math.cos(th2), hh.r2 * Math.sin(th2)], sc: [sc.x, sc.y], th2: th2 };
  }
  function drawHohmann() {
    var cv = hh.cv, ctx = hh.ctx;
    if (!hh.H || !sizeCanvas(cv)) return;
    if (hh.needFit) {
      var ext = Math.max(hh.r1, hh.r2) * 1.18;
      hh.view.cx = 0; hh.view.cy = 0; hh.view.scale = (2 * ext) / Math.min(cv.width, cv.height);
      hh.needFit = false;
    }
    var W = cv.width, H = cv.height, dpr = cv._dpr, v = hh.view, Hm = hh.H;
    drawStars(ctx, W, H);
    var c = w2s(v, cv, 0, 0);
    // quỹ đạo tròn đầu & cuối
    ctx.lineWidth = 1.5 * dpr;
    [[hh.r1, hh.from.color], [hh.r2, hh.to.color]].forEach(function (o) {
      ctx.strokeStyle = o[1]; ctx.globalAlpha = 0.55;
      ctx.beginPath(); ctx.arc(c[0], c[1], o[0] / v.scale, 0, 2 * Math.PI); ctx.stroke();
    });
    ctx.globalAlpha = 1;
    // elip chuyển quỹ đạo: nửa dùng (liền) + nửa còn lại (mờ)
    var rot = hh.outward ? 0 : Math.PI;
    var a = Hm.at, e = Hm.e, b = a * Math.sqrt(1 - e * e);
    var ellipseCenter = w2s(v, cv, -a * e * Math.cos(rot), -a * e * Math.sin(rot));
    ctx.strokeStyle = '#a78bfa'; ctx.setLineDash([5 * dpr, 6 * dpr]); ctx.globalAlpha = 0.4;
    ctx.beginPath(); ctx.ellipse(ellipseCenter[0], ellipseCenter[1], a / v.scale, b / v.scale, -rot, 0, 2 * Math.PI); ctx.stroke();
    ctx.setLineDash([]); ctx.globalAlpha = 1; ctx.lineWidth = 2.5 * dpr;
    ctx.beginPath();
    for (var i = 0; i <= 200; i++) {
      var pp = hohPositionsAt(Hm.tTransfer * i / 200);
      var q = w2s(v, cv, pp[0], pp[1]);
      if (i) ctx.lineTo(q[0], q[1]); else ctx.moveTo(q[0], q[1]);
    }
    ctx.stroke();
    // vật trung tâm
    drawBody(ctx, c[0], c[1], Math.max(hh.center.R / v.scale, 7 * dpr), hh.center.color);

    var P = hohPositions(hh.tau);
    // góc pha lúc phóng
    if (hh.tau === 0) {
      var r0 = Math.min(hh.r1, hh.r2) * 0.45 / v.scale;
      ctx.strokeStyle = '#fbbf24'; ctx.lineWidth = 1.5 * dpr;
      ctx.beginPath(); ctx.arc(c[0], c[1], r0, 0, -P.th2, P.th2 > 0); ctx.stroke();
      label(ctx, 'góc pha ' + fixed(P.th2 * 180 / Math.PI, 1) + '°', c[0] + r0 * Math.cos(-P.th2 / 2) + 6 * dpr, c[1] + r0 * Math.sin(-P.th2 / 2), '#fbbf24');
      ctx.setLineDash([3 * dpr, 4 * dpr]); ctx.globalAlpha = 0.6;
      [P.p1, P.p2].forEach(function (p) { var q = w2s(v, cv, p[0], p[1]); ctx.beginPath(); ctx.moveTo(c[0], c[1]); ctx.lineTo(q[0], q[1]); ctx.stroke(); });
      ctx.setLineDash([]); ctx.globalAlpha = 1;
    }
    // hành tinh & tàu
    function dot(p, color, rad, text) {
      var q = w2s(v, cv, p[0], p[1]);
      ctx.fillStyle = color; ctx.beginPath(); ctx.arc(q[0], q[1], rad * dpr, 0, 2 * Math.PI); ctx.fill();
      if (text) label(ctx, text, q[0] + 9 * dpr, q[1] - 8 * dpr, color);
    }
    dot(P.p1, hh.from.color, 6, hh.from.name);
    dot(P.p2, hh.to.color, 6, hh.to.name);
    // vết tàu
    var q2 = w2s(v, cv, P.sc[0], P.sc[1]);
    ctx.fillStyle = '#ffffff'; ctx.beginPath(); ctx.arc(q2[0], q2[1], 4 * dpr, 0, 2 * Math.PI); ctx.fill();
    label(ctx, 'Tàu', q2[0] - 10 * dpr, q2[1] + 18 * dpr, '#ffffff', 'right');

    var unit = hh.center === O.BODIES.sun ? 86400 : 3600;
    $('hoh-time').textContent = 't = ' + fixed(hh.tau / unit, 1) + (unit === 86400 ? ' ngày' : ' giờ') + ' / ' + fixed(Hm.tTransfer / unit, 1);
    var st = '';
    if (hh.tau >= Hm.tTransfer) {
      var miss = ((P.th2 - Math.PI) * 180 / Math.PI);
      miss = ((miss + 540) % 360) - 180;
      st = Math.abs(miss) < 0.5 ? '✅ Tới nơi đúng lúc gặp ' + hh.to.name + '!'
        : '❌ Trượt: mục tiêu ' + (miss > 0 ? 'đã đi trước' : 'còn ở sau') + ' ' + fixed(Math.abs(miss), 1) + '° (≈ ' + thousands(Math.abs(miss) * Math.PI / 180 * hh.r2 / KM / (unit === 86400 ? 1e6 : 1), unit === 86400 ? 1 : 0) + (unit === 86400 ? ' triệu km' : ' km') + ')';
    } else if (hh.tau === 0) st = 'Lúc phóng: ' + hh.to.name + ' phải đi trước ' + fixed(Hm.phase * 180 / Math.PI, 1) + '°' + (+$('hoh-off').value ? ' (đang lệch ' + $('hoh-off').value + '°)' : '');
    else st = 'Đang bay trên elip chuyển quỹ đạo…';
    $('hoh-status').textContent = st;
  }
  function hohPositionsAt(tau) { return hohPositions(tau).sc; }

  function renderHohmannTable() {
    var H = hh.H, sun = hh.center === O.BODIES.sun;
    var dist = function (r) { return sun ? fixed(r / O.AU, 3) + ' AU' : thousands(r / KM) + ' km'; };
    var kms = function (x) { return fixed(x / KM, 3) + ' km/s'; };
    var t = sun ? thousands(H.tTransfer / 86400, 1) + ' ngày (' + fixed(H.tTransfer / 86400 / 30.44, 1) + ' tháng)' : fixed(H.tTransfer / 3600, 2) + ' giờ';
    var rows = [
      ['Bán kính quỹ đạo đầu r₁', dist(hh.r1)],
      ['Bán kính quỹ đạo đích r₂', dist(hh.r2)],
      ['Bán trục lớn elip chuyển a = (r₁+r₂)/2', dist(H.at)],
      ['v tròn tại r₁', kms(H.v1)],
      ['v elip tại r₁ (sau đốt 1)', kms(H.vp)],
      ['Δv₁', '<b>' + (H.dv1 >= 0 ? '+' : '') + kms(H.dv1) + '</b>'],
      ['v elip tại r₂ (trước đốt 2)', kms(H.va)],
      ['v tròn tại r₂', kms(H.v2)],
      ['Δv₂', '<b>' + (H.dv2 >= 0 ? '+' : '') + kms(H.dv2) + '</b>'],
      ['Tổng |Δv|', '<b>' + kms(H.dvTotal) + '</b>'],
      ['Thời gian bay (nửa chu kì elip)', t],
      ['Góc pha mục tiêu lúc phóng', fixed(H.phase * 180 / Math.PI, 1) + '°']
    ];
    if (sun) {
      rows.push(['Chu kì giao hội (cửa sổ phóng lặp lại)', thousands(H.synodic / 86400) + ' ngày ≈ ' + fixed(H.synodic / 86400 / 30.44, 1) + ' tháng']);
      if ($('hoh-from').value === 'earth' && hh.outward) {
        rows.push(['Δv từ quỹ đạo đỗ 300 km quanh Trái Đất (tính cả hiệu ứng Oberth)', kms(O.departureDv(O.BODIES.earth.mu, O.BODIES.earth.R + 300e3, Math.abs(H.dv1)))]);
      }
    }
    $('hoh-table').innerHTML = rows.map(function (r) { return '<tr><td>' + r[0] + '</td><td>' + r[1] + '</td></tr>'; }).join('');
  }

  $('hoh-theory').innerHTML = '<h2>Chuyển quỹ đạo Hohmann</h2>' + SL.fmtBlock(
    'Cách tiết kiệm nhiên liệu nhất (với 2 lần đốt) để đi giữa hai quỹ đạo tròn đồng phẳng: dùng **nửa elip** tiếp xúc với cả hai quỹ đạo. Đốt lần 1 ở $r_1$ để vào elip, bay nửa vòng, đốt lần 2 ở $r_2$ để "tròn hóa" quỹ đạo.\n\n' +
    '$$a_t = \\frac{r_1 + r_2}{2},\\qquad \\Delta v_1 = \\sqrt{\\frac{GM}{r_1}}\\left(\\sqrt{\\frac{2r_2}{r_1+r_2}} - 1\\right),\\qquad \\Delta v_2 = \\sqrt{\\frac{GM}{r_2}}\\left(1 - \\sqrt{\\frac{2r_1}{r_1+r_2}}\\right)$$\n\n' +
    '$$t_H = \\pi\\sqrt{\\frac{a_t^3}{GM}},\\qquad \\text{góc pha lúc phóng } \\varphi = \\pi - \\omega_2 t_H\\quad(\\omega_2 = \\sqrt{GM/r_2^3})$$\n\n' +
    'Kéo thanh **Lệch pha** rồi bấm Chạy để thấy: phóng sai thời điểm chỉ vài độ là tàu tới quỹ đạo Sao Hỏa khi hành tinh đã ở chỗ khác — vì vậy các sứ mệnh phải chờ **cửa sổ phóng** (với Sao Hỏa khoảng 26 tháng một lần).\n\n' +
    '**Giới hạn của mô hình:** quỹ đạo hành tinh coi là tròn và cùng mặt phẳng; bỏ qua lực hút của hành tinh khi rời đi/đến nơi (thực tế cần tính quỹ đạo hypebol thoát — xem dòng "Δv từ quỹ đạo đỗ 300 km"). Số liệu thực của từng sứ mệnh vì vậy lệch vài phần trăm.'
  );

  /* =====================================================================
     3. TÊN LỬA
     ===================================================================== */
  var RK_PRESETS = [
    { id: 'one', name: '1 tầng (minh họa)', payload: 2, stages: [{ mProp: 100, mDry: 10, isp: 330 }] },
    { id: 'two', name: '2 tầng (minh họa)', payload: 10, stages: [{ mProp: 400, mDry: 25, isp: 300 }, { mProp: 100, mDry: 6, isp: 345 }] },
    { id: 'three', name: '3 tầng, tầng trên dùng hiđrô (minh họa)', payload: 20, stages: [{ mProp: 1500, mDry: 110, isp: 285 }, { mProp: 400, mDry: 30, isp: 330 }, { mProp: 90, mDry: 10, isp: 450 }] }
  ];
  var rk = { stages: RK_PRESETS[1].stages.map(function (s) { return Object.assign({}, s); }), payload: RK_PRESETS[1].payload };
  $('rk-presets').innerHTML = RK_PRESETS.map(function (p) { return '<button class="btn sm" data-rk="' + p.id + '">' + p.name + '</button>'; }).join('');
  $('rk-presets').addEventListener('click', function (e) {
    var b = e.target.closest('[data-rk]');
    if (!b) return;
    var p = RK_PRESETS.filter(function (x) { return x.id === b.getAttribute('data-rk'); })[0];
    rk.stages = p.stages.map(function (s) { return Object.assign({}, s); });
    rk.payload = p.payload;
    renderRocket();
  });
  $('rk-add').addEventListener('click', function () {
    if (rk.stages.length >= 4) { SL.toast('Tối đa 4 tầng.'); return; }
    rk.stages.push({ mProp: 20, mDry: 2, isp: 350 });
    renderRocket();
  });
  $('rk-stages').addEventListener('input', function (e) {
    var t = e.target, i = +t.getAttribute('data-i'), k = t.getAttribute('data-k');
    if (t.matches('input[data-k]')) {
      var val = parseFloat(t.value);
      if (val >= 0) { rk.stages[i][k] = val; renderRocketResult(); }
    }
  });
  $('rk-stages').addEventListener('click', function (e) {
    var b = e.target.closest('[data-del]');
    if (!b) return;
    if (rk.stages.length <= 1) { SL.toast('Cần ít nhất 1 tầng.'); return; }
    rk.stages.splice(+b.getAttribute('data-del'), 1);
    renderRocket();
  });
  $('rk-payload').addEventListener('input', function () {
    var val = parseFloat(this.value);
    if (val >= 0) { rk.payload = val; renderRocketResult(); }
  });
  function renderRocket() {
    $('rk-stages').innerHTML = rk.stages.map(function (s, i) {
      var inp = function (k, step) { return '<input type="number" min="0" step="' + step + '" data-i="' + i + '" data-k="' + k + '" value="' + s[k] + '" aria-label="' + k + ' tầng ' + (i + 1) + '">'; };
      return '<tr><td>' + (i + 1) + (i === 0 ? ' <span class="muted small">(dưới)</span>' : '') + '</td><td>' + inp('mProp', 1) + '</td><td>' + inp('mDry', 0.5) + '</td><td>' + inp('isp', 5) +
        '</td><td><button class="btn sm ghost" data-del="' + i + '" title="Xóa tầng">✕</button></td></tr>';
    }).join('');
    $('rk-payload').value = rk.payload;
    renderRocketResult();
  }
  var LEO_BUDGET = 9.4; // km/s — ngân sách Δv điển hình lên quỹ đạo thấp (gồm tổn hao)
  function renderRocketResult() {
    var valid = rk.stages.every(function (s) { return s.mProp > 0 && s.mDry > 0 && s.isp > 0; });
    if (!valid) { $('rk-result').innerHTML = '<p class="callout warn">Mỗi tầng cần nhiên liệu, vỏ và Isp &gt; 0.</p>'; return; }
    var res = O.rocketStages(rk.stages, rk.payload);
    var totalProp = rk.stages.reduce(function (a, s) { return a + s.mProp; }, 0);
    var single = O.tsiolkovsky(rk.stages[0].isp, res.liftoffMass, res.liftoffMass - totalProp);
    var h = '<div class="table-wrap"><table class="table readout"><tr><th>Tầng</th><th>m₀ (t)</th><th>m_f (t)</th><th>m₀/m_f</th><th>Δv (km/s)</th></tr>';
    res.stages.forEach(function (s, i) {
      h += '<tr><td>' + (i + 1) + '</td><td>' + n(s.m0, 1) + '</td><td>' + n(s.mf, 1) + '</td><td>' + fixed(s.ratio, 2) + '</td><td>' + fixed(s.dv / KM, 2) + '</td></tr>';
    });
    h += '</table></div>';
    var ok = res.total / KM >= LEO_BUDGET;
    h += '<p style="margin:8px 0 4px">Tổng Δv: <b style="font-size:1.25rem">' + fixed(res.total / KM, 2) + ' km/s</b> · khối lượng cất cánh ' + n(res.liftoffMass, 1) + ' t · tải trọng chiếm ' + fixed(100 * rk.payload / res.liftoffMass, 2) + ' %</p>';
    h += '<p class="callout ' + (ok ? 'ok' : 'warn') + ' small" style="margin:6px 0">' + (ok
      ? 'Đủ ngân sách ~' + fixed(LEO_BUDGET, 1) + ' km/s để lên quỹ đạo thấp (ước lượng).'
      : 'Chưa đủ ~' + fixed(LEO_BUDGET, 1) + ' km/s để lên quỹ đạo thấp. Thử giảm tải trọng, giảm khối lượng vỏ, tăng Isp hoặc thêm tầng.') + '</p>';
    if (rk.stages.length > 1) {
      h += '<p class="small muted" style="margin:0">So sánh: nếu dồn toàn bộ nhiên liệu vào <b>một tầng</b> (Isp của tầng 1, cùng tổng khối lượng) thì chỉ đạt Δv = <b>' + fixed(single / KM, 2) + ' km/s</b>. Chia tầng giúp vứt bỏ vỏ rỗng nên lợi thêm ' + fixed((res.total - single) / KM, 2) + ' km/s.</p>';
    }
    $('rk-result').innerHTML = h;
    drawRocketChart(res);
  }
  function drawRocketChart(res) {
    var cv = $('cv-rocket');
    if (!sizeCanvas(cv)) return;
    var ctx = cv.getContext('2d'), W = cv.width, H = cv.height, dpr = cv._dpr;
    var text = cssVar('--text') || '#e7ecfb', muted = cssVar('--muted') || '#97a3c2', accent = cssVar('--accent') || '#5eead4', a2 = cssVar('--accent-2') || '#a78bfa', warn = cssVar('--warn') || '#fbbf24';
    ctx.clearRect(0, 0, W, H);
    var maxV = Math.max(res.total / KM, LEO_BUDGET) * 1.15;
    var left = 44 * dpr, bottom = H - 26 * dpr, top = 12 * dpr, right = W - 10 * dpr;
    var y = function (val) { return bottom - (val / maxV) * (bottom - top); };
    ctx.font = (11 * dpr) + 'px system-ui'; ctx.fillStyle = muted; ctx.strokeStyle = muted; ctx.lineWidth = 1;
    for (var g = 0; g <= maxV; g += 2) {
      ctx.globalAlpha = 0.25; ctx.beginPath(); ctx.moveTo(left, y(g)); ctx.lineTo(right, y(g)); ctx.stroke(); ctx.globalAlpha = 1;
      ctx.textAlign = 'right'; ctx.fillText(g + '', left - 6 * dpr, y(g) + 4 * dpr);
    }
    ctx.save(); ctx.translate(12 * dpr, (top + bottom) / 2); ctx.rotate(-Math.PI / 2); ctx.textAlign = 'center'; ctx.fillText('Δv tích lũy (km/s)', 0, 0); ctx.restore();
    var nb = res.stages.length, bw = (right - left) / nb, cum = 0;
    res.stages.forEach(function (s, i) {
      var x0 = left + i * bw + bw * 0.18, w = bw * 0.64;
      ctx.fillStyle = i % 2 ? a2 : accent;
      ctx.fillRect(x0, y(cum + s.dv / KM), w, y(cum) - y(cum + s.dv / KM));
      cum += s.dv / KM;
      ctx.fillStyle = text; ctx.textAlign = 'center';
      ctx.fillText('Tầng ' + (i + 1) + ': +' + fixed(s.dv / KM, 2), x0 + w / 2, bottom + 16 * dpr);
      if (i < nb - 1) { ctx.strokeStyle = muted; ctx.setLineDash([3, 3]); ctx.beginPath(); ctx.moveTo(x0 + w, y(cum)); ctx.lineTo(x0 + bw, y(cum)); ctx.stroke(); ctx.setLineDash([]); }
    });
    [[LEO_BUDGET, 'Lên quỹ đạo thấp ≈ 9,4 km/s (gồm tổn hao)', warn], [7.8, 'v₁ ở quỹ đạo thấp ≈ 7,8 km/s', muted]].forEach(function (l) {
      ctx.strokeStyle = l[2]; ctx.fillStyle = l[2]; ctx.setLineDash([6, 4]); ctx.lineWidth = 1.5 * dpr;
      ctx.beginPath(); ctx.moveTo(left, y(l[0])); ctx.lineTo(right, y(l[0])); ctx.stroke(); ctx.setLineDash([]);
      ctx.textAlign = 'left'; ctx.fillText(l[1], left + 6 * dpr, y(l[0]) - 5 * dpr);
    });
  }
  $('rk-theory').innerHTML = '<h2>Phương trình tên lửa Tsiolkovsky</h2>' + SL.fmtBlock(
    '$$\\Delta v = I_{sp}\\,g_0\\,\\ln\\frac{m_0}{m_f}$$\n\n' +
    '$m_0$: khối lượng lúc bắt đầu đốt (gồm tải và mọi tầng phía trên), $m_f$: khối lượng khi tầng đó cạn nhiên liệu, $g_0 = 9{,}80665\\ \\mathrm{m/s^2}$. **Xung lượng riêng** $I_{sp}$ (giây) đo "độ hiệu quả" của động cơ: tốc độ khí phụt $v_e = I_{sp}g_0$.\n\n' +
    'Vì Δv chỉ tăng theo **lôgarit** của tỉ số khối lượng, muốn thêm Δv phải tăng nhiên liệu theo hàm mũ. Vứt bỏ vỏ rỗng của tầng dưới (chia tầng) là cách vượt giới hạn này.\n\n' +
    '**Cần xác minh / giới hạn:** con số ~9,4 km/s để lên quỹ đạo thấp là giá trị thường được dẫn (khoảng 9,3–10 km/s, gồm tổn hao do trọng lực và lực cản), phụ thuộc tên lửa và quỹ đạo cụ thể. Mô hình ở đây là Δv lý tưởng trong chân không, không tính tổn hao, thời gian đốt hay lực đẩy.'
  );

  /* =====================================================================
     4. BÀI TẬP — số liệu tính trực tiếp từ OrbitCore
     ===================================================================== */
  function exercises() {
    var E = O.BODIES.earth, mu = E.mu, R = E.R;
    var r400 = R + 400e3, v400 = O.vCircular(mu, r400), T400 = O.period(mu, r400);
    var v1s = O.vCircular(mu, R), v2s = O.vEscape(mu, R);
    var rGeo = O.semiMajorFromPeriod(mu, O.SIDEREAL_DAY);
    var rp = R + 400e3, ra = R + 4000e3, a = (rp + ra) / 2, vp = O.visViva(mu, rp, a), va = O.visViva(mu, ra, a);
    var lg = O.hohmann(mu, R + 300e3, rGeo);
    var em = O.hohmann(O.BODIES.sun.mu, O.AU, O.PLANETS.mars.a * O.AU);
    var isp = 350, dvL = 9400, ratio = Math.exp(dvL / (isp * O.G0));
    var Tm = O.period(O.BODIES.sun.mu, O.PLANETS.mars.a * O.AU) / O.period(O.BODIES.sun.mu, O.AU);
    var D = '\\cdot';
    return [
      {
        title: 'Vận tốc vũ trụ cấp I', tag: 'Cơ bản', go: ['sandbox', 'iss'],
        q: 'Tính tốc độ của vệ tinh chuyển động tròn sát mặt đất và ở độ cao 400 km (độ cao trạm ISS). Biết $GM = 3{,}986' + D + '10^{14}\\ \\mathrm{m^3/s^2}$, $R = 6371\\ \\mathrm{km}$.',
        hint: 'Lực hấp dẫn đóng vai trò lực hướng tâm: $\\dfrac{GMm}{r^2} = \\dfrac{mv^2}{r}$.',
        sol: '$v = \\sqrt{\\dfrac{GM}{r}}$.\n\nSát mặt đất ($r = R$): $v_1 = \\sqrt{\\dfrac{3{,}986' + D + '10^{14}}{6{,}371' + D + '10^{6}}} \\approx ' + fixed(v1s / KM, 2) + '\\ \\mathrm{km/s}$.\n\nỞ độ cao 400 km ($r = 6771\\ \\mathrm{km}$): $v \\approx ' + fixed(v400 / KM, 2) + '\\ \\mathrm{km/s}$ — nhỏ hơn $v_1$: càng lên cao, vệ tinh tròn càng chạy **chậm**.'
      },
      {
        title: 'Chu kì của trạm ISS', tag: 'Cơ bản', go: ['sandbox', 'iss'],
        q: 'Với quỹ đạo tròn ở độ cao 400 km, tính chu kì và số vòng bay mỗi ngày.',
        hint: '$T = \\dfrac{2\\pi r}{v}$ hoặc dùng định luật III Kepler.',
        sol: '$T = 2\\pi\\sqrt{\\dfrac{r^3}{GM}} = ' + thousands(T400, 0) + '\\ \\mathrm{s} \\approx ' + fixed(T400 / 60, 1) + '$ phút.\n\nSố vòng mỗi ngày: $\\dfrac{86\\,400}{' + thousands(T400, 0) + '} \\approx ' + fixed(86400 / T400, 1) + '$ vòng. (Thực tế ISS bay ở khoảng 400–420 km nên chu kì quan sát được ≈ 92–93 phút.)\n\nTrong mô phỏng: chọn "Tròn 400 km", để tua 100× và xem đồng hồ khi tàu quay lại điểm đầu.'
      },
      {
        title: 'Quỹ đạo địa tĩnh', tag: 'Vận dụng', go: ['sandbox', 'geo'],
        q: 'Vệ tinh địa tĩnh đứng yên so với mặt đất nên có chu kì bằng **một ngày sao** ($T = 86\\,164\\ \\mathrm{s}$, không phải 86 400 s). Tính bán kính quỹ đạo và độ cao so với xích đạo ($R_{\\text{xích đạo}} = 6378\\ \\mathrm{km}$).',
        hint: 'Từ định luật III Kepler: $r = \\sqrt[3]{\\dfrac{GM\\,T^2}{4\\pi^2}}$.',
        sol: '$r = \\sqrt[3]{\\dfrac{3{,}986' + D + '10^{14}' + D + '86\\,164^2}{4\\pi^2}} \\approx ' + thousands(rGeo / KM, 0) + '\\ \\mathrm{km}$.\n\nĐộ cao: $' + thousands(rGeo / KM, 0) + ' - 6378 \\approx ' + thousands(rGeo / KM - 6378, 0) + '\\ \\mathrm{km}$ (khớp con số 35 786 km thường gặp). Tốc độ trên quỹ đạo: $' + fixed(O.vCircular(mu, rGeo) / KM, 2) + '\\ \\mathrm{km/s}$.\n\n**Vì sao dùng ngày sao?** Trong một ngày Mặt Trời (24 h), Trái Đất quay được hơn một vòng một chút (vì nó cũng đã đi một đoạn quanh Mặt Trời). So với các ngôi sao — tức là trong hệ quy chiếu của vệ tinh — một vòng quay chỉ mất 23 h 56 min 4 s.'
      },
      {
        title: 'Vận tốc thoát', tag: 'Cơ bản', go: ['sandbox', 'escape'],
        q: 'Chứng minh $v_2 = \\sqrt2\\,v_1$ và tính vận tốc thoát tại mặt đất.',
        hint: 'Vật vừa đủ thoát khi cơ năng bằng 0: $\\dfrac{mv^2}{2} - \\dfrac{GMm}{r} = 0$.',
        sol: '$\\dfrac{v_2^2}{2} = \\dfrac{GM}{r} \\Rightarrow v_2 = \\sqrt{\\dfrac{2GM}{r}} = \\sqrt2\\cdot\\sqrt{\\dfrac{GM}{r}} = \\sqrt2\\,v_1$.\n\nTại mặt đất: $v_2 = \\sqrt2' + D + fixed(v1s / KM, 2) + ' \\approx ' + fixed(v2s / KM, 2) + '\\ \\mathrm{km/s}$.\n\nTrong mô phỏng, preset "Đúng vận tốc thoát" cho quỹ đạo **parabol** (e = 1): tàu đi mãi ra xa, tốc độ giảm dần về 0. Thử giảm $v$ đi 1 % → quỹ đạo thành elip rất dẹt và tàu quay lại.'
      },
      {
        title: 'Phương trình vis-viva và bảo toàn mômen động lượng', tag: 'Vận dụng', go: ['sandbox', 'ellipse'],
        q: 'Vệ tinh bay trên elip có cận điểm ở độ cao 400 km và viễn điểm ở độ cao 4000 km. Tính tốc độ ở cận điểm và viễn điểm. Kiểm tra $r_p v_p = r_a v_a$.',
        hint: 'Bán trục lớn $a = \\dfrac{r_p + r_a}{2}$; dùng $v^2 = GM\\left(\\dfrac2r - \\dfrac1a\\right)$.',
        sol: '$r_p = 6771\\ \\mathrm{km}$, $r_a = 10\\,371\\ \\mathrm{km}$, $a = ' + thousands(a / KM, 0) + '\\ \\mathrm{km}$.\n\n$v_p = ' + fixed(vp / KM, 3) + '\\ \\mathrm{km/s}$, $v_a = ' + fixed(va / KM, 3) + '\\ \\mathrm{km/s}$.\n\n$r_pv_p = ' + thousands(rp * vp / 1e6, 1) + '\\ \\mathrm{km^2/s}$ và $r_av_a = ' + thousands(ra * va / 1e6, 1) + '\\ \\mathrm{km^2/s}$ — bằng nhau: đó là **định luật II Kepler** (mômen động lượng bảo toàn). Vệ tinh nhanh nhất ở cận điểm, chậm nhất ở viễn điểm.'
      },
      {
        title: 'Đưa vệ tinh lên quỹ đạo địa tĩnh (Hohmann)', tag: 'Vận dụng cao', go: ['hohmann', 'earth'],
        q: 'Vệ tinh đang ở quỹ đạo tròn cao 300 km. Tính hai lần tăng tốc Δv₁, Δv₂ của chuyển quỹ đạo Hohmann lên quỹ đạo địa tĩnh và thời gian chuyển.',
        hint: 'Tính $v$ tròn ở hai quỹ đạo và $v$ trên elip chuyển ở hai đầu (vis-viva).',
        sol: '$r_1 = 6671\\ \\mathrm{km}$, $r_2 = ' + thousands(rGeo / KM, 0) + '\\ \\mathrm{km}$, $a_t = ' + thousands(lg.at / KM, 0) + '\\ \\mathrm{km}$.\n\n' +
          '$\\Delta v_1 = ' + fixed(lg.vp / KM, 3) + ' - ' + fixed(lg.v1 / KM, 3) + ' = ' + fixed(lg.dv1 / KM, 3) + '\\ \\mathrm{km/s}$\n\n' +
          '$\\Delta v_2 = ' + fixed(lg.v2 / KM, 3) + ' - ' + fixed(lg.va / KM, 3) + ' = ' + fixed(lg.dv2 / KM, 3) + '\\ \\mathrm{km/s}$\n\n' +
          'Tổng ≈ **' + fixed(lg.dvTotal / KM, 2) + ' km/s**; thời gian $t_H = ' + fixed(lg.tTransfer / 3600, 2) + '$ giờ. (Thực tế vệ tinh còn phải đổi mặt phẳng quỹ đạo về xích đạo nên tốn thêm Δv — mô hình 2D bỏ qua.)'
      },
      {
        title: 'Hành trình Trái Đất → Sao Hỏa', tag: 'Vận dụng cao', go: ['hohmann', 'sun'],
        q: 'Coi quỹ đạo Trái Đất (1 AU) và Sao Hỏa (1,524 AU) là tròn, đồng phẳng. Tính Δv₁, Δv₂ (so với Mặt Trời), thời gian bay và góc Sao Hỏa phải đi trước Trái Đất lúc phóng.',
        hint: 'Như bài trước nhưng $GM_{\\odot} = 1{,}327' + D + '10^{20}\\ \\mathrm{m^3/s^2}$. Góc pha $\\varphi = 180^\\circ - \\omega_{\\text{Hỏa}}\\,t_H$.',
        sol: '$\\Delta v_1 \\approx ' + fixed(em.dv1 / KM, 2) + '\\ \\mathrm{km/s}$, $\\Delta v_2 \\approx ' + fixed(em.dv2 / KM, 2) + '\\ \\mathrm{km/s}$, $t_H \\approx ' + thousands(em.tTransfer / 86400, 0) + '$ ngày (~' + fixed(em.tTransfer / 86400 / 30.44, 1) + ' tháng).\n\n' +
          'Trong $t_H$, Sao Hỏa đi được $\\dfrac{360^\\circ}{' + fixed(Tm * 365.25, 0) + '\\ \\text{ngày}}' + D + thousands(em.tTransfer / 86400, 0) + ' \\approx ' + fixed(180 - em.phase * 180 / Math.PI, 1) + '^\\circ$ ⇒ lúc phóng nó phải đi trước $\\varphi \\approx ' + fixed(em.phase * 180 / Math.PI, 1) + '^\\circ$.\n\n' +
          'Cấu hình này lặp lại sau mỗi chu kì giao hội ≈ ' + thousands(em.synodic / 86400, 0) + ' ngày (~26 tháng) — chính là "cửa sổ phóng" đi Sao Hỏa.'
      },
      {
        title: 'Vì sao tên lửa phải nhiều tầng?', tag: 'Vận dụng', go: ['rocket', 'one'],
        q: 'Cần $\\Delta v \\approx 9{,}4\\ \\mathrm{km/s}$ để lên quỹ đạo thấp. Với động cơ $I_{sp} = 350\\ \\mathrm{s}$, tên lửa **một tầng** phải có tỉ số khối lượng $m_0/m_f$ bằng bao nhiêu? Nhiên liệu chiếm bao nhiêu phần trăm khối lượng cất cánh?',
        hint: 'Đảo phương trình Tsiolkovsky: $\\dfrac{m_0}{m_f} = e^{\\Delta v/(I_{sp}g_0)}$.',
        sol: '$\\dfrac{m_0}{m_f} = \\exp\\left(\\dfrac{9400}{350' + D + '9{,}80665}\\right) \\approx ' + fixed(ratio, 1) + '$.\n\nNhiên liệu chiếm $1 - \\dfrac{1}{' + fixed(ratio, 1) + '} \\approx ' + fixed(100 * (1 - 1 / ratio), 1) + '\\,\\%$ khối lượng; vỏ, động cơ **và** tải trọng chỉ được ' + fixed(100 / ratio, 1) + ' %. Rất khó chế tạo bồn chứa nhẹ như vậy ⇒ người ta **chia tầng**: tầng dưới cạn thì vứt bỏ, phần còn lại nhẹ hơn nhiều. Xem tab Tên lửa để so sánh.'
      },
      {
        title: 'Định luật III Kepler cho Sao Hỏa', tag: 'Cơ bản', go: ['hohmann', 'sun'],
        q: 'Bán trục lớn quỹ đạo Sao Hỏa là 1,524 AU. Tính chu kì quỹ đạo của Sao Hỏa theo năm Trái Đất.',
        hint: 'Với cùng vật trung tâm: $\\dfrac{T^2}{a^3}$ như nhau ⇒ dùng đơn vị năm & AU.',
        sol: '$T_{\\text{Hỏa}} = T_{\\oplus}\\left(\\dfrac{a_{\\text{Hỏa}}}{a_{\\oplus}}\\right)^{3/2} = 1{,}524^{1{,}5} \\approx ' + fixed(Tm, 2) + '$ năm ≈ ' + fixed(Tm * 365.25, 0) + ' ngày.'
      }
    ];
  }
  function renderExercises() {
    var list = exercises();
    $('ex-list').innerHTML = list.map(function (ex, i) {
      return '<article class="card ex" id="ex-' + (i + 1) + '"><div class="row"><h3 style="margin:0">Bài ' + (i + 1) + '. ' + ex.title + '</h3><span class="badge accent">' + ex.tag + '</span></div>' +
        '<div style="margin-top:8px">' + SL.fmtBlock(ex.q) + '</div>' +
        '<details><summary>Gợi ý</summary><div class="sol">' + SL.fmtBlock(ex.hint) + '</div></details>' +
        '<details><summary>Lời giải</summary><div class="sol">' + SL.fmtBlock(ex.sol) + '</div></details>' +
        '<div class="actions" style="margin-top:10px"><button class="btn sm" data-go="' + ex.go.join('|') + '">Thử trong mô phỏng →</button></div></article>';
    }).join('');
    SL.math($('ex-list'));
  }
  $('ex-list').addEventListener('click', function (e) {
    var b = e.target.closest('[data-go]');
    if (!b) return;
    var go = b.getAttribute('data-go').split('|');
    location.hash = '#' + go[0];
    if (go[0] === 'sandbox') {
      if (sb.bodyKey !== 'earth') { $('body').value = 'earth'; sb.bodyKey = 'earth'; sb.body = O.BODIES.earth; renderPresets(); }
      setTimeout(function () { applyPreset(go[1]); }, 30);
    } else if (go[0] === 'hohmann') {
      $('hoh-mode').value = go[1];
      if (go[1] === 'earth') { $('hoh-h1').value = 300; $('hoh-h2').value = 35786; }
      else { $('hoh-from').value = 'earth'; $('hoh-to').value = 'mars'; }
      setTimeout(hohmannSetup, 30);
    } else if (go[0] === 'rocket') {
      var p = RK_PRESETS.filter(function (x) { return x.id === go[1]; })[0];
      rk.stages = p.stages.map(function (s) { return Object.assign({}, s); }); rk.payload = p.payload;
      renderRocket();
    }
    window.scrollTo(0, 0);
  });

  /* ---------------- Khởi động ---------------- */
  window.addEventListener('resize', function () {
    if (current === 'sandbox') drawSandbox();
    if (current === 'hohmann') drawHohmann();
    if (current === 'rocket') renderRocketResult();
  });
  renderPresets();
  SL.math($('sandbox-theory')); SL.math($('hoh-theory')); SL.math($('rk-theory'));
  renderExercises();
  var startTab = location.hash.slice(1).split('-')[0];
  showTab(TABS.indexOf(startTab) >= 0 ? startTab : 'sandbox');
  applyPreset('iss');
  hohmannSetup();
  renderRocket();
  requestAnimationFrame(loop);

  // Cho kiểm thử tự động
  window.OrbitLab = { sb: sb, hh: hh, rk: rk, applyPreset: applyPreset, hohmannSetup: hohmannSetup, exercises: exercises };
})();
