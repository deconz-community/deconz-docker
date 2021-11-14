#!/bin/sh

echo "[marthoc/deconz] Starting deCONZ..."
echo "[marthoc/deconz] Current deCONZ version: $DECONZ_VERSION"
echo "[marthoc/deconz] Web UI port: $DECONZ_WEB_PORT"
echo "[marthoc/deconz] Websockets port: $DECONZ_WS_PORT"

DECONZ_OPTS="--auto-connect=1 \
        --dbg-info=$DEBUG_INFO \
        --dbg-aps=$DEBUG_APS \
        --dbg-zcl=$DEBUG_ZCL \
        --dbg-zdp=$DEBUG_ZDP \
        --dbg-otau=$DEBUG_OTAU \
	--dbg-error=$DEBUG_ERROR \
        --http-port=$DECONZ_WEB_PORT \
        --ws-port=$DECONZ_WS_PORT"

if [ "$DECONZ_VNC_MODE" != 0 ]; then

  if [ "$DECONZ_VNC_PORT" -lt 5900 ]; then
    echo "[marthoc/deconz] ERROR - VNC port must be 5900 or greater!"
    exit 1
  fi

  DECONZ_VNC_DISPLAY=:$(($DECONZ_VNC_PORT - 5900))
  echo "[marthoc/deconz] VNC port: $DECONZ_VNC_PORT"

  if [ ! -e /root/.vnc ]; then
    mkdir /root/.vnc
  fi

  # Set VNC password
  if [ "$DECONZ_VNC_PASSWORD_FILE" != 0 ] && [ -f "$DECONZ_VNC_PASSWORD_FILE" ]; then
      DECONZ_VNC_PASSWORD=$(cat $DECONZ_VNC_PASSWORD_FILE)
  fi

  echo "$DECONZ_VNC_PASSWORD" | tigervncpasswd -f > /root/.vnc/passwd
  chmod 600 /root/.vnc/passwd

  # Cleanup previous VNC session data
  tigervncserver -kill "$DECONZ_VNC_DISPLAY"

  # Set VNC security
  tigervncserver -SecurityTypes VncAuth,TLSVnc "$DECONZ_VNC_DISPLAY"

  # Export VNC display variable
  export DISPLAY=$DECONZ_VNC_DISPLAY

  if [ "$DECONZ_NOVNC_PORT" = 0 ]; then
    echo "[marthoc/deconz] noVNC Disabled"
  else
    if [ "$DECONZ_NOVNC_PORT" -lt 6080 ]; then
      echo "[marthoc/deconz] ERROR - NOVNC port must be 6080 or greater!"
      exit 1
    fi

    # Assert valid SSL certificate
    NOVNC_CERT="/root/.vnc/novnc.pem"
    if [ -f "$NOVNC_CERT" ]; then
      openssl x509 -noout -in "$NOVNC_CERT" -checkend 0 > /dev/null
      if [ $? != 0 ]; then
        echo "[marthoc/deconz] The noVNC SSL certificate has expired; generating a new certificate now."
        rm "$NOVNC_CERT"
      fi
    fi
    if [ ! -f "$NOVNC_CERT" ]; then
      openssl req -x509 -nodes -newkey rsa:2048 -keyout "$NOVNC_CERT" -out "$NOVNC_CERT" -days 365 -subj "/CN=deconz"
    fi

    #Start noVNC
    websockify -D --web=/usr/share/novnc/ --cert="$NOVNC_CERT" $DECONZ_NOVNC_PORT localhost:$DECONZ_VNC_PORT
    echo "[marthoc/deconz] NOVNC port: $DECONZ_NOVNC_PORT"
  fi

else
  echo "[marthoc/deconz] VNC Disabled"
  DECONZ_OPTS="$DECONZ_OPTS -platform minimal"
fi

if [ "$DECONZ_DEVICE" != 0 ]; then
  DECONZ_OPTS="$DECONZ_OPTS --dev=$DECONZ_DEVICE"
fi

if [ "$DECONZ_UPNP" != 1 ]; then
  DECONZ_OPTS="$DECONZ_OPTS --upnp=0"
fi

/usr/bin/deCONZ $DECONZ_OPTS
