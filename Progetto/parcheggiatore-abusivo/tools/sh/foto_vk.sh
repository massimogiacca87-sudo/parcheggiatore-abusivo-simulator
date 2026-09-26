#!/bin/bash
# Fotografie col renderer Forward+ (Vulkan) invece di opengl3: serve per le cose
# che su Compatibility non esistono (le pozzanghere, la 0.62). Vulkan in software
# (lavapipe): apt-get install -y mesa-vulkan-drivers. Lento, ma vero.
# Uso: /tmp/foto_vk.sh foto_x 400 → /tmp/outvk_foto_x.txt
cd /home/claude/parcheggiatore-abusivo
P="$1"; T="${2:-120}"
cp project.godot /tmp/pg.bak
cp tools/$P.gd scripts/_$P.gd
python3 - "$P" <<'PY'
import sys, io
p = sys.argv[1]
s = io.open("project.godot", encoding="utf-8").read()
s = s.replace('SoundManager="*res://scripts/autoload/sound_manager.gd"',
              'SoundManager="*res://scripts/autoload/sound_manager.gd"\nFoto="*res://scripts/_%s.gd"' % p)
io.open("project.godot", "w", encoding="utf-8").write(s)
PY
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json timeout $T xvfb-run -a -s "-screen 0 1280x760x24" /home/claude/godot4 --path . \
  --rendering-driver vulkan --rendering-method forward_plus --resolution 1280x760 > /tmp/outvk_$P.txt 2>&1
cp /tmp/pg.bak project.godot
rm -f scripts/_$P.gd
