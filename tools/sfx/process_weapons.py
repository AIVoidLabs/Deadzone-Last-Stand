"""Deadzone Last Stand silah sesleri v2 (1/2): kullanicinin indirdigi .22 kayitlarindan islenmis turevler.

Calistirma (proje kokunden):  python tools/sfx/process_weapons.py   (sonra gen_weapons_v2.py)
Girdi : assets/audio/source/weapons/ (git'e girmez): "22 Pistol.wav", "22 Magnum.wav" (96 kHz stereo, her dosyada birkac atis).
Cikti : assets/audio/sfx/w_pistol_1..3.wav, w_smg_1..3.wav (44.1 kHz, 16 bit, mono, tepe -3 dBFS)
        build/audio_tmp/w_shotgun_src.wav (ara urun: gen_weapons_v2.py sentezlenmis gumbur ile karistirir)
Koyu/kapali ses dili: alcak geciren ile cirtlak kesilir, kuyruk hizli solar. Ayni girdi ayni cikti verir.
"""

from __future__ import annotations

import re
import struct
import subprocess
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "assets" / "audio" / "source" / "weapons"
TMP = ROOT / "build" / "audio_tmp"
OUT = ROOT / "assets" / "audio" / "sfx"
PEAK_DB = -3.0
FADE_IN = 0.003
PRE_ROLL = 0.002  # ilk atis esiginden once birakilan sure
ONSET_FRAC = 0.15  # tepenin %15'i: atis baslangici
MIN_GAP = 0.25  # atislar arasi en az sessizlik sn

# ad: (kaynak, atis no, sure sn, kuyruk solma sn, perde yari-ton, high-pass Hz, lowpass Hz, ek filtre, sikistirici)
# Her varyant kayittaki FARKLI bir atistan alinir (atis no = onset() ile bulunan siralama); perde farki ustune kucuk ek.
Spec = tuple[str, int, float, float, float, float, float, str, str]
# Govde one cikarma (tepeyi kirpmadan): hizli atak + kisa salinimli compand; sessiz kuyruk/oda sesi ~20 dB yukselir.
# Ham kayitta tepe ile govde arasi ~30 dB; bu egri farki ~10 dB'ye indirir (ses ortalamasi sentez silahlarla yarisir).
COMP_PISTOL = "compand=attacks=0.0005:decays=0.015:points=-90/-90|-70/-26|-50/-14|-30/-9|-10/-7|0/-6"
COMP_SMG = "compand=attacks=0.0005:decays=0.012:points=-90/-90|-70/-28|-50/-15|-30/-10|-10/-7|0/-6"
SPECS: dict[str, Spec] = {
    "w_pistol_1": ("22 Pistol.wav", 0, 0.26, 0.10, -0.5, 50, 5500, "lowshelf=f=160:g=3", COMP_PISTOL),
    "w_pistol_2": ("22 Pistol.wav", 1, 0.26, 0.10, 0.0, 50, 5500, "lowshelf=f=160:g=3", COMP_PISTOL),
    "w_pistol_3": ("22 Pistol.wav", 3, 0.26, 0.10, 0.5, 50, 5500, "lowshelf=f=160:g=3", COMP_PISTOL),
    # smg: daha ince (high-pass 90), cok kisa ve daha kapali (4.5 kHz); seri atista camurlasmasin
    "w_smg_1": ("22 Magnum.wav", 0, 0.15, 0.08, -0.4, 90, 4500, "", COMP_SMG),
    "w_smg_2": ("22 Magnum.wav", 1, 0.15, 0.08, 0.0, 90, 4500, "", COMP_SMG),
    "w_smg_3": ("22 Magnum.wav", 2, 0.15, 0.08, 0.4, 90, 4500, "", COMP_SMG),
    # pompali ara urunu: 5 yari-ton asagi, daha kapali (sikistirma yok; gen_weapons_v2 karistirir)
    "w_shotgun_src": ("22 Magnum.wav", 0, 0.50, 0.25, -5.0, 40, 4000, "lowshelf=f=140:g=3", ""),
}


def onset(path: Path, shot: int = 0) -> float:
    """shot. atisin baslangic zamani (sn): kanallar ortalamasi tepesinin %15'ini >=0.25 sn sessizlikten sonra gecen ornek."""
    with wave.open(str(path)) as w:
        n, ch = w.getnframes(), w.getnchannels()
        data = struct.unpack("<%dh" % (n * ch), w.readframes(n))
        sr = w.getframerate()
    mag = [sum(abs(data[i * ch + c]) for c in range(ch)) / ch for i in range(n)]
    limit = ONSET_FRAC * max(mag)
    found: list[float] = []
    last = -9.0
    for i, v in enumerate(mag):
        if v > limit:
            if i / sr - last > MIN_GAP:
                found.append(i / sr)
            last = i / sr
    return found[shot]


def ff(args: list[str]) -> str:
    r = subprocess.run(["ffmpeg", "-v", "info", "-nostats", "-y", *args], capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr[-800:])
    return r.stderr


def process(name: str, spec: Spec) -> None:
    src, shot, dur, tail, pitch, hp, lp, extra, comp = spec
    path = SRC / src
    ss = max(0.0, onset(path, shot) - PRE_ROLL)
    ratio = 2.0 ** (pitch / 12.0)
    f = ["pan=mono|c0=0.5*c0+0.5*c1", "aresample=44100"]
    if pitch != 0.0:  # perde + hiz birlikte (rubberband atis vurusunu bulaniklastirir)
        f += ["asetrate=%.2f" % (44100 * ratio), "aresample=44100"]
    f.append("highpass=f=%d" % hp)
    if extra:
        f.append(extra)
    f.append("lowpass=f=%d" % lp)
    if comp:
        f.append(comp)
    f.append("afade=t=in:d=%.3f" % FADE_IN)
    f.append("afade=t=out:st=%.3f:d=%.3f:curve=qsin" % (dur - tail, tail))
    tmp = TMP / (name + ".wav")
    ff(["-ss", "%.4f" % ss, "-t", "%.4f" % (dur * ratio), "-i", str(path), "-af", ",".join(f), "-c:a", "pcm_f32le", str(tmp)])
    log = ff(["-i", str(tmp), "-af", "astats=metadata=0", "-f", "null", "-"])
    gain = PEAK_DB - float(re.findall(r"Peak level dB: (-?[\d.]+)", log)[-1])
    if name == "w_shotgun_src":  # ara urun: float kalir, gen_weapons_v2 okur (16 bit WAV)
        ff(["-i", str(tmp), "-af", "volume=%.3fdB" % gain, "-c:a", "pcm_s16le", "-ac", "1", str(tmp.with_suffix(".16.wav"))])
        print("%s -> build/audio_tmp/%s.16.wav" % (name, name))
        return
    ff(["-i", str(tmp), "-af", "volume=%.3fdB" % gain, "-c:a", "pcm_s16le", "-ar", "44100", "-ac", "1", str(OUT / (name + ".wav"))])
    print("%s <- %s [%.3f+%.2f] pitch%+.1f lp%d gain%+.1f" % (name, src, ss, dur, pitch, lp, gain))


def main() -> int:
    TMP.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    for name, spec in SPECS.items():
        process(name, spec)
    return 0


if __name__ == "__main__":
    sys.exit(main())
