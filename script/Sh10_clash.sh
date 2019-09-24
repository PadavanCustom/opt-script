#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
TAG="SS_SPEC"		  # iptables tag
FWI="/tmp/firewall.clash.pdcn"
clash_enable=`nvram get app_88`
[ -z $clash_enable ] && clash_enable=0 && nvram set app_88=0
clash_http_enable=`nvram get app_89`
[ -z $clash_http_enable ] && clash_http_enable=0 && nvram set app_89=0
clash_socks_enable=`nvram get app_90`
[ -z $clash_socks_enable ] && clash_socks_enable=0 && nvram set app_90=0
clash_wget_yml=`nvram get app_91` # 订阅地址
clash_follow=`nvram get app_92`
[ -z $clash_follow ] && clash_follow=0 && nvram set app_92=0
clash_optput=`nvram get app_93`
[ -z $clash_optput ] && clash_optput=0 && nvram set app_93=0
clash_ui=`nvram get app_94`
[ -z $clash_ui ] && clash_ui="0.0.0.0:9090" && nvram set app_94="0.0.0.0:9090"
lan_ipaddr=`nvram get lan_ipaddr`
v2ray_enable=`nvram get v2ray_enable`
[ -z $v2ray_enable ] && v2ray_enable=0 && nvram set v2ray_enable=0
ss_enable=`nvram get ss_enable`
[ -z $ss_enable ] && ss_enable=0 && nvram set ss_enable=0
transocks_enable=`nvram get app_27`
[ -z $transocks_enable ] && transocks_enable=0 && nvram set app_27=0
v2ray_follow=`nvram get v2ray_follow`
[ -z $v2ray_follow ] && v2ray_follow=0 && nvram set v2ray_follow=0
ss_mode_x=`nvram get ss_mode_x` #ss模式，0 为chnroute, 1 为 gfwlist, 2 为全局, 3为ss-local 建立本地 SOCKS 代理
[ -z $ss_mode_x ] && ss_mode_x=0 && nvram set ss_mode_x=$ss_mode_x
if [ "$transocks_enable" != "0" ]  ; then
	if [ "$ss_enable" != "0" ] && [ "$ss_mode_x" != 3 ]  ; then
		logger -t "【clash】" "错误！！！由于已启用 transocks ，停止启用 SS 透明代理！"
		ss_enable=0 && nvram set ss_enable=0
	fi
	if [ "$clash_enable" != 0 ] && [ "$clash_follow" != 0 ]  ; then
		logger -t "【clash】" "错误！！！由于已启用 transocks ，停止启用 clash 透明代理！"
		clash_follow=0 && nvram set app_92=0
	fi
fi
if [ "$v2ray_enable" != 0 ] && [ "$v2ray_follow" != 0 ]  ; then
	if [ "$clash_enable" != 0 ] && [ "$clash_follow" != 0 ]  ; then
		logger -t "【clash】" "错误！！！由于已启用 v2ray 透明代理，停止启用 clash 透明代理！"
		clash_follow=0 && nvram set app_92=0
	fi
fi
if [ "$ss_enable" != "0" ] && [ "$ss_mode_x" != 3 ]  ; then
	if [ "$clash_enable" != 0 ] && [ "$clash_follow" != 0 ]  ; then
		logger -t "【clash】" "错误！！！由于已启用 SS 透明代理，停止启用 clash 透明代理！"
		clash_follow=0 && nvram set app_92=0
	fi
fi
if [ "$clash_enable" != "0" ] ; then
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
#nvramshow=`nvram showall | grep '=' | grep clash | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

chinadns_enable=`nvram get app_1`
[ -z $chinadns_enable ] && chinadns_enable=0 && nvram set app_1=0
chinadns_port=`nvram get app_6`
[ -z $chinadns_port ] && chinadns_port=8053 && nvram set app_6=8053

clash_renum=`nvram get clash_renum`
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="clash"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$clash_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep clash)" ]  && [ ! -s /tmp/script/_app18 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app18
	chmod 777 /tmp/script/_app18
