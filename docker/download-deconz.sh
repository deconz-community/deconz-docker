#!/bin/bash

set -ex

DECONZ_VERSION=$1
CHANNEL=$2
PLATFORM=$3

case "{$PLATFORM}" in
  *linux/arm64*)
    URL="http://deconz.dresden-elektronik.de/debian/${CHANNEL}/deconz_${DECONZ_VERSION}-debian-buster-${CHANNEL}_arm64.deb"
    ;;
  *linux/amd64*)
    URL="http://deconz.dresden-elektronik.de/ubuntu/${CHANNEL}/deconz-${DECONZ_VERSION}-qt5.deb"
    ;;
  *linux/arm/v7*)
    URL="http://deconz.dresden-elektronik.de/raspbian/${CHANNEL}/deconz-${DECONZ_VERSION}-qt5.deb"
    ;;
  *linux/arm/v6*)
    URL="http://deconz.dresden-elektronik.de/raspbian/${CHANNEL}/deconz-${DECONZ_VERSION}-qt5.deb"
    ;;
esac

curl -vv "${URL}" -o /deconz${DEV}.deb

