#!/bin/bash

# Function for manual input of parameters
manual_mode() {
    # Requesting Endpoint from the user
    read -p "Enter Endpoint (for example, 162.159.193.5:4500): " custom_endpoint
    if [ -z "$custom_endpoint" ]; then
        custom_endpoint="162.159.193.5:4500"  # If the user has not entered anything, we use the default value
    fi

    # Requesting MTU from the user
    read -p "Enter value MTU (by default - 1420): " custom_mtu
    if [ -z "$custom_mtu" ]; then
        custom_mtu="1420"  # If the user has not entered anything, we use the default value
    fi

    # We ask if IPv6 is needed
    read -p "Will the config support IPv6? (y/n, by default y): " ipv6_enabled
    if [ "$ipv6_enabled" != "n" ]; then
        ipv6_enabled="y"  # if user selects "n", disable IPv6
    fi
}

# Determining the processor architecture
ARCH=$(uname -m)

# Set the path to the wgcf binary depending on the architecture
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
        echo "Unknown or unsupported architecture: $ARCH. Supported x86_64, i386, arm64, armv7, armv6, armv5, mips, mips64, mipsle, mips64le, s390x."
        exit 1
        ;;
esac

# Check that the selected wgcf binary exists
if [ ! -f "$WGCF" ]; then
    echo "Binary file $WGCF not found. Make sure it exists and is accessible."
    exit 1
fi

# Let's make sure wgcf can be run
chmod +x "$WGCF"

# Operating mode: automatic or manual
read -p "Select mode: 'a'(auto) for automatic setup or 'm'(manual) for manual input (default 'a'): " mode
if [ "$mode" == "m" ]; then
    manual_mode
else
    custom_endpoint="162.159.193.5:4500"  # default value - 162.159.193.5:4500
    custom_mtu="1420"                     # default value - 1420
    ipv6_enabled="y"                      # default value - y
fi

# Generating a configuration file using wgcf
$WGCF register --accept-tos
$WGCF generate

# Check if the generated wgcf-profile.conf file exists
if [ ! -f wgcf-profile.conf ]; then
    echo "Could not find generated configuration file wgcf-profile.conf"
    exit 1
fi

# Inserting new parameters and changing MTU
sed -i '/PrivateKey =/a S1 = 0\nS2 = 0\nJc = 120\nJmin = 23\nJmax = 911\nH1 = 1\nH2 = 2\nH3 = 3\nH4 = 4' wgcf-profile.conf
sed -i "s/MTU = .*/MTU = $custom_mtu/" wgcf-profile.conf

# Изменение Endpoint
sed -i "s|Endpoint = .*|Endpoint = $custom_endpoint|" wgcf-profile.conf

# Remove IPv6 if user chooses to disable
if [ "$ipv6_enabled" == "n" ]; then
    sed -i '/Address.*:/d' wgcf-profile.conf
    sed -i '/AllowedIPs.*:/d' wgcf-profile.conf

    # Setting up IPv4 DNS only
    sed -i 's|DNS = .*|DNS = 208.67.222.222, 208.67.220.220|' wgcf-profile.conf
else
    # Setting IPv4 and IPv6 DNS
    sed -i 's|DNS = .*|DNS = 208.67.222.222, 208.67.220.220, 2620:119:35::35, 2620:119:53::53|' wgcf-profile.conf
fi

# Renaming to RedWARP.conf
mv wgcf-profile.conf RedWARP.conf

# Checking for successful modification
if grep -q "S1 = 0" RedWARP.conf && grep -q "MTU = $custom_mtu" RedWARP.conf && grep -q "Endpoint = $custom_endpoint" RedWARP.conf && (grep -q "DNS = 208.67.222.222, 208.67.220.220" RedWARP.conf || grep -q "DNS = 208.67.222.222, 208.67.220.220, 2620:119:35::35, 2620:119:53::53" RedWARP.conf); then
    echo "Configuration successfully updated and saved to RedWARP.conf!"
else
    echo "An error occurred while updating the configuration."
fi
