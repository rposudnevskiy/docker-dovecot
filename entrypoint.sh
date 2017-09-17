#!/bin/bash
set -e

export MYSQL_HOST
export MYSQL_USER
export MYSQL_PASSWORD
export MYSQL_DATABASE

MYSQL_HOST=${MYSQL_HOST:-dovecot}
MYSQL_USER=${MYSQL_USER:-dovecot}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-dovecot}
MYSQL_DATABASE=${MYSQL_DATABASE:-dovecot}

wait_for_mysql() {
  until mysql --host=$MYSQL_HOST --user=$MYSQL_USER --password=$MYSQL_PASSWORD --execute="USE $MYSQL_DATABASE;" &>/dev/null; do
    echo "waiting for mysql to start..."
    sleep 2
  done
}

init_config() {
  echo "[INFO] Prepare basic configuration"
  
  # Configure MYSQL connection
  sed -i -e "s,#MYSQL_HOST#,$MYSQL_HOST," /etc/dovecot/dovecot-sql.conf.ext
  sed -i -e "s,#MYSQL_USER#,$MYSQL_USER," /etc/dovecot/dovecot-sql.conf.ext
  sed -i -e "s,#MYSQL_PASSWORD#,$MYSQL_PASSWORD," /etc/dovecot/dovecot-sql.conf.ext
  sed -i -e "s,#MYSQL_DATABASE#,$MYSQL_DATABASE," /etc/dovecot/dovecot-sql.conf.ext

  # Configure authentication
  sed -i -e "s,\!include auth-system.conf.ext,#\!include auth-system.conf.ext," /etc/dovecot/conf.d/10-auth.conf
  sed -i -e "s,#\!include auth-sql.conf.ext,\!include auth-sql.conf.ext," /etc/dovecot/conf.d/10-auth.conf
  sed -i -e "s,auth_mechanisms = plain,auth_mechanisms = plain login cram-md5," /etc/dovecot/conf.d/10-auth.conf
 
  sed -i -e "s,#protocols,protocols," /etc/dovecot/dovecot.conf
  sed -i -e "s,#listen,listen," /etc/dovecot/dovecot.conf
  sed -i -e "s,#login_greeting,login_greeting," /etc/dovecot/dovecot.conf
  sed -i -e "s,#shutdown_clients,shutdown_clients," /etc/dovecot/dovecot.conf
}

case ${1} in
  app:help)
    echo "Available options:"
    echo " app:start        - Starts the roundcube server (default)"
    echo " app:init         - Initializes the database"
    echo " app:update       - Updates the config and database"
    echo " app:help         - Displays this help"
    echo " [command]        - Execute the specified command, eg. bash."
    ;;
  app:start)
    ;;
  app:init)
    ;;
  app:update)
    ;;
  *)
    #wait_for_mysql
    init_config
    exec "$@"
    ;;
esac
