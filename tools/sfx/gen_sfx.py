"""Deadzone Last Stand ses efektleri: koddan sentez, dış dosya yok.

Çalıştırma (proje kökünden):  python tools/sfx/gen_sfx.py
Çıktı: assets/audio/sfx/<ad>_<n>.wav (44.1 kHz, 16 bit, mono). Sabit tohumlu: her çalıştırma aynı dosyaları üretir.
Ardından: godot --headless --path . --import
Ses adları ve çeşit sayıları scripts/data/sound_data.gd ile eşleşmeli.
"""

from __future__ import annotations

import math
import random
import struct
import sys
import wave
from pathlib import Path

SR = 44100
PEAK = 0.89  # ~ -1 dBFS
OUT_DIR = Path(__file__).resolve().parents[2] / "assets" / "audio" / "sfx"


# --- Temel parçalar ---------------------------------------------------------------------------

def frames(seconds: float) -> int:
    return int(seconds * SR)


def silence(seconds: float) -> list[float]:
    return [0.0] * frames(seconds)


def noise(n: int, rng: random.Random) -> list[float]:
    return [rng.uniform(-1.0, 1.0) for _ in range(n)]


def mix_into(dst: list[float], src: list[float], gain: float = 1.0, start: float = 0.0) -> None:
    offset = frames(start)
    for i, v in enumerate(src):
        j = i + offset
        if j >= len(dst):
            break
        dst[j] += v * gain


def env_exp(n: int, tau: float, attack: float = 0.0005) -> list[float]:
    """Kısa yükseliş + üstel sönme."""
    a = max(1, frames(attack))
    out = []
    for i in range(n):
        t = i / SR
        rise = min(1.0, i / a)
        out.append(rise * math.exp(-t / tau))
    return out


def env_swell(n: int, peak_at: float, power: float = 1.5) -> list[float]:
    """0'dan yükselip peak_at oranında tepe yapan, sonra sönen zarf (hışırtı için)."""
    out = []
    for i in range(n):
        x = i / max(1, n - 1)
        if x < peak_at:
            v = (x / peak_at) ** power
        else:
            v = ((1.0 - x) / (1.0 - peak_at)) ** power
        out.append(v)
    return out


def apply(sig: list[float], env: list[float]) -> list[float]:
    return [s * e for s, e in zip(sig, env)]


class Biquad:
    """RBJ biquad süzgeci; kesim frekansı her örnekte değişebilir."""

    def __init__(self, kind: str) -> None:
        self.kind = kind
        self.x1 = self.x2 = self.y1 = self.y2 = 0.0
        self.b0 = self.b1 = self.b2 = self.a1 = self.a2 = 0.0

    def set(self, freq: float, q: float) -> None:
        freq = min(max(freq, 20.0), SR * 0.45)
        w = 2.0 * math.pi * freq / SR
        cw, sw = math.cos(w), math.sin(w)
        alpha = sw / (2.0 * q)
        if self.kind == "lp":
            b0, b1, b2 = (1 - cw) / 2, 1 - cw, (1 - cw) / 2
        elif self.kind == "hp":
            b0, b1, b2 = (1 + cw) / 2, -(1 + cw), (1 + cw) / 2
        else:  # "bp": tepe kazancı 1
            b0, b1, b2 = alpha, 0.0, -alpha
        a0 = 1 + alpha
        self.b0, self.b1, self.b2 = b0 / a0, b1 / a0, b2 / a0
        self.a1, self.a2 = -2 * cw / a0, (1 - alpha) / a0

    def tick(self, x: float) -> float:
        y = self.b0 * x + self.b1 * self.x1 + self.b2 * self.x2 - self.a1 * self.y1 - self.a2 * self.y2
        self.x2, self.x1 = self.x1, x
        self.y2, self.y1 = self.y1, y
        return y


def filt(sig: list[float], kind: str, freq, q: float = 0.707) -> list[float]:
    """freq sabit sayı ya da t (sn) -> Hz fonksiyonu olabilir."""
    f = Biquad(kind)
    sweeping = callable(freq)
    if not sweeping:
        f.set(freq, q)
    out = []
    for i, x in enumerate(sig):
        if sweeping and i % 32 == 0:
            f.set(freq(i / SR), q)
        out.append(f.tick(x))
    return out


