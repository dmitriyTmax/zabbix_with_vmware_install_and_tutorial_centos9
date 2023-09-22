#!/bin/bash

version=6.4
release_version=6
release=$version.$release_version
repo="https://repo.zabbix.com/zabbix/$version/rhel/9/x86_64"

#Configure SELinux to work in permissive mode
setenforce 0 && sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

#Update system and install nessary packages
echo "Updating system..."
yum update -y
echo ""
echo "Installing packages..."
dnf install -y epel-release 
dnf install -y wget openssl nginx gcc pv glib2-devel libxml2-devel net-snmp-devel libevent-devel curl-devel go
dnf -y --enablerepo=crb install OpenIPMI-devel

#Install mariadb mariadb-11.0.3
echo ""
echo "Adding repo for mariadb-11.0.3..."
curl -LsS -O https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
bash mariadb_repo_setup --mariadb-server-version=11.0.3
echo""
echo "Installing mariadb-11.0.3..."
dnf -y install MariaDB-server MariaDB-client MariaDB-backup MariaDB-devel
systemctl enable mariadb
systemctl start mariadb
mariadb-secure-installation

#Create initial database
echo ""
echo "Input root password for database:"
read root_dbpassword
echo "Input database password:"
read dbpassword
mariadb -uroot -p'$root_dbpassword' -e "create database zabbix character set utf8mb4 collate utf8mb4_bin;"
mariadb -uroot -p'$root_dbpassword' -e "create user zabbix@localhost identified by '$dbpassword';"
mariadb -uroot -p'$root_dbpassword' -e "grant all privileges on zabbix.* to zabbix@localhost;"
mariadb -uroot -p'$root_dbpassword' -e "set global log_bin_trust_function_creators = 1;"
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p'$dbpassword' zabbix
mariadb -uroot -p'$root_dbpassword' -e "set global log_bin_trust_function_creators = 0;"

#Creating zabbix user and group
echo ""
echo "Creating zabbix group"
groupadd --system zabbix
echo ""
echo "Creating zabbix user"
useradd --system -g zabbix -d /usr/lib/zabbix -s /sbin/nologin -c "Zabbix Monitoring System" zabbix

dnf install -y php-bcmath php-fpm php-gd php-json php-ldap php-mbstring php-xml php-mysqlnd fping unixODBC

#Install zabbix-agent and zabbix-web
rpm -Uvh https://repo.zabbix.com/zabbix/$version/rhel/9/x86_64/zabbix-release-$version-1.el9.noarch.rpm
dnf clean all
dnf install -y zabbix-web-mysql zabbix-nginx-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent2 

# Download zabbix and install zabbix
echo ""
echo "Downloading zabbix-$release"
wget "https://cdn.zabbix.com/zabbix/sources/stable/$version/zabbix-$release.tar.gz"
tar -zxvf zabbix-$release.tar.gz
cd zabbix-$release || exit 1
echo ""
echo "Configurating zabbix server..."
./configure --enable-server --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl --with-libxml2 --with-openipmi
echo ""
echo "Start to install zabbix"
make
make install

nano /etc/nginx/conf.d/zabbix.conf
nano /usr/local/etc/zabbix_server.conf

systemctl restart zabbix-agent2 nginx php-fpm
systemctl enable zabbix-agent2 nginx php-fpm
