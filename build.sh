#!/usr/bin/env bash
# Usage: ./build.sh <variant>   where variant is 2022-desktop | 2025-desktop
set -euo pipefail

VARIANT="${1:-}"
case "$VARIANT" in
  2022-desktop) SOURCE="proxmox-iso.win2022_desktop" ;;
  2025-desktop) SOURCE="proxmox-iso.win2025_desktop" ;;
  *) echo "usage: $0 {2022-desktop|2025-desktop}" >&2; exit 2 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKRVARS="${SCRIPT_DIR}/pkrvars/${VARIANT}.pkrvars.hcl"
[[ -f "$PKRVARS" ]] || { echo "missing $PKRVARS — copy from ${PKRVARS}.example" >&2; exit 2; }

: "${PKR_VAR_proxmox_api_token:?export PKR_VAR_proxmox_api_token before running}"

cd "$SCRIPT_DIR"

pixi run --manifest-path "${SCRIPT_DIR}/pixi.toml" packer init .
pixi run --manifest-path "${SCRIPT_DIR}/pixi.toml" packer validate -var-file="$PKRVARS" .
pixi run --manifest-path "${SCRIPT_DIR}/pixi.toml" packer build -only="$SOURCE" -var-file="$PKRVARS" .