def sine_sweep(n: int, freq) -> list[float]:
    phase = 0.0
    out = []
    for i in range(n):
        phase += 2.0 * math.pi * freq(i / SR) / SR
        out.append(math.sin(phase))
    return out


def saw(n: int, freq) -> list[float]:
    phase = 0.0
    out = []
    for i in range(n):
        phase = (phase + freq(i / SR) / SR) % 1.0
        out.append(2.0 * phase - 1.0)
    return out


def partials(n: int, specs: list[tuple[float, float, float]]) -> list[float]:
    """Metal tınısı: (frekans, sönme tau, genlik) kısmi sesleri."""
    out = [0.0] * n
    for freq, tau, amp in specs:
        for i in range(n):
            t = i / SR
            out[i] += amp * math.sin(2.0 * math.pi * freq * t) * math.exp(-t / tau)
    return out


def formants(sig: list[float], specs: list[tuple[float, float, float]]) -> list[float]:
    """Ses yolu taklidi: (frekans, Q, kazanç) bant geçiren süzgeçlerin toplamı."""
    out = [0.0] * len(sig)
    for freq, q, gain in specs:
        band = filt(sig, "bp", freq, q)
        for i, v in enumerate(band):
            out[i] += v * gain
    return out


def soft_clip(sig: list[float], drive: float) -> list[float]:
    norm = math.tanh(drive)
    return [math.tanh(v * drive) / norm for v in sig]


def fade_out(sig: list[float], seconds: float) -> list[float]:
    n = min(len(sig), frames(seconds))
    out = list(sig)
    for i in range(n):
        out[len(out) - n + i] *= 1.0 - i / n
    return out


def normalize(sig: list[float]) -> list[float]:
    peak = max(abs(v) for v in sig) or 1.0
    return [v * PEAK / peak for v in sig]


def write_wav(name: str, sig: list[float]) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / f"{name}.wav"
    data = normalize(fade_out(sig, 0.01))
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in data))
    print(f"  {path.relative_to(OUT_DIR.parents[2])}  {len(sig) / SR:.2f} sn")


# --- Sesler -----------------------------------------------------------------------------------

def shot(rng: random.Random) -> list[float]:
    """Tabanca: keskin çatlama + gövde + alçak darbe + kısa oda kuyruğu."""
    total = 0.32
    n = frames(total)
    out = [0.0] * n
    crack = filt(noise(frames(0.06), rng), "hp", 1800.0)
    mix_into(out, apply(crack, env_exp(len(crack), 0.010)), 1.0)
    body = filt(noise(frames(0.15), rng), "lp", lambda t: 400.0 + 3200.0 * math.exp(-t / 0.02))
    mix_into(out, apply(body, env_exp(len(body), 0.040)), 1.1)
    thump = sine_sweep(frames(0.15), lambda t: 55.0 + 140.0 * math.exp(-t / 0.025))
    mix_into(out, apply(thump, env_exp(len(thump), 0.045, 0.001)), 0.9)
    tail = filt(noise(n, rng), "bp", 900.0, 0.8)
    mix_into(out, apply(tail, env_exp(n, 0.09, 0.008)), 0.18)
    return soft_clip(out, 1.6)


def pump_clack(rng: random.Random, low: float, high: float) -> list[float]:
    """Pompa sürgüsü: kısa tahta/metal vuruş + metal kısmi sesler."""
    n = frames(0.07)
    knock = filt(noise(n, rng), "bp", rng.uniform(low, high), 2.5)
    knock = apply(knock, env_exp(n, 0.012, 0.0005))
    ring = partials(n, [(rng.uniform(1800.0, 2300.0), 0.02, 1.0), (rng.uniform(3600.0, 4300.0), 0.01, 0.5)])
    return [k * 1.4 + r * 0.25 for k, r in zip(knock, ring)]


