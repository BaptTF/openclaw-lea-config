FROM alpine:3.21

RUN apk add --no-cache openvpn iproute2 lzo build-base git && \
    git clone --depth 1 https://github.com/rofl0r/microsocks.git /tmp/microsocks && \
    cd /tmp/microsocks && make && cp microsocks /usr/local/bin/ && \
    apk del build-base git && rm -rf /tmp/microsocks

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
