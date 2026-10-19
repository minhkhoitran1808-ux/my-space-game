/* ==========================================================================
   Dữ liệu sổ tay công thức Vật lý 12 (Chương trình GDPT 2018)
   Mỗi mục: { t: tên, f: công thức (LaTeX, hiển thị dạng khối), n: ghi chú/đơn vị, trap: bẫy hay gặp }
   ========================================================================== */
(function () {
  var R = String.raw;
  window.FORMULA_BOOK = {
    constants: [
      [R`Số Avogadro`, R`N_A = 6{,}02\cdot10^{23}\ \mathrm{mol^{-1}}`],
      [R`Hằng số khí`, R`R = 8{,}31\ \mathrm{J/(mol\cdot K)}`],
      [R`Hằng số Boltzmann`, R`k = \dfrac{R}{N_A} = 1{,}38\cdot10^{-23}\ \mathrm{J/K}`],
      [R`Tốc độ ánh sáng trong chân không`, R`c = 3\cdot10^{8}\ \mathrm{m/s}`],
      [R`Điện tích nguyên tố`, R`e = 1{,}6\cdot10^{-19}\ \mathrm{C}`],
      [R`Đơn vị khối lượng nguyên tử`, R`1\ \mathrm{u} = 1{,}66054\cdot10^{-27}\ \mathrm{kg} = 931{,}5\ \mathrm{MeV}/c^2`],
      [R`Khối lượng proton, neutron`, R`m_p \approx 1{,}0073\ \mathrm{u},\quad m_n \approx 1{,}0087\ \mathrm{u}`],
      [R`Electronvolt`, R`1\ \mathrm{eV} = 1{,}6\cdot10^{-19}\ \mathrm{J},\quad 1\ \mathrm{MeV} = 1{,}6\cdot10^{-13}\ \mathrm{J}`],
      [R`Nhiệt độ tuyệt đối`, R`T\,(\mathrm K) = t\,(^{\circ}\mathrm C) + 273{,}15 \approx t + 273`],
      [R`Áp suất`, R`1\ \mathrm{atm} = 1{,}013\cdot10^{5}\ \mathrm{Pa};\ 1\ \mathrm{bar} = 10^{5}\ \mathrm{Pa};\ 1\ \mathrm{mmHg} \approx 133\ \mathrm{Pa}`],
      [R`Thể tích`, R`1\ \mathrm{L} = 1\ \mathrm{dm^3} = 10^{-3}\ \mathrm{m^3};\quad 1\ \mathrm{cm^3} = 10^{-6}\ \mathrm{m^3}`],
      [R`Độ phóng xạ`, R`1\ \mathrm{Ci} = 3{,}7\cdot10^{10}\ \mathrm{Bq}`]
    ],
    reference: [
      [R`Nhiệt dung riêng của nước`, R`c \approx 4180\text{–}4200\ \mathrm{J/(kg\cdot K)}`],
      [R`Nhiệt nóng chảy riêng của nước đá`, R`\lambda \approx 3{,}34\cdot10^{5}\ \mathrm{J/kg}`],
      [R`Nhiệt hóa hơi riêng của nước (ở 100 °C)`, R`L \approx 2{,}26\cdot10^{6}\ \mathrm{J/kg}`]
    ],
    chapters: [
      {
        id: 'nhiet', title: 'Chương I. Vật lí nhiệt',
        items: [
          { t: 'Mô hình động học phân tử', ft: R`Chất gồm các phân tử **chuyển động hỗn loạn, không ngừng**; nhiệt độ càng cao chúng chuyển động càng nhanh; giữa các phân tử có lực hút và lực đẩy.`,
            n: R`Rắn: phân tử dao động quanh vị trí cân bằng (có hình dạng, thể tích riêng). Lỏng: có thể tích riêng, không có hình dạng riêng. Khí: lực tương tác rất yếu, chiếm toàn bộ bình chứa.` },
          { t: 'Thang nhiệt độ', f: R`T = t + 273 \qquad \Delta T = \Delta t`,
            n: R`Nhiệt độ tuyệt đối $T \ge 0$; $0\ \mathrm K$ là không độ tuyệt đối. Chính xác: $T = t + 273{,}15$.`,
            trap: R`Mọi tỉ lệ (định luật chất khí, động năng phân tử) phải dùng $T$ (K), không dùng $t$ (°C).` },
          { t: 'Nội năng', f: R`U = \sum W_{\text{đ}} + \sum W_{\text{t}}`,
            n: R`Tổng động năng chuyển động nhiệt và thế năng tương tác của các phân tử. Phụ thuộc nhiệt độ và thể tích. Thay đổi nội năng bằng **thực hiện công** hoặc **truyền nhiệt**.` },
          { t: 'Định luật I nhiệt động lực học', f: R`\Delta U = A + Q`,
            n: R`$Q > 0$: vật **nhận** nhiệt; $Q < 0$: vật tỏa nhiệt. $A > 0$: vật **nhận** công; $A < 0$: vật thực hiện công (khí dãn nở).`,
            trap: R`Khí "thực hiện công 200 J" ⇒ $A = -200\ \mathrm J$.` },
          { t: 'Nhiệt lượng làm nóng / lạnh', f: R`Q = mc\,\Delta t`,
            n: R`$c$: nhiệt dung riêng, đơn vị $\mathrm{J/(kg\cdot K)}$ (= nhiệt lượng làm 1 kg chất tăng 1 K). Nhiệt dung của vật $C = mc$ (J/K).` },
          { t: 'Nóng chảy / đông đặc', f: R`Q = \lambda m`,
            n: R`$\lambda$: nhiệt nóng chảy riêng (J/kg). Chất kết tinh nóng chảy ở **nhiệt độ không đổi**; nội năng vẫn tăng.` },
          { t: 'Hóa hơi / ngưng tụ', f: R`Q = L m`,
            n: R`$L$: nhiệt hóa hơi riêng (J/kg). Bay hơi: ở mặt thoáng, mọi nhiệt độ. Sôi: trong lòng + mặt thoáng, ở nhiệt độ sôi không đổi.` },
          { t: 'Cân bằng nhiệt', f: R`\sum Q_{\text{tỏa}} = \sum Q_{\text{thu}}`,
            n: R`Nhiệt truyền tự phát từ vật nóng hơn sang vật lạnh hơn cho tới khi bằng nhiệt độ.`,
            trap: R`Có chuyển thể (đá tan, nước sôi)? **So sánh nhiệt lượng trước** xem chất có chuyển thể hết không, rồi mới lập phương trình.` },
          { t: 'Hiệu suất cấp nhiệt', f: R`H = \dfrac{Q_{\text{có ích}}}{Q_{\text{toàn phần}}} = \dfrac{mc\Delta t}{P\,\tau}`,
            n: R`Ấm điện công suất $P$ đun trong thời gian $\tau$.` }
        ]
      },
      {
        id: 'khi', title: 'Chương II. Khí lí tưởng',
        items: [
          { t: 'Khí lí tưởng', ft: R`Phân tử coi như **chất điểm**, chuyển động hỗn loạn, **chỉ tương tác khi va chạm**.`,
            n: R`Áp suất khí do các phân tử va chạm với thành bình.` },
          { t: 'Định luật Boyle (đẳng nhiệt)', f: R`p_1V_1 = p_2V_2 \qquad (T = \text{const})`,
            n: R`Đồ thị $(p, V)$: hypebol; đường càng xa gốc thì $T$ càng lớn. Đồ thị $(p, 1/V)$: đường thẳng qua gốc.` },
          { t: 'Định luật Charles (đẳng áp)', f: R`\dfrac{V_1}{T_1} = \dfrac{V_2}{T_2} \qquad (p = \text{const})`,
            n: R`Đồ thị $(V, T)$: đường thẳng có đường kéo dài đi qua gốc $O$.`, trap: R`Tỉ lệ với $T$ (K), không tỉ lệ với $t$ (°C).` },
          { t: 'Quá trình đẳng tích', f: R`\dfrac{p_1}{T_1} = \dfrac{p_2}{T_2} \qquad (V = \text{const})`,
            n: R`Suy ra từ phương trình trạng thái. Ví dụ: bình kín, lốp xe phơi nắng.` },
          { t: 'Phương trình trạng thái', f: R`\dfrac{p_1V_1}{T_1} = \dfrac{p_2V_2}{T_2}`,
            n: R`Áp dụng cho một lượng khí xác định (khối lượng không đổi). Đơn vị $p$, $V$ hai vế chỉ cần giống nhau; $T$ bắt buộc là kelvin.` },
          { t: 'Phương trình Clapeyron', f: R`pV = nRT = \dfrac{m}{M}RT = NkT`,
            n: R`$n$: số mol, $M$: khối lượng mol (kg/mol), $N$: số phân tử. Dùng đơn vị SI: Pa, m³, K.`,
            trap: R`Quên đổi lít → m³ ($\times10^{-3}$) và gam → kg.` },
          { t: 'Áp suất theo mô hình động học', f: R`p = \dfrac13\mu m\overline{v^2} = \dfrac23\mu\overline{E}_{\text{đ}}`,
            n: R`$\mu = N/V$: mật độ phân tử (có sách kí hiệu là $n$), $m$: khối lượng một phân tử. Tương đương $p = \tfrac13\rho\overline{v^2}$ với $\rho$ là khối lượng riêng.` },
          { t: 'Động năng tịnh tiến trung bình', f: R`\overline{E}_{\text{đ}} = \dfrac12 m\overline{v^2} = \dfrac32 kT`,
            n: R`Chỉ phụ thuộc nhiệt độ, **không phụ thuộc loại khí**. Hệ quả: $p = \mu kT$.` },
          { t: 'Tốc độ căn quân phương', f: R`v_{\text{cqp}} = \sqrt{\overline{v^2}} = \sqrt{\dfrac{3kT}{m}} = \sqrt{\dfrac{3RT}{M}}`,
            n: R`$T$ tăng 4 lần ⇒ tốc độ tăng 2 lần. Cùng $T$: khí nhẹ hơn chuyển động nhanh hơn.` },
          { t: 'Áp suất chất lỏng (bài bọt khí)', f: R`p = p_0 + \rho g h`,
            n: R`Bọt khí nổi lên (nhiệt độ không đổi): $(p_0 + \rho gh)V_1 = p_0V_2$.` }
        ]
      },
      {
        id: 'tu', title: 'Chương III. Từ trường',
        items: [
          { t: 'Từ trường & đường sức từ', ft: R`Từ trường tồn tại quanh **nam châm** và **dòng điện** (điện tích chuyển động); tác dụng lực từ lên nam châm/dòng điện đặt trong nó.`,
            n: R`Đường sức từ khép kín, không cắt nhau, càng mau nơi từ trường càng mạnh; bên ngoài nam châm đi ra cực Bắc (N), vào cực Nam (S). Chiều đường sức của dòng điện: **quy tắc nắm tay phải**.` },
          { t: 'Lực từ lên đoạn dây dẫn', f: R`F = BIL\sin\alpha`,
            n: R`$\alpha$: góc giữa dây (chiều dòng điện) và $\vec B$. Chiều: **quy tắc bàn tay trái** (đường sức hướng vào lòng bàn tay, chiều từ cổ tay đến ngón giữa là chiều dòng điện, ngón cái choãi 90° chỉ chiều lực).`,
            trap: R`Dây song song với $\vec B$ ⇒ $F = 0$.` },
          { t: 'Cảm ứng từ', f: R`B = \dfrac{F}{IL\sin\alpha}\qquad [B] = \mathrm{T}`,
            n: R`Đặc trưng cho từ trường về phương diện tác dụng lực.` },
          { t: 'Từ thông', f: R`\Phi = BS\cos\alpha\qquad [\Phi] = \mathrm{Wb} = \mathrm{T\cdot m^2}`,
            n: R`$\alpha$: góc giữa $\vec B$ và **pháp tuyến** $\vec n$ của mặt phẳng khung. Khung $N$ vòng: từ thông toàn phần $N\Phi$.`,
            trap: R`Đề cho góc giữa $\vec B$ và **mặt phẳng khung** là $\beta$ ⇒ $\alpha = 90^\circ - \beta$.` },
          { t: 'Định luật Faraday', f: R`e_c = -N\dfrac{\Delta\Phi}{\Delta t}\qquad |e_c| = N\left|\dfrac{\Delta\Phi}{\Delta t}\right|`,
            n: R`$\Phi$: từ thông qua một vòng. Từ thông có thể biến thiên do $B$, $S$ hoặc góc $\alpha$ thay đổi.` },
          { t: 'Định luật Lenz', ft: R`Dòng điện cảm ứng có chiều sao cho từ trường nó sinh ra **chống lại sự biến thiên** của từ thông qua mạch.`,
            n: R`$\Phi$ tăng ⇒ $\vec B_c$ ngược chiều $\vec B$; $\Phi$ giảm ⇒ $\vec B_c$ cùng chiều $\vec B$. Nam châm lại gần ⇒ vòng dây đẩy; ra xa ⇒ hút.` },
          { t: 'Máy phát điện xoay chiều', f: R`\Phi = NBS\cos(\omega t + \varphi)\ \Rightarrow\ e = NBS\omega\sin(\omega t + \varphi),\quad E_0 = NBS\omega`,
            n: R`$\omega = 2\pi f$; khung quay $n$ vòng/giây ⇒ $\omega = 2\pi n$. Máy có $p$ cặp cực, rôto quay $n$ vòng/s ⇒ $f = pn$.` },
          { t: 'Dòng điện xoay chiều', f: R`i = I_0\cos(\omega t + \varphi_i),\quad I = \dfrac{I_0}{\sqrt2},\quad U = \dfrac{U_0}{\sqrt2}`,
            n: R`Giá trị hiệu dụng: dòng không đổi gây cùng nhiệt lượng trên điện trở. Điện lưới Việt Nam: $U = 220\ \mathrm V$, $f = 50\ \mathrm{Hz}$ ⇒ $U_0 \approx 311\ \mathrm V$.` },
          { t: 'Công suất tỏa nhiệt trên điện trở', f: R`P = I^2R = \dfrac{U^2}{R},\qquad Q = I^2Rt`,
            n: R`Dùng giá trị **hiệu dụng**.`, trap: R`Thay $I_0$ vào sẽ ra gấp đôi.` },
          { t: 'Điện từ trường & sóng điện từ', f: R`\lambda = \dfrac{c}{f} = cT,\qquad \vec E \perp \vec B \perp \vec v`,
            n: R`Điện trường biến thiên sinh ra từ trường và ngược lại. Sóng điện từ là sóng ngang, truyền được trong chân không, mang năng lượng.` },
          { t: 'Thang sóng điện từ', ft: R`Bước sóng giảm dần: **vô tuyến → hồng ngoại → nhìn thấy → tử ngoại → tia X → tia γ**`,
            n: R`Bước sóng giảm dần ⇔ tần số (và năng lượng photon) tăng dần. Ánh sáng nhìn thấy: khoảng 380–760 nm.` }
        ]
      },
      {
        id: 'hatnhan', title: 'Chương IV. Vật lí hạt nhân',
        items: [
          { t: 'Kí hiệu hạt nhân', f: R`{}^{A}_{Z}\mathrm{X}:\quad Z \text{ proton},\quad N = A - Z \text{ neutron}`,
            n: R`$A$: số nucleon (số khối). Đồng vị: cùng $Z$, khác $N$. Bán kính hạt nhân $R \approx 1{,}2\cdot10^{-15}A^{1/3}\ \mathrm m$.` },
          { t: 'Độ hụt khối', f: R`\Delta m = Zm_p + (A - Z)m_n - m_X`,
            n: R`$m_X$: khối lượng **hạt nhân** (không phải nguyên tử).` },
          { t: 'Năng lượng liên kết', f: R`W_{\text{lk}} = \Delta m\,c^2\qquad (1\ \mathrm u\cdot c^2 = 931{,}5\ \mathrm{MeV})`,
            n: R`Thay $\Delta m$ tính bằng u ⇒ nhân 931,5 ra MeV.` },
          { t: 'Năng lượng liên kết riêng', f: R`\varepsilon = \dfrac{W_{\text{lk}}}{A}`,
            n: R`Càng lớn ⇒ hạt nhân càng **bền**. Bền nhất khi $A \approx 50$–$80$ (Fe, Ni: $\approx 8{,}8\ \mathrm{MeV/nucleon}$).`,
            trap: R`So sánh độ bền phải dùng $\varepsilon$, không dùng $W_{\text{lk}}$.` },
          { t: 'Phản ứng hạt nhân', f: R`\Delta E = (m_{\text{trước}} - m_{\text{sau}})c^2`,
            n: R`$\Delta E > 0$: tỏa năng lượng; $\Delta E < 0$: thu năng lượng. Bảo toàn: **số nucleon, điện tích, năng lượng toàn phần, động lượng**.`,
            trap: R`**Không** bảo toàn khối lượng nghỉ, số proton, số neutron.` },
          { t: 'Phân hạch & nhiệt hạch', f: R`\mathrm n + {}^{235}_{92}\mathrm U \to \mathrm X + \mathrm Y + k\,\mathrm n\ (\approx 200\ \mathrm{MeV})`,
            n: R`Phân hạch: hạt nhân nặng vỡ đôi (lò phản ứng). Nhiệt hạch: hạt nhân nhẹ kết hợp, cần nhiệt độ rất cao (Mặt Trời).` },
          { t: 'Các loại phóng xạ', f: R`\alpha:\ {}^{A}_{Z}\mathrm X \to {}^{A-4}_{Z-2}\mathrm Y + {}^{4}_{2}\mathrm{He}\qquad \beta^-:\ Z+1\qquad \beta^+:\ Z-1\qquad \gamma:\ A, Z \text{ không đổi}`,
            n: R`$\beta^-$: $n \to p + e^- + \bar\nu$. $\beta^+$: $p \to n + e^+ + \nu$. Tia $\gamma$ là sóng điện từ, không lệch trong điện trường, từ trường.` },
          { t: 'Định luật phóng xạ', f: R`N = N_0\,2^{-t/T} = N_0\,e^{-\lambda t},\qquad \lambda = \dfrac{\ln 2}{T}`,
            n: R`$T$: chu kì bán rã, $\lambda$: hằng số phóng xạ. Tương tự cho khối lượng: $m = m_0\,2^{-t/T}$. Số hạt đã phân rã: $\Delta N = N_0\left(1 - 2^{-t/T}\right)$.`,
            trap: R`Đọc kỹ "còn lại" hay "đã phân rã". Sau $2T$ vẫn còn $\tfrac14$, không phải hết.` },
          { t: 'Độ phóng xạ', f: R`H = \lambda N = H_0\,2^{-t/T}\qquad [H] = \mathrm{Bq} = \text{phân rã/s}`,
            n: R`Khi tính $H$ (Bq), $\lambda$ phải đổi ra $\mathrm{s^{-1}}$.` },
          { t: 'Số hạt nhân trong khối lượng m', f: R`N = \dfrac{m}{M}N_A`,
            n: R`$M$ (g/mol) $\approx A$. Ví dụ 1 g $\nuc{235}{92}{U}$ có $\approx 2{,}56\cdot10^{21}$ hạt nhân.` },
          { t: 'Tính tuổi / thời gian', f: R`t = T\log_2\dfrac{N_0}{N} = \dfrac{T}{\ln2}\ln\dfrac{N_0}{N}`,
            n: R`Dùng trong định tuổi bằng carbon-14 ($T \approx 5730$ năm).` },
          { t: 'An toàn phóng xạ', ft: R`**Giảm thời gian** tiếp xúc · **tăng khoảng cách** tới nguồn · **che chắn** phù hợp.`,
            n: R`Che chắn: $\alpha$ bị chặn bởi tờ giấy; $\beta$ bởi tấm nhôm vài mm; $\gamma$ cần chì, bê tông dày.` }
        ]
      }
    ]
  };
})();
