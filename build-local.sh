#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${ROOT_DIR}/.zmk-workspace"
OUTPUT_DIR="${ROOT_DIR}/build-local"
IMAGE="${ZMK_DOCKER_IMAGE:-zmkfirmware/zmk-build-arm:stable}"
ZMK_REF="${ZMK_REF:-v0.3}"
BOARD="${ZMK_BOARD:-nice_nano}"

usage() {
    cat <<'EOF'
Usage: ./build-local.sh [options]

Build Crosses V1 firmware locally in Docker. This script never flashes or
resets a keyboard.

Options:
  --clean       Remove the cached Docker ZMK workspace before building
  --internal    Also build the internal-oscillator left and right variants
  --image NAME  Use a different ZMK Docker image
  -h, --help    Show this help
EOF
}

CLEAN=0
BUILD_INTERNAL=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean) CLEAN=1 ;;
        --internal) BUILD_INTERNAL=1 ;;
        --image)
            [[ $# -ge 2 ]] || { echo "--image requires a value" >&2; exit 2; }
            IMAGE="$2"
            shift
            ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

command -v docker >/dev/null || { echo "Docker is required but was not found." >&2; exit 1; }
command -v git >/dev/null || { echo "Git is required but was not found." >&2; exit 1; }
command -v west >/dev/null || { echo "West is required. Install it with: uv tool install west" >&2; exit 1; }
[[ -f "${ROOT_DIR}/build.yaml" ]] || { echo "build.yaml not found." >&2; exit 1; }
[[ -f "${ROOT_DIR}/config/crosses.keymap" ]] || { echo "config/crosses.keymap not found." >&2; exit 1; }

if [[ "${CLEAN}" == 1 ]]; then
    rm -rf "${WORKSPACE_DIR}"
fi

mkdir -p "${WORKSPACE_DIR}" "${OUTPUT_DIR}"

# Clone the manifest on the host. This avoids Docker inheriting a host Git URL
# rewrite or credential helper that can make public GitHub URLs ask for auth.
if [[ ! -d "${WORKSPACE_DIR}/zmk/.git" ]]; then
    rm -rf "${WORKSPACE_DIR}"
    mkdir -p "${WORKSPACE_DIR}"
    git clone --branch "${ZMK_REF}" --depth 1 \
        https://github.com/zmkfirmware/zmk.git "${WORKSPACE_DIR}/zmk"
fi
rm -rf "${WORKSPACE_DIR}/config"
cp -R "${ROOT_DIR}/config" "${WORKSPACE_DIR}/config"
if [[ ! -d "${WORKSPACE_DIR}/.west" ]]; then
    (cd "${WORKSPACE_DIR}" && west init -l config)
fi

echo "Updating ZMK dependencies on the host..."
(cd "${WORKSPACE_DIR}" && west update && west zephyr-export)

echo "Using Docker image: ${IMAGE}"
echo "Board: ${BOARD}"
echo "ZMK workspace: ${WORKSPACE_DIR}"
echo "Output directory: ${OUTPUT_DIR}"

docker run --rm \
    --network host \
    -e "BUILD_INTERNAL=${BUILD_INTERNAL}" \
    -e "BOARD=${BOARD}" \
    -v "${ROOT_DIR}:/work/config-repo" \
    -v "${WORKSPACE_DIR}:/work/zmk-workspace" \
    -v "${OUTPUT_DIR}:/work/output" \
    -w /work/zmk-workspace \
    "${IMAGE}" \
    bash -euo pipefail -c '
        west zephyr-export

        build_one() {
            local shield="$1"
            local artifact="$2"
            shift 2
            local build_dir="build-${artifact}"

            rm -rf "${build_dir}"
            west build -s zmk/app -d "${build_dir}" -b "${BOARD}" -- \
                -DZMK_CONFIG=/work/config-repo/config \
                -DZMK_EXTRA_MODULES=/work/config-repo/crosses-detent \
                -DSHIELD="${shield}" \
                -DEXTRA_DTC_OVERLAY_FILE=/work/config-repo/config/scroll-invert.overlay \
                "$@"
            cp "${build_dir}/zephyr/zmk.uf2" "/work/output/${artifact}.uf2"
        }

        build_one crosses_left crosses_42_left
        build_one crosses_right crosses_42_right \
            -DSNIPPET=studio-rpc-usb-uart \
            -DCONFIG_ZMK_STUDIO=y

        if [[ "${BUILD_INTERNAL}" == 1 ]]; then
            build_one crosses_left crosses_42_left_internal_osc \
                -DCONFIG_CLOCK_CONTROL_NRF_K32SRC_RC=y
            build_one crosses_right crosses_42_right_internal_osc \
                -DSNIPPET=studio-rpc-usb-uart \
                -DCONFIG_ZMK_STUDIO=y \
                -DCONFIG_CLOCK_CONTROL_NRF_K32SRC_RC=y
        fi
    '

echo
echo "Build complete. Firmware artifacts:"
find "${OUTPUT_DIR}" -maxdepth 1 -type f -name '*.uf2' -print | sort
echo
echo "No firmware was flashed and no keyboard was reset."