def shotgun(rng: random.Random) -> list[float]:
    """Pompalı: tabancadan tok ve geniş patlama, uzun kuyruk; ardından pompa çekme (geri-ileri)."""
    total = 0.85
    n = frames(total)
    out = [0.0] * n
    crack = filt(noise(frames(0.08), rng), "hp", 1200.0)
    mix_into(out, apply(crack, env_exp(len(crack), 0.014)), 0.9)
    body = filt(noise(frames(0.3), rng), "lp", lambda t: 250.0 + 2600.0 * math.exp(-t / 0.035), 1.0)
    mix_into(out, apply(body, env_exp(len(body), 0.075)), 1.4)
    thump = sine_sweep(frames(0.3), lambda t: 42.0 + 120.0 * math.exp(-t / 0.035))
    mix_into(out, apply(thump, env_exp(len(thump), 0.085, 0.001)), 1.2)
    tail = filt(noise(frames(0.45), rng), "bp", 650.0, 0.7)
    mix_into(out, apply(tail, env_exp(len(tail), 0.14, 0.01)), 0.22)
    out = soft_clip(out, 2.0)
    # Pompa: geri (daha tok) ve ileri (daha keskin), patlama söndükten sonra.
    mix_into(out, pump_clack(rng, 500.0, 750.0), 0.22, 0.46)
    mix_into(out, pump_clack(rng, 900.0, 1300.0), 0.25, 0.6)
    return out


def hit(rng: random.Random) -> list[float]:
    """Mermi ete giriyor: kısa tık + ıslak boğuk darbe."""
    n = frames(0.16)
    out = [0.0] * n
    tick = filt(noise(frames(0.02), rng), "bp", rng.uniform(2200.0, 3000.0), 2.0)
    mix_into(out, apply(tick, env_exp(len(tick), 0.004)), 0.5)
    cut = rng.uniform(900.0, 1400.0)
    squish = filt(noise(n, rng), "lp", lambda t: 350.0 + cut * math.exp(-t / 0.03), 1.4)
    mix_into(out, apply(squish, env_exp(n, 0.035, 0.002)), 1.0)
    base = rng.uniform(55.0, 70.0)
    thud = sine_sweep(n, lambda t: base + 70.0 * math.exp(-t / 0.02))
    mix_into(out, apply(thud, env_exp(n, 0.03, 0.001)), 0.8)
    return soft_clip(out, 1.3)


def zombie_death(rng: random.Random, base: float) -> list[float]:
    """Zombi ölümü: ıslak çarpma + düşen, hırıltılı inilti."""
    total = 0.8
    n = frames(total)
    out = [0.0] * n
    splat = filt(noise(frames(0.15), rng), "lp", lambda t: 500.0 + 1800.0 * math.exp(-t / 0.03), 1.2)
    mix_into(out, apply(splat, env_exp(len(splat), 0.05, 0.002)), 0.7)

    groan_len = total - 0.03
    m = frames(groan_len)
    # Perde aşağı düşer, rastgele titreşir (yürüyüş: yavaş rastgele sapma).
    wobble = [0.0] * m
    w = 0.0
    for i in range(m):
        if i % 200 == 0:
            w = max(-1.0, min(1.0, w + rng.uniform(-0.35, 0.35)))
        wobble[i] = w
    pitch = lambda t: base * (1.0 - 0.38 * (t / groan_len)) * (1.0 + 0.04 * wobble[min(m - 1, int(t * SR))])
    voice = saw(m, pitch)
    sub = saw(m, lambda t: pitch(t) * 0.5)
    voice = [v + 0.5 * s for v, s in zip(voice, sub)]
    # Hırıltı: genliği alçak geçirilmiş gürültüyle oynat.
    grit = filt(noise(m, rng), "lp", 60.0)
    grit_peak = max(abs(g) for g in grit) or 1.0
    voice = [v * (0.6 + 0.4 * g / grit_peak) for v, g in zip(voice, grit)]
    voice = formants(voice, [(rng.uniform(420.0, 520.0), 5.0, 1.0), (rng.uniform(950.0, 1150.0), 6.0, 0.55), (2400.0, 7.0, 0.2)])
    env = env_swell(m, 0.18, 0.8)
    mix_into(out, apply(voice, env), 1.0, 0.03)
    return soft_clip(out, 1.8)


