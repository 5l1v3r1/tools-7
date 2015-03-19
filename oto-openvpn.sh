clear 
echo "Install starting. Please enter hostname"
read hostnm

date=`date +%Y%m%d-%H%M`
setupdir=/root/setup
mkdir -p $setupdir
cd $setupdir

apt-get update && apt-get upgrade -y
echo $hostnm > /etc/hostname
echo "127.0.1.1       $hostnm" >> /etc/hosts 

apt-get install -y openvpn openvpn-blacklist eurephia fail2ban iptables-persistent pwgen easy-rsa 
cat /etc/sysctl.conf | sed s/\#net\.ipv4\.ip_forward\=1/net\.ipv4\.ip_forward\=1/g > /tmp/sysctl.conf
mv /tmp/sysctl.conf /etc/sysctl.conf

clear 
echo "Generating SSL keys for OpenVPN. Proceed?"
read


mkdir /etc/openvpn/easy-rsa
cp /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
cd /etc/openvpn/easy-rsa/
cat vars  | sed s/export\ KEY_COUNTRY=\"US\"/export\ KEY_COUNTRY=\"TR\"/g > vars1
cat vars1 | sed s/export\ KEY_PROVINCE=\"CA\"/export\ KEY_PROVINCE=\"TR\"/g > vars2 
cat vars2 | sed s/export\ KEY_CITY=\"SanFrancisco\"/export\ KEY_CITY=\"Istanbul\"/g > vars3
cat vars3 | sed s/export\ KEY_ORG=\"Fort-Funston\"/export\ KEY_ORG=\"Bircan\ Inc\.\"/g > vars4 
cat vars4 | sed s/export\ KEY_EMAIL=\"me\@myhost\.mydomain\"/export\ KEY_EMAIL=\"some\@bircan\.net\"/g > vars5 
cat vars5 | sed s/export\ KEY_OU=\"MyOrganizationalUnit\"/export\ KEY_OU=\"IT\ Department\"/g > vars6
mv vars6 vars 
rm vars[1-5]
source ./vars
./clean-all 
./build-ca 
./build-dh 
./build-key-server openvpn-server 

clear 
echo "Configuring IPTables Rules. Proceed?"
read

cd /etc/iptables
rm rules.v4 
wget https://raw.githubusercontent.com/BahtiyarB/tools/master/rules.v4
service iptables-persistent restart

clear 
echo "Configuring OpenVPN. Proceed?"
read

cd /etc/openvpn/
rm -rf server*.conf 
wget https://raw.githubusercontent.com/BahtiyarB/tools/master/server.443.tcp.conf
wget https://raw.githubusercontent.com/BahtiyarB/tools/master/server.1194.udp.conf

echo "Restarting services" 
service openvpn restart
service iptables-persistent restart
service fail2ban restart

clear 
echo "Generating users and passwords" 
read

cd $setupdir

user1=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32}`
pass1=`pwgen -c -n -y -B -s 32 1 -1`
echo $user1:$pass1 > users-$date.txt
user2=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32}`
pass2=`pwgen -c -n -y -B -s 32 1 -1`
echo $user2:$pass2 >> users-$date.txt
user3=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32}`
pass3=`pwgen -c -n -y -B -s 32 1 -1`
echo $user3:$pass3 >> users-$date.txt

echo "Creating users from $setupdir. Please remember to delete this file!!"
read

useradd -M -d /nonexistent -s /usr/sbin/nologin $user1
useradd -M -d /nonexistent -s /usr/sbin/nologin $user2
useradd -M -d /nonexistent -s /usr/sbin/nologin $user3

cat users-$date.txt | chpasswd

echo "Install completed! Please reboot"

