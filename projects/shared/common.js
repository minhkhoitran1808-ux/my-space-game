/* ==========================================================================
   Tiện ích dùng chung (namespace SL = "Study Lab").
   Script cổ điển (không phải module) để chạy được khi mở bằng file://.
   ========================================================================== */
(function () {
  'use strict';

  var SL = window.SL || {};

  /* ---------- localStorage an toàn ---------- */
  SL.store = {
    get: function (key, fallback) {
      try {
        var raw = window.localStorage.getItem(key);
        return raw == null ? fallback : JSON.parse(raw);
      } catch (e) {
        return fallback;
      }
    },
    set: function (key, value) {
      try {
        window.localStorage.setItem(key, JSON.stringify(value));
        return true;
      } catch (e) {
        return false;
      }
    },
    remove: function (key) {
      try { window.localStorage.removeItem(key); } catch (e) { /* bỏ qua */ }
    },
    keys: function (prefix) {
      var out = [];
      try {
        for (var i = 0; i < window.localStorage.length; i++) {
          var k = window.localStorage.key(i);
          if (!prefix || k.indexOf(prefix) === 0) out.push(k);
        }
      } catch (e) { /* bỏ qua */ }
      return out;
    }
  };

  /* ---------- Escape HTML cho dữ liệu người dùng nhập ---------- */
  SL.esc = function (s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  };

  /* ---------- Định dạng nội dung soạn sẵn (tin cậy) ----------
     - $...$ và $$...$$: công thức KaTeX (dấu phẩy thập phân tự sửa thành {,})
     - **đậm**, `mã`, xuống dòng \n, đoạn mới \n\n
     - Cho phép HTML trực tiếp (nội dung do mình soạn, không phải người dùng nhập). */
  SL.fixMathCommas = function (tex) {
    return tex.replace(/(\d),(\d)/g, '$1{,}$2');
  };
  SL.fmt = function (s) {
    if (s == null) return '';
    s = String(s);
    // Tách phần công thức để không xử lý markdown bên trong
    var parts = s.split(/(\$\$[\s\S]+?\$\$|\$[^$]+?\$)/g);
    var out = parts.map(function (p) {
      if (p.charAt(0) === '$' && p.length > 1) return SL.fixMathCommas(p);
      return p
        .replace(/`([^`]+)`/g, '<code>$1</code>')
        .replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>')
        .replace(/\n\n+/g, '</p><p>')
        .replace(/\n/g, '<br>');
    }).join('');
    return out;
  };
  SL.fmtBlock = function (s) {
    return '<p>' + SL.fmt(s) + '</p>';
  };

  /* ---------- KaTeX ---------- */
  SL.katexMacros = {
    '\\nuc': '{}^{#1}_{#2}\\mathrm{#3}',
    '\\unit': '\\,\\mathrm{#1}',
    '\\degC': '\\,^{\\circ}\\mathrm{C}'
  };
  SL.math = function (el) {
    if (!el || typeof window.renderMathInElement !== 'function') return;
    // KaTeX cảnh báo "No character metrics" với chữ Việt có dấu trong \text{};
    // chữ vẫn hiển thị đúng bằng phông hệ thống nên bỏ qua riêng cảnh báo này.
    var warn = console.warn;
    console.warn = function (m) {
      if (typeof m === 'string' && m.indexOf('No character metrics') === 0) return;
      warn.apply(console, arguments);
    };
    try {
      window.renderMathInElement(el, {
        delimiters: [
          { left: '$$', right: '$$', display: true },
          { left: '$', right: '$', display: false }
        ],
        macros: SL.katexMacros,
        throwOnError: false,
        strict: false,
        ignoredTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code', 'input']
      });
    } catch (e) {
      warn.call(console, 'KaTeX lỗi:', e);
    } finally {
      console.warn = warn;
    }
  };

  /* ---------- Số kiểu Việt Nam ---------- */
  SL.num = function (x, digits) {
    if (x == null || isNaN(x)) return '—';
    var d = digits == null ? 2 : digits;
    var s = Number(x).toFixed(d);
    if (d > 0) s = s.replace(/\.?0+$/, '');
    return s.replace('.', ',');
  };
  SL.parseNum = function (s) {
    if (s == null) return NaN;
    var t = String(s).trim().replace(/\s+/g, '').replace(',', '.');
    if (!/^[-+]?(\d+\.?\d*|\.\d+)$/.test(t)) return NaN;
    return parseFloat(t);
  };
  SL.pct = function (a, b) { return b ? Math.round((100 * a) / b) : 0; };

  /* ---------- Thời gian ---------- */
  SL.DAY = 86400000;
  SL.today = function () {
    var d = new Date();
    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
  };
  SL.dateVN = function (ts) {
    var d = new Date(ts);
    return String(d.getDate()).padStart(2, '0') + '/' + String(d.getMonth() + 1).padStart(2, '0') + '/' + d.getFullYear();
  };
  SL.timeVN = function (ts) {
    var d = new Date(ts);
    return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
  };
  SL.mmss = function (sec) {
    sec = Math.max(0, Math.round(sec));
    var m = Math.floor(sec / 60), s = sec % 60;
    return String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
  };

  /* ---------- Ngẫu nhiên ---------- */
  SL.shuffle = function (arr) {
    var a = arr.slice();
    for (var i = a.length - 1; i > 0; i--) {
      var j = Math.floor(Math.random() * (i + 1));
      var t = a[i]; a[i] = a[j]; a[j] = t;
    }
    return a;
  };

  /* ---------- Canvas sắc nét theo mật độ điểm ảnh ----------
     Trả về false nếu canvas đang ẩn (chưa có kích thước). */
  SL.fitCanvas = function (cv) {
    var dpr = Math.min(window.devicePixelRatio || 1, 2);
    var r = cv.getBoundingClientRect();
    if (!r.width || !r.height) return false;
    var w = Math.round(r.width * dpr), h = Math.round(r.height * dpr);
    if (cv.width !== w || cv.height !== h) { cv.width = w; cv.height = h; }
    cv._dpr = dpr;
    return true;
  };
  SL.cssVar = function (name, fallback) {
    var v = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
    return v || fallback;
  };

  /* ---------- Thông báo nhỏ ---------- */
  var toastTimer = null;
  SL.toast = function (msg, ms) {
    var el = document.querySelector('.toast');
    if (!el) {
      el = document.createElement('div');
      el.className = 'toast';
      el.setAttribute('role', 'status');
      document.body.appendChild(el);
    }
    el.textContent = msg;
    el.style.display = 'block';
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { el.style.display = 'none'; }, ms || 2400);
  };

  /* ---------- Tải xuống / đọc tệp ---------- */
  SL.download = function (filename, text, mime) {
    var blob = new Blob([text], { type: mime || 'application/json' });
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    setTimeout(function () { URL.revokeObjectURL(a.href); a.remove(); }, 500);
  };
  SL.readFile = function (file) {
    return new Promise(function (resolve, reject) {
      var r = new FileReader();
      r.onload = function () { resolve(String(r.result)); };
      r.onerror = function () { reject(r.error); };
      r.readAsText(file);
    });
  };

  /* ---------- Giao diện sáng/tối ---------- */
  SL.THEME_KEY = 'sl.theme';
  SL.applyTheme = function (mode) {
    var root = document.documentElement;
    if (mode === 'light' || mode === 'dark') root.setAttribute('data-theme', mode);
    else root.removeAttribute('data-theme');
  };
  SL.initThemeToggle = function (btn) {
    var modes = ['auto', 'light', 'dark'];
    var labels = { auto: '◐ Tự động', light: '☀ Sáng', dark: '☾ Tối' };
    var mode = SL.store.get(SL.THEME_KEY, 'auto');
    SL.applyTheme(mode);
    if (!btn) return;
    btn.textContent = labels[mode] || labels.auto;
    btn.title = 'Đổi giao diện sáng/tối';
    btn.addEventListener('click', function () {
      mode = modes[(modes.indexOf(mode) + 1) % modes.length];
      SL.store.set(SL.THEME_KEY, mode);
      SL.applyTheme(mode);
      btn.textContent = labels[mode];
    });
  };
  // Áp dụng sớm để tránh nháy màu
  SL.applyTheme(SL.store.get(SL.THEME_KEY, 'auto'));

  window.SL = SL;
})();
