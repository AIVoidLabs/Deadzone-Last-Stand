"""Deadzone Last Stand silah sesleri v2 (2/2): koyu, kapali, alcak-orta govdeli sentez.

Calistirma (proje kokunden):  python tools/sfx/process_weapons.py && python tools/sfx/gen_weapons_v2.py
Girdi : build/audio_tmp/w_shotgun_src.16.wav (process_weapons.py ara urunu; pompali icin gercek atis katmani)
Cikti : assets/audio/sfx/w_shotgun_*, w_launcher_*, w_explosion_*, w_plasma_*, w_graviton_*, w_swing_*.wav
        (44.1 kHz, 16 bit, mono, tepe -3 dBFS). Sabit tohumlu. gen_sfx.py ciktilarina dokunmaz.
Hepsi alcak geciren ile kapatilir: parlak/metalik tini yok, kuyruk kisa (sik atis).
"""

from __future__ import annotations

import math
import random
import struct
import sys
import wave
from pathlib import Path

import gen_sfx as g  # yalnizca yardimcilar (main korumali, yan etkisi yok)

SR = g.SR
ROOT = Path(__file__).resolve().parents[2]
SHOTGUN_SRC = ROOT / "build" / "audio_tmp" / "w_shotgun_src.16.wav"
PEAK = 10.0 ** (-3.0 / 20.0)  # -3 dBFS


def write(name: str, sig: list[float]) -> None:
    sig = g.filt(sig, "hp", 25.0)  # DC ve sub-ses payini at
    n = len(sig)
    fi = g.frames(0.002)
    sig = [v * min(1.0, i / fi) for i, v in enumerate(sig)]
    sig = g.fade_out(sig, min(0.03, n / SR * 0.2))
    peak = max(abs(v) for v in sig) or 1.0
    path = g.OUT_DIR / f"{name}.wav"
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * PEAK / peak)) * 32767)) for v in sig))
    print(f"  {path.name}  {n / SR:.2f} sn")


def read_wav(path: Path) -> list[float]:
    with wave.open(str(path)) as w:
        n = w.getnframes()
        return [v / 32768.0 for v in struct.unpack("<%dh" % n, w.readframes(n))]


def resample(sig: list[float], ratio: float) -> list[float]:
    """Dogrusal ornekleme: ratio < 1 daha alcak ve uzun."""
    n = int(len(sig) / ratio)
    out = []
    for i in range(n):
        x = i * ratio
        j = int(x)
        fr = x - j
        b = sig[j + 1] if j + 1 < len(sig) else 0.0
        out.append(sig[j] * (1.0 - fr) + b * fr)
    return out


def sweep_boom(total: float, f_hi: float, f_lo: float, fall: float, tau: float) -> list[float]:
    n = g.frames(total)
    tone = g.sine_sweep(n, lambda t: f_lo + (f_hi - f_lo) * math.exp(-t / fall))
    return g.apply(tone, g.env_exp(n, tau, 0.002))


def noise_burst(rng: random.Random, total: float, lp: float, tau: float, attack: float = 0.001) -> list[float]:
    n = g.frames(total)
    return g.apply(g.lp2(g.noise(n, rng), lp), g.env_exp(n, tau, attack))


def dull_chk(rng: random.Random, body_hz: float, pitch: float) -> list[float]:
    """Pompa 'chk': sadece alcak-orta tok darbe, tin yok (<= 1.2 kHz)."""
    n = g.frames(0.09)
    thump = g.apply(g.sine_sweep(n, lambda t: pitch * (1.0 + 0.5 * math.exp(-t / 0.015))), g.env_exp(n, 0.03, 0.001))
    body = g.apply(g.lp2(g.filt(g.noise(n, rng), "bp", body_hz, 0.8), 1200.0), g.env_exp(n, 0.025, 0.001))
    return [a * 0.8 + b * 0.6 for a, b in zip(thump, body)]


# --- Sesler -----------------------------------------------------------------------------------

