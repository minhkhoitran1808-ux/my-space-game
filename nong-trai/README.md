# 🌾 Nông Trại Vui Vẻ – Giai đoạn 1: Lõi trồng trọt

Game trồng trọt "đúng nghĩa" trên Roblox: mỗi người một **đảo riêng**, tự tay **cuốc đất → gieo hạt → tưới nước mỗi ngày → bón phân → cắt cỏ, diệt sâu → thu hoạch**, theo **ngày/đêm và 4 mùa**. Nông sản có **1–3 sao** tuỳ cách chăm.

Thiết kế hình ảnh đã duyệt: https://claude.ai/artifact/BfqGGJoktPdgxZZcASBDRL

---

## 1. Mở game (cách nhanh nhất)

1. Tải file **`build/NongTraiVuiVe.rbxlx`** trong thư mục này về máy (trên GitHub: bấm vào file → nút **Download raw file**).
2. Mở **Roblox Studio** → **File › Open from File…** → chọn `NongTraiVuiVe.rbxlx`.
3. **File › Publish to Roblox** (tạo game mới).
4. **Home › Game Settings › Security** → bật **Enable Studio Access to API Services** → **Save** (để lưu tiến trình).
5. **Game Settings › Places** → **Max Players = 8** (bản đồ có 8 đảo).
6. Bấm **Play**.

## 2. Cách chơi

| Phím (máy tính) | Công cụ | Dùng để |
|---|---|---|
| 1 | ⛏️ Cuốc | Biến cỏ thành luống đất; dọn đá/gốc cây (3 nhát) |
| 2 | 💧 Bình tưới | Tưới ô đất (15 lần/bình, múc lại ở **Giếng**) |
| 3 | 🌱 Túi hạt | Gieo hạt đang chọn (hàng chọn hạt hiện khi cầm túi) |
| 4 | 🌾 Liềm | Cắt cỏ dại; thu hoạch cây đã chín (viền vàng) |
| 5 | 🧪 Phân bón | +40 màu mỡ cho ô đất |
| 6 | 💨 Bình xịt | Diệt sâu |

Trên điện thoại: chạm vào công cụ ở thanh dưới, rồi **chạm vào ô đất**. Nếu không chạm trúng, game dùng ô ngay trước mặt nhân vật. Ô đang nhắm có viền trắng. Bảng bên phải cho biết tình trạng ô và nên làm gì tiếp.

**Luật trồng trọt**
- 1 ngày trong game = **12 phút** thật. 1 mùa = 7 ngày. Ngày mới bắt đầu lúc **6:00 sáng**.
- Cây chỉ lớn khi đất **được tưới trong ngày**. Đến bình minh thì cây lớn thêm 1 ngày và **đất khô lại**, nên phải tưới tiếp.
- Quên tưới hoặc có sâu thì cây **đứng yên** và bị trừ điểm chất lượng (không chết). Có cỏ dại thì cây chỉ lớn nửa ngày.
- **Chất lượng**: chăm đủ (không bỏ tưới, cỏ, sâu) được 2 sao. Thêm **đất màu mỡ ≥ 60** (bón phân) được **3 sao**. Giá bán ×1 / ×1,25 / ×1,5.
- Mỗi lần thu hoạch, đất mất 15 màu mỡ.
- **Mùa**: tiệm chỉ bán hạt đúng mùa. Hết mùa thì cây trái mùa ngừng lớn tới mùa sau.
- Dâu tây, thanh long: **thu nhiều lần**.
- Thoát game: cây không lớn khi bạn offline. Vào lại thì được tính bù 1 ngày nếu hôm trước đã tưới.

**Đi lại**: nút **🧭 Đi lại** (bên trái) hoặc đứng lên cổng tím. **Đảo Chợ** ở giữa có: Tiệm hạt Bà Bảy, Quầy thu mua (bán tất cả), Giếng.

**Mở rộng**: đứng giữa khu đất bị khoá trên đảo → giữ **E** để mua Khu 2 (500 Xu), Khu 3 (1.500), Khu 4 (4.000).

**Chơi cùng bạn**: dùng **🧭 Đi lại › Thăm đảo …**. Khách được **tưới, cắt cỏ, diệt sâu** giúp. Chỉ chủ đảo được cuốc, gieo, bón phân và thu hoạch.

## 3. Danh sách test (bạn kiểm tra giúp mình)

