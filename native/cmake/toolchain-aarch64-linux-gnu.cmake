# Cross-compilation toolchain: aarch64-linux-gnu (RK3326 / Mali-G31 / GLES-only)
#
# Usage:
#   cmake -S native -B build/linux-aarch64-gles -G Ninja \
#         -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-aarch64-linux-gnu.cmake

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# ---------------------------------------------------------------------------
# Compiler selection
# ---------------------------------------------------------------------------
# Prefer clang cross-compilation (the project already uses clang-style flags).
set(CMAKE_C_COMPILER   clang)
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_C_COMPILER_TARGET   aarch64-linux-gnu)
set(CMAKE_CXX_COMPILER_TARGET aarch64-linux-gnu)
set(CMAKE_ASM_COMPILER_TARGET aarch64-linux-gnu)

# Use GNU cross-linker (aarch64-linux-gnu-ld)
set(CMAKE_EXE_LINKER_FLAGS_INIT    "-fuse-ld=/usr/bin/aarch64-linux-gnu-ld")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-fuse-ld=/usr/bin/aarch64-linux-gnu-ld")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "-fuse-ld=/usr/bin/aarch64-linux-gnu-ld")

# ---------------------------------------------------------------------------
# Sysroot / find-root configuration
# ---------------------------------------------------------------------------
set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu /home/jbc/foxhollow-sysroot/usr /usr)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# pkg-config cross-compilation
set(ENV{PKG_CONFIG_PATH} "/home/jbc/foxhollow-sysroot/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/lib/aarch64-linux-gnu/pkgconfig")
set(ENV{PKG_CONFIG_SYSROOT_DIR} "/home/jbc/foxhollow-sysroot")
set(ENV{PKG_CONFIG_LIBDIR} "/home/jbc/foxhollow-sysroot/usr/lib/aarch64-linux-gnu/pkgconfig")

# Extra include/lib paths
set(CMAKE_PREFIX_PATH "/home/jbc/foxhollow-sysroot/usr;/usr/aarch64-linux-gnu" ${CMAKE_PREFIX_PATH})
list(APPEND CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES
  "/home/jbc/foxhollow-sysroot/usr/include"
  "/home/jbc/foxhollow-sysroot/usr/include/aarch64-linux-gnu"
  "/usr/include/aarch64-linux-gnu")
list(APPEND CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES
  "/home/jbc/foxhollow-sysroot/usr/include"
  "/home/jbc/foxhollow-sysroot/usr/include/aarch64-linux-gnu"
  "/usr/include/aarch64-linux-gnu")

# ---------------------------------------------------------------------------
# RPATH for portable deployment
# ---------------------------------------------------------------------------
set(CMAKE_BUILD_RPATH "$ORIGIN:$ORIGIN/libs.aarch64")
set(CMAKE_INSTALL_RPATH "$ORIGIN:$ORIGIN/libs.aarch64")
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
