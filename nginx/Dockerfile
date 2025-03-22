FROM nginx:alpine

COPY conf/default.conf /etc/nginx/conf.d/
COPY conf/nginx.conf /etc/nginx/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD nginx -t || exit 1 