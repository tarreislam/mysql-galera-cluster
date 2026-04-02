#!/bin/bash
set -e

# Load environment from .env
export $(grep -v '^#' .env | xargs)

# Set read-only flags dynamically
if [ "$MYSQL_ROLE" = "replica" ]; then
  export READ_ONLY=ON
  export SUPER_READ_ONLY=ON
else
  export READ_ONLY=OFF
  export SUPER_READ_ONLY=OFF
fi

# Generate my.cnf
envsubst < /etc/mysql/my.cnf.template > /etc/mysql/my.cnf

# Start MySQL in background
docker-entrypoint.sh mysqld &
PID=$!

# Wait for MySQL to be ready
until mysqladmin ping -h "127.0.0.1" --silent; do
  sleep 1
done

# Role-based replication setup
if [ "$MYSQL_ROLE" = "primary" ]; then
  mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<-EOSQL
    CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY '${REPL_PASSWORD}';
    GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
    FLUSH PRIVILEGES;
EOSQL
fi

if [ "$MYSQL_ROLE" = "replica" ]; then
  mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<-EOSQL
    CHANGE REPLICATION SOURCE TO
      SOURCE_HOST='${PRIMARY_HOST}',
      SOURCE_PORT='${PRIMARY_PORT}',
      SOURCE_USER='repl',
      SOURCE_PASSWORD='${REPL_PASSWORD}',
      SOURCE_AUTO_POSITION=1;
    START REPLICA;
EOSQL
fi

wait $PID