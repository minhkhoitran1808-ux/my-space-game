import { Edges, Html, Line } from '@react-three/drei';
import { useFrame, type ThreeElements, type ThreeEvent } from '@react-three/fiber';
import {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
  type ElementRef,
  type MutableRefObject,
} from 'react';
import * as THREE from 'three';
import { getSimulationDelta, useSimulationTime } from '../store/simulationTime';

/* ------------------------------------------------------------------ */
/* Kiểu & cấu hình                                                     */
/* ------------------------------------------------------------------ */

export type DetectorPhase = 'assembled' | 'exploding' | 'exploded' | 'imploding';

export type DetectorPartId = 'window' | 'housing' | 'sensor' | 'amplifier' | 'adc' | 'display' | 'hv';

type Vec3 = [number, number, number];

export interface DetectorPartSpec {
  id: DetectorPartId;
  name: string;
  description: string;
  /** Độ dời (toạ độ local của detector) khi tách rã hoàn toàn. */
  explodeOffset: Vec3;
  /** Điểm trên bộ phận mà mũi tên chỉ vào (local, khi đang lắp ráp). */
  anchor: Vec3;
  /** Vị trí nhãn so với anchor. */
  labelOffset: Vec3;
}

/**
 * Detector đặt sao cho mặt nhận hạt hướng về −Z local (về phía khe đôi);
 * hạt bay theo +Z. Kích thước khối: 2.6 × 1.7 × 1.5.
 */
export const DETECTOR_PARTS: DetectorPartSpec[] = [
  {
    id: 'window',
    name: 'Cửa sổ nhận hạt',
    description: 'Tấm chắn có khe hẹp: chỉ cho hạt đi từ khe đôi lọt vào, chặn ánh sáng nền.',
    explodeOffset: [0, 0, -2.6],
    anchor: [1.3, 0.85, -0.75],
    labelOffset: [0.7, 0.75, -0.3],
  },
  {
    id: 'housing',
    name: 'Vỏ che chắn',
    description: 'Hộp kín sáng, chống nhiễu điện từ và bảo vệ các linh kiện bên trong.',
    explodeOffset: [0, 2.0, 0],
    anchor: [-0.6, 0.85, -0.3],
    labelOffset: [-0.6, 0.45, -0.2],
  },
  {
    id: 'sensor',
    name: 'Mảng cảm biến',
    description: 'Lưới điểm ảnh. Mỗi hạt chạm vào chỉ làm sáng đúng một điểm — bằng chứng của tính hạt.',
    explodeOffset: [0, 0, 0],
    anchor: [1.1, -0.6, -0.56],
    labelOffset: [0.9, -0.9, -0.5],
  },
  {
    id: 'amplifier',
    name: 'Mạch khuếch đại',
    description: 'Phóng đại xung điện cực nhỏ từ cảm biến lên mức đủ lớn để đo được.',
    explodeOffset: [0, 0, 2.6],
    anchor: [-1.3, 0.85, 0.65],
    labelOffset: [-0.7, 0.75, 0.2],
  },
  {
    id: 'adc',
    name: 'Bộ chuyển đổi & đếm',
    description: 'Đổi xung thành số: ghi vị trí từng hạt và đếm tổng số hạt đã tới.',
    explodeOffset: [0, -1.8, 0],
    anchor: [-1.3, -0.85, -0.65],
    labelOffset: [-0.8, -0.45, -0.2],
  },
  {
    id: 'display',
    name: 'Màn hiển thị kết quả',
    description: 'Vẽ biểu đồ số hạt theo vị trí — các vân giao thoa dần hiện ra.',
    explodeOffset: [-2.6, 0, -0.8],
    anchor: [-1.44, 0.6, -0.6],
    labelOffset: [-0.6, 0.8, -0.3],
  },
  {
    id: 'hv',
    name: 'Nguồn cao áp',
    description: 'Cấp điện áp cao cho cảm biến để một hạt đơn lẻ cũng tạo được tín hiệu.',
    explodeOffset: [1.8, 0, 0.6],
    anchor: [1.54, 0.2, -0.35],
    labelOffset: [0.8, 0.7, -0.2],
  },
];

export interface DetectorTheme {
  accent: string;
  hit: string;
  housing: string;
  window: string;
  sensor: string;
  sensorPixel: string;
  pcb: string;
  trace: string;
  chassis: string;
  chip: string;
  hv: string;
  warning: string;
  screenBg: string;
  labelBg: string;
  labelText: string;
  labelMuted: string;
  fontFamily: string;
}

