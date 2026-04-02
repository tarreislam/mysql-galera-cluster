FROM debian:bookworm-slim AS builder

RUN apt-get update && \
    apt-get install -y gettext && \
    rm -rf /var/lib/apt/lists/*

FROM mariadb:12
COPY --from=builder /usr/bin/envsubst /usr/bin/envsubst

COPY my.cnf.template /etc/mysql/my.cnf.template
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

COPY .env /.env

CMD ["/startup.sh"]