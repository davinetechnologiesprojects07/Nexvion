FROM nginxinc/nginx-unprivileged:1.27-alpine

# Apply available Alpine security patches to the base image
USER root
RUN apk upgrade --no-cache
USER 101

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY app/ /usr/share/nginx/html/

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/healthz || exit 1
