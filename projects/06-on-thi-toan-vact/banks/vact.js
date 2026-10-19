/* ==========================================================================
   Ngân hàng Tư duy V-ACT (luyện kiểu câu: logic, phân tích số liệu,
   suy luận khoa học, toán ứng dụng). Mọi số liệu bảng đều là GIẢ ĐỊNH để luyện tập.
   Đáp án được kiểm bằng tools/verify-toan-vact.js
   ========================================================================== */
(function () {
  var R = String.raw;

  var TABLE_SOLAR = '<table class="table" style="width:auto"><caption class="small muted" style="caption-side:top;text-align:left">Sản lượng điện của 3 trạm điện mặt trời (MWh) — số liệu giả định</caption>' +
    '<thead><tr><th>Trạm</th><th>Tháng 1</th><th>Tháng 2</th><th>Tháng 3</th><th>Tháng 4</th></tr></thead><tbody>' +
    '<tr><td>A</td><td>120</td><td>135</td><td>150</td><td>165</td></tr>' +
    '<tr><td>B</td><td>140</td><td>130</td><td>160</td><td>150</td></tr>' +
    '<tr><td>C</td><td>100</td><td>125</td><td>145</td><td>170</td></tr></tbody></table>';
  var TABLE_PAPER = '<table class="table" style="width:auto"><caption class="small muted" style="caption-side:top;text-align:left">Kết quả thí nghiệm (giả định)</caption>' +
    '<thead><tr><th>Đường kính tấm giấy (cm)</th><th>5</th><th>10</th><th>15</th><th>20</th></tr></thead><tbody>' +
    '<tr><td>Thời gian rơi trung bình (s)</td><td>0,9</td><td>1,3</td><td>1,6</td><td>1,9</td></tr></tbody></table>';
  var PAPER_INTRO = R`Một nhóm học sinh thả rơi các tấm giấy tròn cắt từ **cùng một loại giấy**, có đường kính khác nhau, từ **cùng độ cao 2 m** trong phòng kín gió; mỗi tấm thả 5 lần rồi lấy thời gian trung bình.`;
  var TABLE_BOIL = '<table class="table" style="width:auto"><caption class="small muted" style="caption-side:top;text-align:left">Nhiệt độ sôi của nước theo độ cao (giá trị gần đúng)</caption>' +
    '<thead><tr><th>Độ cao so với mực nước biển (m)</th><th>0</th><th>1500</th><th>3000</th></tr></thead><tbody>' +
    '<tr><td>Nhiệt độ sôi (°C)</td><td>100</td><td>≈ 95</td><td>≈ 90</td></tr></tbody></table>';

  var chapters = [
    { id: 'logic', title: 'Suy luận logic', short: 'Logic' },
    { id: 'solieu', title: 'Phân tích số liệu', short: 'Số liệu' },
    { id: 'khoahoc', title: 'Suy luận khoa học', short: 'Khoa học' },
    { id: 'ungdung', title: 'Toán ứng dụng', short: 'Ứng dụng' }
  ];
  var Q = [];
  function add(ch, list) { list.forEach(function (q) { q.ch = ch; q.type = 'mcq'; Q.push(q); }); }

  add('logic', [
    { id: 'va-l1', level: 1, q: R`"Nếu trời mưa thì mặt đường ướt." Quan sát thấy mặt đường **không** ướt. Kết luận nào chắc chắn đúng?`,
      choices: [R`Trời không mưa.`, R`Trời mưa.`, R`Không kết luận được gì.`, R`Mặt đường đã được lau khô.`], answer: 0,
      explain: R`Từ "Nếu P thì Q" và "không Q" suy ra "không P" (phép phản đảo). Nếu trời mưa thì đường phải ướt; đường không ướt nên trời không mưa.` },
    { id: 'va-l2', level: 1, q: R`Phủ định của mệnh đề "Mọi học sinh lớp 12A đều thích Toán" là`,
      choices: [R`Có ít nhất một học sinh lớp 12A không thích Toán.`, R`Mọi học sinh lớp 12A đều không thích Toán.`, R`Không có học sinh nào lớp 12A thích Toán.`, R`Có ít nhất một học sinh lớp 12A thích Toán.`], answer: 0,
      explain: R`Phủ định của "mọi … đều P" là "tồn tại … không P". Hai phương án "mọi … không" / "không có ai" là phát biểu quá mạnh.` },
    { id: 'va-l3', level: 2, q: R`Ba bạn An, Bình, Chi mỗi người học một ngành khác nhau trong ba ngành: Hàng không, Y, Luật. Biết: (1) An không học Y; (2) Bình không học Hàng không; (3) người học Luật không phải An, cũng không phải Bình. Bình học ngành gì?`,
      choices: [R`Y`, R`Hàng không`, R`Luật`, R`Không xác định được`], answer: 0,
      explain: R`Từ (3): Chi học Luật. Khi đó An học Hàng không hoặc Y; theo (1) An không học Y ⇒ An học Hàng không ⇒ Bình học Y (phù hợp với (2)).` },
    { id: 'va-l4', level: 2, q: R`Tìm số tiếp theo của dãy: 2, 6, 12, 20, 30, …`,
      choices: [R`42`, R`40`, R`36`, R`44`], answer: 0,
      explain: R`Hiệu liên tiếp là 4, 6, 8, 10 ⇒ hiệu tiếp theo là 12 ⇒ $30 + 12 = 42$. (Công thức: $a_n = n(n+1)$.)` },
    { id: 'va-l5', level: 3, q: R`Cho hai tiền đề: "Mọi kỹ sư hàng không đều học cơ học chất lưu" và "Một số người học cơ học chất lưu là nhà khí tượng học". Phát biểu nào **chắc chắn** đúng?`,
      choices: [R`Nếu An là kỹ sư hàng không thì An học cơ học chất lưu.`, R`Một số kỹ sư hàng không là nhà khí tượng học.`, R`Mọi nhà khí tượng học đều là kỹ sư hàng không.`, R`Không có kỹ sư hàng không nào là nhà khí tượng học.`], answer: 0,
      explain: R`Chỉ phương án áp dụng trực tiếp tiền đề 1 là chắc chắn đúng. Tiền đề 2 không cho biết những nhà khí tượng học đó có phải kỹ sư hàng không hay không, nên cả "một số là" lẫn "không ai là" đều **không suy ra được**.`,
      tip: R`Câu hỏi "chắc chắn đúng": loại mọi phương án chỉ "có thể đúng".` },
    { id: 'va-l6', level: 2, q: R`Ngày 19/10/2026 là thứ Hai. Ngày 19/10/2027 là thứ mấy?`,
      choices: [R`Thứ Ba`, R`Thứ Hai`, R`Thứ Tư`, R`Chủ nhật`], answer: 0,
      why: [null, null, R`Coi nhầm năm 2027 là năm nhuận (366 ngày).`, null],
      explain: R`Từ 19/10/2026 đến 19/10/2027 có 365 ngày (tháng 2/2027 có 28 ngày). $365 = 52\cdot7 + 1$ ⇒ thứ trong tuần tiến thêm 1: thứ Hai → thứ Ba.` }
  ]);

  add('solieu', [
    { id: 'va-d1', level: 1, q: R`Dựa vào bảng, tổng sản lượng 4 tháng của trạm nào lớn nhất?`, fig: TABLE_SOLAR,
      choices: [R`Trạm B`, R`Trạm A`, R`Trạm C`, R`Ba trạm bằng nhau`], answer: 0,
      explain: R`A: $120 + 135 + 150 + 165 = 570$; B: $140 + 130 + 160 + 150 = 580$; C: $100 + 125 + 145 + 170 = 540$ ⇒ B lớn nhất.`,
      tip: R`Trạm A tăng đều và C có tháng 4 cao nhất, dễ khiến chọn nhầm; phải cộng đủ 4 tháng.` },
    { id: 'va-d2', level: 2, q: R`Dựa vào bảng, sản lượng của trạm C tăng bao nhiêu phần trăm từ tháng 1 đến tháng 4?`, fig: TABLE_SOLAR,
      choices: [R`70 %`, R`41 %`, R`7 %`, R`170 %`], answer: 0,
      why: [null, R`Chia cho giá trị tháng 4 thay vì tháng 1: $70/170$.`, null, R`Đây là tỉ số tháng 4 so với tháng 1, không phải mức tăng.`],
      explain: R`$\dfrac{170 - 100}{100}\cdot100\,\% = 70\,\%$.` },
    { id: 'va-d3', level: 2, q: R`Dựa vào bảng, nếu trạm A giữ nguyên xu hướng tăng như 4 tháng đầu thì sản lượng tháng 5 dự kiến là`, fig: TABLE_SOLAR,
      choices: [R`180 MWh`, R`170 MWh`, R`195 MWh`, R`165 MWh`], answer: 0,
      explain: R`Trạm A tăng đều 15 MWh mỗi tháng ⇒ tháng 5: $165 + 15 = 180$ MWh.` },
    { id: 'va-d4', level: 1, q: R`Dựa vào bảng, tháng nào có tổng sản lượng của cả ba trạm lớn nhất?`, fig: TABLE_SOLAR,
      choices: [R`Tháng 4`, R`Tháng 3`, R`Tháng 2`, R`Tháng 1`], answer: 0,
      explain: R`Tháng 1: 360; tháng 2: 390; tháng 3: 455; tháng 4: 485.` },
    { id: 'va-d5', level: 3, q: R`Dựa vào bảng, trong tháng 3, trạm B chiếm khoảng bao nhiêu phần trăm tổng sản lượng của ba trạm?`, fig: TABLE_SOLAR,
      choices: [R`35,2 %`, R`33,3 %`, R`27,6 %`, R`40,0 %`], answer: 0,
      explain: R`$\dfrac{160}{150 + 160 + 145} = \dfrac{160}{455} \approx 35{,}2\,\%$.` },
    { id: 'va-d6', level: 3, q: R`Dựa vào bảng, trạm nào có sản lượng **không** tăng liên tục qua các tháng?`, fig: TABLE_SOLAR,
      choices: [R`Chỉ trạm B`, R`Chỉ trạm C`, R`Trạm A và B`, R`Cả ba trạm đều tăng liên tục`], answer: 0,
      explain: R`B giảm ở tháng 2 (140 → 130) và tháng 4 (160 → 150). A và C tăng mỗi tháng.` }
  ]);

  add('khoahoc', [
    { id: 'va-k1', level: 1, q: PAPER_INTRO + R` Biến độc lập (biến được chủ động thay đổi) trong thí nghiệm là`, fig: TABLE_PAPER,
      choices: [R`đường kính tấm giấy.`, R`thời gian rơi.`, R`độ cao thả.`, R`loại giấy.`], answer: 0,
      explain: R`Người làm thí nghiệm chủ động thay đổi đường kính; thời gian rơi là **biến phụ thuộc** (đo được); độ cao và loại giấy là **biến được kiểm soát** (giữ không đổi).` },
    { id: 'va-k2', level: 2, q: PAPER_INTRO + R` Vì sao mỗi tấm được thả 5 lần rồi lấy trung bình?`, fig: TABLE_PAPER,
      choices: [R`Để giảm ảnh hưởng của sai số ngẫu nhiên khi đo.`, R`Để tấm giấy rơi nhanh hơn.`, R`Để thay đổi biến độc lập.`, R`Để loại bỏ hoàn toàn sai số hệ thống.`], answer: 0,
      explain: R`Lặp lại và lấy trung bình làm giảm sai số **ngẫu nhiên** (phản xạ bấm đồng hồ, luồng khí nhỏ…). Nó **không** loại được sai số hệ thống (ví dụ đồng hồ chạy sai).` },
    { id: 'va-k3', level: 2, q: PAPER_INTRO + R` Kết luận nào phù hợp nhất với số liệu?`, fig: TABLE_PAPER,
      choices: [R`Trong phạm vi khảo sát, tấm giấy có đường kính càng lớn thì rơi càng lâu.`, R`Thời gian rơi tỉ lệ thuận với đường kính.`, R`Vật càng nặng thì rơi càng nhanh.`, R`Lực cản của không khí không phụ thuộc kích thước vật.`], answer: 0,
      why: [null, R`Đường kính tăng 4 lần (5 → 20 cm) nhưng thời gian chỉ tăng khoảng 2,1 lần ⇒ không tỉ lệ thuận.`, R`Tấm lớn nặng hơn nhưng lại rơi **lâu** hơn — mâu thuẫn số liệu.`, null],
      explain: R`Số liệu cho thấy xu hướng tăng nhưng không tỉ lệ thuận. Tấm lớn chịu lực cản không khí lớn hơn (diện tích lớn) so với trọng lượng tăng thêm, nên rơi chậm hơn.` },
    { id: 'va-k4', level: 3, q: PAPER_INTRO + R` Dự đoán hợp lý nhất cho thời gian rơi của tấm giấy đường kính 25 cm là`, fig: TABLE_PAPER,
      choices: [R`khoảng 2,2 s`, R`khoảng 1,9 s`, R`khoảng 0,5 s`, R`khoảng 4,5 s`], answer: 0,
      explain: R`Mỗi lần tăng 5 cm, thời gian tăng 0,4 → 0,3 → 0,3 s ⇒ ngoại suy tăng thêm khoảng 0,3 s: $\approx 2{,}2$ s. (Ngoại suy chỉ đáng tin khi xu hướng không đổi.)` },
    { id: 'va-k5', level: 2, q: R`Dựa vào bảng, giải thích nào đúng nhất cho việc nước sôi ở nhiệt độ thấp hơn khi lên cao?`, fig: TABLE_BOIL,
      choices: [R`Càng lên cao áp suất khí quyển càng giảm, nên nước sôi ở nhiệt độ thấp hơn.`, R`Càng lên cao nhiệt độ không khí càng thấp nên nước khó sôi hơn.`, R`Càng lên cao lực hấp dẫn càng giảm mạnh.`, R`Nước trên núi chứa ít muối khoáng hơn.`], answer: 0,
      explain: R`Nước sôi khi áp suất hơi bão hòa bằng áp suất bên ngoài. Áp suất khí quyển giảm theo độ cao ⇒ điều kiện này đạt được ở nhiệt độ thấp hơn. Vì vậy nấu ăn trên núi cao cần nồi áp suất.` },
    { id: 'va-k6', level: 2, q: R`Một bạn đưa ra giả thuyết: "Cây đậu mọc nhanh hơn khi được nghe nhạc." Thiết kế thí nghiệm nào kiểm tra giả thuyết này tốt nhất?`,
      choices: [R`Trồng hai nhóm cây đậu giống nhau, cùng đất, nước, ánh sáng; chỉ một nhóm được nghe nhạc; đo chiều cao sau 2 tuần.`,
        R`Trồng một cây đậu, cho nghe nhạc và đo chiều cao mỗi ngày.`,
        R`Trồng một nhóm cây nghe nhạc ngoài nắng và một nhóm không nghe nhạc trong bóng râm.`,
        R`Hỏi ý kiến những người trồng đậu lâu năm.`], answer: 0,
      explain: R`Cần **nhóm đối chứng** và chỉ thay đổi **một** yếu tố (nghe nhạc). Phương án "ngoài nắng / bóng râm" thay đổi hai yếu tố cùng lúc nên không biết yếu tố nào gây ra khác biệt.` }
  ]);

  add('ungdung', [
    { id: 'va-u1', level: 2, q: R`Gửi 100 triệu đồng vào ngân hàng với lãi suất 6 %/năm, lãi nhập gốc mỗi năm. Sau 2 năm, tổng số tiền nhận được là`,
      choices: [R`112,36 triệu đồng`, R`112 triệu đồng`, R`106 triệu đồng`, R`136 triệu đồng`], answer: 0,
      why: [null, R`Đây là lãi đơn (không nhập gốc).`, null, null],
      explain: R`$100\cdot(1 + 0{,}06)^2 = 112{,}36$ triệu đồng.` },
    { id: 'va-u2', level: 3, q: R`Một xe đi từ A đến B dài 120 km với tốc độ 60 km/h, rồi quay về A với tốc độ 40 km/h. Tốc độ trung bình trên cả quãng đường đi và về là`,
      choices: [R`48 km/h`, R`50 km/h`, R`45 km/h`, R`52 km/h`], answer: 0,
      why: [null, R`Lấy trung bình cộng hai tốc độ — chỉ đúng khi thời gian đi bằng thời gian về.`, null, null],
      explain: R`Thời gian: $2 + 3 = 5$ h; quãng đường: 240 km ⇒ $v_{tb} = 48$ km/h.` },
    { id: 'va-u3', level: 1, q: R`Trên bản đồ tỉ lệ 1 : 50 000, đoạn thẳng dài 4 cm ứng với khoảng cách thực tế là`,
      choices: [R`2 km`, R`20 km`, R`200 m`, R`12,5 km`], answer: 0,
      explain: R`$4\cdot50\,000 = 200\,000$ cm $= 2$ km.` },
    { id: 'va-u4', level: 2, q: R`Chọn ngẫu nhiên 2 người từ nhóm 5 người A, B, C, D, E. Xác suất để A được chọn là`,
      choices: [R`$\dfrac25$`, R`$\dfrac15$`, R`$\dfrac12$`, R`$\dfrac{1}{10}$`], answer: 0,
      explain: R`Có $C_5^2 = 10$ cách chọn; số cách có A: chọn thêm 1 trong 4 người còn lại = 4 ⇒ $\dfrac{4}{10} = \dfrac25$.` },
    { id: 'va-u5', level: 1, q: R`Một bể nước hình hộp chữ nhật có kích thước trong lòng 2 m × 1,5 m × 1 m, chứa đầy nước. Bể chứa bao nhiêu lít nước?`,
      choices: [R`3000 lít`, R`300 lít`, R`30 000 lít`, R`4,5 lít`], answer: 0,
      explain: R`$V = 2\cdot1{,}5\cdot1 = 3\ \mathrm{m^3} = 3000$ lít (vì $1\ \mathrm{m^3} = 1000$ lít).` },
    { id: 'va-u6', level: 3, q: R`Giá một chiếc máy tính tăng 20 % rồi sau đó giảm 20 %. So với giá ban đầu, giá cuối cùng`,
      choices: [R`giảm 4 %`, R`không đổi`, R`tăng 4 %`, R`giảm 2 %`], answer: 0,
      why: [null, R`Hai lần 20 % tính trên hai giá trị khác nhau nên không triệt tiêu.`, null, null],
      explain: R`$1{,}2\cdot0{,}8 = 0{,}96$ ⇒ giảm 4 %.` }
  ]);

  window.QBANKS = window.QBANKS || {};
  window.QBANKS.vact = {
    id: 'vact', title: 'Tư duy V-ACT', short: 'Tư duy V-ACT', version: '1.0 (10/2026)',
    subtitle: 'Luyện kiểu câu suy luận logic, phân tích số liệu, suy luận khoa học và toán ứng dụng (toàn bộ là trắc nghiệm).',
    chapters: chapters, questions: Q,
    exam: {
      minutes: 30, max: 10,
      parts: [{ type: 'mcq', count: 20, points: 0.5 }],
      note: 'Đây là **đề luyện ngắn** (20 câu/30 phút, chấm thang 10), không phải cấu trúc đề thật. Theo hiểu biết của người soạn, đề V-ACT gồm khoảng 120 câu trắc nghiệm trong 150 phút với các phần Sử dụng ngôn ngữ, Toán học, Tư duy khoa học — **cần xác minh** cấu trúc năm 2027 trên trang chính thức của ĐHQG-HCM.'
    },
    notes: 'Bảng số liệu trong các câu là **giả định** để luyện kỹ năng đọc số liệu (trừ bảng nhiệt độ sôi theo độ cao — giá trị gần đúng thực tế). Đáp án được kiểm tự động bằng `tools/verify-toan-vact.js`.'
  };
})();