/** Lấy theo tông của dự án: nền navy #0d0d1a, viền neon cyan, điểm nhấn hồng tím. */
export const DEFAULT_DETECTOR_THEME: DetectorTheme = {
  accent: '#00ffcc',
  hit: '#ff00ff',
  housing: '#3a4566',
  window: '#2b4170',
  sensor: '#145058',
  sensorPixel: '#0f4a50',
  pcb: '#1b5a48',
  trace: '#ffcc00',
  chassis: '#43386a',
  chip: '#1a2430',
  hv: '#6b4a22',
  warning: '#ffcc00',
  screenBg: '#03121a',
  labelBg: 'rgba(0, 15, 30, 0.92)',
  labelText: '#e8fbff',
  labelMuted: '#c4dde6',
  fontFamily: "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif",
};

/** Mặt phẳng nhận hạt (toạ độ world) để hệ hạt tính điểm chạm. */
export interface SensorPlane {
  origin: THREE.Vector3;
  /** Pháp tuyến theo hướng hạt bay vào (+Z local). */
  normal: THREE.Vector3;
  /** Trục ngang / dọc của mặt cảm biến (đã chuẩn hoá). */
  u: THREE.Vector3;
  v: THREE.Vector3;
  halfWidth: number;
  halfHeight: number;
  /** Nửa kích thước khe nhận hạt — hạt nên nhắm trong vùng này. */
  apertureHalfWidth: number;
  apertureHalfHeight: number;
}

export interface DetectorHandle {
  /** Báo một hạt chạm cảm biến tại điểm world. Trả về false nếu điểm nằm ngoài cảm biến. */
  registerHit: (worldPoint: THREE.Vector3) => boolean;
  getSensorPlane: (target?: SensorPlane) => SensorPlane;
  toggle: () => void;
  getPhase: () => DetectorPhase;
  resetHits: () => void;
}

export type DetectorProps = Omit<ThreeElements['group'], 'ref' | 'onClick'> & {
  theme?: Partial<DetectorTheme>;
  /** Thời gian tách / lắp (giây, thời gian thực). Giới hạn 0.6–1. */
  explodeDuration?: number;
  onStateChange?: (phase: DetectorPhase) => void;
  /** Hiện mũi tên + nhãn khi đã tách rã (mặc định true). */
  showLabels?: boolean;
};

/* ------------------------------------------------------------------ */
/* Hằng số hình học & thời gian                                        */
/* ------------------------------------------------------------------ */

const LABEL_FADE_IN = 0.3;
const UI_MAX_DELTA = 0.25;
const LABEL_FADE_OUT = 0.18;

const SIZE = { w: 2.6, h: 1.7 };
const SLIT = { w: 2.0, h: 0.14 };
const SENSOR = { w: 2.2, h: 1.2, d: 0.12, z: -0.5, cols: 44, rows: 24 };
const SENSOR_FACE_Z = SENSOR.z - SENSOR.d / 2;
const PIXEL_PITCH_X = SENSOR.w / SENSOR.cols;
const PIXEL_PITCH_Y = SENSOR.h / SENSOR.rows;

/** Thời gian mô phỏng (giây) — bị làm chậm cùng hạt để thấy tín hiệu chạy qua từng tầng. */
const PIXEL_GLOW_TIME = 0.9;
const LED_DECAY_TIME = 0.25;
const SIGNAL_DELAY = { amplifier: 0.06, adc: 0.14, display: 0.22 };

const DISPLAY_TEX = { w: 256, h: 200 };

const easeOutCubic = (t: number) => 1 - Math.pow(1 - t, 3);

/* ------------------------------------------------------------------ */
/* Khối hình cơ bản                                                    */
/* ------------------------------------------------------------------ */

interface BlockProps {
  size: Vec3;
  position: Vec3;
  color: string;
  edge?: string;
  metalness?: number;
  roughness?: number;
}

function Block({ size, position, color, edge, metalness = 0.2, roughness = 0.6 }: BlockProps) {
  return (
    <mesh position={position}>
      <boxGeometry args={size} />
      <meshStandardMaterial color={color} metalness={metalness} roughness={roughness} />
      {edge && <Edges color={edge} threshold={15} />}
    </mesh>
  );
}

