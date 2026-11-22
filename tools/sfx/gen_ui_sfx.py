"""Arayüz/akış sesleri: koyu, kapalı, boğuk. Yalnız stdlib. Çalıştır: python tools/sfx/gen_ui_sfx.py"""
from __future__ import annotations
import math, random, struct, wave
from pathlib import Path

SR = 44100
OUT = Path(__file__).resolve().parents[2] / "assets" / "audio" / "sfx"
PEAK = 10 ** (-3 / 20)


def n_of(s): return int(s * SR)


def noise(n, rng): return [rng.uniform(-1, 1) for _ in range(n)]


def biquad(sig, kind, f, q=0.707):
    w = 2 * math.pi * f / SR
    al = math.sin(w) / (2 * q); c = math.cos(w)
    if kind == "lp": b = [(1 - c) / 2, 1 - c, (1 - c) / 2]
    elif kind == "hp": b = [(1 + c) / 2, -(1 + c), (1 + c) / 2]
    else: b = [al, 0, -al]  # bp
    a0 = 1 + al; a1 = -2 * c; a2 = 1 - al
    x1 = x2 = y1 = y2 = 0.0; out = []
    for x in sig:
        y = (b[0] * x + b[1] * x1 + b[2] * x2 - a1 * y1 - a2 * y2) / a0
        x2, x1, y2, y1 = x1, x, y1, y; out.append(y)
    return out


def lp(sig, f, order=2):
    for _ in range(order): sig = biquad(sig, "lp", f)
    return sig


def env_exp(n, tau, att=0.002):
    a = max(1, n_of(att))
    return [min(1.0, i / a) * math.exp(-i / SR / tau) for i in range(n)]


def env_swell(n, peak, power=1.6):
    p = max(1, int(n * peak)); o = []
    for i in range(n):
        o.append((i / p) ** power if i < p else (max(0.0, 1 - (i - p) / max(1, n - p))) ** power)
    return o


def mul(a, b): return [x * y for x, y in zip(a, b)]


def sweep(n, f0, f1, curve=4.0):
    ph = 0.0; o = []
    for i in range(n):
        t = i / max(1, n - 1)
        f = f1 + (f0 - f1) * math.exp(-t * curve)
        ph += 2 * math.pi * f / SR; o.append(math.sin(ph))
    return o


def tone(n, freqs, gains=None):
    gains = gains or [1.0] * len(freqs); o = [0.0] * n
    for f, g in zip(freqs, gains):
        w = 2 * math.pi * f / SR
        for i in range(n): o[i] += g * math.sin(w * i)
    return o


def put(dst, src, start=0.0, gain=1.0):
    s = n_of(start)
    if s + len(src) > len(dst): dst.extend([0.0] * (s + len(src) - len(dst)))
    for i, v in enumerate(src): dst[s + i] += v * gain


def thump(dur, f0, f1, tau, rng, grit=0.25, grit_lp=700, curve=6.0):
    n = n_of(dur)
    body = mul(sweep(n, f0, f1, curve), env_exp(n, tau))
    g = mul(lp(noise(n, rng), grit_lp), env_exp(n, tau * 0.5))
    return [b + grit * x for b, x in zip(body, g)]


def finish(name, sig, lpf=2500, total=None):
    if total: sig = (sig + [0.0] * n_of(total))[:n_of(total)]
    sig = lp(sig, lpf)
    sig = biquad(sig, "hp", 25)
    m = sum(sig) / len(sig); sig = [x - m for x in sig]
    f = n_of(0.004); n = len(sig)
    for i in range(min(f, n)):
        sig[i] *= i / f; sig[n - 1 - i] *= i / f
    pk = max(abs(x) for x in sig) or 1.0
    k = PEAK / pk
    data = b"".join(struct.pack("<h", max(-32768, min(32767, int(round(x * k * 32767))))) for x in sig)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data)


def R(seed): return random.Random(seed)


