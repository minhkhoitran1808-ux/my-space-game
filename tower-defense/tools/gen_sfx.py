#!/usr/bin/env python3
"""Tổng hợp toàn bộ hiệu ứng âm thanh của game (không cần file ghi âm, không bản quyền).

Chạy lại bất cứ lúc nào để tạo lại assets/audio/*.wav:
    python3 tools/gen_sfx.py

Mỗi âm thanh ghép từ vài khối cơ bản (sine / square / noise, đường bao ADSR, quét tần số,
lọc thông thấp). RNG cố định seed nên kết quả luôn giống nhau.
Âm phát dày (tiếng bắn, địch chết) để nhỏ hơn âm sự kiện (thắng, thua, wave).
"""
import os
import wave

import numpy as np

RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
rng = np.random.default_rng(1808)


# --- Khối cơ bản -------------------------------------------------------------------

def t_axis(duration):
    return np.arange(int(RATE * duration)) / RATE


def sweep(f_start, f_end, duration, shape="sine", curve=1.0):
    """Dao động quét tần số từ f_start tới f_end (curve > 1: quét chậm lúc đầu)."""
    t = t_axis(duration)
    progress = (t / duration) ** curve
    freq = f_start + (f_end - f_start) * progress
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    if shape == "square":
        return np.sign(np.sin(phase)) * 0.6
    if shape == "saw":
        return 2.0 * ((phase / (2 * np.pi)) % 1.0) - 1.0
    if shape == "triangle":
        return 2.0 * np.abs(2.0 * ((phase / (2 * np.pi)) % 1.0) - 1.0) - 1.0
    return np.sin(phase)


def tone(freq, duration, shape="sine"):
    return sweep(freq, freq, duration, shape)


def noise(duration):
    return rng.uniform(-1.0, 1.0, int(RATE * duration))


def lowpass(signal, cutoff):
    """Lọc thông thấp một cực (cutoff có thể là mảng để lọc thay đổi theo thời gian)."""
    cutoff = np.broadcast_to(np.asarray(cutoff, dtype=float), signal.shape)
    alpha = 1.0 - np.exp(-2.0 * np.pi * cutoff / RATE)
    out = np.empty_like(signal)
    acc = 0.0
    for i, (x, a) in enumerate(zip(signal, alpha)):
        acc += a * (x - acc)
        out[i] = acc
    return out


def lowpass2(signal, cutoff):
    """Lọc thông thấp 2 lần (dốc hơn: tiếng nổ / gõ trầm và dày hơn)."""
    return lowpass(lowpass(signal, cutoff), cutoff)


def highpass(signal, cutoff):
    return signal - lowpass(signal, cutoff)


def envelope(length, attack=0.005, decay=0.1, sustain=0.0, release=0.05, hold=0.0):
    """ADSR (giây). Phần còn lại sau release là im lặng."""
    n = length
    env = np.zeros(n)
    points = [(0.0, 0.0), (attack, 1.0), (attack + decay, sustain),
              (attack + decay + hold, sustain), (attack + decay + hold + release, 0.0)]
    times = np.arange(n) / RATE
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    if sustain == 0.0:
        xs, ys = xs[:3], ys[:3]
    env[:] = np.interp(times, xs, ys, right=0.0)
    return env


def exp_decay(length, time_constant):
    return np.exp(-np.arange(length) / RATE / time_constant)


def pad(signal, duration):
    out = np.zeros(int(RATE * duration))
    out[:min(len(signal), len(out))] = signal[:len(out)]
    return out


def mix(*parts):
    length = max(len(p) for p in parts)
    out = np.zeros(length)
    for p in parts:
        out[:len(p)] += p
    return out


def at(signal, offset, total):
    out = np.zeros(int(RATE * total))
    start = int(RATE * offset)
    end = min(len(out), start + len(signal))
    out[start:end] = signal[:end - start]
    return out


def note(freq, duration, shape="triangle", attack=0.005, decay_tc=0.25):
    sig = tone(freq, duration, shape) + 0.3 * tone(freq * 2, duration)
    return sig * envelope(len(sig), attack=attack, decay=duration - attack, sustain=0.0) * \
        exp_decay(len(sig), decay_tc) * 2.0


