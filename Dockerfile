FROM debian:bookworm-slim AS builder

RUN apt-get update && \
    apt-get install -y gettext && \
    rm -rf /var/lib/apt/lists/*

FROM mariadb:12
ENV TZ=Europe/Stockholm
COPY --from=builder /usr/bin/envsubst /usr/bin/envsubst

RUN apt-get update && \
    apt-get install -y cron && \
    rm -rf /var/lib/apt/lists/*

COPY my.cnf.template /etc/mysql/my.cnf.template
COPY galera.cnf.template /etc/mysql/galera.cnf.template

COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

COPY backup.sh /backup.sh
RUN chmod +x /backup.sh

COPY .env /.env

CMD ["/startup.sh"]