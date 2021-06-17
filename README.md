# rpi-cluster
Bash script to automatically configure a cluster of fresh Raspberry Pi OS Lite nodes. Based on https://dev.to/awwsmm/building-a-raspberry-pi-hadoop-spark-cluster-8b2


If using x86 Debian netinst, install as follows:

      install using "raspberrypi" as hostname
      add user "pi" with password "raspberry"
      install packages: ssh and standard utilities

Once Linux is installed, login as root and run the commands below:

      apt install sudo
      usermod -aG sudo pi
      reboot

ToDo:

- allow user to specify network address range rather than the fixed 192.168.0.1xx
- script should detect the next available IP address and avoid user input using something like this:

      ping -c 1 127.0.0.1 &> /dev/null && echo success || echo fail

- install OS, install script, configure script, clone mSD, & boot each node one at a time
