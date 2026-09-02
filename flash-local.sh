#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIRMWARE_DIR="${ROOT_DIR}/build-local"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This flashing helper currently supports macOS only." >&2
    exit 1
fi

command -v diskutil >/dev/null || { echo "diskutil was not found." >&2; exit 1; }

wait_for_uf2_volume() {
    local volume
    local marker

    echo "Waiting for a Nice!Nano UF2 bootloader volume..." >&2
    echo "Connect the requested half, then double-tap its reset button." >&2
    while true; do
        for volume in /Volumes/*; do
            [[ -d "${volume}" ]] || continue
            for marker in INFO_UF2.TXT INDEX.HTM DETAILS.TXT; do
                if [[ -f "${volume}/${marker}" ]]; then
                    printf '%s\n' "${volume}"
                    return 0
                fi
            done
        done
        sleep 1
    done
}

flash_one() {
    local side="$1"
    local firmware="${FIRMWARE_DIR}/crosses_42_${side}.uf2"
    local volume

    [[ -f "${firmware}" ]] || {
        echo "Missing firmware: ${firmware}" >&2
        exit 1
    }

    echo
    echo "Prepare the ${side} half."
    volume="$(wait_for_uf2_volume)"
    echo "Detected bootloader volume: ${volume}"
    echo "About to copy: ${firmware}"
    echo "Target: ${volume}"
    read -r -p "Flash this ${side} half? Type FLASH to continue: " confirmation
    [[ "${confirmation}" == "FLASH" ]] || {
        echo "Skipped ${side} half."
        exit 1
    }

    cp "${firmware}" "${volume}/"
    sync
    echo "Copied ${firmware}. The half should reboot and the volume should disappear."
    sleep 3
}

echo "Crosses V1 firmware flasher"
echo "This script only copies UF2 files to bootloader volumes."
echo "It does not reset the keyboard or use settings_reset.uf2."
echo
read -r -p "Flash both normal-clock firmware files? Type FLASH to continue: " confirmation
[[ "${confirmation}" == "FLASH" ]] || { echo "Aborted."; exit 1; }

echo "The official Crosses procedure flashes the right (primary) half first."
flash_one right
flash_one left

echo
echo "Both halves were flashed."
echo "Right: ${FIRMWARE_DIR}/crosses_42_right.uf2"
echo "Left:  ${FIRMWARE_DIR}/crosses_42_left.uf2"
