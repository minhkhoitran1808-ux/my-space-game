# RESEARCH.md — Nghiên cứu thị trường sản phẩm số tại Việt Nam

_Ngày nghiên cứu: 20/10/2026. Người thực hiện: Claude (vai trò founder/kỹ sư tự chủ)._

## 0. Phương pháp và giới hạn (đọc trước)

- Dữ liệu lấy bằng công cụ tìm kiếm web. Công cụ đọc trang trực tiếp **không mở được tên miền .vn** trong môi trường này, nên mọi số liệu bên dưới lấy từ **đoạn trích kết quả tìm kiếm** của các bài báo/trang được dẫn link. Mình chưa đọc toàn văn từng văn bản pháp luật gốc.
- Không có công cụ đo lượng tìm kiếm (kiểu Google Keyword Planner) → mức "nhu cầu" được suy ra từ **bằng chứng gián tiếp**: báo chí đưa tin về nỗi đau, quy định mới bắt buộc, số lượng người trong nhóm khách, và việc đã có người trả tiền cho sản phẩm tương tự.
- Mọi con số không có link đi kèm đều được ghi rõ **"ước lượng"**. Không có con số doanh thu nào được bịa ra.
- Các nguồn đôi khi mâu thuẫn nhau (ví dụ ngưỡng thuế 500 triệu hay 1 tỷ, biểu giá điện 5 hay 6 bậc). Mình ghi lại mâu thuẫn thay vì chọn bừa.

## 1. Bối cảnh vĩ mô năm 2026 (vì sao bây giờ)

Ba thay đổi lớn trong năm 2026 tạo ra "nỗi đau mới" mà công cụ cũ chưa phục vụ kịp:

