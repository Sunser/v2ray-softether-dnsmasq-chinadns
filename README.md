使用说明
本脚步只适用 CentOS 7 环境，以及 对需要使用 ICMP协议的人使用，本架构过于复杂，不太需要 ICMP协议的可以 使用 ROS + Lede 的方案 

主要使用 V2ray 作为底层构建 SOcks5 通道，在此基础上再使用 SOftether 对接
  以及使用dnsmasq chinadns 这类提供dhcp 以及 无污染的dns 服务 为 Ros 对接

服务端运行软件包内容：nginx + v2ray + softether + dnsmasq
中转服务器运行软件包内容：v2ray + softether + dnsmasq （gfwlist）+ chinadns + eoip
Ros 内容： 使用 eoip 和 中转服务器对接，并使用 China地址取反来分流（可类似多线叠加 Pcc 分流方式）

软件网络结构图：
![image](v2ray-softether-dnsmasq-chinadns/images/001.png)

使用方法：

境外VPS部分：
首先境外VPS 建议全新安装系统，然后自行安装 BBR 后即可执行本脚本
本脚本安装提示会有2个选择
1: Install Server (Default) # 服务端模式 境外VPS 使用
2: Install Bridge     # 桥接模式 内网中专服务器 使用

服务端安装完毕后会显示当前安装的 v2ray 配置密码保存该密码
上述步骤完成后需要手工配置nginx虚拟站点配置 以及 ssl 证书
nginx配置文件可以直接复制本库的配置文件修改域名以及ssl 证书位置并上传到规定目录下
SSL 证书目录 /etc/nginx/cert/
nginx 虚拟站点默认目录 /etc/nginx/conf.d/
如果使用我脚本的模板配置需要创建个 /opt/web/mirrors/ 目录并下载 intex.html 文件上传
mkdir -p /opt/web/mirrors/
chown -R nginx:nginx /opt/web/mirrors/
到此服务端配置结束 reboot 一次即可

中转服务器部分：
# 安装之前建议使用全新的系统并建立快照（由于国内环境可能在脚本下载过程中失败，快照的目的可以还原后重新来过）
本 Centos 可以放在内网或者境内任意公网机器上，推荐放在内网（dns 部分没有特殊处理可能存在被污染的风险，如需放公网请自行配置 redsocks 并修改下 chinadns）
脚本安装选择 2: Install Bridge     # 桥接模式 内网中专服务器 使用
等待安装结束并检查是否有报错，如果报错还原快照重新来过。安装成功后需要修改的配置如下：

1. 配置V2ray 客户端，配置在 /opt/v2ray/config.json 修改完成后使用 supervisorctl reload # 重载进程
如果对接多台服务端，可以cp 几份 config.json 文件 并修改 supervisor v2ray 配置文件：文件存在在 /etc/supervisor/supervisor.d/v2ray.conf
配置示范:
[program:v2ray-us]

autostart = true
autorestart = true
directory = /opt/v2ray
command = /opt/v2ray/v2ray -config /opt/v2ray/config1.json

stderr_logfile = /opt/v2ray/v2ray-us-error.log
stdout_logfile = /opt/v2ray/v2ray-us-stdout.log

[program:v2ray-hk]

autostart = true
autorestart = true
directory = /opt/v2ray
command = /opt/v2ray/v2ray -config /opt/v2ray/config2.json

stderr_logfile = /opt/v2ray/v2ray-hk-error.log
stdout_logfile = /opt/v2ray/v2ray-hk-stdout.log

修改完成后以及需要执行 supervisorctl reload

2. 配置 eoip (和ROS 对接使用的是 EOIP 协议，采用才协议方便未来更简单的适应IPV6 环境)
eoip 未采用 supervisor 托管进程，该配置直接存在于 /etc/rc.local 修改可以参照下面
# us-tunnel
/opt/eoip/eoip us-tunnel local 0.0.0.0 remote 10.0.1.254 id 1 fork
sleep 1s && ip link set us-tunnel up && sysctl -w net.ipv6.conf.us-tunnel.disable_ipv6=1

# hk-tunnel
/opt/eoip/eoip hk-tunnel local 0.0.0.0 remote 10.0.1.254 id 2 fork
sleep 1s && ip link set hk-tunnel up && sysctl -w net.ipv6.conf.hk-tunnel.disable_ipv6=1

# us-tunnel 和 hk-tunnel 表示eoIp 隧道名称  local 本地监听IP remote ROS ip（内网情况就是内网网关，外网就是外部IP ） id 表示 id编号

修改完成后可以直接reboot 一次或者复制出来直接 ssh 终端上粘贴一次让执行

3. 配置 softether对接
用Windows PC 下载 https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.29-9680-rtm/softether-vpnserver_vpnbridge-v4.29-9680-rtm-2019.02.28-windows-x86_x64-intel.exe
Mac 自行找对应软件包