- [ ] Vào game: xuất hiện trên đảo có biển "Đảo của <tên bạn>", có 100 Xu, 6 hạt rẻ nhất của mùa hiện tại, 3 phân bón.
- [ ] Cuốc ô cỏ thành luống nâu nhạt. Đá/gốc cây mất sau 3 nhát.
- [ ] Gieo hạt. Tưới thì ô sẫm màu. Bảng bên phải hiện đúng "Đất ướt".
- [ ] Qua bình minh (đồng hồ 6:00): cây lớn hơn, đất khô lại. Ô không tưới thì cây đứng yên.
- [ ] Thấy cỏ dại / sâu xuất hiện sau một thời gian. Liềm và Bình xịt xử lý được.
- [ ] Cây chín có viền vàng. Liềm thu hoạch được nông sản kèm sao.
- [ ] Sang Đảo Chợ: mua hạt, mua phân, bán ở Quầy thu mua, múc nước ở Giếng.
- [ ] Mua Khu 2: tấm phủ biến mất, ô đất mới xuất hiện (có đá/gốc cây).
- [ ] **Test › Device** chọn một điện thoại (ví dụ iPhone): bấm được các nút, chạm vào ô đất được.
- [ ] **Test › Clients and Servers › 2 Players**: mỗi người một đảo; thăm đảo bạn, tưới giúp được nhưng không thu hoạch được.
- [ ] Stop rồi Play lại: Xu, hạt, nông sản, ô đất và cây vẫn còn.

**Mẹo test nhanh**: mở `ReplicatedStorage › Shared › Config › Game`, sửa `DayLength = 720` thành `DayLength = 60` (1 ngày = 1 phút) để thấy cây lớn nhanh. Nhớ sửa lại trước khi publish thật.

Nếu có lỗi, mở **View › Output**, chụp màn hình các dòng màu đỏ gửi cho Claude.

## 4. Cập nhật code về sau bằng Rojo (không cần dán tay)

1. Cài **Rojo** theo https://rojo.space/docs/v7/getting-started/installation/ (cài cả plugin Rojo trong Studio).
2. Tải repo này về máy, mở terminal trong thư mục `nong-trai/`, chạy: `rojo serve`
3. Trong Studio: tab **Plugins › Rojo › Connect**. Mọi file trong `src/` được đồng bộ vào game.

Muốn dựng lại file game: `rojo build default.project.json -o build/NongTraiVuiVe.rbxlx`

## 5. Cấu trúc code

```
src/shared/   (ReplicatedStorage.Shared)
  Config/Crops.luau     12 loại cây theo mùa: giá, số ngày lớn, màu, hình dáng
  Config/Game.luau      mọi thông số cân bằng: thời gian, nước, phân, cỏ/sâu, khu đất…
  FarmLogic.luau        LUẬT trồng trọt (thuần, có test)
  GameTime.luau         đổi giờ thật sang lịch trong game (mọi server chung 1 lịch)
src/server/   (ServerScriptService.Server)
  Main.server.luau      khởi động, người chơi vào/ra, đi lại
  DataService           lưu DataStore có khoá phiên (chống mất/nhân bản đồ)
  TimeService           ngày/đêm, báo sang giờ mới & bình minh
  WorldBuilder, Models  dựng biển, đảo, nhà, giếng, cây, công cụ bằng code
  IslandService         giao đảo, tạo ô đất
  FarmService           dùng công cụ, cỏ/sâu theo giờ, cây lớn lúc bình minh, mua khu đất
  ShopService           tiệm hạt, phân bón, quầy thu mua
src/client/   (StarterPlayerScripts.Client)
  HUD, Hotbar, ToolController, TilePopup, Shop, Inventory, Travel, Notifications
tests/FarmLogic.spec.luau   28 test cho luật trồng trọt
```

Chạy test: `luau tests/FarmLogic.spec.luau` (cần Luau CLI).

## 6. Giai đoạn tiếp theo

- **Giai đoạn 2:** thời tiết (mưa tự tưới, nắng gắt, bão) + 4 sự kiện siêu nhiên & cây biến dị, nhà kính.
- **Giai đoạn 3:** giá chợ dao động, đơn hàng NPC, máy chế biến, cấp nông dân, nâng cấp công cụ, máy phun nước.
- **Giai đoạn 4:** bang hội 5 người, đảo bang hội, xếp hạng; giao dịch giữa người chơi.
- **Giai đoạn 5:** nhiệm vụ & cốt truyện, sổ sưu tập, trang trí.
