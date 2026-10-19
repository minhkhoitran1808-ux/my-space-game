#!/usr/bin/env node
// Kiểm tra cấu trúc + công thức KaTeX của ngân hàng câu hỏi.
// Cách dùng: node tools/validate-bank.js <tệp-bank.js> [tệp khác...]
'use strict';
const path = require('path');
const { loadBanks } = require('./lib/load-bank');
const katex = require(path.join(__dirname, '../projects/shared/vendor/katex/katex.min.js'));

const MACROS = {
  '\\nuc': '{}^{#1}_{#2}\\mathrm{#3}',
  '\\unit': '\\,\\mathrm{#1}',
  '\\degC': '\\,^{\\circ}\\mathrm{C}'
};

const files = process.argv.slice(2);
if (!files.length) {
  console.error('Thiếu tham số: node tools/validate-bank.js <bank.js>');
  process.exit(2);
}
const banks = loadBanks(files);
// KaTeX in cảnh báo vô hại với chữ Việt trong \text{} — ẩn đi cho gọn
const origWarn = console.warn;
console.warn = (m, ...r) => { if (typeof m === 'string' && m.startsWith('No character metrics')) return; origWarn(m, ...r); };
let errors = 0, warnings = 0, checkedMath = 0;
const err = (id, msg) => { errors++; console.log(`  ✗ [${id}] ${msg}`); };
const warn = (id, msg) => { warnings++; console.log(`  ! [${id}] ${msg}`); };

function checkText(id, field, s) {
  if (typeof s !== 'string' || !s.trim()) { err(id, `${field} rỗng`); return; }
  if (s.includes('undefined')) err(id, `${field} chứa "undefined"`);
  const stripped = s.replace(/\$\$[\s\S]+?\$\$/g, '').replace(/\$[^$]+?\$/g, '');
  if (stripped.includes('$')) err(id, `${field}: dấu $ không cân bằng`);
  const parts = s.match(/\$\$[\s\S]+?\$\$|\$[^$]+?\$/g) || [];
  for (const p of parts) {
    const display = p.startsWith('$$');
    let tex = display ? p.slice(2, -2) : p.slice(1, -1);
    tex = tex.replace(/(\d),(\d)/g, '$1{,}$2');
    try {
      katex.renderToString(tex, { throwOnError: true, strict: false, displayMode: display, macros: { ...MACROS } });
      checkedMath++;
    } catch (e) {
      err(id, `${field}: KaTeX lỗi "${e.message.split('\n')[0]}" trong ${p.slice(0, 60)}`);
    }
  }
  // Lời giải không được nhắc chữ cái phương án vì phương án bị xáo trộn
  if (/([Đđ]áp án|[Pp]hương án|[Cc]họn)\s+[ABCD]\b/.test(s)) warn(id, `${field} nhắc tới chữ cái phương án`);
}

for (const [bid, bank] of Object.entries(banks)) {
  console.log(`\n== Ngân hàng "${bid}" (${bank.questions.length} câu) ==`);
  const chIds = new Set(bank.chapters.map(c => c.id));
  const seen = new Set();
  const count = {};
  for (const q of bank.questions) {
    const id = q.id || '(không id)';
    if (!q.id) err(id, 'thiếu id');
    if (seen.has(q.id)) err(id, 'id trùng');
    seen.add(q.id);
    if (!chIds.has(q.ch)) err(id, `chương không hợp lệ: ${q.ch}`);
    if (![1, 2, 3, 4].includes(q.level)) err(id, `level không hợp lệ: ${q.level}`);
    count[q.ch] = count[q.ch] || { mcq: 0, tf: 0, short: 0 };
    if (count[q.ch][q.type] == null) { err(id, `type không hợp lệ: ${q.type}`); continue; }
    count[q.ch][q.type]++;
    checkText(id, 'q', q.q);
    checkText(id, 'explain', q.explain);
    if (q.tip) checkText(id, 'tip', q.tip);
    if (q.type === 'mcq') {
      if (!Array.isArray(q.choices) || q.choices.length !== 4) err(id, 'mcq cần đúng 4 phương án');
      else {
        q.choices.forEach((c, i) => checkText(id, `choices[${i}]`, c));
        if (new Set(q.choices).size !== q.choices.length) err(id, 'phương án bị trùng');
      }
      if (!Number.isInteger(q.answer) || q.answer < 0 || q.answer >= (q.choices || []).length) err(id, 'answer sai chỉ số');
      if (q.why) {
        if (q.why.length !== q.choices.length) err(id, 'why phải dài bằng choices');
        if (q.why[q.answer]) warn(id, 'why có chú thích ở phương án đúng');
        q.why.forEach((w, i) => { if (w) checkText(id, `why[${i}]`, w); });
      }
    } else if (q.type === 'tf') {
      if (!Array.isArray(q.statements) || q.statements.length !== 4) err(id, 'tf cần đúng 4 ý');
      else q.statements.forEach((st, i) => {
        if (typeof st.a !== 'boolean') err(id, `statements[${i}].a phải là boolean`);
        checkText(id, `statements[${i}].s`, st.s);
        checkText(id, `statements[${i}].e`, st.e);
      });
      const nTrue = (q.statements || []).filter(s => s.a).length;
      if (nTrue === 0 || nTrue === 4) warn(id, `tất cả các ý đều ${nTrue ? 'Đúng' : 'Sai'}`);
    } else if (q.type === 'short') {
      const a = String(q.answer);
      if (a.length > 4) err(id, `đáp án "${a}" dài hơn 4 ký tự (phiếu trả lời chỉ có 4 ô)`);
      if (!/^-?\d+(,\d+)?$/.test(a)) err(id, `đáp án "${a}" phải là số dạng 12 / 0,25 / -1,5 (dấu phẩy thập phân)`);
      if (q.tol != null && !(q.tol >= 0)) err(id, 'tol phải ≥ 0');
    }
  }
  console.log('  Phân bố (chương: trắc nghiệm / Đúng-Sai / trả lời ngắn):');
  for (const c of bank.chapters) {
    const x = count[c.id] || { mcq: 0, tf: 0, short: 0 };
    console.log(`   - ${c.id.padEnd(10)} ${x.mcq} / ${x.tf} / ${x.short}`);
  }
  if (bank.exam) {
    for (const p of bank.exam.parts) {
      const pool = bank.questions.filter(q => q.type === p.type && !q.noExam).length;
      if (pool < p.count) err(bid, `kho ${p.type} có ${pool} câu < ${p.count} câu cần cho một đề`);
    }
    const max = bank.exam.parts.reduce((s, p) => s + p.count * (p.type === 'tf' ? bank.exam.tfScale[bank.exam.tfScale.length - 1] : p.points), 0);
    if (Math.abs(max - (bank.exam.max || 10)) > 1e-9) err(bid, `tổng điểm đề = ${max}, khác ${bank.exam.max || 10}`);
    else console.log(`  Tổng điểm một đề: ${max} ✓`);
  }
}
console.log(`\nĐã render ${checkedMath} công thức. Lỗi: ${errors}. Cảnh báo: ${warnings}.`);
process.exit(errors ? 1 : 0);