def shotgun(rng: random.Random, src: list[float], boom_hz: float) -> list[float]:
    out = [0.0] * g.frames(0.62)
    g.mix_into(out, src, 0.8)
    g.mix_into(out, sweep_boom(0.35, boom_hz * 2.0, boom_hz, 0.05, 0.12), 0.9)
    g.mix_into(out, dull_chk(rng, 500.0, 95.0), 0.35, 0.25)
    g.mix_into(out, dull_chk(rng, 420.0, 80.0), 0.3, 0.33)
    return g.soft_clip(out, 1.2)


def launcher(rng: random.Random, f_hi: float) -> list[float]:
    out = [0.0] * g.frames(0.3)
    g.mix_into(out, sweep_boom(0.3, f_hi, 80.0, 0.03, 0.07), 1.0)
    g.mix_into(out, noise_burst(rng, 0.3, 1500.0, 0.035), 0.6)
    air = g.apply(g.filt(g.noise(g.frames(0.3), rng), "bp", 600.0, 0.9), g.env_swell(g.frames(0.3), 0.3, 1.5))
    g.mix_into(out, air, 0.2)
    return g.lp2(g.soft_clip(out, 1.3), 1500.0)


def explosion(rng: random.Random, total: float, boom_hz: float) -> list[float]:
    n = g.frames(total)
    out = [0.0] * n
    g.mix_into(out, sweep_boom(total, 90.0, boom_hz, 0.12, 0.3), 1.0)
    rumble = g.filt(g.noise(n, rng), "lp", lambda t: 2500.0 * math.exp(-t / 0.25) + 180.0)
    g.mix_into(out, g.apply(rumble, g.env_exp(n, total * 0.3, 0.004)), 0.9)
    for _ in range(int(total * 14)):  # alcak enkaz: seyrek, yumusak, kisa parcalar
        at = rng.uniform(0.08, total * 0.75)
        g.mix_into(out, noise_burst(rng, 0.15, 1200.0, 0.04, 0.003), rng.uniform(0.08, 0.25), at)
    return g.lp2(g.soft_clip(out, 1.4), 2500.0)


def plasma(rng: random.Random, f0: float) -> list[float]:
    n = g.frames(0.18)
    out = [0.0] * n
    tone = g.sine_sweep(n, lambda t: f0 * math.exp(-t / 0.07) + 180.0)
    g.mix_into(out, g.apply(tone, g.env_exp(n, 0.06)), 0.7)
    buzz = g.saw(n, lambda t: 110.0 * math.exp(-t / 0.08) + 70.0)
    g.mix_into(out, g.apply(g.filt(buzz, "lp", 800.0), g.env_exp(n, 0.07)), 0.35)
    g.mix_into(out, g.apply(g.filt(g.noise(n, rng), "bp", 900.0, 0.8), g.env_exp(n, 0.02)), 0.2)
    return g.lp2(g.soft_clip(out, 1.3), 3000.0)


def graviton(rng: random.Random) -> list[float]:
    total = 0.36
    n = g.frames(total)
    out = [0.0] * n
    g.mix_into(out, sweep_boom(total, 80.0, 34.0, 0.1, 0.13), 0.9)
    air = g.filt(g.noise(n, rng), "bp", lambda t: 200.0 + 700.0 * min(1.0, t / total), 0.9)
    g.mix_into(out, g.apply(air, g.env_swell(n, 0.25, 1.5)), 0.3)
    hum = g.sine_sweep(n, lambda t: 160.0 - 70.0 * min(1.0, t / total))
    g.mix_into(out, g.apply(hum, g.env_swell(n, 0.2, 1.4)), 0.25)
    return g.lp2(g.soft_clip(out, 1.2), 3000.0)


def swing(rng: random.Random, total: float, low: float, high: float, thud_gain: float, thud_hz: float) -> list[float]:
    """Karanlik savurma: bant gecirilmis hava + yumusak 'et' darbesi; metal tini yok."""
    n = g.frames(total)
    out = [0.0] * n
    sweep = lambda t: low + (high - low) * math.sin(math.pi * min(1.0, t / total)) ** 1.4
    air = g.filt(g.noise(n, rng), "bp", sweep, 1.0)
    g.mix_into(out, g.apply(air, g.env_swell(n, 0.4, 1.4)), 0.8)
    g.mix_into(out, g.thud(rng, thud_hz * 1.6, thud_hz, 0.045, 300.0, 0.4), thud_gain, total * 0.5)
    return g.lp2(g.soft_clip(out, 1.1), 1800.0)


