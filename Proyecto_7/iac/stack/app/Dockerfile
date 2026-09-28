FROM nginx:1.27-alpine

# La version llega desde el archivo VERSION via build-and-push.sh:
#   docker build --build-arg APP_VERSION="$(cat VERSION)" .
ARG APP_VERSION=0.0.0-dev

LABEL maintainer="dnunez-aquaware"
LABEL description="Cloud Infrastructure Dashboard"
LABEL version="${APP_VERSION}"

ENV APP_NAME="cloud-dashboard" \
    APP_VERSION="${APP_VERSION}"

RUN rm -rf /usr/share/nginx/html/*

COPY html/ /usr/share/nginx/html/

# El entrypoint oficial de nginx corre envsubst sobre /etc/nginx/templates/*.template
# y escribe el resultado en /etc/nginx/conf.d/ al arrancar el contenedor, asi que
# ${APP_NAME} y ${APP_VERSION} quedan resueltos sin tocar el archivo a mano.
COPY nginx.conf.template /etc/nginx/templates/default.conf.template

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1/health || exit 1

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
