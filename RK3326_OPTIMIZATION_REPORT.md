# SwitchWaker: RK3326 Optimization Report

Based on the recent commits implementing 6 major optimizations tailored for ARM64 Handhelds (like RK3326 / Mali-G31), there are a few additional avenues to further squeeze out performance, stability, and memory efficiency on these constrained devices.

## 1. Link-Time Optimization (LTO)
Currently, LTO (Link-Time Optimization) is not enabled in the CMake toolchain (`native/cmake/toolchain-aarch64-linux-gnu.cmake`) or the main `CMakeLists.txt` for the release builds.
Enabling ThinLTO or Full LTO is highly recommended for ARM64 platforms. It performs cross-module inlining, devirtualization, and aggressive dead code elimination.
- **Implementation:** Add `-flto=thin` or `-flto` to `CMAKE_C_FLAGS_RELEASE`, `CMAKE_CXX_FLAGS_RELEASE`, and the linker flags when using the `aarch64-linux-gnu` toolchain.

## 2. Memory Adjustments & Buffer Sizes
The `kMem1Size` is currently set to `160u * 1024 * 1024` (160MB). The device has 1GB of RAM.
- **Tuning `kMem2Size`:** Ensure `kMem2Size` is proportionally constrained to prevent memory fragmentation overhead in Linux.
- **Asset preloading:** If the GLES renderer stutters during texture loads, tuning the asset preload sizes and ensuring textures are correctly compressed (ASTC or BCn if properly decoded in software, but ideally native ASTC or ETC2 for Mali) can reduce hitching. The project disabled HD textures for RK3326, which is good. We should ensure the base textures avoid runtime conversion overhead.

## 3. Shader Precision Overrides (Mali-G31 specific)
The Mali-G31 GPU significantly benefits from 16-bit half-precision (`mediump`) floats in fragment shaders over 32-bit (`highp`) where precision is not critical (e.g., color math).
- **Implementation:** Check the shader generator (`uam` / `glsl_frontend`) and ensure that for the GLES backend on RK3326, default precision for floats in the fragment shader is `mediump`, or explicitly enforce `mediump` on variables not requiring world-space precision.

## 4. `SwitchWaker.sh` Launcher Tweaks
The current launcher sets performance governors for CPU, GPU, and DMC. This is great for max framerate, but a few more tweaks could help:
- **Swap / ZRAM:** Some PortMaster OSes (ArkOS, AmberELEC) use zram. Tweaking `vm.swappiness` to `100` is already done, which helps.
- **Thread Affinity (Taskset):** The RK3326 is a quad-core Cortex-A35. Explicitly pinning the main thread and the audio/render threads to specific cores using `taskset` in the launch script might reduce context-switching overhead. E.g., `taskset -c 1-3 ./switchwaker`.
- **Mali EGL tweaks:** Setting `export EGL_LOG_LEVEL=fatal` and `export MESA_GLSL_CACHE_DISABLE=0` (if using open-source panfrost) could provide minor boosts or faster start times. Though `libmali` blobs are used, minimizing debug traces is good.

## 5. Render Feature Toggles
To ensure a stable 30fps on Mali-G31:
- **Shadows and Post-Processing:** Consider forcing `COS_SHADOW_OFFSCREEN=0` or disabling high-resolution shadows by default via environment variables in `SwitchWaker.sh`.
- **Widescreen vs 4:3:** `COS_WIDTH=640` and `COS_HEIGHT=480` (4:3) is set in the PortMaster script. Keeping `COS_FB_SCALE=1.0` is correct. If users want 16:9, scaling the internal resolution lower (e.g., `0.75`) via `COS_FB_SCALE` for widescreen modes could maintain the pixel-fill-rate budget.

## Summary
The architectural work (batching, draw list fusion, decoupled clocks) already implemented in `7adf26a` tackles the CPU bottlenecks perfectly. The next logical step is LTO (for overall code efficiency) and Mali-specific shader/rendering tweaks to relieve the GPU fill-rate limits.
