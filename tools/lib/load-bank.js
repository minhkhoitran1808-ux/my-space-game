// Nạp một tệp ngân hàng câu hỏi (viết cho trình duyệt) vào Node bằng vm.
'use strict';
const fs = require('fs');
const vm = require('vm');
const path = require('path');

function loadBanks(files) {
  const sandbox = { window: {}, console };
  vm.createContext(sandbox);
  for (const f of files) {
    vm.runInContext(fs.readFileSync(path.resolve(f), 'utf8'), sandbox, { filename: f });
  }
  return sandbox.window.QBANKS || {};
}

module.exports = { loadBanks };
