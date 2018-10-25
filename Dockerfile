FROM ubuntu:latest

MAINTAINER jakezp@gmail.com

ENV DEBIAN_FRONTEND noninteractive

# Update and install packages
RUN apt-get update && apt-get upgrade -yq && apt-get install supervisor iperf3 cron bc iputils-ping netcat jq curl speedtest-cli -yq

# Add config files
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD crontab /crontab
ADD run.sh /run.sh
ADD speedtest.sh /speedtest.sh

# Set permissions
RUN chmod +x /run.sh /speedtest.sh

# Expose volumes & ports
VOLUME ["/var/spool/cron/crontabs"]
# EXPOSE 80 443

WORKDIR /
CMD ["/run.sh"]
