import { useMemo, useRef, type RefObject } from 'react';
import * as THREE from 'three';
import { useSimulationFrame } from '../store/simulationTime';
import type { DetectorHandle, SensorPlane } from './Detector';

type Vec3 = [number, number, number];

export interface ParticleStreamProps {
  detectorRef: RefObject<DetectorHandle>;
  /** Tâm giữa hai khe (world). */
  slitPosition?: Vec3;
  /** Khoảng cách hai khe d, bề rộng mỗi khe a, bước sóng λ (đơn vị scene, phóng đại cho dễ thấy). */
  slitSeparation?: number;
  slitWidth?: number;
  wavelength?: number;
  /** Số hạt phát ra mỗi giây MÔ PHỎNG. */
  emitRate?: number;
  /** Vận tốc hạt (đơn vị/giây MÔ PHỎNG). */
  speed?: number;
  maxParticles?: number;
  color?: string;
  size?: number;
}

/**
 * Hệ hạt mẫu: phát hạt từ khe đôi, chọn điểm đến theo phân bố giao thoa
 * I(x) ∝ cos²(πdx/λL)·sinc²(πax/λL), bay thẳng tới mặt cảm biến rồi báo cho Detector.
 *
 * Mọi chuyển động dùng `simDelta` từ useSimulationFrame, nên chỉnh tốc độ
 * thời gian ở một chỗ là toàn bộ hạt chậm lại — kể cả khi detector đang tách rã.
 */
export function ParticleStream({
  detectorRef,
  slitPosition = [0, 0, -3],
  slitSeparation = 0.3,
  slitWidth = 0.06,
  wavelength = 0.012,
  emitRate = 14,
  speed = 3,
  maxParticles = 256,
  color = '#fff3b0',
  size = 0.025,
}: ParticleStreamProps) {
  const meshRef = useRef<THREE.InstancedMesh>(null);

  const sim = useMemo(
    () => ({
      pos: new Float32Array(maxParticles * 3),
      vel: new Float32Array(maxParticles * 3),
      age: new Float32Array(maxParticles),
      alive: new Uint8Array(maxParticles),
      emitAcc: 0,
      next: 0,
      plane: {
        origin: new THREE.Vector3(),
        normal: new THREE.Vector3(),
        u: new THREE.Vector3(),
        v: new THREE.Vector3(),
        halfWidth: 0,
        halfHeight: 0,
        apertureHalfWidth: 0,
        apertureHalfHeight: 0,
      } as SensorPlane,
      slit: new THREE.Vector3(),
      a: new THREE.Vector3(),
      b: new THREE.Vector3(),
      hit: new THREE.Vector3(),
      dummy: new THREE.Object3D(),
    }),
    [maxParticles],
  );

  const intensity = (x: number, L: number) => {
    const k = Math.PI / (wavelength * L);
    const beta = k * slitWidth * x;
    const sinc = beta === 0 ? 1 : Math.sin(beta) / beta;
    return Math.cos(k * slitSeparation * x) ** 2 * sinc * sinc;
  };

  const spawn = (plane: SensorPlane) => {
    const i = sim.next;
    sim.next = (sim.next + 1) % maxParticles;

    // Điểm xuất phát: một trong hai khe (dọc trục u của cảm biến).
    const side = Math.random() < 0.5 ? -0.5 : 0.5;
    sim.a.set(...slitPosition).addScaledVector(plane.u, side * slitSeparation);

    // Điểm đến: lấy mẫu theo phân bố giao thoa (rejection sampling).
    const L = sim.slit.set(...slitPosition).distanceTo(plane.origin);
    const xMax = plane.apertureHalfWidth * 0.95;
    let x = 0;
    for (let tries = 0; tries < 64; tries++) {
      x = (Math.random() * 2 - 1) * xMax;
      if (Math.random() < intensity(x, L)) break;
    }
    const y = (Math.random() * 2 - 1) * plane.apertureHalfHeight * 0.6;
    sim.b.copy(plane.origin).addScaledVector(plane.u, x).addScaledVector(plane.v, y);

    const dir = sim.b.sub(sim.a).normalize().multiplyScalar(speed);
    sim.pos.set([sim.a.x, sim.a.y, sim.a.z], i * 3);
    sim.vel.set([dir.x, dir.y, dir.z], i * 3);
    sim.age[i] = 0;
    sim.alive[i] = 1;
  };

  useSimulationFrame((_, simDelta) => {
    const mesh = meshRef.current;
    const detector = detectorRef.current;
    if (!mesh || !detector) return;
    const plane = detector.getSensorPlane(sim.plane);

    if (simDelta > 0) {
      sim.emitAcc += simDelta * emitRate;
      while (sim.emitAcc >= 1) {
        sim.emitAcc -= 1;
        spawn(plane);
      }
    }

    const { pos, vel, age, alive, dummy } = sim;
    for (let i = 0; i < maxParticles; i++) {
      const o = i * 3;
      if (!alive[i]) {
        dummy.scale.setScalar(0);
        dummy.updateMatrix();
        mesh.setMatrixAt(i, dummy.matrix);
        continue;
      }

      // Khoảng cách có dấu tới mặt cảm biến trước và sau bước này.
      sim.a.set(pos[o], pos[o + 1], pos[o + 2]);
      const before = sim.hit.copy(sim.a).sub(plane.origin).dot(plane.normal);
      pos[o] += vel[o] * simDelta;
      pos[o + 1] += vel[o + 1] * simDelta;
      pos[o + 2] += vel[o + 2] * simDelta;
      sim.b.set(pos[o], pos[o + 1], pos[o + 2]);
      const after = sim.hit.copy(sim.b).sub(plane.origin).dot(plane.normal);
      age[i] += simDelta;

      if (before < 0 && after >= 0) {
        const f = before / (before - after);
        sim.hit.copy(sim.a).lerp(sim.b, f);
        detector.registerHit(sim.hit);
        alive[i] = 0;
      } else if (age[i] > 30) {
        alive[i] = 0;
      }

      // Vệt kéo dài theo hướng bay để nhìn rõ quỹ đạo khi làm chậm.
      dummy.position.copy(sim.b);
      dummy.lookAt(sim.hit.copy(sim.b).add(sim.a.set(vel[o], vel[o + 1], vel[o + 2])));
      if (alive[i]) dummy.scale.set(1, 1, 3);
      else dummy.scale.setScalar(0);
      dummy.updateMatrix();
      mesh.setMatrixAt(i, dummy.matrix);
    }
    mesh.instanceMatrix.needsUpdate = true;
  });

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, maxParticles]} frustumCulled={false}>
      <sphereGeometry args={[size, 10, 10]} />
      <meshBasicMaterial color={color} toneMapped={false} />
    </instancedMesh>
  );
}
