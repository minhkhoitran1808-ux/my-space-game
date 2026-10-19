/* ==========================================================================
   Ngân hàng câu hỏi Vật lý 12 — Chương trình GDPT 2018
   Định dạng: xem README.md của thư mục này.
   Lưu ý soạn: dùng R`...` (String.raw) để giữ nguyên dấu \ của LaTeX;
   KHÔNG viết "${" trong nội dung (dùng macro \nuc{A}{Z}{X} cho hạt nhân).
   Lời giải không nhắc tới chữ cái A/B/C/D vì phương án được xáo trộn.
   ========================================================================== */
(function () {
  var R = String.raw;

  /* ---------- Hình minh họa (SVG, dùng currentColor để hợp cả nền sáng/tối) ---------- */
  var FIG_HEATING = R`<svg viewBox="0 0 340 190" width="340" role="img" aria-label="Đồ thị nhiệt độ theo thời gian của chất rắn kết tinh khi được đun nóng">
  <g stroke="currentColor" stroke-width="1.4" fill="none">
    <line x1="40" y1="160" x2="320" y2="160"/><polygon points="320,160 312,156 312,164" fill="currentColor"/>
    <line x1="40" y1="160" x2="40" y2="14"/><polygon points="40,14 36,22 44,22" fill="currentColor"/>
    <line x1="40" y1="95" x2="110" y2="95" stroke-dasharray="4 4" opacity="0.6"/>
  </g>
  <polyline points="40,145 110,95 210,95 285,40" fill="none" stroke="var(--accent)" stroke-width="3" stroke-linejoin="round"/>
  <g fill="currentColor" font-size="13" font-family="system-ui, sans-serif">
    <text x="30" y="149">A</text><text x="104" y="86">B</text><text x="206" y="86">C</text><text x="288" y="38">D</text>
    <text x="300" y="178">τ (phút)</text><text x="46" y="20">t (°C)</text><text x="4" y="99">t₀</text>
  </g>
</svg>`;

  var FIG_ISOTHERMS = R`<svg viewBox="0 0 320 200" width="320" role="img" aria-label="Hai đường đẳng nhiệt T1 và T2 trong hệ tọa độ p-V">
  <g stroke="currentColor" stroke-width="1.4" fill="none">
    <line x1="40" y1="170" x2="305" y2="170"/><polygon points="305,170 297,166 297,174" fill="currentColor"/>
    <line x1="40" y1="170" x2="40" y2="12"/><polygon points="40,12 36,20 44,20" fill="currentColor"/>
  </g>
  <path d="M60,60 Q90,140 290,155" fill="none" stroke="var(--accent)" stroke-width="2.6"/>
  <path d="M80,25 Q120,120 290,135" fill="none" stroke="var(--accent-2)" stroke-width="2.6"/>
  <g fill="currentColor" font-size="13" font-family="system-ui, sans-serif">
    <text x="292" y="190">V</text><text x="22" y="22">p</text>
    <text x="258" y="150" fill="var(--accent)">T₁</text><text x="258" y="125" fill="var(--accent-2)">T₂</text>
  </g>
</svg>`;

  var chapters = [
    { id: 'nhiet', title: 'Chương I. Vật lí nhiệt', short: 'Vật lí nhiệt' },
    { id: 'khi', title: 'Chương II. Khí lí tưởng', short: 'Khí lí tưởng' },
    { id: 'tu', title: 'Chương III. Từ trường', short: 'Từ trường' },
    { id: 'hatnhan', title: 'Chương IV. Vật lí hạt nhân', short: 'Hạt nhân' }
  ];

  var Q = [];
  function add(ch, list) { list.forEach(function (q) { q.ch = ch; Q.push(q); }); }

  /* =====================================================================
     CHƯƠNG I. VẬT LÍ NHIỆT
     ===================================================================== */
  add('nhiet', [
    {
      id: 'nhiet-01', type: 'mcq', level: 1,
      q: R`Theo mô hình động học phân tử về cấu trúc chất, phát biểu nào sau đây **sai**?`,
      choices: [
        R`Các phân tử chuyển động hỗn loạn, không ngừng.`,
        R`Nhiệt độ của vật càng cao thì các phân tử chuyển động càng nhanh.`,
        R`Giữa các phân tử có khoảng cách.`,
        R`Các phân tử chất rắn đứng yên tại những vị trí cố định.`
      ],
      answer: 3,
      explain: R`Phân tử chất rắn **không đứng yên** mà dao động quanh các vị trí cân bằng xác định. Ba phát biểu còn lại đều là nội dung của mô hình động học phân tử.`
    },
    {
      id: 'nhiet-02', type: 'mcq', level: 1,
      q: R`Nội năng của một vật là`,
      choices: [
        R`tổng động năng và thế năng của vật.`,
        R`tổng động năng và thế năng tương tác của các phân tử cấu tạo nên vật.`,
        R`nhiệt lượng mà vật nhận được trong quá trình truyền nhiệt.`,
        R`tổng động năng của các phân tử cấu tạo nên vật.`
      ],
      answer: 1,
      why: [R`Đây là cơ năng của cả vật (chuyển động có hướng), không phải nội năng.`, null, R`Nhiệt lượng là số đo **phần nội năng thay đổi** trong truyền nhiệt, không phải nội năng.`, R`Thiếu phần thế năng tương tác giữa các phân tử.`],
      explain: R`Nội năng $U$ = tổng động năng (chuyển động nhiệt) và thế năng tương tác của **các phân tử** cấu tạo nên vật. Nội năng phụ thuộc nhiệt độ và thể tích của vật.`
    },
    {
      id: 'nhiet-03', type: 'mcq', level: 1,
      q: R`Nhiệt độ $27\degC$ ứng với bao nhiêu kelvin? (Lấy $T = t + 273$.)`,
      choices: [R`246 K`, R`300 K`, R`327 K`, R`273 K`],
      answer: 1,
      explain: R`$T = t + 273 = 27 + 273 = 300\unit{K}$.`
    },
    {
      id: 'nhiet-04', type: 'mcq', level: 1,
      q: R`Quá trình chuyển trực tiếp từ thể rắn sang thể khí (không qua thể lỏng) gọi là`,
      choices: [R`sự nóng chảy.`, R`sự hóa hơi.`, R`sự thăng hoa.`, R`sự ngưng tụ.`],
      answer: 2,
      explain: R`Rắn → khí trực tiếp là **sự thăng hoa** (ví dụ: băng phiến, đá khô $\mathrm{CO_2}$). Chiều ngược lại (khí → rắn) gọi là sự ngưng kết.`
    },
    {
      id: 'nhiet-05', type: 'mcq', level: 2,
      q: R`Trong quá trình nóng chảy của một chất rắn kết tinh ở áp suất không đổi thì`,
      choices: [
        R`nhiệt độ tăng, nội năng không đổi.`,
        R`nhiệt độ không đổi, nội năng tăng.`,
        R`nhiệt độ và nội năng đều không đổi.`,
        R`nhiệt độ không đổi, nội năng giảm.`
      ],
      answer: 1,
      explain: R`Chất rắn kết tinh nóng chảy ở **nhiệt độ xác định** (không đổi). Nhiệt lượng nhận vào dùng để phá vỡ liên kết mạng tinh thể → thế năng tương tác phân tử tăng → **nội năng tăng** dù nhiệt độ không đổi.`,
      tip: R`"Nhiệt độ không đổi" không có nghĩa là "nội năng không đổi" — nội năng còn gồm thế năng tương tác phân tử.`
    },
    {
      id: 'nhiet-06', type: 'mcq', level: 2,
      q: R`Một khối khí nhận công $100\unit{J}$ và đồng thời tỏa ra môi trường nhiệt lượng $40\unit{J}$. Độ biến thiên nội năng của khối khí là`,
      choices: [R`$140\unit{J}$`, R`$60\unit{J}$`, R`$-60\unit{J}$`, R`$-140\unit{J}$`],
      answer: 1,
      why: [R`Quên đổi dấu nhiệt lượng tỏa ra ($Q<0$).`, null, R`Sai dấu: khí **nhận** công nên $A>0$.`, R`Sai dấu cả $A$ lẫn $Q$.`],
      explain: R`Định luật I của nhiệt động lực học: $\Delta U = A + Q$, với quy ước vật **nhận** công thì $A>0$, vật **nhận** nhiệt thì $Q>0$.

Ở đây $A = +100\unit{J}$, $Q = -40\unit{J}$ ⇒ $\Delta U = 100 - 40 = 60\unit{J}$ (nội năng tăng).`
    },
    {
      id: 'nhiet-07', type: 'mcq', level: 2,
      q: R`Trường hợp nào sau đây nội năng của vật thay đổi chủ yếu do **thực hiện công**?`,
      choices: [
        R`Đun nóng nước trên bếp.`,
        R`Xoa hai bàn tay vào nhau thấy tay ấm lên.`,
        R`Phơi quần áo ngoài nắng.`,
        R`Thả miếng kim loại nóng vào cốc nước lạnh.`
      ],
      answer: 1,
      explain: R`Xoa tay: lực ma sát thực hiện công làm nội năng tăng. Các trường hợp còn lại là **truyền nhiệt** (dẫn nhiệt, đối lưu, bức xạ).`
    },
    {
      id: 'nhiet-08', type: 'mcq', level: 1,
      q: R`Đơn vị của nhiệt dung riêng trong hệ SI là`,
      choices: [R`J/kg`, R`J/K`, R`J/(kg·K)`, R`J·kg/K`],
      answer: 2,
      explain: R`Từ $Q = mc\Delta T$ ⇒ $c = \dfrac{Q}{m\Delta T}$ có đơn vị $\mathrm{J/(kg\cdot K)}$. (J/kg là đơn vị của nhiệt nóng chảy riêng và nhiệt hóa hơi riêng.)`
    },
    {
      id: 'nhiet-09', type: 'mcq', level: 3,
      q: R`Nhiệt lượng cần cung cấp để đun nóng $2\unit{kg}$ nước từ $20\degC$ đến $100\degC$ là bao nhiêu? Biết nhiệt dung riêng của nước là $4200\unit{J/(kg\cdot K)}$.`,
      choices: [R`672 kJ`, R`840 kJ`, R`168 kJ`, R`336 kJ`],
      answer: 0,
      why: [null, R`Dùng nhầm $\Delta t = 100$ thay vì $80$.`, R`Dùng nhầm $\Delta t = 20$.`, R`Quên nhân khối lượng 2 kg.`],
      explain: R`$Q = mc\Delta t = 2\cdot 4200\cdot(100-20) = 672\,000\unit{J} = 672\unit{kJ}$.`
    },
    {
      id: 'nhiet-10', type: 'mcq', level: 3,
      q: R`Nhiệt lượng cần cung cấp để làm nóng chảy hoàn toàn $500\unit{g}$ nước đá ở $0\degC$ là bao nhiêu? Biết nhiệt nóng chảy riêng của nước đá là $3,34\cdot10^{5}\unit{J/kg}$.`,
      choices: [R`334 kJ`, R`16,7 kJ`, R`167 kJ`, R`668 kJ`],
      answer: 2,
      why: [R`Quên đổi 500 g = 0,5 kg (coi như 1 kg).`, R`Sai lũy thừa khi đổi đơn vị.`, null, R`Nhân 2 thay vì chia 2.`],
      explain: R`$Q = \lambda m = 3,34\cdot10^{5}\cdot 0,5 = 1,67\cdot10^{5}\unit{J} = 167\unit{kJ}$.`
    },
    {
      id: 'nhiet-11', type: 'mcq', level: 3,
      q: R`Thả một quả cầu đồng khối lượng $0,2\unit{kg}$ ở $100\degC$ vào $0,5\unit{kg}$ nước ở $20\degC$. Bỏ qua sự trao đổi nhiệt với bình và môi trường. Biết $c_{\text{đồng}} = 380\unit{J/(kg\cdot K)}$, $c_{\text{nước}} = 4200\unit{J/(kg\cdot K)}$. Nhiệt độ khi cân bằng nhiệt xấp xỉ`,
      choices: [R`$22,8\degC$`, R`$25,3\degC$`, R`$20,7\degC$`, R`$60\degC$`],
      answer: 0,
      why: [null, null, null, R`Lấy trung bình cộng nhiệt độ — chỉ đúng khi hai vật có cùng nhiệt dung $mc$.`],
      explain: R`Phương trình cân bằng nhiệt: $Q_{\text{tỏa}} = Q_{\text{thu}}$

$$0,2\cdot380\,(100 - t) = 0,5\cdot4200\,(t - 20)$$
$$76(100-t) = 2100(t-20) \Rightarrow 49\,600 = 2176\,t \Rightarrow t \approx 22,8\degC.$$

Nhiệt độ cân bằng gần nhiệt độ ban đầu của nước vì nước có nhiệt dung $mc$ lớn hơn nhiều.`
    },
    {
      id: 'nhiet-12', type: 'mcq', level: 3,
      q: R`Khí trong xilanh nhận nhiệt lượng $500\unit{J}$ và dãn nở, thực hiện công $200\unit{J}$ đẩy pit-tông. Nội năng của khí`,
      choices: [R`tăng $700\unit{J}$.`, R`tăng $300\unit{J}$.`, R`giảm $300\unit{J}$.`, R`tăng $200\unit{J}$.`],
      answer: 1,
      why: [R`Khí **thực hiện** công (sinh công) thì $A<0$, không cộng vào.`, null, R`Sai dấu của cả biểu thức.`, null],
      explain: R`$Q = +500\unit{J}$ (nhận nhiệt), $A = -200\unit{J}$ (khí thực hiện công). $\Delta U = A + Q = -200 + 500 = 300\unit{J}$ > 0 ⇒ nội năng **tăng** 300 J.`
    },
    {
      id: 'nhiet-13', type: 'mcq', level: 2,
      q: R`Phát biểu nào sau đây về sự bay hơi và sự sôi là **đúng**?`,
      choices: [
        R`Sự sôi xảy ra ở mọi nhiệt độ.`,
        R`Sự bay hơi chỉ xảy ra ở nhiệt độ sôi.`,
        R`Sự bay hơi xảy ra ở bề mặt chất lỏng ở mọi nhiệt độ; sự sôi xảy ra cả trong lòng và trên bề mặt chất lỏng ở nhiệt độ sôi.`,
        R`Trong khi sôi, nhiệt độ của chất lỏng tăng liên tục.`
      ],
      answer: 2,
      explain: R`Bay hơi: ở **mặt thoáng**, xảy ra ở **mọi nhiệt độ**. Sôi: cả **trong lòng** và trên bề mặt, ở **nhiệt độ sôi xác định** (phụ thuộc áp suất); trong suốt quá trình sôi nhiệt độ **không đổi**.`
    },
    {
      id: 'nhiet-14', type: 'mcq', level: 4,
      q: R`Một bếp cung cấp nhiệt đều đặn cho một khối nước đá ở $0\degC$. Sau $334\unit{s}$ nước đá tan hết. Hỏi cần thêm bao lâu nữa để nước bắt đầu sôi ở $100\degC$? Bỏ qua hao phí. Biết $\lambda = 3,34\cdot10^{5}\unit{J/kg}$, $c = 4180\unit{J/(kg\cdot K)}$.`,
      choices: [R`418 s`, R`334 s`, R`100 s`, R`836 s`],
      answer: 0,
      explain: R`Gọi $m$ là khối lượng nước đá, $P$ là công suất cấp nhiệt.

Nóng chảy: $P\cdot 334 = \lambda m$ ⇒ $P = \dfrac{3,34\cdot10^5\,m}{334} = 1000\,m$ (W).

Đun nước $0 \to 100\degC$: $P\,\tau = mc\cdot100$ ⇒ $\tau = \dfrac{m\cdot4180\cdot100}{1000\,m} = 418\unit{s}$.

Khối lượng $m$ tự triệt tiêu — không cần biết.`
    },
    {
      id: 'nhiet-15', type: 'mcq', level: 2,
      q: R`Hình bên là đồ thị nhiệt độ $t$ theo thời gian $\tau$ khi đun nóng liên tục một chất rắn kết tinh. Đoạn BC biểu diễn quá trình nào?`,
      fig: FIG_HEATING,
      choices: [R`Chất rắn nóng lên.`, R`Chất nóng chảy.`, R`Chất lỏng nóng lên.`, R`Chất lỏng sôi.`],
      answer: 1,
      explain: R`Đoạn BC nằm ngang: chất vẫn nhận nhiệt nhưng nhiệt độ không đổi ($t_0$ = nhiệt độ nóng chảy) ⇒ đang **nóng chảy** (rắn và lỏng cùng tồn tại). AB: chất rắn nóng lên; CD: chất lỏng nóng lên.`
    },

    /* ---------- Đúng / Sai ---------- */
    {
      id: 'nhiet-tf1', type: 'tf', level: 2,
      q: R`Xét cấu trúc của chất ở các thể khác nhau và sự chuyển thể.`,
      statements: [
        { s: R`Ở thể khí, khoảng cách giữa các phân tử lớn hơn nhiều lần kích thước của chúng.`, a: true, e: R`Đúng, vì vậy chất khí dễ nén và chiếm toàn bộ thể tích bình chứa.` },
        { s: R`Lực tương tác giữa các phân tử khí rất mạnh nên chất khí có hình dạng xác định.`, a: false, e: R`Lực tương tác giữa các phân tử khí **rất yếu**; chất khí không có hình dạng và thể tích riêng.` },
        { s: R`Chất lỏng có thể tích riêng xác định nhưng không có hình dạng riêng.`, a: true, e: R`Chất lỏng có hình dạng của phần bình chứa nó.` },
        { s: R`Trong quá trình đông đặc, chất rắn kết tinh tỏa nhiệt và nhiệt độ của nó giảm dần.`, a: false, e: R`Đông đặc của chất kết tinh xảy ra ở **nhiệt độ không đổi** (bằng nhiệt độ nóng chảy); chất tỏa nhiệt nhưng nhiệt độ không giảm.` }
      ],
      explain: R`Ôn lại: rắn (có hình dạng và thể tích riêng), lỏng (có thể tích riêng, không có hình dạng riêng), khí (không có cả hai). Chuyển thể của chất kết tinh xảy ra ở nhiệt độ xác định.`
    },
    {
      id: 'nhiet-tf2', type: 'tf', level: 3,
      q: R`Một lượng khí trong xilanh được truyền nhiệt lượng $800\unit{J}$; khí dãn nở đẩy pit-tông và thực hiện công $300\unit{J}$. Dùng quy ước dấu của định luật I nhiệt động lực học $\Delta U = A + Q$.`,
      statements: [
        { s: R`Nhiệt lượng $Q = +800\unit{J}$.`, a: true, e: R`Khí **nhận** nhiệt nên $Q>0$.` },
        { s: R`Công $A = +300\unit{J}$.`, a: false, e: R`Khí **thực hiện** công (sinh công) nên $A = -300\unit{J}$.` },
        { s: R`Nội năng của khí tăng $500\unit{J}$.`, a: true, e: R`$\Delta U = -300 + 800 = 500\unit{J}$.` },
        { s: R`Nếu giữ chặt pit-tông (khí không thực hiện công) thì với cùng nhiệt lượng trên, nội năng khí tăng $800\unit{J}$.`, a: true, e: R`$A = 0$ ⇒ $\Delta U = Q = 800\unit{J}$.` }
      ],
      explain: R`Mấu chốt là quy ước dấu: **nhận** thì dương, **mất/sinh ra** thì âm.`
    },
    {
      id: 'nhiet-tf3', type: 'tf', level: 4,
      q: R`Thả $100\unit{g}$ nước đá ở $0\degC$ vào cốc chứa $300\unit{g}$ nước ở $30\degC$. Bỏ qua trao đổi nhiệt với cốc và môi trường. Biết $\lambda = 3,34\cdot10^{5}\unit{J/kg}$, $c_{\text{nước}} = 4180\unit{J/(kg\cdot K)}$.`,
      statements: [
        { s: R`Nhiệt lượng cần để làm tan hết lượng nước đá là $33,4\unit{kJ}$.`, a: true, e: R`$Q_1 = \lambda m = 3,34\cdot10^5\cdot0,1 = 33\,400\unit{J}$.` },
        { s: R`Nhiệt lượng tối đa mà 300 g nước tỏa ra khi hạ nhiệt độ xuống $0\degC$ là $37,62\unit{kJ}$.`, a: true, e: R`$Q_2 = 0,3\cdot4180\cdot30 = 37\,620\unit{J}$.` },
        { s: R`Nước đá chỉ tan được một phần.`, a: false, e: R`$Q_2 > Q_1$ nên nước đá **tan hết**, còn dư nhiệt làm nóng hỗn hợp.` },
        { s: R`Nhiệt độ cân bằng của hệ xấp xỉ $2,5\degC$.`, a: true, e: R`$0,3\cdot4180(30-t) = 33\,400 + 0,1\cdot4180\,t$ ⇒ $4220 = 1672\,t$ ⇒ $t \approx 2,52\degC$.` }
      ],
      explain: R`Với bài có chuyển thể, luôn **so sánh nhiệt lượng** trước (nước đá có tan hết không?) rồi mới lập phương trình cân bằng nhiệt.`
    },
    {
      id: 'nhiet-tf4', type: 'tf', level: 2,
      q: R`Về thang nhiệt độ Celsius và Kelvin (lấy $T = t + 273$).`,
      statements: [
        { s: R`Nhiệt độ trong thang Kelvin có thể nhận giá trị âm.`, a: false, e: R`$0\unit{K}$ (không độ tuyệt đối) là nhiệt độ thấp nhất; nhiệt độ Kelvin luôn không âm.` },
        { s: R`Độ chênh lệch nhiệt độ $1\degC$ bằng độ chênh lệch $1\unit{K}$.`, a: true, e: R`Hai thang có cùng "kích thước độ", chỉ lệch gốc: $\Delta T = \Delta t$.` },
        { s: R`Nhiệt độ sôi của nước ở áp suất tiêu chuẩn là $373\unit{K}$.`, a: true, e: R`$100 + 273 = 373\unit{K}$.` },
        { s: R`Khi nhiệt độ của vật tăng từ $20\degC$ lên $40\degC$ thì nhiệt độ tuyệt đối của vật tăng gấp đôi.`, a: false, e: R`$293\unit{K} \to 313\unit{K}$, chỉ tăng khoảng 6,8 %. Không được lấy tỉ số nhiệt độ Celsius.` }
      ],
      explain: R`Mọi công thức tỉ lệ với nhiệt độ (chất khí, động năng phân tử) đều dùng **nhiệt độ tuyệt đối** $T$ (K).`
    },

    /* ---------- Trả lời ngắn ---------- */
    {
      id: 'nhiet-s1', type: 'short', level: 3,
      q: R`Tính nhiệt lượng (theo kJ) cần cung cấp để đun nóng $2\unit{kg}$ nước từ $25\degC$ đến $100\degC$. Biết $c = 4200\unit{J/(kg\cdot K)}$.`,
      answer: '630', unit: 'kJ',
      explain: R`$Q = mc\Delta t = 2\cdot4200\cdot75 = 630\,000\unit{J} = 630\unit{kJ}$.`
    },
    {
      id: 'nhiet-s2', type: 'short', level: 2,
      q: R`Tính nhiệt lượng (theo kJ) cần để làm $200\unit{g}$ nước ở $100\degC$ hóa hơi hoàn toàn. Biết nhiệt hóa hơi riêng của nước là $2,3\cdot10^{6}\unit{J/kg}$.`,
      answer: '460', unit: 'kJ',
      explain: R`$Q = Lm = 2,3\cdot10^{6}\cdot0,2 = 4,6\cdot10^{5}\unit{J} = 460\unit{kJ}$.`
    },
    {
      id: 'nhiet-s3', type: 'short', level: 2,
      q: R`Một khối khí bị nén, nhận công $150\unit{J}$, đồng thời tỏa ra môi trường nhiệt lượng $60\unit{J}$. Nội năng của khối khí tăng bao nhiêu jun?`,
      answer: '90', unit: 'J',
      explain: R`$\Delta U = A + Q = 150 + (-60) = 90\unit{J}$.`
    },
    {
      id: 'nhiet-s4', type: 'short', level: 3,
      q: R`Cung cấp nhiệt lượng $11,4\unit{kJ}$ cho một khối kim loại $0,5\unit{kg}$ thì nhiệt độ của nó tăng từ $20\degC$ lên $80\degC$. Nhiệt dung riêng của kim loại đó là bao nhiêu $\mathrm{J/(kg\cdot K)}$?`,
      answer: '380', unit: R`$\mathrm{J/(kg\cdot K)}$`,
      explain: R`$c = \dfrac{Q}{m\Delta t} = \dfrac{11\,400}{0,5\cdot60} = 380\unit{J/(kg\cdot K)}$ (gần với nhiệt dung riêng của đồng).`
    },
    {
      id: 'nhiet-s5', type: 'short', level: 3,
      q: R`Một ấm điện công suất $1000\unit{W}$, hiệu suất $80\,\%$ dùng để đun $1\unit{kg}$ nước từ $20\degC$ đến $100\degC$. Biết $c = 4200\unit{J/(kg\cdot K)}$. Thời gian đun là bao nhiêu phút?`,
      answer: '7', unit: 'phút',
      explain: R`Nhiệt lượng có ích: $Q = 1\cdot4200\cdot80 = 336\,000\unit{J}$.

Điện năng tiêu thụ: $W = \dfrac{Q}{H} = \dfrac{336\,000}{0,8} = 420\,000\unit{J}$ ⇒ $\tau = \dfrac{W}{P} = 420\unit{s} = 7$ phút.`
    },
    {
      id: 'nhiet-s6', type: 'short', level: 4,
      q: R`Thả miếng sắt $0,4\unit{kg}$ ở $200\degC$ vào $1\unit{kg}$ nước ở $25\degC$. Bỏ qua trao đổi nhiệt với bình và môi trường; coi nước không bị hóa hơi. Biết $c_{\text{sắt}} = 460$, $c_{\text{nước}} = 4200\unit{J/(kg\cdot K)}$. Nhiệt độ cân bằng là bao nhiêu $^{\circ}$C (làm tròn đến một chữ số thập phân)?`,
      answer: '32,3', tol: 0.1, unit: R`$^{\circ}$C`,
      explain: R`$0,4\cdot460\,(200-t) = 1\cdot4200\,(t-25)$

$184(200-t) = 4200(t-25) \Rightarrow 36\,800 + 105\,000 = 4384\,t \Rightarrow t = \dfrac{141\,800}{4384} \approx 32,3\degC$.`
    }
  ]);

  /* =====================================================================
     CHƯƠNG II. KHÍ LÍ TƯỞNG
     ===================================================================== */
  add('khi', [
    {
      id: 'khi-01', type: 'mcq', level: 1,
      q: R`Theo mô hình khí lí tưởng, phát biểu nào sau đây đúng?`,
      choices: [
        R`Các phân tử khí có kích thước đáng kể so với khoảng cách giữa chúng.`,
        R`Các phân tử khí chỉ tương tác với nhau khi va chạm; kích thước phân tử có thể bỏ qua.`,
        R`Các phân tử khí đứng yên khi nhiệt độ không đổi.`,
        R`Lực hút giữa các phân tử khí rất lớn.`
      ],
      answer: 1,
      explain: R`Khí lí tưởng: phân tử coi như **chất điểm**, chuyển động hỗn loạn không ngừng, **chỉ tương tác khi va chạm** (va chạm với nhau và với thành bình).`
    },
    {
      id: 'khi-02', type: 'mcq', level: 1,
      q: R`Định luật Boyle phát biểu: trong quá trình đẳng nhiệt của một lượng khí xác định,`,
      choices: [
        R`áp suất tỉ lệ thuận với thể tích.`,
        R`áp suất tỉ lệ nghịch với thể tích.`,
        R`thể tích tỉ lệ thuận với nhiệt độ tuyệt đối.`,
        R`áp suất tỉ lệ thuận với nhiệt độ tuyệt đối.`
      ],
      answer: 1,
      explain: R`Boyle: $T$ không đổi ⇒ $pV = $ hằng số ⇒ $p \sim \dfrac{1}{V}$.`
    },
    {
      id: 'khi-03', type: 'mcq', level: 1,
      q: R`Hệ thức nào sau đây mô tả quá trình **đẳng áp** của một lượng khí xác định?`,
      choices: [R`$pV = \text{hằng số}$`, R`$\dfrac{V}{T} = \text{hằng số}$`, R`$\dfrac{p}{T} = \text{hằng số}$`, R`$VT = \text{hằng số}$`],
      answer: 1,
      explain: R`Định luật Charles: $p$ không đổi ⇒ $\dfrac{V}{T} = $ hằng số ($T$ là nhiệt độ tuyệt đối).`
    },
    {
      id: 'khi-04', type: 'mcq', level: 2,
      q: R`Nén đẳng nhiệt một lượng khí từ thể tích $6\unit{L}$ xuống $4\unit{L}$ thì áp suất tăng thêm $0,75\unit{atm}$. Áp suất ban đầu của khí là`,
      choices: [R`$1,5\unit{atm}$`, R`$0,75\unit{atm}$`, R`$3\unit{atm}$`, R`$2,25\unit{atm}$`],
      answer: 0,
      why: [null, null, null, R`Đây là áp suất **sau** khi nén.`],
      explain: R`$p_1V_1 = p_2V_2 \Rightarrow 6p_1 = 4(p_1 + 0,75) \Rightarrow 2p_1 = 3 \Rightarrow p_1 = 1,5\unit{atm}$.`
    },
    {
      id: 'khi-05', type: 'mcq', level: 2,
      q: R`Một lượng khí ở $27\degC$. Đun nóng đẳng áp để thể tích tăng gấp đôi. Nhiệt độ của khí khi đó là (lấy $T = t + 273$)`,
      choices: [R`$54\degC$`, R`$327\degC$`, R`$600\degC$`, R`$300\degC$`],
      answer: 1,
      why: [R`Nhân đôi nhiệt độ Celsius — sai, phải dùng nhiệt độ tuyệt đối.`, null, R`600 là giá trị theo **kelvin**, không phải độ C.`, null],
      explain: R`$\dfrac{V_1}{T_1} = \dfrac{V_2}{T_2} \Rightarrow T_2 = 2T_1 = 2\cdot300 = 600\unit{K}$ ⇒ $t_2 = 600 - 273 = 327\degC$.`
    },
    {
      id: 'khi-06', type: 'mcq', level: 2,
      q: R`Trong hệ tọa độ $(p, V)$, đường đẳng nhiệt của một lượng khí lí tưởng xác định có dạng`,
      choices: [R`đường thẳng đi qua gốc tọa độ.`, R`đường hypebol.`, R`đường thẳng song song với trục $p$.`, R`đường parabol.`],
      answer: 1,
      explain: R`$pV = $ hằng số ⇒ $p = \dfrac{C}{V}$: đồ thị là một nhánh **hypebol**. (Trong hệ $(p, 1/V)$ thì là đường thẳng qua gốc.)`
    },
    {
      id: 'khi-07', type: 'mcq', level: 2,
      q: R`Hình bên biểu diễn hai đường đẳng nhiệt của cùng một lượng khí ở nhiệt độ $T_1$ và $T_2$. Kết luận nào đúng?`,
      fig: FIG_ISOTHERMS,
      choices: [R`$T_1 > T_2$`, R`$T_1 < T_2$`, R`$T_1 = T_2$`, R`Không so sánh được.`],
      answer: 1,
      explain: R`Kẻ một đường thẳng đứng (cùng thể tích $V$): đường $T_2$ cho áp suất lớn hơn. Theo $pV = nRT$, cùng $V$ thì $p$ lớn hơn ⇔ $T$ lớn hơn ⇒ $T_2 > T_1$. Đường đẳng nhiệt **càng xa gốc tọa độ** thì nhiệt độ **càng cao**.`
    },
    {
      id: 'khi-08', type: 'mcq', level: 1,
      q: R`Theo mô hình động học phân tử, áp suất chất khí tác dụng lên thành bình là do`,
      choices: [
        R`trọng lượng của các phân tử khí.`,
        R`các phân tử khí va chạm với thành bình.`,
        R`lực hút giữa các phân tử khí.`,
        R`các phân tử khí va chạm với nhau.`
      ],
      answer: 1,
      explain: R`Mỗi va chạm của phân tử với thành bình tạo một lực rất nhỏ; vô số va chạm liên tục tạo thành áp lực đều lên thành bình ⇒ áp suất khí.`
    },
    {
      id: 'khi-09', type: 'mcq', level: 2,
      q: R`Động năng tịnh tiến trung bình của phân tử khí ở $27\degC$ là bao nhiêu? Lấy $k = 1,38\cdot10^{-23}\unit{J/K}$, $T = t + 273$.`,
      choices: [R`$6,21\cdot10^{-21}\unit{J}$`, R`$4,14\cdot10^{-21}\unit{J}$`, R`$5,59\cdot10^{-22}\unit{J}$`, R`$6,21\cdot10^{-23}\unit{J}$`],
      answer: 0,
      why: [null, R`Quên hệ số $\tfrac{3}{2}$ (dùng $kT$).`, R`Dùng nhầm $t = 27$ thay vì $T = 300\unit{K}$.`, R`Sai lũy thừa.`],
      explain: R`$\overline{E}_{\text{đ}} = \dfrac{3}{2}kT = \dfrac{3}{2}\cdot1,38\cdot10^{-23}\cdot300 = 6,21\cdot10^{-21}\unit{J}$.`
    },
    {
      id: 'khi-10', type: 'mcq', level: 3,
      q: R`Một bình kín thể tích $8,31\unit{L}$ chứa khí lí tưởng ở $27\degC$ và áp suất $3,0\cdot10^{5}\unit{Pa}$. Lấy $R = 8,31\unit{J/(mol\cdot K)}$. Số mol khí trong bình là`,
      choices: [R`1,0 mol`, R`0,1 mol`, R`10 mol`, R`2,0 mol`],
      answer: 0,
      explain: R`$n = \dfrac{pV}{RT} = \dfrac{3\cdot10^{5}\cdot8,31\cdot10^{-3}}{8,31\cdot300} = \dfrac{2493}{2493} = 1,0\unit{mol}$.

Nhớ đổi $V$ sang $\mathrm{m^3}$ và $t$ sang kelvin.`
    },
    {
      id: 'khi-11', type: 'mcq', level: 3,
      q: R`Một lượng khí ở $27\degC$, áp suất $1\unit{atm}$, thể tích $10\unit{L}$. Nén khí đến thể tích $4\unit{L}$ thì nhiệt độ tăng lên $87\degC$. Áp suất khí khi đó là`,
      choices: [R`$3\unit{atm}$`, R`$2,5\unit{atm}$`, R`$3,6\unit{atm}$`, R`$8\unit{atm}$`],
      answer: 0,
      why: [null, R`Bỏ qua sự thay đổi nhiệt độ (chỉ dùng định luật Boyle).`, null, R`Dùng nhiệt độ Celsius trong tỉ số.`],
      explain: R`Phương trình trạng thái: $\dfrac{p_1V_1}{T_1} = \dfrac{p_2V_2}{T_2}$

$$p_2 = p_1\cdot\dfrac{V_1}{V_2}\cdot\dfrac{T_2}{T_1} = 1\cdot\dfrac{10}{4}\cdot\dfrac{360}{300} = 3\unit{atm}.$$`
    },
    {
      id: 'khi-12', type: 'mcq', level: 3,
      q: R`Khi nhiệt độ tuyệt đối của một lượng khí tăng 4 lần thì tốc độ căn quân phương $v_{\text{cqp}} = \sqrt{\overline{v^2}}$ của các phân tử khí`,
      choices: [R`tăng 2 lần.`, R`tăng 4 lần.`, R`tăng 16 lần.`, R`tăng $\sqrt{2}$ lần.`],
      answer: 0,
      explain: R`$\dfrac{1}{2}m\overline{v^2} = \dfrac{3}{2}kT$ ⇒ $\overline{v^2} \sim T$ ⇒ $\sqrt{\overline{v^2}} \sim \sqrt{T}$. $T$ tăng 4 lần thì $v_{\text{cqp}}$ tăng $\sqrt4 = 2$ lần.`
    },
    {
      id: 'khi-13', type: 'mcq', level: 3,
      q: R`Một bọt khí ở đáy hồ sâu $10\unit{m}$ nổi lên mặt nước. Coi nhiệt độ không đổi. Biết áp suất khí quyển $p_0 = 1,0\cdot10^{5}\unit{Pa}$, khối lượng riêng của nước $1000\unit{kg/m^3}$, $g = 10\unit{m/s^2}$. Khi lên tới mặt nước, thể tích bọt khí`,
      choices: [R`tăng 2 lần.`, R`giảm 2 lần.`, R`tăng 10 lần.`, R`không đổi.`],
      answer: 0,
      explain: R`Áp suất ở đáy: $p_1 = p_0 + \rho g h = 10^{5} + 1000\cdot10\cdot10 = 2\cdot10^{5}\unit{Pa}$. Ở mặt nước: $p_2 = p_0 = 10^5\unit{Pa}$.

Đẳng nhiệt: $\dfrac{V_2}{V_1} = \dfrac{p_1}{p_2} = 2$ ⇒ thể tích tăng 2 lần.`
    },
    {
      id: 'khi-14', type: 'mcq', level: 3,
      q: R`Một chất khí có khối lượng riêng $1,2\unit{kg/m^3}$ ở áp suất $1,0\cdot10^{5}\unit{Pa}$. Tốc độ căn quân phương của các phân tử khí là`,
      choices: [R`$500\unit{m/s}$`, R`$289\unit{m/s}$`, R`$250\unit{m/s}$`, R`$866\unit{m/s}$`],
      answer: 0,
      why: [null, R`Thiếu hệ số 3: $\sqrt{p/\rho}$.`, null, null],
      explain: R`Áp suất theo mô hình động học: $p = \dfrac{1}{3}\mu m\overline{v^2} = \dfrac{1}{3}\rho\overline{v^2}$ (với $\mu$ là mật độ phân tử, $\rho = \mu m$).

$$\sqrt{\overline{v^2}} = \sqrt{\dfrac{3p}{\rho}} = \sqrt{\dfrac{3\cdot10^{5}}{1,2}} = \sqrt{2,5\cdot10^{5}} = 500\unit{m/s}.$$`
    },
    {
      id: 'khi-15', type: 'mcq', level: 4,
      q: R`Mật độ phân tử (số phân tử trong $1\unit{m^3}$) của khí lí tưởng ở áp suất $1,01\cdot10^{5}\unit{Pa}$ và nhiệt độ $273\unit{K}$ xấp xỉ bằng bao nhiêu? Lấy $k = 1,38\cdot10^{-23}\unit{J/K}$.`,
      choices: [R`$2,68\cdot10^{25}\unit{m^{-3}}$`, R`$2,68\cdot10^{22}\unit{m^{-3}}$`, R`$6,02\cdot10^{23}\unit{m^{-3}}$`, R`$3,77\cdot10^{-21}\unit{m^{-3}}$`],
      answer: 0,
      why: [null, R`Đây là số phân tử trong 1 **lít**, không phải 1 m³.`, R`Đây là số Avogadro (số phân tử trong 1 mol).`, R`Đây là $kT$, không phải mật độ.`],
      explain: R`$p = \mu kT$ ⇒ $\mu = \dfrac{p}{kT} = \dfrac{1,01\cdot10^{5}}{1,38\cdot10^{-23}\cdot273} \approx 2,68\cdot10^{25}\unit{m^{-3}}$.`
    },

    /* ---------- Đúng / Sai ---------- */
    {
      id: 'khi-tf1', type: 'tf', level: 2,
      q: R`Một lượng khí lí tưởng xác định thực hiện quá trình đẳng nhiệt.`,
      statements: [
        { s: R`Tích $pV$ không đổi.`, a: true, e: R`Định luật Boyle.` },
        { s: R`Khi thể tích giảm một nửa thì áp suất tăng gấp đôi.`, a: true, e: R`$p \sim 1/V$.` },
        { s: R`Khi khí bị nén, động năng tịnh tiến trung bình của các phân tử khí tăng.`, a: false, e: R`$\overline{E}_{\text{đ}} = \tfrac{3}{2}kT$ chỉ phụ thuộc $T$; đẳng nhiệt thì $T$ không đổi nên động năng trung bình không đổi.` },
        { s: R`Đồ thị biểu diễn $p$ theo $\dfrac{1}{V}$ là đường thẳng đi qua gốc tọa độ.`, a: true, e: R`$p = C\cdot\dfrac1V$ là hàm bậc nhất của $\dfrac1V$, đi qua gốc.` }
      ],
      explain: R`Nén đẳng nhiệt làm áp suất tăng vì **mật độ phân tử** tăng (va chạm thành bình nhiều hơn), không phải vì phân tử chuyển động nhanh hơn.`
    },
    {
      id: 'khi-tf2', type: 'tf', level: 3,
      q: R`Một xilanh chứa $2\unit{L}$ khí ở $27\degC$, áp suất $1,5\cdot10^{5}\unit{Pa}$. Đun nóng đẳng áp đến $127\degC$. Lấy $T = t + 273$, $R = 8,31\unit{J/(mol\cdot K)}$.`,
      statements: [
        { s: R`Thể tích khí sau khi đun xấp xỉ $2,67\unit{L}$.`, a: true, e: R`$V_2 = V_1\dfrac{T_2}{T_1} = 2\cdot\dfrac{400}{300} \approx 2,67\unit{L}$.` },
        { s: R`Trong quá trình đẳng áp, thể tích khí tỉ lệ thuận với nhiệt độ Celsius.`, a: false, e: R`Tỉ lệ thuận với nhiệt độ **tuyệt đối** $T$, không phải $t$.` },
        { s: R`Số mol khí trong xilanh xấp xỉ $0,12\unit{mol}$.`, a: true, e: R`$n = \dfrac{pV}{RT} = \dfrac{1,5\cdot10^5\cdot2\cdot10^{-3}}{8,31\cdot300} \approx 0,120\unit{mol}$.` },
        { s: R`Khối lượng riêng của khí sau khi đun lớn hơn trước khi đun.`, a: false, e: R`Khối lượng không đổi, thể tích tăng ⇒ khối lượng riêng **giảm** (giảm 4/3 lần).` }
      ],
      explain: R`Luôn đổi sang kelvin và $\mathrm{m^3}$ trước khi thay số vào $pV = nRT$.`
    },
    {
      id: 'khi-tf3', type: 'tf', level: 2,
      q: R`Về mô hình động học phân tử chất khí.`,
      statements: [
        { s: R`Các phân tử khí chuyển động hỗn loạn, không ngừng.`, a: true, e: R`Chuyển động nhiệt.` },
        { s: R`Nhiệt độ càng cao thì tốc độ chuyển động trung bình của các phân tử khí càng lớn.`, a: true, e: R`$\overline{v^2} \sim T$.` },
        { s: R`Động năng tịnh tiến trung bình của phân tử khí tỉ lệ thuận với nhiệt độ Celsius.`, a: false, e: R`Tỉ lệ với nhiệt độ tuyệt đối: $\overline{E}_{\text{đ}} = \tfrac32 kT$.` },
        { s: R`Ở cùng nhiệt độ, phân tử hiđrô và phân tử ôxi có cùng động năng tịnh tiến trung bình.`, a: true, e: R`$\overline{E}_{\text{đ}} = \tfrac32 kT$ không phụ thuộc loại khí. (Nhưng tốc độ thì khác: phân tử nhẹ hơn chuyển động nhanh hơn.)` }
      ],
      explain: R`Động năng trung bình chỉ phụ thuộc $T$; tốc độ căn quân phương $\sqrt{3kT/m}$ thì phụ thuộc cả khối lượng phân tử.`
    },
    {
      id: 'khi-tf4', type: 'tf', level: 3,
      q: R`Một bình kín, thể tích không đổi, chứa khí ở $27\degC$ và áp suất $2\unit{atm}$. Đun nóng khí đến $177\degC$. Lấy $T = t + 273$.`,
      statements: [
        { s: R`Quá trình biến đổi của khí là quá trình đẳng tích.`, a: true, e: R`Bình kín, thể tích không đổi.` },
        { s: R`Áp suất của khí sau khi đun là $3\unit{atm}$.`, a: true, e: R`$p_2 = p_1\dfrac{T_2}{T_1} = 2\cdot\dfrac{450}{300} = 3\unit{atm}$.` },
        { s: R`Áp suất tăng $\dfrac{177}{27}$ lần.`, a: false, e: R`Phải dùng tỉ số nhiệt độ tuyệt đối $\dfrac{450}{300} = 1,5$.` },
        { s: R`Nếu bình chỉ chịu được áp suất tối đa $3,5\unit{atm}$ thì nhiệt độ cao nhất có thể đun là $525\degC$.`, a: false, e: R`$T_{\max} = 300\cdot\dfrac{3,5}{2} = 525\unit{K}$, tức là $252\degC$ (không phải $525\degC$).` }
      ],
      explain: R`Đẳng tích: $\dfrac{p}{T} = $ hằng số (suy ra từ phương trình trạng thái khi $V$ không đổi).`
    },

    /* ---------- Trả lời ngắn ---------- */
    {
      id: 'khi-s1', type: 'short', level: 2,
      q: R`Một lượng khí có áp suất $1\unit{atm}$, thể tích $12\unit{L}$. Nén đẳng nhiệt đến thể tích $3\unit{L}$. Áp suất khí lúc sau là bao nhiêu atm?`,
      answer: '4', unit: 'atm',
      explain: R`$p_2 = p_1\dfrac{V_1}{V_2} = 1\cdot\dfrac{12}{3} = 4\unit{atm}$.`
    },
    {
      id: 'khi-s2', type: 'short', level: 3,
      q: R`Một bình $10\unit{L}$ chứa $0,5\unit{mol}$ khí lí tưởng ở $27\degC$. Lấy $R = 8,31\unit{J/(mol\cdot K)}$, $T = t + 273$. Áp suất khí trong bình bằng bao nhiêu $10^{5}\unit{Pa}$ (làm tròn đến hai chữ số thập phân)?`,
      answer: '1,25', unit: R`$\times10^{5}\unit{Pa}$`,
      explain: R`$p = \dfrac{nRT}{V} = \dfrac{0,5\cdot8,31\cdot300}{10\cdot10^{-3}} = 124\,650\unit{Pa} \approx 1,25\cdot10^{5}\unit{Pa}$.`
    },
    {
      id: 'khi-s3', type: 'short', level: 2,
      q: R`Một lượng khí có thể tích $10\unit{L}$ ở $27\degC$. Đun nóng đẳng áp đến $87\degC$. Thể tích khí lúc sau là bao nhiêu lít? (Lấy $T = t + 273$.)`,
      answer: '12', unit: 'L',
      explain: R`$V_2 = V_1\dfrac{T_2}{T_1} = 10\cdot\dfrac{360}{300} = 12\unit{L}$.`
    },
    {
      id: 'khi-s4', type: 'short', level: 3,
      q: R`Ở nhiệt độ bao nhiêu kelvin thì động năng tịnh tiến trung bình của phân tử khí bằng $8,28\cdot10^{-21}\unit{J}$? Lấy $k = 1,38\cdot10^{-23}\unit{J/K}$.`,
      answer: '400', unit: 'K',
      explain: R`$T = \dfrac{2\overline{E}_{\text{đ}}}{3k} = \dfrac{2\cdot8,28\cdot10^{-21}}{3\cdot1,38\cdot10^{-23}} = 400\unit{K}$.`
    },
    {
      id: 'khi-s5', type: 'short', level: 3,
      q: R`Buổi sáng ở $27\degC$, áp suất khí trong lốp xe là $2,0\unit{atm}$. Buổi trưa nhiệt độ khí trong lốp là $42\degC$. Coi thể tích lốp không đổi. Áp suất khí trong lốp buổi trưa là bao nhiêu atm? (Lấy $T = t + 273$.)`,
      answer: '2,1', unit: 'atm',
      explain: R`Đẳng tích: $p_2 = p_1\dfrac{T_2}{T_1} = 2,0\cdot\dfrac{315}{300} = 2,1\unit{atm}$.`
    },
    {
      id: 'khi-s6', type: 'short', level: 4,
      q: R`Một bọt khí nổi từ đáy hồ lên mặt nước thì thể tích tăng $1,5$ lần. Coi nhiệt độ không đổi. Biết $p_0 = 1,0\cdot10^{5}\unit{Pa}$, khối lượng riêng của nước $1000\unit{kg/m^3}$, $g = 10\unit{m/s^2}$. Độ sâu của hồ là bao nhiêu mét?`,
      answer: '5', unit: 'm',
      explain: R`Đẳng nhiệt: $p_{\text{đáy}} = p_0\dfrac{V_2}{V_1} = 1,5\cdot10^{5}\unit{Pa}$.

$\rho g h = p_{\text{đáy}} - p_0 = 0,5\cdot10^{5}$ ⇒ $h = \dfrac{0,5\cdot10^{5}}{1000\cdot10} = 5\unit{m}$.`
    }
  ]);

  /* =====================================================================
     CHƯƠNG III. TỪ TRƯỜNG
     ===================================================================== */
  add('tu', [
    {
      id: 'tu-01', type: 'mcq', level: 1,
      q: R`Đơn vị của cảm ứng từ trong hệ SI là`,
      choices: [R`vêbe (Wb).`, R`tesla (T).`, R`henry (H).`, R`vôn trên mét (V/m).`],
      answer: 1,
      explain: R`Cảm ứng từ $B$ đo bằng **tesla (T)**. Wb là đơn vị từ thông; H là đơn vị độ tự cảm; V/m là đơn vị cường độ điện trường.`
    },
    {
      id: 'tu-02', type: 'mcq', level: 2,
      q: R`$1\unit{Wb}$ bằng`,
      choices: [R`$1\unit{T\cdot m^2}$`, R`$1\unit{T/m^2}$`, R`$1\unit{T\cdot m}$`, R`$1\unit{T/s}$`],
      answer: 0,
      explain: R`$\Phi = BS\cos\alpha$ ⇒ đơn vị $\mathrm{T\cdot m^2} = \mathrm{Wb}$.`
    },
    {
      id: 'tu-03', type: 'mcq', level: 1,
      q: R`Xung quanh vật nào sau đây **không** có từ trường?`,
      choices: [R`Nam châm vĩnh cửu.`, R`Dây dẫn đang có dòng điện chạy qua.`, R`Điện tích đứng yên.`, R`Điện tích đang chuyển động.`],
      answer: 2,
      explain: R`Từ trường tồn tại quanh **nam châm** và quanh **điện tích chuyển động** (dòng điện). Điện tích đứng yên chỉ tạo ra điện trường.`
    },
    {
      id: 'tu-04', type: 'mcq', level: 2,
      q: R`Phát biểu nào sau đây về đường sức từ là **sai**?`,
      choices: [
        R`Các đường sức từ không cắt nhau.`,
        R`Nơi nào từ trường mạnh thì các đường sức từ ở đó dày (mau) hơn.`,
        R`Đường sức từ là những đường cong khép kín hoặc vô hạn ở hai đầu.`,
        R`Bên ngoài nam châm, đường sức từ đi ra từ cực Nam và đi vào cực Bắc.`
      ],
      answer: 3,
      explain: R`Bên ngoài nam châm, đường sức từ **đi ra từ cực Bắc (N)** và **đi vào cực Nam (S)**.`
    },
    {
      id: 'tu-05', type: 'mcq', level: 2,
      q: R`Một đoạn dây dẫn thẳng dài $0,2\unit{m}$ mang dòng điện $5\unit{A}$, đặt vuông góc với các đường sức của từ trường đều có $B = 0,04\unit{T}$. Lực từ tác dụng lên đoạn dây có độ lớn`,
      choices: [R`$0,04\unit{N}$`, R`$0,4\unit{N}$`, R`$4\unit{N}$`, R`$0,02\unit{N}$`],
      answer: 0,
      explain: R`$F = BIL\sin\theta = 0,04\cdot5\cdot0,2\cdot\sin90^\circ = 0,04\unit{N}$.`
    },
    {
      id: 'tu-06', type: 'mcq', level: 2,
      q: R`Lực từ tác dụng lên một đoạn dây dẫn mang dòng điện đặt trong từ trường đều bằng 0 khi đoạn dây`,
      choices: [
        R`vuông góc với các đường sức từ.`,
        R`song song với các đường sức từ.`,
        R`hợp với các đường sức từ một góc $45^\circ$.`,
        R`có dòng điện rất lớn.`
      ],
      answer: 1,
      explain: R`$F = BIL\sin\theta$; $F = 0$ khi $\theta = 0^\circ$ hoặc $180^\circ$, tức là dây **song song** (hoặc ngược chiều) với đường sức từ.`
    },
    {
      id: 'tu-07', type: 'mcq', level: 3,
      q: R`Một khung dây phẳng có diện tích $20\unit{cm^2}$ đặt trong từ trường đều $B = 0,1\unit{T}$. **Mặt phẳng khung** hợp với các đường sức từ một góc $30^\circ$. Từ thông qua khung là`,
      choices: [R`$1,0\cdot10^{-4}\unit{Wb}$`, R`$1,73\cdot10^{-4}\unit{Wb}$`, R`$2,0\cdot10^{-4}\unit{Wb}$`, R`$1,0\cdot10^{-2}\unit{Wb}$`],
      answer: 0,
      why: [null, R`Dùng nhầm $\cos30^\circ$: góc trong công thức là góc giữa $\vec B$ và **pháp tuyến**, không phải với mặt phẳng khung.`, R`Coi như $\vec B$ vuông góc mặt khung.`, R`Đổi sai đơn vị diện tích: $20\unit{cm^2} = 2\cdot10^{-3}\unit{m^2}$, không phải $0,2\unit{m^2}$.`],
      explain: R`Góc giữa $\vec B$ và pháp tuyến $\vec n$ của khung: $\alpha = 90^\circ - 30^\circ = 60^\circ$.

$\Phi = BS\cos\alpha = 0,1\cdot20\cdot10^{-4}\cdot\cos60^\circ = 1,0\cdot10^{-4}\unit{Wb}$.`,
      tip: R`Đọc kỹ đề: "góc với **mặt phẳng khung**" hay "góc với **pháp tuyến**".`
    },
    {
      id: 'tu-08', type: 'mcq', level: 2,
      q: R`Theo định luật Lenz, dòng điện cảm ứng trong mạch kín có chiều sao cho`,
      choices: [
        R`từ trường do nó sinh ra luôn cùng chiều với từ trường ngoài.`,
        R`từ trường do nó sinh ra chống lại sự biến thiên của từ thông qua mạch.`,
        R`từ trường do nó sinh ra luôn ngược chiều với từ trường ngoài.`,
        R`cường độ của nó tỉ lệ với từ thông qua mạch.`
      ],
      answer: 1,
      explain: R`Lenz: từ trường cảm ứng **chống lại sự biến thiên** của từ thông (từ thông tăng → từ trường cảm ứng ngược chiều từ trường ngoài; từ thông giảm → cùng chiều). Vì vậy hai phương án "luôn cùng/ngược chiều" đều sai.`
    },
    {
      id: 'tu-09', type: 'mcq', level: 3,
      q: R`Một khung dây gồm $100$ vòng, diện tích mỗi vòng $50\unit{cm^2}$, đặt trong từ trường đều có $\vec B$ vuông góc với mặt khung. Cảm ứng từ giảm đều từ $0,5\unit{T}$ về $0$ trong $0,1\unit{s}$. Độ lớn suất điện động cảm ứng trong khung là`,
      choices: [R`$2,5\unit{V}$`, R`$0,25\unit{V}$`, R`$25\unit{V}$`, R`$0,025\unit{V}$`],
      answer: 0,
      why: [null, null, R`Quên đổi $\mathrm{cm^2}$ đúng: $50\unit{cm^2} = 5\cdot10^{-3}\unit{m^2}$.`, R`Quên nhân số vòng $N = 100$.`],
      explain: R`$|e| = N\dfrac{|\Delta\Phi|}{\Delta t} = N\dfrac{|\Delta B|S}{\Delta t} = 100\cdot\dfrac{0,5\cdot5\cdot10^{-3}}{0,1} = 2,5\unit{V}$.`
    },
    {
      id: 'tu-10', type: 'mcq', level: 2,
      q: R`Cường độ dòng điện xoay chiều $i = 2\sqrt2\cos(100\pi t)\unit{A}$ có giá trị hiệu dụng và tần số lần lượt là`,
      choices: [R`$2\unit{A}$; $50\unit{Hz}$`, R`$2\sqrt2\unit{A}$; $50\unit{Hz}$`, R`$2\unit{A}$; $100\unit{Hz}$`, R`$2\sqrt2\unit{A}$; $100\pi\unit{Hz}$`],
      answer: 0,
      explain: R`$I = \dfrac{I_0}{\sqrt2} = \dfrac{2\sqrt2}{\sqrt2} = 2\unit{A}$; $f = \dfrac{\omega}{2\pi} = \dfrac{100\pi}{2\pi} = 50\unit{Hz}$.`
    },
    {
      id: 'tu-11', type: 'mcq', level: 1,
      q: R`Máy phát điện xoay chiều hoạt động dựa trên hiện tượng`,
      choices: [R`cảm ứng điện từ.`, R`nhiễm điện do cọ xát.`, R`tác dụng nhiệt của dòng điện.`, R`quang điện.`],
      answer: 0,
      explain: R`Khi khung dây quay trong từ trường (hoặc nam châm quay quanh cuộn dây), từ thông qua cuộn dây biến thiên điều hòa ⇒ xuất hiện suất điện động cảm ứng xoay chiều.`
    },
    {
      id: 'tu-12', type: 'mcq', level: 3,
      q: R`Một khung dây có $200$ vòng, diện tích mỗi vòng $100\unit{cm^2}$, quay đều với tốc độ góc $100\pi\unit{rad/s}$ quanh trục vuông góc với các đường sức của từ trường đều $B = 0,2\unit{T}$. Suất điện động cực đại trong khung xấp xỉ`,
      choices: [R`$125,7\unit{V}$`, R`$88,9\unit{V}$`, R`$40\unit{V}$`, R`$1,26\unit{V}$`],
      answer: 0,
      why: [null, R`Đây là giá trị **hiệu dụng** $E_0/\sqrt2$.`, R`Dùng $\omega = 100$ thay vì $100\pi$.`, R`Thiếu thừa số 100 của $\omega$ (chỉ nhân $\pi$).`],
      explain: R`$E_0 = NBS\omega = 200\cdot0,2\cdot100\cdot10^{-4}\cdot100\pi = 40\pi \approx 125,7\unit{V}$.`
    },
    {
      id: 'tu-13', type: 'mcq', level: 2,
      q: R`Phát biểu nào sau đây về sóng điện từ là **sai**?`,
      choices: [
        R`Sóng điện từ truyền được trong chân không.`,
        R`Tại mỗi điểm, vectơ cường độ điện trường và vectơ cảm ứng từ vuông góc với nhau và vuông góc với phương truyền sóng.`,
        R`Sóng điện từ là sóng ngang.`,
        R`Sóng điện từ không mang năng lượng.`
      ],
      answer: 3,
      explain: R`Sóng điện từ **mang năng lượng** (ví dụ: ánh sáng Mặt Trời sưởi ấm Trái Đất, lò vi sóng làm nóng thức ăn).`
    },
    {
      id: 'tu-14', type: 'mcq', level: 2,
      q: R`Điện áp xoay chiều dân dụng ở Việt Nam có giá trị hiệu dụng $220\unit{V}$. Điện áp cực đại xấp xỉ`,
      choices: [R`$311\unit{V}$`, R`$220\unit{V}$`, R`$156\unit{V}$`, R`$440\unit{V}$`],
      answer: 0,
      why: [null, null, R`Chia cho $\sqrt2$ thay vì nhân.`, R`Nhân 2 thay vì nhân $\sqrt2$.`],
      explain: R`$U_0 = U\sqrt2 = 220\sqrt2 \approx 311\unit{V}$.`
    },
    {
      id: 'tu-15', type: 'mcq', level: 2,
      q: R`Một sóng điện từ có tần số $100\unit{MHz}$ truyền trong chân không với tốc độ $3\cdot10^{8}\unit{m/s}$. Bước sóng của nó là`,
      choices: [R`$3\unit{m}$`, R`$30\unit{m}$`, R`$0,3\unit{m}$`, R`$300\unit{m}$`],
      answer: 0,
      explain: R`$\lambda = \dfrac{c}{f} = \dfrac{3\cdot10^{8}}{100\cdot10^{6}} = 3\unit{m}$ (sóng vô tuyến FM).`
    },

    /* ---------- Đúng / Sai ---------- */
    {
      id: 'tu-tf1', type: 'tf', level: 3,
      q: R`Một đoạn dây dẫn thẳng dài $0,5\unit{m}$ mang dòng điện $4\unit{A}$ đặt trong từ trường đều có $B = 0,2\unit{T}$.`,
      statements: [
        { s: R`Nếu dây vuông góc với đường sức từ thì lực từ có độ lớn $0,4\unit{N}$.`, a: true, e: R`$F = 0,2\cdot4\cdot0,5 = 0,4\unit{N}$.` },
        { s: R`Nếu dây hợp với đường sức từ góc $30^\circ$ thì lực từ có độ lớn $0,2\unit{N}$.`, a: true, e: R`$F = 0,4\cdot\sin30^\circ = 0,2\unit{N}$.` },
        { s: R`Nếu dây song song với đường sức từ thì lực từ đạt cực đại.`, a: false, e: R`Song song thì $\sin\theta = 0$ ⇒ $F = 0$ (cực tiểu).` },
        { s: R`Chiều của lực từ được xác định bằng quy tắc nắm tay phải.`, a: false, e: R`Chiều lực từ: **quy tắc bàn tay trái**. Quy tắc nắm tay phải dùng để xác định chiều đường sức từ của dòng điện.` }
      ],
      explain: R`$F = BIL\sin\theta$, $\theta$ là góc giữa dây (chiều dòng điện) và $\vec B$.`
    },
    {
      id: 'tu-tf2', type: 'tf', level: 3,
      q: R`Đưa cực Bắc (N) của một thanh nam châm lại gần một vòng dây dẫn kín đặt cố định.`,
      statements: [
        { s: R`Từ thông qua vòng dây tăng.`, a: true, e: R`Nam châm lại gần ⇒ $B$ qua vòng dây tăng ⇒ $\Phi$ tăng.` },
        { s: R`Trong vòng dây xuất hiện dòng điện cảm ứng.`, a: true, e: R`Từ thông qua mạch kín biến thiên ⇒ có dòng điện cảm ứng.` },
        { s: R`Mặt vòng dây đối diện với nam châm trở thành mặt Nam (S).`, a: false, e: R`Theo Lenz, dòng cảm ứng chống lại sự lại gần ⇒ mặt đối diện trở thành mặt **Bắc (N)** để đẩy cực N của nam châm.` },
        { s: R`Nếu giữ nam châm đứng yên ở gần vòng dây thì trong vòng dây vẫn có dòng điện cảm ứng.`, a: false, e: R`Nam châm đứng yên ⇒ từ thông không đổi ⇒ không có dòng cảm ứng. Chỉ có dòng cảm ứng khi từ thông **biến thiên**.` }
      ],
      explain: R`"Lại gần thì đẩy, ra xa thì hút" — cách nhớ nhanh định luật Lenz với nam châm.`
    },
    {
      id: 'tu-tf3', type: 'tf', level: 2,
      q: R`Một điện áp xoay chiều có biểu thức $u = 220\sqrt2\cos\left(100\pi t + \dfrac{\pi}{3}\right)\unit{V}$ ($t$ tính bằng giây).`,
      statements: [
        { s: R`Điện áp hiệu dụng bằng $220\unit{V}$.`, a: true, e: R`$U = \dfrac{U_0}{\sqrt2} = 220\unit{V}$.` },
        { s: R`Tần số của điện áp là $100\unit{Hz}$.`, a: false, e: R`$f = \dfrac{100\pi}{2\pi} = 50\unit{Hz}$.` },
        { s: R`Chu kì của điện áp là $0,02\unit{s}$.`, a: true, e: R`$T = \dfrac1f = 0,02\unit{s}$.` },
        { s: R`Tại thời điểm $t = 0$, điện áp tức thời bằng $110\sqrt2\unit{V}$.`, a: true, e: R`$u(0) = 220\sqrt2\cos\dfrac{\pi}{3} = 110\sqrt2 \approx 155,6\unit{V}$.` }
      ],
      explain: R`Đọc biểu thức $u = U_0\cos(\omega t + \varphi)$: $U_0$ là biên độ, $\omega = 2\pi f$, $\varphi$ là pha ban đầu.`
    },
    {
      id: 'tu-tf4', type: 'tf', level: 2,
      q: R`Về điện từ trường và thang sóng điện từ.`,
      statements: [
        { s: R`Tia X có bước sóng ngắn hơn ánh sáng nhìn thấy.`, a: true, e: R`Thứ tự bước sóng giảm dần: vô tuyến > hồng ngoại > ánh sáng nhìn thấy > tử ngoại > tia X > tia gamma.` },
        { s: R`Sóng vô tuyến có tần số lớn hơn tia gamma.`, a: false, e: R`Sóng vô tuyến có bước sóng dài nhất ⇒ tần số **nhỏ nhất**.` },
        { s: R`Trong chân không, mọi sóng điện từ đều truyền với tốc độ xấp xỉ $3\cdot10^{8}\unit{m/s}$.`, a: true, e: R`Tốc độ ánh sáng $c$ không phụ thuộc tần số trong chân không.` },
        { s: R`Một điện trường biến thiên theo thời gian sinh ra một từ trường.`, a: true, e: R`Đây là một ý của thuyết điện từ Maxwell: điện trường biến thiên ⇄ từ trường biến thiên ⇒ điện từ trường.` }
      ],
      explain: R`Nhớ thang sóng điện từ theo bước sóng **giảm dần** (tần số tăng dần): vô tuyến – hồng ngoại – nhìn thấy – tử ngoại – X – gamma.`
    },

    /* ---------- Trả lời ngắn ---------- */
    {
      id: 'tu-s1', type: 'short', level: 2,
      q: R`Một đoạn dây dẫn dài $20\unit{cm}$ mang dòng điện $10\unit{A}$ đặt vuông góc với đường sức của từ trường đều $B = 0,05\unit{T}$. Lực từ tác dụng lên đoạn dây có độ lớn bao nhiêu newton?`,
      answer: '0,1', unit: 'N',
      explain: R`$F = BIL = 0,05\cdot10\cdot0,2 = 0,1\unit{N}$.`
    },
    {
      id: 'tu-s2', type: 'short', level: 3,
      q: R`Một vòng dây phẳng diện tích $0,04\unit{m^2}$ đặt trong từ trường đều $B = 0,5\unit{T}$, vectơ cảm ứng từ hợp với **pháp tuyến** của mặt phẳng vòng dây góc $60^\circ$. Từ thông qua vòng dây bằng bao nhiêu miliwebe (mWb)?`,
      answer: '10', unit: 'mWb',
      explain: R`$\Phi = BS\cos\alpha = 0,5\cdot0,04\cdot\cos60^\circ = 0,01\unit{Wb} = 10\unit{mWb}$.`
    },
    {
      id: 'tu-s3', type: 'short', level: 3,
      q: R`Một ống dây có $500$ vòng. Từ thông qua mỗi vòng dây tăng đều từ $2\unit{mWb}$ lên $6\unit{mWb}$ trong $0,1\unit{s}$. Độ lớn suất điện động cảm ứng trong ống dây là bao nhiêu vôn?`,
      answer: '20', unit: 'V',
      explain: R`$|e| = N\dfrac{\Delta\Phi}{\Delta t} = 500\cdot\dfrac{(6-2)\cdot10^{-3}}{0,1} = 20\unit{V}$.`
    },
    {
      id: 'tu-s4', type: 'short', level: 4,
      q: R`Một khung dây gồm $100$ vòng, diện tích mỗi vòng $400\unit{cm^2}$, quay đều với tốc độ $50$ vòng/giây quanh trục vuông góc với từ trường đều $B = 0,1\unit{T}$. Suất điện động **hiệu dụng** trong khung bằng bao nhiêu vôn (làm tròn đến hàng đơn vị)?`,
      answer: '89', unit: 'V',
      explain: R`$\omega = 2\pi n = 2\pi\cdot50 = 100\pi\unit{rad/s}$.

$E_0 = NBS\omega = 100\cdot0,1\cdot0,04\cdot100\pi = 40\pi \approx 125,7\unit{V}$ ⇒ $E = \dfrac{E_0}{\sqrt2} = 20\sqrt2\,\pi \approx 88,9 \approx 89\unit{V}$.`
    },
    {
      id: 'tu-s5', type: 'short', level: 3,
      q: R`Dòng điện xoay chiều $i = 4\cos(100\pi t)\unit{A}$ chạy qua điện trở $R = 10\,\Omega$. Công suất tỏa nhiệt trung bình trên điện trở là bao nhiêu oát?`,
      answer: '80', unit: 'W',
      explain: R`$I = \dfrac{4}{\sqrt2} = 2\sqrt2\unit{A}$ ⇒ $P = I^2R = 8\cdot10 = 80\unit{W}$.

Lưu ý: công suất trung bình tính bằng giá trị **hiệu dụng**; nếu dùng $I_0$ sẽ ra 160 W (sai).`
    },
    {
      id: 'tu-s6', type: 'short', level: 2,
      q: R`Một sóng điện từ có bước sóng $25\unit{m}$ trong chân không. Lấy $c = 3\cdot10^{8}\unit{m/s}$. Tần số của sóng là bao nhiêu MHz?`,
      answer: '12', unit: 'MHz',
      explain: R`$f = \dfrac{c}{\lambda} = \dfrac{3\cdot10^{8}}{25} = 1,2\cdot10^{7}\unit{Hz} = 12\unit{MHz}$.`
    }
  ]);

  /* =====================================================================
     CHƯƠNG IV. VẬT LÍ HẠT NHÂN
     Hằng số dùng chung: 1 u = 931,5 MeV/c², m_p = 1,0073 u, m_n = 1,0087 u,
     1 MeV = 1,6·10⁻¹³ J, N_A = 6,02·10²³ mol⁻¹ (ghi rõ trong từng đề).
     ===================================================================== */
  add('hatnhan', [
    {
      id: 'hn-01', type: 'mcq', level: 1,
      q: R`Hạt nhân $\nuc{235}{92}{U}$ có`,
      choices: [R`92 proton và 235 neutron.`, R`92 proton và 143 neutron.`, R`143 proton và 92 neutron.`, R`235 proton và 92 neutron.`],
      answer: 1,
      explain: R`Kí hiệu $\nuc{A}{Z}{X}$: $Z$ = số proton, $A$ = số nucleon. Số neutron $N = A - Z = 235 - 92 = 143$.`
    },
    {
      id: 'hn-02', type: 'mcq', level: 1,
      q: R`Các hạt nhân đồng vị là những hạt nhân có`,
      choices: [
        R`cùng số nucleon nhưng khác số proton.`,
        R`cùng số proton nhưng khác số neutron.`,
        R`cùng số neutron nhưng khác số proton.`,
        R`cùng khối lượng nhưng khác điện tích.`
      ],
      answer: 1,
      explain: R`Đồng vị: cùng $Z$ (cùng nguyên tố hóa học), khác $N$ (do đó khác $A$). Ví dụ $\nuc{1}{1}{H}$, $\nuc{2}{1}{H}$, $\nuc{3}{1}{H}$.`
    },
    {
      id: 'hn-03', type: 'mcq', level: 1,
      q: R`Tia phóng xạ nào sau đây **không** bị lệch khi đi qua điện trường?`,
      choices: [R`Tia $\alpha$`, R`Tia $\beta^-$`, R`Tia $\beta^+$`, R`Tia $\gamma$`],
      answer: 3,
      explain: R`Tia $\gamma$ là sóng điện từ (photon năng lượng cao), không mang điện ⇒ không bị lệch trong điện trường và từ trường.`
    },
    {
      id: 'hn-04', type: 'mcq', level: 2,
      q: R`Đại lượng đặc trưng cho mức độ bền vững của hạt nhân là`,
      choices: [R`năng lượng liên kết.`, R`năng lượng liên kết riêng.`, R`số nucleon.`, R`độ hụt khối.`],
      answer: 1,
      why: [R`Năng lượng liên kết lớn chưa chắc bền vì có thể do hạt nhân có nhiều nucleon.`, null, null, R`Độ hụt khối tỉ lệ với năng lượng liên kết, cũng chưa tính "trên mỗi nucleon".`],
      explain: R`Năng lượng liên kết riêng $\varepsilon = \dfrac{W_{\text{lk}}}{A}$ càng lớn thì hạt nhân càng bền. Các hạt nhân có $A$ khoảng 50–80 (như $\nuc{56}{26}{Fe}$) bền nhất, $\varepsilon \approx 8,8\unit{MeV/nucleon}$.`
    },
    {
      id: 'hn-05', type: 'mcq', level: 2,
      q: R`Hạt nhân $\nuc{226}{88}{Ra}$ phóng xạ $\alpha$ tạo thành hạt nhân con X. Hạt nhân X là`,
      choices: [R`$\nuc{222}{86}{Rn}$`, R`$\nuc{222}{88}{Ra}$`, R`$\nuc{230}{90}{Th}$`, R`$\nuc{226}{87}{Fr}$`],
      answer: 0,
      explain: R`Hạt $\alpha$ là $\nuc{4}{2}{He}$. Bảo toàn số nucleon và điện tích: $A = 226 - 4 = 222$, $Z = 88 - 2 = 86$ ⇒ X là $\nuc{222}{86}{Rn}$ (radon).`
    },
    {
      id: 'hn-06', type: 'mcq', level: 2,
      q: R`Trong phóng xạ $\beta^-$, so với hạt nhân mẹ thì hạt nhân con có`,
      choices: [
        R`số proton tăng 1, số nucleon không đổi.`,
        R`số proton giảm 1, số nucleon không đổi.`,
        R`số proton giảm 2, số nucleon giảm 4.`,
        R`số proton và số nucleon đều không đổi.`
      ],
      answer: 0,
      explain: R`Bản chất $\beta^-$: một neutron biến thành proton: $n \to p + e^- + \bar\nu$. Vì vậy $Z$ tăng 1, $A$ không đổi.`
    },
    {
      id: 'hn-07', type: 'mcq', level: 2,
      q: R`Một chất phóng xạ có chu kì bán rã $T$. Sau thời gian $3T$, số hạt nhân chưa phân rã còn lại bằng bao nhiêu phần số hạt nhân ban đầu $N_0$?`,
      choices: [R`$N_0/3$`, R`$N_0/6$`, R`$N_0/8$`, R`$N_0/9$`],
      answer: 2,
      explain: R`$N = N_0\cdot2^{-t/T} = N_0\cdot2^{-3} = \dfrac{N_0}{8}$.`
    },
    {
      id: 'hn-08', type: 'mcq', level: 3,
      q: R`Cho khối lượng hạt nhân $\nuc{4}{2}{He}$ là $4,0015\unit{u}$; $m_p = 1,0073\unit{u}$; $m_n = 1,0087\unit{u}$; $1\unit{u} = 931,5\unit{MeV/c^2}$. Năng lượng liên kết của hạt nhân $\nuc{4}{2}{He}$ xấp xỉ`,
      choices: [R`$28,4\unit{MeV}$`, R`$7,1\unit{MeV}$`, R`$30,5\unit{MeV}$`, R`$2,84\unit{MeV}$`],
      answer: 0,
      why: [null, R`Đây là năng lượng liên kết **riêng** (chia cho $A = 4$).`, null, null],
      explain: R`$\Delta m = 2m_p + 2m_n - m_{\text{He}} = 2\cdot1,0073 + 2\cdot1,0087 - 4,0015 = 0,0305\unit{u}$.

$W_{\text{lk}} = \Delta m\,c^2 = 0,0305\cdot931,5 \approx 28,4\unit{MeV}$.`
    },
    {
      id: 'hn-09', type: 'mcq', level: 3,
      q: R`Cho phản ứng nhiệt hạch $\nuc{2}{1}{H} + \nuc{3}{1}{H} \to \nuc{4}{2}{He} + \nuc{1}{0}{n}$. Biết $m_{\text{D}} = 2,0136\unit{u}$, $m_{\text{T}} = 3,0155\unit{u}$, $m_{\text{He}} = 4,0015\unit{u}$, $m_n = 1,0087\unit{u}$, $1\unit{u} = 931,5\unit{MeV/c^2}$. Phản ứng này`,
      choices: [R`tỏa năng lượng $17,6\unit{MeV}$.`, R`thu năng lượng $17,6\unit{MeV}$.`, R`tỏa năng lượng $1,76\unit{MeV}$.`, R`tỏa năng lượng $176\unit{MeV}$.`],
      answer: 0,
      explain: R`$m_{\text{trước}} = 2,0136 + 3,0155 = 5,0291\unit{u}$; $m_{\text{sau}} = 4,0015 + 1,0087 = 5,0102\unit{u}$.

$m_{\text{trước}} > m_{\text{sau}}$ ⇒ phản ứng **tỏa** năng lượng $\Delta E = (5,0291 - 5,0102)\cdot931,5 = 0,0189\cdot931,5 \approx 17,6\unit{MeV}$.`
    },
    {
      id: 'hn-10', type: 'mcq', level: 3,
      q: R`Iốt phóng xạ $\nuc{131}{53}{I}$ có chu kì bán rã 8 ngày. Ban đầu có $100\unit{g}$. Sau 24 ngày, khối lượng $\nuc{131}{53}{I}$ còn lại là`,
      choices: [R`$12,5\unit{g}$`, R`$33,3\unit{g}$`, R`$25\unit{g}$`, R`$87,5\unit{g}$`],
      answer: 0,
      why: [null, R`Chia cho 3 — sai, phân rã là hàm mũ.`, R`Đây là khối lượng sau 16 ngày (2 chu kì).`, R`Đây là khối lượng **đã phân rã**.`],
      explain: R`$t/T = 24/8 = 3$ ⇒ $m = m_0\cdot2^{-3} = 100/8 = 12,5\unit{g}$.`
    },
    {
      id: 'hn-11', type: 'mcq', level: 2,
      q: R`Phản ứng phân hạch là`,
      choices: [
        R`sự kết hợp hai hạt nhân nhẹ thành một hạt nhân nặng hơn.`,
        R`sự vỡ một hạt nhân nặng thành hai hạt nhân có khối lượng trung bình, thường kèm theo vài neutron.`,
        R`sự phát ra tia $\alpha$ của hạt nhân nặng.`,
        R`sự biến đổi neutron thành proton trong hạt nhân.`
      ],
      answer: 1,
      explain: R`Phân hạch: hạt nhân nặng (như $\nuc{235}{92}{U}$) hấp thụ neutron chậm rồi vỡ thành hai hạt nhân trung bình + 2–3 neutron, tỏa khoảng 200 MeV. Kết hợp hai hạt nhân nhẹ là **nhiệt hạch**.`
    },
    {
      id: 'hn-12', type: 'mcq', level: 3,
      q: R`Pôlôni $\nuc{210}{84}{Po}$ có chu kì bán rã 138 ngày. Hằng số phóng xạ của nó xấp xỉ`,
      choices: [R`$5,81\cdot10^{-8}\unit{s^{-1}}$`, R`$5,02\cdot10^{-3}\unit{s^{-1}}$`, R`$1,99\cdot10^{-7}\unit{s^{-1}}$`, R`$5,81\cdot10^{-6}\unit{s^{-1}}$`],
      answer: 0,
      why: [null, R`Đây là $\lambda$ tính theo đơn vị **ngày⁻¹**, chưa đổi sang giây.`, null, null],
      explain: R`$\lambda = \dfrac{\ln2}{T} = \dfrac{0,693}{138\cdot86\,400\unit{s}} \approx 5,81\cdot10^{-8}\unit{s^{-1}}$.`
    },
    {
      id: 'hn-13', type: 'mcq', level: 2,
      q: R`Biện pháp nào sau đây **không** giúp giảm liều chiếu xạ khi làm việc gần nguồn phóng xạ?`,
      choices: [
        R`Tăng khoảng cách tới nguồn phóng xạ.`,
        R`Giảm thời gian tiếp xúc với nguồn.`,
        R`Dùng vật liệu che chắn phù hợp (chì, bê tông…).`,
        R`Đứng sát nguồn để thao tác nhanh hơn.`
      ],
      answer: 3,
      explain: R`Ba nguyên tắc an toàn bức xạ: **thời gian** (càng ngắn càng tốt), **khoảng cách** (càng xa càng tốt), **che chắn**. Đứng sát nguồn làm tăng mạnh liều chiếu.`
    },
    {
      id: 'hn-14', type: 'mcq', level: 4,
      q: R`Mỗi phân hạch của $\nuc{235}{92}{U}$ tỏa ra trung bình $200\unit{MeV}$. Năng lượng tỏa ra khi $1\unit{g}$ $\nuc{235}{92}{U}$ phân hạch hoàn toàn xấp xỉ bao nhiêu? Lấy $N_A = 6,02\cdot10^{23}\unit{mol^{-1}}$, $1\unit{MeV} = 1,6\cdot10^{-13}\unit{J}$, khối lượng mol của U-235 là $235\unit{g/mol}$.`,
      choices: [R`$8,2\cdot10^{10}\unit{J}$`, R`$5,1\cdot10^{23}\unit{J}$`, R`$8,2\cdot10^{13}\unit{J}$`, R`$1,9\cdot10^{10}\unit{J}$`],
      answer: 0,
      why: [null, R`Đây là năng lượng tính theo **MeV**, chưa đổi sang J.`, R`Nhầm khối lượng 1 kg.`, null],
      explain: R`Số hạt nhân: $N = \dfrac{1}{235}\cdot6,02\cdot10^{23} \approx 2,56\cdot10^{21}$.

$E = N\cdot200\cdot1,6\cdot10^{-13} \approx 8,2\cdot10^{10}\unit{J}$ — tương đương đốt khoảng 2–3 tấn than đá (con số so sánh mang tính ước lượng).`
    },

    /* ---------- Đúng / Sai ---------- */
    {
      id: 'hn-tf1', type: 'tf', level: 3,
      q: R`Xét hạt nhân $\nuc{56}{26}{Fe}$ có khối lượng $55,9207\unit{u}$. Cho $m_p = 1,0073\unit{u}$, $m_n = 1,0087\unit{u}$, $1\unit{u} = 931,5\unit{MeV/c^2}$. Năng lượng liên kết riêng của $\nuc{4}{2}{He}$ là $7,1\unit{MeV/nucleon}$.`,
      statements: [
        { s: R`Hạt nhân $\nuc{56}{26}{Fe}$ có 26 proton và 30 neutron.`, a: true, e: R`$N = 56 - 26 = 30$.` },
        { s: R`Độ hụt khối của hạt nhân $\nuc{56}{26}{Fe}$ xấp xỉ $0,530\unit{u}$.`, a: true, e: R`$\Delta m = 26\cdot1,0073 + 30\cdot1,0087 - 55,9207 = 0,5301\unit{u}$.` },
        { s: R`Năng lượng liên kết riêng của $\nuc{56}{26}{Fe}$ xấp xỉ $8,8\unit{MeV/nucleon}$.`, a: true, e: R`$W_{\text{lk}} = 0,5301\cdot931,5 \approx 493,8\unit{MeV}$; $\varepsilon = 493,8/56 \approx 8,82\unit{MeV/nucleon}$.` },
        { s: R`Hạt nhân $\nuc{56}{26}{Fe}$ kém bền vững hơn hạt nhân $\nuc{4}{2}{He}$.`, a: false, e: R`$\varepsilon_{\text{Fe}} \approx 8,8 > \varepsilon_{\text{He}} = 7,1$ ⇒ Fe **bền hơn**.` }
      ],
      explain: R`Sắt nằm gần đỉnh đường cong năng lượng liên kết riêng — vì vậy cả phân hạch (hạt nhân nặng) lẫn nhiệt hạch (hạt nhân nhẹ) đều tỏa năng lượng khi tiến về phía sắt.`
    },
    {
      id: 'hn-tf2', type: 'tf', level: 2,
      q: R`Một mẫu côban $\nuc{60}{27}{Co}$ có chu kì bán rã $5,27$ năm.`,
      statements: [
        { s: R`Sau 5,27 năm, một nửa số hạt nhân $\nuc{60}{27}{Co}$ ban đầu đã bị phân rã.`, a: true, e: R`Định nghĩa chu kì bán rã.` },
        { s: R`Độ phóng xạ của mẫu giảm dần theo thời gian.`, a: true, e: R`$H = \lambda N$ giảm theo $N$.` },
        { s: R`Sau 10,54 năm, mẫu không còn hạt nhân $\nuc{60}{27}{Co}$ nào.`, a: false, e: R`Sau $2T$ vẫn còn $N_0/4$; số hạt giảm theo hàm mũ, không về 0 sau hữu hạn chu kì.` },
        { s: R`Chu kì bán rã của $\nuc{60}{27}{Co}$ giảm khi nung nóng mẫu.`, a: false, e: R`Phóng xạ là quá trình tự phát trong hạt nhân, **không** phụ thuộc nhiệt độ, áp suất hay trạng thái hóa học.` }
      ],
      explain: R`Hai bẫy kinh điển: "sau 2 chu kì là hết" và "chu kì bán rã thay đổi theo điều kiện bên ngoài".`
    },
    {
      id: 'hn-tf3', type: 'tf', level: 3,
      q: R`Năm 1919, Rutherford thực hiện phản ứng hạt nhân nhân tạo đầu tiên: $\nuc{14}{7}{N} + \nuc{4}{2}{He} \to \nuc{17}{8}{O} + \mathrm{X}$.`,
      statements: [
        { s: R`X là proton.`, a: true, e: R`$A_X = 14 + 4 - 17 = 1$; $Z_X = 7 + 2 - 8 = 1$ ⇒ X là $\nuc{1}{1}{p}$.` },
        { s: R`Trong mọi phản ứng hạt nhân, tổng số proton luôn được bảo toàn.`, a: false, e: R`Bảo toàn **điện tích** và **số nucleon**, nhưng số proton (và số neutron) riêng rẽ có thể thay đổi — ví dụ phóng xạ $\beta^-$ biến neutron thành proton.` },
        { s: R`Tổng số nucleon được bảo toàn trong phản ứng.`, a: true, e: R`$14 + 4 = 17 + 1$.` },
        { s: R`Tổng khối lượng nghỉ của các hạt được bảo toàn trong phản ứng hạt nhân.`, a: false, e: R`Khối lượng nghỉ **không** bảo toàn; độ chênh khối lượng tương ứng với năng lượng tỏa ra hay thu vào ($\Delta E = \Delta m\,c^2$).` }
      ],
      explain: R`Các định luật bảo toàn trong phản ứng hạt nhân: điện tích, số nucleon, năng lượng toàn phần, động lượng. **Không** bảo toàn: khối lượng nghỉ, số proton, số neutron.`
    },
    {
      id: 'hn-tf4', type: 'tf', level: 4,
      q: R`Một nhà máy điện hạt nhân có công suất điện $1000\unit{MW}$, hiệu suất chuyển hóa năng lượng hạt nhân thành điện năng là $33\,\%$. Mỗi phân hạch $\nuc{235}{92}{U}$ tỏa $200\unit{MeV}$. Lấy $1\unit{MeV} = 1,6\cdot10^{-13}\unit{J}$, $N_A = 6,02\cdot10^{23}\unit{mol^{-1}}$.`,
      statements: [
        { s: R`Phân hạch là phản ứng hạt nhân tỏa năng lượng.`, a: true, e: R`Tổng khối lượng các hạt sau nhỏ hơn trước.` },
        { s: R`Công suất do phân hạch trong lò tạo ra là $330\unit{MW}$.`, a: false, e: R`$P_{\text{hạt nhân}} = \dfrac{P_{\text{điện}}}{H} = \dfrac{1000}{0,33} \approx 3030\unit{MW}$. ($330$ MW là nhân thay vì chia.)` },
        { s: R`Số phân hạch xảy ra trong mỗi giây xấp xỉ $9,5\cdot10^{19}$.`, a: true, e: R`$\dfrac{3,03\cdot10^{9}}{200\cdot1,6\cdot10^{-13}} \approx 9,47\cdot10^{19}$ phân hạch/s.` },
        { s: R`Khối lượng $\nuc{235}{92}{U}$ tiêu thụ trong một ngày xấp xỉ $32\unit{kg}$.`, a: false, e: R`$9,47\cdot10^{19}\cdot86\,400 \approx 8,18\cdot10^{24}$ hạt nhân $= 13,6\unit{mol}$ ⇒ $m \approx 3,2\unit{kg}$, không phải 32 kg.` }
      ],
      explain: R`Chuỗi tính: công suất điện → công suất hạt nhân (chia hiệu suất) → số phân hạch/giây (chia năng lượng mỗi phân hạch) → số mol → khối lượng.`
    },

    /* ---------- Trả lời ngắn ---------- */
    {
      id: 'hn-s1', type: 'short', level: 1,
      q: R`Hạt nhân $\nuc{238}{92}{U}$ có bao nhiêu neutron?`,
      answer: '146',
      explain: R`$N = A - Z = 238 - 92 = 146$.`
    },
    {
      id: 'hn-s2', type: 'short', level: 3,
      q: R`Cho khối lượng hạt nhân $\nuc{12}{6}{C}$ là $11,9967\unit{u}$; $m_p = 1,0073\unit{u}$; $m_n = 1,0087\unit{u}$; $1\unit{u} = 931,5\unit{MeV/c^2}$. Năng lượng liên kết riêng của $\nuc{12}{6}{C}$ là bao nhiêu MeV/nucleon (làm tròn đến hai chữ số thập phân)?`,
      answer: '7,71', tol: 0.01, unit: 'MeV/nucleon',
      explain: R`$\Delta m = 6\cdot1,0073 + 6\cdot1,0087 - 11,9967 = 0,0993\unit{u}$.

$W_{\text{lk}} = 0,0993\cdot931,5 \approx 92,50\unit{MeV}$ ⇒ $\varepsilon = \dfrac{92,50}{12} \approx 7,71\unit{MeV/nucleon}$.`
    },
    {
      id: 'hn-s3', type: 'short', level: 2,
      q: R`Một chất phóng xạ có chu kì bán rã 5 ngày. Sau 15 ngày, số hạt nhân chưa phân rã còn lại bằng bao nhiêu phần trăm số hạt nhân ban đầu?`,
      answer: '12,5', unit: '%',
      explain: R`$\dfrac{N}{N_0} = 2^{-15/5} = 2^{-3} = 0,125 = 12,5\,\%$.`
    },
    {
      id: 'hn-s4', type: 'short', level: 3,
      q: R`Radon $\nuc{222}{86}{Rn}$ có chu kì bán rã $3,8$ ngày. Sau bao nhiêu ngày thì $75\,\%$ số hạt nhân ban đầu đã bị phân rã?`,
      answer: '7,6', unit: 'ngày',
      explain: R`Đã phân rã 75 % ⇒ còn lại 25 % $= \dfrac14 = 2^{-2}$ ⇒ $t = 2T = 7,6$ ngày.`,
      tip: R`Đọc kỹ "đã phân rã" hay "còn lại".`
    },
    {
      id: 'hn-s5', type: 'short', level: 3,
      q: R`Một mẫu chứa $2,0\cdot10^{15}$ hạt nhân $\nuc{222}{86}{Rn}$ (chu kì bán rã $3,8$ ngày). Độ phóng xạ của mẫu bằng bao nhiêu $10^{9}\unit{Bq}$ (làm tròn đến hai chữ số thập phân)?`,
      answer: '4,22', tol: 0.01, unit: R`$\times10^{9}\unit{Bq}$`,
      explain: R`$\lambda = \dfrac{\ln2}{3,8\cdot86\,400} \approx 2,111\cdot10^{-6}\unit{s^{-1}}$.

$H = \lambda N = 2,111\cdot10^{-6}\cdot2,0\cdot10^{15} \approx 4,22\cdot10^{9}\unit{Bq}$.`
    },
    {
      id: 'hn-s6', type: 'short', level: 4,
      q: R`Cho phản ứng $\nuc{7}{3}{Li} + \nuc{1}{1}{p} \to 2\,\nuc{4}{2}{He}$. Biết $m_{\text{Li}} = 7,0144\unit{u}$, $m_p = 1,0073\unit{u}$, $m_{\text{He}} = 4,0015\unit{u}$, $1\unit{u} = 931,5\unit{MeV/c^2}$. Năng lượng tỏa ra của phản ứng là bao nhiêu MeV (làm tròn đến một chữ số thập phân)?`,
      answer: '17,4', tol: 0.1, unit: 'MeV',
      explain: R`$\Delta m = (7,0144 + 1,0073) - 2\cdot4,0015 = 8,0217 - 8,0030 = 0,0187\unit{u}$.

$\Delta E = 0,0187\cdot931,5 \approx 17,4\unit{MeV}$.`
    }
  ]);

  window.QBANKS = window.QBANKS || {};
  window.QBANKS.vatly12 = {
    id: 'vatly12',
    title: 'Ôn thi Vật lý 12',
    short: 'Vật lý 12',
    version: '1.0 (10/2026)',
    subtitle: 'Chương trình GDPT 2018 · dạng đề thi tốt nghiệp THPT mới: trắc nghiệm, Đúng/Sai, trả lời ngắn.',
    chapters: chapters,
    questions: Q,
    exam: {
      minutes: 50, max: 10,
      parts: [
        { type: 'mcq', count: 18, points: 0.25 },
        { type: 'tf', count: 4 },
        { type: 'short', count: 6, points: 0.25 }
      ],
      tfScale: [0, 0.1, 0.25, 0.5, 1],
      note: 'Cấu trúc theo định dạng đề thi tốt nghiệp THPT môn Vật lí áp dụng từ năm 2025 (18 + 4 + 6 câu, 50 phút). **Cần xác minh** lại khi Bộ GD&ĐT công bố quy chế kỳ thi 2027.'
    },
    notes: 'Hằng số dùng trong ngân hàng (luôn được ghi lại trong từng đề): $T = t + 273$; $R = 8,31\\ \\mathrm{J/(mol\\cdot K)}$; $k = 1,38\\cdot10^{-23}\\ \\mathrm{J/K}$; $N_A = 6,02\\cdot10^{23}\\ \\mathrm{mol^{-1}}$; $1\\ \\mathrm{u} = 931,5\\ \\mathrm{MeV/c^2}$; $m_p = 1,0073\\ \\mathrm{u}$; $m_n = 1,0087\\ \\mathrm{u}$; $1\\ \\mathrm{MeV} = 1,6\\cdot10^{-13}\\ \\mathrm{J}$.\n\nMọi đáp số tính toán đã được đối chiếu lại bằng script `tools/verify-vatly12.js`. Nội dung bám theo yêu cầu cần đạt của Chương trình GDPT 2018; một số cách gọi tên/kí hiệu có thể hơi khác giữa các bộ sách (Kết nối tri thức, Cánh diều, Chân trời sáng tạo).'
  };
})();
