#!/usr/bin/env bash

#####################################################
# CentOS 7 V2Ray And Softether Install Shell Script #
#####################################################

clear
echo "+-----------------------------------------------------------------------------------------+"
echo "|                    Centos 7 V2Ray And Softether Install Shell Script                    |"
echo "+-----------------------------------------------------------------------------------------+"
echo "|              A tool to auto-compile & install V2Ray And Softether on linux              |"
echo "+-----------------------------------------------------------------------------------------+"

guide() {
	echo -e "\nVersion selection"
	ver_info=('Server' 'Bridge')

	if [ -z ${verselect} ]; then
		verselect="1"
		echo "Please select install version."
		echo "1: Install ${ver_info[0]} (Default)"
		echo "2: Install ${ver_info[1]}"
		read -p "Enter your choice (1 , 2): " verselect
	fi
	case "${verselect}" in
	1)
		echo "You will install ${ver_info[0]}"
		;;
	2)
		echo "You will install ${ver_info[1]}"
		;;
	*)
		echo "No input,You will install ${ver_info[0]}"
		verselect="1"
	esac
}

init_system() {
# Replacement CentOS-Base repo
if [ ${verselect} = "1" ] ; then
	system_repo
elif [ ${verselect} = "2" ] ; then
	system_repo_china
fi

# check firewalld
yum install -y firewalld
systemctl start firewalld
systemctl enable firewalld

firewallzone=$(firewall-cmd --get-default-zone)
if [ ${firewallzone} != "public" ] ; then
	firewall-cmd --set-default-zone=public
fi

publicsshstate=$(firewall-cmd --zone=public --query-service=ssh)
if [ ${publicsshstate} != "yes" ] ; then
	firewall-cmd --permanent --zone=public --add-service=ssh
fi

sshdport=$(cat /etc/ssh/sshd_config | grep "Port " | awk -F 'Port ' '{print $2}')
if [ ${sshdport} != "22" ] ; then
  othersshstate=$(firewall-cmd --permanent --zone=public --query-port=$sshdport/tcp)
  if [ ${othersshstate} != "yes" ] ; then
    firewall-cmd --permanent --zone=public --add-port=$sshdport/tcp
  fi
fi

systemctl restart firewalld

# check selinux
selinuxstate=$(getenforce)
if [ ${selinuxstate} != "Disabled" ] ; then
	setenforce 0
	echo -e "Permanently shutdown SELINUX function"
	sed -i 's/SELINUX\=enforcing/SELINUX\=disabled/g' /etc/selinux/config
fi

# check yum-cron
yumcronpackagestate=$(rpm -qa | grep "^yum-cron")
if [ -n "$yumcronpackagestate" ] ; then
	systemctl stop yum-cron
	systemctl disable yum-cron
fi

# Crack the number of connections
ulimitnum=$(ulimit -n)
if [ ${ulimitnum} = "1024" ] ; then
	# Write config file
	tee -a /etc/security/limits.conf <<-'EOF'

	* soft nproc 65535
	* hard nproc 65535
	* soft nofile 65535
	* hard nofile 65535

	EOF
fi

# Check wget and unzip package
yum clean all
rm -rf /var/cache/yum
rm -rf /var/lib/yum/history/*.sqlite
softwarepackage=("wget" "unzip" "gcc" "make" "expect" "net-tools" "dnsmasq" "zlib-devel" "openssl-devel" "ncurses-devel" "readline-devel") 
for softwarepackagevariable in ${softwarepackage[@]}
do
	softwarepackagestate=$(rpm -qa | grep "^$softwarepackagevariable")
	if [ ! -n "$softwarepackagestate" ] ; then
		echo "Install $softwarepackagevariable software package"
		yum install -y $softwarepackagevariable
	else
		echo "$softwarepackagevariable software packages have been installed."
	fi
done
}

system_repo() {
cat >/etc/yum.repos.d/CentOS-Base.repo <<"EOF"
# CentOS-Base.repo
# disable metalink enable baseurl
# baseurl default connection address
# http://mirror.centos.org/centos/

[base]
name=CentOS-$releasever - Base
baseurl=http://mirror.centos.org/centos/$releasever/os/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates 
[updates]
name=CentOS-$releasever - Updates
baseurl=http://mirror.centos.org/centos/$releasever/updates/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates&infra=$infra
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras
baseurl=http://mirror.centos.org/centos/$releasever/extras/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus
baseurl=http://mirror.centos.org/centos/$releasever/centosplus/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus&infra=$infra
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
}

system_repo_china() {
cat >/etc/yum.repos.d/CentOS-Base.repo <<"EOF"
# CentOS-Base.repo
# disable metalink enable baseurl
# baseurl default connection address
# http://mirror.centos.org/centos/

[base]
name=CentOS-$releasever - Base
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/os/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates 
[updates]
name=CentOS-$releasever - Updates
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/updates/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates&infra=$infra
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/extras/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/centosplus/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus&infra=$infra
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
}

nginx_repo() {
cat >/etc/yum.repos.d/nginx.repo <<"EOF"
# nginx.repo
# baseurl default connection address
# http://nginx.org/packages/centos/7/$basearch/

[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/7/$basearch/
gpgcheck=0
enabled=1
EOF
}

nginx_repo_china() {
cat >/etc/yum.repos.d/nginx.repo <<"EOF"
# nginx.repo
# baseurl default connection address
# http://nginx.org/packages/centos/7/$basearch/

[nginx]
name=nginx repo
baseurl=https://mirrors.0diis.com/nginx/centos/7/$basearch/
gpgcheck=0
enabled=1
EOF
}

epel_repo() {
cat >/etc/yum.repos.d/epel.repo <<"EOF"
# epel.repo
# disable metalink enable baseurl
# baseurl default connection address
# http://download.fedoraproject.org/pub/epel/7/

[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
baseurl=http://dl.fedoraproject.org/pub/epel/7/$basearch
#metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - $basearch - Debug
baseurl=http://dl.fedoraproject.org/pub/epel/7/$basearch/debug
#metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 7 - $basearch - Source
baseurl=http://dl.fedoraproject.org/pub/epel/7/SRPMS
#metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
EOF
}

epel_repo_china() {
cat >/etc/yum.repos.d/epel.repo <<"EOF"
# epel.repo
# disable metalink enable baseurl
# baseurl default connection address
# http://download.fedoraproject.org/pub/epel/7/

[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/$basearch
#metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - $basearch - Debug
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/$basearch/debug
#metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 7 - $basearch - Source
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/SRPMS
#metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
EOF
}

self_certificate() {
cat >/etc/nginx/cert/root.crt <<"EOF"
-----BEGIN CERTIFICATE-----
MIIDdzCCAl+gAwIBAgIJALIG4MqPPPyZMA0GCSqGSIb3DQEBCwUAMFIxCzAJBgNV
BAYTAkNOMQ4wDAYDVQQIDAVDaGluYTEVMBMGA1UEBwwMRGVmYXVsdCBDaXR5MRww
GgYDVQQKDBNEZWZhdWx0IENvbXBhbnkgTHRkMB4XDTE3MDkyMjA4MzcyMVoXDTE4
MDkyMjA4MzcyMVowUjELMAkGA1UEBhMCQ04xDjAMBgNVBAgMBUNoaW5hMRUwEwYD
VQQHDAxEZWZhdWx0IENpdHkxHDAaBgNVBAoME0RlZmF1bHQgQ29tcGFueSBMdGQw
ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDNdy+ik635t7yqsORWQxIO
n+CiTv/hSJGl+dgsbe3d/Wyki5WxC5MuGSUWT0WrKzw8MsqgTpOOYAMc0yhFiFs2
DL6QTs8Z7r5lUmcf4VhgZA/6X0dStWYmIMTQyKwOnefEDJWE0y4hAAlIRRTdbqzw
5rvp9Qot7us06Y3y/JqbfdNQ8ODaYTGQigrnxKeh0XUaulcfGVf1eXVmiFxtr4B7
O6d9XH3TvU1Ilu3FsBfa4dS2FG28LZDyHBy7a6ayG+QWNLidlDJyZgWm/mtHR1FC
ISny6hsGmFRQG767DWRLbJMt4ojuTbDaKEIhBU/w7fj5Kx5pSwbeYk/DGh30TpZT
AgMBAAGjUDBOMB0GA1UdDgQWBBTcu5hmHAnAhGeXX9aL+jMkak3DkDAfBgNVHSME
GDAWgBTcu5hmHAnAhGeXX9aL+jMkak3DkDAMBgNVHRMEBTADAQH/MA0GCSqGSIb3
DQEBCwUAA4IBAQA5f19FfnnNycL5PzUFeAtNT9Fo8UQbYqC8q2xvmQ0Lb0iDKj+T
esuiIO/lCArhKpco+4+dJPwZQeYUlT9qVcwcXnYfJwPwBTYXU2ngMMMmvONryeXb
k0255u14XQftX1koLiVHkV1Yc7NXGTWA5CMAqFMz1PkWN7Lv8jWFBz57WqNGoXqb
oKPXaPxgVxqSgryyMqfO+Ea8rfpZpZYVIONmcdednQrwEcJOi78V2zE79M0t65k8
+/ZjtMSSOKGAKlC+IOz29CLldX1G6wSzmV9RTBbzBCyVOG8t8IrdsaWjSGkh8JY3
K+SAnQK6U3rs8LRC2Z61PD65PfLKbPV4igab
-----END CERTIFICATE-----
EOF

cat >/etc/nginx/cert/root.key <<"EOF"
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDNdy+ik635t7yq
sORWQxIOn+CiTv/hSJGl+dgsbe3d/Wyki5WxC5MuGSUWT0WrKzw8MsqgTpOOYAMc
0yhFiFs2DL6QTs8Z7r5lUmcf4VhgZA/6X0dStWYmIMTQyKwOnefEDJWE0y4hAAlI
RRTdbqzw5rvp9Qot7us06Y3y/JqbfdNQ8ODaYTGQigrnxKeh0XUaulcfGVf1eXVm
iFxtr4B7O6d9XH3TvU1Ilu3FsBfa4dS2FG28LZDyHBy7a6ayG+QWNLidlDJyZgWm
/mtHR1FCISny6hsGmFRQG767DWRLbJMt4ojuTbDaKEIhBU/w7fj5Kx5pSwbeYk/D
Gh30TpZTAgMBAAECggEBAJPMY5i4UNKsR+wlOOuQbaHVgfpfh5Nf512Uftte7Ffe
n9Mxkal8oQ/tCI+m0H/Tpw3Kn5V3UI9/I14Nyw9RigM0YbRe7H1EDvPFtebp6+/S
que4uA6X7HYK5mkloRcWoYyWXMviOXGFnCe/gcXTglX8NDqUiREHp2w1gWXELdcg
/QcrmsUVjdR04j0wVW0hxwQ5Tah30L1VxBgylmdhqA94trdj3FdHCOp556IBj1gS
InXrcw3yPrwCkYQ9VW/BF3t9s3hfxzwmPpNy/HCR9mOCibzELFgPHnKBsoSYGBwf
DJF859S1wRN76RmBE/jdJJ14qIfcnDqTA8pjOl8WAFkCgYEA/5dnKi/eVf5UZ8II
6ZcNRW9OU+4ni9KhMXlMbPyttkJxJ99vWaR1gJTiGmVLa5UoV3GIRmImbIv+m70W
p+n2EaBHcTFaDE20dyeskofhRD7EfutPf54YYyG5Rk8Ip+TaoBPWMip/kk0GtwVt
85d0IgBsMjNbNkaCQoVJWQDkSJ8CgYEAzctFEzXv/DZoGkQJZGFL/zLpSM2jZ5fy
OEM8PHQ0gaPSvDfkv2Gr5oUs2cjl6Aun6f4fYTm7e9YClUVuezjHpheQVDi2zwwf
1h0WlMSvgEjhg2XXc+xfLEq5etCrxIocSEzO1XHWVMKzbMQ6U5R1hoYo6pyCOchH
ikbta7wmMc0CgYEA3QmtwXE2Yb4adsT6ejEU3Bifb7xFXQmiN6wEKTj4befV/jqg
DLFKoRGg3Fz/taGACud3iA731eXYIg2MG1kdYi7vufeJPZyx1l5sQyjZ6vAxdOXB
kcdCpfCTTzeob7JeVBPzqNzSCM8uYHeEmCZB2+nrqBp75lth6W9leGBqDFcCgYAc
YJQ00vI1uBbg0FLvOY9uMEoE1P5cUZJ/+Z17xJZc7gcoFxj+3uwCTIjjuxUgy0Kr
PHR9RqW4rMkMZleWvDyjhYpMYsmqgUR+lOJBP2Hn8aTPJqLwBD8Xb3JmIhIdduHx
gk3fFuR0KajuLZzRW55dH3DS8SPv7dMXmTIx8e7eXQKBgAUb26yJ+QT3FjOF7UVv
yluV7auwrVcGRhhF9XIpn9orYVRPcQY4gY2wqF1gYhHnz5VIWmXKxfDd7ZaPtx8L
UaF83K4cdQiD27YhnnVSBhygAbXhfui4acwQM5j6iuDyuSWWlaAiX+/Ac35gsLuk
r1DFDASTgBIecibWrId2vz5A
-----END PRIVATE KEY-----
EOF
}

install_nginx() {
	# Install nginx repo
	echo "Install nginx repo"
	rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm

	# Modify nginx repo
	if [ ${verselect} = "1" ] ; then
		nginx_repo
	elif [ ${verselect} = "2" ] ; then
		nginx_repo_china
	fi

	# Install nginx And openssl component package
	yum clean all
	rm -rf /var/cache/yum/
	rm -rf /var/lib/yum/history/*.sqlite
	yum install -y openssl nginx
	systemctl start nginx.service
	systemctl enable nginx.service

	# Optimizing nginx default configuration
	sed -i "/^$/{N;/\n$/D}" /etc/nginx/nginx.conf
	mv /etc/nginx/conf.d/default.conf /etc/nginx/default.conf
	sed -i "/tcp_nopush/a\ \n    server_tokens   off\;" /etc/nginx/nginx.conf
	sed -i "s/worker_processes  1/worker_processes  auto/g" /etc/nginx/nginx.conf
	sed -i "/worker_processes/a\worker_rlimit_nofile  65535\;" /etc/nginx/nginx.conf
	sed -i "s/worker_connections  1024/worker_connections  65535/g" /etc/nginx/nginx.conf
	sed -i "/include \/etc\/nginx\/conf.d\/\*.conf/i\    include \/etc\/nginx\/default.conf\;" /etc/nginx/nginx.conf
	sed -i "/listen       80\;/a\    listen       [::]:80\;" /etc/nginx/default.conf
	sed -i "/listen       [::]:80\;/a\    listen       443 ssl\;" /etc/nginx/default.conf
	sed -i "/listen       443 ssl\;/a\    listen       [::]:443 ssl\;" /etc/nginx/default.conf
	sed -i "/server_name/a\ \n    ssl_certificate \/etc\/nginx\/cert\/root.crt\;" /etc/nginx/default.conf
	sed -i "/ssl_certificate/a\    ssl_certificate_key \/etc\/nginx\/cert\/root.key\;" /etc/nginx/default.conf
	sed -i "/server_name/a\ \n    return       403\;" /etc/nginx/default.conf

	# Configure SSL support for nginx
	mkdir -p /etc/nginx/cert/
	self_certificate ; systemctl restart nginx
	
	# Configuration firewall to open service to nginx
	firewall-cmd --permanent --zone=public --add-service=http
	firewall-cmd --permanent --zone=public --add-service=https
	firewall-cmd --reload
}

install_supervisor() {
	# Install epel repo
	echo "Install epel repo"
	rm -rf /etc/yum.repos.d/epel*
	rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

	# Modify epel repo
	if [ ${verselect} = "1" ] ; then
		epel_repo
	elif [ ${verselect} = "2" ] ; then
		epel_repo_china
	fi

	# Install supervisor
	yum clean all
	rm -rf /var/cache/yum
	rm -rf /var/lib/yum/history/*.sqlite
	yum install -y python-pip
	pip install --upgrade pip
	pip install supervisor
	mkdir -p /etc/supervisor/supervisor.d
	echo_supervisord_conf > /etc/supervisor/supervisord.conf
	sed -i "s/;\[include\]/\[include\]/g" /etc/supervisor/supervisord.conf
	sed -i "s/\/tmp\/supervisor.sock/\/var\/run\/supervisor.sock/g" /etc/supervisor/supervisord.conf
	sed -i "s/\/tmp\/supervisord.pid/\/var\/run\/supervisord.pid/g" /etc/supervisor/supervisord.conf
	sed -i "s/\/tmp\/supervisord.log/\/var\/log\/supervisord.log/g" /etc/supervisor/supervisord.conf
	sed -i "s/;files = relative\/directory\/\*.ini/files = \/etc\/supervisor\/supervisor.d\/\*.conf/g" /etc/supervisor/supervisord.conf

	# config supervisord Startup
	supervisor_startup

	chmod +x /etc/systemd/system/supervisord.service
	systemctl enable supervisord
	systemctl start supervisord
}

supervisor_startup() {
tee /etc/systemd/system/supervisord.service <<-'EOF'

# supervisord service for systemd (CentOS 7.0+)
# by ET-CS (https://github.com/ET-CS)

[Unit]
Description=Supervisor daemon

[Service]
Type=forking
ExecStart=/usr/bin/supervisord
ExecStop=/usr/bin/supervisorctl $OPTIONS shutdown
ExecReload=/usr/bin/supervisorctl $OPTIONS reload
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target

EOF
}

install_v2ray() {
	cd /tmp
	# Get the latest version of v2ray on GitHub
	v2raylatestversion=$(curl -s https://mirrors.0diis.com/github/v2ray/v2ray-core/releases/latest | awk -F 'tag/v' '{print $2}' | awk -F '">' '{print $1}')

	# Down v2ray file
	wget https://mirrors.0diis.com/github/v2ray/v2ray-core/releases/download/v$v2raylatestversion/v2ray-linux-64.zip

	# install file to opt directory
	rm -rf /opt/v2ray
	unzip v2ray*.zip -d /opt/v2ray
	rm -f v2ray*.zip && cd /opt/v2ray/
	rm -rf doc systemd systemv v2ray.sig v2ctl.sig
	chmod +x /opt/v2ray/v2ray
	chmod +x /opt/v2ray/v2ctl

  # Install V2Ray config
	UUID=$(cat /proc/sys/kernel/random/uuid)

	if [ ${verselect} = "1" ] ; then
		wget https://other.0diis.com/v2rayserverconfig.json
		mv -f v2rayserverconfig.json /opt/v2ray/config.json
		sed -i "s/\/ray/\/v2ray/g" "/opt/v2ray/config.json"
		sed -i "s/23ab6b60-8b6b-40b7-8bb0-b3b33bbb829766/${UUID}/g" "/opt/v2ray/config.json"
	elif [ ${verselect} = "2" ] ; then
		wget https://other.0diis.com/v2rayclientconfig.json
		mv -f v2rayclientconfig.json /opt/v2ray/config.json
		sed -i "s/1080/5001/g" "/opt/v2ray/config.json"
		sed -i "s/\/ray/\/v2ray/g" "/opt/v2ray/config.json"
	fi

	# install varay to supervisord
	tee /etc/supervisor/supervisor.d/v2ray.conf <<-'EOF'

	[program:v2ray]

	autostart = true
	autorestart = true
	directory = /opt/v2ray
	command = /opt/v2ray/v2ray -config /opt/v2ray/config.json

	stderr_logfile = /opt/v2ray/v2ray-error.log
	stdout_logfile = /opt/v2ray/v2ray-stdout.log

	EOF

	# start v2ray
	supervisorctl reload

	# config time
	install_ntp

	# install nginx
	if [ ${verselect} = "1" ] ; then
		install_nginx
	fi
}

install_ntp() {
	# install ntp server
	rpm -qa | grep "^ntp" > /dev/null || yum install -y ntp

	# config ntp config file
	sed -i "s/^server/#server/g" /etc/ntp.conf
	echo "SYNC_HWCLOCK=yes" >> /etc/sysconfig/ntpd
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	ntp_config

	# start and startup
	systemctl start ntpd
	systemctl enable ntpd
}

ntp_config() {
cat >> /etc/ntp.conf <<EOF

# Custom asia ntp server.
server cn.pool.ntp.org iburst
server tw.pool.ntp.org iburst
server hk.pool.ntp.org iburst
server jp.pool.ntp.org iburst
server asia.pool.ntp.org iburst

EOF
}

install_chinadns() {
	# down chinadns file
	wget --no-check-certificate https://mirrors.0diis.com/github/shadowsocks/ChinaDNS/releases/download/1.3.2/chinadns-1.3.2.tar.gz

	# install chinadns
	tar -zxvf chinadns-*.tar.gz
	rm -f chinadns-*.tar.gz
	cd chinadns-*
	./configure
	make
	mkdir -p /opt/chinadns
	mv src/chinadns /opt/chinadns/
	cd ..
	rm -rf chinadns-*
	cd /opt/chinadns/
	wget --no-check-certificate https://raw.githubusercontent.com/Tsuk1ko/ChinaDNS/master/iplist.txt
	curl 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > chnroute.txt

	# config supervisor for chinadns
	supervisor_chinadns
	supervisorctl reload
}

supervisor_chinadns() {
cat >/etc/supervisor/supervisor.d/chinadns.conf <<"EOF"

[program:chinadns]

autostart = true
autorestart = true
directory = /opt/chinadns
command = /opt/chinadns/chinadns -p 5353 -m -l iplist.txt -c chnroute.txt -s 114.114.114.114,208.67.222.222:443,8.8.8.8

stderr_logfile = /opt/chinadns/chinadns-error.log
stdout_logfile = /opt/chinadns/chinadns-stdout.log

EOF
}

install_eoip() {
	cd /tmp
	# git eoip
	wget -O eoip.zip https://mirrors.0diis.com/github/Nat-Lab/eoip/archive/master.zip
	unzip eoip.zip
	rm -f eoip.zip
	cd eoip*
	make
	mkdir -p /opt/eoip
	mv -f eoip /opt/eoip/eoip
	firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 -p gre -j ACCEPT
	firewall-cmd --permanent --direct --add-rule ipv6 filter INPUT 0 -p gre -j ACCEPT
	firewall-cmd --reload
	chmod +x /etc/rc.d/rc.local
	echo -e "\n# v2ray-tunnel" >> /etc/rc.local
	echo "/opt/eoip/eoip v2ray-tunnel local 0.0.0.0 remote 10.0.1.254 id 1 fork" >> /etc/rc.local
	echo "sleep 1s && ip link set v2ray-tunnel up && sysctl -w net.ipv6.conf.v2ray-tunnel.disable_ipv6=1" >> /etc/rc.local
}

install_softether() {
	cd /tmp
	# git softehter
	wget -O softether.zip https://mirrors.0diis.com/github/SoftEtherVPN/SoftEtherVPN_Stable/archive/master.zip
	unzip softether.zip
	rm -f softether.zip
	cd SoftEther*
	./configure

	# wget custom makefiles
	wget https://other.0diis.com/softethermakefiles/server.mak
	mv -f server.mak Makefile
	make
	make install

	# config softether Startup
	mv -f systemd/softether-vpnserver.service /etc/systemd/system/softether.service
	sed -i "s/\/opt\/vpnserver/\/opt\/softether/g" /etc/systemd/system/softether.service
	cd ..
	rm -rf SoftEther*
	chmod +x /etc/systemd/system/softether.service
	systemctl daemon-reload
	systemctl start softether
	systemctl enable softether

	if [ ${verselect} = "2" ] ; then
		install_chinadns
		wget -O gfwlist.conf https://cokebar.github.io/gfwlist2dnsmasq/dnsmasq_gfwlist.conf
		mv -f gfwlist.conf /etc/dnsmasq.d/
		firewall-cmd --permanent --zone=public --add-service=dns
		firewall-cmd --permanent --zone=public --add-service=ipsec
		firewall-cmd --permanent --zone=public --add-port=443/tcp
		firewall-cmd --permanent --zone=public --add-port=992/tcp
		firewall-cmd --permanent --zone=public --add-port=1194/udp
		firewall-cmd --permanent --zone=public --add-port=5555/tcp
		firewall-cmd --permanent --zone=public --add-port=8888/tcp
		sed -i "/4500/i\ \ \<port protocol=\"udp\" port\=\"1701\"\/\>" /usr/lib/firewalld/services/ipsec.xml
		firewall-cmd --reload
		systemctl restart dnsmasq
	fi

	# down config	file
	if [ ${verselect} = "1" ] ; then
		wget https://other.0diis.com/softether-123456.config
		configpath=$(pwd)
		softether_config
		chmod +x softether.exp
		expect softether.exp
		rm -f softether.exp
		rm -f softether.config
		sleep 3s
		firewall-cmd --permanent --add-masquerade
		firewall-cmd --permanent --zone=public --add-service=dhcp
		firewall-cmd --permanent --zone=public --add-service=dhcpv6
		/opt/softether/vpncmd localhost:992 /server /password:123456 /cmd:Flush
		sed -i "/ExecStart/aExecStartPost=\/usr\/bin\/sleep 1s \; \/sbin\/ifconfig tap_vpn 192.168.$ipaddr.254/24" /etc/systemd/system/softether.service
		sleep 3s
		firewall-cmd --reload
		systemctl daemon-reload
		systemctl restart softether dnsmasq
	fi
}

softether_config() {
cat > softether.exp <<EOF
#!/usr/bin/expect
set timeout 30
spawn /opt/softether/vpncmd localhost:992 /server

expect "VPN Server" {send "ConfigSet\r";}
expect "Config file path name" {send "$configpath/softether-123456.config\r";}
expect "VPN Server" {send "exit\r";}
expect eof
EOF
}

dnsmasq_config() {
	# Random number
	ipaddr=$(($RANDOM%254+1))
	# server config dnsmasq
	if [ ${verselect} = "1" ] ; then
		# Write config file
		tee -a /etc/dnsmasq.conf <<-EOF

		# softether dnsmasq configuration

		interface=tap_vpn
		listen-address=192.168.${ipaddr}.254
		dhcp-option=option:router,192.168.${ipaddr}.254
		dhcp-range=192.168.${ipaddr}.1,192.168.${ipaddr}.250,7d
		dhcp-option=option:dns-server,8.8.8.8,8.8.4.4
		EOF

		# config Increase dependency
		sed -i  's/network.target/& softether.service/' /lib/systemd/system/dnsmasq.service
		systemctl daemon-reload
		systemctl enable dnsmasq
	fi

	# brige config dnsmasq
	if [ ${verselect} = "2" ] ; then
		# Write config file
		tee -a /etc/dnsmasq.conf <<-'EOF'

		# chinadns dnsmasq configuration

		port=53
		no-poll
		no-resolv
		cache-size=4096
		server=114.114.114.114
		server=114.114.115.115
		conf-dir=/etc/dnsmasq.d
		EOF
		systemctl start dnsmasq
		systemctl enable dnsmasq
	fi
}

# Run Script
guide
init_system 2>&1>/dev/null
install_supervisor 2>&1>/dev/null
install_v2ray 2>&1>/dev/null
dnsmasq_config 2>&1>/dev/null
install_softether 2>&1>/dev/null
# install eoip
if [ ${verselect} = "2" ] ; then
	install_eoip 2>&1>/dev/null
fi

echo -e "\nV2Ray And Softether installation is complete"

if [ ${verselect} = "1" ] ; then
	echo -e "V2Ray Password: ${UUID}"
fi
