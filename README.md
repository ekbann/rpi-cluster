# rpi-cluster
Bash script to automatically configure a cluster of fresh Debian Netinst (or Raspberry Pi OS Lite) nodes.

Based on https://dev.to/awwsmm/building-a-raspberry-pi-hadoop-spark-cluster-8b2

ToDo:
- allow user to specify network address range rather than the fixed 192.168.0.1xx
- script should detect the next available IP address and avoid user input:
  ping -c 1 127.0.0.1 &> /dev/null && echo success || echo fail
- install OS, install script, configure script, clone mSD, & boot each node one at a time
