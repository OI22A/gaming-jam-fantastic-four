#!/usr/bin/env bash
# Revisa estilo con gdtoolkit (pip install -r requirements-dev.txt).
# Uso:  scripts/tools/lint.sh          -> solo comprueba
#       scripts/tools/lint.sh --fix    -> reformatea los archivos
set -euo pipefail
cd "$(dirname "$0")/../.."

if [[ "${1:-}" == "--fix" ]]; then
  gdformat scripts tests
else
  gdformat --check scripts tests
fi
gdlint scripts tests
