#!/bin/bash

set -ex

DECONZ_VERSION=$1
CHANNEL=$2 # stable or beta
PLATFORM=$3

# Map "generic-beta" for APT if channel is beta
APT_CHANNEL="generic"
if [ "${CHANNEL}" = "beta" ]; then
    APT_CHANNEL="generic-beta"
fi

if echo "${PLATFORM}" | grep -qE "amd64"; then
    # 1. Install Repo GPG Key
    curl -sL http://phoscon.de/apt/deconz.pub.key | apt-key add -

    # 2. Add Repository
    echo "deb [arch=amd64] http://phoscon.de/apt/deconz ${APT_CHANNEL} main" > /etc/apt/sources.list.d/deconz.list

    # 3. Install via APT
    apt-get update
    # Note: We install a specific version if provided, otherwise latest
    apt-get install -y deconz="${DECONZ_VERSION}*" || apt-get install -y deconz

    # Create a dummy file so the Dockerfile dpkg command doesn't fail,
    # or we can handle the logic in the Dockerfile (see below).
    touch /deconz_installed_via_apt
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
