#!/usr/bin/env bash
# Chạy toàn bộ kiểm thử của các dự án trong projects/. Cách dùng: bash tools/run-all-tests.sh
cd "$(dirname "$0")/.." || exit 1
fail=0
run() { echo; echo "▶ $*"; out=$("$@" 2>&1); code=$?; echo "$out" | grep -E "✗|Kết quả|Lỗi:" | tail -5; [ $code -ne 0 ] && fail=$((fail+1)); }
run node tools/validate-bank.js projects/01-on-thi-vat-ly-12/banks/vatly12.js
run node tools/validate-bank.js projects/06-on-thi-toan-vact/banks/toan12.js projects/06-on-thi-toan-vact/banks/vact.js
run node tools/verify-vatly12.js
run node tools/verify-toan-vact.js
run node tools/test-orbit.js
run node tools/test-labs.js
run node tools/test-quiz.js projects/01-on-thi-vat-ly-12/index.html
run node tools/test-quiz.js projects/06-on-thi-toan-vact/index.html
run node tools/test-orbit-ui.js
run node tools/test-formulas.js
run node tools/test-labs-ui.js
run node tools/test-dash.js
run node tools/test-hub.js
echo
[ $fail -eq 0 ] && echo "TẤT CẢ ĐẠT" || echo "CÓ $fail BỘ KIỂM THỬ LỖI"
exit $fail
