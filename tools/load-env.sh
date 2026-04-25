#!/usr/bin/env bash
# Load secrets from .env into pixi-activated shell.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "warn: $ENV_FILE missing; copy .env.example and fill secrets" >&2
    return 0 2>/dev/null || exit 0
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a
