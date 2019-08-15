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

iperf_packet_loss () {
  packet_loss_results=$(date +%Y-%m-%d-%H-%M-%S)-iperf3-$1-packet_loss.json
  iperf3 -4 -V -R -t 10 -O 3 -u -b 80M -l 1460 -c $1 -p $2 -J > /root/speedtest/results/$packet_loss_results
}

echo -e "**Results**\n " | tee /tmp/results.tmp

for hostname in $*; do
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
    iperf_packet_loss $hostname $port
    download=$(cat /root/speedtest/results/$download_results | jq -r '.end.sum_received.bits_per_second')
    upload=$(cat /root/speedtest/results/$upload_results | jq -r '.end.sum_sent.bits_per_second')
    total_packets=$(cat /root/speedtest/results/$packet_loss_results | jq -r '.end.sum.packets')
    lost_packets=$(cat /root/speedtest/results/$packet_loss_results | jq -r '.end.sum.lost_packets')
    lost_percent=$(cat /root/speedtest/results/$packet_loss_results | jq -r '.end.sum.lost_percent')
    ping=$(ping -c 4 $hostname | awk -F '/' 'END {print $5}')
    #jitter=$(iperf3 -c $hostname -u -t 5 -J | jq -r '.end.sum.jitter_ms')
    echo -e "$hostname:" | tee -a /tmp/results.tmp
    echo -e "Download speed: $(bc <<< "scale=2;$download/1024/1024") Mbps" | tee -a /tmp/results.tmp
    echo -e "Upload speed: $(bc <<< "scale=2;$upload/1024/1024") Mbps" | tee -a /tmp/results.tmp
    echo -e "Latency: $ping ms" | tee -a /tmp/results.tmp
    echo -e "Packet loss (udp): $lost_packets / $total_packets (${lost_percent}%)" | tee -a /tmp/results.tmp
    echo -e "Date: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a /tmp/results.tmp
    #echo -e Jitter: $jitter ms | tee -a /tmp/results.tmp
    echo -e " " | tee -a /tmp/results.tmp
  fi
done

# send message
curl -s "${url}/sendMessage?chat_id=${chat_id}" --data-urlencode "text=$(cat /tmp/results.tmp)"
rm /tmp/results.tmp
