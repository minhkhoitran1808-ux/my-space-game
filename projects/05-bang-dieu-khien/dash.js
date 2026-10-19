/* ==========================================================================
   Bảng điều khiển ôn thi — mọi dữ liệu nằm trong localStorage['sl.dash.v1'].
   Đọc thêm (chỉ đọc) tiến độ các bộ ôn thi: localStorage['sl.quiz.<bank>.v1'].
   ========================================================================== */
(function () {
  'use strict';
  var SL = window.SL, esc = SL.esc;
  var KEY = 'sl.dash.v1', RUN_KEY = 'sl.dash.pomo-run';
  var $app = document.getElementById('app');
  var DAY = SL.DAY;
  var WEEKDAYS = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
  var ERROR_TYPES = ['Hiểu sai khái niệm', 'Quên / nhầm công thức', 'Tính toán sai', 'Đọc sai đề', 'Sai đơn vị / đổi đơn vị', 'Thiếu trường hợp', 'Hết thời gian', 'Khác'];
  var REVIEW_DAYS = [1, 3, 7, 14, 30];
  var BANK_INFO = {
    vatly12: { name: 'Ôn thi Vật lý 12', href: '../01-on-thi-vat-ly-12/index.html' },
    toan12: { name: 'Ôn thi Toán 12', href: '../06-on-thi-toan-vact/index.html' },
    vact: { name: 'Tư duy V-ACT', href: '../06-on-thi-toan-vact/index.html' }
  };
  SL.initThemeToggle(document.getElementById('theme-btn'));

  /* ---------------- Dữ liệu ---------------- */
  var uid = function () { return Date.now().toString(36) + Math.random().toString(36).slice(2, 7); };
  function defaults() {
    var t = function (text, subject, min) { return { id: uid(), text: text, subject: subject, min: min }; };
    return {
      v: 1,
      exams: [
        { id: uid(), name: 'Thi tốt nghiệp THPT 2027', date: '2027-06-10', note: 'Ngày giả định — cần xác minh khi Bộ GD&ĐT công bố lịch thi chính thức.' },
        { id: uid(), name: 'V-ACT (ĐGNL ĐHQG-HCM) 2027 · đợt 1', date: '2027-04-04', note: 'Ngày giả định — cần xác minh trên trang của ĐHQG-HCM.' }
      ],
      subjects: ['Toán', 'Vật lý', 'Hóa học', 'Tiếng Anh', 'Ngữ văn', 'V-ACT', 'Tiếng Đức', 'Lập trình'],
      plan: {
        template: {
          0: [t('Vật lý 12: luyện 20 câu chương đang học', 'Vật lý', 45), t('Toán: 1 đề trắc nghiệm', 'Toán', 60)],
          1: [t('Toán: chuyên đề yếu nhất', 'Toán', 60), t('Tiếng Anh: đọc hiểu 2 bài', 'Tiếng Anh', 30)],
          2: [t('Vật lý: thí nghiệm ảo + sổ tay công thức', 'Vật lý', 40), t('V-ACT: tư duy khoa học', 'V-ACT', 45)],
          3: [t('Toán: luyện tập', 'Toán', 60), t('Tiếng Anh: từ vựng', 'Tiếng Anh', 30)],
          4: [t('Vật lý: 1 đề thi thử 50 phút', 'Vật lý', 50), t('Ôn sổ lỗi sai', 'Vật lý', 30)],
          5: [t('V-ACT: 1 đề', 'V-ACT', 90), t('Tiếng Đức A1: 1 bài', 'Tiếng Đức', 30)],
          6: [t('Ôn các câu đến hạn + nghỉ ngơi', 'Vật lý', 30)]
        },
        done: {}
      },
      log: [],
      mistakes: [],
      pomo: { work: 25, brk: 5 },
      sample: true
    };
  }
  var data = SL.store.get(KEY, null);
  if (!data || data.v !== 1) data = defaults();
  function save() { SL.store.set(KEY, data); }
  save();

  /* ---------------- Ngày tháng ---------------- */
  function ymd(d) { return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0'); }
  function parseYmd(s) { var p = s.split('-'); return new Date(+p[0], +p[1] - 1, +p[2]); }
  function weekdayIdx(d) { return (d.getDay() + 6) % 7; }       // Thứ 2 = 0
  function startOfWeek(d) { var x = new Date(d.getFullYear(), d.getMonth(), d.getDate()); x.setDate(x.getDate() - weekdayIdx(x)); return x; }
  function addDays(d, n) { var x = new Date(d); x.setDate(x.getDate() + n); return x; }
  function daysUntil(s) { var a = parseYmd(SL.today()), b = parseYmd(s); return Math.round((b - a) / DAY); }
  function fmtDate(s) { var d = parseYmd(s); return String(d.getDate()).padStart(2, '0') + '/' + String(d.getMonth() + 1).padStart(2, '0') + '/' + d.getFullYear(); }
  function hm(min) { min = Math.round(min); return min >= 60 ? Math.floor(min / 60) + ' h ' + String(min % 60).padStart(2, '0') + "'" : min + "'"; }

  /* ---------------- Định tuyến ---------------- */
  var TABS = ['home', 'plan', 'focus', 'mistakes', 'data'];
  function route() {
    var tab = location.hash.slice(1).split('/')[0];
    if (TABS.indexOf(tab) < 0) tab = 'home';
    document.querySelectorAll('.nav a[data-tab]').forEach(function (a) { a.classList.toggle('active', a.getAttribute('data-tab') === tab); });
    ({ home: viewHome, plan: viewPlan, focus: viewFocus, mistakes: viewMistakes, data: viewData })[tab]();
  }
  window.addEventListener('hashchange', route);

  /* ===================== TỔNG QUAN ===================== */
  function viewHome() {
    var today = new Date(), wi = weekdayIdx(today), key = SL.today();
    var tasks = data.plan.template[wi] || [], done = data.plan.done[key] || [];
    var wk = weekMinutes(startOfWeek(today));
    var dueMistakes = mistakesDue().length;
    var h = '<section class="stack">';
    h += '<div class="row"><h1 style="margin:0">Chào bạn 👋</h1><span class="spacer"></span><span class="muted">' + WEEKDAYS[wi] + ', ' + fmtDate(key) + '</span></div>';
    if (data.sample) h += '<div class="callout small">Đây là <b>kế hoạch & ngày thi mẫu</b>. Sửa ở tab <a href="#plan">Kế hoạch tuần</a> và mục ngày thi bên dưới cho đúng với bạn. <button class="btn sm ghost" data-act="dismiss-sample">Đã hiểu</button></div>';

    // Đếm ngược
    h += '<div class="grid grid-2">' + data.exams.slice().sort(function (a, b) { return a.date < b.date ? -1 : 1; }).map(function (e) {
      var n = daysUntil(e.date);
      return '<div class="card countdown"><div class="row"><b>' + esc(e.name) + '</b><span class="spacer"></span><button class="btn sm ghost" data-act="edit-exam" data-id="' + e.id + '" title="Sửa">✎</button></div>' +
        '<div class="big">' + (n >= 0 ? n : 0) + '<span> ngày</span></div>' +
        '<div class="muted small">' + fmtDate(e.date) + (n >= 0 ? ' · còn khoảng ' + Math.floor(n / 7) + ' tuần' : ' · đã qua') + '</div>' +
        (e.note ? '<div class="small warn-text">' + esc(e.note) + '</div>' : '') + '</div>';
    }).join('') + '</div>';
    h += '<div><button class="btn sm" data-act="add-exam">+ Thêm kỳ thi</button></div>';

    // Hôm nay + số liệu
    h += '<div class="grid grid-2">';
    h += '<div class="card"><div class="row"><h3 style="margin:0">Việc hôm nay</h3><span class="spacer"></span><a class="small" href="#plan">Sửa kế hoạch</a></div>' +
      (tasks.length ? '<ul class="tasks">' + tasks.map(function (t) {
        var on = done.indexOf(t.id) >= 0;
        return '<li class="' + (on ? 'done' : '') + '"><label><input type="checkbox" data-act="toggle-task" data-id="' + t.id + '"' + (on ? ' checked' : '') + '> ' +
          esc(t.text) + ' <span class="badge">' + esc(t.subject) + ' · ' + t.min + "'</span></label></li>";
      }).join('') + '</ul>' : '<p class="muted">Hôm nay không có việc theo kế hoạch.</p>') +
      '<div class="bar" style="margin-top:8px"><i style="width:' + (tasks.length ? 100 * done.filter(function (id) { return tasks.some(function (t) { return t.id === id; }); }).length / tasks.length : 0) + '%"></i></div></div>';
    h += '<div class="card stack"><h3 style="margin:0">Tuần này</h3><div class="grid grid-3">' +
      '<div class="stat"><b>' + hm(wk.total) + '</b><span>đã học</span></div>' +
      '<div class="stat"><b>' + weekPlanPct() + '%</b><span>kế hoạch hoàn thành</span></div>' +
      '<div class="stat"><b>' + dueMistakes + '</b><span>lỗi sai cần ôn</span></div></div>' +
      daysChart(14) +
      '<div class="row"><a class="btn sm primary" href="#focus">▶ Bắt đầu Pomodoro</a>' + (dueMistakes ? '<a class="btn sm" href="#mistakes">Ôn ' + dueMistakes + ' lỗi sai</a>' : '') + '</div></div>';
    h += '</div>';

    // Thống kê từ ứng dụng ôn thi
    h += '<div class="card"><h3>Tiến độ trong các bộ ôn thi</h3>' + quizStats() + '</div>';
    h += '</section>';
    $app.innerHTML = h;
  }
  function quizStats() {
    var keys = SL.store.keys('sl.quiz.').filter(function (k) { return /^sl\.quiz\.[^.]+\.v1$/.test(k); });
    var rows = keys.map(function (k) {
      var id = k.split('.')[2], d = SL.store.get(k, null);
      if (!d || !d.q) return '';
      var recs = Object.keys(d.q).map(function (q) { return d.q[q]; });
      var seen = recs.filter(function (r) { return r.seen; }).length;
      var right = recs.reduce(function (a, r) { return a + (r.right || 0); }, 0), wrong = recs.reduce(function (a, r) { return a + (r.wrong || 0); }, 0);
      var wb = recs.filter(function (r) { return r.wb; }).length, due = recs.filter(function (r) { return r.seen && r.due <= Date.now(); }).length;
      var last = d.exams && d.exams.length ? d.exams[d.exams.length - 1] : null;
      var info = BANK_INFO[id] || { name: id, href: '#' };
      return '<tr><td><a href="' + info.href + '">' + esc(info.name) + '</a></td><td>' + seen + '</td><td>' + (right + wrong ? Math.round(100 * right / (right + wrong)) + '%' : '—') +
        '</td><td>' + due + '</td><td>' + wb + '</td><td>' + (last ? SL.num(last.total, 2) + '/' + last.max + ' <span class="muted small">(' + SL.dateVN(last.t) + ')</span>' : '—') + '</td></tr>';
    }).join('');
    if (!rows) return '<p class="muted small" style="margin:0">Chưa có dữ liệu. Làm bài ở <a href="../01-on-thi-vat-ly-12/index.html">Ôn thi Vật lý 12</a> hoặc <a href="../06-on-thi-toan-vact/index.html">Toán & V-ACT</a> — số liệu sẽ tự hiện ở đây (khi mở cùng một trình duyệt, cùng cách mở file/web).</p>';
    return '<div class="table-wrap"><table class="table"><tr><th>Bộ ôn</th><th>Câu đã làm</th><th>Tỉ lệ đúng</th><th>Đến hạn ôn</th><th>Trong sổ sai</th><th>Thi thử gần nhất</th></tr>' + rows + '</table></div>';
  }
  function weekMinutes(start) {
    var total = 0, bySub = {};
    data.log.forEach(function (e) {
      var d = parseYmd(e.date);
      if (d >= start && d < addDays(start, 7)) { total += e.min; bySub[e.subject] = (bySub[e.subject] || 0) + e.min; }
    });
    return { total: total, bySub: bySub };
  }
  function weekPlanPct() {
    var start = startOfWeek(new Date()), total = 0, done = 0;
    for (var i = 0; i < 7; i++) {
      var day = addDays(start, i), key = ymd(day), tasks = data.plan.template[i] || [];
      if (day > new Date()) break;
      total += tasks.length;
      done += (data.plan.done[key] || []).filter(function (id) { return tasks.some(function (t) { return t.id === id; }); }).length;
    }
    return total ? Math.round(100 * done / total) : 0;
  }
  var SUB_COLORS = ['#5eead4', '#a78bfa', '#fbbf24', '#60a5fa', '#f472b6', '#4ade80', '#fb923c', '#94a3b8'];
  function subColor(s) { var i = data.subjects.indexOf(s); return SUB_COLORS[(i < 0 ? data.subjects.length : i) % SUB_COLORS.length]; }
  function daysChart(n) {
    var today = parseYmd(SL.today()), days = [], max = 30;
    for (var i = n - 1; i >= 0; i--) {
      var d = addDays(today, -i), key = ymd(d), by = {};
      data.log.forEach(function (e) { if (e.date === key) by[e.subject] = (by[e.subject] || 0) + e.min; });
      var tot = Object.keys(by).reduce(function (a, k) { return a + by[k]; }, 0);
      max = Math.max(max, tot);
      days.push({ d: d, by: by, tot: tot });
    }
    var used = {};
    var h = '<div class="days" role="img" aria-label="Số phút học ' + n + ' ngày gần nhất">' + days.map(function (x) {
      return '<div class="day" title="' + x.d.getDate() + '/' + (x.d.getMonth() + 1) + ': ' + hm(x.tot) + '"><div class="col">' + Object.keys(x.by).map(function (s) {
        used[s] = 1;
        return '<i style="height:' + (100 * x.by[s] / max).toFixed(1) + '%;background:' + subColor(s) + '"></i>';
      }).join('') + '</div><span>' + x.d.getDate() + '</span></div>';
    }).join('') + '</div>';
    h += '<div class="legend">' + (Object.keys(used).length ? Object.keys(used).map(function (s) { return '<span><i style="background:' + subColor(s) + '"></i>' + esc(s) + '</span>'; }).join('') : '<span>Chưa có giờ học nào được ghi — dùng Pomodoro hoặc thêm tay.</span>') + '</div>';
    return h;
  }

  /* ===================== KẾ HOẠCH TUẦN ===================== */
  var planOffset = 0;
  function viewPlan() {
    var start = addDays(startOfWeek(new Date()), planOffset * 7);
    var h = '<section class="stack"><div class="row"><h1 style="margin:0">Kế hoạch tuần</h1><span class="spacer"></span>' +
      '<button class="btn sm" data-act="week" data-d="-1">← Tuần trước</button><b>' + fmtDate(ymd(start)) + ' – ' + fmtDate(ymd(addDays(start, 6))) + '</b>' +
      '<button class="btn sm" data-act="week" data-d="1">Tuần sau →</button></div>' +
      '<p class="muted small" style="margin:0">Kế hoạch lặp lại hằng tuần (mẫu theo thứ). Đánh dấu hoàn thành cho từng ngày cụ thể. Tổng thời gian dự kiến: <b>' + hm(planTotal()) + '</b>/tuần.</p>';
    h += '<div class="week">';
    for (var i = 0; i < 7; i++) {
      var day = addDays(start, i), key = ymd(day), tasks = data.plan.template[i] || [], done = data.plan.done[key] || [];
      var isToday = key === SL.today();
      h += '<div class="card day-col' + (isToday ? ' today' : '') + '"><div class="row"><b>' + WEEKDAYS[i] + '</b><span class="muted small">' + day.getDate() + '/' + (day.getMonth() + 1) + '</span></div><ul class="tasks">';
      tasks.forEach(function (t) {
        var on = done.indexOf(t.id) >= 0;
        h += '<li class="' + (on ? 'done' : '') + '"><label><input type="checkbox" data-act="toggle-task" data-id="' + t.id + '" data-date="' + key + '"' + (on ? ' checked' : '') + '> ' + esc(t.text) +
          '</label><span class="row" style="gap:4px"><span class="badge" style="border-color:' + subColor(t.subject) + '">' + esc(t.subject) + ' · ' + t.min + "'</span>" +
          '<button class="btn sm ghost" data-act="del-task" data-day="' + i + '" data-id="' + t.id + '" title="Xóa">✕</button></span></li>';
      });
      h += '</ul><form class="add-task" data-day="' + i + '"><input type="text" name="text" placeholder="Thêm việc…" required>' +
        '<div class="row"><select name="subject">' + data.subjects.map(function (s) { return '<option>' + esc(s) + '</option>'; }).join('') + '</select>' +
        '<input type="number" name="min" value="30" min="5" step="5" style="width:5em" aria-label="Số phút"><button class="btn sm">+</button></div></form></div>';
    }
    h += '</div>';
    h += '<div class="card small"><b>Môn học:</b> ' + data.subjects.map(function (s) { return '<span class="badge" style="border-color:' + subColor(s) + '">' + esc(s) + '</span>'; }).join(' ') +
      ' <form id="add-subject" class="row" style="display:inline-flex;margin-left:8px"><input type="text" name="s" placeholder="Môn mới" required style="width:9em"><button class="btn sm">Thêm môn</button></form></div>';
    h += '</section>';
    $app.innerHTML = h;
  }
  function planTotal() {
    var t = 0;
    for (var i = 0; i < 7; i++) (data.plan.template[i] || []).forEach(function (x) { t += x.min; });
    return t;
  }

  /* ===================== POMODORO & NHẬT KÝ ===================== */
  var tick = null;
  function viewFocus() {
    var run = SL.store.get(RUN_KEY, null);
    var h = '<section class="stack"><h1 style="margin:0">Pomodoro & nhật ký giờ học</h1><div class="grid grid-2">';
    h += '<div class="card stack center pomo"><div class="row" style="justify-content:center">' +
      '<label class="field"><span>Môn</span><select id="pm-sub">' + data.subjects.map(function (s) { return '<option' + (run && run.subject === s ? ' selected' : '') + '>' + esc(s) + '</option>'; }).join('') + '</select></label>' +
      '<label class="field"><span>Học (phút)</span><input type="number" id="pm-work" value="' + data.pomo.work + '" min="5" max="120" style="width:5em"></label>' +
      '<label class="field"><span>Nghỉ (phút)</span><input type="number" id="pm-brk" value="' + data.pomo.brk + '" min="1" max="30" style="width:5em"></label></div>' +
      '<div class="clock" id="pm-clock">' + SL.mmss(data.pomo.work * 60) + '</div><div class="muted" id="pm-mode">Sẵn sàng</div>' +
      '<div class="row" style="justify-content:center"><button class="btn primary" data-act="pm-start" id="pm-start">▶ Bắt đầu học</button><button class="btn" data-act="pm-stop">■ Dừng</button></div>' +
      '<p class="small muted" style="margin:0">Hết phiên học, thời gian được ghi tự động vào nhật ký. Dừng giữa chừng sẽ ghi số phút đã học (nếu ≥ 5 phút).</p></div>';
    var wk = weekMinutes(startOfWeek(new Date()));
    h += '<div class="card stack"><h3 style="margin:0">Tuần này: ' + hm(wk.total) + '</h3>' +
      Object.keys(wk.bySub).sort(function (a, b) { return wk.bySub[b] - wk.bySub[a]; }).map(function (s) {
        return '<div><div class="row small"><span>' + esc(s) + '</span><span class="spacer"></span><b>' + hm(wk.bySub[s]) + '</b></div><div class="bar"><i style="width:' + (100 * wk.bySub[s] / wk.total) + '%;background:' + subColor(s) + '"></i></div></div>';
      }).join('') + daysChart(14) + '</div>';
    h += '</div>';
    h += '<div class="card"><h3>Thêm giờ học thủ công</h3><form id="add-log" class="row">' +
      '<label class="field"><span>Ngày</span><input type="date" name="date" value="' + SL.today() + '" required></label>' +
      '<label class="field"><span>Môn</span><select name="subject">' + data.subjects.map(function (s) { return '<option>' + esc(s) + '</option>'; }).join('') + '</select></label>' +
      '<label class="field"><span>Số phút</span><input type="number" name="min" value="45" min="1" max="600" required style="width:6em"></label>' +
      '<label class="field" style="flex:1;min-width:160px"><span>Ghi chú</span><input type="text" name="note" placeholder="vd: chương Hạt nhân, 20 câu"></label>' +
      '<button class="btn primary">Thêm</button></form></div>';
    h += '<div class="card"><h3>Nhật ký gần đây</h3>' + (data.log.length ? '<div class="table-wrap"><table class="table"><tr><th>Ngày</th><th>Môn</th><th>Thời gian</th><th>Ghi chú</th><th></th></tr>' +
      data.log.slice().sort(function (a, b) { return a.date < b.date ? 1 : a.date > b.date ? -1 : (b.t || 0) - (a.t || 0); }).slice(0, 30).map(function (e) {
        return '<tr><td>' + fmtDate(e.date) + '</td><td>' + esc(e.subject) + '</td><td>' + hm(e.min) + '</td><td>' + esc(e.note || '') + (e.src === 'pomodoro' ? ' <span class="badge accent">pomodoro</span>' : '') +
          '</td><td><button class="btn sm ghost" data-act="del-log" data-id="' + e.id + '">✕</button></td></tr>';
      }).join('') + '</table></div>' : '<p class="muted">Chưa có mục nào.</p>') + '</div>';
    h += '</section>';
    $app.innerHTML = h;
    startTick();
  }
  function startTick() {
    clearInterval(tick);
    var paint = function () {
      var run = SL.store.get(RUN_KEY, null), clock = document.getElementById('pm-clock');
      if (!run) { document.title = 'Bảng điều khiển ôn thi'; return; }
      var rem = run.dur * 60 - (Date.now() - run.start) / 1000;
      if (rem <= 0) { finishPhase(run); return; }
      document.title = SL.mmss(rem) + ' · ' + (run.mode === 'work' ? 'Học' : 'Nghỉ');
      if (clock) {
        clock.textContent = SL.mmss(rem);
        document.getElementById('pm-mode').textContent = run.mode === 'work' ? 'Đang học: ' + run.subject : 'Đang nghỉ giải lao';
        clock.classList.toggle('break', run.mode !== 'work');
        var b = document.getElementById('pm-start'); if (b) b.disabled = true;
      }
    };
    paint();
    tick = setInterval(paint, 500);
  }
  function finishPhase(run) {
    beep();
    if (run.mode === 'work') {
      addLog({ date: ymd(new Date(run.start)), subject: run.subject, min: run.dur, note: 'Pomodoro', src: 'pomodoro' });
      SL.store.set(RUN_KEY, { mode: 'break', start: Date.now(), dur: data.pomo.brk, subject: run.subject });
      SL.toast('Xong một phiên học! Nghỉ ' + data.pomo.brk + ' phút nhé.', 4000);
    } else {
      SL.store.remove(RUN_KEY);
      SL.toast('Hết giờ nghỉ. Sẵn sàng phiên tiếp theo.', 4000);
    }
    if ((location.hash || '#home').indexOf('#focus') === 0) viewFocus();
  }
  function beep() {
    try {
      var ac = new (window.AudioContext || window.webkitAudioContext)();
      [0, 0.25, 0.5].forEach(function (t) {
        var o = ac.createOscillator(), g = ac.createGain();
        o.frequency.value = 880; o.connect(g); g.connect(ac.destination);
        g.gain.setValueAtTime(0.15, ac.currentTime + t); g.gain.exponentialRampToValueAtTime(0.001, ac.currentTime + t + 0.2);
        o.start(ac.currentTime + t); o.stop(ac.currentTime + t + 0.22);
      });
    } catch (e) { /* không có âm thanh cũng không sao */ }
  }
  function addLog(e) {
    e.id = uid(); e.t = Date.now();
    data.log.push(e); save();
  }

  /* ===================== SỔ LỖI SAI ===================== */
  var mFilter = { subject: '', type: '', status: 'active' };
  function mistakesDue() {
    var now = Date.now();
    return data.mistakes.filter(function (m) { return !m.mastered && m.due <= now; });
  }
  function viewMistakes() {
    var due = mistakesDue();
    var h = '<section class="stack"><div class="row"><h1 style="margin:0">Sổ lỗi sai</h1><span class="spacer"></span>' +
      (due.length ? '<button class="btn primary" data-act="review">Ôn ' + due.length + ' lỗi đến hạn</button>' : '<span class="muted small">Không có lỗi nào đến hạn ôn.</span>') + '</div>' +
      '<p class="muted small" style="margin:0">Ghi lại <b>vì sao sai</b> và <b>cách đúng</b>. Mỗi lỗi được nhắc ôn lại sau 1 → 3 → 7 → 14 → 30 ngày; trả lời "Nhớ rồi" đủ 5 lần là thành thạo. Câu sai trong các bộ ôn thi được theo dõi riêng ở mục "Sổ câu sai" của từng bộ.</p>';
    h += '<details class="card" ' + (data.mistakes.length ? '' : 'open') + '><summary><b>+ Ghi lỗi sai mới</b></summary><form id="add-mistake" class="stack" style="margin-top:10px">' +
      '<div class="row"><label class="field"><span>Môn</span><select name="subject">' + data.subjects.map(function (s) { return '<option>' + esc(s) + '</option>'; }).join('') + '</select></label>' +
      '<label class="field" style="flex:1;min-width:160px"><span>Chủ đề / bài</span><input type="text" name="topic" placeholder="vd: Từ thông — góc α" required></label>' +
      '<label class="field"><span>Loại lỗi</span><select name="type">' + ERROR_TYPES.map(function (t) { return '<option>' + t + '</option>'; }).join('') + '</select></label>' +
      '<label class="field"><span>Nguồn</span><input type="text" name="source" placeholder="vd: đề thi thử số 3, câu 12"></label></div>' +
      '<label class="field"><span>Mình đã làm sai thế nào?</span><textarea name="wrong" required placeholder="vd: Dùng cos 30° vì nhầm góc với mặt phẳng khung"></textarea></label>' +
      '<label class="field"><span>Cách làm đúng</span><textarea name="right" required placeholder="vd: α là góc giữa B và PHÁP TUYẾN: α = 90° − 30° = 60°"></textarea></label>' +
      '<label class="field"><span>Mẹo nhớ / dấu hiệu nhận biết lần sau</span><input type="text" name="tip" placeholder="vd: Thấy chữ &quot;mặt phẳng khung&quot; → đổi sang góc với pháp tuyến"></label>' +
      '<div><button class="btn primary">Lưu lỗi sai</button></div></form></details>';
    // thống kê theo loại lỗi
    var active = data.mistakes.filter(function (m) { return !m.mastered; });
    if (data.mistakes.length) {
      var byType = {};
      data.mistakes.forEach(function (m) { byType[m.type] = (byType[m.type] || 0) + 1; });
      var maxT = Math.max.apply(null, Object.keys(byType).map(function (k) { return byType[k]; }));
      h += '<div class="card"><h3>Mình hay sai kiểu gì?</h3>' + Object.keys(byType).sort(function (a, b) { return byType[b] - byType[a]; }).map(function (k) {
        return '<div class="row small" style="margin:4px 0"><span style="width:12em">' + esc(k) + '</span><div class="bar" style="flex:1"><i style="width:' + (100 * byType[k] / maxT) + '%"></i></div><b style="width:2em;text-align:right">' + byType[k] + '</b></div>';
      }).join('') + '<p class="small muted" style="margin:6px 0 0">Đang theo dõi ' + active.length + ' lỗi · đã thành thạo ' + (data.mistakes.length - active.length) + '.</p></div>';
    }
    h += '<div class="card row">' +
      '<label class="field"><span>Môn</span><select id="mf-subject"><option value="">Tất cả</option>' + data.subjects.map(function (s) { return '<option' + (mFilter.subject === s ? ' selected' : '') + '>' + esc(s) + '</option>'; }).join('') + '</select></label>' +
      '<label class="field"><span>Loại lỗi</span><select id="mf-type"><option value="">Tất cả</option>' + ERROR_TYPES.map(function (s) { return '<option' + (mFilter.type === s ? ' selected' : '') + '>' + s + '</option>'; }).join('') + '</select></label>' +
      '<label class="field"><span>Trạng thái</span><select id="mf-status"><option value="active"' + (mFilter.status === 'active' ? ' selected' : '') + '>Đang theo dõi</option><option value="mastered"' + (mFilter.status === 'mastered' ? ' selected' : '') + '>Đã thành thạo</option><option value=""' + (mFilter.status === '' ? ' selected' : '') + '>Tất cả</option></select></label></div>';
    var list = data.mistakes.filter(function (m) {
      return (!mFilter.subject || m.subject === mFilter.subject) && (!mFilter.type || m.type === mFilter.type) &&
        (mFilter.status === '' || (mFilter.status === 'mastered') === !!m.mastered);
    }).sort(function (a, b) { return a.due - b.due; });
    h += list.length ? '<div class="stack">' + list.map(mistakeCard).join('') + '</div>' : '<div class="card empty muted center">Không có lỗi nào phù hợp.</div>';
    h += '</section>';
    $app.innerHTML = h;
  }
  function mistakeCard(m, reviewMode) {
    var due = !m.mastered && m.due <= Date.now();
    return '<article class="card mistake"><div class="row"><span class="badge accent">' + esc(m.subject) + '</span><b>' + esc(m.topic) + '</b><span class="badge">' + esc(m.type) + '</span>' +
      '<span class="spacer"></span>' + (m.mastered ? '<span class="badge ok">thành thạo</span>' : due ? '<span class="badge warn">đến hạn ôn</span>' : '<span class="muted small">ôn lại ' + SL.dateVN(m.due) + '</span>') + '</div>' +
      '<p class="small" style="margin:8px 0 0"><b>Sai:</b> ' + esc(m.wrong) + '</p>' +
      (reviewMode ? '<details style="margin-top:6px"><summary>Hiện cách đúng</summary>' : '') +
      '<p class="small" style="margin:6px 0 0"><b>Đúng:</b> ' + esc(m.right) + '</p>' + (m.tip ? '<p class="small" style="margin:6px 0 0">💡 ' + esc(m.tip) + '</p>' : '') +
      (reviewMode ? '</details>' : '') +
      '<div class="row small muted" style="margin-top:8px">' + (m.source ? 'Nguồn: ' + esc(m.source) + ' · ' : '') + 'ghi ngày ' + SL.dateVN(m.created) + ' · đã ôn ' + (m.stage || 0) + '/5' +
      '<span class="spacer"></span>' + (reviewMode ? '' : '<button class="btn sm ghost danger" data-act="del-mistake" data-id="' + m.id + '">Xóa</button>') + '</div></article>';
  }
  var reviewQueue = null;
  function viewReview() {
    if (!reviewQueue || !reviewQueue.length) { reviewQueue = null; SL.toast('Đã ôn xong các lỗi đến hạn 🎉'); viewMistakes(); return; }
    var m = reviewQueue[0];
    $app.innerHTML = '<section class="stack"><div class="row"><h1 style="margin:0">Ôn lỗi sai</h1><span class="spacer"></span><span class="muted">còn ' + reviewQueue.length + '</span></div>' +
      '<p class="muted small" style="margin:0">Đọc lỗi, <b>tự nhắc lại cách đúng trong đầu</b>, rồi mở ra đối chiếu.</p>' + mistakeCard(m, true) +
      '<div class="row"><button class="btn primary" data-act="rv-ok">✓ Nhớ rồi</button><button class="btn" data-act="rv-fail">✗ Vẫn quên</button><button class="btn ghost" data-act="rv-end">Dừng</button></div></section>';
  }
  function reviewAnswer(ok) {
    var m = reviewQueue.shift();
    if (ok) {
      m.stage = (m.stage || 0) + 1;
      if (m.stage >= REVIEW_DAYS.length) { m.mastered = true; m.due = Infinity; SL.toast('Lỗi này đã thành thạo!'); }
      else m.due = Date.now() + REVIEW_DAYS[m.stage] * DAY;
    } else { m.stage = 0; m.due = Date.now() + DAY; }
    save();
    viewReview();
  }

  /* ===================== DỮ LIỆU ===================== */
  function viewData() {
    var h = '<section class="stack"><h1 style="margin:0">Dữ liệu & sao lưu</h1>';
    h += '<div class="card stack"><p style="margin:0">Mọi thứ lưu <b>trong trình duyệt này</b> (localStorage) — không gửi đi đâu. Hãy xuất tệp sao lưu định kỳ.</p>' +
      '<div class="row"><button class="btn primary" data-act="export">Xuất tệp (.json)</button><label class="btn">Nhập từ tệp…<input type="file" id="import" accept=".json" hidden></label></div>' +
      '<p class="small muted" style="margin:0">Tệp xuất gồm cả tiến độ các bộ ôn thi (nếu có). Nhập sẽ <b>thay thế</b> dữ liệu bảng điều khiển hiện tại và gộp tiến độ ôn thi theo bản ghi mới hơn.</p></div>';
    h += '<div class="card stack"><h3 style="margin:0">Ngày thi</h3>' + data.exams.map(function (e) {
      return '<div class="row"><b>' + esc(e.name) + '</b><span class="muted">' + fmtDate(e.date) + '</span><span class="spacer"></span><button class="btn sm" data-act="edit-exam" data-id="' + e.id + '">Sửa</button><button class="btn sm ghost danger" data-act="del-exam" data-id="' + e.id + '">Xóa</button></div>';
    }).join('') + '<div><button class="btn sm" data-act="add-exam">+ Thêm kỳ thi</button></div></div>';
    h += '<div class="card stack"><h3 style="margin:0">Làm lại từ đầu</h3><p class="small muted" style="margin:0">Xóa toàn bộ dữ liệu bảng điều khiển (không đụng tới tiến độ các bộ ôn thi).</p><div><button class="btn danger" data-act="reset">Xóa dữ liệu bảng điều khiển…</button></div></div>';
    h += '</section>';
    $app.innerHTML = h;
  }
  function exportAll() {
    var quiz = {};
    SL.store.keys('sl.quiz.').forEach(function (k) { if (/\.v1$/.test(k)) quiz[k] = SL.store.get(k, null); });
    SL.download('bang-dieu-khien-' + SL.today() + '.json', JSON.stringify({ app: 'study-lab-dashboard', exported: new Date().toISOString(), dash: data, quiz: quiz }, null, 1));
  }
  function importAll(text) {
    var o;
    try { o = JSON.parse(text); } catch (e) { SL.toast('Tệp không hợp lệ.'); return; }
    if (!o || o.app !== 'study-lab-dashboard' || !o.dash || o.dash.v !== 1) { SL.toast('Không phải tệp sao lưu của bảng điều khiển.'); return; }
    if (!window.confirm('Thay thế dữ liệu bảng điều khiển hiện tại bằng tệp này?')) return;
    data = o.dash;
    data.mistakes.forEach(function (m) { if (m.due === null) m.due = Infinity; });
    save();
    Object.keys(o.quiz || {}).forEach(function (k) {
      var inc = o.quiz[k], cur = SL.store.get(k, null);
      if (!cur) { SL.store.set(k, inc); return; }
      Object.keys(inc.q || {}).forEach(function (id) { if (!cur.q[id] || (inc.q[id].last || 0) > (cur.q[id].last || 0)) cur.q[id] = inc.q[id]; });
      SL.store.set(k, cur);
    });
    SL.toast('Đã nhập dữ liệu.');
    route();
  }
  function editExam(id) {
    var e = id ? data.exams.filter(function (x) { return x.id === id; })[0] : null;
    var name = window.prompt('Tên kỳ thi:', e ? e.name : 'Kỳ thi mới');
    if (!name) return;
    var date = window.prompt('Ngày thi (YYYY-MM-DD):', e ? e.date : SL.today());
    if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date) || isNaN(parseYmd(date))) { SL.toast('Ngày không hợp lệ (dạng 2027-06-10).'); return; }
    if (e) { e.name = name; e.date = date; e.note = ''; } else data.exams.push({ id: uid(), name: name, date: date, note: '' });
    save(); route();
  }

  /* ===================== SỰ KIỆN ===================== */
  $app.addEventListener('click', function (ev) {
    var t = ev.target.closest('[data-act]');
    if (!t) return;
    var act = t.getAttribute('data-act'), id = t.getAttribute('data-id');
    if (act === 'toggle-task') return;   // xử lý ở change
    switch (act) {
      case 'dismiss-sample': data.sample = false; save(); viewHome(); break;
      case 'add-exam': editExam(null); break;
      case 'edit-exam': editExam(id); break;
      case 'del-exam': if (window.confirm('Xóa kỳ thi này?')) { data.exams = data.exams.filter(function (x) { return x.id !== id; }); save(); route(); } break;
      case 'week': planOffset += +t.getAttribute('data-d'); viewPlan(); break;
      case 'del-task': {
        var day = t.getAttribute('data-day');
        data.plan.template[day] = data.plan.template[day].filter(function (x) { return x.id !== id; });
        data.sample = false; save(); viewPlan(); break;
      }
      case 'pm-start': {
        data.pomo.work = Math.max(5, +document.getElementById('pm-work').value || 25);
        data.pomo.brk = Math.max(1, +document.getElementById('pm-brk').value || 5);
        save();
        SL.store.set(RUN_KEY, { mode: 'work', start: Date.now(), dur: data.pomo.work, subject: document.getElementById('pm-sub').value });
        viewFocus(); break;
      }
      case 'pm-stop': {
        var run = SL.store.get(RUN_KEY, null);
        if (run && run.mode === 'work') {
          var mins = Math.floor((Date.now() - run.start) / 60000);
          if (mins >= 5) { addLog({ date: SL.today(), subject: run.subject, min: mins, note: 'Pomodoro (dừng sớm)', src: 'pomodoro' }); SL.toast('Đã ghi ' + mins + ' phút.'); }
        }
        SL.store.remove(RUN_KEY); document.title = 'Bảng điều khiển ôn thi'; viewFocus(); break;
      }
      case 'del-log': data.log = data.log.filter(function (x) { return x.id !== id; }); save(); viewFocus(); break;
      case 'del-mistake': if (window.confirm('Xóa lỗi sai này?')) { data.mistakes = data.mistakes.filter(function (x) { return x.id !== id; }); save(); viewMistakes(); } break;
      case 'review': reviewQueue = mistakesDue().sort(function (a, b) { return a.due - b.due; }); viewReview(); break;
      case 'rv-ok': reviewAnswer(true); break;
      case 'rv-fail': reviewAnswer(false); break;
      case 'rv-end': reviewQueue = null; viewMistakes(); break;
      case 'export': exportAll(); break;
      case 'reset': if (window.confirm('Xóa toàn bộ dữ liệu bảng điều khiển? Không thể hoàn tác.')) { data = defaults(); data.sample = true; save(); SL.toast('Đã đặt lại.'); viewData(); } break;
    }
  });
  $app.addEventListener('change', function (ev) {
    var t = ev.target;
    if (t.matches('[data-act="toggle-task"]')) {
      var key = t.getAttribute('data-date') || SL.today(), id = t.getAttribute('data-id');
      var list = data.plan.done[key] || (data.plan.done[key] = []);
      var i = list.indexOf(id);
      if (t.checked && i < 0) list.push(id); else if (!t.checked && i >= 0) list.splice(i, 1);
      save();
      var li = t.closest('li'); if (li) li.classList.toggle('done', t.checked);
      if ((location.hash || '#home') === '#home' || location.hash === '') viewHome();
    } else if (t.id === 'import' && t.files[0]) SL.readFile(t.files[0]).then(importAll);
    else if (/^mf-/.test(t.id)) { mFilter[t.id.slice(3)] = t.value; viewMistakes(); }
  });
  $app.addEventListener('submit', function (ev) {
    ev.preventDefault();
    var f = ev.target, fd = function (n) { return (f.elements[n] && f.elements[n].value || '').trim(); };
    if (f.classList.contains('add-task')) {
      var day = f.getAttribute('data-day');
      (data.plan.template[day] = data.plan.template[day] || []).push({ id: uid(), text: fd('text'), subject: fd('subject'), min: Math.max(5, +fd('min') || 30) });
      data.sample = false; save(); viewPlan();
    } else if (f.id === 'add-subject') {
      var s = fd('s');
      if (s && data.subjects.indexOf(s) < 0) { data.subjects.push(s); save(); }
      viewPlan();
    } else if (f.id === 'add-log') {
      addLog({ date: fd('date'), subject: fd('subject'), min: Math.max(1, +fd('min')), note: fd('note'), src: 'manual' });
      SL.toast('Đã thêm vào nhật ký.'); viewFocus();
    } else if (f.id === 'add-mistake') {
      data.mistakes.push({ id: uid(), created: Date.now(), subject: fd('subject'), topic: fd('topic'), type: fd('type'), source: fd('source'),
        wrong: fd('wrong'), right: fd('right'), tip: fd('tip'), stage: 0, due: Date.now() + REVIEW_DAYS[0] * DAY, mastered: false });
      save(); SL.toast('Đã lưu. Sẽ nhắc ôn lại vào ngày mai.'); viewMistakes();
    }
  });

  // JSON không lưu được Infinity → chuẩn hóa khi nạp
  data.mistakes.forEach(function (m) { if (m.due === null || m.mastered) m.due = Infinity; });
  startTick();
  route();
  window.Dash = { data: function () { return data; }, finishPhase: finishPhase };
})();