def melody(notes, step, total, shape="triangle", decay_tc=0.25):
    """notes: danh sách (tần số, nhịp bắt đầu, độ dài nhịp)."""
    out = np.zeros(int(RATE * total))
    for freq, beat, length in notes:
        out += at(note(freq, step * length, shape, decay_tc=decay_tc), beat * step, total)
    return out


# Tần số nốt (Hz).
C4, D4, E4, F4, G4, A4, B4 = 261.6, 293.7, 329.6, 349.2, 392.0, 440.0, 493.9
C5, E5, G5, C6 = 523.3, 659.3, 784.0, 1046.5
G3, E3, C3 = 196.0, 164.8, 130.8


# --- Từng âm thanh ---------------------------------------------------------------

def shoot_archer():
    d = 0.12
    whoosh = highpass(noise(d), 1800) * exp_decay(int(RATE * d), 0.03)
    twang = sweep(980, 620, d) * exp_decay(int(RATE * d), 0.035)
    return mix(0.5 * whoosh, 0.6 * twang)


def shoot_cannon():
    d = 0.32
    n = int(RATE * d)
    thump = sweep(140, 45, d, curve=0.5) * exp_decay(n, 0.09)
    blast = lowpass2(noise(d), np.linspace(1600, 200, n)) * exp_decay(n, 0.06) * 2.5
    return mix(1.0 * thump, 0.9 * blast)


def shoot_frost():
    d = 0.22
    n = int(RATE * d)
    bell = (tone(1760, d) + 0.6 * tone(2637, d) + 0.3 * tone(3520, d)) * exp_decay(n, 0.06)
    hiss = highpass(noise(d), 4000) * exp_decay(n, 0.04)
    return mix(0.45 * bell, 0.25 * hiss)


def shoot_mage():
    d = 0.2
    n = int(RATE * d)
    t = t_axis(d)
    zap = sweep(500, 1500, d, "saw") * (1.0 + 0.3 * np.sin(2 * np.pi * 35 * t))
    zap = lowpass(zap, 3500) * envelope(n, attack=0.01, decay=0.19)
    return 0.55 * zap


def explosion():
    d = 0.6
    n = int(RATE * d)
    rumble = lowpass2(noise(d), np.linspace(1200, 120, n)) * exp_decay(n, 0.16) * 3.0
    boom = sweep(90, 35, d) * exp_decay(n, 0.2)
    return mix(1.2 * rumble, 0.8 * boom)


def enemy_death():
    d = 0.16
    n = int(RATE * d)
    pop = sweep(720, 180, d, curve=0.6) * exp_decay(n, 0.045)
    crack = highpass(noise(d), 2500) * exp_decay(n, 0.015)
    return mix(0.7 * pop, 0.35 * crack)


def base_hit():
    d = 0.45
    n = int(RATE * d)
    thud = sweep(110, 55, d) * exp_decay(n, 0.12)
    buzz = lowpass(tone(98, d, "square") + tone(104, d, "square"), 900) * exp_decay(n, 0.15)
    return mix(1.0 * thud, 0.5 * buzz)


def build():
    total = 0.28

    def knock():
        d = 0.08
        n = int(RATE * d)
        return (lowpass2(noise(d), 1000) * 3.0 + 0.6 * sweep(320, 220, d)) * exp_decay(n, 0.02)
    return mix(at(knock(), 0.0, total), at(0.8 * knock(), 0.11, total))


def upgrade():
    return 0.55 * lowpass(melody([(C5, 0, 1), (E5, 1, 1), (G5, 2, 1), (C6, 3, 2)], 0.07, 0.5, "square", 0.12), 2500)


def sell():
    total = 0.32
    return 0.5 * mix(at(note(1318.5, 0.12, "sine", decay_tc=0.06), 0.0, total),
                     at(note(1760.0, 0.25, "sine", decay_tc=0.1), 0.07, total))


def wave_start():
    d = 0.75
    n = int(RATE * d)
    horn = tone(G3 * 1.0, d, "saw") + 0.7 * tone(G3 * 1.5, d, "saw") + 0.4 * tone(G3 * 2, d, "saw")
    horn = lowpass(horn, np.linspace(600, 2000, n)) * envelope(n, attack=0.08, decay=0.1, sustain=0.8,
                                                              hold=0.35, release=0.2)
    return 0.35 * horn


