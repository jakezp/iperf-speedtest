#!/bin/bash
source /root/speedtest_config

# create results directory
if [[ ! -d /root/speedtest/results ]]; then
  mkdir -p /root/speedtest/results
fi

# test functions
iperf_receive () {
  download_results=$(date +%Y-%m-%d-%H-%M-%S)-iperf3-$1-download.json
  iperf3 -4 -V -R -t 5 -O 3 -l 1460 -c $1 -p $2 -J > /root/speedtest/results/$download_results
}

iperf_send () {
  upload_results=$(date +%Y-%m-%d-%H-%M-%S)-iperf3-$1-upload.json
  iperf3 -4 -V -t 5 -O 3 -l 1460 -c $1 -p $2 -J > /root/speedtest/results/$upload_results
}

echo -e "iperf test results:\n " | tee /tmp/results.tmp

for hostname in $*; do
#for hostname in emoncms.jakezp.co.za iperf.atomic.ac; do
  if [[ $hostname == emoncms.jakezp.co.za ]]; then
    port=5201
  elif [[ $hostname == iperf.atomic.ac ]]; then
    port=3334
  fi
  nc -vz $hostname $port -w 1 >/dev/null 2>&1
  if [[ ! $? == 0 ]]; then
    echo -e "iperf host - $hostname is down. skipping test..."
    echo -e " "
    curl -s -F "token=$pushtoken" -F "user=$pushuser" -F "title=iperf server is down" -F "message=iperf server - $hostname is down. Investigate..." https://api.pushover.net/1/messages.json  >/dev/null 2>&1
  else
    iperf_receive $hostname $port
    iperf_send $hostname $port
    download=$(cat /root/speedtest/results/$download_results | jq -r '.end.sum_received.bits_per_second')
    upload=$(cat /root/speedtest/results/$upload_results | jq -r '.end.sum_sent.bits_per_second')
    ping=$(ping -c 4 $hostname | awk -F '/' 'END {print $5}')
    #jitter=$(iperf3 -c $hostname -u -t 5 -J | jq -r '.end.sum.jitter_ms')
    echo -e "$hostname:" | tee -a /tmp/results.tmp
    echo -e "Download speed: $(bc <<< "scale=2;$download/1024/1024") Mbps" | tee -a /tmp/results.tmp
    echo -e "Upload speed: $(bc <<< "scale=2;$upload/1024/1024") Mbps" | tee -a /tmp/results.tmp
    echo -e "Latency: $ping ms" | tee -a /tmp/results.tmp
    echo -e "Date: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a /tmp/results.tmp
    #echo -e Jitter: $jitter ms | tee -a /tmp/results.tmp
    echo -e " " | tee -a /tmp/results.tmp
  fi
done

# send message
curl -s "${url}/sendMessage?chat_id=${chat_id}" --data-urlencode "text=$(cat /tmp/results.tmp)"
rm /tmp/results.tmp

# speedtest tests
# auto
speedtest="$(speedtest-cli --json --share)"
speed_host=$(echo $speedtest | jq -r '.server.sponsor')
speed_down=$(echo $speedtest | jq -r '.download')
speed_up=$(echo $speedtest | jq -r '.upload')
speed_latency=$(echo $speedtest | jq -r '.ping')
speed_share=$(echo $speedtest | jq -r '.share')
echo $speedtest > /root/speedtest/results/$(date +%Y-%m-%d-%H-%M-%S)-speedtest-$(echo $speed_host | sed -e 's/\ /_/g').json

echo -e "speedtest results - $speed_host (auto selected):" | tee -a /tmp/results.tmp
echo -e "Download speed: $(bc <<< "scale=2;$speed_down/1024/1024") Mbps" | tee -a /tmp/results.tmp
echo -e "Upload speed: $(bc <<< "scale=2;$speed_up/1024/1024") Mbps" | tee -a /tmp/results.tmp
echo -e "Latency: $speed_latency ms" | tee -a /tmp/results.tmp
echo -e "Date: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a /tmp/results.tmp
echo -e "Share: $speed_share" | tee -a /tmp/results.tmp
echo -e " " | tee -a /tmp/results.tmp

# send message
curl -s "${url}/sendMessage?chat_id=${chat_id}" --data-urlencode "text=$(cat /tmp/results.tmp)"
rm /tmp/results.tmp

# vodacom - jhb
speedtest="$(speedtest-cli --server 1440 --json --share)"
speed_host=$(echo $speedtest | jq -r '.server.sponsor')
speed_down=$(echo $speedtest | jq -r '.download')
speed_up=$(echo $speedtest | jq -r '.upload')
speed_latency=$(echo $speedtest | jq -r '.ping')
speed_share=$(echo $speedtest | jq -r '.share')
echo $speedtest > /root/speedtest/results/$(date +%Y-%m-%d-%H-%M-%S)-speedtest.net-$speed_host.json

echo -e "speedtest results - $speed_host JHB (manual):" | tee -a /tmp/results.tmp
echo -e "Download speed: $(bc <<< "scale=2;$speed_down/1024/1024") Mbps" | tee -a /tmp/results.tmp
echo -e "Upload speed: $(bc <<< "scale=2;$speed_up/1024/1024") Mbps" | tee -a /tmp/results.tmp
echo -e "Latency: $speed_latency ms" | tee -a /tmp/results.tmp
echo -e "Date: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a /tmp/results.tmp
echo -e "Share: $speed_share" | tee -a /tmp/results.tmp
echo -e " " | tee -a /tmp/results.tmp

# send message
curl -s "${url}/sendMessage?chat_id=${chat_id}" --data-urlencode "text=$(cat /tmp/results.tmp)"
rm /tmp/results.tmp

# speedtest - mybroadband cpt
mini_speedtest="$(speedtest-cli --json --mini http://cptspeedtest.mybroadband.co.za)"
mini_speed_host=$(echo $mini_speedtest | jq -r '.server.name')
mini_speed_down=$(echo $mini_speedtest | jq -r '.download')
mini_speed_up=$(echo $mini_speedtest | jq -r '.upload')
mini_speed_latency=$(echo $mini_speedtest | jq -r '.ping')
echo $mini_speedtest > /root/speedtest/results/$(date +%Y-%m-%d-%H-%M-%S)-mybroadband_cpt.json

echo -e "mybroadband speedtest (CPT):" | tee -a /tmp/results.tmp
echo -e "Download speed: $(bc <<< "scale=2;$mini_speed_down/1024/1024") Mbps" | tee -a /tmp/results.tmp
echo -e "Upload speed: $(bc <<< "scale=2;$mini_speed_up/1024/1024") Mbps" | tee -a /tmp/results.tmp
echo -e "Latency: $mini_speed_latency ms" | tee -a /tmp/results.tmp
echo -e "Date: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a /tmp/results.tmp
echo -e " " | tee -a /tmp/results.tmp

# send message
curl -s "${url}/sendMessage?chat_id=${chat_id}" --data-urlencode "text=$(cat /tmp/results.tmp)"
rm /tmp/results.tmp
