#!/usr/bin/env bash
#
# Publica una nueva version de cloud-dashboard en ECR.
#
#   ./release.sh          1.0.0 -> 1.0.1
#   ./release.sh minor    1.0.1 -> 1.1.0
#   ./release.sh major    1.1.0 -> 2.0.0
#
set -euo pipefail
cd "$(dirname "$0")"

REGISTRY="087692765125.dkr.ecr.us-east-1.amazonaws.com"
REGION="us-east-1"
REPO="cloud-dashboard"

# 1. Incrementar la version (VERSION es la fuente unica de verdad)
IFS=. read -r MAJOR MINOR PATCH < VERSION
case "${1:-patch}" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
  *) echo "uso: $0 [major|minor|patch]" >&2; exit 1 ;;
esac
VERSION="${MAJOR}.${MINOR}.${PATCH}"
IMAGE="${REGISTRY}/${REPO}:v${VERSION}"
echo "$VERSION" > VERSION
echo "==> Nueva version: v${VERSION}"

# 2. Construir la imagen con la version inyectada
docker build --build-arg "APP_VERSION=${VERSION}" -t "$IMAGE" .

# 3. Publicar en ECR
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"
docker push "$IMAGE"

# 4. Apuntar el manifiesto de Argo CD a la version nueva
sed -i "s|image: .*/${REPO}:.*|image: ${IMAGE}|" ../k8s/deployment.yaml

echo "==> Publicado ${IMAGE}"
echo "    Falta: git commit -am \"release v${VERSION}\" && git push"
