# Nhận xét code game "Phi Thuyền" (`index.html`, bản 1.4)

> Chỉ đọc và chạy thử — **không sửa** file game. Số dòng tham chiếu theo `index.html` hiện tại (593 dòng).
> Mỗi lỗi dưới đây đều đã được **tái hiện bằng trình duyệt thật** (`node tools/probe-game-bugs.js`) hoặc đọc trực tiếp từ code; các nghi vấn mà chạy thử cho thấy không phải lỗi được ghi ở mục cuối.

## Tóm tắt

Game chạy ổn, không có lỗi console, cấu trúc dễ đọc (HUD, kỹ năng, quái, hạt được tách thành hàm rõ ràng), có điều khiển cảm ứng và giao diện thích ứng điện thoại — rất tốt cho một dự án tự học. Ba vấn đề đáng sửa nhất:

| Ưu tiên | Vấn đề | Ảnh hưởng |
|---|---|---|
| 🔴 1 | Tốc độ game phụ thuộc tần số quét màn hình | Trên màn 120/144 Hz (nhiều điện thoại, laptop gaming) mọi thứ nhanh gấp 2–2,4 lần, hồi chiêu ngắn lại |
| 🔴 2 | Quái vừa bị đạn tiêu diệt vẫn trừ máu người chơi | Mất HP oan (đã tái hiện) |
| 🟠 3 | Thiếu xử lý `touchcancel` | Trên điện thoại có thể bị "kẹt" di chuyển và tự bắn mãi |

---

## 🔴 1. Game chạy theo khung hình, không theo thời gian

**Ở đâu:** dòng 217–218 (`cdMax: 600 // 10s * 60fps`), 492–493 (di chuyển `player.speed` mỗi khung), 496, 503, 507–508 (`frameCount % spawnRate`), 515, 542.

**Vì sao là lỗi:** `requestAnimationFrame` chạy theo tần số màn hình. Màn 60 Hz → đúng thiết kế; màn 120 Hz → quái rơi nhanh gấp đôi, kỹ năng E hồi trong 5 s thay vì 10 s, quái xuất hiện dày gấp đôi. Máy yếu (rớt xuống 30 fps) thì ngược lại.

**Cách sửa (đơn giản nhất):** đo thời gian giữa hai khung và nhân mọi vận tốc/bộ đếm với hệ số `dt`:

```js
let last = performance.now();
function loop(now) {
  if (!gameRunning) return;
  const dt = Math.min((now - last) / (1000 / 60), 3); // 1.0 ở 60 fps, 0.5 ở 120 fps; chặn 3 để tránh "nhảy cóc" khi chuyển tab
  last = now;
  if (!isPaused) { update(dt); draw(); }
  animationId = requestAnimationFrame(loop);
}
// trong update(dt):
player.x -= player.speed * dt;
e.y += e.speed * dt;
player.skills.e.cd = Math.max(0, player.skills.e.cd - dt);
spawnTimer -= dt; if (spawnTimer <= 0) { spawnEnemy(); spawnTimer = spawnRate; }  // thay cho frameCount % spawnRate
```

Đây cũng là đúng kiến thức Vật lý: $x \mathrel{+}= v\,\Delta t$ — cùng ý tưởng với tích phân số trong Orbit Lab.

## 🔴 2. Quái đã chết vẫn gây sát thương (đã tái hiện)

**Ở đâu:** dòng 519–538.

```js
if (e.hp <= 0) { killEnemy(e); enemies.splice(i, 1); }   // dòng 524: xóa quái…
break;
...
if (i < enemies.length && rectIntersect(player, e)) {     // dòng 530: …nhưng vẫn dùng biến e cũ
```

Sau `splice`, biến `e` vẫn trỏ tới quái vừa chết, còn điều kiện `i < enemies.length` vẫn đúng nếu trong mảng còn quái khác. Kết quả kiểm thử: quái chồng lên phi thuyền bị đạn giết, còn một quái khác ở xa → **HP giảm từ 3 xuống 2**. Ngoài ra dòng 538 `if (e.y > ch) enemies.splice(i, 1)` khi đó có thể xóa nhầm một quái khác.

**Cách sửa:** sau khi quái chết thì bỏ qua phần còn lại của vòng lặp:

```js
let killed = false;
for (let j = player.bullets.length - 1; j >= 0; j--) {
  ...
  if (e.hp <= 0) { killEnemy(e); enemies.splice(i, 1); killed = true; }
  break;
}
if (killed) continue;
```

## 🟠 3. Điều khiển cảm ứng: thiếu `touchcancel`, không có đa điểm chạm thật sự

**Ở đâu:** dòng 464–467. Khi hệ điều hành hủy chạm (thông báo bật lên, vuốt ra mép màn hình, cuộc gọi đến…), trình duyệt gửi `touchcancel` chứ không phải `touchend` → `keys.Left/Right` giữ `true`, `setInterval(shoot, 200)` chạy mãi. Thêm:

