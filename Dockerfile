FROM mysql:8.4

RUN apt-get update && apt-get install -y gettext-base && rm -rf /var/lib/apt/lists/*

COPY my.cnf.template /etc/mysql/my.cnf.template
COPY startup.sh /startup.sh

RUN chmod +x /startup.sh

ENTRYPOINT ["/startup.sh"]