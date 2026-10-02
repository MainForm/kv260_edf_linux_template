#!/usr/bin/env bash
set -euo pipefail

# Run after: source ./edf-init-build-env build
if ! command -v gen-machine-conf >/dev/null 2>&1 ||
   ! command -v bitbake >/dev/null 2>&1 ||
   [[ -z "${BUILDDIR:-}" || ! -d "${BUILDDIR}/conf" ]]; then
    echo "ERROR: 먼저 source ./edf-init-build-env build로 환경을 초기화하세요." >&2
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LAYER_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
MACHINE_NAME="zynqmp-kv260-sdt-full"
SDT_DIR="${LAYER_DIR}/hw/sdt"
TEMPLATE="${LAYER_DIR}/conf/machineyaml/kv260.yaml"
WORK_DIR="${BUILDDIR}/gen-machine/${MACHINE_NAME}"

if [[ ! -s "${SDT_DIR}/system-top.dts" || ! -f "$TEMPLATE" ]]; then
    echo "ERROR: hw/sdt/system-top.dts와 conf/machineyaml/kv260.yaml이 필요합니다." >&2
    exit 1
fi

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Generate configuration in the layer and temporary files in build/.
# Omit -l to leave local.conf unchanged.
gen-machine-conf parse-sdt \
    --template "$TEMPLATE" \
    --hw-description "$SDT_DIR" \
    --machine-name "$MACHINE_NAME" \
    -c "${LAYER_DIR}/conf" \
    --output "${WORK_DIR}/output" \
    -g full

echo "생성 완료: ${LAYER_DIR}/conf/machine/${MACHINE_NAME}.conf"
echo "생성된 설정과 SDT_URI 경로를 검토한 뒤 빌드 머신을 선택하세요."