/* ------------------------------------------------------------------ */
/* Các bộ phận                                                         */
/* ------------------------------------------------------------------ */

function WindowPart({ theme, edge }: { theme: DetectorTheme; edge: string }) {
  const t = 0.1;
  const z = -0.7;
  const barH = (SIZE.h - SLIT.h) / 2;
  const sideW = (SIZE.w - SLIT.w) / 2;
  const glowZ = z - t / 2 - 0.004;
  return (
    <>
      <Block size={[SIZE.w, barH, t]} position={[0, SLIT.h / 2 + barH / 2, z]} color={theme.window} edge={edge} />
      <Block size={[SIZE.w, barH, t]} position={[0, -(SLIT.h / 2 + barH / 2), z]} color={theme.window} edge={edge} />
      <Block size={[sideW, SLIT.h, t]} position={[SLIT.w / 2 + sideW / 2, 0, z]} color={theme.window} edge={edge} />
      <Block size={[sideW, SLIT.h, t]} position={[-(SLIT.w / 2 + sideW / 2), 0, z]} color={theme.window} edge={edge} />
      {/* Viền sáng quanh khe nhận hạt */}
      {[SLIT.h / 2, -SLIT.h / 2].map((y) => (
        <mesh key={y} position={[0, y, glowZ]}>
          <boxGeometry args={[SLIT.w, 0.012, 0.004]} />
          <meshBasicMaterial color={theme.accent} toneMapped={false} />
        </mesh>
      ))}
    </>
  );
}

function HousingPart({ theme, edge }: { theme: DetectorTheme; edge: string }) {
  return (
    <>
      <Block size={[SIZE.w, 0.1, 1.3]} position={[0, 0.8, 0]} color={theme.housing} edge={edge} />
      <Block size={[0.1, 1.5, 1.3]} position={[-1.25, 0, 0]} color={theme.housing} edge={edge} />
      <Block size={[0.1, 1.5, 1.3]} position={[1.25, 0, 0]} color={theme.housing} edge={edge} />
    </>
  );
}

interface SensorPartProps {
  theme: DetectorTheme;
  edge: string;
  pixelsRef: MutableRefObject<THREE.InstancedMesh | null>;
  faceRef: MutableRefObject<THREE.Object3D | null>;
}

function SensorPart({ theme, edge, pixelsRef, faceRef }: SensorPartProps) {
  const count = SENSOR.cols * SENSOR.rows;

  useLayoutEffect(() => {
    const mesh = pixelsRef.current;
    if (!mesh) return;
    const m = new THREE.Matrix4();
    const base = new THREE.Color(theme.sensorPixel);
    for (let r = 0; r < SENSOR.rows; r++) {
      for (let c = 0; c < SENSOR.cols; c++) {
        const i = r * SENSOR.cols + c;
        m.makeTranslation(
          -SENSOR.w / 2 + PIXEL_PITCH_X * (c + 0.5),
          -SENSOR.h / 2 + PIXEL_PITCH_Y * (r + 0.5),
          SENSOR_FACE_Z - 0.006,
        );
        mesh.setMatrixAt(i, m);
        mesh.setColorAt(i, base);
      }
    }
    mesh.instanceMatrix.needsUpdate = true;
    if (mesh.instanceColor) mesh.instanceColor.needsUpdate = true;
  }, [pixelsRef, theme.sensorPixel]);

  return (
    <>
      <Block size={[SENSOR.w, SENSOR.h, SENSOR.d]} position={[0, 0, SENSOR.z]} color={theme.sensor} edge={edge} />
      <instancedMesh ref={pixelsRef} args={[undefined, undefined, count]} frustumCulled={false}>
        <boxGeometry args={[PIXEL_PITCH_X * 0.82, PIXEL_PITCH_Y * 0.82, 0.008]} />
        <meshBasicMaterial color="#ffffff" toneMapped={false} />
      </instancedMesh>
      <object3D ref={faceRef} position={[0, 0, SENSOR_FACE_Z]} />
    </>
  );
}

interface LedProps {
  position: Vec3;
  color: string;
  ledRef: MutableRefObject<THREE.MeshStandardMaterial | null>;
}

function Led({ position, color, ledRef }: LedProps) {
  return (
    <mesh position={position}>
      <sphereGeometry args={[0.035, 12, 12]} />
      <meshStandardMaterial ref={ledRef} color={color} emissive={color} emissiveIntensity={0.3} toneMapped={false} />
    </mesh>
  );
}