fi

clash_restart () {

relock="/var/lock/clash_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set clash_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【clash】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	clash_renum=${clash_renum:-"0"}
	clash_renum=`expr $clash_renum + 1`
	nvram set clash_renum="$clash_renum"
	if [ "$clash_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【clash】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get clash_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set clash_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set clash_status=0
eval "$scriptfilepath &"
exit 0
}

clash_get_status () {

A_restart=`nvram get clash_status`
B_restart="$clash_enable$clash_http_enable$clash_socks_enable$clash_wget_yml$clash_follow$clash_optput$clash_ui"
B_restart="$B_restart""$(cat /etc/storage/app_20.sh | grep -v '^#' | grep -v "^$")"
[ "$(nvram get app_86)" = "wget_yml" ] && wget_yml
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set clash_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

clash_check () {

clash_get_status
if [ "$clash_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof clash`" ] && logger -t "【clash】" "停止 clash" && clash_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$clash_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		clash_close
		clash_start
	else
		[ -z "`pidof clash`" ] && clash_restart
		if [ "$clash_follow" = "1" ] ; then
		port=$(iptables -t nat -L | grep 'SS_SPEC' | wc -l)
		if [ "$port" = 0 ] ; then
			logger -t "【clash】" "检测:找不到 SS_SPEC 转发规则, 重新添加"
			clash_restart
		fi
		fi
	fi
fi
}

clash_keep () {
logger -t "【clash】" "守护进程启动"
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【clash】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof clash\`" ] || [ ! -s "/opt/bin/clash" ] && nvram set clash_status=00 && logger -t "【clash】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【clash】|^$/d' /tmp/script/_opt_script_check # 【clash】
OSC
#return
fi
clash_enable=`nvram get app_88`
while [ "$clash_enable" = "1" ]; do
	clash_follow=`nvram get clash_follow`
	if [ "$clash_follow" = "1" ] ; then
		port=$(iptables -t nat -L | grep 'SS_SPEC' | wc -l)
		if [ "$port" = 0 ] ; then
			logger -t "【clash】" "检测:找不到 SS_SPEC 转发规则, 重新添加"
			clash_restart
		fi
		if [ "$chinadns_enable" = "0" ] || [ "$chinadns_port" != "8053" ] ; then
			port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
			if [ "$port" = 0 ] ; then
				sleep 10
				port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
			fi
			if [ "$port" = 0 ] ; then
				logger -t "【clash】" "检测:找不到 dnsmasq 转发规则, 重新添加"
				# 写入dnsmasq配置

# 				sed -Ei '/port=0|no-resolv|server=|dns-forward-max=|min-cache-ttl=|max-cache-ttl=/d' /etc/storage/dnsmasq/dnsmasq.conf
# 				cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-EOF
# port=0
# no-resolv
# server=127.0.0.1#$8053
# dns-forward-max=1000
# min-cache-ttl=1800
# EOF
# 				restart_dhcpd

			fi
		fi
	fi
sleep 218
clash_enable=`nvram get app_88`
done
}

clash_close () {
flush_r
sed -Ei '/【clash】|^$/d' /tmp/script/_opt_script_check
killall clash
killall -9 clash
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
kill_ps "/tmp/script/_app18"
kill_ps "_clash.sh"
kill_ps "$scriptname"
}

clash_start () {
check_webui_yes
SVC_PATH="/opt/bin/clash"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【clash】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt start
	initopt
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【clash】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh /opt/bin/clash "$hiboyfile/clash" "$hiboyfile2/clash"
	chmod 755 "/opt/bin/clash"
else
	logger -t "【clash】" "找到 $SVC_PATH"
fi
chmod 777 "$SVC_PATH"
clash_v=$($SVC_PATH -v | grep Clash | awk -F ' ' '{print $2;}')
nvram set clash_v="$clash_v"
[ -z "$clash_v" ] && rm -rf $SVC_PATH
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【clash】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【clash】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && clash_restart x
fi
if [ ! -s "/opt/bin/yq" ] ; then
	logger -t "【clash】" "找不到 /opt/bin/yq 下载程序"
	wgetcurl.sh /opt/bin/yq "$hiboyfile/yq" "$hiboyfile2/yq"
	chmod 755 "/opt/bin/yq"
	[[ "$(yq -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/yq
fi
if [ ! -s "/opt/bin/yq" ] ; then
	logger -t "【clash】" "找不到 /opt/bin/yq ，需要手动安装 /opt/bin/yq"
	logger -t "【clash】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && clash_restart x
fi
# 下载clash_webs
if [ ! -d "/opt/app/clash/clash_webs" ] ; then
	logger -t "【clash】" "找不到 /opt/app/clash/clash_webs 下载 clash_webs"
	wgetcurl.sh /opt/app/clash/clash_webs.tgz "$hiboyfile/clash_webs.tgz" "$hiboyfile2/clash_webs.tgz"
	tar -xzvf /opt/app/clash/clash_webs.tgz -C /opt/app/clash
	rm -f /opt/app/clash/clash_webs.tgz
	[ -d "/opt/app/clash/clash_webs" ] && logger -t "【clash】" "下载 clash_webs 完成"
fi

logger -t "【clash】" "初始化 clash 配置"
mkdir -p /opt/app/clash/config
config_yml="/opt/app/clash/config/config.yml"
cp -f /etc/storage/app_20.sh $config_yml
sed -e '/^$/d' -i $config_yml
sed -r 's@^[ ]+#@#@g' -i $config_yml
sed -e '/^#/d' -i $config_yml
sed -e 's@#@♯@g' -i $config_yml
yq w -i $config_yml allow-lan true
logger -t "【clash】" "允许局域网的连接"
if [ "$clash_http_enable" != "0" ] ; then
yq w -i $config_yml port 7890
logger -t "【clash】" "HTTP 代理端口：7890"
else
yq d -i $config_yml port
fi
if [ "$clash_socks_enable" != "0" ] ; then
yq w -i $config_yml socks-port 7891
logger -t "【clash】" "SOCKS5 代理端口：7891"
else
yq d -i $config_yml socks-port
fi
if [ "$clash_follow" != "0" ] ; then
yq w -i $config_yml redir-port 7892
logger -t "【clash】" "redir 代理端口：7892"
else
yq d -i $config_yml redir-port
fi
yq w -i $config_yml external-controller $clash_ui
yq w -i $config_yml external-ui "/opt/app/clash/clash_webs/"
# 没搞懂 Clash DNS 暂时使用外部程序
# if [ "$chinadns_enable" != "0" ] && [ "$chinadns_port" = "8053" ] ; then
	# logger -t "【clash】" "已经启动 chinadns  防止域名污染"
	# yq w -i $config_yml dns.enable "false"
# else
	# logger -t "【clash】" "启动 clash 内置 DNS 防止域名污染"
	# pidof dnsproxy >/dev/null 2>&1 && killall dnsproxy && killall -9 dnsproxy 2>/dev/null
	# pidof pdnsd >/dev/null 2>&1 && killall pdnsd && killall -9 pdnsd 2>/dev/null
	# logger -t "【clash】" "删除 Clash 配置文件中原有的 DNS 配置"
	# yq d -i $config_yml dns
	# logger -t "【clash】" "将 DNS 配置 /tmp/clash/dns.yml 以覆盖的方式与 $config_yml 合并"
	# yq m -x -i $config_yml /tmp/clash/dns.yml
# fi

cd "$(dirname "$SVC_PATH")"
su_cmd="eval"
if [ "$clash_follow" = "1" ] && [ "$clash_optput" = "1" ]; then
	NUM=`iptables -m owner -h 2>&1 | grep owner | wc -l`
	hash su 2>/dev/null && su_x="1"
	hash su 2>/dev/null || su_x="0"
	[ "$su_x" != "1" ] && logger -t "【clash】" "缺少 su 命令"
	[ "$NUM" -ge "3" ] || logger -t "【clash】" "缺少 iptables -m owner 模块"
	if [ "$NUM" -ge "3" ] && [ "$clash_optput" = 1 ] && [ "$su_x" = "1" ] ; then
		adduser -u 778 cl -D -S -H -s /bin/sh
		killall clash
		su_cmd="su cl -c "
	else
		logger -t "【clash】" "停止路由自身流量走透明代理"
		clash_optput=0
		nvram set clash_optput=0
	fi
fi
logger -t "【clash】" "运行 /opt/bin/clash"

logger -t "【clash】" "检查 dnsmasq 配置是否停用了 dns 功能"
logger -t "【clash】" " clash_follow: $clash_follow"
logger -t "【clash】" " $(netstat -an | grep 53)"
# port=$(grep "port="  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
# if [ "$port" = 0 ] ; then
# 	logger -t "【clash】" "停用 dnsmasq dns 功能"
# 	cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-\EOF
# 	port=0 #clash1
# 	EOF
# 	restart_dhcpd
# fi

su_cmd2="/opt/bin/clash -d /opt/app/clash/config"
eval "$su_cmd" '"cmd_name=clash && '"$su_cmd2"' $cmd_log"' &
sleep 3
[ ! -z "`pidof clash`" ] && logger -t "【clash】" "启动成功" && clash_restart o
[ -z "`pidof clash`" ] && logger -t "【clash】" "启动失败, 注意检clash是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && clash_restart x
nvram set app_86=0
clash_get_status

if [ "$clash_follow" = "1" ] ; then
flush_r

# 透明代理
logger -t "【clash】" "启动 透明代理"
logger -t "【clash】" "备注：默认配置的透明代理会导致广告过滤失效，需要手动改造配置前置代理过滤软件"

if [ "$chinadns_enable" != "0" ] && [ "$chinadns_port" = "8053" ] ; then
echo "已经启动 chinadns 防止域名污染"
else
pidof dnsproxy >/dev/null 2>&1 && killall dnsproxy && killall -9 dnsproxy 2>/dev/null
pidof pdnsd >/dev/null 2>&1 && killall pdnsd && killall -9 pdnsd 2>/dev/null
logger -t "【clash】" "使用 clash 内置 DNS 防止域名污染"
logger -t "【clash】" "禁用 dnsmasq 监听 53 端口，相当于停用 dnsmasq 作为默认 dns"
#防火墙转发规则加载
# sed -Ei '/port=0|no-resolv|server=|dns-forward-max=|min-cache-ttl=|max-cache-ttl=/d' /etc/storage/dnsmasq/dnsmasq.conf
# cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-\EOF
# port=0 #clash
# no-resolv
# server=127.0.0.1#8053
# dns-forward-max=1000
# min-cache-ttl=1800
# EOF

fi

restart_dhcpd

logger -t "【clash】" "载入 透明代理 转发规则设置"
#载入iptables模块
for module in ip_set ip_set_bitmap_ip ip_set_bitmap_ipmac ip_set_bitmap_port ip_set_hash_ip ip_set_hash_ipport ip_set_hash_ipportip ip_set_hash_ipportnet ip_set_hash_net ip_set_hash_netport ip_set_list_set xt_set xt_TPROXY
do
	modprobe $module
done 

# rules规则
json_gen_special_purpose_ip
ipset -! restore <<-EOF 
create ss_spec_dst_sp hash:net hashsize 64
$(gen_special_purpose_ip | sed -e "s/^/add ss_spec_dst_sp /")
EOF

# 加载 nat 规则
include_ac_rules nat
iptables -t nat -A SS_SPEC_WAN_FW -p tcp -j REDIRECT --to-ports 7892
get_wifidognx
gen_prerouting_rules nat tcp $wifidognx
# iptables -t nat -I OUTPUT -p tcp -j SS_SPEC_CLASH_LAN_DG
# iptables -t nat -D OUTPUT -p tcp -j SS_SPEC_CLASH_LAN_DG


# iptables -t nat -I OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-ports 7892
# iptables -t nat -I OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-ports 7892

# 同时将代理规则应用到 OUTPUT 链, 让路由自身流量走透明代理
NUM=`iptables -m owner -h 2>&1 | grep owner | wc -l`
hash su 2>/dev/null && su_x="1"
hash su 2>/dev/null || su_x="0"
if [ "$NUM" -ge "3" ] && [ "$clash_optput" = 1 ] && [ "$su_x" = "1" ] ; then

# logger -t "【clash】" "支持游戏模式（UDP转发）"
# 加载 mangle 规则
# ip rule add fwmark 1 table 100
# ip route add local 0.0.0.0/0 dev lo table 100
# include_ac_rules mangle
# iptables -t mangle -A SS_SPEC_WAN_FW -p udp -j TPROXY --on-port 7892 --tproxy-mark 1
# get_wifidognx_mangle
# gen_prerouting_rules mangle udp $wifidognx

	logger -t "【clash】" "同时将透明代理规则应用到 OUTPUT 链, 让路由自身流量走透明代理"
	iptables -t nat -D OUTPUT -m owner ! --uid-owner 778 -p tcp -j SS_SPEC_CLASH_LAN_DG
	iptables -t nat -A OUTPUT -m owner ! --uid-owner 778 -p tcp -j SS_SPEC_CLASH_LAN_DG
fi
	logger -t "【clash】" "完成 透明代理 转发规则设置"
	gen_include &

# 透明代理
fi

eval "$scriptfilepath keep &"

exit 0
}

gen_include() {
[ -n "$FWI" ] || return 0
cat <<-CAT >>$FWI
iptables-restore -n <<-EOF
$(iptables-save | sed  "s/webstr--url/webstr --url/g" | grep -E "$TAG|^\*|^COMMIT" |sed -e "s/^-A \(OUTPUT\|PREROUTING\)/-I \1 1/")
EOF
CAT
return $?
}

gen_prerouting_rules() {
	iptables -t $1 -I PREROUTING $3 -p $2 -j SS_SPEC_CLASH_LAN_DG
}

flush_r() {
	[ -n "$FWI" ] && echo '#!/bin/sh' >$FWI
	iptables-save -c | sed  "s/webstr--url/webstr --url/g" | grep -v "SS_SPEC" | iptables-restore -c
	ip rule del fwmark 1 table 100 2>/dev/null
	ip route del local 0.0.0.0/0 dev lo table 100 2>/dev/null
	for setname in $(ipset -n list | grep -i "SS_SPEC"); do
		ipset destroy $setname 2>/dev/null
	done
	iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-ports 7892
	iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-ports 7892
	iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j RETURN
	iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j RETURN

	# if [ "$chinadns_enable" = "0" ] || [ "$chinadns_port" != "8053" ] ; then
	# 	logger -t "【clash】" "删除 dnsmasq 转发相关配置"
	# 	sed -Ei '/port=0|no-resolv|server=|dns-forward-max=|min-cache-ttl=|max-cache-ttl=/d' /etc/storage/dnsmasq/dnsmasq.conf
	# fi
	# restart_dhcpd

	return 0
}

gen_special_purpose_ip() {
cat <<-EOF | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}"
0.0.0.0/8
10.0.0.0/8
100.64.0.0/10
127.0.0.0/8
169.254.0.0/16
172.16.0.0/12
192.0.0.0/24
192.0.2.0/24
192.25.61.0/24
192.31.196.0/24
192.52.193.0/24
192.88.99.0/24
192.168.0.0/16
192.175.48.0/24
198.18.0.0/15
198.51.100.0/24
203.0.113.0/24
224.0.0.0/4
240.0.0.0/4
255.255.255.255
100.100.100.100
188.188.188.188
110.110.110.110
$lan_ipaddr
$ss_s1_ip
$ss_s2_ip
$kcptun_server
$v2ray_server_addresses
EOF
}

#-A SS_SPEC_CLASH_LAN_DG -p tcp -m multiport --dports 8118,3000,18309 -j RETURN

include_ac_rules() {
	iptables-restore -n <<-EOF
*$1
:SS_SPEC_CLASH_LAN_DG - [0:0]
:SS_SPEC_WAN_FW - [0:0]
-A SS_SPEC_CLASH_LAN_DG -m mark --mark 0xff -j RETURN
-A SS_SPEC_CLASH_LAN_DG -m set --match-set ss_spec_dst_sp dst -j RETURN
-A SS_SPEC_CLASH_LAN_DG -j SS_SPEC_WAN_FW
COMMIT
EOF

}


get_wifidognx() {
	wifidognx=""
	#wifidogn=`iptables -t nat -L PREROUTING --line-number | grep AD_BYBY | awk '{print $1}' | awk 'END{print $1}'`  ## AD_BYBY
	#if [ -z "$wifidogn" ] ; then
		wifidogn=`iptables -t nat -L PREROUTING --line-number | grep Outgoing | awk '{print $1}' | awk 'END{print $1}'`  ## Outgoing
		if [ -z "$wifidogn" ] ; then
			wifidogn=`iptables -t nat -L PREROUTING --line-number | grep vserver | awk '{print $1}' | awk 'END{print $1}'`  ## vserver
			if [ -z "$wifidogn" ] ; then
				wifidognx=1
			else
				wifidognx=`expr $wifidogn + 1`
			fi
		else
			wifidognx=`expr $wifidogn + 1`
		fi
	#else
	#	wifidognx=`expr $wifidogn + 1`
	#fi
	wifidognx=$wifidognx
}

get_wifidognx_mangle() {
	wifidognx=""
	wifidogn=`iptables -t mangle -L PREROUTING --line-number | grep Outgoing | awk '{print $1}' | awk 'END{print $1}'`  ## Outgoing
		if [ -z "$wifidogn" ] ; then
			wifidogn=`iptables -t mangle -L PREROUTING --line-number | grep UP | awk '{print $1}' | awk 'END{print $1}'`  ## UP
			if [ -z "$wifidogn" ] ; then
				wifidognx=1
			else
				wifidognx=`expr $wifidogn + 1`
			fi
		else
			wifidognx=`expr $wifidogn + 1`
		fi
	wifidognx=$wifidognx
}

arNslookup() {
mkdir -p /tmp/arNslookup
nslookup $1 | tail -n +3 | grep "Address" | awk '{print $3}'| grep -v ":" > /tmp/arNslookup/$$ &
I=5
while [ ! -s /tmp/arNslookup/$$ ] ; do
		I=$(($I - 1))
		[ $I -lt 0 ] && break
		sleep 1
done
killall nslookup
if [ -s /tmp/arNslookup/$$ ] ; then
cat /tmp/arNslookup/$$ | sort -u | grep -v "^$"
rm -f /tmp/arNslookup/$$
else
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		Address="`wget --no-check-certificate --quiet --output-document=- http://119.29.29.29/d?dn=$1`"
		if [ $? -eq 0 ]; then
		echo "$Address" |  sed s/\;/"\n"/g | grep -E -o '([0-9]+\.){3}[0-9]+'
		fi
	else
		Address="`curl -k -s http://119.29.29.29/d?dn=$1`"
		if [ $? -eq 0 ]; then
		echo "$Address" |  sed s/\;/"\n"/g | grep -E -o '([0-9]+\.){3}[0-9]+'
		fi
	fi
fi
}

arNslookup6() {
mkdir -p /tmp/arNslookup
nslookup $1 | tail -n +3 | grep "Address" | awk '{print $3}'| grep ":" > /tmp/arNslookup/$$ &
I=5
while [ ! -s /tmp/arNslookup/$$ ] ; do
		I=$(($I - 1))
		[ $I -lt 0 ] && break
		sleep 1
done
killall nslookup
if [ -s /tmp/arNslookup/$$ ] ; then
	cat /tmp/arNslookup/$$ | sort -u | grep -v "^$"
	rm -f /tmp/arNslookup/$$
fi
}

json_gen_special_purpose_ip() {
ss_s1_ip=""
ss_s2_ip=""
kcptun_server=""
v2ray_server_addresses=""
#处理肯定不走通道的目标网段
kcptun_server=`nvram get kcptun_server`
kcptun_enable=`nvram get kcptun_enable`
[ -z $kcptun_enable ] && kcptun_enable=0 && nvram set kcptun_enable=0
[ "$kcptun_enable" = "0" ] && kcptun_server=""
if [ "$kcptun_enable" != "0" ] ; then
if [ -z $(echo $kcptun_server | grep : | grep -v "\.") ] ; then 
resolveip=`/usr/bin/resolveip -4 -t 4 $kcptun_server | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`/usr/bin/resolveip -6 -t 4 $kcptun_server | grep : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`arNslookup $kcptun_server | sed -n '1p'` 
[ -z "$resolveip" ] && resolveip=`arNslookup6 $kcptun_server | sed -n '1p'` 
kcptun_server=$resolveip
else
# IPv6
kcptun_server=$kcptun_server
fi
fi
ss_server1=`nvram get ss_server1`
if [ "$ss_enable" != "0" ] && [ ! -z "$ss_server1" ] ; then
if [ -z $(echo $ss_server1 | grep : | grep -v "\.") ] ; then 
resolveip=`/usr/bin/resolveip -4 -t 4 $ss_server1 | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`/usr/bin/resolveip -6 -t 4 $ss_server1 | grep : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`arNslookup $ss_server1 | sed -n '1p'` 
[ -z "$resolveip" ] && resolveip=`arNslookup6 $ss_server1 | sed -n '1p'` 
ss_s1_ip=$resolveip
else
# IPv6
ss_s1_ip=$ss_server1
fi
fi
ss_server2=`nvram get ss_server2`
if [ "$ss_enable" != "0" ] && [ ! -z "$ss_server2" ] ; then
if [ -z $(echo $ss_server2 | grep : | grep -v "\.") ] ; then 
resolveip=`/usr/bin/resolveip -4 -t 4 $ss_server2 | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`/usr/bin/resolveip -6 -t 4 $ss_server2 | grep : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`arNslookup $ss_server2 | sed -n '1p'` 
[ -z "$resolveip" ] && resolveip=`arNslookup6 $ss_server2 | sed -n '1p'` 
ss_s2_ip=$resolveip
else
# IPv6
ss_s2_ip=$ss_server2
fi
fi
server_addresses=$(cat /etc/storage/v2ray_config_script.sh | tr -d ' ' | grep -Eo '"address":.+' | sed -n '1p' | cut -d':' -f2 | tr -d '"' | tr -d ',')
if [ ! -z "$server_addresses" ] ; then
	resolveip=`/usr/bin/resolveip -4 -t 4 $server_addresses | grep -v : | sed -n '1p'`
	[ -z "$resolveip" ] && resolveip=`arNslookup $server_addresses | sed -n '1p'` 
	[ -z "$resolveip" ] && resolveip=`arNslookup6 $server_addresses | sed -n '1p'` 
	server_addresses=$resolveip
	v2ray_server_addresses="$server_addresses"
else
	v2ray_server_addresses=""
fi
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

wget_yml () {
nvram set app_86=0
[ -z "$clash_wget_yml" ] && return
mkdir -p /tmp/clash
logger -t "【clash】" "服务器订阅：开始更新"
yml_tmp="/tmp/clash/app_20.sh"
wgetcurl.sh $app_20 "$clash_wget_yml" "$clash_wget_yml" N
if [ ! -s $app_20 ] ; then
	rm -f $app_20
	wget --no-check-certificate --user-agent 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36' -O $app_20 "$ssr_link_i"
fi
if [ ! -s $app_20 ] ; then
	rm -f $app_20
	curl -L -k --user-agent 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36' -o $app_20 "$ssr_link_i"
fi
if [ ! -s $app_20 ] ; then
	logger -t "【clash】" "错误！！clash 服务器订阅文件下载失败！请检查下载地址"
else
	nvram set clash_status=wget_yml
	cp -f $yml_tmp /etc/storage/app_20.sh
	yq w -i /etc/storage/app_20.sh allow-lan true
	rm -f $yml_tmp
fi
logger -t "【clash】" "服务器订阅：更新完成"
logger -t "【clash】" "请按F5或刷新 web 页面刷新配置"
}

initconfig () {

app_20="/etc/storage/app_20.sh"
if [ ! -f "$app_20" ] || [ ! -s "$app_20" ] ; then
	cat > "$app_20" <<-\EEE
#如果您不知道如何操作，请参阅 https://github.com/Hackl0us/SS-Rule-Snippet/blob/master/LAZY_RULES/clash.yaml

EEE
	chmod 755 "$app_20"
fi

mkdir -p /tmp/clash
cat > "/tmp/clash/dns.yml" <<-\EEE
dns:
  enable: true
  ipv6: false
  listen: 0.0.0.0:8053
  enhanced-mode: redir-host
  # enhanced-mode: redir-host # 或 fake-ip
  # # fake-ip-range: 198.18.0.1/16 # 如果你不知道这个参数的作用，请勿修改
  # # 实验性功能 hosts, 支持通配符 (例如 *.clash.dev 甚至 *.foo.*.example.com)
  # # 静态的域名 比 通配域名 具有更高的优先级 (foo.example.com 优先于 *.example.com)
  # # 注意: hosts 在 fake-ip 模式下不生效
  # hosts:
  #   '*.clash.dev': 127.0.0.1
  #   'alpha.clash.dev': '::1'

  nameserver:
    - 119.29.29.29
    - 114.114.114.114
    - 223.5.5.5
    #- tls://dns.rubyfish.cn:853
    #- https://dns.rubyfish.cn/dns-query
     
  fallback:
    # 与 nameserver 内的服务器列表同时发起请求，当规则符合 GEOIP 在 CN 以外时，fallback 列表内的域名服务器生效。
    - tls://1.1.1.1
    # - tls://1.0.0.1:853
    # - tls://dns.google:853
    # - tls://dns.google

    #- https://dns.rubyfish.cn/dns-query
    #- https://cloudflare-dns.com/dns-query
    #- https://dns.google/dns-query
EEE

}

initconfig

update_app () {
mkdir -p /opt/app/clash
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/clash/Advanced_Extensions_clash.asp /opt/bin/clash /opt/app/clash/config/Country.mmdb /opt/app/clash/clash_webs
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/clash/Advanced_Extensions_clash.asp" ] || [ ! -s "/opt/app/clash/Advanced_Extensions_clash.asp" ] ; then
	wgetcurl.sh /opt/app/clash/Advanced_Extensions_clash.asp "$hiboyfile/Advanced_Extensions_clashasp" "$hiboyfile2/Advanced_Extensions_clashasp"
fi
umount /www/Advanced_Extensions_app18.asp
mount --bind /opt/app/clash/Advanced_Extensions_clash.asp /www/Advanced_Extensions_app18.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/clash del &
}

case $ACTION in
start)
	clash_close
	clash_check
	;;
check)
	clash_check
	;;
stop)
	clash_close
	;;
updateapp18)
	clash_restart o
	[ "$clash_enable" = "1" ] && nvram set clash_status="updateclash" && logger -t "【clash】" "重启" && clash_restart
	[ "$clash_enable" != "1" ] && nvram set clash_v="" && logger -t "【clash】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
keep)
	#clash_check
	clash_keep
	;;
wget_yml)
	nvram set app_86="wget_yml"
	wget_yml
	clash_check
	;;
*)
	clash_check
	;;
esac

