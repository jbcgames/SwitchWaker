#!/bin/bash
# PortMaster Launch Script for SwitchWaker (The Legend of Zelda: The Wind Waker)
# Target: RK3326 / Mali-G31 / OpenGL ES 3.0 / KMSDRM

# Pre-kill any stale instances to ensure DRM master is completely free
sudo killall -9 switchwaker gptokeyb gptokeyb2 2>/dev/null || true

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

[ -f "$controlfolder/control.txt" ] && source "$controlfolder/control.txt"
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
type get_controls >/dev/null 2>&1 && get_controls

GAMEDIR="/roms/ports/SwitchWaker"
cd "$GAMEDIR" || exit 1

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# =============================================================================
# HARDWARE AUDIO SETUP
# =============================================================================
amixer -c 0 sset 'Playback Path' 'SPK' >/dev/null 2>&1 || true
amixer -c 0 sset 'Playback' 95% >/dev/null 2>&1 || true

# =============================================================================
# AUTO-DETECT MALI GPU DRIVER & CREATE SYMLINKS
# =============================================================================
MALI_DIR="/tmp/switchwaker_mali"
rm -rf "$MALI_DIR"
mkdir -p "$MALI_DIR"

if [ -f "$GAMEDIR/libs.aarch64/libmali-bifrost-g31-rxp0-gbm.so" ]; then
  MALI_BLOB="$GAMEDIR/libs.aarch64/libmali-bifrost-g31-rxp0-gbm.so"
elif [ -f "/usr/lib/aarch64-linux-gnu/libmali-bifrost-g31-rxp0-gbm.so" ]; then
  MALI_BLOB="/usr/lib/aarch64-linux-gnu/libmali-bifrost-g31-rxp0-gbm.so"
else
  MALI_BLOB=$(find /usr/lib -name "libmali-bifrost-g31-*.so" -o -name "libmali.so" 2>/dev/null | head -n 1)
fi

if [ -n "$MALI_BLOB" ]; then
  ln -sf "$MALI_BLOB" "$MALI_DIR/libEGL.so.1"
  ln -sf "$MALI_BLOB" "$MALI_DIR/libEGL.so"
  ln -sf "$MALI_BLOB" "$MALI_DIR/libGLESv2.so.2"
  ln -sf "$MALI_BLOB" "$MALI_DIR/libGLESv2.so"
  ln -sf "$MALI_BLOB" "$MALI_DIR/libgbm.so.1"
  ln -sf "$MALI_BLOB" "$MALI_DIR/libgbm.so"
fi

export LD_LIBRARY_PATH="$MALI_DIR:$GAMEDIR/libs.aarch64:$GAMEDIR:$LD_LIBRARY_PATH"
unset LD_PRELOAD

export SDL_VIDEODRIVER="sdl2"
export SDL3SHIM_SDL2_VIDEODRIVER="kmsdrm"
export SDL_AUDIODRIVER="sdl2"
export SDL3SHIM_SDL2_AUDIODRIVER="alsa"
export SDL_AUDIO_ALSA_SET_BUFFER_SIZE=1
export SDL_AUDIO_ALSA_BUFFER_SIZE=4096
export SDL_AUDIO_ALSA_PERIOD_SIZE=1024

# =============================================================================
# HARDWARE PERFORMANCE GOVERNORS & MEMORY TUNING
# =============================================================================
# Online all available CPU cores
for cpu in /sys/devices/system/cpu/cpu[0-3]/online; do
  [ -f "$cpu" ] && echo 1 | sudo tee "$cpu" >/dev/null 2>&1 || true
done

# CPU performance governor
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
  echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
fi

# Mali GPU devfreq governor -> performance (locks Mali-G31 clock to max ~520MHz)
for gpu_gov in /sys/devices/platform/*.gpu/devfreq/*.gpu/governor /sys/class/devfreq/*gpu*/governor; do
  [ -f "$gpu_gov" ] && echo performance | sudo tee "$gpu_gov" >/dev/null 2>&1 || true
done

# DMC (Dynamic Memory Controller / DRAM) governor -> performance (locks DDR to max)
for dmc_gov in /sys/devices/platform/dmc/devfreq/dmc/governor /sys/class/devfreq/*dmc*/governor; do
  [ -f "$dmc_gov" ] && echo performance | sudo tee "$dmc_gov" >/dev/null 2>&1 || true
done

