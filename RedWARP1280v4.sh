#!/bin/bash

ARCH=$(uname -m)

case "$ARCH" in
    "x86_64")
        WGCF="./bin/wgcf_amd64"
        ;;
    "i386" | "i686")
        WGCF="./bin/wgcf_386"
        ;;
    "aarch64" | "arm64")
        WGCF="./bin/wgcf_arm64"
        ;;
    "armv7l")
        WGCF="./bin/wgcf_armv7"
        ;;
    "armv6l")
        WGCF="./bin/wgcf_armv6"
        ;;
    "armv5tel")
        WGCF="./bin/wgcf_armv5"
        ;;
    "mips")
        WGCF="./bin/wgcf_mips"
        ;;
    "mips64")
        WGCF="./bin/wgcf_mips64"
        ;;
    "mipsle")
        WGCF="./bin/wgcf_mipsle"
        ;;
    "mips64le")
        WGCF="./bin/wgcf_mips64le"
        ;;
    "s390x")
        WGCF="./bin/wgcf_s390x"
        ;;
    *)
        echo "Unknown or unsupported architecture: $ARCH. Supported: x86_64, i386, arm64, armv7, armv6, armv5, mips, mips64, mipsle, mips64le, s390x."
        exit 1
        ;;
esac

# Проверяем, что выбранный бинарник wgcf существует
if [ ! -f "$WGCF" ]; then
    echo "Binary file $WGCF not found. Make sure it exists and is accessible."
    exit 1
fi

# Убедимся, что wgcf можно запускать
chmod +x "$WGCF"

# Генерация конфигурационного файла при помощи wgcf
$WGCF register --accept-tos
$WGCF generate

# Проверьте, существует ли сгенерированный файл wgcf-profile.conf
if [ ! -f wgcf-profile.conf ]; then
    echo "Could not find generated configuration file wgcf-profile.conf"
    exit 1
fi

# Вставка новых параметров и изменение MTU
sed -i '/PrivateKey =/a S1 = 0\nS2 = 0\nJc = 120\nJmin = 23\nJmax = 911\nH1 = 1\nH2 = 2\nH3 = 3\nH4 = 4' wgcf-profile.conf
sed -i 's/MTU = .*/MTU = 1280/' wgcf-profile.conf

# Изменение Endpoint на 162.159.192.1
sed -i 's|Endpoint = .*|Endpoint = engage.cloudflareclient.com:2408|' wgcf-profile.conf

# Удаление строк с IPv6-адресами из Address и AllowedIPs
sed -i '/Address.*:/d' wgcf-profile.conf
sed -i '/AllowedIPs.*:/d' wgcf-profile.conf

# Замена DNS на 208.67.222.222 и 208.67.220.220
sed -i 's|DNS = .*|DNS = 208.67.222.222, 208.67.220.220|' wgcf-profile.conf

# Переименование в WARP.conf
mv wgcf-profile.conf RedWARP.conf

# Проверка на успешную модификацию
if grep -q "S1 = 0" RedWARP.conf && grep -q "MTU = 1280" RedWARP.conf && grep -q "Endpoint = engage.cloudflareclient.com:2408" RedWARP.conf && grep -q "DNS = 208.67.222.222, 208.67.220.220" RedWARP.conf; then
    echo "The configuration has been successfully updated and saved to RedWARP.conf!"
else
    echo "An error occurred while updating the configuration."
fi