```js
['touchend', 'touchcancel'].forEach(ev => {
  touchLeft.addEventListener(ev, e => { e.preventDefault(); handleTouch('left', false); });
  touchRight.addEventListener(ev, e => { e.preventDefault(); handleTouch('right', false); });
});
```

Ngoài ra `gameOver()` (dòng 590) gọi `clearInterval(autoShootInt)` nhưng **không** đặt `autoShootInt = null`: sang ván mới, lần chạm đầu tiên thấy `autoShootInt` vẫn "có giá trị" nên **không tự bắn**. Và nếu thua khi đang giữ tay, `touchend` bị bỏ qua (vì `gameRunning = false` ở dòng 458) nên `keys.Left/Right` vẫn là `true` → ván mới phi thuyền tự trôi. Sửa: trong `gameOver()` thêm `autoShootInt = null; keys.Left = keys.Right = false;`.

## 🟡 Các điểm nên cải thiện (không gây lỗi ngay)

1. **`gainExp` chỉ lên tối đa 1 cấp mỗi lần** (dòng 572): `gainExp(400)` ở cấp 1 cho kết quả cấp 2 với 300/150 EXP (thanh EXP vượt 100 %). Hiện chưa xảy ra vì mỗi quái cho tối đa 100 EXP, nhưng sẽ lộ ra khi bạn tăng thưởng. Dùng `while (player.exp >= player.nextLevelExp) levelUp();`.
2. **Chữ HUD không nhất quán:** dòng 120 ghi `Level: 1`, dòng 575 đổi thành `LV: …` ngay khi bắt đầu.
3. **Hiệu năng vẽ:** `shadowBlur` được đặt cho **từng viên đạn** (dòng 555) và `Math.random()` cho độ sáng từng ngôi sao mỗi khung (dòng 549) — `shadowBlur` là thao tác đắt trên canvas. Đặt một lần cho cả nhóm, hoặc vẽ sẵn sprite phát sáng ra canvas phụ.
4. **Đổi kích thước cửa sổ khi đang chơi** (dòng 261–265): canvas đổi kích thước nhưng phi thuyền có thể nằm ngoài màn hình (khi thu nhỏ) và vị trí `y` không cập nhật. Kẹp lại: `player.x = Math.min(player.x, cw - player.w); player.y = ch - 100;`.
5. **Va chạm cầu năng lượng** (dòng 401) chỉ kiểm tâm quả cầu nằm trong hình chữ nhật → quả cầu bán kính 15 px "sượt" qua mép quái mà không trúng. Dùng va chạm tròn–chữ nhật: tìm điểm gần nhất trên hình chữ nhật rồi so khoảng cách với `r`.
6. **Laser** (dòng 360–373) không bỏ qua quái `e.dead` như cầu năng lượng (dòng 399). Hiện chưa gây lỗi vì quái chết bị dọn trước lượt sát thương tiếp theo, nhưng nên thêm `if (e.dead) return;` cho an toàn.
7. **Trải nghiệm:** chưa có phím tạm dừng (P/Esc), chưa lưu điểm cao (`localStorage`), `user-scalable=no` (dòng 5) cản người dùng phóng to trang — cân nhắc bỏ.

## Đề xuất cấu trúc khi game lớn hơn

- Tách `index.html` thành `style.css`, `game.js`, `entities.js`; gom hằng số cân bằng game (tốc độ, hồi chiêu tính bằng **giây**, EXP) vào một object `CONFIG`.
- Mỗi loại thực thể (đạn, quái, hạt, kỹ năng) có `update(dt)` và `draw(ctx)` riêng; vòng lặp chính chỉ gọi lần lượt. Dọn đối tượng "chết" ở **một chỗ** cuối khung (đánh dấu `dead = true` rồi `filter`) — sẽ loại bỏ hẳn kiểu lỗi số 2.
- Viết vài kiểm thử nhỏ cho logic không phụ thuộc màn hình (`rectIntersect`, `gainExp`, `spawnEnemy` theo trọng số) — giống cách các dự án trong `projects/` được kiểm thử (`tools/`).

## Nghi vấn đã kiểm tra và **không** phải lỗi

- *Bấm Space sau khi click "PLAY GAME" có khởi động lại ván?* — Không: nút bị ẩn nên mất focus; `startGame` chỉ được gọi 1 lần.
- *Quả cầu năng lượng "dính tường" và mất hết số lần nảy?* — Không: sau khi đổi chiều, quả cầu luôn ra khỏi tường ở khung kế tiếp.

## Thứ tự sửa gợi ý (≈ 1–2 buổi)
1. Sửa lỗi số 2 (5 phút) và thêm `touchcancel` (5 phút).
2. Chuyển sang `dt` (1–2 giờ, đổi đơn vị hồi chiêu sang giây).
3. Gom hằng số vào `CONFIG`, thêm phím tạm dừng và lưu điểm cao.
4. Tách file và viết kiểm thử nhỏ — lúc đó game xứng đáng là một mục portfolio riêng.