def footstep(rng: random.Random) -> list[float]:
    """Zırhlı bot sert zeminde: boğuk darbe, kum, belli belirsiz metal şıngırtı."""
    n = frames(0.13)
    out = [0.0] * n
    thump = filt(noise(n, rng), "lp", rng.uniform(450.0, 700.0), 1.1)
    mix_into(out, apply(thump, env_exp(n, 0.018, 0.001)), 1.0)
    low = sine_sweep(n, lambda t: 55.0 + 40.0 * math.exp(-t / 0.015))
    mix_into(out, apply(low, env_exp(n, 0.022, 0.001)), 0.6)
    grit = filt(noise(frames(0.03), rng), "bp", rng.uniform(3000.0, 4200.0), 1.0)
    mix_into(out, apply(grit, env_exp(len(grit), 0.007)), 0.18)
    clink = partials(frames(0.08), [(rng.uniform(2200.0, 2500.0), 0.025, 1.0), (rng.uniform(3500.0, 3900.0), 0.018, 0.6)])
    mix_into(out, clink, 0.05, 0.006)
    return out


def gear_clink(rng: random.Random) -> list[float]:
    """Çantadaki tek bir metal parça: 2-3 uyumsuz kısmi ses, kısa sönme."""
    base = rng.uniform(1500.0, 3200.0)
    specs = [(base, rng.uniform(0.02, 0.045), 1.0),
             (base * rng.uniform(2.3, 2.9), rng.uniform(0.01, 0.025), 0.55),
             (base * rng.uniform(3.9, 4.6), 0.008, 0.3)]
    return partials(frames(0.09), specs)


def gear_clunk(rng: random.Random) -> list[float]:
    """Zırh plakasının boğuk tok vuruşu."""
    n = frames(0.08)
    knock = filt(noise(n, rng), "bp", rng.uniform(550.0, 850.0), 3.0)
    ring = partials(n, [(rng.uniform(700.0, 950.0), 0.03, 1.0)])
    return [(k * 1.5 + r * 0.4) * math.exp(-(i / SR) / 0.025) for i, (k, r) in enumerate(zip(knock, ring))]


def dash(rng: random.Random) -> list[float]:
    """Dash (takla): yumuşak hava hışırtısı + zırh ve alet çantası tıngırtısı.
    Tıngırtı taklanın üç anında yoğunlaşır: yere iniş, yuvarlanma, kalkış."""
    total = 0.5
    n = frames(total)
    out = [0.0] * n
    sweep = lambda t: 300.0 + 1400.0 * math.sin(math.pi * min(1.0, t / total)) ** 1.6
    air = filt(noise(n, rng), "bp", sweep, 1.0)
    mix_into(out, apply(air, env_swell(n, 0.3, 1.6)), 0.35)
    body = filt(noise(n, rng), "lp", 400.0)
    mix_into(out, apply(body, env_swell(n, 0.25, 2.0)), 0.25)
    for center, count, spread in ((0.06, 3, 0.03), (0.2, 4, 0.06), (0.36, 4, 0.04)):
        mix_into(out, gear_clunk(rng), 0.5, max(0.0, center - 0.01))
        for _ in range(count):
            at = max(0.0, center + rng.uniform(-spread, spread))
            mix_into(out, gear_clink(rng), rng.uniform(0.12, 0.28), at)
    return soft_clip(out, 1.2)


def metal_hit(rng: random.Random, base: float, tau: float, ratios=(1.0, 2.76, 5.4, 8.9)) -> list[float]:
    """Zırh/tokalı metal vuruşu: sönümlü uyumsuz kısmi sesler."""
    amps = (1.0, 0.6, 0.35, 0.2)
    specs = [(base * r * rng.uniform(0.98, 1.02), tau / (1.0 + 0.5 * k), a)
             for k, (r, a) in enumerate(zip(ratios, amps)) if base * r < SR * 0.42]
    return partials(frames(tau * 4.0), specs)


