################
# First-boot script:
################

# log potential errors
exec > /init_setup.log 2>&1

LAN_IP_ADDRESS="192.168.1.1"
LAN_MASK="255.255.255.0"

PPPoE_USERNAME="USERNAME"
PPPoE_PASSWORD="PASSWORD"

WLAN_NAME_2G="OpenWrt2"
WLAN_NAME_5G_1="OpenWrt5g"
WLAN_NAME_5G_2="OpenWrt5g-2"
WLAN_PASSWORD='CHANGE_ME'

# Configure LAN
# More options: https://openwrt.org/docs/guide-user/base-system/basic-networking
if [ -n "$LAN_IP_ADDRESS" ]; then
  uci set network.lan.ipaddr="$LAN_IP_ADDRESS"
  uci set network.lan.netmask="$LAN_MASK"
  uci commit network
  /etc/init.d/network reload
fi

# Configure PPPoE
# More options: https://openwrt.org/docs/guide-user/network/wan/wan_interface_protocols#protocol_pppoe_ppp_over_ethernet
if [ -n "$PPPoE_USERNAME" -a "$PPPoE_PASSWORD" ]; then
  uci set network.wan.proto='pppoe'
  uci set network.wan.username="$PPPoE_USERNAME"
  uci set network.wan.password="$PPPoE_PASSWORD"
  uci commit network
  /etc/init.d/network reload
fi

# get wifi devices name
WIFI_DEVICE_2G="$(uci show wireless | grep 2g | awk -F '.' '{print $2}')"
WIFI_DEVICE_5G_1="$(uci show wireless | grep 5g | awk -F '.' 'NR==1 {print $2}')"
WIFI_DEVICE_5G_2="$(uci show wireless | grep 5g | awk -F '.' 'NR==2 {print $2}')"

# # set wifi config
setWiFi(){ # device, network, mode, band, htmode, txpower, ssid, key, encryption
  uci set wireless.default_"${1}".network="$2"
  uci set wireless.default_"${1}".mode="$3"
  uci set wireless.default_"${1}".band="$4"
  uci set wireless.default_"${1}".channel='auto'
  uci set wireless.default_"${1}".htmode="$5"
  uci set wireless.default_"${1}".txpower="$6"
  uci set wireless.default_"${1}".country='PA'
  uci set wireless.default_"${1}".ssid="$7"
  uci set wireless.default_"${1}".key="$8"
  uci set wireless.default_"${1}".encryption="$9"
  uci set wireless.default_"${1}".disabled='0'
  uci set wireless."${1}".disabled='0'
  uci commit wireless
}

if [ -n "$WLAN_NAME_2G" ]; then
  setWiFi "$WIFI_DEVICE_2G" lan ap 2g HT20 20 "${WLAN_NAME_2G}" "$WLAN_PASSWORD" 'sae-mixed'
fi
if [ -n "$WLAN_NAME_5G_1" ]; then
  setWiFi "$WIFI_DEVICE_5G_1" lan ap 5g VHT20 20 "${WLAN_NAME_5G_1}" "$WLAN_PASSWORD" 'sae'
fi
if [ -n "$WLAN_NAME_5G_2" ]; then
  setWiFi "$WIFI_DEVICE_5G_2" lan ap 5g VHT80 20 "${WLAN_NAME_5G_2}" "$WLAN_PASSWORD" 'sae'
fi

uci commit
wifi reload
sync

exit 0
