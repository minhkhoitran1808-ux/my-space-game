# Máy dò hạt (Detector) — exploded view cho thí nghiệm khe đôi

Component React Three Fiber cho máy dò hạt đặt sau khe đôi:

- **Click lần 1**: các bộ phận tách ra theo 6 hướng (ease-out, 0.8 s). Sau khi dừng hẳn, mũi tên và nhãn chú thích mới fade-in.
- **Click lần 2**: nhãn fade-out trước, rồi các bộ phận thu về đúng vị trí với cùng thời lượng và easing.
- **State machine** `assembled → exploding → exploded → imploding → assembled`. Click trong lúc `exploding` hoặc `imploding` sẽ bị bỏ qua.
- **Tốc độ thời gian** (Bình thường / Chậm 2× / 5× / 10× + thanh trượt) đặt trong một store Zustand dùng chung. Toàn bộ hạt đọc store này, kể cả khi máy dò đang tách rã.

## Chạy thử

```bash
cd double-slit-detector
npm install
npm run dev        # mở http://localhost:5173
npm run typecheck
```

## Các file

| File | Vai trò |
| --- | --- |
| `src/components/Detector.tsx` | Mô hình detector, state machine, mũi tên + nhãn, ghi nhận hạt |
| `src/store/simulationTime.ts` | Store `timeScale` dùng chung, `<SimulationClock/>`, hook `useSimulationFrame` |
| `src/components/TimeScaleControl.tsx` | Panel HTML chọn tốc độ (đặt ngoài `<Canvas>`) |
| `src/components/ParticleStream.tsx` | Hệ hạt mẫu: phân bố giao thoa, bay tới detector |
| `src/DemoScene.tsx` | Scene ví dụ ghép tất cả lại |

## Gắn vào scene có sẵn

```tsx
<Canvas>
  <SimulationClock />                      {/* một lần duy nhất */}
  {/* ...nguồn, khe đôi, hệ hạt của bạn... */}
  <Detector ref={detectorRef} position={[0, 0, 3]} onStateChange={setPhase} />
</Canvas>
<TimeScaleControl />                       {/* lớp HTML phía trên canvas */}
```

Detector quay mặt nhận hạt về **−Z local**, tức là hạt bay theo +Z. Hãy xoay group (`rotation`) nếu scene của bạn dùng hướng khác.

### Cho hệ hạt có sẵn đọc tốc độ thời gian

Chỉ cần đổi `useFrame` thành `useSimulationFrame` trong vòng lặp cập nhật hạt:

```tsx
useSimulationFrame((_, simDelta) => {
  for (const p of particles) p.position.addScaledVector(p.velocity, simDelta);
});
```

Nếu không muốn đổi hook, nhân delta với hệ số ngay trong `useFrame`: `delta * useSimulationTime.getState().timeScale`. Đừng đặt `timeScale` cho từng hạt riêng lẻ.

### Báo hạt chạm detector

```ts
const plane = detectorRef.current.getSensorPlane(); // origin, normal, u, v, aperture...
detectorRef.current.registerHit(worldPoint);        // pixel sáng → khuếch đại → ADC → màn hiển thị
```

Tín hiệu đi qua từng tầng với độ trễ tính theo thời gian mô phỏng. Vì vậy ở chế độ chậm, học sinh thấy lần lượt pixel sáng lên, LED mạch khuếch đại nháy, LED ADC nháy, rồi cột trên màn hiển thị tăng.

### Tuỳ biến

- `theme`: ghi đè màu (mặc định lấy tông của dự án: nền `#0d0d1a`, viền neon `#00ffcc`, điểm chạm `#ff00ff`).
- `explodeDuration`: 0.6–1 s, mặc định 0.8.
- `showLabels`: tắt nhãn nếu chỉ muốn xem tách rã.
- `DETECTOR_PARTS`: tên, mô tả, hướng tách và vị trí nhãn của từng bộ phận.
