#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIRMWARE_DIR="${ROOT_DIR}/build-local"
SIDES="right left"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This flashing helper currently supports macOS only." >&2
    exit 1
fi

command -v diskutil >/dev/null || { echo "diskutil was not found." >&2; exit 1; }

case "${1:-all}" in
    all) ;;
    left) SIDES="left" ;;
    right) SIDES="right" ;;
    *) echo "Usage: $0 [all|left|right]" >&2; exit 2 ;;
esac

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

wait_for_volume_to_disconnect() {
    local volume="$1"
    local attempts=30

    while [[ -d "${volume}" && ${attempts} -gt 0 ]]; do
        sleep 1
        attempts=$((attempts - 1))
    done

    [[ ! -d "${volume}" ]]
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
    # The UF2 bootloader can eject the volume while cp is still unwinding.
    # Treat that expected disconnect as success even if cp reports an I/O error.
    set +e
    cp "${firmware}" "${volume}/"
    local copy_status=$?
    sync
    set -e

    if wait_for_volume_to_disconnect "${volume}"; then
        echo "${side} half accepted the firmware and rebooted."
    elif [[ ${copy_status} -eq 0 ]]; then
        echo "${side} half was flashed, but the bootloader volume is still mounted." >&2
        return 1
    else
        echo "Copy failed and the bootloader volume is still mounted." >&2
        return 1
    fi
}

echo "Crosses V1 firmware flasher"
echo "This script only copies UF2 files to bootloader volumes."
echo "It does not reset the keyboard or use settings_reset.uf2."
echo
if [[ "${SIDES}" == "right left" ]]; then
    echo "The official Crosses procedure flashes the right (primary) half first."
fi
for side in ${SIDES}; do
    flash_one "${side}"
done

echo
if [[ "${SIDES}" == "right left" ]]; then
    echo "Both halves were flashed."
else
    echo "${SIDES} half was flashed."
fi
