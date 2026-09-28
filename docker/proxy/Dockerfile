FROM alpine:3
RUN apk add --no-cache tinyproxy
COPY tinyproxy.conf allowlist.txt /etc/tinyproxy/
EXPOSE 8888
CMD ["tinyproxy", "-d", "-c", "/etc/tinyproxy/tinyproxy.conf"]
