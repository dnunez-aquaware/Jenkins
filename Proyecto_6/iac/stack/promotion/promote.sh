#!/usr/bin/env bash
#
# Promueve la imagen de un ambiente al siguiente copiando el tag en git.
#
#   ./promote.sh dev staging
#   ./promote.sh staging prod
#
set -euo pipefail
cd "$(dirname "$0")/../envs"

FROM="${1:?uso: $0 <origen> <destino>}"
TO="${2:?uso: $0 <origen> <destino>}"

IMAGE="$(grep -oE 'image: [^ ]+' "$FROM/deployment.yaml" | cut -d' ' -f2)"
sed -i "s|image: [^ ]*|image: ${IMAGE}|" "$TO/deployment.yaml"

echo "==> ${TO} ahora usa ${IMAGE}"
echo "    Falta: git commit -am \"promote ${TO}: ${IMAGE##*:}\" && git push"
