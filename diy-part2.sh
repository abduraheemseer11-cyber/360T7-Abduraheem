#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
#账号:root 密码:无密码

# 1. تعديل عنوان IP الافتراضي إلى 192.168.1.20
sed -i 's/192.168.1.1/192.168.1.20/g' package/base-files/files/bin/config_generate

# 2. تغيير الثيم الافتراضي إلى Argon
sed -i "s/bootstrap/argon/ig" feeds/luci/collections/luci/Makefile

# 3. إضافة اسم مخصص للنسخة
# sed -i "s/OpenWrt /${Author} compiled in $(TZ=UTC-8 date "+%Y.%m.%d") @ OpenWrt /g" "package/emortal/default-settings/files/99-default-settings"
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

# 5. إنشاء سكريبت uci-defaults لتطبيق إعدادات الشبكة والوايرلس (AP + WDS + LAN Bridge)
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-custom-ap-wds
#!/bin/sh
# سكريبت يعمل مرة واحدة عند أول إقلاع لتطبيق الإعدادات

# الانتظار قليلاً لضمان اكتمال إقلاع النظام
sleep 5

# --- إعدادات الشبكة (Network) ---
# إضافة منفذ WAN إلى جسر LAN (لجعل جميع المنافذ تعمل كـ LAN)
# ملاحظة: في أجهزة 360T7 يعمل السوفت عادة بنظام DSA، واسم المنفذ يكون 'wan'
uci add_list network.lan.ports='wan'
# حذف واجهات WAN و WAN6 (حذف المنطق فقط، المنفذ الفيزيائي تم دمجه في LAN)
uci -q delete network.wan
uci -q delete network.wan6
# تثبيت عنوان IP
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
# تحويل الواجهات إلى وضع AP مع تفعيل WDS
uci set wireless.@wifi-iface[0].mode='ap'
uci set wireless.@wifi-iface[0].wds='1'
uci set wireless.@wifi-iface[1].mode='ap'
uci set wireless.@wifi-iface[1].wds='1'
uci commit wireless

# إعادة تشغيل الشبكة لتطبيق التغييرات فوراً
/etc/init.d/network restart

exit 0
EOF

# جعل السكريبت قابلاً للتنفيذ
chmod +x package/base-files/files/etc/uci-defaults/99-custom-ap-wds

# 6. تغيير شعار OpenWrt و LuCI
# نسخ الصورة المخصصة لتحل محل شعار ثيم Argon
if [ -f "$GITHUB_WORKSPACE/custom_logo.png" ]; then
    # المسار الأساسي لشعار ثيم Argon
    cp $GITHUB_WORKSPACE/custom_logo.png feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/logo.png
    # المسار الخاص بالوضع الليلي/النهاري في بعض إصدارات Argon
    cp $GITHUB_WORKSPACE/custom_logo.png feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/logo_blue.png
    
    # استبدال شعار LuCI الافتراضي (لضمان التغيير في كل مكان)
    cp $GITHUB_WORKSPACE/custom_logo.png package/feeds/luci/luci-base/htdocs/luci-static/resources/logo.png
    
    # --- تعديل CSS للثيم ليسمح بشعار عريض (البانر) ---
    echo ".brand { width: auto !important; min-width: 200px; }" >> feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/css/cascade.css
    echo ".brand .logo img { max-width: 250px !important; height: auto !important; }" >> feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/css/cascade.css
    
    echo "تم استبدال الشعار وتعديل CSS بنجاح!"
else
    echo "تحذير: لم يتم العثور على ملف custom_logo.png في المستودع!"
fi

