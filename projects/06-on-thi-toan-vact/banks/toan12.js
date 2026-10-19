/* ==========================================================================
   Ngân hàng câu hỏi Toán 12 — Chương trình GDPT 2018 (định dạng như vatly12.js)
   Mọi đáp số được tính lại bằng tools/verify-toan-vact.js
   ========================================================================== */
(function () {
  var R = String.raw;

  var TABLE_STUDY = '<table class="table" style="width:auto"><thead><tr><th>Thời gian (phút)</th><th>[0; 30)</th><th>[30; 60)</th><th>[60; 90)</th><th>[90; 120)</th><th>[120; 150)</th></tr></thead>' +
    '<tbody><tr><td>Số học sinh</td><td>5</td><td>12</td><td>15</td><td>6</td><td>2</td></tr></tbody></table>';
  var STUDY_INTRO = R`Thời gian tự học mỗi ngày của 40 học sinh lớp 12 được cho trong bảng (mẫu số liệu ghép nhóm). Dùng giá trị đại diện là trung điểm mỗi nhóm.`;

  var chapters = [
    { id: 'daoham', title: 'Ứng dụng đạo hàm & khảo sát hàm số', short: 'Đạo hàm' },
    { id: 'tichphan', title: 'Nguyên hàm & tích phân', short: 'Tích phân' },
    { id: 'oxyz', title: 'Vectơ & tọa độ trong không gian', short: 'Oxyz' },
    { id: 'thongke', title: 'Số đặc trưng đo độ phân tán (ghép nhóm)', short: 'Thống kê' },
    { id: 'xacsuat', title: 'Xác suất có điều kiện', short: 'Xác suất' }
  ];
  var Q = [];
  function add(ch, list) { list.forEach(function (q) { q.ch = ch; Q.push(q); }); }

  /* ======================= ĐẠO HÀM ======================= */
  add('daoham', [
    { id: 'dh-01', type: 'mcq', level: 1,
      q: R`Hàm số $y = x^3 - 3x^2 + 2$ nghịch biến trên khoảng nào?`,
      choices: [R`$(0; 2)$`, R`$(-\infty; 0)$`, R`$(2; +\infty)$`, R`$(-2; 0)$`], answer: 0,
      explain: R`$y' = 3x^2 - 6x = 3x(x - 2) < 0 \Leftrightarrow 0 < x < 2$. Hàm nghịch biến trên $(0; 2)$.` },
    { id: 'dh-02', type: 'mcq', level: 2,
      q: R`Hàm số $y = x^4 - 2x^2 + 3$ có bao nhiêu điểm cực trị?`,
      choices: [R`1`, R`2`, R`3`, R`0`], answer: 2,
      explain: R`$y' = 4x^3 - 4x = 4x(x-1)(x+1)$ có 3 nghiệm đơn $x = -1, 0, 1$, $y'$ đổi dấu qua cả ba ⇒ **3** điểm cực trị (2 cực tiểu, 1 cực đại).` },
    { id: 'dh-03', type: 'mcq', level: 2,
      q: R`Giá trị lớn nhất của hàm số $y = -x^2 + 4x - 1$ trên đoạn $[0; 3]$ là`,
      choices: [R`3`, R`2`, R`$-1$`, R`4`], answer: 0,
      why: [null, R`Đây là $y(3)$ — chưa xét điểm tới hạn $x = 2$.`, R`Đây là giá trị nhỏ nhất $y(0)$.`, null],
      explain: R`$y' = -2x + 4 = 0 \Leftrightarrow x = 2 \in [0; 3]$. So sánh: $y(0) = -1$, $y(2) = 3$, $y(3) = 2$ ⇒ $\max = 3$ tại $x = 2$.` },
    { id: 'dh-04', type: 'mcq', level: 1,
      q: R`Đồ thị hàm số $y = \dfrac{2x - 1}{x + 1}$ có tiệm cận đứng và tiệm cận ngang lần lượt là`,
      choices: [R`$x = -1$ và $y = 2$`, R`$x = 1$ và $y = 2$`, R`$x = -1$ và $y = -1$`, R`$x = 2$ và $y = -1$`], answer: 0,
      explain: R`Mẫu bằng 0 khi $x = -1$ (tử $= -3 \ne 0$) ⇒ TCĐ $x = -1$. $\lim_{x\to\pm\infty} y = \dfrac{2}{1} = 2$ ⇒ TCN $y = 2$.` },
    { id: 'dh-05', type: 'mcq', level: 2,
      q: R`Giá trị cực tiểu của hàm số $y = x^3 - 3x + 1$ là`,
      choices: [R`$-1$`, R`3`, R`1`, R`$-3$`], answer: 0,
      why: [null, R`Đây là giá trị **cực đại** (tại $x = -1$).`, R`Đây là hoành độ điểm cực tiểu, không phải giá trị cực tiểu.`, null],
      explain: R`$y' = 3x^2 - 3 = 0 \Leftrightarrow x = \pm1$. $y'' = 6x$: $y''(1) = 6 > 0$ ⇒ cực tiểu tại $x = 1$, $y_{CT} = 1 - 3 + 1 = -1$.`,
      tip: R`Phân biệt **điểm cực tiểu** ($x_{CT}$) và **giá trị cực tiểu** ($y_{CT}$).` },
    { id: 'dh-06', type: 'mcq', level: 3,
      q: R`Một tên lửa mô hình bay thẳng đứng, độ cao $h(t) = -5t^2 + 40t$ (mét, $t$ tính bằng giây). Độ cao lớn nhất tên lửa đạt được là`,
      choices: [R`80 m`, R`40 m`, R`160 m`, R`4 m`], answer: 0,
      why: [null, null, null, R`Đây là thời điểm đạt độ cao lớn nhất ($t = 4$ s), không phải độ cao.`],
      explain: R`$h'(t) = -10t + 40 = 0 \Leftrightarrow t = 4$ s. $h(4) = -80 + 160 = 80$ m. (Vận tốc $v = h'$ bằng 0 ở đỉnh — liên hệ Vật lý: ném thẳng đứng với $v_0 = 40$ m/s, $g = 10$ m/s².)` },
    { id: 'dh-tf1', type: 'tf', level: 3,
      q: R`Cho hàm số $f(x) = x^3 - 3x^2 - 9x + 5$.`,
      statements: [
        { s: R`$f'(x) = 3x^2 - 6x - 9$.`, a: true, e: R`Đạo hàm từng hạng tử.` },
        { s: R`Hàm số đồng biến trên khoảng $(-1; 3)$.`, a: false, e: R`$f'(x) = 3(x+1)(x-3) < 0$ trên $(-1; 3)$ ⇒ hàm **nghịch** biến.` },
        { s: R`Hàm số đạt cực đại tại $x = -1$ và giá trị cực đại bằng 10.`, a: true, e: R`$f'$ đổi dấu từ $+$ sang $-$ qua $x = -1$; $f(-1) = -1 - 3 + 9 + 5 = 10$.` },
        { s: R`Giá trị nhỏ nhất của $f$ trên đoạn $[0; 4]$ là $-22$.`, a: true, e: R`$f(0) = 5$, $f(3) = -22$, $f(4) = -15$ ⇒ $\min = -22$.` }
      ],
      explain: R`Quy trình tìm GTLN/GTNN trên đoạn: tính $f'$, tìm nghiệm thuộc đoạn, so sánh giá trị tại các nghiệm và hai đầu mút.` },
    { id: 'dh-tf2', type: 'tf', level: 3,
      q: R`Cho hàm số $y = \dfrac{x^2 + 3}{x - 1}$.`,
      statements: [
        { s: R`Tập xác định là $\mathbb{R}\setminus\{1\}$.`, a: true, e: R`Mẫu khác 0.` },
        { s: R`$y' = \dfrac{x^2 - 2x - 3}{(x-1)^2}$.`, a: true, e: R`$y' = \dfrac{2x(x-1) - (x^2+3)}{(x-1)^2} = \dfrac{x^2 - 2x - 3}{(x-1)^2}$.` },
        { s: R`Hàm số có giá trị cực tiểu bằng 6.`, a: true, e: R`$y' = 0 \Leftrightarrow x = -1$ hoặc $x = 3$; $y'$ đổi dấu từ $-$ sang $+$ qua $x = 3$ ⇒ $y_{CT} = y(3) = \dfrac{12}{2} = 6$.` },
        { s: R`Đồ thị có tiệm cận ngang $y = 1$.`, a: false, e: R`Bậc tử lớn hơn bậc mẫu ⇒ không có tiệm cận ngang; có **tiệm cận xiên** $y = x + 1$ (vì $y = x + 1 + \dfrac{4}{x-1}$).` }
      ],
      explain: R`Với hàm phân thức bậc 2/bậc 1, viết $y = ax + b + \dfrac{c}{x - d}$ để thấy ngay tiệm cận xiên.` },
    { id: 'dh-s1', type: 'short', level: 3,
      q: R`Có bao nhiêu giá trị nguyên của $m \in [-10; 10]$ để hàm số $y = x^3 - 3x^2 + mx + 1$ đồng biến trên $\mathbb{R}$?`,
      answer: '8',
      explain: R`$y' = 3x^2 - 6x + m \ge 0\ \forall x \Leftrightarrow \Delta' = 9 - 3m \le 0 \Leftrightarrow m \ge 3$. Các số nguyên $m \in \{3, 4, \dots, 10\}$: **8** giá trị.` },
    { id: 'dh-s2', type: 'short', level: 4,
      q: R`Từ một tấm bìa hình vuông cạnh 12 cm, người ta cắt bỏ ở bốn góc bốn hình vuông bằng nhau cạnh $x$ cm rồi gấp lại thành một chiếc hộp không nắp. Thể tích lớn nhất của hộp là bao nhiêu cm³?`,
      answer: '128', unit: 'cm³',
      explain: R`$V(x) = x(12 - 2x)^2$, $0 < x < 6$. $V'(x) = (12 - 2x)(12 - 6x) = 0 \Rightarrow x = 2$ (loại $x = 6$). $V(2) = 2\cdot 8^2 = 128$ cm³.` },
    { id: 'dh-s3', type: 'short', level: 3,
      q: R`Giá trị nhỏ nhất của hàm số $y = x + \dfrac{4}{x}$ trên khoảng $(0; +\infty)$ là bao nhiêu?`,
      answer: '4',
      explain: R`$y' = 1 - \dfrac{4}{x^2} = 0 \Leftrightarrow x = 2$; $y'$ đổi dấu từ $-$ sang $+$ ⇒ $\min y = y(2) = 2 + 2 = 4$. (Hoặc Cô-si: $x + \tfrac4x \ge 2\sqrt4 = 4$.)` }
  ]);

  /* ======================= TÍCH PHÂN ======================= */
  add('tichphan', [
    { id: 'tp-01', type: 'mcq', level: 1,
      q: R`$\displaystyle\int (3x^2 + 2x)\,dx$ bằng`,
      choices: [R`$x^3 + x^2 + C$`, R`$6x + 2 + C$`, R`$x^3 + 2x^2 + C$`, R`$3x^3 + x^2 + C$`], answer: 0,
      why: [null, R`Đây là đạo hàm, không phải nguyên hàm.`, null, null],
      explain: R`$\int x^n dx = \dfrac{x^{n+1}}{n+1} + C$ ⇒ $\int 3x^2 dx = x^3$, $\int 2x\,dx = x^2$.` },
    { id: 'tp-02', type: 'mcq', level: 1,
      q: R`$\displaystyle\int e^{2x}\,dx$ bằng`,
      choices: [R`$\dfrac12 e^{2x} + C$`, R`$2e^{2x} + C$`, R`$e^{2x} + C$`, R`$\dfrac{e^{2x+1}}{2x+1} + C$`], answer: 0,
      explain: R`$\int e^{ax}dx = \dfrac{1}{a}e^{ax} + C$. Kiểm tra: $\left(\tfrac12 e^{2x}\right)' = e^{2x}$.` },
    { id: 'tp-03', type: 'mcq', level: 1,
      q: R`$\displaystyle\int_0^1 (2x + 1)\,dx$ bằng`,
      choices: [R`2`, R`1`, R`3`, R`$\dfrac32$`], answer: 0,
      explain: R`$\left[x^2 + x\right]_0^1 = 2$.` },
    { id: 'tp-04', type: 'mcq', level: 2,
      q: R`$\displaystyle\int_0^{\pi/2} \cos x\,dx$ bằng`,
      choices: [R`1`, R`0`, R`$-1$`, R`$\dfrac{\pi}{2}$`], answer: 0,
      explain: R`$\left[\sin x\right]_0^{\pi/2} = 1 - 0 = 1$.` },
    { id: 'tp-05', type: 'mcq', level: 2,
      q: R`Diện tích hình phẳng giới hạn bởi đồ thị $y = x^2$, trục hoành và hai đường thẳng $x = 0$, $x = 3$ là`,
      choices: [R`9`, R`27`, R`3`, R`6`], answer: 0,
      explain: R`$S = \int_0^3 x^2 dx = \left[\dfrac{x^3}{3}\right]_0^3 = 9$.` },
    { id: 'tp-06', type: 'mcq', level: 3,
      q: R`Cho hình phẳng giới hạn bởi $y = \sqrt{x}$, trục hoành, $x = 0$ và $x = 4$. Thể tích khối tròn xoay tạo thành khi quay hình phẳng đó quanh trục $Ox$ là`,
      choices: [R`$8\pi$`, R`$16\pi$`, R`$4\pi$`, R`$\dfrac{16\pi}{3}$`], answer: 0,
      why: [null, null, null, R`Quên bình phương: tính $\pi\int_0^4\sqrt{x}\,dx$.`],
      explain: R`$V = \pi\int_0^4 (\sqrt x)^2 dx = \pi\int_0^4 x\,dx = \pi\cdot\dfrac{16}{2} = 8\pi$.` },
    { id: 'tp-07', type: 'mcq', level: 2,
      q: R`Biết $\displaystyle\int_1^3 f(x)\,dx = 5$ và $\displaystyle\int_1^3 g(x)\,dx = 2$. Giá trị của $\displaystyle\int_1^3 [2f(x) - 3g(x)]\,dx$ là`,
      choices: [R`4`, R`7`, R`16`, R`$-4$`], answer: 0,
      explain: R`Tính chất tuyến tính: $2\cdot5 - 3\cdot2 = 4$.` },
    { id: 'tp-tf1', type: 'tf', level: 3,
      q: R`Một vật chuyển động thẳng với vận tốc $v(t) = 3t^2 + 2$ (m/s), $t$ tính bằng giây.`,
      statements: [
        { s: R`Quãng đường vật đi được trong 2 giây đầu là 12 m.`, a: true, e: R`$s = \int_0^2 (3t^2 + 2)dt = [t^3 + 2t]_0^2 = 12$ m.` },
        { s: R`Gia tốc của vật tại $t = 1$ s là $6$ m/s².`, a: true, e: R`$a = v'(t) = 6t$ ⇒ $a(1) = 6$ m/s².` },
        { s: R`Các nguyên hàm của $v(t)$ có dạng $t^3 + 2t + C$.`, a: true, e: R`$(t^3 + 2t)' = 3t^2 + 2$.` },
        { s: R`Quãng đường vật đi được từ $t = 1$ s đến $t = 3$ s là 32 m.`, a: false, e: R`$[t^3 + 2t]_1^3 = 33 - 3 = 30$ m.` }
      ],
      explain: R`Quãng đường = tích phân của vận tốc (khi $v \ge 0$); gia tốc = đạo hàm của vận tốc — cầu nối giữa Toán và Vật lý.` },
    { id: 'tp-tf2', type: 'tf', level: 3,
      q: R`Cho $F(x)$ là một nguyên hàm của $f(x) = \sin x + 2x$ thỏa mãn $F(0) = 1$.`,
      statements: [
        { s: R`$F(x) = -\cos x + x^2 + 2$.`, a: true, e: R`$F(x) = -\cos x + x^2 + C$; $F(0) = -1 + C = 1 \Rightarrow C = 2$.` },
        { s: R`$F(\pi) = \pi^2 + 3$.`, a: true, e: R`$-\cos\pi + \pi^2 + 2 = 1 + \pi^2 + 2$.` },
        { s: R`$\displaystyle\int_0^{\pi} f(x)\,dx = \pi^2 + 2$.`, a: true, e: R`$F(\pi) - F(0) = \pi^2 + 3 - 1 = \pi^2 + 2$.` },
        { s: R`$F'(x) = \cos x + 2x$.`, a: false, e: R`$F'(x) = f(x) = \sin x + 2x$.` }
      ],
      explain: R`$F' = f$ là định nghĩa nguyên hàm; hằng số $C$ xác định nhờ điều kiện ban đầu.` },
    { id: 'tp-s1', type: 'short', level: 2,
      q: R`Tính $\displaystyle\int_1^2 (4x^3 - 3x^2)\,dx$.`,
      answer: '8',
      explain: R`$\left[x^4 - x^3\right]_1^2 = (16 - 8) - (1 - 1) = 8$.` },
    { id: 'tp-s2', type: 'short', level: 3,
      q: R`Tính diện tích hình phẳng giới hạn bởi hai đồ thị $y = x^2$ và $y = 2x$ (làm tròn đến hàng phần trăm).`,
      answer: '1,33',
      explain: R`Hoành độ giao điểm: $x^2 = 2x \Leftrightarrow x = 0$ hoặc $x = 2$. Trên $(0;2)$: $2x \ge x^2$.

$S = \int_0^2 (2x - x^2)dx = \left[x^2 - \dfrac{x^3}{3}\right]_0^2 = 4 - \dfrac83 = \dfrac43 \approx 1{,}33$.` },
    { id: 'tp-s3', type: 'short', level: 3,
      q: R`Nước chảy vào một bể với tốc độ $r(t) = 10 + 2t$ (lít/phút), $t$ tính bằng phút. Lượng nước chảy vào bể trong 10 phút đầu là bao nhiêu lít?`,
      answer: '200', unit: 'lít',
      explain: R`$\int_0^{10}(10 + 2t)dt = [10t + t^2]_0^{10} = 200$ lít.` }
  ]);

  /* ======================= OXYZ ======================= */
  add('oxyz', [
    { id: 'ox-01', type: 'mcq', level: 1,
      q: R`Trong không gian $Oxyz$, cho $A(1; 2; 3)$ và $B(3; 0; -1)$. Tọa độ trung điểm của đoạn $AB$ là`,
      choices: [R`$(2; 1; 1)$`, R`$(4; 2; 2)$`, R`$(1; -1; -2)$`, R`$(2; -2; -4)$`], answer: 0,
      why: [null, R`Quên chia 2.`, R`Đây là $\tfrac12\overrightarrow{AB}$.`, R`Đây là $\overrightarrow{AB}$.`],
      explain: R`$I = \left(\dfrac{1+3}{2}; \dfrac{2+0}{2}; \dfrac{3-1}{2}\right) = (2; 1; 1)$.` },
    { id: 'ox-02', type: 'mcq', level: 1,
      q: R`Độ dài của vectơ $\vec a = (1; -2; 2)$ là`,
      choices: [R`3`, R`9`, R`5`, R`$\sqrt5$`], answer: 0,
      explain: R`$|\vec a| = \sqrt{1 + 4 + 4} = 3$.` },
    { id: 'ox-03', type: 'mcq', level: 1,
      q: R`Cho $\vec a = (1; 2; -1)$ và $\vec b = (2; 0; 1)$. Tích vô hướng $\vec a\cdot\vec b$ bằng`,
      choices: [R`1`, R`3`, R`$-1$`, R`0`], answer: 0,
      explain: R`$1\cdot2 + 2\cdot0 + (-1)\cdot1 = 1$.` },
    { id: 'ox-04', type: 'mcq', level: 2,
      q: R`Khoảng cách từ gốc tọa độ $O$ đến mặt phẳng $(P): 2x - y + 2z - 3 = 0$ bằng`,
      choices: [R`1`, R`3`, R`$\dfrac13$`, R`$\dfrac{3}{\sqrt5}$`], answer: 0,
      explain: R`$d = \dfrac{|2\cdot0 - 0 + 2\cdot0 - 3|}{\sqrt{4 + 1 + 4}} = \dfrac{3}{3} = 1$.` },
    { id: 'ox-05', type: 'mcq', level: 1,
      q: R`Mặt cầu $(S): (x - 1)^2 + (y + 2)^2 + z^2 = 9$ có tâm $I$ và bán kính $R$ là`,
      choices: [R`$I(1; -2; 0)$, $R = 3$`, R`$I(-1; 2; 0)$, $R = 3$`, R`$I(1; -2; 0)$, $R = 9$`, R`$I(-1; 2; 0)$, $R = 9$`], answer: 0,
      explain: R`Dạng $(x - a)^2 + (y - b)^2 + (z - c)^2 = R^2$ ⇒ $I(1; -2; 0)$, $R = \sqrt9 = 3$.`,
      tip: R`Đổi dấu tọa độ tâm và lấy căn vế phải.` },
    { id: 'ox-06', type: 'mcq', level: 2,
      q: R`Đường thẳng $\Delta$ đi qua $A(1; 0; 2)$ và có vectơ chỉ phương $\vec u = (2; -1; 3)$ có phương trình tham số là`,
      choices: [R`$x = 1 + 2t,\ y = -t,\ z = 2 + 3t$`, R`$x = 2 + t,\ y = -1,\ z = 3 + 2t$`, R`$x = 1 + 2t,\ y = t,\ z = 2 + 3t$`, R`$x = 2 + t,\ y = -t,\ z = 3 + 2t$`], answer: 0,
      explain: R`$x = x_A + at$, $y = y_A + bt$, $z = z_A + ct$ với $(a; b; c) = (2; -1; 3)$.` },
    { id: 'ox-07', type: 'mcq', level: 2,
      q: R`Mặt phẳng đi qua $M(1; 2; -1)$ và có vectơ pháp tuyến $\vec n = (2; 1; -3)$ có phương trình là`,
      choices: [R`$2x + y - 3z - 7 = 0$`, R`$2x + y - 3z + 7 = 0$`, R`$x + 2y - z - 7 = 0$`, R`$2x + y - 3z - 1 = 0$`], answer: 0,
      explain: R`$2(x - 1) + 1(y - 2) - 3(z + 1) = 0 \Leftrightarrow 2x + y - 3z - 7 = 0$. Kiểm tra: $2 + 2 + 3 - 7 = 0$ ✓.` },
    { id: 'ox-tf1', type: 'tf', level: 3,
      q: R`Cho ba điểm $A(1; 0; 0)$, $B(0; 2; 0)$, $C(0; 0; 3)$.`,
      statements: [
        { s: R`Mặt phẳng $(ABC)$ có phương trình $\dfrac{x}{1} + \dfrac{y}{2} + \dfrac{z}{3} = 1$.`, a: true, e: R`Phương trình mặt phẳng theo đoạn chắn.` },
        { s: R`$\vec n = (6; 3; 2)$ là một vectơ pháp tuyến của $(ABC)$.`, a: true, e: R`Nhân hai vế với 6: $6x + 3y + 2z - 6 = 0$.` },
        { s: R`Khoảng cách từ $O$ đến $(ABC)$ bằng $\dfrac67$.`, a: true, e: R`$d = \dfrac{6}{\sqrt{36 + 9 + 4}} = \dfrac67$.` },
        { s: R`Thể tích tứ diện $OABC$ bằng 6.`, a: false, e: R`$V = \dfrac16\cdot OA\cdot OB\cdot OC = \dfrac{1\cdot2\cdot3}{6} = 1$.` }
      ],
      explain: R`Ba điểm trên ba trục ⇒ dùng ngay phương trình đoạn chắn.` },
    { id: 'ox-tf2', type: 'tf', level: 3,
      q: R`Trong không gian $Oxyz$ (đơn vị km, mặt phẳng $Oxy$ là mặt đất), một máy bay cất cánh từ $O$ và bay thẳng theo hướng vectơ $\vec u = (2; 2; 1)$.`,
      statements: [
        { s: R`Sau khi bay được 3 km, máy bay ở điểm $(2; 2; 1)$.`, a: true, e: R`$|\vec u| = 3$ nên điểm $O + \vec u = (2; 2; 1)$ cách $O$ đúng 3 km.` },
        { s: R`Góc $\varphi$ giữa đường bay và mặt đất thỏa mãn $\sin\varphi = \dfrac13$.`, a: true, e: R`$\sin\varphi = \dfrac{|\vec u\cdot\vec k|}{|\vec u|} = \dfrac13$ ($\varphi \approx 19{,}5^\circ$).` },
        { s: R`Khi máy bay ở độ cao 5 km thì nó cách $O$ đúng 15 km.`, a: true, e: R`$z = t = 5$ ⇒ điểm $(10; 10; 5)$, khoảng cách $\sqrt{100 + 100 + 25} = 15$ km.` },
        { s: R`Máy bay bay qua điểm $M(4; 4; 3)$.`, a: false, e: R`$x = 4 \Rightarrow t = 2 \Rightarrow z = 2 \ne 3$.` }
      ],
      explain: R`Đường bay: $x = 2t$, $y = 2t$, $z = t$. Góc giữa đường thẳng và mặt phẳng dùng **sin** (tích vô hướng với vectơ pháp tuyến).` },
    { id: 'ox-s1', type: 'short', level: 2,
      q: R`Tính khoảng cách giữa hai điểm $A(1; 2; 3)$ và $B(3; -4; 6)$.`,
      answer: '7',
      explain: R`$AB = \sqrt{2^2 + (-6)^2 + 3^2} = \sqrt{49} = 7$.` },
    { id: 'ox-s2', type: 'short', level: 2,
      q: R`Tính góc (đơn vị độ) giữa hai vectơ $\vec a = (1; 0; 1)$ và $\vec b = (0; 1; 1)$.`,
      answer: '60', unit: '°',
      explain: R`$\cos(\vec a, \vec b) = \dfrac{0 + 0 + 1}{\sqrt2\cdot\sqrt2} = \dfrac12$ ⇒ góc $= 60^\circ$.` },
    { id: 'ox-s3', type: 'short', level: 3,
      q: R`Tìm số thực $m > 0$ để mặt phẳng $(P): x + 2y - 2z + m = 0$ cách điểm $A(1; 1; 1)$ một khoảng bằng 3.`,
      answer: '8',
      explain: R`$d = \dfrac{|1 + 2 - 2 + m|}{\sqrt{1 + 4 + 4}} = \dfrac{|m + 1|}{3} = 3 \Leftrightarrow m = 8$ hoặc $m = -10$. Vì $m > 0$ ⇒ $m = 8$.` }
  ]);

  /* ======================= THỐNG KÊ ======================= */
  add('thongke', [
    { id: 'tk-01', type: 'mcq', level: 1, q: STUDY_INTRO + R` Khoảng biến thiên của mẫu số liệu là`, fig: TABLE_STUDY,
      choices: [R`150 phút`, R`120 phút`, R`135 phút`, R`30 phút`], answer: 0,
      why: [null, R`Lấy nhầm đầu mút **trái** của nhóm cuối (120).`, R`Lấy nhầm giá trị đại diện của nhóm cuối (135).`, R`Đây là độ dài một nhóm.`],
      explain: R`Khoảng biến thiên của mẫu ghép nhóm $R = a_{k+1} - a_1 = 150 - 0 = 150$ phút (đầu mút phải của nhóm cuối trừ đầu mút trái của nhóm đầu).` },
    { id: 'tk-02', type: 'mcq', level: 2, q: STUDY_INTRO + R` Số trung bình của mẫu số liệu là`, fig: TABLE_STUDY,
      choices: [R`66 phút`, R`75 phút`, R`60 phút`, R`70 phút`], answer: 0,
      explain: R`Giá trị đại diện: 15, 45, 75, 105, 135.

$\bar x = \dfrac{5\cdot15 + 12\cdot45 + 15\cdot75 + 6\cdot105 + 2\cdot135}{40} = \dfrac{2640}{40} = 66$ phút.` },
    { id: 'tk-03', type: 'mcq', level: 3, q: STUDY_INTRO + R` Tứ phân vị thứ nhất $Q_1$ của mẫu số liệu là`, fig: TABLE_STUDY,
      choices: [R`42,5 phút`, R`45 phút`, R`40 phút`, R`37,5 phút`], answer: 0,
      explain: R`$\dfrac n4 = 10$; tần số tích lũy: 5, 17, … ⇒ $Q_1$ thuộc nhóm $[30; 60)$.

$Q_1 = 30 + \dfrac{10 - 5}{12}\cdot30 = 42{,}5$ phút.` },
    { id: 'tk-04', type: 'mcq', level: 1, q: R`Phát biểu nào sau đây là **đúng**?`,
      choices: [R`Độ lệch chuẩn là căn bậc hai số học của phương sai và có cùng đơn vị với số liệu.`, R`Phương sai có cùng đơn vị với số liệu.`,
        R`Khoảng tứ phân vị bị ảnh hưởng mạnh bởi các giá trị ngoại lệ.`, R`Độ lệch chuẩn luôn lớn hơn phương sai.`], answer: 0,
      explain: R`Phương sai có đơn vị là **bình phương** đơn vị số liệu; lấy căn được độ lệch chuẩn cùng đơn vị. Khoảng tứ phân vị chỉ dùng 50 % số liệu ở giữa nên **ít** bị ảnh hưởng bởi ngoại lệ. Nếu phương sai < 1 thì độ lệch chuẩn lớn hơn phương sai, nên "luôn lớn hơn" là sai.` },
    { id: 'tk-tf1', type: 'tf', level: 3, q: STUDY_INTRO, fig: TABLE_STUDY,
      statements: [
        { s: R`Nhóm chứa tứ phân vị thứ ba là $[60; 90)$.`, a: true, e: R`$\dfrac{3n}{4} = 30$; tần số tích lũy đến nhóm $[60;90)$ là 32 ≥ 30, đến nhóm trước là 17 < 30.` },
        { s: R`$Q_3 = 86$ phút.`, a: true, e: R`$Q_3 = 60 + \dfrac{30 - 17}{15}\cdot30 = 86$.` },
        { s: R`Khoảng tứ phân vị bằng 43,5 phút.`, a: true, e: R`$\Delta_Q = Q_3 - Q_1 = 86 - 42{,}5 = 43{,}5$.` },
        { s: R`Độ lệch chuẩn của mẫu số liệu xấp xỉ 954 phút.`, a: false, e: R`954 là **phương sai** (đơn vị phút²); độ lệch chuẩn $\approx \sqrt{954} \approx 30{,}9$ phút.` }
      ],
      explain: R`Công thức tứ phân vị nhóm: $Q = a_p + \dfrac{\tfrac{kn}{4} - C}{m_p}\,(a_{p+1} - a_p)$, với $C$ là tần số tích lũy trước nhóm $p$.` },
    { id: 'tk-s1', type: 'short', level: 3, q: STUDY_INTRO + R` Tính phương sai của mẫu số liệu (đơn vị phút²).`, fig: TABLE_STUDY,
      answer: '954',
      explain: R`$s^2 = \dfrac1n\sum m_i x_i^2 - \bar x^2 = \dfrac{5\cdot225 + 12\cdot2025 + 15\cdot5625 + 6\cdot11025 + 2\cdot18225}{40} - 66^2 = 5310 - 4356 = 954$.` },
    { id: 'tk-s2', type: 'short', level: 3, q: STUDY_INTRO + R` Tính độ lệch chuẩn của mẫu số liệu (làm tròn đến hàng phần mười, đơn vị phút).`, fig: TABLE_STUDY,
      answer: '30,9',
      explain: R`$s = \sqrt{954} \approx 30{,}9$ phút.` }
  ]);

  /* ======================= XÁC SUẤT ======================= */
  add('xacsuat', [
    { id: 'xs-01', type: 'mcq', level: 1,
      q: R`Cho hai biến cố $A$, $B$ với $P(A) = 0{,}5$, $P(B) = 0{,}4$, $P(A\cap B) = 0{,}2$. Xác suất có điều kiện $P(A\,|\,B)$ bằng`,
      choices: [R`0,5`, R`0,4`, R`0,2`, R`0,8`], answer: 0,
      explain: R`$P(A|B) = \dfrac{P(A\cap B)}{P(B)} = \dfrac{0{,}2}{0{,}4} = 0{,}5$. (Ở đây $P(A|B) = P(A)$ nên $A$, $B$ độc lập.)` },
    { id: 'xs-02', type: 'mcq', level: 2,
      q: R`Một hộp có 5 viên bi đỏ và 3 viên bi xanh. Lấy lần lượt 2 viên, không hoàn lại. Biết viên thứ nhất màu đỏ, xác suất viên thứ hai cũng màu đỏ là`,
      choices: [R`$\dfrac47$`, R`$\dfrac58$`, R`$\dfrac57$`, R`$\dfrac12$`], answer: 0,
      why: [null, R`Quên rằng đã lấy ra 1 viên đỏ (không hoàn lại).`, null, null],
      explain: R`Sau khi lấy 1 bi đỏ, còn 7 bi trong đó 4 bi đỏ ⇒ $P = \dfrac47$.` },
    { id: 'xs-03', type: 'mcq', level: 2,
      q: R`Cho $B$ là biến cố với $0 < P(B) < 1$. Công thức xác suất toàn phần cho biến cố $A$ là`,
      choices: [R`$P(A) = P(B)P(A|B) + P(\overline B)P(A|\overline B)$`, R`$P(A) = P(A|B) + P(A|\overline B)$`, R`$P(A) = P(B)P(B|A) + P(\overline B)P(\overline B|A)$`, R`$P(A) = P(A|B)\cdot P(A|\overline B)$`], answer: 0,
      explain: R`$A = (A\cap B)\cup(A\cap\overline B)$ (xung khắc) ⇒ $P(A) = P(A\cap B) + P(A\cap\overline B) = P(B)P(A|B) + P(\overline B)P(A|\overline B)$.` },
    { id: 'xs-04', type: 'mcq', level: 4,
      q: R`Một bệnh có tỉ lệ mắc 2 % trong cộng đồng. Một xét nghiệm cho kết quả dương tính với 95 % người mắc bệnh, nhưng cũng dương tính (nhầm) với 10 % người không mắc. Một người xét nghiệm dương tính. Xác suất người đó thực sự mắc bệnh xấp xỉ`,
      choices: [R`0,16`, R`0,95`, R`0,02`, R`0,90`], answer: 0,
      why: [null, R`Nhầm $P(\text{dương}|\text{bệnh})$ với $P(\text{bệnh}|\text{dương})$ — lỗi kinh điển.`, R`Đây là tỉ lệ mắc bệnh trước khi xét nghiệm.`, null],
      explain: R`Công thức Bayes: $P(\text{bệnh}|+) = \dfrac{0{,}02\cdot0{,}95}{0{,}02\cdot0{,}95 + 0{,}98\cdot0{,}10} = \dfrac{0{,}019}{0{,}117} \approx 0{,}16$.

Dù xét nghiệm "chính xác 95 %", chỉ khoảng 16 % người dương tính thật sự mắc bệnh, vì bệnh hiếm nên số người khỏe bị dương tính nhầm nhiều hơn.` },
    { id: 'xs-tf1', type: 'tf', level: 3,
      q: R`Một nhà máy có hai dây chuyền: dây chuyền I làm ra 60 % sản phẩm với tỉ lệ phế phẩm 2 %; dây chuyền II làm ra 40 % sản phẩm với tỉ lệ phế phẩm 3 %. Chọn ngẫu nhiên một sản phẩm.`,
      statements: [
        { s: R`Xác suất sản phẩm là phế phẩm bằng 0,024.`, a: true, e: R`$0{,}6\cdot0{,}02 + 0{,}4\cdot0{,}03 = 0{,}024$.` },
        { s: R`Biết sản phẩm là phế phẩm, xác suất nó do dây chuyền II làm ra bằng 0,5.`, a: true, e: R`$\dfrac{0{,}4\cdot0{,}03}{0{,}024} = 0{,}5$.` },
        { s: R`Xác suất sản phẩm tốt và do dây chuyền I làm ra bằng 0,588.`, a: true, e: R`$0{,}6\cdot0{,}98 = 0{,}588$.` },
        { s: R`Xác suất sản phẩm là phế phẩm, biết nó do dây chuyền I làm ra, bằng 0,012.`, a: false, e: R`$P(\text{phế}|\text{I}) = 0{,}02$; còn 0,012 là $P(\text{phế}\cap\text{I})$.` }
      ],
      explain: R`Vẽ sơ đồ cây: nhánh 1 chọn dây chuyền, nhánh 2 chọn tốt/phế. Nhân theo nhánh, cộng các nhánh cùng kết quả.` },
    { id: 'xs-tf2', type: 'tf', level: 3,
      q: R`Một lớp có 40 học sinh, trong đó có 24 nam. Có 12 học sinh nam và 6 học sinh nữ học giỏi Toán. Chọn ngẫu nhiên một học sinh.`,
      statements: [
        { s: R`Xác suất chọn được học sinh giỏi Toán là 0,45.`, a: true, e: R`$\dfrac{18}{40} = 0{,}45$.` },
        { s: R`Biết học sinh được chọn là nữ, xác suất học sinh đó giỏi Toán là 0,375.`, a: true, e: R`$\dfrac{6}{16} = 0{,}375$.` },
        { s: R`Biết học sinh được chọn giỏi Toán, xác suất đó là học sinh nam bằng $\dfrac23$.`, a: true, e: R`$\dfrac{12}{18} = \dfrac23$.` },
        { s: R`Hai biến cố "chọn được nam" và "chọn được học sinh giỏi Toán" độc lập.`, a: false, e: R`$P(\text{giỏi}|\text{nam}) = \dfrac{12}{24} = 0{,}5 \ne P(\text{giỏi}) = 0{,}45$ ⇒ không độc lập.` }
      ],
      explain: R`Lập bảng 2×2 (nam/nữ × giỏi/không giỏi) là cách nhanh nhất cho dạng bài này.` },
    { id: 'xs-s1', type: 'short', level: 4,
      q: R`Một bệnh có tỉ lệ mắc 1 %. Xét nghiệm dương tính với 90 % người mắc bệnh và dương tính nhầm với 5 % người không mắc. Một người có kết quả dương tính. Tính xác suất người đó mắc bệnh (làm tròn đến hàng phần trăm).`,
      answer: '0,15',
      explain: R`$P = \dfrac{0{,}01\cdot0{,}9}{0{,}01\cdot0{,}9 + 0{,}99\cdot0{,}05} = \dfrac{0{,}009}{0{,}0585} \approx 0{,}15$.` },
    { id: 'xs-s2', type: 'short', level: 3,
      q: R`Gieo hai con xúc xắc cân đối. Biết tổng số chấm bằng 8, tính xác suất có ít nhất một con xuất hiện mặt 6 chấm.`,
      answer: '0,4',
      explain: R`Các kết quả có tổng 8: (2,6), (3,5), (4,4), (5,3), (6,2) — 5 kết quả đồng khả năng; có mặt 6: 2 kết quả ⇒ $P = \dfrac25 = 0{,}4$.` }
  ]);

  window.QBANKS = window.QBANKS || {};
  window.QBANKS.toan12 = {
    id: 'toan12', title: 'Ôn thi Toán 12', short: 'Toán 12', version: '1.0 (10/2026)',
    subtitle: 'Chương trình GDPT 2018 · dạng đề tốt nghiệp THPT mới (12 trắc nghiệm + 4 Đúng/Sai + 6 trả lời ngắn).',
    chapters: chapters, questions: Q,
    exam: {
      minutes: 90, max: 10,
      parts: [{ type: 'mcq', count: 12, points: 0.25 }, { type: 'tf', count: 4 }, { type: 'short', count: 6, points: 0.5 }],
      tfScale: [0, 0.1, 0.25, 0.5, 1],
      note: 'Theo định dạng đề tốt nghiệp THPT môn Toán áp dụng từ 2025 (12 + 4 + 6 câu, 90 phút). Đề thật còn có nội dung lớp 10–11; gói này tập trung lớp 12. **Cần xác minh** lại quy chế 2027.'
    },
    notes: 'Mỗi đáp số được tính lại tự động bằng `tools/verify-toan-vact.js`. Phương sai dùng công thức $s^2 = \\frac1n\\sum m_i(x_i - \\bar x)^2$ như SGK.'
  };
})();
