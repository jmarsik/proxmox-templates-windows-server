#!/usr/bin/env bash

# Usage:
#
# ./build.sh <variant> [additional packer build args]
#
# <variant> is 2022-desktop or 2025-desktop
# [additional packer build args] are passed verbatim to `packer build` just before final template arg
#
# Examples:
#
# ./build.sh 2022-desktop
# ./build.sh 2025-desktop -debug -on-error=ask

set -euo pipefail

VARIANT="${1:-}"
case "$VARIANT" in
  2022-desktop) SOURCE="proxmox-iso.win2022_desktop" ;;
  2025-desktop) SOURCE="proxmox-iso.win2025_desktop" ;;
  *) echo "usage: $0 {2022-desktop|2025-desktop} [additional packer build args]" >&2; exit 2 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check for required Packer variable file
PKRVARS="${SCRIPT_DIR}/pkrvars/${VARIANT}.pkrvars.hcl"
[[ -f "$PKRVARS" ]] || { echo "missing $PKRVARS — copy from ${PKRVARS}.example" >&2; exit 2; }

# Check for required environment variables
: "${PKR_VAR_proxmox_api_token:?export PKR_VAR_proxmox_api_token before running}"

pushd "$SCRIPT_DIR"

pixi run --manifest-path "${SCRIPT_DIR}/pixi.toml" packer init .
pixi run --manifest-path "${SCRIPT_DIR}/pixi.toml" packer validate -var-file="$PKRVARS" .
pixi run --manifest-path "${SCRIPT_DIR}/pixi.toml" packer build \
  -only="proxmox-windows.$SOURCE" -var-file="$PKRVARS" -timestamp-ui \
  ${@:2} \
  .

popd