function AmplifierPart({
  theme,
  edge,
  ledRef,
}: {
  theme: DetectorTheme;
  edge: string;
  ledRef: MutableRefObject<THREE.MeshStandardMaterial | null>;
}) {
  const traces = useMemo(() => Array.from({ length: 9 }, (_, i) => -0.95 + i * 0.24), []);
  return (
    <>
      <Block size={[SIZE.w, SIZE.h, 0.1]} position={[0, 0, 0.7]} color={theme.pcb} edge={edge} roughness={0.8} metalness={0.1} />
      {traces.map((x) => (
        <mesh key={x} position={[x, 0, 0.646]}>
          <boxGeometry args={[0.012, 1.45, 0.004]} />
          <meshStandardMaterial color={theme.trace} emissive={theme.trace} emissiveIntensity={0.15} metalness={0.8} roughness={0.3} />
        </mesh>
      ))}
      <Block size={[0.5, 0.36, 0.1]} position={[-0.6, 0.3, 0.6]} color={theme.chip} edge={edge} />
      <Block size={[0.4, 0.4, 0.1]} position={[0.5, 0.2, 0.6]} color={theme.chip} edge={edge} />
      <Block size={[0.9, 0.22, 0.08]} position={[0.1, -0.4, 0.61]} color={theme.chip} edge={edge} />
      <Led position={[0.95, 0.6, 0.62]} color={theme.accent} ledRef={ledRef} />
    </>
  );
}

function AdcPart({
  theme,
  edge,
  ledRef,
}: {
  theme: DetectorTheme;
  edge: string;
  ledRef: MutableRefObject<THREE.MeshStandardMaterial | null>;
}) {
  return (
    <>
      <Block size={[SIZE.w, 0.1, 1.3]} position={[0, -0.8, 0]} color={theme.chassis} edge={edge} />
      <Block size={[2.0, 0.1, 1.0]} position={[0, -0.7, 0]} color={theme.pcb} edge={edge} roughness={0.8} metalness={0.1} />
      <Block size={[0.4, 0.06, 0.3]} position={[-0.4, -0.62, -0.1]} color={theme.chip} edge={edge} />
      <Block size={[0.3, 0.06, 0.3]} position={[0.3, -0.62, 0.15]} color={theme.chip} edge={edge} />
      <Led position={[0.8, -0.6, -0.3]} color={theme.hit} ledRef={ledRef} />
    </>
  );
}

function DisplayPart({ theme, edge, texture }: { theme: DetectorTheme; edge: string; texture: THREE.Texture }) {
  return (
    <>
      <Block size={[0.14, 1.0, 1.2]} position={[-1.37, 0.1, 0]} color={theme.housing} edge={edge} />
      {/* Màn hình quay ra −X */}
      <mesh position={[-1.441, 0.1, 0]} rotation={[0, -Math.PI / 2, 0]}>
        <planeGeometry args={[1.08, 0.86]} />
        <meshBasicMaterial map={texture} toneMapped={false} />
      </mesh>
    </>
  );
}

function HvPart({ theme, edge }: { theme: DetectorTheme; edge: string }) {
  return (
    <>
      <Block size={[0.24, 0.8, 0.9]} position={[1.42, -0.2, 0.1]} color={theme.hv} edge={edge} />
      <mesh position={[1.42, 0.05, 0.1]}>
        <boxGeometry args={[0.246, 0.1, 0.906]} />
        <meshStandardMaterial color={theme.warning} emissive={theme.warning} emissiveIntensity={0.35} />
      </mesh>
    </>
  );
}

/* ------------------------------------------------------------------ */
/* Chú thích: mũi tên + nhãn                                           */
/* ------------------------------------------------------------------ */

interface CalloutRefs {
  line: (ElementRef<typeof Line> | null)[];
  arrow: (THREE.Mesh | null)[];
  label: (HTMLDivElement | null)[];
}

const ARROW_LEN = 0.12;
const UP = new THREE.Vector3(0, 1, 0);
/** Mũi tên/đường dẫn không nhận click — tránh bắt nhầm khi chúng đang ẩn. */
const noRaycast = () => null;