def wave_complete():
    return 0.5 * melody([(G4, 0, 1), (C5, 1, 1), (E5, 2, 2)], 0.1, 0.7)


def victory():
    notes = [(C5, 0, 1), (E5, 1, 1), (G5, 2, 1), (C6, 3, 3), (G5, 6, 1), (C6, 7, 4)]
    lead = melody(notes, 0.12, 1.6, decay_tc=0.35)
    bass = melody([(C3, 0, 6), (G3, 6, 6)], 0.12, 1.6, "sine", decay_tc=0.6)
    return 0.5 * lead + 0.35 * bass


def defeat():
    notes = [(G4, 0, 2), (E4, 2, 2), (C4, 4, 2), (B4 / 2, 6, 6)]
    lead = melody(notes, 0.16, 1.8, "triangle", decay_tc=0.4)
    return 0.55 * lowpass(lead, 1600)


def ability_meteor():
    total = 1.1
    whoosh_d = 0.5
    n = int(RATE * whoosh_d)
    whoosh = lowpass(noise(whoosh_d), np.linspace(400, 4000, n)) * np.linspace(0.1, 1.0, n)
    boom = explosion()
    return mix(at(0.6 * whoosh, 0.0, total), at(1.1 * boom, whoosh_d, total))


def ability_freeze():
    d = 0.9
    n = int(RATE * d)
    chord = (tone(1318.5, d) + tone(1975.5, d) + tone(2637.0, d)) / 3.0
    shimmer = chord * (0.6 + 0.4 * np.sin(2 * np.pi * 9 * t_axis(d)))
    hiss = highpass(noise(d), 5000) * exp_decay(n, 0.25)
    return mix(0.5 * shimmer * envelope(n, attack=0.02, decay=0.88), 0.35 * hiss)


def achievement():
    notes = [(G5, 0, 1), (C6, 1, 1), (E5 * 2, 2, 3)]
    sparkle = highpass(noise(0.6), 6000) * exp_decay(int(RATE * 0.6), 0.15)
    return mix(0.5 * melody(notes, 0.08, 0.6, "sine", 0.18), 0.12 * sparkle)


# Âm nào phát dày thì nhỏ hơn (đỉnh tính theo dBFS).
SOUNDS = {
    "shoot_archer": (shoot_archer, -14.0),
    "shoot_cannon": (shoot_cannon, -9.0),
    "shoot_frost": (shoot_frost, -15.0),
    "shoot_mage": (shoot_mage, -14.0),
    "explosion": (explosion, -8.0),
    "enemy_death": (enemy_death, -12.0),
    "base_hit": (base_hit, -5.0),
    "build": (build, -6.0),
    "upgrade": (upgrade, -6.0),
    "sell": (sell, -7.0),
    "wave_start": (wave_start, -6.0),
    "wave_complete": (wave_complete, -6.0),
    "victory": (victory, -4.0),
    "defeat": (defeat, -4.0),
    "ability_meteor": (ability_meteor, -4.0),
    "ability_freeze": (ability_freeze, -6.0),
    "achievement": (achievement, -7.0),
}


def write_wav(path, signal, peak_db):
    # Fade 5ms ở hai đầu để không có tiếng "tách".
    fade = min(int(RATE * 0.005), len(signal) // 2)
    signal = signal.copy()
    signal[:fade] *= np.linspace(0.0, 1.0, fade)
    signal[-fade:] *= np.linspace(1.0, 0.0, fade)
    peak = np.max(np.abs(signal)) or 1.0
    signal = signal / peak * (10 ** (peak_db / 20.0))
    data = (np.clip(signal, -1.0, 1.0) * 32767).astype("<i2")
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data.tobytes())


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, (builder, peak_db) in SOUNDS.items():
        path = os.path.join(OUT_DIR, name + ".wav")
        write_wav(path, builder(), peak_db)
        print(f"{name:16s} {os.path.getsize(path) / 1024:6.1f} KB")


if __name__ == "__main__":
    main()
