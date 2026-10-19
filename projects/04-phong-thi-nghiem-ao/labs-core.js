/* ==========================================================================
   Phòng thí nghiệm ảo — lõi mô phỏng (không phụ thuộc giao diện, chạy được trong Node)
   ========================================================================== */
(function (root) {
  'use strict';

  /* Bộ sinh số ngẫu nhiên có hạt giống (để kiểm thử lặp lại được) */
  function rng(seed) {
    var s = (seed >>> 0) || 1;
    return function () {
      s ^= s << 13; s >>>= 0; s ^= s >>> 17; s ^= s << 5; s >>>= 0;
      return s / 4294967296;
    };
  }
  function gauss(rand) {
    var u = 1 - rand(), v = rand();
    return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
  }

  /* =======================================================================
     1. KHÍ LÍ TƯỞNG 2D — các đĩa cứng va chạm đàn hồi trong hộp có pit-tông
     Đơn vị mô phỏng: m = 1, k = 1, chiều cao hộp H = 1.
     Trong 2 chiều: động năng trung bình mỗi phân tử = kT (2 bậc tự do)
     và phương trình trạng thái p·S = N·k·T (S = diện tích, đóng vai trò thể tích).
     ======================================================================= */
  function Gas(opts) {
    opts = opts || {};
    this.rand = rng(opts.seed || 12345);
    this.H = 1;
    this.W = opts.W || 1;                // vị trí pit-tông (thành phải)
    this.r = opts.r || 0.004;            // bán kính phân tử
    this.thermostat = opts.thermostat !== false;
    this.Tset = opts.T || 1;
    this.t = 0;
    this.wallU = 0;                      // vận tốc pit-tông
    this.impulse = 0; this.impT = 0;     // xung lượng truyền cho thành (đo áp suất)
    this.pHist = [];                     // [t, xung lượng] trong cửa sổ trượt
    this.window = opts.window || 2;      // cửa sổ trung bình áp suất (đơn vị thời gian)
    this.setN(opts.N || 200);
  }
  Gas.prototype.setN = function (N) {
    var p = [];
    for (var i = 0; i < N; i++) {
      var s = Math.sqrt(this.Tset);
      p.push({ x: this.r + this.rand() * (this.W - 2 * this.r), y: this.r + this.rand() * (this.H - 2 * this.r),
        vx: gauss(this.rand) * s, vy: gauss(this.rand) * s });
    }
    this.p = p;
    this.pHist = [];
  };
  Gas.prototype.temperature = function () {
    var e = 0;
    for (var i = 0; i < this.p.length; i++) e += 0.5 * (this.p[i].vx * this.p[i].vx + this.p[i].vy * this.p[i].vy);
    return e / this.p.length;                 // 2D: <E> = kT, k = 1
  };
  Gas.prototype.area = function () { return this.W * this.H; };
  Gas.prototype.perimeter = function () { return 2 * (this.W + this.H); };
  Gas.prototype.rescale = function (Tnew) {
    var T = this.temperature();
    if (T <= 0) return;
    var f = Math.sqrt(Tnew / T);
    for (var i = 0; i < this.p.length; i++) { this.p[i].vx *= f; this.p[i].vy *= f; }
  };
  /* Một bước thời gian dt */
  Gas.prototype.step = function (dt) {
    var P = this.p, r = this.r, n = P.length, i, a;
    // pit-tông di chuyển
    this.W = Math.max(0.2, this.W + this.wallU * dt);
    var W = this.W, H = this.H, imp = 0;
    for (i = 0; i < n; i++) {
      a = P[i];
      a.x += a.vx * dt; a.y += a.vy * dt;
      if (a.x < r) { a.x = 2 * r - a.x; imp += 2 * Math.abs(a.vx); a.vx = Math.abs(a.vx); }
      if (a.x > W - r) {
        var rel = a.vx - this.wallU;
        if (rel > 0) { imp += 2 * rel; a.vx = 2 * this.wallU - a.vx; }
        a.x = Math.max(r, 2 * (W - r) - a.x);   // phản xạ vị trí qua thành
      }
      if (a.y < r) { a.y = 2 * r - a.y; imp += 2 * Math.abs(a.vy); a.vy = Math.abs(a.vy); }
      if (a.y > H - r) { a.y = 2 * (H - r) - a.y; imp += 2 * Math.abs(a.vy); a.vy = -Math.abs(a.vy); }
    }
    this.collide();
    if (this.thermostat) {
      // Bộ ổn nhiệt nhẹ (Berendsen): kéo dần nhiệt độ về giá trị đặt
      var T = this.temperature();
      if (T > 0) {
        var f = Math.sqrt(1 + 0.05 * (this.Tset / T - 1));
        for (i = 0; i < n; i++) { P[i].vx *= f; P[i].vy *= f; }
      }
    }
    this.t += dt;
    this.pHist.push([this.t, imp, dt]);
    while (this.pHist.length && this.pHist[0][0] < this.t - this.window) this.pHist.shift();
  };
  /* Va chạm đàn hồi giữa các đĩa cùng khối lượng — lưới ô để tìm cặp gần nhau */
  Gas.prototype.collide = function () {
    var P = this.p, r = this.r, d = 2 * r, cs = Math.max(d, 0.02);
    var cols = Math.ceil(this.W / cs) + 2, grid = {};
    var i, j, k;
    for (i = 0; i < P.length; i++) {
      var cx = Math.floor(P[i].x / cs), cy = Math.floor(P[i].y / cs), key = cx + cy * cols;
      (grid[key] || (grid[key] = [])).push(i);
    }
    for (i = 0; i < P.length; i++) {
      var a = P[i], ax = Math.floor(a.x / cs), ay = Math.floor(a.y / cs);
      for (var ox = -1; ox <= 1; ox++) for (var oy = -1; oy <= 1; oy++) {
        var cell = grid[(ax + ox) + (ay + oy) * cols];
        if (!cell) continue;
        for (k = 0; k < cell.length; k++) {
          j = cell[k];
          if (j <= i) continue;
          var b = P[j], dx = b.x - a.x, dy = b.y - a.y, dist2 = dx * dx + dy * dy;
          if (dist2 >= d * d || dist2 === 0) continue;
          var dist = Math.sqrt(dist2), nx = dx / dist, ny = dy / dist;
          var dvn = (a.vx - b.vx) * nx + (a.vy - b.vy) * ny;
          if (dvn <= 0) continue;              // đang tách ra
          a.vx -= dvn * nx; a.vy -= dvn * ny;
          b.vx += dvn * nx; b.vy += dvn * ny;
          var push = (d - dist) / 2;          // tách chồng lấn
          a.x -= nx * push; a.y -= ny * push; b.x += nx * push; b.y += ny * push;
        }
      }
    }
  };
  /* Áp suất đo được = tổng xung lượng lên thành / (thời gian · chu vi) */
  Gas.prototype.pressure = function () {
    var J = 0, T = 0;
    for (var i = 0; i < this.pHist.length; i++) { J += this.pHist[i][1]; T += this.pHist[i][2]; }
    return T > 0 ? J / (T * this.perimeter()) : 0;
  };
  Gas.prototype.pressureTheory = function (T) {
    return this.p.length * (T == null ? this.temperature() : T) / this.area();
  };
  /* Phân bố tốc độ 2D Maxwell–Boltzmann: f(v) = (m v / kT) e^{-m v² / 2kT} */
  function maxwell2D(v, T) { return (v / T) * Math.exp(-v * v / (2 * T)); }

  /* =======================================================================
     2. PHÂN RÃ PHÓNG XẠ — mỗi hạt nhân phân rã ngẫu nhiên, độc lập
     ======================================================================= */
  function Decay(N0, halfLife, seed) {
    this.rand = rng(seed || 777);
    this.N0 = N0; this.T = halfLife; this.t = 0;
    this.alive = new Uint8Array(N0).fill(1);
    this.decayTime = new Float64Array(N0).fill(-1);
    this.N = N0;
    this.history = [[0, N0]];
  }
  Decay.prototype.step = function (dt) {
    var pDecay = 1 - Math.pow(2, -dt / this.T), count = 0;
    for (var i = 0; i < this.N0; i++) {
      if (this.alive[i] && this.rand() < pDecay) { this.alive[i] = 0; this.decayTime[i] = this.t + dt; count++; }
    }
    this.N -= count; this.t += dt;
    this.history.push([this.t, this.N]);
    return count;
  };
  Decay.prototype.theory = function (t) { return this.N0 * Math.pow(2, -t / this.T); };

  /* =======================================================================
     3. CẢM ỨNG ĐIỆN TỪ
     ======================================================================= */
  /* Từ thông qua vòng dây bán kính a do lưỡng cực từ nằm trên trục, cách tâm vòng x.
     Φ(x) = Φmax · a³ / (a² + x²)^{3/2}   (chuẩn hóa: Φ(0) = Φmax) */
  function dipoleFlux(x, a, phiMax) {
    return phiMax * Math.pow(a, 3) / Math.pow(a * a + x * x, 1.5);
  }
  /* Máy phát: khung N vòng, diện tích S, cảm ứng từ B, quay n vòng/s */
  function generator(N, B, S, n, t) {
    var w = 2 * Math.PI * n;
    return { omega: w, f: n, E0: N * B * S * w, E: N * B * S * w / Math.SQRT2,
      phi: N * B * S * Math.cos(w * t), e: N * B * S * w * Math.sin(w * t) };
  }

  var api = { rng: rng, gauss: gauss, Gas: Gas, maxwell2D: maxwell2D, Decay: Decay, dipoleFlux: dipoleFlux, generator: generator };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.LabsCore = api;
})(this);