def thud(rng: random.Random, f_hi: float, f_lo: float, tau: float, grit_hz: float, grit_gain: float) -> list[float]:
    """Gövde/bot darbesi: hızlı perde düşüşlü alçak tok ses + kısa kumlu gürültü patlaması."""
    n = frames(tau * 4.0)
    low = sine_sweep(n, lambda t: f_lo + (f_hi - f_lo) * math.exp(-t / 0.025))
    out = apply(low, env_exp(n, tau, 0.002))
    grit = filt(noise(n, rng), "lp", grit_hz, 0.9)
    mix_into(out, apply(grit, env_exp(n, tau * 0.4, 0.001)), grit_gain)
    return out


def dash_armored(rng: random.Random) -> list[float]:
    """Zırhlı askerin takla atması: kumaş hışırtısı, omuz darbesi, asfaltta sürtünme,
    zırh/tokalı şıngırtısı ve diz-bot inişi. Havalı hışırtı yok denecek kadar az."""
    total = rng.uniform(0.52, 0.58)
    n = frames(total)
    out = [0.0] * n
    ti = total * rng.uniform(0.27, 0.33)  # omuz yere çarpar
    tl = total - rng.uniform(0.11, 0.14)  # diz/bot inişi
    # 1) kalkışta kumaş/ekipman hışırtısı
    rn = frames(0.085)
    rustle = filt(noise(rn, rng), "bp", rng.uniform(1600.0, 2400.0), 0.8)
    mix_into(out, apply(rustle, env_swell(rn, 0.2, 1.3)), 0.35)
    # çok hafif hava
    air = filt(noise(n, rng), "bp", 1000.0, 0.8)
    mix_into(out, apply(air, env_swell(n, 0.3, 1.8)), 0.05)
    # 2) omuz darbesi
    mix_into(out, thud(rng, rng.uniform(115.0, 125.0), rng.uniform(58.0, 66.0), 0.07, 1500.0, 0.55), 1.0, ti)
    mix_into(out, gear_clunk(rng), 0.45, ti + 0.004)
    # 3) asfaltta sürtünme: yavaş genlik modülasyonlu kumlu gürültü
    sn = frames(max(0.05, tl - ti - 0.01))
    scr_t0 = ti + 0.03
    sn = max(0, min(sn, n - frames(scr_t0)))
    sweep = lambda t: 500.0 + 1200.0 * math.sin(math.pi * min(1.0, t / max(0.01, sn / SR))) ** 1.2
    scrape = filt(noise(sn, rng), "bp", sweep, 0.9)
    am_raw = filt(noise(sn, rng), "lp", 45.0, 0.7)
    am_peak = max(abs(v) for v in am_raw) or 1.0
    am = [0.45 + 0.55 * abs(v) / am_peak for v in am_raw]
    scrape = apply(apply(scrape, am), env_swell(sn, 0.25, 1.4))
    mix_into(out, scrape, 0.55, scr_t0)
    # 4) zırh/tokalı şıngırtısı: darbe çevresinde ve sonda 5 vuruş
    for k in range(5):
        around_end = k >= 3
        at = (tl + rng.uniform(-0.03, 0.05)) if around_end else (ti + rng.uniform(0.01, 0.11))
        mix_into(out, metal_hit(rng, rng.uniform(1100.0, 3600.0), rng.uniform(0.02, 0.07)),
                 rng.uniform(0.07, 0.17), min(max(0.0, at), total - 0.1))
    # 5) toparlanma: ikinci küçük darbe + son kısa şıngırtı
    mix_into(out, thud(rng, rng.uniform(95.0, 105.0), rng.uniform(52.0, 58.0), 0.05, 900.0, 0.35), 0.5, tl)
    mix_into(out, metal_hit(rng, rng.uniform(1800.0, 3000.0), 0.03), 0.1, min(tl + 0.03, total - 0.1))
    # DC'yi at, hafif sınırla, kısa giriş
    mean = sum(out) / n
    out = [v - mean for v in out]
    for i in range(frames(0.003)):
        out[i] *= i / frames(0.003)
    return soft_clip(out, 1.1)


