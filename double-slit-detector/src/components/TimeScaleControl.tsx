import type { CSSProperties } from 'react';
import { MAX_TIME_SCALE, MIN_TIME_SCALE, TIME_SCALE_PRESETS, useSimulationTime } from '../store/simulationTime';

/**
 * Panel HTML (đặt NGOÀI <Canvas>) để chọn tốc độ thời gian của mô phỏng.
 * Chỉ ghi vào store dùng chung, nên hoạt động độc lập với trạng thái tách/lắp của detector.
 */

const ACCENT = '#00ffcc';

// Thanh trượt theo thang log: chậm 10× nằm giữa chừng thay vì dồn sát mép trái.
const LOG_RANGE = Math.log(MAX_TIME_SCALE / MIN_TIME_SCALE);
const toSlider = (scale: number) => Math.log(scale / MIN_TIME_SCALE) / LOG_RANGE;
const fromSlider = (s: number) => MIN_TIME_SCALE * Math.exp(s * LOG_RANGE);

function describe(scale: number) {
  if (scale >= 0.995) return 'Bình thường';
  const slow = 1 / scale;
  return `Chậm ${slow < 10 ? slow.toFixed(1).replace(/\.0$/, '') : Math.round(slow)}×`;
}

export function TimeScaleControl({ style }: { style?: CSSProperties }) {
  const target = useSimulationTime((s) => s.targetTimeScale);
  const setTimeScale = useSimulationTime((s) => s.setTimeScale);

  return (
    <div
      role="group"
      aria-label="Tốc độ thời gian"
      style={{
        position: 'absolute',
        left: 16,
        bottom: 16,
        display: 'flex',
        flexDirection: 'column',
        gap: 10,
        padding: '14px 16px',
        maxWidth: 'calc(100vw - 32px)',
        boxSizing: 'border-box',
        background: 'rgba(0, 15, 30, 0.9)',
        border: `1px solid ${ACCENT}`,
        borderRadius: 12,
        boxShadow: '0 0 20px rgba(0, 255, 204, 0.25)',
        color: '#e8fbff',
        fontFamily: "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif",
        userSelect: 'none',
        zIndex: 20,
        ...style,
      }}
    >
      <div style={{ display: 'flex', justifyContent: 'space-between', gap: 16, alignItems: 'baseline' }}>
        <span style={{ fontWeight: 700, fontSize: 14 }}>Tốc độ thời gian</span>
        <span style={{ fontSize: 13, color: ACCENT, fontWeight: 600 }} aria-live="polite">
          {describe(target)}
        </span>
      </div>

      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
        {TIME_SCALE_PRESETS.map((p) => {
          const active = Math.abs(target - p.value) < 1e-3;
          return (
            <button
              key={p.value}
              type="button"
              aria-pressed={active}
              onClick={() => setTimeScale(p.value)}
              style={{
                minHeight: 44,
                padding: '0 14px',
                borderRadius: 10,
                border: `1px solid ${active ? ACCENT : 'rgba(169, 199, 210, 0.35)'}`,
                background: active ? ACCENT : 'transparent',
                color: active ? '#0d0d1a' : '#e8fbff',
                fontWeight: 600,
                fontSize: 13,
                fontFamily: 'inherit',
                cursor: 'pointer',
              }}
            >
              {p.label}
            </button>
          );
        })}
      </div>

      <label style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 12, color: '#a9c7d2' }}>
        <span>Chậm</span>
        <input
          type="range"
          min={0}
          max={1}
          step={0.001}
          value={toSlider(target)}
          onChange={(e) => setTimeScale(fromSlider(Number(e.target.value)))}
          aria-label="Hệ số thời gian"
          aria-valuetext={describe(target)}
          style={{ flex: 1, accentColor: ACCENT }}
        />
        <span>Nhanh</span>
      </label>
    </div>
  );
}
