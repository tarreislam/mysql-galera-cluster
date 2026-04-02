FROM debian:bookworm-slim AS builder

RUN apt-get update && \
    apt-get install -y gettext && \
    rm -rf /var/lib/apt/lists/*

FROM mysql:8.4
COPY --from=builder /usr/bin/envsubst /usr/bin/envsubst

COPY my.cnf.template /etc/mysql/my.cnf.template
COPY startup.sh /startup.sh
COPY .env /.env

RUN chmod +x /startup.sh

ENTRYPOINT ["/startup.sh"]