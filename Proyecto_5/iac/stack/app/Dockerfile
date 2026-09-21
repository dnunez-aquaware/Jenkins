FROM nginx:1.27-alpine

LABEL maintainer="dnunez-aquaware"
LABEL description="Cloud Infrastructure Dashboard"
LABEL version="1.0.0"

ENV APP_NAME="cloud-dashboard" \
    APP_VERSION="1.0.0"

RUN rm -rf /usr/share/nginx/html/*

COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN nginx -t

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]