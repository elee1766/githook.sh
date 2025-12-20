# Build stage
FROM alpine:3.19 AS builder

RUN apk add --no-cache make coreutils m4

WORKDIR /build
COPY src/ src/
COPY site/src/ site/src/
COPY Makefile .

RUN make build

# Runtime stage
FROM caddy:2-alpine

COPY --from=builder /build/site/dist/ /srv/site/
COPY --from=builder /build/.githook.sh /srv/site/githook.sh
COPY site/Caddyfile /etc/caddy/Caddyfile

EXPOSE 80

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
