import { useFrame, type RootState } from '@react-three/fiber';
import { useRef } from 'react';
import { create } from 'zustand';

/**
 * Đồng hồ mô phỏng dùng chung cho TOÀN BỘ hệ thống hạt.
 *
 * - `targetTimeScale`: hệ số người dùng chọn (1 = bình thường, 0.1 = chậm 10×).
 * - `timeScale`: hệ số đang áp dụng, được <SimulationClock/> làm mượt về target
 *   để hạt không bị giật khi đổi tốc độ.
 * - `simTime`: thời gian mô phỏng đã trôi (giây, đã nhân timeScale).
 *
 * Hệ hạt không cần biết UI: chỉ việc dùng `useSimulationFrame` (hoặc đọc
 * `useSimulationTime.getState().timeScale` trong useFrame) và nhân với delta.
 */

export const TIME_SCALE_PRESETS = [
  { label: 'Bình thường', value: 1 },
  { label: 'Chậm 2×', value: 0.5 },
  { label: 'Chậm 5×', value: 0.2 },
  { label: 'Chậm 10×', value: 0.1 },
] as const;

export const MIN_TIME_SCALE = 0.05;
export const MAX_TIME_SCALE = 1;

/** Giới hạn delta thực để tránh "nhảy cóc" khi tab bị ẩn rồi mở lại. */
export const MAX_REAL_DELTA = 0.1;

interface SimulationTimeState {
  targetTimeScale: number;
  timeScale: number;
  simTime: number;
  paused: boolean;
  setTimeScale: (value: number) => void;
  setPaused: (paused: boolean) => void;
  /** Chỉ <SimulationClock/> gọi hàm này, mỗi frame một lần. */
  tick: (realDelta: number) => void;
}

const clampScale = (v: number) => Math.min(MAX_TIME_SCALE, Math.max(MIN_TIME_SCALE, v));

export const useSimulationTime = create<SimulationTimeState>((set, get) => ({
  targetTimeScale: 1,
  timeScale: 1,
  simTime: 0,
  paused: false,
  setTimeScale: (value) => set({ targetTimeScale: clampScale(value) }),
  setPaused: (paused) => set({ paused }),
  tick: (realDelta) => {
    const { timeScale, targetTimeScale, simTime, paused } = get();
    // Làm mượt hằng số thời gian ~50 ms: đạt ~95% giá trị mới sau ~150 ms.
    const k = 1 - Math.exp(-realDelta / 0.05);
    let next = timeScale + (targetTimeScale - timeScale) * k;
    if (Math.abs(next - targetTimeScale) < 1e-4) next = targetTimeScale;
    set({ timeScale: next, simTime: paused ? simTime : simTime + realDelta * next });
  },
}));

/** Delta mô phỏng của frame hiện tại (giây). */
export function getSimulationDelta(realDelta: number): number {
  const { timeScale, paused } = useSimulationTime.getState();
  return paused ? 0 : Math.min(realDelta, MAX_REAL_DELTA) * timeScale;
}

/**
 * Đặt MỘT lần bên trong <Canvas>. Chạy với priority âm nên luôn cập nhật
 * timeScale trước mọi useFrame khác (priority âm không tắt auto-render của R3F).
 */
export function SimulationClock() {
  useFrame((_, delta) => {
    useSimulationTime.getState().tick(Math.min(delta, MAX_REAL_DELTA));
  }, -1);
  return null;
}

/**
 * Thay thế useFrame cho mọi thứ "thuộc về mô phỏng" (hạt, sóng, va chạm...).
 * Callback nhận `simDelta` đã nhân timeScale và `realDelta` gốc.
 */
export function useSimulationFrame(
  callback: (state: RootState, simDelta: number, realDelta: number) => void,
  priority = 0,
) {
  const cb = useRef(callback);
  cb.current = callback;
  useFrame((state, delta) => {
    cb.current(state, getSimulationDelta(delta), Math.min(delta, MAX_REAL_DELTA));
  }, priority);
}
