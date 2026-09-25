#!/bin/bash
# Prepara le patch dei commit nuovi (dal tag pc_sync) per il repo sul PC.
cd /home/claude/parcheggiatore-abusivo
rm -rf /mnt/user-data/outputs/_claude_tmp; mkdir -p /mnt/user-data/outputs/_claude_tmp
git format-patch --binary -o /mnt/user-data/outputs/_claude_tmp pc_sync..HEAD -- . ':!.godot'