1. **Bỏ thuế khoán từ 01/01/2026.** Hộ/cá nhân kinh doanh phải tự kê khai, ghi sổ ([MISA](https://sme.misa.vn/342561/thue-khoan-ho-kinh-doanh/), [LuatVietnam](https://luatvietnam.vn/tin-phap-luat/5-cau-hoi-thuong-gap-ve-thue-doi-voi-ho-kinh-doanh-tu-2026-230-105403-article.html)). Thông tư 152/2025/TT-BTC thay Thông tư 88, có mẫu sổ doanh thu S1a-HKD ([LuatVietnam](https://luatvietnam.vn/ke-toan/thong-tu-152-2025-tt-btc-huong-dan-ke-toan-cho-ho-kinh-doanh-ca-nhan-kinh-doanh-423164-d1.html), [xcyber](https://xcyber.vn/mau-so-s1a-hkd/)).
2. **Ngưỡng không chịu thuế nâng lên 1 tỷ đồng/năm** theo Nghị định 141/2026/NĐ-CP, áp dụng từ 01/01/2026 ([Cổng Chính phủ – toàn văn](https://xaydungchinhsach.chinhphu.vn/toan-van-nghi-dinh-so-141-2026-nd-cp-nang-nguong-doanh-thu-khong-phai-chiu-thue-len-1-ty-dong-119260504154326455.htm)). Dưới ngưỡng vẫn phải **thông báo doanh thu** cho cơ quan thuế ([MISA eShop](https://www.misaeshop.vn/?p=41101), [VietnamFinance](https://vietnamfinance.vn/nguoi-cho-thue-nha-doanh-thu-duoi-1-ty-dong-nam-can-lam-gi-d146149.html)).
3. **Phạt nặng chủ trọ thu tiền điện cao hơn giá quy định**: Nghị định 133/2026/NĐ-CP, hiệu lực 25/5/2026, phạt **20–30 triệu đồng** và buộc hoàn trả phần thu vượt (trước đây 7–10 triệu) ([LuatVietnam](https://luatvietnam.vn/tin-van-ban-moi/tu-25-5-2026-chu-nha-thu-tien-dien-cua-nguoi-thue-cao-hon-quy-dinh-bi-phat-den-30-trieu-dong-186-108536-article.html), [Tiền Phong](https://tienphong.vn/chu-tro-thu-tien-dien-gia-cat-co-se-bi-xu-ly-ra-sao-post1843304.tpo), [Tuổi Trẻ](https://tuoitre.vn/chu-tro-thu-tien-dien-sai-se-bi-phat-nang-nguoi-thue-va-chu-nha-deu-co-noi-niem-rieng-20260503075052179.htm)).

Ngoài ra: **phí sàn TMĐT tăng liên tục năm 2026** (Shopee nhiều đợt tháng 5/2026; TikTok Shop phí giao dịch 6% từ 9/5/2026, hoa hồng mặc định 14%) ([Sapo](https://www.sapo.vn/blog/cap-nhat-phi-san-tmdt-thang-5-2026), [VCCI](https://vcci.com.vn/tin-tuc/shopee-tiktok-shop-tang-manh-phi-san-nhieu-shop-cang-ban-cang-lo), [BigSeller](https://www.bigseller.com/blog/articleDetails/phi-tiktok-shop-moi-nhat-2026.4733.htm)).

## 2. Danh sách 12 cơ hội

Ký hiệu công sức: **Xây** = công làm MVP (ước lượng), **Duy trì** = giờ/tuần sau khi ra mắt (ước lượng).

### CH1. Bộ công cụ tính tiền phòng trọ "đúng luật" (điện, nước, phiếu thu) cho chủ trọ nhỏ

- **Khách hàng:** chủ nhà trọ/chủ dãy phòng nhỏ (5–50 phòng), thường tự ghi sổ tay hoặc Excel. Riêng TP.HCM có **60.470 nhà trọ** do người dân tự xây (Sở Xây dựng TP.HCM, dẫn qua [Nhadautu](https://nhadautu.vn/tphcm-can-khuyen-khich-doanh-nghiep-bat-dong-san-dau-tu-phat-trien-phong-tro-cho-thue-nha-o-xa-hoi-gia-re-d30488.html); bài không ghi rõ năm). HoREA ước tính hộ gia đình, cá nhân đáp ứng ~80% nhu cầu phòng trọ (cùng nguồn).
- **Nỗi đau:**
  - Từ 25/5/2026, thu tiền điện cao hơn quy định bị phạt 20–30 triệu ([LuatVietnam](https://luatvietnam.vn/tin-van-ban-moi/tu-25-5-2026-chu-nha-thu-tien-dien-cua-nguoi-thue-cao-hon-quy-dinh-bi-phat-den-30-trieu-dong-186-108536-article.html)). Khảo sát báo chí: nhiều nơi đang thu 3.500–5.000đ/kWh, trong khi bậc cao nhất là 3.460đ/kWh ([VnBusiness](https://vnbusiness.vn/nguoi-thue-tro-chu-y-gia-dien-vuot-3460-dong-la-sai-quy-dinh.html)).
  - Tổng tiền điện thu của người thuê không được vượt hóa đơn điện hằng tháng; không được cộng chi phí thang máy, đèn hành lang, camera vào tiền điện ([Saigon Times](https://thesaigontimes.vn/saigontimes/tphcm-siet-tinh-trang-doi-gia-dien-nha-tro-thu-sai-phat-den-30-trieu-dong/)).
  - Chủ trọ lo lỗ, tính tăng giá nhà ([VnBusiness](https://vnbusiness.vn/lo-bi-phat-thu-tien-dien-chu-tro-tinh-tang-gia-nha.html), [Phụ nữ VN/Baomoi](https://baomoi.com/siet-gia-dien-nha-tro-chu-tro-noi-gi-c55093517.epi)) → cần tách bạch tiền phòng, phí dịch vụ và tiền điện để minh bạch.
  - Từ 2026 chủ cho thuê dưới 1 tỷ/năm vẫn phải thông báo doanh thu (mẫu 01/TKN-CNKD, theo [MISA eShop](https://www.misaeshop.vn/40795/ke-khai-thue-ho-kinh-doanh-cho-thue-tai-san/)) → cần con số doanh thu cả năm.
  - Quy định chi tiết (Thông tư 60/2025/TT-BCT): thuê ≥12 tháng có đăng ký cư trú được cấp định mức theo số người; thuê <12 tháng mà chủ không khai đủ số người thì áp giá bậc 101–200 kWh cho toàn bộ sản lượng ([Thư viện pháp luật](https://thuvienphapluat.vn/hoi-dap-phap-luat/quy-dinh-ve-thu-tien-dien-nha-tro-2026-nhu-the-nao-138089756.html)). Rất nhiều chủ trọ không nắm được.
- **Đối thủ:** LOZIDO (miễn phí, 4,6★/320 đánh giá trên App Store — [App Store](https://apps.apple.com/vn/app/id1560928216)); Khutro.com; các app "Quản lý phòng trọ"; file Excel miễn phí trên mạng ([Sforum](https://cellphones.com.vn/sforum/huong-dan-luu-va-su-dung-file-quan-ly-phong-tro-bang-excel-chi-trong-3-buoc)); phần mềm như SmartOS. Chưa thấy đối thủ nào lấy "tính tiền điện **không vượt hóa đơn EVN** + cảnh báo vượt giá" làm tính năng chính (chưa kiểm chứng hết, cần xem trực tiếp app).
- **Giá khách chấp nhận:** Khutro.com gói 1 **60.000đ/tháng cho tối đa 10 phòng** ([Thế Giới Di Động](https://www.thegioididong.com/game-app/top-11-phan-mem-quan-ly-phong-tro-nha-tro-mien-phi-tot-nhat-1335391); bài có thể đã cũ) → bằng chứng có người trả tiền định kỳ. Giá bán một lần 99.000–199.000đ là **ước lượng** hợp lý (bằng 2–3 tháng thuê bao).
- **Công sức:** Xây 15–25 giờ (web app chạy offline + file Excel). Duy trì 1–2 giờ/tuần; giá điện chỉ đổi vài lần/năm và người dùng nhập được.
- **Rủi ro:** Pháp lý thấp nếu công cụ **chỉ chia lại đúng số tiền trên hóa đơn EVN** (không tự "tư vấn luật") và ghi rõ là tham khảo. Rủi ro thị trường trung bình: app miễn phí mạnh (LOZIDO), chủ trọ lớn tuổi ít mua online. Dữ liệu ở máy người dùng → không thu thập dữ liệu cá nhân.

### CH2. Bảng tính giá bán & lãi thật cho người bán trên Shopee/TikTok Shop

- **Khách hàng:** nhà bán nhỏ trên sàn. Q1/2025 còn ~472,5 nghìn shop có phát sinh đơn trên 4 sàn (Metric, dẫn qua [Báo Pháp luật](https://doanhnhan.baophapluat.vn/hon-600-000-shop-chia-tay-thi-truong-thuong-mai-dien-tu-trong-nam-2025-da-tang-cua-shopee-cham-lai.html)); TikTok Shop có hơn 266.000 nhà bán có doanh thu nửa đầu 2025 (YouNet ECI, [Báo Pháp luật](https://doanhnhan.baophapluat.vn/thi-truong-tmdt-6-thang-dau-nam-2025-tiktok-shop-vuot-shopee-ve-so-luong-nha-ban-84838.html)).
- **Nỗi đau:** phí tăng nhiều đợt, "càng bán càng lỗ" ([VCCI](https://vcci.com.vn/tin-tuc/shopee-tiktok-shop-tang-manh-phi-san-nhieu-shop-cang-ban-cang-lo)); SHS dự báo tỷ lệ chi phí/giá trị đơn có thể lên ~33,8% năm 2026 (dự báo, cùng nguồn). Sàn khấu trừ thuế 1,5% với hàng hóa ([LuatVietnam](https://luatvietnam.vn/thue-phi-le-phi/ho-ca-nhan-kinh-doanh-online-bi-khau-tru-thue-bao-nhieu-565-102490-article.html)).
- **Đối thủ:** **nhiều công cụ miễn phí**: Shopee Analytics, EcomProfit, Heightmedia, Allship ([shopeeanalytics.com](https://www.shopeeanalytics.com/), [EcomProfit](https://ecomprofit.mainnmedia.com/), [Heightmedia](https://heightmedia.vn/du-doan-doanh-so), [Allship](https://allship.vn/cong-cu-tinh-gia-ban-tren-tiktok-shop-shopee/)); phần mềm như BigSeller.
- **Giá khách chấp nhận:** chưa tìm được bằng chứng người bán trả tiền cho riêng bảng tính giá. Ước lượng 49.000–99.000đ nếu có thêm báo cáo lãi theo SKU/tháng.
- **Công sức:** Xây 10–15 giờ. Duy trì 2–3 giờ/tuần vì biểu phí đổi liên tục.
- **Rủi ro:** thị trường cao (đồ miễn phí sẵn có), dữ liệu phí nhanh lỗi thời.

### CH3. Sổ doanh thu cho hộ/cá nhân kinh doanh (mẫu S1a-HKD) + theo dõi ngưỡng 1 tỷ

- **Khách hàng:** hộ kinh doanh nhỏ, người bán online đa kênh.
- **Nỗi đau:** bỏ thuế khoán, phải ghi sổ; nhiều người tưởng doanh thu thấp thì không cần sổ ([Tạp chí Thuế](https://thuehaiquan.tapchikinhtetaichinh.vn/ho-kinh-doanh-khong-chiu-thue-chi-can-mot-so-theo-doi-doanh-thu-138151.html)); quy định đổi liên tục, nguồn mâu thuẫn (500 triệu vs 1 tỷ).
- **Đối thủ:** rất mạnh và miễn phí: Nhà nước cấp miễn phí phần mềm kế toán theo Điều 10 Nghị định 20/2026 ([VOH](https://voh.com.vn/phap-luat/ho-kinh-doanh-duoc-dung-phan-mem-ke-toan-tich-hop-mien-phi-647082.html), [LSVN](https://lsvn.vn/mien-phi-phan-mem-ke-toan-cho-ho-kinh-doanh-a168563.html)); Sapo, KiotViet, MISA eShop đều có gói/công cụ miễn phí ([Sapo](https://www.sapo.vn/blog/phan-mem-mien-phi-cho-ho-kinh-doanh)); MISA phát file Excel miễn phí.
- **Giá khách chấp nhận:** chưa có bằng chứng; ước lượng thấp (≤99.000đ) vì có đồ miễn phí.
- **Công sức:** Xây 8–12 giờ; duy trì 2–3 giờ/tuần theo dõi văn bản mới.
- **Rủi ro:** pháp lý cao (sai mẫu sổ/sai ngưỡng → khách bị phạt, mình mất uy tín); thị trường cao (cạnh tranh miễn phí từ Nhà nước và hãng lớn).

### CH4. Bảng tài chính cá nhân/gia đình theo "6 chiếc lọ" (Google Sheets tiếng Việt)

- **Khách hàng:** người đi làm trẻ, cặp vợ chồng trẻ.
- **Nỗi đau:** muốn áp dụng 6 chiếc lọ (rất phổ biến ở VN — [MoMo](https://www.momo.vn/blog/phuong-phap-6-chiec-lo-tai-chinh-c181dt1615), [Home Credit](https://www.homecredit.vn/blog/quy-tac-6-chiec-lo-tai-chinh)) nhưng app thì rườm rà.
- **Đối thủ:** MISA Sổ thu chi miễn phí có sẵn 6 lọ ([MISA AMIS](https://amis.misa.vn/187949/quy-tac-6-chiec-lo-va-50-30-20/)), Money Lover, file Excel miễn phí (Simplize). Quốc tế có template trả phí trên Gumroad.
- **Giá khách chấp nhận:** không tìm được giá bán template tiếng Việt; ước lượng 29.000–79.000đ.
- **Công sức:** Xây 5–8 giờ; duy trì ~0.
- **Rủi ro:** pháp lý rất thấp; thị trường cao (bão hòa, đồ miễn phí tốt).

### CH5. Bộ kế hoạch cưới: ngân sách + danh sách khách + sổ mừng cưới

- **Khách hàng:** cặp đôi sắp cưới, gia đình hai bên.
- **Nỗi đau:** chi phí cưới tăng, áp lực tiền mừng; khảo sát 4.000 độc giả VnExpress: 49% mừng theo mức chung, 41% theo khả năng ([VnExpress](https://vnexpress.net/an-cuoi-dat-do-4810963.html)). Thói quen ghi sổ mừng để "trả lễ" (kiến thức văn hóa phổ biến, không có số liệu).
- **Đối thủ:** "Planner Đám Cưới" (iOS, có tiếng Việt, Premium 12,99 USD/tháng — [App Store](https://apps.apple.com/us/app/%E5%A9%9A%E7%A6%AE%E8%A8%88%E5%8A%83%E7%AE%A1%E5%AE%B6-%E5%B9%B8%E7%A6%8F%E5%A4%A7%E6%97%A5/id6557050795?l=vi)); WeLogs ([App Store](https://apps.apple.com/us/app/welogs/id6755553069)); file Excel miễn phí.
- **Giá khách chấp nhận:** không có bằng chứng ở VN; ước lượng 49.000–99.000đ.
- **Công sức:** Xây 8–12 giờ; duy trì thấp, nhưng mỗi khách chỉ mua một lần trong đời → phải liên tục tìm khách mới.
- **Rủi ro:** pháp lý rất thấp; thị trường cao.

### CH6. Bảng chấm công & tính lương theo ca cho quán F&B nhỏ

- **Khách hàng:** chủ quán cafe/trà sữa có nhân viên part-time.
- **Nỗi đau:** tính lương theo giờ/ca thủ công, sai sót.
- **Đối thủ:** nhiều mẫu miễn phí: MISA AMIS, AZTAX, EasyHRM ([MISA](https://amis.misa.vn/94551/bang-cham-cong-theo-gio/), [AZTAX](https://aztax.com.vn/bang-cham-cong-theo-gio/), [EasyHRM](https://easyhrm.vn/?p=2006)); app POS có chấm công.
- **Giá khách chấp nhận:** không có bằng chứng; ước lượng 49.000–99.000đ.
- **Công sức:** Xây 6–10 giờ; duy trì thấp.
- **Rủi ro:** pháp lý trung bình (lương tối thiểu, BHXH, làm thêm giờ); thị trường cao.

### CH7. Bộ template Canva tiếng Việt cho tiệm spa/nail/quán ăn

- **Khách hàng:** chủ tiệm nhỏ cần bài đăng, menu, bảng giá.
- **Nỗi đau:** template quốc tế thiếu font tiếng Việt có dấu, không hợp văn hóa.
- **Đối thủ:** Canva có sẵn mẫu miễn phí; Creative Market, Gumroad (bộ 100 mẫu spa giá **29 USD** — [Gumroad](https://canvagator.gumroad.com/l/spa-and-wellness-canva-templates-for-social-media)).
- **Giá khách chấp nhận:** quốc tế 29 USD; VN chưa có bằng chứng, ước lượng 99.000–199.000đ.
- **Công sức:** Xây 20–30 giờ (thiết kế nặng; mình không thao tác trực tiếp được Canva). Duy trì thấp.
- **Rủi ro:** bản quyền font/ảnh/điều khoản Canva; phụ thuộc thẩm mỹ.

### CH8. Bộ gợi ý lời nhận xét học bạ tiểu học theo Thông tư 27

- **Khách hàng:** giáo viên tiểu học (mùa cao điểm cuối kỳ).
- **Nỗi đau:** viết hàng trăm lời nhận xét khác nhau cho từng học sinh.
- **Đối thủ:** rất nhiều trang miễn phí (Thư viện pháp luật, Hoatieu). Hoatieu bán gói Pro tải file **từ 99.000đ** ([Hoatieu](https://hoatieu.vn/bieu-mau/cach-ghi-nhan-xet-hoc-ba-lop-1-theo-thong-tu-22-138660)).
- **Giá khách chấp nhận:** ~99.000đ cho quyền tải nhiều tài liệu (Hoatieu).
- **Công sức:** Xây 10–15 giờ; theo mùa.
- **Rủi ro:** pháp lý thấp; thị trường cao (đồ miễn phí tràn lan), doanh số dồn vào 2 đợt/năm.

### CH9. Phiếu bài tập mầm non in được (tô chữ tiếng Việt, số, tô màu)

- **Khách hàng:** phụ huynh có con 3–6 tuổi, giáo viên mầm non.
- **Đối thủ:** Canva worksheet miễn phí, Quantrimang bộ tập tô miễn phí ([Canva](https://www.canva.com/vi_vn/worksheets/mau/mam-non/), [Quantrimang](https://quantrimang.com/mau-tap-to-chu-cai-181432)); vở tập tô bán ở nhà sách.
- **Giá khách chấp nhận:** không có bằng chứng giá file PDF; ước lượng 29.000–59.000đ.
- **Công sức:** Xây 20+ giờ (cần hình minh họa; ảnh AI có rủi ro chất lượng và bản quyền).
- **Rủi ro:** thị trường cao, bản quyền hình ảnh.

### CH10. Template Notion tiếng Việt (học tập/công việc)

- **Khách hàng:** sinh viên, nhân viên văn phòng dùng Notion.
- **Đối thủ:** kho template miễn phí của Notion; template quốc tế 5–19 USD ([Gumroad](https://anferneeck.gumroad.com/l/101-notion-system-ideas)); Notion Marketplace thu 10% ([Fungies](https://fungies.io/how-to-sell-notion-templates.md)).
- **Giá khách chấp nhận:** VN chưa có bằng chứng; [FPT Shop](https://fptshop.com.vn/tin-tuc/thu-thuat/notion-template-mau-150496) nói template nâng cao bán "từ vài USD đến hàng chục USD".
- **Công sức:** Xây 6–10 giờ.
- **Rủi ro:** thị trường cao (tệp người dùng Notion ở VN nhỏ — ước lượng).

### CH11. Bộ câu lệnh AI (prompt) cho người bán hàng nhỏ

- **Đối thủ:** cực nhiều, nhiều bộ miễn phí; giá quốc tế 5–500 USD ([Lilys](https://lilys.ai/notes/vi/sell-digital-products-20251212/top-ai-digital-products-2026)).
- **Rủi ro:** thị trường rất cao, giá trị khó chứng minh, dễ bị coi là "bán gió". Pháp lý thấp.

### CH12. Ebook "Thuế cho người bán online 2026"

- **Khách hàng:** người bán online bối rối về thuế.
- **Nỗi đau:** thật và lớn, nhưng quy định thay đổi liên tục (ngưỡng 500 triệu → 1 tỷ, hồi tố — [Thư viện pháp luật](https://thuvienphapluat.vn/ma-so-thue/phap-luat-thue/huong-dan-xu-ly-ho-kinh-doanh-duoi-1-ty-da-ke-khai-va-nop-thue-quy-12026-227291.html); Nghị định 252/2026 về khấu trừ qua sàn — [Đại biểu Nhân dân](https://daibieunhandan.vn/cach-tinh-thue-doi-voi-ho-kinh-doanh-ban-hang-online-sau-khi-bo-thue-khoan-10396920.html)).
- **Đối thủ:** hàng trăm bài miễn phí của MISA, LuatVietnam, Thư viện pháp luật, đại lý thuế.
- **Rủi ro:** **pháp lý cao nhất** — nội dung sai có thể khiến khách bị phạt; bản thân người viết không phải chuyên gia thuế. Loại.

## 3. Nhận định chung

- **Mẫu hình rõ nhất:** những gì "chung chung" (quản lý chi tiêu, chấm công, Notion, prompt) đều đã có đồ miễn phí tốt → khó bán. Cơ hội tốt nằm ở **nỗi đau mới do quy định 2026 tạo ra**, nơi công cụ cũ chưa kịp cập nhật.
- **Đáng chú ý nhất:** CH1 (chủ trọ + Nghị định 133/2026): nỗi đau có **mức phạt cụ thể 20–30 triệu**, báo lớn đưa tin dày (Tuổi Trẻ, Tiền Phong, Saigon Times, VnBusiness, LuatVietnam), tệp khách lớn và đã có bằng chứng chủ trọ trả tiền thuê bao (Khutro 60.000đ/tháng).
- **Nhóm thuế (CH3, CH12):** nhu cầu thật nhưng rủi ro pháp lý cao + Nhà nước phát phần mềm miễn phí → không phù hợp tiêu chí "ít rủi ro nhất".
- **Nền tảng thanh toán quốc tế** (Gumroad, Lemon Squeezy, Payhip): chưa xác nhận được hỗ trợ rút tiền về Việt Nam ([Lemon Squeezy – quốc gia hỗ trợ](https://docs.lemonsqueezy.com/help/getting-started/supported-countries)) → nên ưu tiên chuyển khoản ngân hàng/VietQR trong nước (xem LAUNCH/).