下载后安装过程中选 softether vpn server 管理工具（仅限管理工具）这个选项，下一步 下一步这类的就不描述了
安装完毕后先连接中专服务器
![image](v2ray-softether-dnsmasq-chinadns/images/002.png)
首次连接必须设置密码，这个密码自定义，接着弹出来一个简单配置向导以及L2TP服务器配置向导，直接关闭
到此开始配置和服务器对接，如下直接附图
![image](v2ray-softether-dnsmasq-chinadns/images/003.png)
![image](v2ray-softether-dnsmasq-chinadns/images/004.png)
![image](v2ray-softether-dnsmasq-chinadns/images/005.png)
![image](v2ray-softether-dnsmasq-chinadns/images/006.png)
![image](v2ray-softether-dnsmasq-chinadns/images/007.png)
上面softether socks5 的5001 改改口是客户端监听本地的端口(改成实际端口)
hub 名称 脚本默认设置的 VPn ,用户认证 账号 VPNUser 密码 123456
创建桥接那张图就是上面eoip 的隧道接口
到此 中转服务器结束

3.配置ROS 对接 EOIP  直接参考脚本自行修改

/interface eoip

add name="proxy-tunnel1" remote-address=10.0.1.250 tunnel-id=1 comment="Us VPn"

add name="proxy-tunnel2" remote-address=10.0.1.250 tunnel-id=2 comment="Hk VPn"

:foreach i in=[find name~"proxy-tunnel"] do={unset $i keepalive ; set $i mtu=1500 disabled=no}

/ip route

add dst-address=0.0.0.0/0 gateway="proxy-tunnel1" routing-mark=PR1 disabled=no

add dst-address=0.0.0.0/0 gateway="proxy-tunnel2" routing-mark=PR2 disabled=no

/ip dhcp-client

add interface=proxy-tunnel1 add-default-route=no use-peer-dns=no use-peer-ntp=no disabled=no script="\r\n:local \"router_id\"\r\n:local \"gateway_address\"\r\n\r\n/ip route\r\n:if (\$bound = 1) do={\r\n\t:set \"router_id\" [:pick \$interface 12 [:len \$interface]]\r\n\t:set \"gateway_address\" [get [find routing-mark=(\"PR\" .\$\"router_id\")] gateway]\r\n\t# \C5\D0\B6\CF\CD\F8\B9\D8\B1\E4\C1\BF\B2\BB\B5\C8\D3\DA\B2\A2\D6\B4\D0\D0\r\n\t:if (\$\"gateway_address\" != \$\"gateway-address\") do={\r\n\t\tset [find routing-mark=(\"PR\" .\$\"router_id\")] gateway=\$\"gateway-address\"\r\n\t}\r\n}\r\n" 

add interface=proxy-tunnel2 add-default-route=no use-peer-dns=no use-peer-ntp=no disabled=no script="\r\n:local \"router_id\"\r\n:local \"gateway_address\"\r\n\r\n/ip route\r\n:if (\$bound = 1) do={\r\n\t:set \"router_id\" [:pick \$interface 12 [:len \$interface]]\r\n\t:set \"gateway_address\" [get [find routing-mark=(\"PR\" .\$\"router_id\")] gateway]\r\n\t# \C5\D0\B6\CF\CD\F8\B9\D8\B1\E4\C1\BF\B2\BB\B5\C8\D3\DA\B2\A2\D6\B4\D0\D0\r\n\t:if (\$\"gateway_address\" != \$\"gateway-address\") do={\r\n\t\tset [find routing-mark=(\"PR\" .\$\"router_id\")] gateway=\$\"gateway-address\"\r\n\t}\r\n}\r\n" 

/ip firewall nat

add action=masquerade chain=srcnat disabled=no out-interface="proxy-tunnel1" comment="Proxy Tunnel Reflux Rule"

add action=masquerade chain=srcnat disabled=no out-interface="proxy-tunnel2"

/ip firewall address-list

remove [find list="NOProxy-Address" dynamic=no]

add list="NOProxy-Address" address=Mirrors-Us.xxx.com comment="Us VPn Address"

add list="NOProxy-Address" address=Mirrors-Hk.xxx.com comment="Hk VPn Address"

/ip firewall mangle

add chain=prerouting action=mark-connection disabled=yes dst-address-list=!"NOProxy-Address" dst-address-type=!local in-interface-list="Internal-Network-List" per-connection-classifier=both-addresses-and-ports:2/0 new-connection-mark=PC1 passthrough=yes comment="Proxy Pcc Rule-1"

add action=mark-routing chain=prerouting connection-mark=PC1 disabled=yes in-interface-list="Internal-Network-List" new-routing-mark=PR1 passthrough=yes

add action=mark-connection chain=input disabled=yes in-interface=proxy-tunnel1 new-connection-mark=PC1 passthrough=yes

add action=mark-routing chain=output connection-mark=PC1 disabled=yes new-routing-mark=PR1 passthrough=yes

add chain=prerouting action=mark-connection disabled=yes dst-address-list=!"NOProxy-Address" dst-address-type=!local in-interface-list="Internal-Network-List" per-connection-classifier=both-addresses-and-ports:2/1 new-connection-mark=PC2 passthrough=yes comment="Proxy Pcc Rule-2"

add action=mark-routing chain=prerouting connection-mark=PC2 disabled=yes in-interface-list="Internal-Network-List" new-routing-mark=PR2 passthrough=yes

add action=mark-connection chain=input disabled=yes in-interface=proxy-tunnel2 new-connection-mark=PC2 passthrough=yes

add action=mark-routing chain=output connection-mark=PC2 disabled=yes new-routing-mark=PR2 passthrough=yes

