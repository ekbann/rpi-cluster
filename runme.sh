#!/bin/bash
echo ===============================================================
echo Raspberry Pi Hadoop/Spark Cluster Creator: Create Cluster Nodes
echo ===============================================================
echo
echo 'Please UPDATE and UPGRADE your system before running this script:'
echo 'sudo apt-get -y update && sudo apt-get -y upgrade && sudo reboot'
echo

if [ "$(id -u)" -ne 0 ]; then
	echo 'This script must be run as ROOT.'
	echo 'e.g. sudo ./runme.sh'
	echo 'e.g. su'
	exit 1
fi

# Ask user for cluster SIZE and current NODE number
read -p 'Enter TOTAL number of nodes in the cluster: ' TOTAL
read -p 'Enter NODE number of this Raspberry Pi: ' NUM
echo

# Check if user pi exists

echo '>>> Checking for user pi.'
id -u pi &> /dev/null
if [ $? -eq 0 ]; then
	echo '  + User pi found.'
else
	echo '  + User pi not found. Creating user=pi, password=raspberry.'
	useradd -m -p $(openssl passwd -1 raspberry) pi
	# -m: create home directory if doesn't exist
fi

# Install SUDO for BASHRC cluster commands.

echo '>>> Checking for SUDO.'
dpkg -s sudo &> /dev/null
if [ $? -eq 0 ]; then
	echo '  + Found. SUDO already installed.'	# Raspbian has by default
else
	echo '  + Not found, installing SUDO.'		# x86 doesn't have by default
	apt-get -y install sudo > /dev/null
	# Add user pi to sudoers
	echo 'pi	ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
fi

# Determine the ETHERNET interface name, e.g. eth0 or enp1s0
IFNAME="$(ls /sys/class/net | grep ^e)"
echo '>>> Ethernet Interface Name:' ${IFNAME}

# Configure Static IP Address
IP=$((100+NUM))
echo '>>> Configuring Static IP Address:' 192.168.0.${IP}/24

# Check if DHCPCD is running/exited/dead

echo '>>> Checking to see if DHCPCD daemon is running.'
RES=$(systemctl show -p SubState --value dhcpcd)


if [ "$RES" = "running" ]; then
	# ... using DHCPCD (DHCP Client Daemon). Raspbian default.
	echo '  + DHCPCD daemon present.'
	echo 'interface '${IFNAME} >> /etc/dhcpcd.conf
	echo 'static ip_address=192.168.0.'${IP}'/24' >> /etc/dhcpcd.conf
else
	# ... using /etc/network/interfaces. x86 default
	echo '  + DHCPCD daemon not present, using INTERFACES.'
	sed -i /$IFNAME/s/^/#/ /etc/network/interfaces		# Comment out ETHERNET interface
	echo 'auto '${IFNAME} >> /etc/network/interfaces
	echo 'iface '${IFNAME}' inet static' >> /etc/network/interfaces
	echo '    address 192.168.0.'${IP}'/24' >> /etc/network/interfaces
	#echo '    gateway 192.168.0.1' >> /etc/network/interfaces
fi

# Install NMAP for cluster status using:
# sudo nmap -sP 192.168.0.0/24

echo '>>> Checking for NMAP.'
dpkg -s nmap &> /dev/null
if [ $? -eq 0 ]; then
	echo '  + Found. NMAP already installed.'
else
	echo '  + Not found, installing NMAP.'
	apt-get -y install nmap > /dev/null
fi

# Check if SSH is running/exited/dead

echo '>>> Checking to see if SSH server is running.'
RES=$(sudo systemctl show -p SubState --value ssh)

# Enable SSH daemon for remote login

if [ "$RES" = "running" ]; then
	echo '  + SSH daemon is already running.'
else
	echo '  + SSH daemon not running, starting SSH.'
	systemctl enable ssh
	systemctl start ssh
fi

# Define unique hostnames for each node: piX, where X is node number

echo '>>> Renaming HOSTNAME to pi'"$NUM"'.'
sed -i -e s/raspberrypi/pi${NUM}/g /etc/hostname
sed -i -e s/raspberrypi/pi${NUM}/g /etc/hosts

echo '>>> Adding all cluster nodes HOSTNAME to HOSTS.' 
for i in `seq 1 ${TOTAL}`;
do
	IP=$((100+i))
	IPADDR=192.168.0.${IP}
	HOST=pi${i}
	echo ${IPADDR} ${HOST} >> /etc/hosts
done

# Check for .ssh directory

echo '>>> Checking for ~/.ssh directory.'
if [ -d "${HOME}/.ssh" ]; then
	echo '  + Found.'
else
	echo '  + Not found, creating .ssh.'
	mkdir -m 700 /home/pi/.ssh
	chown pi:pi /home/pi/.ssh
fi

# Setup SSH alias

echo '>>> Setting up SSH ALIAS.'
for i in `seq 1 ${TOTAL}`;
do
	IP=$((100+i))
	IPADDR=192.168.0.${IP}
	HOST=pi${i}
	echo 'Host' ${HOST} >> /home/pi/.ssh/config
	echo 'User pi' >> /home/pi/.ssh/config
	echo 'Hostname' ${IPADDR} >> /home/pi/.ssh/config
done
chown pi:pi /home/pi/.ssh/config
chmod 600 /home/pi/.ssh/config

# Setup public/private KEY PAIRS using a MASTERKEY
#
# Masterkey was generated without a passphrase (unencrypted/unsafe)
#
# ssh-keygen -t ed25519 -C 'masterkey'
# (private and public keys are stored in ~/.ssh)
#
# The last field in a public key is a comment (usually user@hostname)
# but there's no user information stored in SSH keys, so we can use ONE
# key for all NODES in order to configure password-less authentication
# between them. This allows for easy setup, but later each node should
# have its own uniquely generated key.

# Private key:
echo '>>> Setting up ssh masterkey for password-less authentication.'
echo '  + Adding PRIVATE key.' 
cat ./id_ed25519 > /home/pi/.ssh/id_ed25519
chown pi:pi /home/pi/.ssh/id_ed25519
chmod 600 /home/pi/.ssh/id_ed25519

# Public key
echo '  + Adding PUBLIC key.' 
cat ./id_ed25519.pub > /home/pi/.ssh/authorized_keys
chown pi:pi /home/pi/.ssh/authorized_keys
chmod 600 /home/pi/.ssh/authorized_keys

# Setup cluster commands in ~/.bashrc

echo '>>> Setting up cluster commands in .bashrc.'
cat ./cluster_functions.sh >> /home/pi/.bashrc

echo '>>> Finished. Please REBOOT for changes to take effect.'
