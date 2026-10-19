/* ==========================================================================
   Engine ôn thi — dùng chung cho mọi ngân hàng câu hỏi.

   Cần nạp trước: shared/common.js, KaTeX (tùy chọn), và một hoặc nhiều tệp
   ngân hàng khai báo window.QBANKS[id] = { ... } (xem README của P1).

   Cấu hình trang: window.QUIZ_APP = { title, bankIds: [...], backLink }
   Dữ liệu tiến độ: localStorage['sl.quiz.<bankId>.v1']
   ========================================================================== */
(function () {
  'use strict';

  var SL = window.SL;
  var esc = SL.esc, fmt = SL.fmt;
  var APP = window.QUIZ_APP || {};
  var BANKS = window.QBANKS || {};
  var BANK_IDS = (APP.bankIds || Object.keys(BANKS)).filter(function (id) { return BANKS[id]; });

  var TYPE_LABEL = { mcq: 'Trắc nghiệm', tf: 'Đúng/Sai', short: 'Trả lời ngắn' };
  var LEVEL_LABEL = { 1: 'Biết', 2: 'Hiểu', 3: 'Vận dụng', 4: 'Vận dụng cao' };
  var LETTERS = ['A', 'B', 'C', 'D', 'E', 'F'];
  var TF_LETTERS = ['a', 'b', 'c', 'd'];

  /* Hộp Leitner: thời gian chờ trước khi câu "đến hạn" ôn lại */
  var MIN = 60000, DAY = SL.DAY;
  var INTERVAL = { 1: 10 * MIN, 2: 1 * DAY, 3: 3 * DAY, 4: 7 * DAY, 5: 21 * DAY };
  var MASTER_BOX = 4;

  var $app = document.getElementById('app');
  var bank, byId, chapterIdx, data;
  var session = null;   // phiên luyện tập đang chạy
  var exam = null;      // bài thi thử đang làm
  var examTimer = null;

  /* ======================== Lưu trữ ======================== */
  function dataKey(id) { return 'sl.quiz.' + id + '.v1'; }
  function examKey(id) { return 'sl.quiz.' + id + '.exam-inprogress'; }
  function emptyData() { return { v: 1, q: {}, exams: [], log: [], daily: {} }; }
  function loadData(id) {
    var d = SL.store.get(dataKey(id), null);
    if (!d || typeof d !== 'object' || !d.q) d = emptyData();
    d.exams = d.exams || []; d.log = d.log || []; d.daily = d.daily || {};
    return d;
  }
  function save() { SL.store.set(dataKey(bank.id), data); }
  function rec(id) {
    var r = data.q[id];
    if (!r) r = data.q[id] = { box: 0, due: 0, seen: 0, right: 0, wrong: 0, streak: 0, wb: false, last: 0 };
    return r;
  }
  function peek(id) { return data.q[id] || null; }

  /* Ghi nhận một lần trả lời và cập nhật hộp Leitner */
  function grade(id, ok) {
    var r = rec(id), now = Date.now();
    r.seen++;
    if (ok) {
      r.right++; r.streak++;
      r.box = r.box ? Math.min(5, r.box + 1) : 3;
      if (r.wb && r.streak >= 2) r.wb = false;   // đúng 2 lần liên tiếp thì rời sổ câu sai
    } else {
      r.wrong++; r.streak = 0; r.box = 1; r.wb = true;
    }
    r.due = now + INTERVAL[r.box];
    r.last = now; r.lastOk = ok;
    data.log.push({ t: now, id: id, ok: ok ? 1 : 0 });
    if (data.log.length > 3000) data.log = data.log.slice(-3000);
    var day = SL.today();
    var dd = data.daily[day] || (data.daily[day] = { n: 0, ok: 0 });
    dd.n++; if (ok) dd.ok++;
  }

  /* ======================== Chấm điểm ======================== */
  function decimals(s) {
    var t = String(s).replace(',', '.'), i = t.indexOf('.');
    return i < 0 ? 0 : t.length - i - 1;
  }
  function blankAnswer(q) { return q.type === 'tf' ? q.statements.map(function () { return null; }) : null; }
  function isAnswered(q, a) {
    if (q.type === 'tf') return !!a && a.every(function (x) { return x !== null; });
    if (q.type === 'short') return a != null && String(a).trim() !== '';
    return a != null;
  }
  function evaluate(q, a) {
    if (q.type === 'mcq') return { ok: a === q.answer, n: a === q.answer ? 1 : 0 };
    if (q.type === 'tf') {
      var n = 0;
      q.statements.forEach(function (st, i) { if (a && a[i] === st.a) n++; });
      return { ok: n === q.statements.length, n: n };
    }
    var x = SL.parseNum(a), y = SL.parseNum(q.answer);
    var tol = q.tol != null ? q.tol : 0;
    var ok = !isNaN(x) && Math.abs(x - y) <= tol + 1e-9;
    return { ok: ok, n: ok ? 1 : 0 };
  }

  /* ======================== Tiện ích ======================== */
  function chapterTitle(ch) { var c = bank.chapters[chapterIdx[ch]]; return c ? c.title : ch; }
  function chapterShort(ch) { var c = bank.chapters[chapterIdx[ch]]; return c ? (c.short || c.title) : ch; }
  function badgesFor(q) {
    return '<span class="badge accent">' + esc(chapterShort(q.ch)) + '</span>' +
      '<span class="badge">' + TYPE_LABEL[q.type] + '</span>' +
      (q.level ? '<span class="badge">' + LEVEL_LABEL[q.level] + '</span>' : '') +
      (q.verify ? '<span class="badge warn" title="Nội dung cần xác minh thêm">cần xác minh</span>' : '');
  }
  function setView(html) {
    $app.innerHTML = html;
    SL.math($app);
    window.scrollTo(0, 0);
  }
  function go(hash) { if (location.hash === hash) route(); else location.hash = hash; }
  function questionsOf(filter) { return bank.questions.filter(filter || function () { return true; }); }
  function dueList() {
    var now = Date.now();
    return bank.questions.filter(function (q) { var r = peek(q.id); return r && r.seen && r.due <= now; });
  }
  function wrongList() {
    return bank.questions.filter(function (q) { var r = peek(q.id); return r && r.wb; })
      .sort(function (a, b) { return peek(b.id).last - peek(a.id).last; });
  }
  function chapterStats(ch) {
    var qs = bank.questions.filter(function (q) { return !ch || q.ch === ch; });
    var s = { total: qs.length, seen: 0, master: 0, right: 0, wrong: 0, due: 0, wb: 0 };
    var now = Date.now();
    qs.forEach(function (q) {
      var r = peek(q.id);
      if (!r || !r.seen) return;
      s.seen++; s.right += r.right; s.wrong += r.wrong;
      if (r.box >= MASTER_BOX) s.master++;
      if (r.due <= now) s.due++;
      if (r.wb) s.wb++;
    });
    s.acc = s.right + s.wrong ? s.right / (s.right + s.wrong) : null;
    return s;
  }

  /* ======================== Hiển thị câu hỏi ========================
     ctx = { key, mode: 'answer'|'review', answer, perm, showWhy }
     Trả về HTML; sự kiện được gắn bằng uỷ quyền (data-act). */
  function renderQuestionBody(q, ctx) {
    var h = '<div class="q-stem">' + SL.fmtBlock(q.q) + '</div>';
    if (q.fig) h += '<div class="q-fig">' + q.fig + '</div>';
    var review = ctx.mode === 'review';
    if (q.type === 'mcq') {
      h += '<ul class="choices" role="list">';
      ctx.perm.forEach(function (orig, pos) {
        var cls = 'choice';
        if (review) {
          if (orig === q.answer) cls += ' right';
          else if (orig === ctx.answer) cls += ' wrong';
        } else if (ctx.answer === orig) cls += ' sel';
        var why = review && ctx.showWhy && q.why && q.why[orig] ? '<span class="why">' + fmt(q.why[orig]) + '</span>' : '';
        h += '<li><button type="button" class="' + cls + '" data-act="pick" data-key="' + ctx.key + '" data-v="' + orig + '"' +
          (review ? ' disabled' : '') + ' aria-pressed="' + (ctx.answer === orig) + '">' +
          '<span class="letter">' + LETTERS[pos] + '</span><span class="body">' + fmt(q.choices[orig]) + why + '</span></button></li>';
      });
      h += '</ul>';
    } else if (q.type === 'tf') {
      h += '<div class="tf">';
      q.statements.forEach(function (st, i) {
        var a = ctx.answer ? ctx.answer[i] : null;
        var cls = 'tf-row';
        if (review) cls += (a === st.a) ? ' right' : ' wrong';
        var btn = function (val, label) {
          return '<button type="button" class="tf-btn' + (a === val ? ' sel' : '') + '" data-act="tf" data-key="' + ctx.key +
            '" data-i="' + i + '" data-v="' + (val ? 1 : 0) + '"' + (review ? ' disabled' : '') +
            ' aria-pressed="' + (a === val) + '" title="' + (val ? 'Đúng' : 'Sai') + '">' + label + '</button>';
        };
        h += '<div class="' + cls + '"><span class="lbl">' + TF_LETTERS[i] + ')</span><span class="txt">' + fmt(st.s) + '</span>' +
          '<span class="tf-btns">' + btn(true, 'Đ') + btn(false, 'S') + '</span>';
        if (review) {
          h += '<div class="exp"><b>' + (st.a ? 'Đúng' : 'Sai') + '.</b> ' + fmt(st.e || '') +
            (a !== null && a !== st.a ? ' <span class="badge bad">bạn chọn ' + (a ? 'Đ' : 'S') + '</span>' : '') +
            (a === null ? ' <span class="badge warn">bỏ trống</span>' : '') + '</div>';
        }
        h += '</div>';
      });
      h += '</div>';
    } else if (q.type === 'short') {
      var v = ctx.answer == null ? '' : String(ctx.answer);
      var cls2 = review ? (evaluate(q, ctx.answer).ok ? 'right' : 'wrong') : '';
      h += '<div class="short"><label class="sr-only" for="in-' + ctx.key + '">Đáp số</label>' +
        '<input id="in-' + ctx.key + '" type="text" inputmode="decimal" maxlength="4" autocomplete="off" spellcheck="false" ' +
        'class="' + cls2 + '" data-act="short" data-key="' + ctx.key + '" value="' + esc(v) + '"' + (review ? ' disabled' : '') +
        ' placeholder="____">' +
        (q.unit ? '<span class="muted">' + fmt(q.unit) + '</span>' : '') +
        '<span class="muted small">Tối đa 4 ký tự (kể cả dấu “-” và dấu phẩy).</span></div>';
      if (review) {
        h += '<p class="small" style="margin-top:8px">Đáp án: <b>' + esc(q.answer) + '</b>' +
          (q.tol ? ' (chấp nhận sai lệch ±' + SL.num(q.tol, 3) + ')' : '') + '</p>';
      }
    }
    return h;
  }

  function renderExplain(q) {
    var h = '<div class="explain"><h4>Lời giải</h4>' + SL.fmtBlock(q.explain || '') + '</div>';
    if (q.tip) h += '<div class="callout warn small" style="margin-top:10px"><b>Mẹo / bẫy hay gặp:</b> ' + fmt(q.tip) + '</div>';
    if (q.verify) h += '<div class="callout warn small" style="margin-top:10px"><b>Cần xác minh:</b> ' + fmt(q.verify) + '</div>';
    return h;
  }

  function makePerm(q) {
    if (q.type !== 'mcq') return null;
    var idx = q.choices.map(function (_, i) { return i; });
    return q.keepOrder ? idx : SL.shuffle(idx);
  }

  /* ======================== Trang chủ ======================== */
  function viewHome() {
    var all = chapterStats(null);
    var due = dueList().length, wb = wrongList().length;
    var inprog = SL.store.get(examKey(bank.id), null);
    var h = '';
    h += '<section class="stack">';
    h += '<div class="row"><div><h1>' + esc(bank.title) + '</h1><p class="muted" style="margin:0">' + fmt(bank.subtitle || '') + '</p></div></div>';

    if (inprog) {
      h += '<div class="callout warn row"><span>Bạn có một bài thi thử đang làm dở (bắt đầu lúc ' + SL.timeVN(inprog.start) + ' ' + SL.dateVN(inprog.start) + ').</span>' +
        '<span class="spacer"></span><button class="btn sm primary" data-act="resume-exam">Làm tiếp</button><button class="btn sm ghost danger" data-act="drop-exam">Hủy bài</button></div>';
    }

    h += '<div class="grid grid-4">' +
      stat(all.seen + '/' + all.total, 'câu đã làm') +
      stat(all.acc == null ? '—' : Math.round(all.acc * 100) + '%', 'tỉ lệ đúng (mọi lượt)') +
      stat(all.master, 'câu thành thạo (hộp ≥ ' + MASTER_BOX + ')') +
      stat(streakDays(), 'ngày học liên tiếp') +
      '</div>';

    h += '<div class="grid grid-3">' +
      actionCard('Ôn câu đến hạn', due ? due + ' câu cần ôn hôm nay theo lịch lặp lại ngắt quãng.' : 'Chưa có câu nào đến hạn. Làm thêm câu mới nhé!', 'start-due', due ? 'Ôn ngay (' + due + ')' : 'Không có câu đến hạn', !due) +
      actionCard('Sổ câu sai', wb ? wb + ' câu bạn từng làm sai và chưa sửa được 2 lần liên tiếp.' : 'Sổ trống — tuyệt vời.', 'go-wrong', 'Mở sổ câu sai', false) +
      actionCard('Thi thử', examFormatText(), 'go-exam', 'Vào phòng thi', false) +
      '</div>';

    // Từng chương
    h += '<div class="card"><div class="row"><h2 style="margin:0">Tiến độ theo chương</h2><span class="spacer"></span>' +
      '<a class="btn sm" href="#/practice">Luyện tập tùy chọn →</a></div>' +
      '<div class="legend" style="margin:8px 0 4px"><span><i style="background:var(--ok)"></i>Thành thạo</span>' +
      '<span><i style="background:var(--accent)"></i>Đang học</span><span><i style="background:var(--bad)"></i>Đang sai</span>' +
      '<span><i style="background:var(--surface-2);border:1px solid var(--border)"></i>Chưa làm</span></div>' +
      '<div class="grid grid-2" style="margin-top:10px">';
    bank.chapters.forEach(function (c) {
      var s = chapterStats(c.id);
      var learning = Math.max(0, s.seen - s.master - s.wb);
      var w = function (n) { return (s.total ? (100 * n) / s.total : 0).toFixed(2) + '%'; };
      h += '<div class="card flat chapter-card"><div class="row"><b>' + esc(c.title) + '</b><span class="spacer"></span>' +
        '<span class="badge">' + s.total + ' câu</span></div>' +
        '<div class="bar stacked" aria-label="Tiến độ chương"><i style="width:' + w(s.master) + ';background:var(--ok)"></i>' +
        '<i style="width:' + w(learning) + ';background:var(--accent)"></i><i style="width:' + w(s.wb) + ';background:var(--bad)"></i></div>' +
        '<div class="row small muted"><span>Đã làm ' + s.seen + '/' + s.total + '</span>' +
        '<span>· Đúng ' + (s.acc == null ? '—' : Math.round(s.acc * 100) + '%') + '</span>' +
        (s.due ? '<span>· <b style="color:var(--warn)">' + s.due + ' đến hạn</b></span>' : '') +
        '<span class="spacer"></span><button class="btn sm" data-act="start-chapter" data-ch="' + c.id + '">Luyện chương</button></div></div>';
    });
    h += '</div></div>';

    // Gợi ý + lịch sử thi
    h += '<div class="grid grid-2">';
    h += '<div class="card"><h3>Gợi ý hôm nay</h3>' + suggestion() + '</div>';
    h += '<div class="card"><h3>Lịch sử thi thử</h3>' + examHistoryMini() + '</div>';
    h += '</div>';
    if (bank.notes) h += '<div class="card"><h3>Ghi chú về ngân hàng câu hỏi</h3>' + SL.fmtBlock(bank.notes) + '</div>';
    h += '</section>';
    setView(h);
  }
  function stat(v, label) { return '<div class="card stat"><b>' + v + '</b><span>' + label + '</span></div>'; }
  function actionCard(title, text, act, btn, disabled) {
    return '<div class="card stack"><h3 style="margin:0">' + title + '</h3><p class="muted small" style="margin:0">' + text + '</p>' +
      '<div><button class="btn' + (disabled ? '' : ' primary') + '" data-act="' + act + '"' + (disabled ? ' disabled' : '') + '>' + btn + '</button></div></div>';
  }
  function examFormatText() {
    var f = bank.exam;
    if (!f) return 'Chưa cấu hình đề thi.';
    return f.parts.map(function (p) { return p.count + ' ' + TYPE_LABEL[p.type].toLowerCase(); }).join(' + ') +
      ' · ' + f.minutes + ' phút · chấm theo thang 10.';
  }
  function streakDays() {
    var n = 0, d = new Date();
    for (;;) {
      var key = d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
      if (data.daily[key] && data.daily[key].n > 0) { n++; d.setDate(d.getDate() - 1); }
      else if (n === 0 && key === SL.today()) { d.setDate(d.getDate() - 1); }   // hôm nay chưa học vẫn giữ chuỗi
      else break;
      if (n > 3650) break;
    }
    return n;
  }
  function suggestion() {
    var stats = bank.chapters.map(function (c) { return { c: c, s: chapterStats(c.id) }; });
    var untouched = stats.filter(function (x) { return x.s.seen === 0; });
    var weak = stats.filter(function (x) { return x.s.right + x.s.wrong >= 5; })
      .sort(function (a, b) { return a.s.acc - b.s.acc; })[0];
    var lines = [];
    var due = dueList().length;
    if (due) lines.push('Ôn <b>' + due + '</b> câu đến hạn trước — đó là thứ bạn sắp quên.');
    if (weak && weak.s.acc < 0.8) lines.push('Chương yếu nhất: <b>' + esc(weak.c.title) + '</b> (đúng ' + Math.round(weak.s.acc * 100) + '%). Luyện 10 câu chương này.');
    if (untouched.length) lines.push('Chưa làm câu nào ở: ' + untouched.map(function (x) { return '<b>' + esc(x.c.title) + '</b>'; }).join(', ') + '.');
    if (data.exams.length === 0) lines.push('Bạn chưa thi thử lần nào — làm 1 đề để biết mình đang ở đâu.');
    if (!lines.length) lines.push('Mọi thứ ổn! Làm 1 đề thi thử để giữ phong độ.');
    return '<ul style="margin:0;padding-left:20px">' + lines.map(function (l) { return '<li>' + l + '</li>'; }).join('') + '</ul>';
  }
  function examHistoryMini() {
    var ex = data.exams.slice(-12);
    if (!ex.length) return '<p class="muted">Chưa có bài thi nào.</p>';
    var W = 300, H = 70, pad = 6;
    var pts = ex.map(function (e, i) {
      var x = ex.length === 1 ? W / 2 : pad + (i * (W - 2 * pad)) / (ex.length - 1);
      var y = H - pad - ((e.total / e.max) * (H - 2 * pad));
      return [x, y];
    });
    var svg = '<svg class="spark" viewBox="0 0 ' + W + ' ' + H + '" preserveAspectRatio="none" role="img" aria-label="Điểm các lần thi">' +
      '<line x1="0" x2="' + W + '" y1="' + (H - pad - 0.5 * (H - 2 * pad)) + '" y2="' + (H - pad - 0.5 * (H - 2 * pad)) + '" stroke="var(--border)" stroke-dasharray="4 4"/>' +
      '<polyline fill="none" stroke="var(--accent)" stroke-width="2" points="' + pts.map(function (p) { return p.join(','); }).join(' ') + '"/>' +
      pts.map(function (p) { return '<circle cx="' + p[0] + '" cy="' + p[1] + '" r="3" fill="var(--accent)"/>'; }).join('') + '</svg>';
    var last = data.exams[data.exams.length - 1];
    return svg + '<p class="small muted" style="margin:6px 0 0">Gần nhất: <b>' + SL.num(last.total, 2) + '/' + last.max + '</b> (' + SL.dateVN(last.t) +
      '). Đường đứt = mốc 5 điểm. <a href="#/exam">Xem tất cả →</a></p>';
  }

  /* ======================== Luyện tập tùy chọn ======================== */
  var practiceOpts = SL.store.get('sl.quiz.practiceOpts', null) || { chs: null, types: ['mcq', 'tf', 'short'], levels: [1, 2, 3, 4], n: 10, src: 'new' };
  function viewPractice() {
    // Lựa chọn đã lưu có thể thuộc ngân hàng khác → chỉ giữ chương của ngân hàng đang mở
    var chs = (practiceOpts.chs || []).filter(function (c) { return chapterIdx[c] != null; });
    if (!chs.length) chs = bank.chapters.map(function (c) { return c.id; });
    var types = practiceOpts.types.filter(function (t) { return bank.questions.some(function (q) { return q.type === t; }); });
    if (!types.length) types = ['mcq', 'tf', 'short'];
    var chip = function (group, val, label, on) {
      return '<label class="chip' + (on ? ' on' : '') + '"><input type="checkbox" data-group="' + group + '" value="' + val + '"' + (on ? ' checked' : '') + '> ' + label + '</label>';
    };
    var h = '<section class="stack"><h1>Luyện tập tùy chọn</h1>';
    h += '<div class="card stack"><div><b>Chương</b><div class="row" style="margin-top:6px">' +
      bank.chapters.map(function (c) { return chip('ch', c.id, esc(c.title), chs.indexOf(c.id) >= 0); }).join('') + '</div></div>';
    h += '<div><b>Dạng câu</b><div class="row" style="margin-top:6px">' +
      ['mcq', 'tf', 'short'].filter(function (t) { return bank.questions.some(function (q) { return q.type === t; }); })
        .map(function (t) { return chip('type', t, TYPE_LABEL[t], types.indexOf(t) >= 0); }).join('') + '</div></div>';
    h += '<div><b>Mức độ</b><div class="row" style="margin-top:6px">' +
      [1, 2, 3, 4].map(function (l) { return chip('level', l, LEVEL_LABEL[l], practiceOpts.levels.indexOf(l) >= 0); }).join('') + '</div></div>';
    h += '<div class="row"><label class="field"><span>Nguồn câu hỏi</span><select id="p-src">' +
      [['new', 'Ưu tiên câu chưa làm'], ['all', 'Ngẫu nhiên tất cả'], ['weak', 'Ưu tiên câu hay sai / hộp thấp']].map(function (o) {
        return '<option value="' + o[0] + '"' + (practiceOpts.src === o[0] ? ' selected' : '') + '>' + o[1] + '</option>';
      }).join('') + '</select></label>' +
      '<label class="field"><span>Số câu</span><select id="p-n">' + [5, 10, 20, 30, 0].map(function (n) {
        return '<option value="' + n + '"' + (practiceOpts.n === n ? ' selected' : '') + '>' + (n || 'Tất cả') + '</option>';
      }).join('') + '</select></label></div>';
    h += '<div class="row"><button class="btn primary" data-act="start-practice">Bắt đầu</button><span class="muted small" id="p-count"></span></div></div>';
    h += '<div class="card small muted">Mẹo: trong lúc làm, bấm <kbd>1</kbd>–<kbd>4</kbd> (hoặc <kbd>A</kbd>–<kbd>D</kbd>) để chọn đáp án, <kbd>Enter</kbd> để kiểm tra / sang câu tiếp.</div>';
    h += '</section>';
    setView(h);
    updatePracticeCount();
  }
  function readPracticeForm() {
    var get = function (g) {
      return Array.prototype.slice.call($app.querySelectorAll('input[data-group="' + g + '"]:checked')).map(function (i) { return i.value; });
    };
    practiceOpts = {
      chs: get('ch'), types: get('type'), levels: get('level').map(Number),
      n: Number(document.getElementById('p-n').value), src: document.getElementById('p-src').value
    };
    SL.store.set('sl.quiz.practiceOpts', practiceOpts);
    return practiceOpts;
  }
  function practicePool(o) {
    return bank.questions.filter(function (q) {
      return o.chs.indexOf(q.ch) >= 0 && o.types.indexOf(q.type) >= 0 && o.levels.indexOf(q.level || 2) >= 0;
    });
  }
  function updatePracticeCount() {
    var el = document.getElementById('p-count');
    if (!el) return;
    var o = readPracticeForm();
    el.textContent = practicePool(o).length + ' câu phù hợp.';
  }
  function pickPractice(o) {
    var pool = SL.shuffle(practicePool(o));
    if (o.src === 'new') {
      pool.sort(function (a, b) { var ra = peek(a.id), rb = peek(b.id); return (ra && ra.seen ? 1 : 0) - (rb && rb.seen ? 1 : 0); });
    } else if (o.src === 'weak') {
      var score = function (q) { var r = peek(q.id); if (!r || !r.seen) return 2.5; return r.box - (r.wb ? 2 : 0); };
      pool.sort(function (a, b) { return score(a) - score(b); });
    }
    return o.n ? pool.slice(0, o.n) : pool;
  }

  /* ======================== Phiên luyện tập ======================== */
  function startSession(qs, title) {
    if (!qs.length) { SL.toast('Không có câu hỏi phù hợp.'); return; }
    session = {
      title: title, items: qs.map(function (q) { return { id: q.id, perm: makePerm(q), a: blankAnswer(q), done: false, ok: null }; }),
      i: 0, started: Date.now()
    };
    go('#/session');
  }
  function viewSession() {
    if (!session) { go('#/'); return; }
    if (session.i >= session.items.length) { viewSessionSummary(); return; }
    var it = session.items[session.i], q = byId[it.id];
    var n = session.items.length;
    var doneCount = session.items.filter(function (x) { return x.done; }).length;
    var h = '<section>';
    h += '<div class="session-top"><b>' + esc(session.title) + '</b><span class="muted small">Câu ' + (session.i + 1) + '/' + n + '</span>' +
      '<div class="bar"><i style="width:' + (100 * doneCount / n).toFixed(1) + '%"></i></div>' +
      '<button class="btn sm ghost" data-act="end-session">Kết thúc</button></div>';
    h += '<article class="card" id="qcard">' + questionCardInner(q, it) + '</article>';
    h += '</section>';
    setView(h);
    focusFirst();
  }
  function questionCardInner(q, it) {
    var h = '<div class="q-meta">' + badgesFor(q) + '<span class="spacer"></span><span class="muted small">' + esc(q.id) + '</span></div>';
    h += renderQuestionBody(q, { key: 's', mode: it.done ? 'review' : 'answer', answer: it.a, perm: it.perm, showWhy: true });
    if (it.done) {
      h += '<div class="feedback"><div class="verdict ' + (it.ok ? 'ok' : 'bad') + '">' + verdictText(q, it) + '</div>' + renderExplain(q) + '</div>';
      h += '<div class="actions"><button class="btn primary" data-act="next" id="btn-next">' +
        (session.i + 1 < session.items.length ? 'Câu tiếp theo →' : 'Xem kết quả') + '</button></div>';
    } else {
      h += '<div class="actions"><button class="btn primary" data-act="check" id="btn-check"' + (isAnswered(q, it.a) ? '' : ' disabled') + '>Kiểm tra</button>' +
        '<button class="btn ghost" data-act="skip">Bỏ qua</button></div>';
    }
    return h;
  }
  function verdictText(q, it) {
    if (q.type === 'tf') {
      var n = evaluate(q, it.a).n;
      return it.ok ? '✓ Đúng cả 4 ý!' : '✗ Đúng ' + n + '/4 ý' + (bank.exam && bank.exam.tfScale ? ' (thi thật được ' + SL.num(bank.exam.tfScale[n], 2) + ' điểm)' : '');
    }
    return it.ok ? '✓ Chính xác!' : '✗ Chưa đúng';
  }
  function refreshCard() {
    var it = session.items[session.i], q = byId[it.id];
    var card = document.getElementById('qcard');
    card.innerHTML = questionCardInner(q, it);
    SL.math(card);
  }
  function focusFirst() {
    var el = $app.querySelector('.short input:not(:disabled)');
    if (el) el.focus();
  }
  function sessionCheck() {
    var it = session.items[session.i], q = byId[it.id];
    if (it.done || !isAnswered(q, it.a)) return;
    var r = evaluate(q, it.a);
    it.done = true; it.ok = r.ok; it.n = r.n;
    grade(q.id, r.ok);
    save();
    refreshCard();
    var nb = document.getElementById('btn-next');
    if (nb) nb.focus({ preventScroll: true });
  }
  function sessionNext() {
    session.i++;
    viewSession();
  }
  function viewSessionSummary() {
    var items = session.items.filter(function (x) { return x.done; });
    var ok = items.filter(function (x) { return x.ok; }).length;
    var mins = Math.max(1, Math.round((Date.now() - session.started) / 60000));
    var h = '<section class="stack"><h1>Kết quả: ' + esc(session.title) + '</h1>';
    h += '<div class="grid grid-3">' + stat(ok + '/' + items.length, 'câu đúng') + stat(SL.pct(ok, items.length) + '%', 'tỉ lệ đúng') + stat(mins + ' phút', 'thời gian') + '</div>';
    var wrong = items.filter(function (x) { return !x.ok; });
    h += '<div class="row">' +
      (wrong.length ? '<button class="btn primary" data-act="retry-wrong">Làm lại ' + wrong.length + ' câu sai</button>' : '') +
      '<a class="btn" href="#/">Về trang chủ</a><a class="btn" href="#/practice">Luyện tiếp</a></div>';
    h += '<div class="card"><h3>Chi tiết</h3><div class="table-wrap"><table class="table"><thead><tr><th>#</th><th>Câu</th><th>Chương</th><th>Kết quả</th></tr></thead><tbody>';
    session.items.forEach(function (x, i) {
      var q = byId[x.id];
      h += '<tr><td>' + (i + 1) + '</td><td>' + esc(q.id) + ' <span class="muted small">' + TYPE_LABEL[q.type] + '</span></td><td>' + esc(chapterShort(q.ch)) + '</td><td>' +
        (!x.done ? '<span class="badge">bỏ qua</span>' : x.ok ? '<span class="badge ok">đúng</span>' : '<span class="badge bad">sai</span>') + '</td></tr>';
    });
    h += '</tbody></table></div></div></section>';
    setView(h);
  }

  /* ======================== Thi thử ======================== */
  function buildExam() {
    var f = bank.exam, ids = [];
    f.parts.forEach(function (p) {
      var pool = bank.questions.filter(function (q) { return q.type === p.type && !q.noExam; });
      // Rải đều theo chương: xếp vòng tròn giữa các chương (thứ tự trong chương ngẫu nhiên)
      var groups = {};
      SL.shuffle(pool).forEach(function (q) { (groups[q.ch] = groups[q.ch] || []).push(q); });
      var keys = SL.shuffle(Object.keys(groups)), picked = [];
      while (picked.length < p.count && keys.some(function (k) { return groups[k].length; })) {
        keys.forEach(function (k) { if (picked.length < p.count && groups[k].length) picked.push(groups[k].shift()); });
      }
      picked.sort(function (a, b) { return (a.level || 2) - (b.level || 2) || chapterIdx[a.ch] - chapterIdx[b.ch]; });
      picked.forEach(function (q) { ids.push(q.id); });
    });
    return {
      bank: bank.id, ids: ids, start: Date.now(), minutes: f.minutes,
      answers: ids.map(function (id) { return blankAnswer(byId[id]); }),
      perms: ids.map(function (id) { return makePerm(byId[id]); })
    };
  }
  function saveExam() { if (exam) SL.store.set(examKey(bank.id), exam); }
  function viewExamLobby() {
    var f = bank.exam;
    var h = '<section class="stack"><h1>Thi thử</h1>';
    h += '<div class="card stack"><h3 style="margin:0">Cấu trúc đề</h3><div class="table-wrap"><table class="table"><thead><tr><th>Phần</th><th>Dạng</th><th>Số câu</th><th>Cách tính điểm</th></tr></thead><tbody>';
    f.parts.forEach(function (p, i) {
      var pool = bank.questions.filter(function (q) { return q.type === p.type && !q.noExam; }).length;
      var rule = p.type === 'tf'
        ? 'Mỗi câu 4 ý; đúng 1/2/3/4 ý được ' + f.tfScale.slice(1).map(function (x) { return SL.num(x, 2); }).join(' / ') + ' điểm'
        : SL.num(p.points, 2) + ' điểm/câu';
      h += '<tr><td>' + ['I', 'II', 'III', 'IV'][i] + '</td><td>' + TYPE_LABEL[p.type] + '</td><td>' + p.count + ' <span class="muted small">(kho ' + pool + ')</span></td><td>' + rule + '</td></tr>';
    });
    h += '</tbody></table></div><p class="small muted" style="margin:0">Thời gian: <b>' + f.minutes + ' phút</b>. ' + fmt(f.note || '') + '</p>' +
      '<div class="row"><button class="btn primary" data-act="start-exam">Bắt đầu làm bài</button>' +
      '<label class="chip"><input type="checkbox" id="exam-notimer"> Không giới hạn thời gian</label></div></div>';
    if (data.exams.length) {
      h += '<div class="card"><h3>Các lần thi trước</h3><div class="table-wrap"><table class="table"><thead><tr><th>Ngày</th><th>Điểm</th>' +
        f.parts.map(function (p, i) { return '<th>Phần ' + ['I', 'II', 'III'][i] + '</th>'; }).join('') + '<th>Thời gian</th><th></th></tr></thead><tbody>';
      data.exams.slice().reverse().forEach(function (e, ri) {
        var idx = data.exams.length - 1 - ri;
        h += '<tr><td>' + SL.dateVN(e.t) + ' ' + SL.timeVN(e.t) + '</td><td><b>' + SL.num(e.total, 2) + '</b>/' + e.max + '</td>' +
          e.parts.map(function (p) { return '<td>' + SL.num(p.got, 2) + '/' + SL.num(p.max, 2) + '</td>'; }).join('') +
          '<td>' + SL.mmss(e.dur) + '</td><td><a href="#/exam/result/' + idx + '">Xem lại</a></td></tr>';
      });
      h += '</tbody></table></div></div>';
    }
    h += '</section>';
    setView(h);
  }
  function viewExamRun() {
    if (!exam) { exam = SL.store.get(examKey(bank.id), null); }
    if (!exam || exam.bank !== bank.id) { exam = null; go('#/exam'); return; }
    var f = bank.exam;
    var h = '<section>';
    h += '<div class="exam-bar"><span class="timer" id="timer">--:--</span><span class="muted small" id="answered"></span>' +
      '<span class="spacer"></span><button class="btn primary sm" data-act="submit-exam">Nộp bài</button></div>';
    h += '<details class="card flat" style="margin-bottom:12px"><summary class="small"><b>Bảng câu hỏi</b> (bấm để nhảy tới câu)</summary><div class="navgrid" style="margin-top:8px" id="navgrid"></div></details>';
    var k = 0;
    f.parts.forEach(function (p, pi) {
      h += '<h2 class="exam-part-title">Phần ' + ['I', 'II', 'III'][pi] + ' — ' + TYPE_LABEL[p.type] + '</h2>';
      for (var j = 0; j < p.count && k < exam.ids.length; j++, k++) {
        var q = byId[exam.ids[k]];
        if (!q) continue;
        h += '<article class="card exam-q" id="eq-' + k + '"><div class="q-meta"><span class="qnum">Câu ' + (j + 1) + '.</span></div>' +
          renderQuestionBody(q, { key: 'e' + k, mode: 'answer', answer: exam.answers[k], perm: exam.perms[k] }) + '</article>';
      }
    });
    h += '<div class="actions"><button class="btn primary" data-act="submit-exam">Nộp bài</button></div></section>';
    setView(h);
    updateExamNav();
    startExamTimer();
  }
  function examRemaining() {
    if (!exam || exam.noTimer) return Infinity;
    return exam.minutes * 60 - (Date.now() - exam.start) / 1000;
  }
  function startExamTimer() {
    clearInterval(examTimer);
    var tick = function () {
      var el = document.getElementById('timer');
      if (!el || !exam) { clearInterval(examTimer); return; }
      var rem = examRemaining();
      if (rem === Infinity) { el.textContent = '∞ ' + SL.mmss((Date.now() - exam.start) / 1000); return; }
      el.textContent = SL.mmss(rem);
      el.classList.toggle('low', rem < 300);
      if (rem <= 0) { clearInterval(examTimer); SL.toast('Hết giờ! Bài đã được nộp tự động.', 4000); submitExam(); }
    };
    tick();
    examTimer = setInterval(tick, 1000);
  }
  function updateExamNav() {
    var nav = document.getElementById('navgrid');
    if (!nav || !exam) return;
    var f = bank.exam, k = 0, h = '', done = 0;
    f.parts.forEach(function (p, pi) {
      h += '<a class="part" href="#eq-' + k + '" data-act="jump" data-k="' + k + '">' + ['I', 'II', 'III'][pi] + '</a>';
      for (var j = 0; j < p.count && k < exam.ids.length; j++, k++) {
        var ans = isAnswered(byId[exam.ids[k]], exam.answers[k]);
        if (ans) done++;
        h += '<a href="#eq-' + k + '" data-act="jump" data-k="' + k + '" class="' + (ans ? 'done' : '') + '">' + (j + 1) + '</a>';
      }
    });
    nav.innerHTML = h;
    var a = document.getElementById('answered');
    if (a) a.textContent = 'Đã làm ' + done + '/' + exam.ids.length + ' câu';
  }
  function scoreExam(ex) {
    var f = bank.exam, k = 0, total = 0, parts = [], byCh = {};
    f.parts.forEach(function (p) {
      var got = 0, max = 0;
      for (var j = 0; j < p.count && k < ex.ids.length; j++, k++) {
        var q = byId[ex.ids[k]];
        if (!q) continue;
        var r = evaluate(q, ex.answers[k]);
        var pts = p.type === 'tf' ? f.tfScale[r.n] : (r.ok ? p.points : 0);
        var pmax = p.type === 'tf' ? f.tfScale[f.tfScale.length - 1] : p.points;
        got += pts; max += pmax;
        var c = byCh[q.ch] || (byCh[q.ch] = { got: 0, max: 0 });
        c.got += pts; c.max += pmax;
      }
      parts.push({ type: p.type, got: Math.round(got * 1000) / 1000, max: Math.round(max * 1000) / 1000 });
      total += got;
    });
    return { total: Math.round(total * 1000) / 1000, max: f.max || 10, parts: parts, byCh: byCh };
  }
  function submitExam() {
    if (!exam) return;
    clearInterval(examTimer);
    var sc = scoreExam(exam);
    exam.ids.forEach(function (id, k) {
      var q = byId[id];
      if (q && isAnswered(q, exam.answers[k])) grade(id, evaluate(q, exam.answers[k]).ok);
      else if (q) grade(id, false);
    });
    var dur = Math.min((Date.now() - exam.start) / 1000, exam.noTimer ? Infinity : exam.minutes * 60);
    data.exams.push({ t: Date.now(), dur: Math.round(dur), total: sc.total, max: sc.max, parts: sc.parts, byCh: sc.byCh,
      ids: exam.ids, answers: exam.answers, perms: exam.perms });
    if (data.exams.length > 50) data.exams = data.exams.slice(-50);
    save();
    SL.store.remove(examKey(bank.id));
    exam = null;
    go('#/exam/result/' + (data.exams.length - 1));
  }
  function viewExamResult(idx) {
    var e = data.exams[idx];
    if (!e) { go('#/exam'); return; }
    var f = bank.exam;
    var h = '<section class="stack"><h1>Kết quả thi thử</h1>';
    h += '<div class="card row"><div><div class="score-big">' + SL.num(e.total, 2) + '<span class="muted" style="font-size:1.2rem">/' + e.max + '</span></div>' +
      '<div class="muted small">' + SL.dateVN(e.t) + ' · làm trong ' + SL.mmss(e.dur) + '</div></div><span class="spacer"></span>' +
      '<div class="grid grid-3" style="flex:1;min-width:260px">' + e.parts.map(function (p, i) {
        return '<div class="stat"><b style="font-size:1.2rem">' + SL.num(p.got, 2) + '/' + SL.num(p.max, 2) + '</b><span>Phần ' + ['I', 'II', 'III'][i] + ' · ' + TYPE_LABEL[p.type] + '</span></div>';
      }).join('') + '</div></div>';
    h += '<div class="card"><h3>Theo chương</h3>';
    bank.chapters.forEach(function (c) {
      var x = e.byCh[c.id];
      if (!x) return;
      var p = x.max ? x.got / x.max : 0;
      h += '<div style="margin:8px 0"><div class="row small"><span>' + esc(c.title) + '</span><span class="spacer"></span><b>' + SL.num(x.got, 2) + '/' + SL.num(x.max, 2) + '</b></div>' +
        '<div class="bar"><i style="width:' + (p * 100).toFixed(1) + '%;background:' + (p >= 0.8 ? 'var(--ok)' : p >= 0.5 ? 'var(--accent)' : 'var(--bad)') + '"></i></div></div>';
    });
    h += '</div>';
    h += '<div class="row"><a class="btn" href="#/exam">Về phòng thi</a><a class="btn" href="#/wrong">Mở sổ câu sai</a><button class="btn primary" data-act="start-exam">Thi đề mới</button></div>';
    h += '<h2>Xem lại bài làm</h2><div class="card flat"><div class="navgrid">';
    e.ids.forEach(function (id, k) {
      var q = byId[id];
      var ok = q && evaluate(q, e.answers[k]).ok;
      h += '<a href="#rq-' + k + '" data-act="jump-r" data-k="' + k + '" class="' + (ok ? 'right' : 'wrong') + '">' + (k + 1) + '</a>';
    });
    h += '</div></div>';
    var k = 0;
    f.parts.forEach(function (p, pi) {
      h += '<h3 class="exam-part-title">Phần ' + ['I', 'II', 'III'][pi] + '</h3>';
      for (var j = 0; j < p.count && k < e.ids.length; j++, k++) {
        var q = byId[e.ids[k]];
        if (!q) continue;
        var r = evaluate(q, e.answers[k]);
        h += '<article class="card exam-q" id="rq-' + k + '"><div class="q-meta"><span class="qnum">Câu ' + (j + 1) + '.</span>' + badgesFor(q) +
          '<span class="spacer"></span>' + (r.ok ? '<span class="badge ok">đúng</span>' : (q.type === 'tf' ? '<span class="badge warn">' + r.n + '/4 ý</span>' : '<span class="badge bad">' + (isAnswered(q, e.answers[k]) ? 'sai' : 'bỏ trống') + '</span>')) + '</div>' +
          renderQuestionBody(q, { key: 'r' + k, mode: 'review', answer: e.answers[k], perm: e.perms[k] || makePerm(q), showWhy: true }) +
          '<details style="margin-top:10px"><summary class="small"><b>Xem lời giải</b></summary><div style="margin-top:8px">' + renderExplain(q) + '</div></details></article>';
      }
    });
    h += '</section>';
    setView(h);
  }

  /* ======================== Sổ câu sai ======================== */
  function viewWrong() {
    var list = wrongList();
    var h = '<section class="stack"><div class="row"><h1 style="margin:0">Sổ câu sai</h1><span class="spacer"></span>' +
      (list.length ? '<button class="btn primary" data-act="start-wrong">Luyện lại tất cả (' + list.length + ')</button>' : '') + '</div>';
    h += '<p class="muted small" style="margin:0">Câu sẽ tự rời sổ khi bạn làm đúng <b>2 lần liên tiếp</b>. Bạn cũng có thể gỡ thủ công nếu chắc đã hiểu.</p>';
    if (!list.length) { h += '<div class="card empty">Chưa có câu sai nào. Làm bài rồi quay lại đây nhé.</div></section>'; setView(h); return; }
    // Gom theo chương
    var groups = {};
    list.forEach(function (q) { (groups[q.ch] = groups[q.ch] || []).push(q); });
    bank.chapters.forEach(function (c) {
      var g = groups[c.id];
      if (!g) return;
      h += '<h2>' + esc(c.title) + ' <span class="badge bad">' + g.length + '</span></h2><div class="qlist">';
      g.forEach(function (q) { h += qItem(q, true); });
      h += '</div>';
    });
    h += '</section>';
    setView(h);
  }
  function qItem(q, wrongMode) {
    var r = peek(q.id);
    var h = '<article class="card qitem"><div class="q-meta">' + badgesFor(q) + '<span class="spacer"></span><span class="muted small">' + esc(q.id) + '</span></div>';
    h += '<div class="q-stem">' + SL.fmtBlock(q.q) + '</div>' + (q.fig ? '<div class="q-fig">' + q.fig + '</div>' : '');
    if (r && r.seen) {
      h += '<p class="small muted" style="margin:6px 0 0">Đã làm ' + r.seen + ' lần · đúng ' + r.right + ' · sai ' + r.wrong + ' · hộp ' + r.box +
        (r.last ? ' · lần cuối ' + SL.dateVN(r.last) : '') + '</p>';
    }
    h += '<details><summary>Đáp án & lời giải</summary><div class="ans">' + answerKeyHtml(q) + renderExplain(q) + '</div></details>';
    h += '<div class="actions" style="margin-top:10px"><button class="btn sm" data-act="practice-one" data-id="' + q.id + '">Làm lại câu này</button>' +
      (wrongMode ? '<button class="btn sm ghost" data-act="unwrong" data-id="' + q.id + '">Gỡ khỏi sổ</button>' : '') + '</div>';
    h += '</article>';
    return h;
  }
  function answerKeyHtml(q) {
    if (q.type === 'mcq') return '<p><b>Đáp án:</b> ' + fmt(q.choices[q.answer]) + '</p>';
    if (q.type === 'short') return '<p><b>Đáp án:</b> ' + esc(q.answer) + (q.unit ? ' ' + fmt(q.unit) : '') + '</p>';
    return '<ul class="small">' + q.statements.map(function (st, i) {
      return '<li><b>' + TF_LETTERS[i] + ') ' + (st.a ? 'Đúng' : 'Sai') + '</b> — ' + fmt(st.s) + '<br><span class="muted">' + fmt(st.e || '') + '</span></li>';
    }).join('') + '</ul>';
  }

  /* ======================== Ngân hàng câu hỏi ======================== */
  var bankFilter = { ch: '', type: '', level: '', text: '', status: '' };
  function viewBank() {
    var h = '<section class="stack"><h1>Ngân hàng câu hỏi</h1>';
    h += '<div class="card row">' +
      sel('f-ch', 'Chương', [['', 'Tất cả']].concat(bank.chapters.map(function (c) { return [c.id, c.title]; })), bankFilter.ch) +
      sel('f-type', 'Dạng', [['', 'Tất cả'], ['mcq', TYPE_LABEL.mcq], ['tf', TYPE_LABEL.tf], ['short', TYPE_LABEL.short]], bankFilter.type) +
      sel('f-level', 'Mức độ', [['', 'Tất cả'], ['1', 'Biết'], ['2', 'Hiểu'], ['3', 'Vận dụng'], ['4', 'Vận dụng cao']], bankFilter.level) +
      sel('f-status', 'Trạng thái', [['', 'Tất cả'], ['new', 'Chưa làm'], ['wrong', 'Trong sổ sai'], ['master', 'Thành thạo']], bankFilter.status) +
      '<label class="field" style="flex:1;min-width:180px"><span>Tìm theo nội dung</span><input type="search" id="f-text" value="' + esc(bankFilter.text) + '" placeholder="vd: chu kì bán rã"></label></div>';
    h += '<div id="bank-list"></div></section>';
    setView(h);
    renderBankList();
  }
  function sel(id, label, opts, val) {
    return '<label class="field"><span>' + label + '</span><select id="' + id + '">' + opts.map(function (o) {
      return '<option value="' + o[0] + '"' + (String(val) === String(o[0]) ? ' selected' : '') + '>' + esc(o[1]) + '</option>';
    }).join('') + '</select></label>';
  }
  function plainText(q) {
    var t = q.q + ' ' + (q.choices || []).join(' ') + ' ' + (q.statements || []).map(function (s) { return s.s; }).join(' ');
    return t.toLowerCase();
  }
  function renderBankList() {
    var f = bankFilter, text = f.text.trim().toLowerCase();
    var list = bank.questions.filter(function (q) {
      if (f.ch && q.ch !== f.ch) return false;
      if (f.type && q.type !== f.type) return false;
      if (f.level && String(q.level) !== f.level) return false;
      var r = peek(q.id);
      if (f.status === 'new' && r && r.seen) return false;
      if (f.status === 'wrong' && !(r && r.wb)) return false;
      if (f.status === 'master' && !(r && r.box >= MASTER_BOX)) return false;
      if (text && plainText(q).indexOf(text) < 0 && q.id.indexOf(text) < 0) return false;
      return true;
    });
    var el = document.getElementById('bank-list');
    var shown = list.slice(0, 60);
    el.innerHTML = '<p class="muted small">' + list.length + ' câu' + (list.length > shown.length ? ' (hiển thị 60 câu đầu — lọc thêm để thu hẹp)' : '') + '</p>' +
      '<div class="qlist">' + shown.map(function (q) { return qItem(q, false); }).join('') + '</div>';
    SL.math(el);
  }

  /* ======================== Dữ liệu ======================== */
  function viewData() {
    var size = 0;
    try { size = (localStorage.getItem(dataKey(bank.id)) || '').length; } catch (e) { /* bỏ qua */ }
    var h = '<section class="stack"><h1>Dữ liệu & sao lưu</h1>';
    h += '<div class="card stack"><p style="margin:0">Tiến độ được lưu <b>ngay trong trình duyệt này</b> (localStorage, ~' + Math.ceil(size / 1024) + ' KB). ' +
      'Không có gì được gửi lên mạng. Nếu xóa dữ liệu trình duyệt hoặc đổi máy, hãy <b>xuất tệp sao lưu</b> trước.</p>' +
      '<div class="row"><button class="btn primary" data-act="export">Xuất tệp sao lưu (.json)</button>' +
      '<label class="btn">Nhập từ tệp…<input type="file" accept=".json,application/json" id="import-file" hidden></label></div>' +
      '<p class="small muted" style="margin:0">Khi nhập: lấy bản ghi mới hơn cho từng câu (gộp, không mất dữ liệu đang có).</p></div>';
    h += '<div class="card stack"><h3 style="margin:0">Xóa tiến độ</h3><p class="small muted" style="margin:0">Xóa toàn bộ lịch sử làm bài, sổ câu sai và kết quả thi của <b>' + esc(bank.title) + '</b>. Không thể hoàn tác.</p>' +
      '<div><button class="btn danger" data-act="reset">Xóa tiến độ…</button></div></div>';
    h += '<div class="card small muted"><b>Thống kê kho:</b> ' + bank.questions.length + ' câu · ' +
      ['mcq', 'tf', 'short'].map(function (t) { return bank.questions.filter(function (q) { return q.type === t; }).length + ' ' + TYPE_LABEL[t].toLowerCase(); }).join(' · ') +
      (bank.version ? ' · phiên bản ' + esc(bank.version) : '') + '</div>';
    h += '</section>';
    setView(h);
  }
  function exportData() {
    var payload = { app: 'study-lab-quiz', bank: bank.id, exported: new Date().toISOString(), data: data };
    SL.download('tien-do-' + bank.id + '-' + SL.today() + '.json', JSON.stringify(payload, null, 1));
  }
  function importData(text) {
    var obj;
    try { obj = JSON.parse(text); } catch (e) { SL.toast('Tệp không phải JSON hợp lệ.'); return; }
    if (!obj || obj.app !== 'study-lab-quiz' || !obj.data || !obj.data.q) { SL.toast('Tệp không đúng định dạng sao lưu.'); return; }
    if (obj.bank !== bank.id && !window.confirm('Tệp này thuộc ngân hàng "' + obj.bank + '", khác ngân hàng đang mở. Vẫn nhập?')) return;
    var inc = obj.data, n = 0;
    Object.keys(inc.q).forEach(function (id) {
      var a = data.q[id], b = inc.q[id];
      if (!a || (b.last || 0) > (a.last || 0)) { data.q[id] = b; n++; }
    });
    var seen = {};
    data.exams.forEach(function (e) { seen[e.t] = 1; });
    (inc.exams || []).forEach(function (e) { if (!seen[e.t]) data.exams.push(e); });
    data.exams.sort(function (a, b) { return a.t - b.t; });
    Object.keys(inc.daily || {}).forEach(function (d) {
      var a = data.daily[d], b = inc.daily[d];
      if (!a || b.n > a.n) data.daily[d] = b;
    });
    data.log = data.log.concat(inc.log || []).sort(function (a, b) { return a.t - b.t; }).slice(-3000);
    save();
    SL.toast('Đã nhập: cập nhật ' + n + ' câu.');
    viewData();
  }

  /* ======================== Sự kiện ======================== */
  $app.addEventListener('click', function (ev) {
    var t = ev.target.closest('[data-act]');
    if (!t || !$app.contains(t)) return;
    var act = t.getAttribute('data-act');
    var key = t.getAttribute('data-key');
    switch (act) {
      case 'pick': case 'tf': onAnswerInput(t, key); break;
      case 'check': sessionCheck(); break;
      case 'next': sessionNext(); break;
      case 'skip': session.i++; viewSession(); break;
      case 'end-session': session.i = session.items.length; viewSession(); break;
      case 'retry-wrong':
        startSession(session.items.filter(function (x) { return x.done && !x.ok; }).map(function (x) { return byId[x.id]; }), 'Làm lại câu sai');
        break;
      case 'start-due': startSession(SL.shuffle(dueList()), 'Ôn câu đến hạn'); break;
      case 'go-wrong': go('#/wrong'); break;
      case 'go-exam': go('#/exam'); break;
      case 'start-wrong': startSession(SL.shuffle(wrongList()), 'Luyện lại câu sai'); break;
      case 'start-chapter': {
        var ch = t.getAttribute('data-ch');
        startSession(pickPractice({ chs: [ch], types: ['mcq', 'tf', 'short'], levels: [1, 2, 3, 4], n: 10, src: 'new' }), 'Luyện: ' + chapterTitle(ch));
        break;
      }
      case 'start-practice': {
        var o = readPracticeForm();
        startSession(pickPractice(o), 'Luyện tập tùy chọn');
        break;
      }
      case 'practice-one': startSession([byId[t.getAttribute('data-id')]], 'Làm lại 1 câu'); break;
      case 'unwrong': {
        var r = rec(t.getAttribute('data-id'));
        r.wb = false; save();
        SL.toast('Đã gỡ khỏi sổ câu sai.');
        viewWrong();
        break;
      }
      case 'start-exam': {
        var prev = SL.store.get(examKey(bank.id), null);
        if (prev && !window.confirm('Bạn đang có bài thi làm dở. Bỏ bài đó và tạo đề mới?')) return;
        exam = buildExam();
        var nt = document.getElementById('exam-notimer');
        exam.noTimer = !!(nt && nt.checked);
        saveExam();
        go('#/exam/run');
        break;
      }
      case 'resume-exam': exam = SL.store.get(examKey(bank.id), null); go('#/exam/run'); break;
      case 'drop-exam':
        if (window.confirm('Hủy bài thi đang làm dở? Bài này sẽ không được chấm.')) { SL.store.remove(examKey(bank.id)); exam = null; viewHome(); }
        break;
      case 'submit-exam': {
        var un = exam ? exam.ids.filter(function (id, k) { return !isAnswered(byId[id], exam.answers[k]); }).length : 0;
        if (window.confirm(un ? 'Còn ' + un + ' câu chưa làm xong. Vẫn nộp bài?' : 'Nộp bài?')) submitExam();
        break;
      }
      case 'jump': case 'jump-r': {
        ev.preventDefault();
        var target = document.getElementById((act === 'jump' ? 'eq-' : 'rq-') + t.getAttribute('data-k'));
        if (target) target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        break;
      }
      case 'export': exportData(); break;
      case 'reset':
        if (window.confirm('Xóa TOÀN BỘ tiến độ của "' + bank.title + '"? Không thể hoàn tác.\n\nGợi ý: hãy xuất tệp sao lưu trước.')) {
          data = emptyData(); save(); SL.store.remove(examKey(bank.id)); SL.toast('Đã xóa tiến độ.'); viewData();
        }
        break;
    }
  });
  function onAnswerInput(t, key) {
    var v = Number(t.getAttribute('data-v'));
    if (key === 's') {
      var it = session.items[session.i], q = byId[it.id];
      if (it.done) return;
      if (q.type === 'mcq') it.a = v;
      else if (q.type === 'tf') it.a[Number(t.getAttribute('data-i'))] = !!v;
      refreshCard();
    } else if (key && key.charAt(0) === 'e' && exam) {
      var k = Number(key.slice(1)), qq = byId[exam.ids[k]];
      if (qq.type === 'mcq') exam.answers[k] = v;
      else if (qq.type === 'tf') exam.answers[k][Number(t.getAttribute('data-i'))] = !!v;
      saveExam();
      var art = document.getElementById('eq-' + k);
      var head = art.querySelector('.q-meta').outerHTML;
      art.innerHTML = head + renderQuestionBody(qq, { key: key, mode: 'answer', answer: exam.answers[k], perm: exam.perms[k] });
      SL.math(art);
      updateExamNav();
    }
  }
  $app.addEventListener('input', function (ev) {
    var t = ev.target;
    if (t.matches('input[data-act="short"]')) {
      var key = t.getAttribute('data-key');
      if (key === 's') {
        var it = session.items[session.i];
        it.a = t.value;
        var b = document.getElementById('btn-check');
        if (b) b.disabled = !isAnswered(byId[it.id], it.a);
      } else if (exam) {
        var k = Number(key.slice(1));
        exam.answers[k] = t.value;
        saveExam();
        updateExamNav();
      }
    }
  });
  $app.addEventListener('change', function (ev) {
    var t = ev.target;
    if (t.matches('input[data-group]')) {
      t.closest('.chip').classList.toggle('on', t.checked);
      updatePracticeCount();
    } else if (t.id === 'p-n' || t.id === 'p-src') {
      updatePracticeCount();
    } else if (t.id === 'import-file' && t.files && t.files[0]) {
      SL.readFile(t.files[0]).then(importData);
    } else if (/^f-(ch|type|level|status)$/.test(t.id)) {
      bankFilter[t.id.slice(2)] = t.value;
      renderBankList();
    }
  });
  $app.addEventListener('keyup', function (ev) {
    if (ev.target.id === 'f-text') { bankFilter.text = ev.target.value; renderBankList(); }
  });
  document.addEventListener('keydown', function (ev) {
    if (location.hash !== '#/session' || !session || session.i >= session.items.length) return;
    if (ev.ctrlKey || ev.metaKey || ev.altKey) return;
    var it = session.items[session.i], q = byId[it.id];
    var inInput = ev.target.tagName === 'INPUT' || ev.target.tagName === 'TEXTAREA' || ev.target.tagName === 'SELECT';
    if (ev.key === 'Enter') {
      if (ev.target.tagName === 'BUTTON' && !ev.target.matches('#btn-next, #btn-check')) return;
      ev.preventDefault();
      if (it.done) sessionNext(); else sessionCheck();
      return;
    }
    if (inInput || it.done || q.type !== 'mcq') return;
    var map = { '1': 0, '2': 1, '3': 2, '4': 3, a: 0, b: 1, c: 2, d: 3 };
    var pos = map[ev.key.toLowerCase()];
    if (pos != null && pos < it.perm.length) { it.a = it.perm[pos]; refreshCard(); }
  });

  /* ======================== Định tuyến ======================== */
  function setActiveNav() {
    var h = location.hash || '#/';
    document.querySelectorAll('.nav a[href^="#/"]').forEach(function (a) {
      var href = a.getAttribute('href');
      a.classList.toggle('active', href === '#/' ? (h === '#/' || h === '') : h.indexOf(href) === 0);
    });
  }
  function route() {
    var h = location.hash || '#/';
    if (h.indexOf('#/exam/run') !== 0) clearInterval(examTimer);
    setActiveNav();
    if (h === '#/' || h === '') viewHome();
    else if (h === '#/practice') viewPractice();
    else if (h === '#/session') viewSession();
    else if (h === '#/exam') viewExamLobby();
    else if (h === '#/exam/run') viewExamRun();
    else if (h.indexOf('#/exam/result/') === 0) viewExamResult(Number(h.split('/').pop()));
    else if (h === '#/wrong') viewWrong();
    else if (h === '#/bank') viewBank();
    else if (h === '#/data') viewData();
    else if (h.indexOf('#eq-') === 0 || h.indexOf('#rq-') === 0) { /* neo trong trang */ }
    else viewHome();
  }

  function loadBank(id) {
    bank = BANKS[id];
    byId = {}; chapterIdx = {};
    bank.questions.forEach(function (q) { byId[q.id] = q; });
    bank.chapters.forEach(function (c, i) { chapterIdx[c.id] = i; });
    data = loadData(id);
    session = null; exam = null;
    var t = document.getElementById('bank-title');
    if (t) t.textContent = APP.title || bank.title;
    document.title = (APP.title || bank.title) + ' — Ôn thi';
  }

  function init() {
    if (!BANK_IDS.length) { $app.innerHTML = '<div class="card">Không tìm thấy ngân hàng câu hỏi.</div>'; return; }
    var saved = SL.store.get('sl.quiz.lastBank.' + (APP.id || 'default'), BANK_IDS[0]);
    loadBank(BANK_IDS.indexOf(saved) >= 0 ? saved : BANK_IDS[0]);
    var sw = document.getElementById('bank-switch');
    if (sw) {
      if (BANK_IDS.length > 1) {
        sw.innerHTML = BANK_IDS.map(function (id) {
          return '<option value="' + id + '"' + (id === bank.id ? ' selected' : '') + '>' + esc(BANKS[id].short || BANKS[id].title) + '</option>';
        }).join('');
        sw.hidden = false;
        sw.addEventListener('change', function () {
          loadBank(sw.value);
          SL.store.set('sl.quiz.lastBank.' + (APP.id || 'default'), sw.value);
          go('#/');
        });
      } else sw.hidden = true;
    }
    SL.initThemeToggle(document.getElementById('theme-btn'));
    window.addEventListener('hashchange', route);
    route();
  }

  // Xuất một số hàm để kiểm thử tự động
  window.QuizEngine = { evaluate: evaluate, decimals: decimals, INTERVAL: INTERVAL };

  init();
})();
