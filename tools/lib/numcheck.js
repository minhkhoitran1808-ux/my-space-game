// Tiện ích so sánh số cho các script kiểm đáp án.
'use strict';

// Đọc số từ chuỗi kiểu "6,21\cdot10^{-21}\unit{J}" / "$22,8\degC$" / "672 kJ"
function parseNumber(s) {
  const t = String(s).replace(/\$/g, '').replace(/\\,/g, '').replace(/\s+/g, ' ');
  const m = t.match(/(-?\d+(?:[.,]\d+)?)(?:\s*\\cdot\s*10\^\{?(-?\d+)\}?)?/);
  if (!m) return NaN;
  let v = parseFloat(m[1].replace(',', '.'));
  if (m[2]) v *= Math.pow(10, parseInt(m[2], 10));
  return v;
}

function close(a, b, rel) {
  if (b === 0) return Math.abs(a) < 1e-12;
  return Math.abs(a - b) / Math.abs(b) <= rel;
}

// Đáp án ngắn (chuỗi) có đúng là giá trị v đã làm tròn đúng cách không?
function isCorrectRounding(answerStr, v) {
  const t = String(answerStr).replace(',', '.');
  const i = t.indexOf('.');
  const d = i < 0 ? 0 : t.length - i - 1;
  return Math.abs(v - parseFloat(t)) <= 0.5 * Math.pow(10, -d) + 1e-9;
}

module.exports = { parseNumber, close, isCorrectRounding };
