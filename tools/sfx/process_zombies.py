"""Deadzone Last Stand zombi sesleri: kullanicinin indirdigi CC0 paketlerden islenmis turevler.

Calistirma (proje kokunden):  python tools/sfx/process_zombies.py
Girdi : assets/audio/source/zombies/ (git'e girmez), arsivler build/audio_extract/<ad>/ altina acilir.
Cikti : assets/audio/sfx/z_*.wav (44.1 kHz, 16 bit, mono, 4 ms fade, tepe -3 dBFS).
Her cikti icin tam ffmpeg zinciri asagidaki SPECS tablosundadir; ayni girdi ayni cikti verir.
Ardindan: godot --headless --path . --import
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "assets" / "audio" / "source" / "zombies"
EXT = ROOT / "build" / "audio_extract"
TMP = ROOT / "build" / "audio_tmp"
OUT = ROOT / "assets" / "audio" / "sfx"
PEAK_DB = -3.0
FADE = 0.004

ARCHIVES = [
    "independent_nu_ljudbank-extreme_splatter.7z",
    "independent_nu_ljudbank-wet_squish_slurp_impacts.7z",
    "monster_sfx_pack_2.zip",
    "yelling sounds.zip",
    "zombiemoans_-_wav.zip",
]

SPLAT = "independent_nu_ljudbank-extreme_splatter/extreme_splatter/"
IMPACT = "independent_nu_ljudbank-wet_squish_slurp_impacts/impsplat/"
MON = "monster_sfx_pack_2/monster_sfx_pack_2/"
YELL = "yelling sounds/yelling sounds/"
MOAN = "zombiemoans_-_wav/ZombieMoans - Track "

# ad: (kaynak, baslangic sn, sure sn, perde yari-ton, lowpass Hz, ek filtre)
# kaynak "src:" onekli ise SRC klasorunden, degilse EXT altindan.
SPECS: dict[str, tuple[str, float, float, float, float, str]] = {
    # horde grunt (zombi inlemesi)
    "z_groan_1": (MOAN + "5 - ZombieMoan1.wav", 0.0, 2.1, 0.0, 5000, ""),
    "z_groan_2": (MOAN + "6 - ZombieMoan2.wav", 0.0, 1.85, 0.0, 5000, ""),
    "z_groan_3": (MOAN + "7 - ZombieMoan3.wav", 0.0, 1.5, -2.0, 5000, ""),
    "z_groan_4": ("src:darsycho__zombie-moans.ogg", 3.65, 2.3, 0.0, 5000, ""),
    "z_groan_5": ("src:darsycho__zombie-moans.ogg", 6.62, 2.25, -1.5, 5000, ""),
    "z_groan_6": ("src:darsycho__zombie-moans.ogg", 9.30, 0.95, -2.0, 5000, ""),
    # kosan zombi uyari cigligi
    "z_runner_screech_1": (MON + "monster-12.wav", 0.0, 0.5, 0.0, 5500, ""),
    "z_runner_screech_2": (MON + "monster-16.wav", 0.04, 0.5, -1.0, 5500, ""),
    # screamer cagri
    "z_screamer_scream_1": ("src:high_pitch_scream.mp3", 0.03, 1.5, -4.0, 6000, ""),
    "z_screamer_scream_2": (YELL + "yell4.wav", 0.48, 1.1, -3.0, 5500, ""),
    # boss kukremesi
    "z_boss_roar_1": (YELL + "3yell1.wav", 0.38, 1.5, -7.0, 4000, "lowshelf=f=180:g=4"),
    "z_boss_roar_2": (YELL + "3yell9.wav", 0.38, 1.6, -6.0, 4000, "lowshelf=f=180:g=4"),
    # dil
    "z_tongue_lash_1": (IMPACT + "impactsplat08.mp3.flac", 0.05, 0.3, 0.0, 4500, ""),
    "z_tongue_lash_2": (IMPACT + "impactsplat07.mp3.flac", 0.05, 0.25, 0.0, 4500, ""),
    "z_tongue_slurp_1": (IMPACT + "impactsplat05.mp3.flac", 0.25, 0.6, 0.0, 4500, ""),
    # tukuruk ve asit
    "z_spit_1": (IMPACT + "impactsplat06.mp3.flac", 0.05, 0.4, 0.0, 4500, ""),
    "z_spit_2": (IMPACT + "impactsplat04.mp3.flac", 0.12, 0.38, -1.0, 4500, ""),
    "z_acid_splash_1": (SPLAT + "crack12.mp3.flac", 2.9, 0.85, 0.0, 5000, ""),
    "z_acid_splash_2": (SPLAT + "crack12.mp3.flac", 4.42, 0.85, 0.0, 5000, ""),
    # patlayan (alcak agirlikli)
    "z_bloater_burst_1": (SPLAT + "crack12.mp3.flac", 5.73, 0.9, -5.0, 3500, "lowshelf=f=150:g=4"),
    "z_bloater_burst_2": (SPLAT + "crack11.mp3.flac", 0.05, 1.1, -4.0, 3500, "lowshelf=f=150:g=4"),
    # firlatici homurtu
    "z_thrower_grunt_1": (YELL + "3grunt3.wav", 0.0, 0.45, -3.0, 3500, ""),
    "z_thrower_grunt_2": (YELL + "3grunt2.wav", 0.3, 0.6, -3.0, 3500, ""),
    # govde dusmesi (boguk)
    "z_bodyfall_1": (IMPACT + "impactsplat01.mp3.flac", 0.05, 0.4, -3.0, 1000, "lowshelf=f=120:g=3"),
    "z_bodyfall_2": (IMPACT + "impactsplat02.mp3.flac", 0.15, 0.4, -3.0, 1000, "lowshelf=f=120:g=3"),
    "z_bodyfall_3": (IMPACT + "impactsplat03.mp3.flac", 0.10, 0.4, -3.0, 1000, "lowshelf=f=120:g=3"),
}

# kalabalik inlemesi katmani: 3 inleme x 3 perde (-4, -1.5, +1.5 yari-ton), z_groan ile ayni filtre zinciri
MOAN_FILES = [("5 - ZombieMoan1.wav", 2.1), ("6 - ZombieMoan2.wav", 1.85), ("7 - ZombieMoan3.wav", 1.5)]
for _n, (_f, _d) in enumerate(MOAN_FILES):
    for _k, _p in enumerate((-4.0, -1.5, 1.5)):
        SPECS["z_moan_%d" % (_n * 3 + _k + 1)] = (MOAN + _f, 0.0, _d, _p, 5000, "")


def extract() -> None:
    for a in ARCHIVES:
        d = EXT / Path(a).stem
        if d.is_dir() and any(d.iterdir()):
            continue
        d.mkdir(parents=True, exist_ok=True)
        subprocess.run(["tar", "-xf", str(SRC / a), "-C", str(d)], check=True)


def ff(args: list[str]) -> str:
    r = subprocess.run(["ffmpeg", "-v", "info", "-nostats", "-y", *args], capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr[-800:])
    return r.stderr


def build_filter(pitch: float, lp: float, extra: str) -> str:
    f = ["highpass=f=50"]
    if pitch != 0.0:
        f.append("rubberband=pitch=%.5f" % (2.0 ** (pitch / 12.0)))
    if extra:
        f.append(extra)
    f.append("lowpass=f=%d" % lp)
    return ",".join(f)


def process(name: str, spec: tuple[str, float, float, float, float, str]) -> None:
    src, ss, dur, pitch, lp, extra = spec
    path = SRC / src[4:] if src.startswith("src:") else EXT / src
    tmp = TMP / (name + ".wav")
    # 1. gecis: kes, mono, perde, filtre, fade -> 32 bit float, 44.1 kHz
    fo = max(0.0, dur - FADE)
    af = build_filter(pitch, lp, extra) + ",afade=t=in:d=%.3f,afade=t=out:st=%.3f:d=%.3f" % (FADE, fo, FADE)
    ff(["-ss", "%.3f" % ss, "-t", "%.3f" % dur, "-i", str(path), "-ac", "1", "-ar", "44100",
        "-af", af, "-c:a", "pcm_f32le", str(tmp)])
    # 2. gecis: gercek tepe (astats float okur; volumedetect 16 bit'e kirpar)
    log = ff(["-i", str(tmp), "-af", "astats=metadata=0", "-f", "null", "-"])
    m = re.findall(r"Peak level dB: (-?[\d.]+)", log)
    gain = PEAK_DB - float(m[-1])
    # 3. gecis: kazanc, 16 bit
    ff(["-i", str(tmp), "-af", "volume=%.3fdB" % gain,
        "-c:a", "pcm_s16le", "-ar", "44100", "-ac", "1", str(OUT / (name + ".wav"))])
    print("%s <- %s [%.2f+%.2f] pitch%+.1f lp%d gain%+.1f" % (name, src, ss, dur, pitch, lp, gain))


def main() -> int:
    extract()
    TMP.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    for name, spec in SPECS.items():
        process(name, spec)
    return 0


if __name__ == "__main__":
    sys.exit(main())
