#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 1. تعديل عنوان IP الافتراضي إلى 192.168.1.20
sed -i 's/192.168.1.1/192.168.1.20/g' package/base-files/files/bin/config_generate

# 2. تغيير الثيم الافتراضي إلى Argon
sed -i "s/bootstrap/argon/ig" feeds/luci/collections/luci/Makefile

# 3. إضافة اسم مخصص للنسخة
sed -i "s/ImmortalWrt /$(TZ=UTC-8 date "+%Y.%m.%d") @ ImmortalWrt /g" "package/emortal/default-settings/files/99-default-settings"

# 4. تعديل أسماء بعض الإضافات (الترجمة)
sed -i 's/"aMule设置"/"电驴下载"/g' `egrep "aMule设置" -rl ./`
sed -i 's/"网络存储"/"存储"/g' `egrep "网络存储" -rl ./`
sed -i 's/"Turbo ACC 网络加速"/"网络加速"/g' `egrep "Turbo ACC 网络加速" -rl ./`
sed -i 's/"KMS 服务器"/"KMS激活"/g' `egrep "KMS 服务器" -rl ./`
sed -i 's/"终端"/"命令窗"/g' `egrep "终端" -rl ./`
sed -i 's/"USB 打印服务器"/"打印服务"/g' `egrep "USB 打印服务器" -rl ./`
sed -i 's/"Web 管理"/"访问控制"/g' `egrep "Web 管理" -rl ./`
sed -i 's/"管理权"/"改密码"/g' `egrep "管理权" -rl ./`
sed -i 's/"上网时间控制"/"上网控制"/g' `egrep "上网时间控制" -rl ./`
sed -i 's/"frp 客户端"/"内网穿透"/g' `egrep "frp 客户端" -rl ./`
sed -i 's/"Nps 内网穿透"/"内网穿透"/g' `egrep "Nps 内网穿透" -rl ./`

# 5. إنشاء سكريبت uci-defaults لتطبيق جميع إعدادات الشبكة والوايرلس
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-custom-setup
#!/bin/sh

# الانتظار قليلاً لضمان اكتمال إقلاع النظام
sleep 5

# --- إعدادات الشبكة (Network) ---
# دمج منفذ WAN إلى جسر LAN (جميع المنافذ تعمل كـ LAN)
uci add_list network.lan.ports='wan'
uci -q delete network.wan
uci -q delete network.wan6
uci set network.lan.ipaddr='192.168.1.20'
uci set network.lan.netmask='255.255.255.0'
uci commit network

# --- إعدادات خادم DHCP (DHCP) ---
# إيقاف خادم DHCPv4
uci set dhcp.lan.ignore='1'
# إيقاف خدمات IPv6 (RA, DHCPv6, NDP)
uci set dhcp.lan.ra='disabled'
uci set dhcp.lan.dhcpv6='disabled'
uci set dhcp.lan.ndp='disabled'
uci commit dhcp

# --- إعدادات اللاسلكي (Wireless) ---
# تشغيل الراديو (Radio)
uci set wireless.radio0.disabled='0'
uci set wireless.radio1.disabled='0'

# إعدادات راديو 2.4GHz (radio0)
uci set wireless.radio0.country='PA'
uci set wireless.radio0.channel='5'
uci set wireless.radio0.htmode='HT20'
uci set wireless.radio0.txpower='30'
uci set wireless.radio0.band='2g'

# إعدادات راديو 5GHz (radio1)
uci set wireless.radio1.country='PA'
uci set wireless.radio1.channel='116'
uci set wireless.radio1.htmode='HT40'
uci set wireless.radio1.txpower='30'
uci set wireless.radio1.band='5g'

# إعدادات واجهة 2.4G
uci set wireless.default_radio0.mode='ap'
uci set wireless.default_radio0.ssid='AbduRaheem_2G'
uci set wireless.default_radio0.network='lan'
uci set wireless.default_radio0.encryption='none'
uci set wireless.default_radio0.disabled='0'

# إعدادات واجهة 5G (مع تفعيل WDS)
uci set wireless.default_radio1.mode='ap'
uci set wireless.default_radio1.wds='1'
uci set wireless.default_radio1.ssid='AbduRaheem_5G'
uci set wireless.default_radio1.network='lan'
uci set wireless.default_radio1.encryption='none'
uci set wireless.default_radio1.disabled='0'

uci commit wireless

# إعادة تشغيل الشبكة والوايرلس لتطبيق التغييرات فوراً
/etc/init.d/network restart
wifi reload

exit 0
EOF

# جعل السكريبت قابلاً للتنفيذ
chmod +x package/base-files/files/etc/uci-defaults/99-custom-setup

# 6. تغيير شعار OpenWrt و LuCI (مع تعديل CSS للشعار العريض)
if [ -f "$GITHUB_WORKSPACE/custom_logo.png" ]; then
    cp $GITHUB_WORKSPACE/custom_logo.png feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/logo.png
    cp $GITHUB_WORKSPACE/custom_logo.png feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/logo_blue.png
    cp $GITHUB_WORKSPACE/custom_logo.png package/feeds/luci/luci-base/htdocs/luci-static/resources/logo.png
    
    echo ".brand { width: auto !important; min-width: 200px; }" >> feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/css/cascade.css
    echo ".brand .logo img { max-width: 250px !important; height: auto !important; }" >> feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/css/cascade.css
    echo "تم استبدال الشعار وتعديل CSS بنجاح!"
else
    echo "تحذير: لم يتم العثور على ملف custom_logo.png في المستودع!"
fi