function Callout({ spec, index, theme, refs }: { spec: DetectorPartSpec; index: number; theme: DetectorTheme; refs: CalloutRefs }) {
  const { labelPos, lineEnd, arrowPos, arrowQuat } = useMemo(() => {
    const a = new THREE.Vector3(...spec.anchor);
    const l = a.clone().add(new THREE.Vector3(...spec.labelOffset));
    const dir = a.clone().sub(l).normalize();
    return {
      labelPos: l,
      lineEnd: a.clone().addScaledVector(dir, -ARROW_LEN),
      arrowPos: a.clone().addScaledVector(dir, -ARROW_LEN / 2),
      arrowQuat: new THREE.Quaternion().setFromUnitVectors(UP, dir),
    };
  }, [spec.anchor, spec.labelOffset]);

  return (
    <group>
      <Line
        ref={(el) => {
          refs.line[index] = el;
        }}
        points={[labelPos, lineEnd]}
        color={theme.accent}
        lineWidth={1.5}
        transparent
        opacity={0}
        depthTest={false}
        renderOrder={10}
        raycast={noRaycast}
      />
      <mesh
        ref={(el) => {
          refs.arrow[index] = el;
        }}
        position={arrowPos}
        quaternion={arrowQuat}
        renderOrder={10}
        raycast={noRaycast}
      >
        <coneGeometry args={[0.04, ARROW_LEN, 12]} />
        <meshBasicMaterial color={theme.accent} transparent opacity={0} depthTest={false} toneMapped={false} />
      </mesh>
      <Html position={labelPos} center zIndexRange={[30, 10]} style={{ pointerEvents: 'none' }}>
        <div
          ref={(el) => {
            refs.label[index] = el;
          }}
          style={{
            opacity: 0,
            visibility: 'hidden',
            width: 220,
            boxSizing: 'border-box',
            padding: '8px 12px',
            background: theme.labelBg,
            border: `1px solid ${theme.accent}`,
            borderRadius: 8,
            boxShadow: `0 0 12px ${theme.accent}55`,
            color: theme.labelText,
            fontFamily: theme.fontFamily,
            userSelect: 'none',
          }}
        >
          <div style={{ fontWeight: 700, fontSize: 14, color: theme.accent }}>{spec.name}</div>
          <div style={{ marginTop: 3, fontSize: 12, lineHeight: 1.4, color: theme.labelMuted }}>{spec.description}</div>
        </div>
      </Html>
    </group>
  );
}

/* ------------------------------------------------------------------ */
/* Màn hiển thị: biểu đồ số hạt theo vị trí                             */
/* ------------------------------------------------------------------ */

function drawDisplay(ctx: CanvasRenderingContext2D, theme: DetectorTheme, histogram: Uint32Array, total: number) {
  const { w, h } = DISPLAY_TEX;
  ctx.fillStyle = theme.screenBg;
  ctx.fillRect(0, 0, w, h);
  ctx.strokeStyle = theme.accent;
  ctx.globalAlpha = 0.5;
  ctx.strokeRect(1.5, 1.5, w - 3, h - 3);
  ctx.globalAlpha = 1;

  ctx.fillStyle = theme.accent;
  ctx.font = `600 13px ${theme.fontFamily}`;
  ctx.fillText('SỐ HẠT / VỊ TRÍ', 12, 22);
  ctx.font = `700 20px ${theme.fontFamily}`;
  ctx.fillStyle = theme.labelText;
  ctx.fillText(String(total), 12, 46);

  let max = 1;
  for (let i = 0; i < histogram.length; i++) max = Math.max(max, histogram[i]);
  const left = 12;
  const bottom = h - 12;
  const plotH = h - 70;
  const bw = (w - 24) / histogram.length;
  ctx.fillStyle = theme.accent;
  for (let i = 0; i < histogram.length; i++) {
    const bh = (histogram[i] / max) * plotH;
    if (bh > 0) ctx.fillRect(left + i * bw, bottom - bh, Math.max(1, bw - 1), bh);
  }
  ctx.fillStyle = theme.labelMuted;
  ctx.globalAlpha = 0.4;
  ctx.fillRect(left, bottom, w - 24, 1);
  ctx.globalAlpha = 1;
}

/* ------------------------------------------------------------------ */
/* Detector                                                            */
/* ------------------------------------------------------------------ */

interface QueuedSignal {
  at: number;
  col: number;
}

