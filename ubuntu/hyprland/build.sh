#!/usr/bin/env bash
# Builds the Hyprland stack from source into an isolated prefix (/opt/hyprland).
# Follows the wiki build order. Safe to re-run: finished packages are skipped
# unless a newer stable tag exists. Nothing is installed into /usr.
set -euo pipefail

PREFIX=/opt/hyprland
SRC="$HOME/hyprland-build/src"
MARK="$PREFIX/.built"
JOBS="${JOBS:-$(nproc)}"
export CC=gcc-16 CXX=g++-16

CLEAN_PATH="$(printf %s "$PATH" | tr : "\n" | grep -vx "$HOME/.local/bin" | paste -sd:)"
export PATH="$PREFIX/bin:$CLEAN_PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig"
export CMAKE_PREFIX_PATH="$PREFIX"
export LD_LIBRARY_PATH="$PREFIX/lib"

log() { printf '\n=== %s ===\n' "$*"; }

if [ "$EUID" -eq 0 ]; then echo "run as your normal user"; exit 1; fi

log "apt build dependencies"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential cmake cmake-extras git ninja-build pkg-config meson gcc-16 g++-16 \
    libpugixml-dev libpixman-1-dev libcairo2-dev librsvg2-dev libtomlplusplus-dev libzip-dev \
    libdrm-dev libgles2-mesa-dev libheif-dev libjpeg-dev libjxl-dev libmagic-dev libwebp-dev \
    libdisplay-info-dev libgbm-dev libgles-dev libinput-dev libseat-dev libwayland-dev \
    libabsl-dev libiniparser-dev libxkbcommon-dev glslang-dev glslang-tools libeis-dev \
    libglaze-dev liblua5.5-dev libmuparser-dev libudis86-dev libxcb-composite0-dev \
    libxcb-errors-dev libxcb-icccm4-dev libxcb-res0-dev libxcb-xfixes0-dev libxcursor-dev \
    libexpat1-dev libffi-dev libxml2-dev libsystemd-dev libpipewire-0.3-dev libspa-0.2-dev \
    libxcb-ewmh-dev libxcb-render-util0-dev libxcb-xinput-dev xwayland

if [ ! -d "$PREFIX" ]; then
    sudo mkdir -p "$PREFIX"
    sudo chown "$USER":"$USER" "$PREFIX"
fi
mkdir -p "$SRC" "$MARK"

# latest_tag <regex>: newest tag matching the regex, by version sort
latest_tag() { git tag | grep -E "$1" | sort -V | tail -n 1; }

# fetch <name> <url> <tag-regex>  -> checks out the newest matching tag, sets TAG
fetch() {
    local name="$1" url="$2" re="$3"
    [ -d "$SRC/$name/.git" ] || git clone "$url" "$SRC/$name"
    cd "$SRC/$name"
    git fetch --all --tags --prune --quiet
    TAG="$(latest_tag "$re")"
    [ -n "$TAG" ] || { echo "no tag matching $re for $name"; exit 1; }
    git checkout --quiet --force "$TAG"
    git submodule update --init --force --recursive --quiet
}

built() { [ -f "$MARK/$1-$2" ]; }
mark() { rm -f "$MARK/$1-"[0-9v]* ; touch "$MARK/$1-$2"; }

# build_cmake <name> <url> <tag-regex> [extra cmake args...]
build_cmake() {
    local name="$1" url="$2" re="$3"; shift 3
    log "$name"
    fetch "$name" "$url" "$re"
    if built "$name" "$TAG"; then echo "$name $TAG already built"; return; fi
    if [ ! -f CMakeLists.txt ] && [ -f meson.build ]; then
        rm -rf build
        meson setup build --prefix="$PREFIX" --libdir=lib -Dc_link_args="-Wl,-rpath,$PREFIX/lib" "$@"
        ninja -C build
        ninja -C build install
    else
        cmake -S . -B build --fresh -G Ninja \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_INSTALL_LIBDIR=lib \
            -DCMAKE_INSTALL_RPATH="$PREFIX/lib" \
            -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" "$@"
        cmake --build build -j "$JOBS"
        cmake --install build
    fi
    mark "$name" "$TAG"
}

# build_meson <name> <url> <tag-regex> [meson args...]
build_meson() {
    local name="$1" url="$2" re="$3"; shift 3
    log "$name"
    fetch "$name" "$url" "$re"
    if built "$name" "$TAG"; then echo "$name $TAG already built"; return; fi
    rm -rf build
    meson setup build --prefix="$PREFIX" --libdir=lib -Dc_link_args="-Wl,-rpath,$PREFIX/lib" "$@"
    ninja -C build
    ninja -C build install
    mark "$name" "$TAG"
}

# Ubuntu 26.04's wayland, wayland-protocols and re2 are too old for current Hyprland.
build_meson wayland https://gitlab.freedesktop.org/wayland/wayland.git '^[0-9]+\.[0-9]+\.([0-9]|[1-7][0-9]|8[0-9])$' \
    -Dtests=false -Ddocumentation=false
build_meson wayland-protocols https://gitlab.freedesktop.org/wayland/wayland-protocols.git '^[0-9]+\.[0-9]+$' \
    -Dtests=false
build_cmake re2 https://github.com/google/re2.git '^20[0-9]{2}-[0-9]{2}-[0-9]{2}$' \
    -DCMAKE_CXX_STANDARD=20 -DBUILD_SHARED_LIBS=ON -DRE2_BUILD_TESTING=OFF

HW=https://github.com/hyprwm
STABLE='^v?[0-9]+\.[0-9]+\.[0-9]+$'
build_cmake hyprland-protocols $HW/hyprland-protocols.git "$STABLE"
build_cmake hyprwayland-scanner $HW/hyprwayland-scanner.git "$STABLE"
build_cmake hyprutils $HW/hyprutils.git "$STABLE"
build_cmake hyprgraphics $HW/hyprgraphics.git "$STABLE"
build_cmake hyprlang $HW/hyprlang.git "$STABLE"
build_cmake hyprcursor $HW/hyprcursor.git "$STABLE"
build_cmake aquamarine $HW/aquamarine.git "$STABLE"
build_cmake hyprwire $HW/hyprwire.git "$STABLE"
build_cmake hyprtoolkit $HW/hyprtoolkit.git "$STABLE"
build_cmake hyprland-guiutils $HW/hyprland-guiutils.git "$STABLE"
build_cmake Hyprland $HW/Hyprland.git "$STABLE" \
    -DPython3_EXECUTABLE=/usr/bin/python3 -DPython_EXECUTABLE=/usr/bin/python3

log "session wrapper"
cat > "$PREFIX/bin/hyprland-session" <<EOF
#!/bin/sh
export PATH="$PREFIX/bin:\$PATH"
export XDG_DATA_DIRS="$PREFIX/share:\${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
exec "$PREFIX/bin/start-hyprland" "\$@"
EOF
chmod +x "$PREFIX/bin/hyprland-session"

log "DONE"
"$PREFIX/bin/Hyprland" --version | head -2
