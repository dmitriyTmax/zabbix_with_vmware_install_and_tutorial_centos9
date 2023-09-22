# zabbix_with_vmware_install_and_tutorial_centos9 x86_64
This repository provides you step by step guide how to deploy and make configuration of zabbix on CentOS 9 with VMWare support. Database is using in this script **_MariaDB-11.0.3_**.

1. Install epel repo <br/>
  `dnf -y install epel-release` 

2. Disable Zabbix packages provided by EPEL. Edit file /etc/yum.repos.d/epel.repo and add the following statement. <br/>

   [epel]<br/>
   ... <br/>
   excludepkgs=zabbix*

3. Make script to run <br/>
   `chmod +x zabbix_install`

4. Run script <br/>
   `./zabbix_install`

5.  Configure PHP for Zabbix frontend
Edit file /etc/nginx/conf.d/zabbix.conf uncomment and set 'listen' and 'server_name' directives. <br/>

# listen 8080; <br/>
# server_name example.com; <br/>

6. d. Configure the database for Zabbix server
Edit file /etc/zabbix/zabbix_server.conf

**DBPassword=your_database_password**