def swing(rng: random.Random, total: float, low: float, high: float, hum: float = 0.0, crackle: float = 0.0, ring: float = 0.0) -> list[float]:
    """Yakın dövüş savurması: hava hışırtısı (süpürülen bant). hum: enerji uğultusu (Hz, 0 yok),
    crackle: ateş çıtırtısı payı, ring: metal tınısı payı (kılıç)."""
    n = frames(total)
    out = [0.0] * n
    sweep = lambda t: low + (high - low) * math.sin(math.pi * min(1.0, t / total)) ** 1.4
    air = filt(noise(n, rng), "bp", sweep, 1.2)
    mix_into(out, apply(air, env_swell(n, 0.4, 1.4)), 0.7)
    if hum > 0.0:
        tone = sine_sweep(n, lambda t: hum * (1.0 + 0.5 * math.sin(math.pi * min(1.0, t / total))))
        mix_into(out, apply(tone, env_swell(n, 0.4, 1.2)), 0.35)
        buzz = saw(n, lambda t: hum * 0.5 * (1.0 + 0.5 * math.sin(math.pi * min(1.0, t / total))))
        mix_into(out, apply(filt(buzz, "lp", 900.0), env_swell(n, 0.4, 1.2)), 0.2)
    if crackle > 0.0:
        for _ in range(int(total * 90)):
            at = rng.uniform(0.0, total * 0.9)
            pop = apply(filt(noise(frames(0.012), rng), "hp", 1800.0), env_exp(frames(0.012), 0.003))
            mix_into(out, pop, crackle * rng.uniform(0.3, 1.0), at)
        low_roar = filt(noise(n, rng), "lp", 500.0)
        mix_into(out, apply(low_roar, env_swell(n, 0.35, 1.5)), 0.4)
    if ring > 0.0:
        tink = partials(frames(0.18), [(rng.uniform(2300.0, 2700.0), 0.05, 0.5), (rng.uniform(4100.0, 4600.0), 0.03, 0.3)])
        mix_into(out, tink, ring, total * 0.45)
    return soft_clip(out, 1.1)


def plasma(rng: random.Random) -> list[float]:
    """Plazma atışı: yüksekten alçağa süpürülen enerji cızırtısı + kısa parlak 'zap'."""
    total = 0.22
    n = frames(total)
    out = [0.0] * n
    tone = sine_sweep(n, lambda t: 1800.0 * math.exp(-t / 0.07) + 380.0)
    mix_into(out, apply(tone, env_exp(n, 0.07)), 0.6)
    buzz = saw(n, lambda t: 240.0 * math.exp(-t / 0.1) + 120.0)
    mix_into(out, apply(filt(buzz, "lp", 1400.0), env_exp(n, 0.09)), 0.3)
    mix_into(out, apply(filt(noise(n, rng), "hp", 2500.0), env_exp(n, 0.02)), 0.25)
    return soft_clip(out, 1.3)


def graviton(rng: random.Random) -> list[float]:
    """Graviton itmesi: alçak, yükselen 'vuuum' darbesi ve hava yığılması."""
    total = 0.45
    n = frames(total)
    out = [0.0] * n
    thump = sine_sweep(n, lambda t: 40.0 + 90.0 * math.exp(-t / 0.12))
    mix_into(out, apply(thump, env_exp(n, 0.16)), 0.9)
    air = filt(noise(n, rng), "bp", lambda t: 300.0 + 1800.0 * min(1.0, t / total), 0.9)
    mix_into(out, apply(air, env_swell(n, 0.25, 1.5)), 0.35)
    hum = sine_sweep(n, lambda t: 220.0 - 90.0 * min(1.0, t / total))
    mix_into(out, apply(hum, env_swell(n, 0.2, 1.4)), 0.25)
    return soft_clip(out, 1.2)


