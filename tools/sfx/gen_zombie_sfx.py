"""Deadzone Last Stand zombi ses efektleri (sentez): agir darbe, kaya, kalkan, boss.

Calistirma (proje kokunden):  python tools/sfx/gen_zombie_sfx.py
Cikti: assets/audio/sfx/z_*.wav (44.1 kHz, 16 bit, mono, 4 ms fade, tepe -3 dBFS). Sabit tohumlu.
Hepsi alcak geciren suzgecten gecer; tonal cinlama yok. Yardimcilar kendi icinde (yan etkisiz).
Ardindan: godot --headless --path . --import
"""

from __future__ import annotations

import math
import random
import struct
import sys
import wave
from pathlib import Path

SR = 44100
PEAK = 10 ** (-3.0 / 20.0)  # -3 dBFS
FADE = 0.004
OUT_DIR = Path(__file__).resolve().parents[2] / "assets" / "audio" / "sfx"


def n_of(seconds: float) -> int:
    return int(seconds * SR)


def noise(n: int, rng: random.Random) -> list[float]:
    return [rng.uniform(-1.0, 1.0) for _ in range(n)]


def lowpass(sig: list[float], freq: float, passes: int = 2) -> list[float]:
    """RBJ biquad alcak geciren, ard arda 'passes' kez (Q=0.707)."""
    w0 = 2.0 * math.pi * freq / SR
    alpha = math.sin(w0) / (2.0 * 0.707)
    cw = math.cos(w0)
    b0 = (1 - cw) / 2
    b1 = 1 - cw
    b2 = (1 - cw) / 2
    a0 = 1 + alpha
    a1 = -2 * cw
    a2 = 1 - alpha
    b0, b1, b2, a1, a2 = b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0
    out = sig
    for _ in range(passes):
        x1 = x2 = y1 = y2 = 0.0
        res = []
        for x in out:
            y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            x2, x1, y2, y1 = x1, x, y1, y
            res.append(y)
        out = res
    return out


def env_exp(n: int, tau: float, attack: float = 0.001) -> list[float]:
    a = max(1, int(attack * SR))
    return [min(1.0, i / a) * math.exp(-(i / SR) / tau) for i in range(n)]


def sweep(n: int, f0: float, f1: float, tau_f: float) -> list[float]:
    """Ustel inen frekansli sinus (darbe govdesi)."""
    ph = 0.0
    out = []
    for i in range(n):
        f = f1 + (f0 - f1) * math.exp(-(i / SR) / tau_f)
        ph += 2.0 * math.pi * f / SR
        out.append(math.sin(ph))
    return out


def mix_into(dst: list[float], src: list[float], gain: float = 1.0, start: float = 0.0) -> None:
    s0 = n_of(start)
    for i, v in enumerate(src):
        j = s0 + i
        if j < len(dst):
            dst[j] += v * gain


def grain(rng: random.Random, dur: float, tau: float, cutoff: float) -> list[float]:
    n = n_of(dur)
    g = lowpass(noise(n, rng), cutoff, 1)
    e = env_exp(n, tau, 0.0008)
    return [a * b for a, b in zip(g, e)]


def scatter(total: float, rng: random.Random, count: int, t0: float, t1: float, gain: float, cutoff: float) -> list[float]:
    """Cakil/enkaz serpintisi: rastgele zamanli kisa gurultu taneleri, zamanla zayiflar."""
    buf = [0.0] * n_of(total)
    for _ in range(count):
        t = rng.uniform(t0, t1)
        fall = math.exp(-(t - t0) / max(0.05, (t1 - t0) * 0.6))
        g = grain(rng, rng.uniform(0.01, 0.035), rng.uniform(0.004, 0.012), cutoff * rng.uniform(0.6, 1.0))
        mix_into(buf, g, gain * fall * rng.uniform(0.4, 1.0), t)
    return buf


def finish(sig: list[float]) -> list[float]:
    f = max(1, int(FADE * SR))
    for i in range(min(f, len(sig))):
        k = i / f
        sig[i] *= k
        sig[-1 - i] *= k
    peak = max(abs(v) for v in sig) or 1.0
    return [v * PEAK / peak for v in sig]


def write_wav(name: str, sig: list[float]) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sig = finish(sig)
    with wave.open(str(OUT_DIR / (name + ".wav")), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in sig))
    print("%s %.2fs" % (name, len(sig) / SR))


# --- Sesler -----------------------------------------------------------------------------------