export const Detector = forwardRef<DetectorHandle, DetectorProps>(function Detector(
  { theme: themeOverride, explodeDuration = 0.8, onStateChange, showLabels = true, ...groupProps },
  ref,
) {
  const theme = useMemo(() => ({ ...DEFAULT_DETECTOR_THEME, ...themeOverride }), [themeOverride]);
  const edge = useMemo(() => '#' + new THREE.Color(theme.accent).multiplyScalar(0.6).getHexString(), [theme.accent]);
  const duration = THREE.MathUtils.clamp(explodeDuration, 0.6, 1);

  /* ---------- State machine ---------- */
  const [phase, setPhase] = useState<DetectorPhase>('assembled');
  const phaseRef = useRef<DetectorPhase>('assembled');
  const anim = useRef({ t: 0, progress: 0, labelOpacity: 0, appliedOpacity: -1 });
  const onStateChangeRef = useRef(onStateChange);
  onStateChangeRef.current = onStateChange;

  const goTo = useCallback((next: DetectorPhase) => {
    phaseRef.current = next;
    if (next === 'exploding' || next === 'imploding') anim.current.t = 0;
    setPhase(next);
    onStateChangeRef.current?.(next);
  }, []);

  const toggle = useCallback(() => {
    // Ref được cập nhật đồng bộ nên hai click liên tiếp trong cùng frame vẫn bị chặn đúng.
    const current = phaseRef.current;
    if (current === 'assembled') goTo('exploding');
    else if (current === 'exploded') goTo('imploding');
    // 'exploding' | 'imploding': bỏ qua input cho tới khi animation xong.
  }, [goTo]);

  /* ---------- Refs của scene ---------- */
  const partGroups = useRef<(THREE.Group | null)[]>([]);
  const callouts = useRef<CalloutRefs>({ line: [], arrow: [], label: [] });
  const pixelsRef = useRef<THREE.InstancedMesh | null>(null);
  const sensorFaceRef = useRef<THREE.Object3D | null>(null);
  const ampLedRef = useRef<THREE.MeshStandardMaterial | null>(null);
  const adcLedRef = useRef<THREE.MeshStandardMaterial | null>(null);

  /* ---------- Dữ liệu ghi nhận hạt ---------- */
  const hits = useRef({
    intensity: new Float32Array(SENSOR.cols * SENSOR.rows),
    active: new Set<number>(),
    histogram: new Uint32Array(SENSOR.cols),
    total: 0,
    ampQ: [] as QueuedSignal[],
    adcQ: [] as QueuedSignal[],
    displayQ: [] as QueuedSignal[],
    ampPulse: 0,
    adcPulse: 0,
    displayDirty: true,
    sinceRedraw: 0,
  });

  /* ---------- Texture màn hiển thị ---------- */
  const display = useMemo(() => {
    const canvas = document.createElement('canvas');
    canvas.width = DISPLAY_TEX.w;
    canvas.height = DISPLAY_TEX.h;
    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    return { ctx: canvas.getContext('2d')!, texture };
  }, []);
  useEffect(() => () => display.texture.dispose(), [display]);
  useEffect(() => {
    hits.current.displayDirty = true;
  }, [theme]);

  /* ---------- API cho hệ hạt ---------- */
  const tmp = useMemo(
    () => ({ local: new THREE.Vector3(), color: new THREE.Color(), base: new THREE.Color(), hit: new THREE.Color() }),
    [],
  );

  const getSensorPlane = useCallback((target?: SensorPlane): SensorPlane => {
    const out: SensorPlane = target ?? {
      origin: new THREE.Vector3(),
      normal: new THREE.Vector3(),
      u: new THREE.Vector3(),
      v: new THREE.Vector3(),
      halfWidth: 0,
      halfHeight: 0,
      apertureHalfWidth: 0,
      apertureHalfHeight: 0,
    };
    const face = sensorFaceRef.current;
    if (!face) return out;
    face.updateWorldMatrix(true, false);
    face.matrixWorld.extractBasis(out.u, out.v, out.normal);
    const sx = out.u.length();
    const sy = out.v.length();
    out.u.normalize();
    out.v.normalize();
    out.normal.normalize();
    out.origin.setFromMatrixPosition(face.matrixWorld);
    out.halfWidth = (SENSOR.w / 2) * sx;
    out.halfHeight = (SENSOR.h / 2) * sy;
    out.apertureHalfWidth = (Math.min(SENSOR.w, SLIT.w) / 2) * sx;
    out.apertureHalfHeight = (Math.min(SENSOR.h, SLIT.h) / 2) * sy;
    return out;
  }, []);

  const registerHit = useCallback(
    (worldPoint: THREE.Vector3) => {
      const face = sensorFaceRef.current;
      if (!face) return false;
      const p = face.worldToLocal(tmp.local.copy(worldPoint));
      const col = Math.floor((p.x + SENSOR.w / 2) / PIXEL_PITCH_X);
      const row = Math.floor((p.y + SENSOR.h / 2) / PIXEL_PITCH_Y);
      if (col < 0 || col >= SENSOR.cols || row < 0 || row >= SENSOR.rows) return false;
      const h = hits.current;
      const idx = row * SENSOR.cols + col;
      h.intensity[idx] = 1;
      h.active.add(idx);
      // Tín hiệu đi qua từng tầng theo thời gian mô phỏng → làm chậm thì thấy rõ thứ tự.
      const now = useSimulationTime.getState().simTime;
      h.ampQ.push({ at: now + SIGNAL_DELAY.amplifier, col });
      h.adcQ.push({ at: now + SIGNAL_DELAY.adc, col });
      h.displayQ.push({ at: now + SIGNAL_DELAY.display, col });
      return true;
    },
    [tmp],
  );

  const resetHits = useCallback(() => {
    const h = hits.current;
    h.intensity.fill(0);
    h.active.forEach((i) => pixelsRef.current?.setColorAt(i, tmp.base.set(theme.sensorPixel)));
    if (pixelsRef.current?.instanceColor) pixelsRef.current.instanceColor.needsUpdate = true;
    h.active.clear();
    h.histogram.fill(0);
    h.total = 0;
    h.ampQ.length = h.adcQ.length = h.displayQ.length = 0;
    h.displayDirty = true;
  }, [theme.sensorPixel, tmp]);

  useImperativeHandle(
    ref,
    () => ({ registerHit, getSensorPlane, toggle, getPhase: () => phaseRef.current, resetHits }),
    [registerHit, getSensorPlane, toggle, resetHits],
  );

  /* ---------- Vòng lặp mỗi frame ---------- */
  useFrame((_, rawDelta) => {
    // Animation UI: chấp nhận delta lớn hơn để vẫn giữ ~0.8 s trên máy yếu (FPS thấp).
    const dt = Math.min(rawDelta, UI_MAX_DELTA);
    const a = anim.current;

    // 1) Tách / lắp — dùng thời gian THỰC, không bị timeScale ảnh hưởng.
    switch (phaseRef.current) {
      case 'exploding':
        a.labelOpacity = 0;
        a.t = Math.min(1, a.t + dt / duration);
        a.progress = easeOutCubic(a.t);
        if (a.t >= 1) goTo('exploded');
        break;
      case 'exploded':
        a.progress = 1;
        a.labelOpacity = Math.min(1, a.labelOpacity + dt / LABEL_FADE_IN);
        break;
      case 'imploding':
        if (a.labelOpacity > 0) {
          // Pha 1: nhãn & mũi tên biến mất trước, bộ phận đứng yên.
          a.labelOpacity = Math.max(0, a.labelOpacity - dt / LABEL_FADE_OUT);
        } else {
          // Pha 2: cùng thời lượng & easing ease-out như lúc tách.
          a.t = Math.min(1, a.t + dt / duration);
          a.progress = 1 - easeOutCubic(a.t);
          if (a.t >= 1) {
            a.progress = 0;
            goTo('assembled');
          }
        }
        break;
      default:
        a.progress = 0;
        a.labelOpacity = 0;
    }

    for (let i = 0; i < DETECTOR_PARTS.length; i++) {
      const g = partGroups.current[i];
      const o = DETECTOR_PARTS[i].explodeOffset;
      if (g) g.position.set(o[0] * a.progress, o[1] * a.progress, o[2] * a.progress);
    }

    const opacity = showLabels ? a.labelOpacity : 0;
    if (opacity !== a.appliedOpacity) {
      a.appliedOpacity = opacity;
      const visible = opacity > 0.001;
      const c = callouts.current;
      for (let i = 0; i < DETECTOR_PARTS.length; i++) {
        const line = c.line[i];
        if (line) {
          (line.material as THREE.Material).opacity = opacity;
          line.visible = visible;
        }
        const arrow = c.arrow[i];
        if (arrow) {
          (arrow.material as THREE.Material).opacity = opacity;
          arrow.visible = visible;
        }
        const label = c.label[i];
        if (label) {
          label.style.opacity = String(opacity);
          label.style.visibility = visible ? 'visible' : 'hidden';
        }
      }
    }

    // 2) Ghi nhận hạt — dùng thời gian MÔ PHỎNG (chậm lại cùng hạt).
    const simDelta = getSimulationDelta(rawDelta);
    const simTime = useSimulationTime.getState().simTime;
    const h = hits.current;

    while (h.ampQ.length && h.ampQ[0].at <= simTime) {
      h.ampQ.shift();
      h.ampPulse = 1;
    }
    while (h.adcQ.length && h.adcQ[0].at <= simTime) {
      h.adcQ.shift();
      h.adcPulse = 1;
    }
    while (h.displayQ.length && h.displayQ[0].at <= simTime) {
      const s = h.displayQ.shift()!;
      h.histogram[s.col]++;
      h.total++;
      h.displayDirty = true;
    }

    h.ampPulse = Math.max(0, h.ampPulse - simDelta / LED_DECAY_TIME);
    h.adcPulse = Math.max(0, h.adcPulse - simDelta / LED_DECAY_TIME);
    if (ampLedRef.current) ampLedRef.current.emissiveIntensity = 0.3 + h.ampPulse * 4;
    if (adcLedRef.current) adcLedRef.current.emissiveIntensity = 0.3 + h.adcPulse * 4;

    const pixels = pixelsRef.current;
    if (pixels && h.active.size > 0) {
      tmp.base.set(theme.sensorPixel);
      tmp.hit.set(theme.hit);
      h.active.forEach((i) => {
        const v = Math.max(0, h.intensity[i] - simDelta / PIXEL_GLOW_TIME);
        h.intensity[i] = v;
        pixels.setColorAt(i, tmp.color.copy(tmp.base).lerp(tmp.hit, v));
        if (v === 0) h.active.delete(i);
      });
      if (pixels.instanceColor) pixels.instanceColor.needsUpdate = true;
    }

    h.sinceRedraw += dt;
    if (h.displayDirty && h.sinceRedraw > 0.08) {
      drawDisplay(display.ctx, theme, h.histogram, h.total);
      display.texture.needsUpdate = true;
      h.displayDirty = false;
      h.sinceRedraw = 0;
    }
  });

  /* ---------- Tương tác ---------- */
  const busy = phase === 'exploding' || phase === 'imploding';

  const handleClick = useCallback(
    (e: ThreeEvent<MouseEvent>) => {
      e.stopPropagation();
      // Bỏ qua nếu người dùng đang kéo xoay camera (OrbitControls).
      if (e.delta > 4) return;
      toggle();
    },
    [toggle],
  );

  const hovered = useRef(false);
  const setCursor = useCallback(() => {
    document.body.style.cursor = hovered.current ? (busy ? 'progress' : 'pointer') : 'auto';
  }, [busy]);
  useEffect(setCursor, [setCursor]);
  useEffect(
    () => () => {
      if (hovered.current) document.body.style.cursor = 'auto';
    },
    [],
  );

  const renderPart = (id: DetectorPartId) => {
    switch (id) {
      case 'window':
        return <WindowPart theme={theme} edge={edge} />;
      case 'housing':
        return <HousingPart theme={theme} edge={edge} />;
      case 'sensor':
        return <SensorPart theme={theme} edge={edge} pixelsRef={pixelsRef} faceRef={sensorFaceRef} />;
      case 'amplifier':
        return <AmplifierPart theme={theme} edge={edge} ledRef={ampLedRef} />;
      case 'adc':
        return <AdcPart theme={theme} edge={edge} ledRef={adcLedRef} />;
      case 'display':
        return <DisplayPart theme={theme} edge={edge} texture={display.texture} />;
      case 'hv':
        return <HvPart theme={theme} edge={edge} />;
    }
  };

  return (
    <group
      {...groupProps}
      onClick={handleClick}
      onPointerOver={(e) => {
        e.stopPropagation();
        hovered.current = true;
        setCursor();
      }}
      onPointerOut={() => {
        hovered.current = false;
        setCursor();
      }}
    >
      {DETECTOR_PARTS.map((spec, i) => (
        <group
          key={spec.id}
          name={`detector-${spec.id}`}
          ref={(el) => {
            partGroups.current[i] = el;
          }}
        >
          {renderPart(spec.id)}
          <Callout spec={spec} index={i} theme={theme} refs={callouts.current} />
        </group>
      ))}
    </group>
  );
});
