import { OrbitControls } from '@react-three/drei';
import { Canvas } from '@react-three/fiber';
import { useRef, useState } from 'react';
import { Detector, type DetectorHandle, type DetectorPhase } from './components/Detector';
import { ParticleStream } from './components/ParticleStream';
import { TimeScaleControl } from './components/TimeScaleControl';
import { SimulationClock } from './store/simulationTime';

/**
 * Scene ví dụ để chạy thử. Trong dự án thật chỉ cần:
 *   1. đặt <SimulationClock/> một lần trong <Canvas>,
 *   2. đặt <Detector ref={...} position={...}/> sau khe đôi,
 *   3. cho hệ hạt dùng useSimulationFrame (hoặc nhân delta với timeScale),
 *   4. đặt <TimeScaleControl/> ở lớp HTML ngoài <Canvas>.
 */

const SLIT_Z = -3;

function DoubleSlitBarrier() {
  const gap = 0.3;
  const slitW = 0.06;
  const slitH = 0.9;
  const W = 4;
  const H = 2.6;
  const t = 0.06;
  const outerW = (W - gap - slitW) / 2;
  const capH = (H - slitH) / 2;
  const color = '#283048';
  return (
    <group position={[0, 0, SLIT_Z]}>
      {[1, -1].map((s) => (
        <mesh key={`side${s}`} position={[s * (gap / 2 + slitW / 2 + outerW / 2), 0, 0]}>
          <boxGeometry args={[outerW, H, t]} />
          <meshStandardMaterial color={color} metalness={0.4} roughness={0.6} />
        </mesh>
      ))}
      <mesh>
        <boxGeometry args={[gap - slitW, H, t]} />
        <meshStandardMaterial color={color} metalness={0.4} roughness={0.6} />
      </mesh>
      {[1, -1].map((s) => (
        <mesh key={`cap${s}`} position={[0, s * (slitH / 2 + capH / 2), 0]}>
          <boxGeometry args={[gap + slitW * 2, capH, t]} />
          <meshStandardMaterial color={color} metalness={0.4} roughness={0.6} />
        </mesh>
      ))}
    </group>
  );
}

function Source() {
  return (
    <mesh position={[0, 0, -6]}>
      <sphereGeometry args={[0.12, 24, 24]} />
      <meshBasicMaterial color="#ffcc00" toneMapped={false} />
    </mesh>
  );
}

const HINTS: Record<DetectorPhase, string> = {
  assembled: 'Nhấn vào máy dò để xem cấu tạo bên trong.',
  exploding: 'Đang tách rã…',
  exploded: 'Nhấn vào máy dò lần nữa để thu lại.',
  imploding: 'Đang thu lại…',
};

export function DemoScene() {
  const detectorRef = useRef<DetectorHandle>(null);
  const [phase, setPhase] = useState<DetectorPhase>('assembled');

  return (
    <div style={{ position: 'relative', width: '100%', height: '100%' }}>
      <Canvas camera={{ position: [-7.6, 3.6, -2.6], fov: 50 }} dpr={[1, 2]}>
        <color attach="background" args={['#0d0d1a']} />
        <hemisphereLight args={['#cfe9ff', '#0d0d1a', 1.4]} />
        <directionalLight position={[-5, 8, -4]} intensity={1.6} />
        <pointLight position={[4, 2, 5]} intensity={18} color="#00ffcc" />

        <SimulationClock />
        <Source />
        <DoubleSlitBarrier />
        <ParticleStream detectorRef={detectorRef} slitPosition={[0, 0, SLIT_Z]} />
        <Detector ref={detectorRef} position={[0, 0, 3]} onStateChange={setPhase} />

        <OrbitControls target={[0, 0.2, 1.8]} enableDamping makeDefault />
      </Canvas>

      <div
        aria-live="polite"
        style={{
          position: 'absolute',
          top: 16,
          left: 16,
          right: 16,
          color: '#e8fbff',
          fontWeight: 600,
          textShadow: '2px 2px 0 #000',
          pointerEvents: 'none',
        }}
      >
        {HINTS[phase]}
      </div>
      <TimeScaleControl />
    </div>
  );
}
