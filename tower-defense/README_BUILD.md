# Bản build Tower Defense (v1.0.0) – Windows & Web

Build bằng **Godot 4.7.2**, export template chính thức (`windows_release_x86_64.exe`,
`web_nothreads_release.zip`). Thư mục `build/` không được đưa lên git (đã có trong `.gitignore`);
chạy lại các lệnh ở mục "Build lại" để tạo lại.

## Nội dung thư mục `build/`

```
build/
├── windows/
│   └── TowerDefense.exe          104 MB  (dữ liệu game đã gộp bên trong, chỉ cần 1 file)
├── web/                          ~38 MB  (gần như toàn bộ là engine index.wasm)
│   ├── index.html                trang chính
│   ├── index.js, index.wasm      engine Godot
│   ├── index.pck                 dữ liệu game + âm thanh + nội dung meta (~650 KB)
│   ├── index.audio*.worklet.js   xử lý âm thanh
│   └── index*.png                icon / ảnh khởi động
└── itch/                         ← FILE ĐỂ UPLOAD LÊN ITCH.IO
    ├── TowerDefense_Web.zip      10.2 MB (index.html nằm ở gốc zip)
    └── TowerDefense_Windows.zip  37 MB   (TowerDefense/TowerDefense.exe)
```

## Chạy bản Windows

1. Giải nén `TowerDefense_Windows.zip` (hoặc lấy thẳng `build/windows/TowerDefense.exe`).
2. Nhấp đúp `TowerDefense.exe`. Không cần cài đặt, không cần file nào khác.
3. Lần đầu, Windows SmartScreen có thể báo "Windows protected your PC" vì file chưa được ký số:
   bấm **More info → Run anyway**.

Yêu cầu: Windows 10/11 64-bit, card đồ hoạ hỗ trợ OpenGL 3.3 (gần như mọi máy từ 2012 trở lại đây).
Tiến độ và cài đặt lưu tại `%APPDATA%\Godot\app_userdata\Tower Defense\save.cfg`.

## Chạy bản Web trên máy

Trình duyệt **không** chạy được khi mở thẳng `index.html` bằng nhấp đúp (file://).
Cần một web server cục bộ:

```
cd build/web
python -m http.server 8000
```

Rồi mở `http://localhost:8000` bằng Chrome / Edge / Firefox.
Bản Web tắt đa luồng nên **không** cần cấu hình header COOP/COEP; chạy được trên itch.io,
GitHub Pages hay mọi hosting tĩnh. Tiến độ lưu trong bộ nhớ của trình duyệt (IndexedDB).

## Đưa lên itch.io

1. itch.io → **Upload new project**.
2. **Kind of project:** chọn **HTML**.
3. **Uploads:**
   - Upload `build/itch/TowerDefense_Web.zip` → tick **"This file will be played in the browser"**.
   - Upload `build/itch/TowerDefense_Windows.zip` → đánh dấu nền tảng **Windows**.
4. **Embed options** (cho bản Web):
   - Viewport dimensions: **1280 × 720**
   - Tick **Fullscreen button**
   - Không cần tick "SharedArrayBuffer support" (bản này không dùng đa luồng).
   - Không tick "Mobile friendly" (game cần chuột và bàn phím).
5. Save → xem trang thử (**View page**) trước khi chuyển sang Public.

Gợi ý phần mô tả: chuột trái đặt / chọn tháp, `1`–`4` chọn tháp, `Space` gọi wave,
`U` / `X` / `T` nâng cấp / bán / đổi mục tiêu, `Q` / `E` kỹ năng, `F` tốc độ, `P` tạm dừng.

## Đã kiểm tra

- **Smoke test** của project (130 phép kiểm tra, bot thắng cả 3 màn) đạt trước khi export.
- **Windows:** file là PE32+ x86-64 dạng GUI (không bật cửa sổ console), đã ghi tên sản phẩm và phiên bản
  1.0.0.0; dữ liệu gộp trong exe được nạp thử bằng Godot và vào tới menu chính, không lỗi.
  (Chưa chạy trực tiếp trên một máy Windows thật.)
- **Web:** chạy trong Chromium (WebGL 2) qua web server cục bộ, thao tác thật bằng chuột và bàn phím:
  menu → chọn màn → đặt tháp → gọi wave → chọn + nâng cấp tháp → kỹ năng Thiên thạch → tạm dừng;
  tải lại trang thì tiến độ vẫn còn. Console trình duyệt không có lỗi.

## Tối ưu đã áp dụng cho bản Web

- Renderer **Compatibility** (WebGL 2) – bắt buộc cho Web, nhẹ nhất.
- Template **không đa luồng** (`thread_support = false`): chạy mọi nơi, không cần header đặc biệt.
- Không bật GDExtension (`extensions_support = false`) và PWA → ít file thừa.
- Canvas tự co giãn theo khung (`canvas_resize_policy = Adaptive`), tự nhận bàn phím khi mở trang.
- Chỉ đóng gói dữ liệu cần thiết: thư mục `tests/` bị loại, file wave `data/*.json` được đưa vào.
- Ẩn nút "Thoát" trên Web (trình duyệt không cho game tự đóng tab).
- `index.wasm` (~38 MB, nén zip còn ~9.5 MB) là engine Godot chuẩn; muốn nhỏ hơn nữa phải tự biên dịch
  template riêng (tắt 3D, vật lý...), không cần thiết với game cỡ này.

## Build lại

Cần Godot 4.7.2 và export template cùng phiên bản:
**Editor → Manage Export Templates → Download and Install** (hoặc tải file
`Godot_v4.7.2-stable_export_templates.tpz` ở trang release của Godot rồi chọn **Install from File**).

Trong editor: **Project → Export… → Export All** (hoặc chọn từng preset → **Export Project**,
nhớ bỏ tick "Export With Debug").

Hoặc bằng dòng lệnh (chạy trong thư mục `tower-defense/`). Nên xoá bản cũ trước và đặt file
`build/.gdignore` để Godot không quét / gói nhầm bản build cũ vào bản mới (preset cũng đã loại `build/*`):

```
rm -rf build && mkdir -p build/windows build/web build/itch && touch build/.gdignore
godot --headless --export-release "Windows Desktop" build/windows/TowerDefense.exe
godot --headless --export-release "Web" build/web/index.html
```

Sau đó nén `build/web/*` (index.html ở gốc) và `build/windows/TowerDefense.exe` thành 2 file zip để upload.
