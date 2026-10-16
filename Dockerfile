FROM haproxy:3.4.6-alpine3.24

USER root

RUN apk --no-cache add ca-certificates \
  && update-ca-certificates

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY gcp-auth.lua /usr/local/etc/haproxy/gcp-auth.lua

USER haproxy

CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
