/* ==========================================================================
   Phòng thí nghiệm ảo — giao diện 4 thí nghiệm. Mô phỏng nằm trong labs-core.js.
   ========================================================================== */
(function () {
  'use strict';
  var L = window.LabsCore, SL = window.SL;
  var $ = function (id) { return document.getElementById(id); };
  var fx = function (x, d) { return Number(x).toFixed(d == null ? 2 : d).replace('.', ','); };
  SL.initThemeToggle($('theme-btn'));

  /* ---------------- Tab ---------------- */
  var TABS = ['gas', 'decay', 'lenz', 'gen'], current = 'gas';
  function showTab(name) {
    if (TABS.indexOf(name) < 0) name = 'gas';
    current = name;
    TABS.forEach(function (t) { $('tab-' + t).hidden = t !== name; });
    document.querySelectorAll('.nav a[data-tab]').forEach(function (a) { a.classList.toggle('active', a.getAttribute('data-tab') === name); });
    redrawStatic();
  }
  window.addEventListener('hashchange', function () { showTab(location.hash.slice(1)); });

  /* ---------------- Vẽ đồ thị đơn giản ----------------
     cfg: { xMin, xMax, yMin, yMax, xLabel, yLabel, series: [{ data: [[x,y]], type: 'line'|'step'|'points'|'bars', color, dash, width, barW }],
            vlines: [{ x, label }], hlines: [{ y, label }], legend: [[text, color]] } */
  function plot(cv, cfg) {
    if (!SL.fitCanvas(cv)) return;
    var ctx = cv.getContext('2d'), W = cv.width, H = cv.height, d = cv._dpr;
    var text = SL.cssVar('--text', '#ddd'), muted = SL.cssVar('--muted', '#999'), border = SL.cssVar('--border', '#444');
    ctx.clearRect(0, 0, W, H);
    var L0 = 48 * d, R0 = W - 12 * d, T0 = 14 * d, B0 = H - 34 * d;
    var X = function (x) { return L0 + (x - cfg.xMin) / (cfg.xMax - cfg.xMin) * (R0 - L0); };
    var Y = function (y) { return B0 - (y - cfg.yMin) / (cfg.yMax - cfg.yMin) * (B0 - T0); };
    ctx.font = (11 * d) + 'px system-ui, sans-serif';
    ctx.strokeStyle = border; ctx.fillStyle = muted; ctx.lineWidth = 1;
    function ticks(min, max, n) {
      var step = niceStep((max - min) / n), out = [];
      for (var v = Math.ceil(min / step) * step; v <= max + 1e-9; v += step) out.push(Math.abs(v) < 1e-12 ? 0 : v);
      return out;
    }
    ticks(cfg.yMin, cfg.yMax, 5).forEach(function (v) {
      ctx.globalAlpha = 0.5; ctx.beginPath(); ctx.moveTo(L0, Y(v)); ctx.lineTo(R0, Y(v)); ctx.stroke(); ctx.globalAlpha = 1;
      ctx.textAlign = 'right'; ctx.fillText(fmtTick(v), L0 - 5 * d, Y(v) + 4 * d);
    });
    ticks(cfg.xMin, cfg.xMax, 6).forEach(function (v) {
      ctx.textAlign = 'center'; ctx.fillText(fmtTick(v), X(v), B0 + 14 * d);
    });
    ctx.strokeStyle = muted; ctx.beginPath(); ctx.moveTo(L0, T0); ctx.lineTo(L0, B0); ctx.lineTo(R0, B0); ctx.stroke();
    ctx.fillStyle = text; ctx.textAlign = 'right'; ctx.fillText(cfg.xLabel || '', R0, B0 + 28 * d);
    ctx.textAlign = 'left'; ctx.fillText(cfg.yLabel || '', L0 + 4 * d, T0 - 2 * d + 8 * d);
    (cfg.vlines || []).forEach(function (l) {
      if (l.x < cfg.xMin || l.x > cfg.xMax) return;
      ctx.strokeStyle = muted; ctx.setLineDash([4 * d, 4 * d]); ctx.beginPath(); ctx.moveTo(X(l.x), T0); ctx.lineTo(X(l.x), B0); ctx.stroke(); ctx.setLineDash([]);
      if (l.label) { ctx.fillStyle = muted; ctx.textAlign = 'center'; ctx.fillText(l.label, X(l.x), T0 + 10 * d); }
    });
    (cfg.hlines || []).forEach(function (l) {
      ctx.strokeStyle = muted; ctx.setLineDash([4 * d, 4 * d]); ctx.beginPath(); ctx.moveTo(L0, Y(l.y)); ctx.lineTo(R0, Y(l.y)); ctx.stroke(); ctx.setLineDash([]);
      if (l.label) { ctx.fillStyle = muted; ctx.textAlign = 'right'; ctx.fillText(l.label, R0, Y(l.y) - 4 * d); }
    });
    ctx.save(); ctx.beginPath(); ctx.rect(L0, T0 - 2, R0 - L0, B0 - T0 + 4); ctx.clip();
    (cfg.series || []).forEach(function (s) {
      ctx.strokeStyle = ctx.fillStyle = s.color; ctx.lineWidth = (s.width || 2) * d;
      if (s.dash) ctx.setLineDash([6 * d, 5 * d]);
      if (s.type === 'points') {
        s.data.forEach(function (p) { ctx.beginPath(); ctx.arc(X(p[0]), Y(p[1]), 4 * d, 0, 7); ctx.fill(); });
      } else if (s.type === 'bars') {
        s.data.forEach(function (p) {
          var x0 = X(p[0] - s.barW / 2), x1 = X(p[0] + s.barW / 2);
          ctx.globalAlpha = 0.55; ctx.fillRect(x0 + 1, Y(p[1]), x1 - x0 - 2, B0 - Y(p[1])); ctx.globalAlpha = 1;
        });
      } else {
        ctx.beginPath();
        s.data.forEach(function (p, i) {
          var x = X(p[0]), y = Y(p[1]);
          if (i === 0) ctx.moveTo(x, y);
          else if (s.type === 'step') { ctx.lineTo(x, Y(s.data[i - 1][1])); ctx.lineTo(x, y); }
          else ctx.lineTo(x, y);
        });
        ctx.stroke();
      }
      ctx.setLineDash([]);
    });
    ctx.restore();
    var lx = L0 + 10 * d;
    (cfg.legend || []).forEach(function (l) {
      ctx.fillStyle = l[1]; ctx.fillRect(lx, T0 + 16 * d, 12 * d, 4 * d);
      ctx.fillStyle = text; ctx.textAlign = 'left'; ctx.fillText(l[0], lx + 16 * d, T0 + 21 * d);
      lx += ctx.measureText(l[0]).width + 34 * d;
    });
  }
  function niceStep(x) { var p = Math.pow(10, Math.floor(Math.log10(x))), m = x / p; return (m < 1.5 ? 1 : m < 3.5 ? 2 : m < 7.5 ? 5 : 10) * p; }
  function fmtTick(v) { return Math.abs(v) >= 1000 ? Math.round(v).toString() : String(+v.toPrecision(3)).replace('.', ','); }
  function colors() {
    return { accent: SL.cssVar('--accent', '#5eead4'), a2: SL.cssVar('--accent-2', '#a78bfa'), warn: SL.cssVar('--warn', '#fbbf24'),
      bad: SL.cssVar('--bad', '#fb923c'), ok: SL.cssVar('--ok', '#4ade80'), text: SL.cssVar('--text', '#ddd'), muted: SL.cssVar('--muted', '#999'),
      border: SL.cssVar('--border', '#444'), surface2: SL.cssVar('--surface-2', '#222') };
  }
  function tableRows(id, rows) {
    $(id).innerHTML = rows.map(function (r) { return '<tr><td>' + r[0] + '</td><td>' + r[1] + '</td></tr>'; }).join('');
  }

  /* =====================================================================
     1. KHÍ LÍ TƯỞNG
     ===================================================================== */
  var gas = { g: null, paused: false, records: [], targetW: 1, frame: 0, drag: false };
  function gasReset() {
    gas.g = new L.Gas({ N: +$('gas-n').value, T: +$('gas-T').value, W: gas.targetW, seed: Date.now() % 100000, thermostat: $('gas-thermo').checked });
  }
  $('gas-n').addEventListener('change', gasReset);
  $('gas-thermo').addEventListener('change', function () { gas.g.thermostat = this.checked; });
  $('gas-T').addEventListener('input', function () {
    gas.g.Tset = +this.value; $('gas-T-val').textContent = fx(this.value);
    if (!$('gas-thermo').checked) { $('gas-thermo').checked = true; gas.g.thermostat = true; SL.toast('Đã bật bộ ổn nhiệt để đặt nhiệt độ.'); }
  });
  $('gas-S').addEventListener('input', function () { gas.targetW = +this.value; $('gas-S-val').textContent = fx(this.value); });
  $('gas-pause').addEventListener('click', function () { gas.paused = !gas.paused; this.textContent = gas.paused ? '▶' : '⏸'; });
  $('gas-same').addEventListener('click', function () {
    $('gas-thermo').checked = false; gas.g.thermostat = false;
    var v = Math.sqrt(2 * gas.g.Tset);
    gas.g.p.forEach(function (a, i) { var ang = i * 2.399963; a.vx = v * Math.cos(ang); a.vy = v * Math.sin(ang); });
    SL.toast('Mọi phân tử cùng tốc độ; đã tắt bộ ổn nhiệt. Theo dõi biểu đồ phân bố.');
  });
  $('gas-rec').addEventListener('click', function () {
    var g = gas.g;
    if (Math.abs(g.W - gas.targetW) > 0.005) { SL.toast('Chờ pit-tông dừng hẳn rồi hãy ghi.'); return; }
    if (g.t < 1.5) { SL.toast('Chờ khoảng 2 giây để áp suất ổn định.'); return; }
    gas.records.push({ S: g.area(), T: g.temperature(), p: g.pressure(), N: g.p.length });
    renderGasTable(); drawGasPlot();
  });
  $('gas-clear').addEventListener('click', function () { gas.records = []; renderGasTable(); drawGasPlot(); });
  $('gas-axes').addEventListener('change', drawGasPlot);
  function renderGasTable() {
    if (!gas.records.length) { $('gas-table').innerHTML = '<tr><td class="muted">Chưa có điểm đo. Đổi S hoặc T, chờ ổn định, bấm "Ghi điểm đo".</td></tr>'; return; }
    $('gas-table').innerHTML = '<tr><th>#</th><th>S</th><th>T</th><th>p</th><th>pS</th><th>pS/T</th></tr>' + gas.records.map(function (r, i) {
      return '<tr><td>' + (i + 1) + '</td><td>' + fx(r.S) + '</td><td>' + fx(r.T) + '</td><td>' + fx(r.p, 1) + '</td><td>' + fx(r.p * r.S, 1) + '</td><td>' + fx(r.p * r.S / r.T, 1) + '</td></tr>';
    }).join('');
  }
  function drawGasPlot() {
    var c = colors(), mode = $('gas-axes').value, recs = gas.records, g = gas.g, N = g.p.length;
    var T = recs.length ? recs[recs.length - 1].T : g.Tset, S = g.area();
    var cfg = { series: [], legend: [['Điểm đo', c.warn], ['Lý thuyết lí tưởng', c.accent]] }, theory = [];
    if (mode === 'pS') {
      cfg.xMin = 0; cfg.xMax = 1.7; cfg.xLabel = 'S (diện tích, đvtđ)'; cfg.yLabel = 'p';
      for (var s = 0.3; s <= 1.7; s += 0.02) theory.push([s, N * T / s]);
      cfg.series.push({ data: recs.map(function (r) { return [r.S, r.p]; }), type: 'points', color: c.warn });
      cfg.yMax = Math.max(N * T / 0.35, 10);
    } else if (mode === 'pinvS') {
      cfg.xMin = 0; cfg.xMax = 2.6; cfg.xLabel = '1/S'; cfg.yLabel = 'p';
      theory = [[0, 0], [2.6, N * T * 2.6]];
      cfg.series.push({ data: recs.map(function (r) { return [1 / r.S, r.p]; }), type: 'points', color: c.warn });
      cfg.yMax = N * T * 2.6;
    } else {
      cfg.xMin = 0; cfg.xMax = 3.2; cfg.xLabel = 'T (đvtđ)'; cfg.yLabel = 'p';
      theory = [[0, 0], [3.2, N * 3.2 / S]];
      cfg.series.push({ data: recs.map(function (r) { return [r.T, r.p]; }), type: 'points', color: c.warn });
      cfg.yMax = N * 3.2 / S;
    }
    cfg.yMin = 0;
    cfg.series.unshift({ data: theory, type: 'line', color: c.accent, dash: true });
    plot($('cv-gas-plot'), cfg);
  }
  function drawGasHist() {
    var g = gas.g, c = colors(), T = g.temperature(), vmax = 4 * Math.sqrt(Math.max(T, 0.05)), nb = 20, bw = vmax / nb, bins = new Array(nb).fill(0);
    g.p.forEach(function (a) { var k = Math.floor(Math.hypot(a.vx, a.vy) / bw); if (k < nb) bins[k]++; });
    var theory = [];
    for (var v = 0; v <= vmax; v += vmax / 80) theory.push([v, g.p.length * L.maxwell2D(v, T) * bw]);
    var ymax = Math.max.apply(null, bins.concat(theory.map(function (p) { return p[1]; }))) * 1.15 || 1;
    plot($('cv-gas-hist'), { xMin: 0, xMax: vmax, yMin: 0, yMax: ymax, xLabel: 'tốc độ v', yLabel: 'số phân tử',
      series: [{ data: bins.map(function (n, i) { return [(i + 0.5) * bw, n]; }), type: 'bars', barW: bw, color: c.a2 }, { data: theory, type: 'line', color: c.accent }],
      legend: [['Mô phỏng', c.a2], ['Maxwell 2D', c.accent]] });
  }
  var gasView = {};
  function drawGas() {
    var cv = $('cv-gas');
    if (!SL.fitCanvas(cv)) return;
    var ctx = cv.getContext('2d'), Wc = cv.width, Hc = cv.height, d = cv._dpr, g = gas.g;
    var m = 16 * d, sc = Math.min((Wc - 2 * m - 40 * d) / 1.65, Hc - 2 * m);
    var ox = m, oy = (Hc - sc) / 2;
    gasView = { ox: ox, oy: oy, sc: sc };
    ctx.fillStyle = '#0b1124'; ctx.fillRect(0, 0, Wc, Hc);
    // vùng tối đa
    ctx.strokeStyle = 'rgba(255,255,255,0.08)'; ctx.setLineDash([4 * d, 4 * d]); ctx.strokeRect(ox, oy, 1.6 * sc, sc); ctx.setLineDash([]);
    ctx.strokeStyle = '#c9d3f2'; ctx.lineWidth = 2 * d;
    ctx.beginPath(); ctx.moveTo(ox + g.W * sc, oy); ctx.lineTo(ox, oy); ctx.lineTo(ox, oy + sc); ctx.lineTo(ox + g.W * sc, oy + sc); ctx.stroke();
    var vref = 2.5 * Math.sqrt(g.Tset), rpx = Math.max(2 * d, g.r * sc * 1.4);
    g.p.forEach(function (a) {
      var v = Math.hypot(a.vx, a.vy), h = 220 - Math.min(1, v / vref) * 220;
      ctx.fillStyle = 'hsl(' + h + ',85%,60%)';
      ctx.beginPath(); ctx.arc(ox + a.x * sc, oy + (1 - a.y) * sc, rpx, 0, 7); ctx.fill();
    });
    // pit-tông
    var px = ox + g.W * sc;
    ctx.fillStyle = gas.drag ? '#fbbf24' : '#8ea0c9';
    ctx.fillRect(px, oy - 4 * d, 10 * d, sc + 8 * d);
    ctx.fillRect(px + 10 * d, oy + sc / 2 - 4 * d, Wc, 8 * d);
    ctx.fillStyle = '#c9d3f2'; ctx.font = (12 * d) + 'px system-ui'; ctx.textAlign = 'left';
    ctx.fillText('← kéo pit-tông', Math.min(px + 16 * d, Wc - 100 * d), oy + sc / 2 - 12 * d);
  }
  // kéo pit-tông bằng chuột/ngón tay
  (function () {
    var cv = $('cv-gas');
    function worldX(e) { var r = cv.getBoundingClientRect(); return ((e.clientX - r.left) * (cv._dpr || 1) - gasView.ox) / gasView.sc; }
    cv.addEventListener('pointerdown', function (e) {
      if (Math.abs(worldX(e) - gas.g.W) < 0.12) { gas.drag = true; cv.setPointerCapture(e.pointerId); }
    });
    cv.addEventListener('pointermove', function (e) {
      if (!gas.drag) return;
      var w = Math.max(0.4, Math.min(1.6, Math.round(worldX(e) * 20) / 20));
      gas.targetW = w; $('gas-S').value = w; $('gas-S-val').textContent = fx(w);
    });
    var up = function () { gas.drag = false; };
    cv.addEventListener('pointerup', up); cv.addEventListener('pointercancel', up);
  })();
  function gasFrame() {
    var g = gas.g;
    if (!gas.paused) {
      for (var i = 0; i < 6; i++) {
        var diff = gas.targetW - g.W;
        g.wallU = Math.abs(diff) < 0.002 ? 0 : Math.max(-0.4, Math.min(0.4, diff * 4));
        if (!g.wallU) g.W = gas.targetW;
        g.step(0.0025);
      }
    }
    drawGas();
    if (gas.frame++ % 8 === 0) {
      var p = g.pressure(), T = g.temperature();
      tableRows('gas-read', [
        ['Thời gian', fx(g.t, 1)],
        ['Nhiệt độ đo được T', fx(T)],
        ['Diện tích S', fx(g.area())],
        ['Áp suất đo p (TB 2 s)', fx(p, 1)],
        ['Lý thuyết NkT/S', fx(g.pressureTheory(T), 1)],
        ['Tỉ số pS/(NkT)', fx(p * g.area() / (g.p.length * T), 3)]
      ]);
      drawGasHist();
    }
  }

  $('gas-explain').innerHTML = '<h2>Giải thích & câu hỏi khám phá</h2>' + SL.fmtBlock(
    'Mỗi chấm là một phân tử (màu xanh = chậm, đỏ = nhanh). Chúng va chạm đàn hồi với nhau và với thành hộp. **Áp suất** được đo thật sự bằng cách cộng xung lượng $2mv_\\perp$ mà các phân tử truyền cho thành trong 2 giây rồi chia cho thời gian và chu vi hộp.\n\n' +
    'Mô phỏng chạy trong **2 chiều** nên "thể tích" là diện tích $S$, động năng trung bình mỗi phân tử là $kT$ (2 bậc tự do, thay vì $\\tfrac32kT$ trong 3 chiều) và phương trình trạng thái là $pS = NkT$. Mọi tỉ lệ (Boyle, Charles, đẳng tích) giữ nguyên như trong sách. Đơn vị là đơn vị mô phỏng ($m = k = 1$).'
  ) + qa([
    ['Giữ T, ghi 4–5 điểm đo với S khác nhau. Cột pS có gần như không đổi không? Đó là định luật nào?', 'pS gần như không đổi (lệch vài % do dao động thống kê và kích thước phân tử) — định luật Boyle. Chọn đồ thị "p theo 1/S": các điểm nằm trên đường thẳng qua gốc.'],
    ['Giữ S, tăng T từ 0,5 lên 2. Áp suất thay đổi thế nào? Vì sao theo mô hình động học?', 'p tăng tỉ lệ thuận với T. Nhiệt độ cao → phân tử nhanh hơn → mỗi va chạm truyền xung lượng lớn hơn và va chạm thường xuyên hơn.'],
    ['Tắt bộ ổn nhiệt rồi đẩy pit-tông vào nhanh. Nhiệt độ thay đổi ra sao? Liên hệ định luật I nhiệt động lực học.', 'Nhiệt độ tăng: pit-tông chuyển động ngược chiều phân tử nên phân tử bật lại nhanh hơn — khí nhận công A > 0, Q = 0 (không ổn nhiệt) nên ΔU = A > 0. Kéo pit-tông ra thì ngược lại, khí lạnh đi.'],
    ['Bấm "Cho mọi phân tử cùng tốc độ". Vì sao chỉ sau vài giây phân bố tốc độ đã trải rộng?', 'Va chạm phân phối lại động năng giữa các phân tử: tổng năng lượng bảo toàn nhưng tốc độ từng hạt thay đổi ngẫu nhiên, cuối cùng đạt phân bố Maxwell — trạng thái "hỗn loạn nhất" ứng với năng lượng đó.']
  ]);

  /* =====================================================================
     2. PHÓNG XẠ
     ===================================================================== */
  var ISOS = [
    { name: 'Chất giả định (T = 10 s)', T: 10, unit: 's' },
    { name: 'Iốt-131 (T = 8,02 ngày)', T: 8.02, unit: 'ngày' },
    { name: 'Radon-222 (T = 3,82 ngày)', T: 3.82, unit: 'ngày' },
    { name: 'Pôlôni-210 (T = 138,4 ngày)', T: 138.4, unit: 'ngày' },
    { name: 'Côban-60 (T = 5,27 năm)', T: 5.27, unit: 'năm' },
    { name: 'Cacbon-14 (T = 5730 năm)', T: 5730, unit: 'năm' }
  ];
  $('dc-iso').innerHTML = ISOS.map(function (s, i) { return '<option value="' + i + '">' + s.name + '</option>'; }).join('');
  var dc = { d: null, running: false, lastDecay: null };
  function iso() { return ISOS[+$('dc-iso').value]; }
  function dcReset() {
    dc.d = new L.Decay(+$('dc-n').value, 1, (Date.now() % 9973) + 1);
    dc.running = false; $('dc-run').textContent = '▶ Bắt đầu';
    dcDraw(); dcPlot(); dcRead();
  }
  ['dc-iso', 'dc-n'].forEach(function (id) { $(id).addEventListener('change', dcReset); });
  $('dc-reset').addEventListener('click', dcReset);
  $('dc-run').addEventListener('click', function () {
    if (dc.d.N === 0 || dc.d.t >= 6) dcReset();
    dc.running = !dc.running; this.textContent = dc.running ? '⏸ Tạm dừng' : '▶ Tiếp tục';
  });
  $('dc-speed').addEventListener('input', function () { $('dc-speed-val').textContent = fx(this.value) + ' chu kì / giây'; });
  $('dc-speed-val').textContent = fx($('dc-speed').value) + ' chu kì / giây';
  function dcDraw() {
    var cv = $('cv-decay');
    if (!SL.fitCanvas(cv)) return;
    var ctx = cv.getContext('2d'), W = cv.width, H = cv.height, d = dc.d, c = colors();
    ctx.clearRect(0, 0, W, H);
    var n = d.N0, cols = Math.ceil(Math.sqrt(n * W / H)), rows = Math.ceil(n / cols);
    var cell = Math.min((W - 20) / cols, (H - 20) / rows), ox = (W - cols * cell) / 2, oy = (H - rows * cell) / 2;
    var gap = cell > 6 ? 1.5 : 0;
    for (var i = 0; i < n; i++) {
      var x = ox + (i % cols) * cell, y = oy + Math.floor(i / cols) * cell;
      if (d.alive[i]) ctx.fillStyle = c.accent;
      else if (d.t - d.decayTime[i] < 0.06) ctx.fillStyle = c.warn;
      else ctx.fillStyle = c.border;
      ctx.fillRect(x + gap, y + gap, cell - 2 * gap, cell - 2 * gap);
    }
  }
  function dcPlot() {
    var d = dc.d, c = colors(), th = [];
    for (var t = 0; t <= 6; t += 0.05) th.push([t, d.theory(t)]);
    plot($('cv-decay-plot'), { xMin: 0, xMax: 6, yMin: 0, yMax: d.N0 * 1.05, xLabel: 't / T', yLabel: 'N',
      series: [{ data: th, color: c.accent, dash: true }, { data: d.history, type: 'step', color: c.warn }],
      vlines: [{ x: 1, label: 'T' }, { x: 2, label: '2T' }, { x: 3, label: '3T' }], hlines: [{ y: d.N0 / 2, label: 'N₀/2' }],
      legend: [['Mô phỏng', c.warn], ['N₀·2^(−t/T)', c.accent]] });
  }
  function dcRead() {
    var d = dc.d, s = iso(), h = d.history, k = h.length - 1, j = k;
    while (j > 0 && h[k][0] - h[j][0] < 0.1) j--;
    var act = k > j ? (h[j][1] - h[k][1]) / ((h[k][0] - h[j][0]) * s.T) : 0;
    tableRows('dc-read', [
      ['Thời gian t', fx(d.t * s.T, s.T > 100 ? 0 : 2) + ' ' + s.unit + ' (' + fx(d.t, 2) + ' T)'],
      ['Số hạt còn lại N', d.N + ' / ' + d.N0],
      ['N/N₀ (mô phỏng)', fx(100 * d.N / d.N0, 1) + ' %'],
      ['N/N₀ (lý thuyết)', fx(100 * Math.pow(2, -d.t), 1) + ' %'],
      ['Độ phóng xạ (phân rã/' + s.unit + ')', fx(act, act > 100 ? 0 : 1)]
    ]);
  }
  function dcFrame(dtReal) {
    if (!dc.running) return;
    var d = dc.d;
    d.step(dtReal * +$('dc-speed').value);
    if (d.N === 0 || d.t >= 6) { dc.running = false; $('dc-run').textContent = '↺ Chạy lại'; }
    dcDraw(); dcPlot(); dcRead();
  }
  document.querySelectorAll('[data-rep]').forEach(function (b) {
    b.addEventListener('click', function () {
      var n0 = +b.getAttribute('data-rep'), res = [], c = colors();
      for (var k = 0; k < 20; k++) {
        var d = new L.Decay(n0, 1, 1000 + k * 7919 + n0);
        while (d.N > n0 / 2) d.step(0.005);
        res.push(d.t);
      }
      var mean = res.reduce(function (a, b2) { return a + b2; }) / res.length;
      var sd = Math.sqrt(res.reduce(function (a, x) { return a + (x - mean) * (x - mean); }, 0) / (res.length - 1));
      plot($('cv-rep'), { xMin: 0, xMax: 21, yMin: 0, yMax: Math.max(2, Math.max.apply(null, res) * 1.1), xLabel: 'lần đo', yLabel: 't½ đo / T',
        series: [{ data: res.map(function (t, i) { return [i + 1, t]; }), type: 'points', color: c.warn }], hlines: [{ y: 1, label: 'giá trị thật' }] });
      $('rep-out').innerHTML = 'N₀ = ' + n0 + ': chu kì bán rã đo được trung bình <b>' + fx(mean, 2) + ' T</b>, độ lệch chuẩn <b>' + fx(sd, 2) + ' T</b> ' +
        '(nhỏ nhất ' + fx(Math.min.apply(null, res), 2) + ', lớn nhất ' + fx(Math.max.apply(null, res), 2) + ').';
    });
  });
  $('decay-explain').innerHTML = '<h2>Giải thích & câu hỏi khám phá</h2>' + SL.fmtBlock(
    'Trong mỗi khoảng thời gian ngắn $\\Delta t$, **mỗi** hạt nhân chưa phân rã có cùng một xác suất phân rã $1 - 2^{-\\Delta t/T}$, độc lập với các hạt khác và với "tuổi" của nó. Không thể biết **hạt nào** phân rã lúc nào, nhưng với số đông, số hạt còn lại bám rất sát $N = N_0\\cdot2^{-t/T}$. Ô vàng là hạt vừa phân rã.\n\n' +
    'Thời gian trên đồng hồ được đổi theo chu kì của chất bạn chọn — mô phỏng chạy theo đơn vị $T$ nên mọi chất có đường cong giống hệt nhau.'
  ) + qa([
    ['Chạy với N₀ = 100 vài lần. Sau đúng 1 chu kì có phải lúc nào cũng còn 50 hạt không?', 'Không — có khi 44, có khi 57… Định luật phóng xạ là quy luật thống kê; sai lệch tương đối cỡ $1/\\sqrt{N}$, nên N₀ càng lớn càng sát lý thuyết.'],
    ['Dùng phần "Đo chu kì bán rã 20 lần" với N₀ = 20 và N₀ = 1000. So sánh độ lệch chuẩn.', 'Với N₀ = 20 kết quả dao động mạnh (độ lệch chuẩn cỡ 0,3T); với N₀ = 1000 chỉ cỡ 0,05T. Một mẫu thật có khoảng 10²⁰ hạt nên chu kì bán rã đo được cực kì ổn định.'],
    ['Độ phóng xạ ở cuối thí nghiệm thay đổi thế nào so với lúc đầu? Vì sao?', 'Giảm theo cùng quy luật $H = \\lambda N = H_0 2^{-t/T}$, vì số phân rã mỗi giây tỉ lệ với số hạt còn lại.'],
    ['Sau 2T còn bao nhiêu phần trăm? Đã phân rã bao nhiêu phần trăm?', 'Còn 25 %, đã phân rã 75 % — đây là bẫy hay gặp trong đề thi (đọc kỹ "còn lại" hay "đã phân rã").']
  ]);

  /* =====================================================================
     3. ĐỊNH LUẬT LENZ
     ===================================================================== */
  var lz = { x: -3, sign: 1, phi: 0, e: 0, hist: [], t: 0, drag: false, auto: false, lastPhi: null, view: {} };
  var A_RING = 1, PHI_MAX = 1;
  $('lz-flip').addEventListener('click', function () { lz.sign *= -1; lz.lastPhi = null; });
  $('lz-auto').addEventListener('change', function () { lz.auto = this.checked; });
  $('lz-n').addEventListener('input', function () { $('lz-n-val').textContent = this.value; });
  (function () {
    var cv = $('cv-lenz');
    function wx(e) { var r = cv.getBoundingClientRect(); return ((e.clientX - r.left) * (cv._dpr || 1) - lz.view.cx) / lz.view.sc; }
    cv.addEventListener('pointerdown', function (e) {
      if (Math.abs(wx(e) - lz.x) < 1.2) { lz.drag = true; lz.auto = false; $('lz-auto').checked = false; cv.setPointerCapture(e.pointerId); }
    });
    cv.addEventListener('pointermove', function (e) { if (lz.drag) lz.x = Math.max(-5.5, Math.min(5.5, wx(e))); });
    var up = function () { lz.drag = false; };
    cv.addEventListener('pointerup', up); cv.addEventListener('pointercancel', up);
  })();
  function lzFrame(dt) {
    if (dt <= 0) return;
    lz.t += dt;
    if (lz.auto) lz.x = -2.7 + 2.1 * Math.sin(1.4 * lz.t);
    var N = +$('lz-n').value;
    var phi = lz.sign * L.dipoleFlux(lz.x, A_RING, PHI_MAX);
    var raw = lz.lastPhi == null ? 0 : -N * (phi - lz.lastPhi) / dt;
    lz.lastPhi = phi;
    lz.e = 0.7 * lz.e + 0.3 * raw;           // làm mượt nhẹ
    lz.phi = phi;
    lz.hist.push([lz.t, phi, lz.e]);
    while (lz.hist.length && lz.hist[0][0] < lz.t - 6) lz.hist.shift();
    lzDraw(); lzPlot(); lzSay();
  }
  function lzDraw() {
    var cv = $('cv-lenz');
    if (!SL.fitCanvas(cv)) return;
    var ctx = cv.getContext('2d'), W = cv.width, H = cv.height, d = cv._dpr, c = colors();
    ctx.clearRect(0, 0, W, H);
    var sc = Math.min(W / 13, H / 6), cx = W / 2 + sc * 0.5, cy = H * 0.62;
    lz.view = { sc: sc, cx: cx };
    // trục
    ctx.strokeStyle = c.border; ctx.setLineDash([4 * d, 4 * d]); ctx.beginPath(); ctx.moveTo(0, cy); ctx.lineTo(W, cy); ctx.stroke(); ctx.setLineDash([]);
    // vòng dây (phối cảnh)
    var ringH = sc * 1.25, ringW = sc * 0.35;
    var faceL = '', faceR = '';
    if (Math.abs(lz.e) > 0.02) { var m = lz.e > 0 ? 1 : -1; faceR = m > 0 ? 'N' : 'S'; faceL = m > 0 ? 'S' : 'N'; }
    ctx.lineWidth = (3 + Math.min(4, Math.abs(lz.e) * 3)) * d;
    ctx.strokeStyle = Math.abs(lz.e) > 0.02 ? c.warn : c.muted;
    ctx.beginPath(); ctx.ellipse(cx, cy, ringW, ringH, 0, 0, 2 * Math.PI); ctx.stroke();
    ctx.font = 'bold ' + (16 * d) + 'px system-ui'; ctx.textAlign = 'center';
    if (faceL) {
      ctx.fillStyle = faceL === 'N' ? '#e5484d' : '#3e7bfa'; ctx.fillText(faceL, cx - ringW - 16 * d, cy - ringH - 6 * d);
      ctx.fillStyle = faceR === 'N' ? '#e5484d' : '#3e7bfa'; ctx.fillText(faceR, cx + ringW + 16 * d, cy - ringH - 6 * d);
    }
    // nam châm
    var mx = cx + lz.x * sc, half = 0.9 * sc, mh = 0.42 * sc;
    var rightIsN = lz.sign > 0;
    ctx.fillStyle = rightIsN ? '#3e7bfa' : '#e5484d'; ctx.fillRect(mx - half, cy - mh / 2, half, mh);
    ctx.fillStyle = rightIsN ? '#e5484d' : '#3e7bfa'; ctx.fillRect(mx, cy - mh / 2, half, mh);
    ctx.fillStyle = '#fff'; ctx.font = 'bold ' + (14 * d) + 'px system-ui';
    ctx.fillText(rightIsN ? 'S' : 'N', mx - half / 2, cy + 5 * d); ctx.fillText(rightIsN ? 'N' : 'S', mx + half / 2, cy + 5 * d);
    if (lz.drag) { ctx.strokeStyle = c.warn; ctx.lineWidth = 2 * d; ctx.strokeRect(mx - half, cy - mh / 2, 2 * half, mh); }
    // điện kế
    var gx = W * 0.5, gy = H * 0.26, gr = Math.min(W, H) * 0.17;
    ctx.strokeStyle = c.muted; ctx.lineWidth = 2 * d;
    ctx.beginPath(); ctx.arc(gx, gy, gr, Math.PI * 1.15, Math.PI * 1.85); ctx.stroke();
    ctx.fillStyle = c.muted; ctx.font = (12 * d) + 'px system-ui'; ctx.fillText('0', gx, gy - gr - 6 * d); ctx.fillText('điện kế', gx, gy + 16 * d);
    var ang = -Math.PI / 2 + Math.max(-1, Math.min(1, lz.e / 2.5)) * 0.33 * Math.PI;
    ctx.strokeStyle = c.bad; ctx.lineWidth = 3 * d;
    ctx.beginPath(); ctx.moveTo(gx, gy); ctx.lineTo(gx + gr * Math.cos(ang), gy + gr * Math.sin(ang)); ctx.stroke();
    // hình nhỏ: nhìn vòng dây từ phía trái
    var ix = 70 * d, iy = 70 * d, ir = 34 * d;
    ctx.strokeStyle = c.muted; ctx.lineWidth = 2 * d; ctx.beginPath(); ctx.arc(ix, iy, ir, 0, 2 * Math.PI); ctx.stroke();
    ctx.fillStyle = c.muted; ctx.font = (11 * d) + 'px system-ui'; ctx.fillText('nhìn từ bên trái', ix, iy + ir + 16 * d);
    if (Math.abs(lz.e) > 0.02) {
      // e > 0: dòng theo chiều dương quanh trục +x → nhìn từ trái (từ phía −x) thấy thuận chiều kim đồng hồ
      var cw = lz.e > 0;
      ctx.strokeStyle = c.warn; ctx.lineWidth = 3 * d;
      ctx.beginPath(); ctx.arc(ix, iy, ir, -Math.PI / 2 - 0.9, -Math.PI / 2 + 0.9); ctx.stroke();
      var tipA = cw ? -Math.PI / 2 + 0.9 : -Math.PI / 2 - 0.9, tx = ix + ir * Math.cos(tipA), ty = iy + ir * Math.sin(tipA);
      var dir = cw ? tipA + Math.PI / 2 : tipA - Math.PI / 2;
      ctx.fillStyle = c.warn; ctx.beginPath(); ctx.moveTo(tx + 9 * d * Math.cos(dir), ty + 9 * d * Math.sin(dir));
      ctx.lineTo(tx + 7 * d * Math.cos(dir + 2.3), ty + 7 * d * Math.sin(dir + 2.3)); ctx.lineTo(tx + 7 * d * Math.cos(dir - 2.3), ty + 7 * d * Math.sin(dir - 2.3)); ctx.fill();
      ctx.fillStyle = c.text; ctx.fillText(cw ? 'thuận chiều KĐH' : 'ngược chiều KĐH', ix, iy + 4 * d);
    }
  }
  function lzPlot() {
    var c = colors(), h = lz.hist;
    if (!h.length) return;
    var t1 = lz.t, t0 = t1 - 6, emax = Math.max(1, Math.max.apply(null, h.map(function (p) { return Math.abs(p[2]); })));
    plot($('cv-lenz-plot'), { xMin: t0, xMax: t1, yMin: -1.15, yMax: 1.15, xLabel: 't (s)', yLabel: 'đã chuẩn hóa',
      series: [{ data: h.map(function (p) { return [p[0], p[1] / PHI_MAX]; }), color: c.accent }, { data: h.map(function (p) { return [p[0], p[2] / emax]; }), color: c.warn }],
      hlines: [{ y: 0 }], legend: [['Φ', c.accent], ['e = −N·dΦ/dt', c.warn]] });
  }
  function lzSay() {
    var e = lz.e, txt;
    if (Math.abs(e) < 0.02) txt = 'Từ thông qua vòng dây <b>không đổi</b> ⇒ không có dòng điện cảm ứng (kim điện kế ở số 0).';
    else {
      var phiInc = -e * lz.sign > 0;   // |Φ| tăng khi e ngược dấu với Φ
      var facing = lz.x < 0 ? 'bên trái' : 'bên phải';
      var faceN = lz.x < 0 ? (e < 0 ? 'N' : 'S') : (e > 0 ? 'N' : 'S');
      txt = '|Φ| đang <b>' + (phiInc ? 'tăng' : 'giảm') + '</b> ⇒ dòng điện cảm ứng sinh từ trường <b>' + (phiInc ? 'ngược chiều' : 'cùng chiều') + '</b> từ trường của nam châm. ' +
        'Mặt vòng dây ' + facing + ' (đối diện nam châm) thành cực <b>' + faceN + '</b> ⇒ vòng dây <b>' + (phiInc ? 'đẩy' : 'hút') + '</b> nam châm, chống lại chuyển động.';
    }
    $('lz-say').innerHTML = txt;
  }
  $('lenz-explain').innerHTML = '<h2>Giải thích & câu hỏi khám phá</h2>' + SL.fmtBlock(
    'Từ thông qua vòng dây do nam châm (coi như lưỡng cực từ nằm trên trục) là $\\Phi(x) = \\Phi_{\\max}\\dfrac{a^3}{(a^2 + x^2)^{3/2}}$ — lớn nhất khi nam châm ở tâm vòng. Suất điện động cảm ứng $e = -N\\dfrac{\\Delta\\Phi}{\\Delta t}$ được tính từ chính sự thay đổi Φ giữa các khung hình. Dấu trừ là **định luật Lenz**.'
  ) + qa([
    ['Đưa nam châm lại gần thật chậm rồi thật nhanh. Kim điện kế khác nhau thế nào?', 'Càng nhanh thì $\\Delta\\Phi/\\Delta t$ càng lớn ⇒ $|e|$ càng lớn (định luật Faraday). Đứng yên thì e = 0 dù nam châm ở rất gần.'],
    ['Nam châm (cực N hướng vào vòng) đang lại gần: mặt vòng dây đối diện nam châm là cực gì? Vòng dây hút hay đẩy?', 'Mặt đối diện thành cực N ⇒ đẩy nam châm. Năng lượng điện sinh ra phải trả bằng công bạn đẩy nam châm — đó là lý do định luật Lenz phù hợp với bảo toàn năng lượng.'],
    ['Đảo cực nam châm và lặp lại. Điều gì đổi dấu?', 'Φ đổi dấu nên e và chiều dòng điện đổi dấu; nhưng quy luật "lại gần thì đẩy, ra xa thì hút" vẫn giữ nguyên.'],
    ['Trên đồ thị, e đạt cực đại khi nào: khi Φ lớn nhất hay khi Φ thay đổi nhanh nhất?', 'Khi Φ thay đổi nhanh nhất (đồ thị Φ dốc nhất). Lúc Φ đạt cực đại, nó tạm thời không đổi nên e = 0.']
  ]);

  /* =====================================================================
     4. MÁY PHÁT ĐIỆN XOAY CHIỀU
     ===================================================================== */
  var gen = { t: 0, n: 0.5 };
  ['g-N', 'g-B', 'g-S', 'g-n', 'g-R'].forEach(function (id) { $(id).addEventListener('input', function () { if (id === 'g-n') gen.n = +this.value; genLabels(); }); });
  $('g-50').addEventListener('click', function () { gen.n = 50; genLabels(); SL.toast('n = 50 vòng/s: hình quay được chiếu chậm, số liệu là thật.'); });
  function genParams() { return { N: +$('g-N').value, B: +$('g-B').value, S: +$('g-S').value * 1e-4, n: gen.n, R: +$('g-R').value }; }
  function genLabels() {
    var p = genParams();
    $('g-N-val').textContent = p.N; $('g-B-val').textContent = fx(p.B); $('g-S-val').textContent = $('g-S').value;
    $('g-n-val').textContent = fx(p.n, 1); $('g-R-val').textContent = p.R;
    var g = L.generator(p.N, p.B, p.S, p.n, 0);
    tableRows('g-read', [
      ['ω = 2πn', fx(g.omega, 2) + ' rad/s'],
      ['Tần số f', fx(g.f, 2) + ' Hz'],
      ['Φ₀ = NBS', fx(p.N * p.B * p.S, 4) + ' Wb'],
      ['E₀ = NBSω', fx(g.E0, 3) + ' V'],
      ['E = E₀/√2 (hiệu dụng)', fx(g.E, 3) + ' V'],
      ['I = E/R', fx(g.E / p.R, 4) + ' A'],
      ['Công suất P = I²R', fx(g.E * g.E / p.R, 4) + ' W']
    ]);
    genPlot();
  }
  function genFrame(dt) {
    var visN = gen.n > 3 ? 0.4 : gen.n;   // tốc độ nhìn thấy (chiếu chậm nếu quá nhanh)
    gen.t += dt * visN / gen.n;
    genDraw(); genPlot();
  }
  function genDraw() {
    var cv = $('cv-gen');
    if (!SL.fitCanvas(cv)) return;
    var ctx = cv.getContext('2d'), W = cv.width, H = cv.height, d = cv._dpr, c = colors();
    ctx.clearRect(0, 0, W, H);
    var cx = W / 2, cy = H / 2, s = Math.min(W, H) * 0.3;
    // nam châm
    ctx.fillStyle = '#e5484d'; ctx.fillRect(cx - 2.3 * s, cy - 1.1 * s, 0.6 * s, 2.2 * s);
    ctx.fillStyle = '#3e7bfa'; ctx.fillRect(cx + 1.7 * s, cy - 1.1 * s, 0.6 * s, 2.2 * s);
    ctx.fillStyle = '#fff'; ctx.font = 'bold ' + (20 * d) + 'px system-ui'; ctx.textAlign = 'center';
    ctx.fillText('N', cx - 2 * s, cy + 7 * d); ctx.fillText('S', cx + 2 * s, cy + 7 * d);
    // đường sức
    ctx.strokeStyle = c.border; ctx.lineWidth = 1.2 * d;
    for (var k = -2; k <= 2; k++) {
      var y = cy + k * 0.42 * s;
      ctx.beginPath(); ctx.moveTo(cx - 1.65 * s, y); ctx.lineTo(cx + 1.65 * s, y); ctx.stroke();
      ctx.fillStyle = c.border; ctx.beginPath(); ctx.moveTo(cx + 1.2 * s, y); ctx.lineTo(cx + 1.1 * s, y - 4 * d); ctx.lineTo(cx + 1.1 * s, y + 4 * d); ctx.fill();
    }
    ctx.fillStyle = c.muted; ctx.font = (12 * d) + 'px system-ui'; ctx.fillText('B', cx + 1.45 * s, cy - 2.1 * 0.42 * s);
    // khung dây: pháp tuyến n = (cosθ, 0, sinθ), quay quanh trục thẳng đứng
    var th = 2 * Math.PI * gen.n * gen.t;
    var tx = -Math.sin(th), tz = Math.cos(th), hw = 0.95 * s, hh = 0.85 * s;
    var proj = function (x, y, z) { return [cx + x - 0.45 * z, cy - y + 0.28 * z]; };
    var pts = [[1, 1], [-1, 1], [-1, -1], [1, -1]].map(function (q) { return proj(q[0] * hw * tx, q[1] * hh, q[0] * hw * tz); });
    ctx.fillStyle = 'rgba(94,234,212,0.18)'; ctx.strokeStyle = c.warn; ctx.lineWidth = 4 * d;
    ctx.beginPath(); pts.forEach(function (p, i) { if (i) ctx.lineTo(p[0], p[1]); else ctx.moveTo(p[0], p[1]); }); ctx.closePath(); ctx.fill(); ctx.stroke();
    // trục quay
    ctx.strokeStyle = c.muted; ctx.lineWidth = 2 * d; ctx.setLineDash([5 * d, 4 * d]);
    ctx.beginPath(); ctx.moveTo(cx, cy - 1.25 * s); ctx.lineTo(cx, cy + 1.25 * s); ctx.stroke(); ctx.setLineDash([]);
    // pháp tuyến
    var nEnd = proj(0.9 * s * Math.cos(th), 0, 0.9 * s * Math.sin(th));
    ctx.strokeStyle = c.a2; ctx.lineWidth = 3 * d; ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(nEnd[0], nEnd[1]); ctx.stroke();
    ctx.fillStyle = c.a2; ctx.beginPath(); ctx.arc(nEnd[0], nEnd[1], 5 * d, 0, 7); ctx.fill();
    ctx.fillText('n', nEnd[0] + 10 * d, nEnd[1] - 8 * d);
    var deg = ((th * 180 / Math.PI) % 360 + 360) % 360;
    ctx.fillStyle = c.text; ctx.textAlign = 'left'; ctx.font = (13 * d) + 'px system-ui';
    ctx.fillText('α = (n, B) = ' + Math.round(deg) + '°' + (gen.n > 3 ? '   (chiếu chậm)' : ''), 12 * d, 22 * d);
  }
  function genPlot() {
    var p = genParams(), c = colors(), T = 1 / p.n, t1 = gen.t, t0 = t1 - 2 * T, phi = [], e = [];
    var g0 = L.generator(p.N, p.B, p.S, p.n, 0);
    for (var i = 0; i <= 240; i++) {
      var t = t0 + 2 * T * i / 240, g = L.generator(p.N, p.B, p.S, p.n, t);
      phi.push([t - t1, g.phi / (p.N * p.B * p.S)]); e.push([t - t1, g.e / g0.E0]);
    }
    plot($('cv-gen-plot'), { xMin: -2 * T, xMax: 0, yMin: -1.15, yMax: 1.15, xLabel: 't − t_hiện tại (s)', yLabel: 'chuẩn hóa theo biên độ',
      series: [{ data: phi, color: c.accent }, { data: e, color: c.warn }], hlines: [{ y: 0 }],
      legend: [['Φ / (NBS)', c.accent], ['e / E₀  (E₀ = ' + fx(g0.E0, 2) + ' V)', c.warn]] });
  }
  $('gen-explain').innerHTML = '<h2>Giải thích & câu hỏi khám phá</h2>' + SL.fmtBlock(
    'Khung dây $N$ vòng, diện tích $S$ quay đều quanh trục vuông góc với $\\vec B$. Góc giữa pháp tuyến $\\vec n$ và $\\vec B$ là $\\alpha = \\omega t$, nên\n\n' +
    '$$\\Phi = NBS\\cos\\omega t,\\qquad e = -\\frac{d\\Phi}{dt} = NBS\\omega\\sin\\omega t,\\qquad E_0 = NBS\\omega,\\qquad E = \\frac{E_0}{\\sqrt2}.$$\n\n' +
    'Mô hình bỏ qua điện trở và độ tự cảm của khung dây.'
  ) + qa([
    ['Khi α = 0° (khung vuông góc với đường sức), Φ và e bằng bao nhiêu?', 'Φ cực đại, e = 0 — vì lúc đó Φ tạm thời không thay đổi. Hai đồ thị lệch pha nhau một phần tư chu kì ($\\pi/2$).'],
    ['Tăng gấp đôi tốc độ quay n. E₀, tần số và công suất trên R thay đổi thế nào?', 'E₀ và f cùng tăng gấp đôi; công suất $P = E^2/R$ tăng gấp 4.'],
    ['Với N = 100, B = 0,1 T, S = 400 cm², bấm "n = 50 vòng/s". So E hiệu dụng với bài tu-s4 trong Ôn thi Vật lý 12.', 'E ≈ 88,86 V ⇒ làm tròn 89 V, đúng đáp án câu tu-s4.'],
    ['Để có điện áp hiệu dụng 220 V, 50 Hz với B = 0,5 T, S = 400 cm² cần bao nhiêu vòng?', '$N = \\dfrac{220\\sqrt2}{BS\\omega} = \\dfrac{311{,}1}{0{,}5\\cdot0{,}04\\cdot100\\pi} \\approx 50$ vòng.']
  ]);

  function qa(list) {
    return '<h3 style="margin-top:12px">Câu hỏi khám phá</h3>' + list.map(function (x, i) {
      return '<details><summary>' + (i + 1) + '. ' + SL.fmt(x[0]) + '</summary><p class="ans">' + SL.fmt(x[1]) + '</p></details>';
    }).join('');
  }

  /* ---------------- Vòng lặp ---------------- */
  var last = 0;
  function loop(ts) {
    var dt = last ? Math.min(0.05, (ts - last) / 1000) : 0;
    last = ts;
    if (current === 'gas') gasFrame();
    else if (current === 'decay') dcFrame(dt);
    else if (current === 'lenz') lzFrame(dt);
    else if (current === 'gen') genFrame(dt);
    requestAnimationFrame(loop);
  }
  function redrawStatic() {
    if (current === 'gas') { drawGasPlot(); renderGasTable(); }
    if (current === 'decay') { dcDraw(); dcPlot(); dcRead(); }
    if (current === 'gen') genLabels();
  }
  window.addEventListener('resize', redrawStatic);

  gasReset();
  dcReset();
  ['gas-explain', 'decay-explain', 'lenz-explain', 'gen-explain'].forEach(function (id) { SL.math($(id)); });
  SL.math($('tab-decay'));
  showTab(location.hash.slice(1));
  requestAnimationFrame(loop);

  window.Labs = { gas: gas, dc: dc, lz: lz, gen: gen };
})();
