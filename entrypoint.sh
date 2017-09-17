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

  # Configure SSL
  # Change TLS/SSL dirs in default config and generate default certs
  sed -i -e "s,^ssl_cert =.*,ssl_cert = </etc/pki/dovecot/certs/server.pem," /etc/dovecot/conf.d/10-ssl.conf
  sed -i -e "s,^ssl_key =.*,ssl_key = </etc/pki/dovecot/certs/server.key," /etc/dovecot/conf.d/10-ssl.conf
  sed -i -e "s,^ssl =.*,ssl = required," /etc/dovecot/conf.d/10-ssl.conf 

  openssl req -new -x509 -nodes -days 365 -config /etc/pki/dovecot/dovecot-openssl.cnf -out /etc/pki/dovecot/certs/server.pem -keyout /etc/pki/dovecot/certs/server.key

  chmod 0600 /etc/pki/dovecot/certs/server.key

  # Tweak TLS/SSL settings to achieve A grade
  sed -i -e "s,^#ssl_prefer_server_ciphers =.*,ssl_prefer_server_ciphers = yes," /etc/dovecot/conf.d/10-ssl.conf
  sed -i -e "s,^#ssl_cipher_list =.*,ssl_cipher_list = ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:!DSS," /etc/dovecot/conf.d/10-ssl.conf
  sed -i -e "s,^#ssl_protocols =.*,ssl_protocols = !SSLv3," /etc/dovecot/conf.d/10-ssl.conf
  sed -i -e "s,^#ssl_dh_parameters_length =.*,ssl_dh_parameters_length = 2048," /etc/dovecot/conf.d/10-ssl.conf

  # Pregenerate Diffie-Hellman parameters (heavy operation) # to not consume time at container start
  mkdir -p /var/lib/dovecot
  /usr/libexec/dovecot/ssl-params
 
  sed -i -e "s,#protocols,protocols," /etc/dovecot/dovecot.conf
  sed -i -e "s,#listen,listen," /etc/dovecot/dovecot.conf
  sed -i -e "s,#login_greeting,login_greeting," /etc/dovecot/dovecot.conf
  sed -i -e "s,#shutdown_clients,shutdown_clients," /etc/dovecot/dovecot.conf
}

start_dovecot() {
  # Run dovecot
  exec /usr/sbin/dovecot -c /etc/dovecot/dovecot.conf -F
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
    wait_for_mysql
    init_config
    start_dovecot
    ;;
  app:init)
    ;;
  app:update)
    ;;
  *)
    init_config
    exec "$@"
    ;;
esac
