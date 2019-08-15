#!/bin/bash
source /root/speedtest_config

# create results directory
if [[ ! -d /root/speedtest/results ]]; then
  mkdir -p /root/speedtest/results
fi

# test functions
iperf_receive () {
  download_results=$(date +%Y-%m-%d-%H-%M-%S)-iperf3-$1-download.json
  echo -e "Download (TCP):\niperf3 -4 -V -R -t 5 -O 3 -l 1460 -c $1 -p $2\n" > /root/speedtest/results/$download_results
  iperf3 -4 -V -R -t 5 -O 3 -l 1460 -c $1 -p $2 >> /root/speedtest/results/$download_results
}

iperf_send () {
  upload_results=$(date +%Y-%m-%d-%H-%M-%S)-iperf3-$1-upload.json
  echo -e "Upload (TCP):\niperf3 -4 -V -t 5 -O 3 -l 1460 -c $1 -p $2\n" > /root/speedtest/results/$upload_results
  iperf3 -4 -V -t 5 -O 3 -l 1460 -c $1 -p $2 >> /root/speedtest/results/$upload_results
}

iperf_packet_loss () {
  packet_loss_results=$(date +%Y-%m-%d-%H-%M-%S)-iperf3-$1-packet_loss.json
  echo -e "Packet Loss (UDP):\niperf3 -4 -V -R -t 10 -O 3 -u -b 80M -l 1440 -c $1 -p $2\n" > /root/speedtest/results/$packet_loss_results
  iperf3 -4 -V -R -t 10 -O 3 -u -b 80M -l 1460 -c $1 -p $2 >> /root/speedtest/results/$packet_loss_results
}

for hostname in $*; do
  if [[ $hostname == emoncms.jakezp.co.za ]]; then
    port=5201
  else
# elif [[ $hostname == iperf.atomic.ac ]]; then
    port=3334
  fi
  nc -vz $hostname $port -w 1 >/dev/null 2>&1
  if [[ ! $? == 0 ]]; then
    echo -e "iperf host - $hostname is down. skipping test..."
    curl -s "${url}/sendMessage?chat_id=${chat_id}" --data-urlencode "text=iperf host - $hostname is down. skipping test..."
    echo -e " "
    curl -s -F "token=$pushtoken" -F "user=$pushuser" -F "title=iperf server is down" -F "message=iperf server - $hostname is down. Investigate..." https://api.pushover.net/1/messages.json  >/dev/null 2>&1
    exit 1
  else
    iperf_receive $hostname $port
    iperf_send $hostname $port
    iperf_packet_loss $hostname $port
    curl -s "${url}/sendMessage?chat_id=${chat_id}" --data-urlencode "text=$(cat /root/speedtest/results/$download_results)"
    curl -s "${url}/sendMessage?chat_id=${chat_id}" --data-urlencode "text=$(cat /root/speedtest/results/$upload_results)"
    curl -s "${url}/sendMessage?chat_id=${chat_id}" --data-urlencode "text=$(cat /root/speedtest/results/$packet_loss_results)"
  fi
done
