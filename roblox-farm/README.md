# 🌾 Nông Trại Tycoon – Game Roblox co-op

Game nông trại nhiều người chơi: mỗi người một mảnh ruộng, mua hạt → trồng → tưới → thu hoạch → bán lấy Xu → nâng cấp. Bạn bè trong cùng server có thể **tưới cây giúp nhau** để cây lớn nhanh hơn và nhận Xu thưởng.

Bản đồ (nền cỏ, 6 mảnh ruộng, quầy bán, cửa hàng) và giao diện đều **tự tạo bằng code**, bạn chỉ cần dán 5 script vào Roblox Studio.

---

## 1. Tạo game trong Roblox Studio

1. Mở **Roblox Studio** → **New** → chọn template **Baseplate**.
2. Bấm **File › Publish to Roblox** (bắt buộc, vì DataStore chỉ chạy với game đã publish).
3. Vào **Home › Game Settings › Security** → bật **Enable Studio Access to API Services** → **Save**.
   *(Thiếu bước này game vẫn chơi được nhưng sẽ không lưu tiến trình.)*
4. (Nên làm) **Game Settings › Places** → sửa **Max Players = 6** (bản đồ có 6 mảnh ruộng).

## 2. Dán script

Mở cửa sổ **Explorer** (View › Explorer). Với mỗi dòng dưới đây: chuột phải vào thư mục cha → **Insert Object** → chọn đúng **loại** → đổi tên **đúng y hệt** → mở ra, xoá code mẫu, dán toàn bộ nội dung file.

| # | Thư mục cha trong Explorer | Loại (Insert Object) | Tên | Nội dung lấy từ file |
|---|---|---|---|---|
| 1 | `ReplicatedStorage` | **ModuleScript** | `GameConfig` | `ReplicatedStorage/GameConfig.lua` |
| 2 | `ServerScriptService` | **ModuleScript** | `DataManager` | `ServerScriptService/DataManager.lua` |
| 3 | `ServerScriptService` | **ModuleScript** | `MapBuilder` | `ServerScriptService/MapBuilder.lua` |
| 4 | `ServerScriptService` | **Script** | `FarmServer` | `ServerScriptService/FarmServer.server.lua` |
| 5 | `StarterPlayer › StarterPlayerScripts` | **LocalScript** | `FarmClient` | `StarterPlayer/StarterPlayerScripts/FarmClient.client.lua` |

> ⚠️ Sai **loại** (ví dụ Script thay vì ModuleScript) hoặc sai **tên** là lỗi hay gặp nhất. Nếu game không chạy, mở **View › Output** để xem lỗi màu đỏ.

## 3. Chơi thử

Bấm **Play** (F5):

1. Bạn xuất hiện ở cổng ruộng có biển **"🌻 Ruộng của <tên bạn>"**, được tặng 50 Xu và 3 hạt Lúa mì.
2. Đến ô đất nâu → nhấn **E** để trồng (trên điện thoại: chạm vào nút hiện ra).
3. Nhấn **E** lần nữa khi cây đang lớn để **tưới nước 💧** (nhanh hơn 20%).
4. Cây chín (quả phát sáng, chữ "Chín!") → nhấn **E** để thu hoạch.
5. Ra **💰 QUẦY BÁN** ở giữa bản đồ → giữ **E** để bán hết.
6. Bấm nút **🛒 Cửa hàng** (hoặc đến quầy CỬA HÀNG) để mua thêm hạt và nâng cấp.
7. Bấm **Tab** để xem bảng xếp hạng (Xu, Thu hoạch).

**Thử nhiều người:** tab **Test** → **Clients and Servers** → chọn **2 Players** → **Start**. Kiểm tra: mỗi người một ruộng; người khác không trồng/thu hoạch được trên ruộng của bạn, nhưng tưới giúp được (+2 Xu).

**Thử lưu tiến trình:** chơi một lúc → **Stop** → **Play** lại: Xu, hạt giống, nâng cấp và cây đang trồng vẫn còn (cây vẫn tiếp tục lớn cả khi bạn offline!).

## 4. Nội dung game

| Cây | Giá hạt | Thời gian lớn | Giá bán | Mở khoá khi đã thu hoạch |
|---|---|---|---|---|
| 🌾 Lúa mì | 5 | 10s | 10 | 0 |
| 🥕 Cà rốt | 15 | 20s | 32 | 10 |
| 🍅 Cà chua | 40 | 35s | 90 | 30 |
| 🎃 Bí ngô | 100 | 60s | 240 | 75 |
| 🍉 Dưa hấu | 250 | 90s | 620 | 150 |
| 🌽 Ngô vàng | 600 | 2p30s | 1.600 | 300 |

| Nâng cấp | Tác dụng | Số cấp |
|---|---|---|
| 🚜 Mở rộng ruộng | +4 ô đất (4 → 16) | 3 |
| 🧪 Phân bón | Cây lớn nhanh hơn 15%/cấp | 5 |
| 💰 Thương lái | Giá bán +20%/cấp | 5 |

## 5. Tự chỉnh game

Mọi con số nằm trong **`GameConfig`**: giá, thời gian, số Xu ban đầu, giá nâng cấp, phần thưởng tưới giúp...

- **Thêm cây mới:** thêm một mục vào `GameConfig.Crops` (ví dụ `Strawberry = { Name = "Dâu tây", Emoji = "🍓", ... }`) và thêm `"Strawberry"` vào `GameConfig.CropOrder`.
- **Xoá sạch dữ liệu mọi người** (ví dụ trước khi ra mắt chính thức): đổi `GameConfig.DataStoreName` thành tên mới.

## 6. Cách code hoạt động (cho ai muốn học)

- **Server quyết định mọi thứ** (`FarmServer`): client chỉ *gửi yêu cầu* ("mua 10 hạt cà rốt") qua RemoteEvent, server kiểm tra đủ Xu / đã mở khoá rồi mới thực hiện → chống hack.
- **ProximityPrompt** trên từng ô đất xử lý trồng / tưới / thu hoạch.
- Cây lưu **thời điểm trồng** (`os.time()`), nên thời gian còn lại luôn được tính đúng kể cả sau khi thoát game.
- **DataManager** lưu bằng DataStore: thử lại khi lỗi, tự lưu mỗi 60 giây, lưu khi thoát và khi server tắt. Nếu tải lỗi, game sẽ không ghi đè lên dữ liệu cũ.
- **FarmClient** tự dựng toàn bộ giao diện bằng code và vẽ lại mỗi khi server gửi `StateChanged`.
