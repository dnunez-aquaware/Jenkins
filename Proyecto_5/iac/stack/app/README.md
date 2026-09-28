# cloud-dashboard

App basada en la imagen oficial `nginx:1.27-alpine`, publicada en ECR con
versionado semantico y desplegada en EKS por Argo CD.

```
app/
├── VERSION               # fuente unica de verdad de la version
├── release.sh            # bump + build + push a ECR + actualiza el manifiesto
├── Dockerfile            # recibe la version via --build-arg APP_VERSION
├── nginx.conf.template   # ${APP_NAME} y ${APP_VERSION} se resuelven al arrancar
├── html/index.html
└── Jenkinsfile
```

## Publicar una version

```bash
export AWS_PROFILE=dnunez

./release.sh          # 1.0.0 -> 1.0.1
./release.sh minor    # 1.0.1 -> 1.1.0
./release.sh major    # 1.1.0 -> 2.0.0

git commit -am "release v1.0.1" && git push   # Argo CD despliega el nuevo tag
```

La version solo se escribe en `VERSION`. De ahi se propaga sola:

| Destino | Como |
|---|---|
| `LABEL version` / `ENV APP_VERSION` | `--build-arg APP_VERSION` |
| JSON de `/api/info` | `envsubst` sobre el template al arrancar el contenedor |
| Tag de la imagen en ECR | `v${VERSION}` |
| `image:` de `k8s/deployment.yaml` | `sed` desde `release.sh` |

## Desde Jenkins

Job parametrizado con `BUMP` (`patch`/`minor`/`major`). Necesita dos credenciales:
`aws-ecr-credentials` (Access Key / Secret) y `github-credentials` (usuario / token).

## Endpoints

| Ruta | Respuesta |
|---|---|
| `/` | Dashboard HTML (lee la version de `/api/info`) |
| `/health` | `healthy` — usado por el `HEALTHCHECK` |
| `/api/info` | `{"application":"cloud-dashboard","version":"1.0.0","status":"running"}` |

## Probar en local

```bash
docker build --build-arg APP_VERSION="$(cat VERSION)" -t cloud-dashboard:dev .
docker run --rm -p 8080:80 cloud-dashboard:dev
curl localhost:8080/api/info
```