# Kernel virtual memory tunings & cache drop
echo ark | sudo -S /sbin/sysctl -w vm.overcommit_memory=1 >/dev/null 2>&1 || true
echo ark | sudo -S /sbin/sysctl -w vm.min_free_kbytes=32768 >/dev/null 2>&1 || true
echo ark | sudo -S /sbin/sysctl -w vm.vfs_cache_pressure=200 >/dev/null 2>&1 || true
echo ark | sudo -S /sbin/sysctl -w vm.swappiness=100 >/dev/null 2>&1 || true
echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true

# Auto-protect switchwaker process from OOM killer
(
  for _ in {1..30}; do
    PID=$(pgrep -x switchwaker | head -n 1)
    if [ -n "$PID" ]; then
      echo ark | sudo -S sh -c "echo -800 > /proc/$PID/oom_score_adj" 2>/dev/null
      break
    fi
    sleep 0.5
  done
) &

# =============================================================================
# GAMEPAD CONFIGURATION
# =============================================================================
MAP_GO="190000004b4800000011000000010000,GO-Super Gamepad,a:b1,b:b0,back:b12,dpdown:b9,dpleft:b10,dpright:b11,dpup:b8,guide:b16,leftshoulder:b4,leftstick:b14,lefttrigger:b6,leftx:a0,lefty:a1,rightshoulder:b5,rightstick:b15,righttrigger:b7,rightx:a2,righty:a3,start:b13,x:b2,y:b3,platform:Linux,"
MAP_GO_DEB="1900bb3e4b4800000011000000010000,GO-Super Gamepad,a:b1,b:b0,back:b12,dpdown:b9,dpleft:b10,dpright:b11,dpup:b8,guide:b16,leftshoulder:b4,leftstick:b14,lefttrigger:b6,leftx:a0,lefty:a1,rightshoulder:b5,rightstick:b15,righttrigger:b7,rightx:a2,righty:a3,start:b13,x:b2,y:b3,platform:Linux,"

if [ -n "$sdl_controllerconfig" ]; then
  cfg_deb=$(echo "$sdl_controllerconfig" | sed 's/190000004b4800000011000000010000/1900bb3e4b4800000011000000010000/g')
  export SDL_GAMECONTROLLERCONFIG="${sdl_controllerconfig}"$'\n'"${cfg_deb}"$'\n'"${MAP_GO}"$'\n'"${MAP_GO_DEB}"
else
  export SDL_GAMECONTROLLERCONFIG="${MAP_GO}"$'\n'"${MAP_GO_DEB}"
fi

BIN="$GAMEDIR/switchwaker"
chmod +x "$BIN"

# =============================================================================
# CONTROLLER HOTKEY DAEMON (SELECT + START EXIT)
# =============================================================================
if [ -f "$GAMEDIR/switchwaker.gptk" ]; then
  if [ -n "$GPTOKEYB2" ]; then
    $GPTOKEYB2 "$(basename "$BIN")" -c "$GAMEDIR/switchwaker.gptk" &
  elif [ -n "$GPTOKEYB" ]; then
    $GPTOKEYB "$(basename "$BIN")" -c "$GAMEDIR/switchwaker.gptk" &
  fi
fi

type pm_platform_helper >/dev/null 2>&1 && pm_platform_helper "$BIN"

# =============================================================================
# LAUNCH — find GZLE01 disc
# =============================================================================
ISO_PATH=""
for iso in "$GAMEDIR"/*.iso "$GAMEDIR"/*.ISO "$GAMEDIR"/*.gcm "$GAMEDIR"/*.GCM; do
  if [ -f "$iso" ]; then
    ISO_PATH="$iso"
    break
  fi
done

if [ -z "$ISO_PATH" ]; then
  echo "ERROR: No disc image (.iso / .gcm) found in $GAMEDIR"
  echo "Place your Wind Waker disc image (GZLE01.iso) in $GAMEDIR"
  type pm_finish >/dev/null 2>&1 && pm_finish
  exit 1
fi

export COS_DISC="$ISO_PATH"
export COS_BACKEND="opengles"
export COS_STALL_S=0
export COS_WIDTH=640
export COS_HEIGHT=480
export COS_FB_SCALE=1.0
export COS_QOL_SKIP_INTRO=1
export COS_QOL_INSTANT_TEXT=1
export AURORA_GX_SWEEP_PERIOD=30
export AURORA_GX_RETAIN_FRAMES=90
export COS_MEM1_MB=160
export COS_FULL_SPEED_CLOCK=1

echo "=== Launching SwitchWaker with disc: $ISO_PATH ==="
"$BIN" "$ISO_PATH"
ret=$?

echo "=== SwitchWaker exited with code $ret ==="
type pm_finish >/dev/null 2>&1 && pm_finish