def heavy_impact(rng: random.Random, length: float, f_hi: float, f_lo: float, tau: float, debris: int) -> list[float]:
    n = n_of(length)
    body = [a * b for a, b in zip(sweep(n, f_hi, f_lo, 0.05), env_exp(n, tau, 0.002))]
    sub = [a * b for a, b in zip(sweep(n, f_lo * 1.0, f_lo * 0.8, 0.2), env_exp(n, tau * 1.4, 0.004))]
    thump = lowpass(grain(rng, length, tau * 0.35, 700.0), 500.0, 2)
    sig = [0.0] * n
    mix_into(sig, body, 1.0)
    mix_into(sig, sub, 0.7)
    mix_into(sig, thump, 1.4)
    mix_into(sig, scatter(length, rng, debris, 0.04, length * 0.8, 0.7, 1800.0), 0.5)
    return lowpass(sig, 900.0, 2)


def rock_impact(rng: random.Random, length: float, f_hi: float, count: int) -> list[float]:
    n = n_of(length)
    thud = [a * b for a, b in zip(sweep(n, f_hi, f_hi * 0.55, 0.03), env_exp(n, 0.05, 0.001))]
    click = lowpass(grain(rng, 0.05, 0.012, 2200.0), 2000.0, 2)
    sig = [0.0] * n
    mix_into(sig, thud, 1.0)
    mix_into(sig, click, 1.2)
    mix_into(sig, scatter(length, rng, count, 0.03, length * 0.85, 1.0, 2600.0), 0.8)
    return lowpass(sig, 2400.0, 2)


def shield_thunk(rng: random.Random, f_hi: float, length: float) -> list[float]:
    n = n_of(length)
    body = [a * b for a, b in zip(sweep(n, f_hi, f_hi * 0.6, 0.02), env_exp(n, 0.03, 0.0008))]
    pad = lowpass(grain(rng, length, 0.018, 900.0), 800.0, 2)
    sig = [0.0] * n
    mix_into(sig, body, 1.0)
    mix_into(sig, pad, 1.6)
    return lowpass(sig, 1500.0, 2)


def boss_charge(rng: random.Random) -> list[float]:
    total = 1.2
    n = n_of(total)
    sig = [0.0] * n
    step = 0.2
    for k in range(6):
        t = 0.02 + k * step
        g = 0.55 + 0.1 * k
        m = n_of(0.35)
        th = [a * b for a, b in zip(sweep(m, 85.0, 42.0, 0.06), env_exp(m, 0.1, 0.004))]
        mix_into(sig, th, g, t)
        mix_into(sig, lowpass(grain(rng, 0.3, 0.07, 400.0), 300.0, 2), g * 1.6, t)
    rumble = lowpass(noise(n, rng), 160.0, 2)
    for i in range(n):
        x = i / SR
        sig[i] += rumble[i] * 3.0 * (0.5 + 0.5 * math.sin(2.0 * math.pi * 11.0 * x)) * min(1.0, x / 0.2)
    swell = [min(1.0, i / n_of(0.25)) * min(1.0, (n - i) / n_of(0.35)) for i in range(n)]
    sig = [a * b for a, b in zip(sig, swell)]
    return lowpass(sig, 400.0, 2)


def boss_warning(rng: random.Random) -> list[float]:
    total = 2.0
    n = n_of(total)
    specs = [(55.0, 1.0), (55.9, 0.9), (82.5, 0.5), (110.0, 0.7), (111.1, 0.6), (165.0, 0.25)]
    sig = [0.0] * n
    ph = [rng.uniform(0.0, 6.28) for _ in specs]
    for i in range(n):
        x = i / SR
        v = 0.0
        for k, (f, a) in enumerate(specs):
            v += a * math.sin(2.0 * math.pi * f * x + ph[k])
        sig[i] = v
    # yumusak doyum: alt harmoniklere etki, sonra alcak geciren
    sig = [math.tanh(1.6 * v / 3.0) for v in sig]
    swell = [math.sin(math.pi * min(1.0, (i / n) ** 0.9)) ** 1.5 for i in range(n)]
    sig = [a * b for a, b in zip(sig, swell)]
    return lowpass(sig, 450.0, 2)


def main() -> int:
    for i, (ln, fh, fl, tau, deb) in enumerate([(0.6, 120.0, 45.0, 0.16, 14), (0.5, 105.0, 42.0, 0.14, 10), (0.8, 90.0, 38.0, 0.22, 20)], 1):
        write_wav("z_heavy_impact_%d" % i, heavy_impact(random.Random(1000 + i), ln, fh, fl, tau, deb))
    for i, (ln, fh, cnt) in enumerate([(0.45, 160.0, 12), (0.55, 140.0, 16)], 1):
        write_wav("z_rock_impact_%d" % i, rock_impact(random.Random(2000 + i), ln, fh, cnt))
    for i, (fh, ln) in enumerate([(130.0, 0.16), (110.0, 0.14), (150.0, 0.18)], 1):
        write_wav("z_shield_thunk_%d" % i, shield_thunk(random.Random(3000 + i), fh, ln))
    write_wav("z_boss_charge_1", boss_charge(random.Random(4001)))
    write_wav("z_boss_warning_1", boss_warning(random.Random(5001)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
