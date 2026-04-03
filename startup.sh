#!/bin/bash
set -e
# Load environment from .env
export $(grep -v '^#' .env | xargs)

# Generate config
touch /etc/mysql/conf.d/10.cnf
touch /etc/mysql/conf.d/11.cnf

envsubst < /etc/mysql/my.cnf.template > /etc/mysql/conf.d/10.cnf
envsubst < /etc/mysql/galera.cnf.template > /etc/mysql/conf.d/11.cnf

# Set up backup cron job
if [ "${BACKUP_ENABLED:-true}" = "true" ]; then
  BACKUP_CRON_SCHEDULE_HOUR="${BACKUP_CRON_SCHEDULE_HOUR:-23}"
  echo "0 $BACKUP_CRON_SCHEDULE_HOUR * * * /backup.sh >> /var/log/backup.log 2>&1" | crontab -
  cron
fi

#Debug?
if [ "$MYSQL_ROLE" = "debug" ]; then
  echo "Debug"
    while true
    do
        :
    done
fi

# Run mariadb
if [ "$MYSQL_ROLE" = "wsrep-new-cluster" ]; then
  echo "Starting new cluster (force safe to start)"
  if [ -f /var/lib/mysql/grastate.dat ]; then
    sed -i 's/^\(safe_to_bootstrap:\s*\).*/\11/' /var/lib/mysql/grastate.dat
  fi
  docker-entrypoint.sh mariadbd --wsrep-new-cluster
else
  echo "Running as joiner"
  rm -f /var/lib/mysql/sst_in_progress
  rm -f /var/lib/mysql/galera.cache
  docker-entrypoint.sh mariadbd
fi