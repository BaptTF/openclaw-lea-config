FROM alpine:3.21

RUN apk add --no-cache openvpn iproute2 lzo tinyproxy

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8888

ENTRYPOINT ["/entrypoint.sh"]
