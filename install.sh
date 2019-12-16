#!/bin/bash
# Simple Dante Socks5 Script for Debian
# Script by Bonveio
# https://github.com/Bonveio/BonvScripts
#

function YourBanner(){
# Edit nyo to
 echo -e " Welcome to my Script"
 echo -e " SOCKS5 Server Installer for Debian"
 echo -e " Script by Bonveio"
 echo -e " This script is open for Remodification and Redistribution"
 echo -e ""
}

source /etc/os-release
if [[ "$ID" != 'debian' ]]; then
 YourBanner
 echo -e "[\e[1;31mError\e[0m] This script is for Debian Machine only, exting..." 
 exit 1
fi

if [[ $EUID -ne 0 ]];then
 YourBanner
 echo -e "[\e[1;31mError\e[0m] This script must be run as root, exiting..."
 exit 1
fi

function Installation(){
 cd /root
 export DEBIAN_FRONTEND=noninteractive
 apt-get update
 apt-get upgrade -y
 apt-get install wget nano dante-server netcat -y &> /dev/null | echo '[*] Installing SOCKS5 Server...'
 cat <<'EOF'> /etc/danted.conf
logoutput: /var/log/socks.log
internal: 0.0.0.0 port = SOCKSPORT
external: SOCKSINET
socksmethod: SOCKSAUTH
user.privileged: root
user.notprivileged: nobody

client pass {
 from: 0.0.0.0/0 to: 0.0.0.0/0
 log: error connect disconnect
 }
 
client block {
 from: 0.0.0.0/0 to: 0.0.0.0/0
 log: connect error
 }
 
socks pass {
 from: 0.0.0.0/0 to: 0.0.0.0/0
 log: error connect disconnect
 }
 
socks block {
 from: 0.0.0.0/0 to: 0.0.0.0/0
 log: connect error
 }
EOF
 sed -i "s/SOCKSINET/$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)/g" /etc/danted.conf
 sed -i "s/SOCKSPORT/$SOCKSPORT/g" /etc/danted.conf
 sed -i "s/SOCKSAUTH/$SOCKSAUTH/g" /etc/danted.conf
 sed -i '/\/bin\/false/d' /etc/shells
 echo '/bin/false' >> /etc/shells
 systemctl restart danted.service
 systemctl enable danted.service
}
 
function Uninstallation(){
 echo -e '[*] Uninstalling SOCKS5 Server'
 apt-get remove --purge dante-server &> /dev/null
 rm -rf /etc/danted.conf
 echo -e '[√] SOCKS5 Server successfully uninstalled and removed.'
}

function SuccessMessage(){
 clear
 echo -e ""
 YourBanner
 echo -e ""
 echo -e "== Success installed SOCKS5 Server into your VPS =="
 echo -e ""
 echo -e " Your SOCKS5 Proxy IP Address: $(wget -4qO- http://ipinfo.io/ip)"
 echo -e " Your SOCKS5 Proxy Port: $SOCKSPORT"
 if [ "$SOCKSAUTH" == 'username' ]; then
 echo -e " Your SOCKS5 Authentication:"
 echo -e " SOCKS5 Username: $socksUser"
 echo -e " SOCKS5 Password: $socksPass"
 fi
 echo -e " Install.txt can be found at /root/socks5.txt"
 cat <<EOF> ~/socks5.txt
==Your SOCKS5 Proxy Information==
IP Address: $(wget -4qO- http://ipinfo.io/ip)
Port: $SOCKSPORT
EOF
 if [ "$SOCKSAUTH" == 'username' ]; then
 cat <<EOF>> ~/socks5.txt
Username: $socksUser
Password: $socksPass
EOF
 fi
 cat ~/socks5.txt | nc termbin.com 9999 > /tmp/walwal.txt
 echo -e " Your SOCKS5 Information Online: $(tr -d '\0' </tmp/walwal.txt)"
 echo -e ""
}

clear
YourBanner
echo -e " To exit the script, kindly Press \e[1;32mCRTL\e[0m key together with \e[1;32mC\e[0m"
echo -e ""
echo -e " Choose SOCKS5 Proxy Type"
echo -e " [1] Public Proxy (Can be Accessible by Anyone in the Internet)"
echo -e " [2] Private Proxy (Can be Accessable using username and password Authentication"
echo -e " [3] Uninstall SOCKS5 Proxy Server"
until [[ "$opts" =~ ^[1-3]$ ]]; do
	read -rp " Choose from [1-3]: " -e opts
	done

	case $opts in
	1)
	until [[ "$SOCKSPORT" =~ ^[0-9]+$ ]] && [ "$SOCKSPORT" -ge 1 ] && [ "$SOCKSPORT" -le 65535 ]; do
	read -rp " Choose your SOCKS5 Port [1-65535]: " -i 2408 -e SOCKSPORT
	done
	SOCKSAUTH='none'
	Installation
	;;
	2)
	until [[ "$SOCKSPORT" =~ ^[0-9]+$ ]] && [ "$SOCKSPORT" -ge 1 ] && [ "$SOCKSPORT" -le 65535 ]; do
	read -rp " Choose your SOCKS5 Port [1-65535]: " -i 2408 -e SOCKSPORT
	done
	SOCKSAUTH='username'
	until [[ "$socksUser" =~ ^[a-zA-Z0-9_]+$ ]]; do
	read -rp " Your SOCKS5 Username: " -e socksUser
	done
	until [[ "$socksPass" =~ ^[a-zA-Z0-9_]+$ ]]; do
	read -rp " Your SOCKS5 Password: " -e socksPass
	done
	userdel -r -f $socksUser &> /dev/null
	useradd -m -s /bin/false $socksUser
	echo -e "$socksPass\n$socksPass\n" | passwd $socksUser &> /dev/null
	Installation
	;;
	3)
	Uninstallation
	exit 1
	;;
esac
SuccessMessage
exit 1
