# iperf Speedtest

iperf and speedtest.net speedtest configured to run at 00:00, 09:00 and 21:00 with pushover.net notifications

Run with:
```
docker run -d --name='iperf-speedtest' --net='bridge' \
      -v '/tmp/iperf-speedtest/cron':'/var/spool/cron/crontabs/' \
      -v '/tmp/iperf-speedtest/config':'/root/' \
      jakezp/iperf-speedtest
```

### Require:

Remote server with iperf3 running in server mode:
```
iperf3 -s
```
Pushover.net account and applilcation configured. 
Telegram bot

### Details:
Edit /tmp/cron/root:
```
* * * * * /speedtest.sh iperf.hostname.com 10 pushover-token pushover-user
* * * * * /alt_speedtest.sh iperf.hostname.com iperf2.hostname.com
```
#### Scripts
*2 versions of the speedtest scripts are include:*<br>
speedtest.sh - enter iperf hostname, duration to run, pushover-token and pushoer-user keys in line
alt_speedtest.sh - enter multiple iperf hosts. speedtest.net will run against auto selected server as well as Vodacom (South Africa) server and a mini server. Results will be posted to a Telegram chat room (A telegram bot is required)<br><br>

Move the /speedtest_config.sample to /tmp/iperf-speedtest/config (/root), rename it to speedtest_config and update it with pushover and telegram details.