def launcher(rng: random.Random) -> list[float]:
    """Bomba atar: tok 'tonk' (tüpten çıkış) + kısa hava hışırtısı."""
    total = 0.3
    n = frames(total)
    out = [0.0] * n
    thump = sine_sweep(n, lambda t: 70.0 + 110.0 * math.exp(-t / 0.03))
    mix_into(out, apply(thump, env_exp(n, 0.07)), 1.0)
    pop = filt(noise(n, rng), "lp", 900.0)
    mix_into(out, apply(pop, env_exp(n, 0.03)), 0.7)
    air = filt(noise(n, rng), "bp", 1400.0, 1.0)
    mix_into(out, apply(air, env_swell(n, 0.3, 1.5)), 0.2)
    return soft_clip(out, 1.4)


def explosion(rng: random.Random) -> list[float]:
    """Patlama: alçak gümbürtü + gürültü patlaması, uzun sönme."""
    total = 0.8
    n = frames(total)
    out = [0.0] * n
    boom = sine_sweep(n, lambda t: 38.0 + 70.0 * math.exp(-t / 0.15))
    mix_into(out, apply(boom, env_exp(n, 0.25)), 1.0)
    burst = filt(noise(n, rng), "lp", lambda t: 3500.0 * math.exp(-t / 0.18) + 200.0)
    mix_into(out, apply(burst, env_exp(n, 0.22, 0.002)), 0.9)
    crack = filt(noise(n, rng), "hp", 1500.0)
    mix_into(out, apply(crack, env_exp(n, 0.02, 0.0005)), 0.4)
    return soft_clip(out, 1.5)


def horde_groan(rng: random.Random, base: float, length: float) -> list[float]:
    """Sürü homurtusu: yavaş yükselip inen, boğuk (uzaktan gelen) inilti."""
    n = frames(length)
    wobble = [0.0] * n
    w = 0.0
    for i in range(n):
        if i % 300 == 0:
            w = max(-1.0, min(1.0, w + rng.uniform(-0.3, 0.3)))
        wobble[i] = w
    rise = rng.uniform(0.08, 0.2)
    contour = lambda t: 1.0 + rise * math.sin(math.pi * t / length) - 0.15 * (t / length)
    pitch = lambda t: base * contour(t) * (1.0 + 0.05 * wobble[min(n - 1, int(t * SR))])
    voice = saw(n, pitch)
    sub = saw(n, lambda t: pitch(t) * 0.5)
    voice = [v + 0.6 * s for v, s in zip(voice, sub)]
    grit = filt(noise(n, rng), "lp", 45.0)
    grit_peak = max(abs(g) for g in grit) or 1.0
    voice = [v * (0.55 + 0.45 * g / grit_peak) for v, g in zip(voice, grit)]
    vowel = rng.uniform(0.85, 1.15)
    voice = formants(voice, [(420.0 * vowel, 4.5, 1.0), (850.0 * vowel, 5.0, 0.45), (2200.0, 6.0, 0.12)])
    voice = filt(voice, "lp", 1800.0)  # uzaklık: tizler yumuşak
    breath = filt(noise(n, rng), "bp", 1200.0, 0.8)
    voice = [v + 0.04 * b for v, b in zip(voice, breath)]
    return soft_clip(apply(voice, env_swell(n, rng.uniform(0.3, 0.5), 1.3)), 1.4)


def player_hurt(rng: random.Random) -> list[float]:
    """Asker vuruldu: zırha çarpan metal + boğuk darbe + kısa homurtu."""
    n = frames(0.42)
    out = [0.0] * n
    clank = partials(n, [(620.0, 0.16, 1.0), (1470.0, 0.11, 0.6), (2380.0, 0.07, 0.4), (3310.0, 0.045, 0.25)])
    mix_into(out, clank, 0.35)
    thud = sine_sweep(n, lambda t: 60.0 + 70.0 * math.exp(-t / 0.03))
    mix_into(out, apply(thud, env_exp(n, 0.05, 0.001)), 0.9)
    punch = filt(noise(n, rng), "lp", 900.0)
    mix_into(out, apply(punch, env_exp(n, 0.03, 0.001)), 0.7)
    g = frames(0.2)
    grunt = saw(g, lambda t: 150.0 - 40.0 * (t / 0.2))
    grunt = formants(grunt, [(600.0, 5.0, 1.0), (1150.0, 6.0, 0.5)])
    mix_into(out, apply(grunt, env_swell(g, 0.12, 0.7)), 0.5, 0.015)
    return soft_clip(out, 1.5)


