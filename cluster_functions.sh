
# get the hostname of all other Pis on the cluster

function otherpis {
  grep "pi" /etc/hosts | awk '{print $2}' | grep -v $(hostname)
}

# send the same command to all Pis

function clustercmd {
  for pi in $(otherpis); do ssh $pi "$@"; done
  $@
}

# reboot the cluster

function clusterreboot {
  clustercmd sudo shutdown -r now
}

# shutdown the cluster

function clustershutdown {
  clustercmd sudo shutdown now
}

# send the same file to all Pis

function clusterscp {
  for pi in $(otherpis); do
    cat $1 | ssh $pi "sudo tee $1" > /dev/null 2>&1
  done
}

# status of entire cluster nodes except calling node

function clusterstatus {
  sudo nmap -sP 192.168.0.0/24
}

# add all other nodes hostname to ~/.ssh/known_hosts file

function addhosts {
  [ -f /home/pi/.ssh/known_hosts ] && rm /home/pi/.ssh/known_hosts
  for i in $(otherpis);
  do
    NODE="${i: -1}"
    IP=$((100+NODE))
    IPADDR=192.168.0.${IP}
    ssh-keyscan -t ecdsa -H ${IPADDR} >> /home/pi/.ssh/known_hosts
  done
}
