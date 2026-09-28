# Task 4 — Multiples ambientes con Argo CD (sin Kargo)

La misma app (`cloud-dashboard`) desplegada en `dev`, `staging` y `prod`,
cada uno en su namespace y con su propia Application de Argo CD.

```
stack/
├── argocd/            # una Application por ambiente
│   ├── dev.yaml       # auto-sync
│   ├── staging.yaml   # auto-sync
│   └── prod.yaml      # sync manual
├── envs/              # manifiestos por ambiente (solo cambia el tag de la imagen)
│   ├── dev/
│   ├── staging/
│   └── prod/
└── promotion/
    ├── promote.sh     # copia el tag de un ambiente al siguiente
    └── Jenkinsfile    # lo mismo desde Jenkins, con aprobacion para prod
```

## Desplegar

```bash
kubectl apply -f iac/stack/argocd/
kubectl -n argocd get applications          # cloud-dashboard-dev / -staging / -prod
argocd app sync cloud-dashboard-prod        # prod no sincroniza solo
```

## Como se promueve una version

La "version" de cada ambiente es el `image:` de su `envs/<env>/deployment.yaml`.
Promover = cambiar ese tag en git; Argo CD hace el resto.

```
release.sh ──> ECR v1.0.1 ──> envs/dev ──> envs/staging ──> envs/prod
                              (auto)       (auto)           (sync manual)
```

1. **Nueva version a dev** — despues de `app/release.sh`, apuntar dev al tag nuevo:
   ```bash
   sed -i "s|cloud-dashboard:v[0-9.]*|cloud-dashboard:v1.0.1|" iac/stack/envs/dev/deployment.yaml
   git commit -am "dev: v1.0.1" && git push
   ```
2. **dev -> staging** — `./promotion/promote.sh dev staging` + commit/push.
3. **staging -> prod** — `./promotion/promote.sh staging prod` + commit/push,
   y luego `argocd app sync cloud-dashboard-prod` (o boton Sync en la UI).

## Opciones sin Kargo

| Opcion | Como | Problema |
|---|---|---|
| Manual | Editar el YAML y hacer push | Errores de tipeo, nadie valida que la version paso por staging |
| Script | `promote.sh dev staging` | Mas rapido, pero depende de quien lo corre y de su maquina |
| Pipeline CI | `promotion/Jenkinsfile` con `input` para prod | Hay historial y aprobacion, pero Jenkins no sabe si dev/staging estan *Healthy* en Argo CD |

## Retos que Kargo resuelve

- **No hay registro de que se probo**: nada impide mandar a prod una version que nunca estuvo en staging.
- **Salud no verificada**: el script/pipeline promueve aunque la app en staging este `Degraded`.
- **Logica de promocion dispersa**: `sed`, scripts y pipelines por ambiente que hay que mantener.
- **Rollback manual**: hay que buscar el tag anterior en el historial de git y promoverlo a mano.
- **Sin vista global**: para saber que version corre en cada ambiente hay que revisar tres archivos o tres apps.
- **Credenciales de git en el CI**: Jenkins necesita permiso de push al repo para promover.

Kargo modela esto como *Warehouse* (detecta nuevas imagenes en ECR), *Freight*
(la version a promover) y *Stages* (dev/staging/prod) que solo aceptan Freight
verificado en el Stage anterior.
