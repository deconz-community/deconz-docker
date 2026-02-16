#!/bin/bash

set -ex

DECONZ_VERSION=$1
CHANNEL=$2
PLATFORM=$3

if [[ "$PLATFORM" == *"amd64"* ]]; then
    # Download key to the modern keyring location
    wget -O - http://phoscon.de/apt/deconz.pub.key | gpg --dearmor -o /usr/share/keyrings/deconz.gpg
    
    APT_CHANNEL="generic"
    if [ "$CHANNEL" == "beta" ]; then APT_CHANNEL="generic-beta"; fi
    
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/deconz.gpg] http://phoscon.de/apt/deconz ${APT_CHANNEL} main" > /etc/apt/sources.list.d/deconz.list
    
    apt-get update
    apt-get install -y deconz
    # Create a flag so the Dockerfile knows skip dpkg
    touch /tmp/apt_installed
    exit 0
fi

# Fallback for arm64 / v7 (Manual Download)
if echo "${PLATFORM}" | grep -qE "arm64"; then
  URL="http://deconz.dresden-elektronik.de/debian/${CHANNEL}/deconz_${DECONZ_VERSION}-debian-buster-${CHANNEL}_arm64.deb"
fi
if echo "${PLATFORM}" | grep -qE "v7"; then
  URL="http://deconz.dresden-elektronik.de/raspbian/${CHANNEL}/deconz-${DECONZ_VERSION}-qt5.deb"
fi

curl -vv "${URL}" -o /deconz.deb
