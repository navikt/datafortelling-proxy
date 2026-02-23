FROM haproxy:3.3.4-alpine3.23

USER root

RUN apk --no-cache add ca-certificates \
  && update-ca-certificates

USER haproxy

ADD haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]