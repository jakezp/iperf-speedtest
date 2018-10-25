# iperf Speedtest

iperf and speedtest.net speedtest configured to run at 00:00, 09:00 and 21:00 with pushover.net notifications

Run with:
```
docker run -d --name='iperf-speedtest' --net='bridge' \
      -v '/tmp/base/cron':'/var/spool/cron/crontabs/' \
      jakezp/iperf-speedtest
```

###Require:

Remote server with iperf3 running in server mode:
```
iperf3 -s
```

Pushover.net account and applilcation configured. 

###Details:
Edit /tmp/cron/root with hostname, test duration in seconds, pushover token and user id.
```
/speedtest.sh iperf.hostname.com 10 pushover-token pushover-user
```
