#!/bin/bash

export TZ

# Configure cron
if [[ ! -f /var/spool/cron/crontabs/root ]]; then
  mv /crontab /var/spool/cron/crontabs/root
fi
touch /etc/crontab /etc/cron.d/* /var/spool/cron/crontabs/* /var/log/cron.log
chmod 0600 /var/spool/cron/crontabs/root

# Use supervisord to start all processes
echo -e "Starting supervisord"
supervisord -c /etc/supervisor/conf.d/supervisord.conf
