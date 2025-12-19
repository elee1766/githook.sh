# Build stage
FROM alpine:3.19 AS builder

RUN apk add --no-cache make coreutils

WORKDIR /build
COPY src/ src/
COPY Makefile .

RUN make build

# Runtime stage
FROM caddy:2-alpine

COPY site/ /srv/site/
COPY --from=builder /build/.githook.sh /srv/site/githook.sh
COPY Caddyfile /etc/caddy/Caddyfile

EXPOSE 80

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
