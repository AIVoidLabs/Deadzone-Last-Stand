"""Tüm amblemlerin kontak görüntüsü: koyu kırmızı zemin, 4 sütun. 256 px ve 96 px (küçük okunurluk).

    blender --background --python tools/blender/ui_emblems_contact.py
Çıktı: build/shots/emblems_contact.png, build/shots/emblems_contact_small.png
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ui_ink as U  # noqa: E402

names = sorted(f[:-4] for f in os.listdir(U.OUT_DIR) if f.endswith(".png") and f[:-4].split("_")[0] in ("weapon", "stat"))
order = [n for n in names if n.startswith("weapon_")] + [n for n in names if n.startswith("stat_")]
U.contact_sheet(order, os.path.join(U.REPO, "build", "shots", "emblems_contact.png"), cols=4, tile=256)
U.contact_sheet(order, os.path.join(U.REPO, "build", "shots", "emblems_contact_small.png"), cols=7, tile=96)
print("CONTACT", len(order))
