FROM debian:13-slim

# Build arguments
ARG VERSION
ARG CHANNEL
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# Runtime environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    DECONZ_VERSION=${VERSION} \
    DECONZ_WEB_PORT=80 \
    DECONZ_WS_PORT=443 \
    DEBUG_INFO=1 \
    DEBUG_APS=0 \
    DEBUG_ZCL=0 \
    DEBUG_ZDP=0 \
    DEBUG_DDF=0 \
    DEBUG_DEV=0 \
    DEBUG_OTA=0 \
    DEBUG_ERROR=0 \
    DEBUG_HTTP=0 \
    DECONZ_DEV_TEST_MANAGED=0 \
    DECONZ_DEVICE=0 \
    DECONZ_VNC_MODE=0 \
    DECONZ_VNC_DISPLAY=0 \
    DECONZ_VNC_DISABLE_PASSWORD=0 \
    DECONZ_VNC_PASSWORD=changeme \
    DECONZ_VNC_PASSWORD_FILE=0 \
    DECONZ_VNC_PORT=5900 \
    DECONZ_NOVNC_PORT=6080 \
    DECONZ_UPNP=1 \
    DECONZ_UID=1000 \
    DECONZ_GID=1000 \
    DECONZ_START_VERBOSE=0 \
    DECONZ_BAUDRATE=0 \
    DECONZ_APPDATA_DIR=/opt/deCONZ \
    NON_ROOT=0

# Install deCONZ dependencies
RUN apt-get update && \
    apt-get install -y \
        gosu \
        curl \
        kmod \
        udev \
        libatomic1 \
        libcap2-bin \
        libqt5core5a \
        libqt5gui5 \
        libqt5network5 \
        libqt5serialport5 \
        libqt5sql5 \
        libqt5websockets5 \
        libqt5widgets5 \
        libqt5qml5 \
        libssl3 \
        libssl-dev \
        lsof \
        sqlite3 \
        tigervnc-standalone-server \
        tigervnc-common \
        novnc \
        websockify \
        openbox \
        xfonts-base \
        xfonts-scalable && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Workaround required on amd64 to address issue #292
RUN if [ "${TARGETPLATFORM}" = "linux/amd64" ] ; then \
    apt-get update && \
    apt-get install -y \
        binutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    strip --remove-section=.note.ABI-tag /usr/lib/x86_64-linux-gnu/libQt5Core.so.5 ; fi

# Add start.sh and Conbee udev data; set execute permissions
COPY root /
RUN chmod +x /start.sh && \
    chmod +x /firmware-update.sh

# Make user
RUN groupadd -g ${DECONZ_GID} "deconz" && \
    useradd -u ${DECONZ_UID} -g "deconz" -G dialout -ms /bin/bash "deconz"

# Add deCONZ, install deCONZ, make OTAU dir
COPY download-deconz.sh /

RUN chmod +x /download-deconz.sh && /download-deconz.sh ${VERSION} ${CHANNEL} ${TARGETPLATFORM}

RUN dpkg -i /deconz.deb && \
    chown root:root /usr/bin/deCONZ* && \
    setcap CAP_NET_BIND_SERVICE=+eip /usr/bin/deCONZ && \
    rm -f /deconz.deb

VOLUME [ "/opt/deCONZ" ]

HEALTHCHECK --interval=10s --timeout=20s --retries=5 CMD curl -I 127.0.0.1:${DECONZ_WEB_PORT} || exit 1

EXPOSE ${DECONZ_WEB_PORT} ${DECONZ_WS_PORT} ${DECONZ_VNC_PORT} ${DECONZ_NOVNC_PORT}

ENTRYPOINT [ "/start.sh" ]
