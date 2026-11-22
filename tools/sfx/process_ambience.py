"""Taha'nin indirdigi CC0 ortam seslerini oyun icin isler (ffmpeg gerekir, PATH'te olmali).

Calistirma (proje kokunden):  python tools/sfx/process_ambience.py
Girdi : assets/audio/source/ambience/*  (ham, git'e girmez)
Cikti : assets/audio/ambience/*_cc0.wav (44.1 kHz, 16 bit, mono). Sentez yer tutucular (gen_ambience.py) diskte kalir.
Ardindan: godot --headless --path . --import
Duzey: donguler ortalama (mean) -24 dB'ye, tek seferlikler tepe -3 dBFS'e getirilir; oyundaki asil duzey
scripts/data/ambience_data.gd'deki volume_db ile ayarlanir.

Kirpma zamanlari:
  storm_3_siren: 46.5 s - 53.0 s (sn 47/49/51'de 500-700 Hz'de en belirgin sirenin tonu; 75 s sonrasi gok gurultusu).
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "assets" / "audio" / "source" / "ambience"
OUT = ROOT / "assets" / "audio" / "ambience"
LOOP_MEAN_DB = -24.0
ONESHOT_PEAK_DB = -3.0
OUT_FMT = ["-ar", "44100", "-ac", "1", "-c:a", "pcm_s16le"]


def ffmpeg(args: list[str]) -> str:
    cmd = ["ffmpeg", "-hide_banner", "-y", *args]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(res.stderr)
        raise SystemExit(f"ffmpeg basarisiz: {' '.join(cmd)}")
    return res.stderr


def measure(path: Path) -> tuple[float, float]:
    """(mean_volume dB, max_volume dB) volumedetect ile."""
    err = ffmpeg(["-i", str(path), "-af", "volumedetect", "-f", "null", "-"])
    mean = float(re.search(r"mean_volume: (-?[\d.]+) dB", err).group(1))
    peak = float(re.search(r"max_volume: (-?[\d.]+) dB", err).group(1))
    return mean, peak


def render(src: Path, out_name: str, chain: str, loop: bool, extra_in: list[str] | None = None) -> None:
    """chain: ffmpeg -filter_complex govdesi; girdi [0:a], cikti [o]. Sonra duzey normalizasyonu."""
    tmp = OUT / f"_tmp_{out_name}.wav"
    ffmpeg([*(extra_in or []), "-i", str(src), "-filter_complex", chain, "-map", "[o]", *OUT_FMT, str(tmp)])
    mean, peak = measure(tmp)
    gain = (LOOP_MEAN_DB - mean) if loop else (ONESHOT_PEAK_DB - peak)
    # not: alimiter kullanilmaz (gecikmesi dosya basini sifirlar); tepe asilirsa asagidaki kontrol uyarir
    final = OUT / out_name
    ffmpeg(["-i", str(tmp), "-af", f"volume={gain:.2f}dB", *OUT_FMT, str(final)])
    tmp.unlink()
    m2, p2 = measure(final)
    if p2 > -0.5:
        print("UYARI: tepe 0 dB'ye cok yakin, hedef ortalamayi dusur")
    print(f"{out_name}: kazanc {gain:+.1f} dB -> mean {m2:.1f} dB, peak {p2:.1f} dB")


def seamless(trim_start: float, trim_end: float, xfade: float, pre: str = "") -> str:
    """Dongu: son xfade sn basa esit guc ile carpazlanir. Uzunluk = (trim_end - trim_start) - xfade."""
    dur = trim_end - trim_start
    return (
        f"[0:a]{pre}atrim={trim_start}:{trim_end},asetpts=PTS-STARTPTS,asplit=3[a][b][c];"
        f"[a]atrim=0:{xfade},asetpts=PTS-STARTPTS[head];"
        f"[b]atrim={xfade}:{dur - xfade},asetpts=PTS-STARTPTS[mid];"
        f"[c]atrim={dur - xfade}:{dur},asetpts=PTS-STARTPTS[tail];"
        f"[tail][head]acrossfade=d={xfade}:c1=qsin:c2=qsin[cf];"
        f"[cf][mid]concat=n=2:v=0:a=1[o]"
    )


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    mono = "pan=mono|c0=0.5*c0+0.5*c1,"  # ham dosya mono ise c1 yok; asagida mono olanlarda kullanilmaz
    # sehir yatagi: 29.3 s, 1 sn carpazli dongu, hafif alcak/yuksek kirpma
    render(SRC / "busy_cyberworld.ogg", "city_bed_cc0.wav",
           seamless(0.0, 29.3, 1.0, pre="aresample=44100,highpass=f=40,"), loop=True)
    # ates: 3.5 s, 0.5 sn carpazli dongu (3.0 s); oyunda yayicilar rastgele ofset + perde ile calar
    render(SRC / "fire-1.ogg", "fire_cc0.wav",
           seamless(0.0, 3.5, 0.5, pre="aresample=44100,"), loop=True)
    # siren: stereo -> mono, 400-1500 Hz bant (firtina hissi/gurultu azalir), 0.5 sn solma
    render(SRC / "storm_3_siren.ogg", "distant_siren_cc0.wav",
           f"[0:a]{mono}atrim=46.5:53.0,asetpts=PTS-STARTPTS,highpass=f=400,lowpass=f=1500,"
           "afade=t=in:d=0.5,afade=t=out:st=6.0:d=0.5[o]", loop=False)
    # kopek: 4 ms solma, ~4 kHz ust kirpma (uzak)
    render(SRC / "dog_barking_mono.wav", "distant_dog_cc0.wav",
           "[0:a]aresample=44100,lowpass=f=4000,afade=t=in:d=0.004,afade=t=out:st=2.03:d=0.004[o]", loop=False)
    # cam: stereo -> mono, ~5 kHz ust kirpma, 4 ms solma
    render(SRC / "glass_breaking.wav", "distant_glass_cc0.wav",
           f"[0:a]{mono}aresample=44100,lowpass=f=5000,afade=t=in:d=0.004,afade=t=out:st=1.30:d=0.004[o]", loop=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
