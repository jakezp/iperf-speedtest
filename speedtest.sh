#!/bin/bash
hostname=$1
duration=$2
token=$3
user=$4
minihost=$5
#----------------------------

received=$(iperf3 -c $hostname -P 10 -t $duration -R -J | jq -r '.end.sum_received.bits_per_second')
sent=$(iperf3 -c $hostname -P 10 -t $duration -J | jq -r '.end.sum_sent.bits_per_second')
ping=$(ping -c 4 $hostname | awk -F '/' 'END {print $5}')
jitter=$(iperf3 -c $hostname -u -t 5 -J | jq -r '.end.sum.jitter_ms')

echo -e "Results:" | tee /tmp/results.tmp

# iperf tests
nc -vz $hostname 5201 -w 1 >/dev/null 2>&1
if [[ ! $? == 0 ]]; then
  echo -e iperf host down
  echo -e " "
  curl -s -F "token=$token" -F "user=$user" -F "title=iperf server down" -F "message=iperf server - $hostname is down. Investigate..." https://api.pushover.net/1/messages.json  >/dev/null 2>&1
else
  echo -e iperf results - $hostname: | tee -a /tmp/results.tmp
  echo -e Download speed: $(bc <<< "scale=2;$received/1024/1024") Mbps | tee -a /tmp/results.tmp
  echo -e Upload speed: $(bc <<< "scale=2;$sent/1024/1024") Mbps | tee -a /tmp/results.tmp
  echo -e Latency: $ping ms | tee -a /tmp/results.tmp
  echo -e Jitter: $jitter ms | tee -a /tmp/results.tmp
  echo -e " " | tee -a /tmp/results.tmp
fi

# speedtest tests
speedtest="$(speedtest-cli --json --share)"
speed_host=$(echo $speedtest | jq -r '.server.sponsor')
speed_down=$(echo $speedtest | jq -r '.download')
speed_up=$(echo $speedtest | jq -r '.upload')
speed_latency=$(echo $speedtest | jq -r '.ping')
speed_share=$(echo $speedtest | jq -r '.share')

echo -e speedtest results - $speed_host: | tee -a /tmp/results.tmp
echo -e Download speed: $(bc <<< "scale=2;$speed_down/1024/1024") Mbps | tee -a /tmp/results.tmp
echo -e Upload speed: $(bc <<< "scale=2;$speed_up/1024/1024") Mbps | tee -a /tmp/results.tmp
echo -e Latency: $speed_latency ms | tee -a /tmp/results.tmp
echo -e Share: $speed_share | tee -a /tmp/results.tmp
echo -e " " | tee -a /tmp/results.tmp

# speedtest mini server - optional
if [[ -n $minihost ]]; then
  mini_speedtest="$(speedtest-cli --json --mini $minihost)"
  mini_speed_host=$(echo $mini_speedtest | jq -r '.server.name')
  mini_speed_down=$(echo $mini_speedtest | jq -r '.download')
  mini_speed_up=$(echo $mini_speedtest | jq -r '.upload')
  mini_speed_latency=$(echo $mini_speedtest | jq -r '.ping')

  echo -e mini-speedtest results - $mini_speed_host: | tee -a /tmp/results.tmp
  echo -e Download speed: $(bc <<< "scale=2;$mini_speed_down/1024/1024") Mbps | tee -a /tmp/results.tmp
  echo -e Upload speed: $(bc <<< "scale=2;$mini_speed_up/1024/1024") Mbps | tee -a /tmp/results.tmp
  echo -e Latency: $mini_speed_latency ms | tee -a /tmp/results.tmp
  echo -e " " | tee -a /tmp/results.tmp
fi

echo -e "Test date: $(echo $speedtest | jq -r '.timestamp')"  | tee -a /tmp/results.tmp
curl -s -F "token=$token" -F "user=$user" -F "title=Speedtest results" -F "message=$(cat /tmp/results.tmp)" https://api.pushover.net/1/messages.json  >/dev/null 2>&1
rm /tmp/results.tmp