def click(seed, f):
    r = R(seed); s = thump(0.06, f * 1.3, f, 0.012, r, 0.5, 900)
    return s


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    finish("ui_click_1", click(101, 520), 1800)
    finish("ui_click_2", click(102, 640), 1800)
    r = R(110); n = n_of(0.025)
    finish("ui_hover_1", mul(lp(noise(n, r), 900), env_exp(n, 0.006, 0.001)), 1500)
    for i, (sd, f) in enumerate([(121, 110), (122, 95)], 1):
        r = R(sd); s = thump(0.2, f * 1.6, f, 0.05, r, 0.6, 500, 5)
        tok = thump(0.08, 230, 180, 0.02, r, 0.1, 600)
        put(s, tok, 0.045, 0.55)
        finish(f"ui_buy_{i}", s, 1600, 0.2)
    r = R(130); s = thump(0.15, 150, 70, 0.04, r, 0.4, 500, 3)
    finish("ui_sell_1", s, 1500, 0.15)
    r = R(140); n = n_of(0.25)
    sw = mul(lp(tone(n, [70, 105, 140], [1, .7, .4]), 400), env_swell(n, 0.9, 2))
    s = sw[:]; put(s, thump(0.2, 110, 50, 0.07, r, 0.5, 500, 5), 0.25, 1.6)
    finish("ui_merge_1", s, 1500, 0.45)
    r = R(150); s = thump(0.09, 140, 105, 0.03, r, 0.3, 400, 3)
    put(s, thump(0.09, 130, 95, 0.03, r, 0.3, 400, 3), 0.08, 0.85)
    finish("ui_deny_1", s, 900, 0.18)
    r = R(160); n = n_of(0.35)
    ns = biquad(biquad(noise(n, r), "hp", 200), "lp", 1200)
    ns = biquad(ns, "lp", 1200)
    finish("ui_card_open_1", mul(ns, env_swell(n, 0.4, 1.4)), 1300)
    r = R(170); s = thump(0.15, 170, 90, 0.04, r, 0.4, 500, 5)
    put(s, mul(lp(tone(n_of(0.2), [220, 221.5], [1, .5]), 1200), env_exp(n_of(0.2), 0.07, 0.01)), 0.04, 0.6)
    finish("ui_card_pick_1", s, 1200, 0.25)
    n = n_of(0.8)
    t = tone(n, [110, 165, 220], [1, .8, .25])
    finish("ui_level_up_1", mul(t, env_swell(n, 0.35, 1.6)), 1500)
    r = R(180); n = n_of(1.2)
    s = thump(0.5, 95, 40, 0.14, r, 0.55, 450, 5)
    dr = mul(lp(tone(n, [70, 70.7, 140], [1, .8, .2]), 1000), env_swell(n, 0.25, 1.5))
    put(s, dr[:n_of(1.0)], 0.1, 0.6)
    finish("ui_wave_start_1", s, 1000, 1.2)
    n = n_of(1.0)
    sw = [0.0] * n; ph1 = ph2 = 0.0
    for i in range(n):
        t = i / n; f = 200 - 90 * t
        ph1 += 2 * math.pi * f / SR; ph2 += 2 * math.pi * f * 1.5 / SR
        sw[i] = math.sin(ph1) + 0.5 * math.sin(ph2)
    finish("ui_wave_end_1", mul(sw, env_swell(n, 0.3, 1.6)), 900)
    r = R(190); n = n_of(1.6)
    s = thump(0.5, 100, 38, 0.12, r, 0.7, 400, 5)
    put(s, thump(0.3, 70, 40, 0.1, r, 0.5, 300, 4), 0.14, 0.5)
    dr = mul(lp(tone(n, [48, 72], [1, .4]), 300), env_swell(n, 0.1, 1.2))
    put(s, dr, 0.0, 0.5)
    finish("ui_player_death_1", s, 800, 1.6)
    n = n_of(2.2)
    t = tone(n, [55, 56.4, 82.5, 110.3], [1, 1, .35, .15])
    finish("ui_game_over_1", mul(lp(t, 700), env_swell(n, 0.15, 1.5)), 800)
    n = n_of(2.5)
    t = tone(n, [110, 164.8, 220, 220.8, 329.6], [1, .8, .7, .5, .12])
    finish("ui_victory_1", mul(t, env_swell(n, 0.4, 1.8)), 1800)
    r = R(200)
    s = thump(0.2, 80, 52, 0.07, r, 0.2, 200, 4)
    put(s, thump(0.2, 70, 45, 0.07, r, 0.2, 200, 4), 0.25, 0.7)
    s = (s + [0.0] * n_of(0.8))[:n_of(0.8)]
    finish("ui_low_health_1", s, 400, 0.8)


if __name__ == "__main__":
    build()
