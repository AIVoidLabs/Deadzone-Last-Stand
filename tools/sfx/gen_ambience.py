"""Deadzone Last Stand ortam sesleri: koddan sentez (yalniz standart kutuphane), dis dosya yok.

Calistirma (proje kokunden):  python tools/sfx/gen_ambience.py
Cikti: assets/audio/ambience/<ad>.wav (44.1 kHz, 16 bit, mono). Sabit tohumlu: her calistirma ayni dosyalari uretir.
Ardindan: godot --headless --path . --import
Dongu dosyalari (loop=True) dikis noktasinda capraz solmayla kapatilir; Godot'ta dongu AudioStreamWAV'a
kodda verilir (scripts/world/ambience_stream.gd), .import ayari gerekmez.
fire_crackle, distant_* YER TUTUCUDUR; gercek CC0 dosyalar gelince scripts/data/ambience_data.gd'de dosya adi degisir.
"""

from __future__ import annotations

import math
import random
import struct
import sys
import wave
from pathlib import Path

SR = 44100
PEAK = 0.85
OUT_DIR = Path(__file__).resolve().parents[2] / "assets" / "audio" / "ambience"
TAU = math.tau


def n_of(seconds: float) -> int:
    return int(round(seconds * SR))


def noise(n: int, rng: random.Random) -> list[float]:
    return [rng.uniform(-1.0, 1.0) for _ in range(n)]


def lowpass(sig: list[float], freq: float, passes: int = 2) -> list[float]:
    """Tek kutuplu alcak geciren, birkac gecis (daha dik)."""
    a = 1.0 - math.exp(-TAU * freq / SR)
    out = sig
    for _ in range(passes):
        y = out[0] if out else 0.0  # sifirdan baslamasin (sabit girisin basinda rampa olmasin)
        res = []
        for x in out:
            y += a * (x - y)
            res.append(y)
        out = res
    return out


def highpass(sig: list[float], freq: float) -> list[float]:
    low = lowpass(sig, freq, 1)
    return [x - l for x, l in zip(sig, low)]


def bandpass(sig: list[float], lo: float, hi: float) -> list[float]:
    return lowpass(highpass(sig, lo), hi, 2)


def normalize(sig: list[float], peak: float = PEAK) -> list[float]:
    m = max(1e-9, max(abs(x) for x in sig))
    return [x * peak / m for x in sig]


def loop_seam(sig: list[float], fade: float) -> list[float]:
    """sig uzunlugu N + F olmali; son F ornek basa esit guc ile carpazlanir, sonuc N orneklik kusursuz dongu."""
    f = n_of(fade)
    n = len(sig) - f
    out = sig[:n]
    for i in range(f):
        t = i / f
        out[i] = sig[i] * math.sin(t * math.pi / 2) + sig[n + i] * math.cos(t * math.pi / 2)
    return out


def fade_edges(sig: list[float], ms: float = 4.0) -> list[float]:
    """Tek seferlikler: basta ve sonda kisa dogrusal solma (tik olmasin)."""
    k = n_of(ms / 1000.0)
    out = list(sig)
    for i in range(min(k, len(out))):
        g = i / k
        out[i] *= g
        out[-1 - i] *= g
    return out


def write_wav(name: str, sig: list[float]) -> float:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    data = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, x)) * 32767)) for x in sig)
    with wave.open(str(OUT_DIR / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    return len(sig) / SR


# --- Donguler ---------------------------------------------------------------------------------

def neon_buzz(rng: random.Random, broken: bool) -> list[float]:
    """Sebeke uguldamasi: ~120 Hz + armonikler (tam sayi dongu -> dikissiz) + hafif cizirti."""
    secs = 4.0 if not broken else 6.0
    n = n_of(secs)
    hum = [0.0] * n
    for k, g in ((1, 1.0), (2, 0.45), (3, 0.3), (5, 0.15), (8, 0.08)):
        f = 120.0 * k  # secs tam sayi -> f*secs tam sayi dongu
        for i in range(n):
            hum[i] += g * math.sin(TAU * f * i / SR + k)
    seam = 0.25
    buzz = bandpass(noise(n + n_of(seam), rng), 1500.0, 4500.0)
    buzz = loop_seam(buzz, seam)  # gurultu periyodik degil: dikisi carpazla
    sig = [h * 0.6 + b * 0.5 * (0.6 + 0.4 * math.sin(TAU * 120.0 * i / SR)) for i, (h, b) in enumerate(zip(hum, buzz))]
    sig = normalize(sig, 0.7)
    if broken:
        # rastgele kopma bosluklari: bosluklarda ses kesilir, kenarlarinda sert cizirti patlar
        gate = [1.0] * n
        t = 0.0
        pops = noise(n, rng)
        pops = highpass(pops, 2500.0)
        crack = [0.0] * n
        while True:
            t += rng.uniform(0.7, 1.6)
            if t > secs - 0.4:
                break
            length = rng.uniform(0.06, 0.28)
            a, b = n_of(t), min(n, n_of(t + length))
            for i in range(a, b):
                gate[i] = 0.12 if rng.random() < 0.5 else 0.5
                crack[i] = pops[i] * rng.uniform(0.6, 1.4)
        gate = lowpass(gate, 400.0, 1)
        sig = [s * g + c * 0.6 for s, g, c in zip(sig, gate, crack)]
        return normalize(sig, PEAK)  # tam sayi dongu + bosluklar son 0.4 sn icinde yok -> dikis temiz
    return normalize(sig, PEAK)


def wire_hum(rng: random.Random) -> list[float]:
    n = n_of(5.0)
    sig = [math.sin(TAU * 50.0 * i / SR) + 0.6 * math.sin(TAU * 100.0 * i / SR + 1.0) + 0.15 * math.sin(TAU * 150.0 * i / SR) for i in range(n)]
    seam = 0.25
    air = loop_seam(lowpass(noise(n + n_of(seam), rng), 600.0, 1), seam)
    sig = [s * 0.5 + a * 0.25 for s, a in zip(sig, air)]
    return normalize(sig, 0.6)


def wind(rng: random.Random) -> list[float]:
    secs, fade = 12.0, 1.5
    n = n_of(secs + fade)
    base = lowpass(noise(n, rng), 500.0, 3)
    # yavas esintiler: iki ayri yavas sinus
    gust = [0.55 + 0.3 * math.sin(TAU * i / SR / 7.0 + 1.0) + 0.15 * math.sin(TAU * i / SR / 3.1) for i in range(n)]
    whistle = bandpass(noise(n, rng), 700.0, 1100.0)
    sig = [b * g + w * 0.12 * g * g for b, w, g in zip(base, whistle, gust)]
    return normalize(loop_seam(sig, fade), 0.8)


def main() -> int:
    items = [
        ("neon_buzz", neon_buzz(random.Random(101), False)),
        ("neon_broken", neon_buzz(random.Random(102), True)),
        ("wire_hum", wire_hum(random.Random(103))),
        ("wind", wind(random.Random(104))),
    ]
    for name, sig in items:
        print(f"{name}.wav  {write_wav(name, sig):.2f} s  first={int(sig[0]*32767)} last={int(sig[-1]*32767)} slope_first={int((sig[1]-sig[0])*32767)} slope_last={int((sig[-1]-sig[-2])*32767)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