def pickup(rng: random.Random, base: float) -> list[float]:
    """Kristal toplama: kısa, cam gibi tınlama; hafif yukarı kayan iki nota + parıltı."""
    n = frames(0.22)
    out = [0.0] * n
    glass = partials(n, [(base, 0.07, 1.0), (base * 2.76, 0.04, 0.45), (base * 5.4, 0.025, 0.2)])
    mix_into(out, glass, 0.5)
    m = frames(0.16)
    chirp = sine_sweep(m, lambda t: base * 1.5 * (1.0 + 0.25 * min(1.0, t / 0.05)))
    mix_into(out, apply(chirp, env_exp(m, 0.045, 0.002)), 0.35, 0.03)
    sparkle = filt(noise(n, rng), "hp", 6000.0)
    mix_into(out, apply(sparkle, env_exp(n, 0.02, 0.001)), 0.12)
    return fade_out(out, 0.04)


def main() -> int:
    print(f"Ses efektleri -> {OUT_DIR}")
    # Tohumlar sabit: aynı dosyalar. Çeşit eklemek için listeyi uzat, sound_data.gd'yi güncelle.
    write_wav("shot_1", shot(random.Random(101)))
    write_wav("shotgun_1", shotgun(random.Random(111)))
    for i, seed in enumerate((201, 202, 203), start=1):
        write_wav(f"hit_{i}", hit(random.Random(seed)))
    for i, (seed, base) in enumerate(((301, 92.0), (302, 78.0), (303, 108.0)), start=1):
        write_wav(f"zombie_death_{i}", zombie_death(random.Random(seed), base))
    for i, seed in enumerate((401, 402, 403, 404), start=1):
        write_wav(f"footstep_{i}", footstep(random.Random(seed)))
    for i, seed in enumerate((501, 502, 503), start=1):
        write_wav(f"dash_{i}", dash(random.Random(seed)))
    for i, seed in enumerate((511, 512, 513), start=1):
        write_wav(f"dash_armored_{i}", dash_armored(random.Random(seed)))
    groans = ((701, 88.0, 1.3), (702, 72.0, 1.6), (703, 104.0, 1.1), (704, 80.0, 1.8), (705, 96.0, 1.4))
    for i, (seed, base, length) in enumerate(groans, start=1):
        write_wav(f"horde_groan_{i}", horde_groan(random.Random(seed), base, length))
    for i, seed in enumerate((901, 902, 903), start=1):
        write_wav(f"swing_light_{i}", swing(random.Random(seed), 0.16, 1800.0, 4200.0))
    for i, seed in enumerate((911, 912, 913), start=1):
        write_wav(f"swing_medium_{i}", swing(random.Random(seed), 0.26, 900.0, 3000.0, ring=0.25))
    for i, seed in enumerate((921, 922, 923), start=1):
        write_wav(f"swing_energy_{i}", swing(random.Random(seed), 0.36, 600.0, 2200.0, hum=140.0))
    for i, seed in enumerate((931, 932, 933), start=1):
        write_wav(f"swing_fire_{i}", swing(random.Random(seed), 0.34, 500.0, 2000.0, crackle=0.5))
    for i, seed in enumerate((941, 942, 943), start=1):
        write_wav(f"plasma_{i}", plasma(random.Random(seed)))
    for i, seed in enumerate((951, 952), start=1):
        write_wav(f"graviton_{i}", graviton(random.Random(seed)))
    for i, seed in enumerate((961, 962), start=1):
        write_wav(f"launcher_{i}", launcher(random.Random(seed)))
    for i, seed in enumerate((971, 972, 973), start=1):
        write_wav(f"explosion_{i}", explosion(random.Random(seed)))
    write_wav("player_hurt_1", player_hurt(random.Random(601)))
    for i, (seed, base) in enumerate(((801, 1320.0), (802, 1480.0), (803, 1180.0)), start=1):
        write_wav(f"pickup_{i}", pickup(random.Random(seed), base))
    return 0


if __name__ == "__main__":
    sys.exit(main())
