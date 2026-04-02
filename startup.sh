#!/bin/bash
set -e
# Load environment from .env
export $(grep -v '^#' .env | xargs)
# Generate config
touch /etc/mysql/conf.d/10.cnf
envsubst < /etc/mysql/my.cnf.template > /etc/mysql/conf.d/10.cnf

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