def swing_energy(rng: random.Random, hum: float) -> list[float]:
    total = 0.4
    n = g.frames(total)
    out = [0.0] * n
    f = lambda t: hum * (0.85 + 0.35 * math.sin(math.pi * min(1.0, t / total)))
    for mult, gain in ((1.0, 0.8), (2.0, 0.3), (3.0, 0.12)):
        tone = g.sine_sweep(n, lambda t, m=mult: f(t) * m)
        g.mix_into(out, g.apply(tone, g.env_swell(n, 0.4, 1.2)), gain)
    air = g.filt(g.noise(n, rng), "bp", lambda t: 300.0 + 600.0 * math.sin(math.pi * min(1.0, t / total)), 1.0)
    g.mix_into(out, g.apply(air, g.env_swell(n, 0.4, 1.4)), 0.2)
    return g.lp2(g.soft_clip(out, 1.1), 2000.0)


def swing_fire(rng: random.Random) -> list[float]:
    total = 0.36
    n = g.frames(total)
    out = [0.0] * n
    sweep = lambda t: 250.0 + 950.0 * math.sin(math.pi * min(1.0, t / total)) ** 1.4
    air = g.filt(g.noise(n, rng), "bp", sweep, 1.0)
    g.mix_into(out, g.apply(air, g.env_swell(n, 0.4, 1.4)), 0.5)
    roar = g.lp2(g.noise(n, rng), 700.0)
    g.mix_into(out, g.apply(roar, g.env_swell(n, 0.35, 1.5)), 0.9)
    for _ in range(int(total * 50)):  # yumusak, bastirilmis fitil carpmasi (parlak degil)
        at = rng.uniform(0.0, total * 0.9)
        pop = g.apply(g.lp2(g.filt(g.noise(g.frames(0.015), rng), "hp", 400.0), 1500.0), g.env_exp(g.frames(0.015), 0.004))
        g.mix_into(out, pop, rng.uniform(0.1, 0.3), at)
    return g.lp2(g.soft_clip(out, 1.1), 2000.0)


def main() -> int:
    print(f"Silah sesleri v2 -> {g.OUT_DIR}")
    src = read_wav(SHOTGUN_SRC)
    for i, (seed, ratio, hz) in enumerate(((1101, 1.0, 55.0), (1102, 0.95, 48.0)), start=1):
        write(f"w_shotgun_{i}", shotgun(random.Random(seed), resample(src, ratio) if ratio != 1.0 else src, hz))
    for i, (seed, f_hi) in enumerate(((1111, 200.0), (1112, 170.0)), start=1):
        write(f"w_launcher_{i}", launcher(random.Random(seed), f_hi))
    for i, (seed, total, hz) in enumerate(((1121, 1.2, 34.0), (1122, 1.0, 40.0), (1123, 1.4, 30.0)), start=1):
        write(f"w_explosion_{i}", explosion(random.Random(seed), total, hz))
    for i, (seed, f0) in enumerate(((1131, 700.0), (1132, 620.0), (1133, 780.0)), start=1):
        write(f"w_plasma_{i}", plasma(random.Random(seed), f0))
    for i, seed in enumerate((1141, 1142), start=1):
        write(f"w_graviton_{i}", graviton(random.Random(seed)))
    for i, seed in enumerate((1151, 1152, 1153), start=1):
        write(f"w_swing_light_{i}", swing(random.Random(seed), 0.16, 250.0, 1100.0, 0.25, 70.0))
    for i, seed in enumerate((1161, 1162, 1163), start=1):
        write(f"w_swing_medium_{i}", swing(random.Random(seed), 0.26, 200.0, 1500.0, 0.45, 55.0))
    for i, (seed, hum) in enumerate(((1171, 80.0), (1172, 70.0), (1173, 90.0)), start=1):
        write(f"w_swing_energy_{i}", swing_energy(random.Random(seed), hum))
    for i, seed in enumerate((1181, 1182, 1183), start=1):
        write(f"w_swing_fire_{i}", swing_fire(random.Random(seed)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
