FROM multiarch/qemu-user-static:aarch64 as qemu
FROM arm64v8/debian:10.9-slim
COPY --from=qemu /usr/bin/qemu-aarch64-static /usr/bin

# Build arguments
ARG VERSION
ARG CHANNEL

# Runtime environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    DECONZ_VERSION=${VERSION} \
    DECONZ_WEB_PORT=80 \
    DECONZ_WS_PORT=443 \
    DEBUG_INFO=1 \
    DEBUG_APS=0 \
    DEBUG_ZCL=0 \
    DEBUG_ZDP=0 \
    DEBUG_OTAU=0 \
    DEBUG_ERROR=0 \
    DECONZ_DEVICE=0 \
    DECONZ_VNC_MODE=0 \
    DECONZ_VNC_DISPLAY=0 \
    DECONZ_VNC_PASSWORD=changeme \
    DECONZ_VNC_PASSWORD_FILE=0 \
    DECONZ_VNC_PORT=5900 \
    DECONZ_NOVNC_PORT=6080 \
    DECONZ_UPNP=1

# Install deCONZ dependencies
RUN apt-get update && \
    apt-get install -y \
        curl \
        kmod \
        libcap2-bin \
        libqt5core5a \
        libqt5gui5 \
        libqt5network5 \
        libqt5serialport5 \
        libqt5sql5 \
        libqt5websockets5 \
        libqt5widgets5 \
	libqt5qml5 \
        libssl1.1 \
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

# Add start.sh and Conbee udev data; set execute permissions
COPY root /
RUN chmod +x /start.sh && \
    chmod +x /firmware-update.sh

# Add deCONZ, install deCONZ, make OTAU dir
ADD http://deconz.dresden-elektronik.de/debian/${CHANNEL}/deconz_${DECONZ_VERSION}-debian-stretch-${CHANNEL}_arm64.deb /deconz.deb
RUN dpkg -i /deconz.deb && \
    rm -f /deconz.deb && \
    mkdir /root/otau && \
    chown root:root /usr/bin/deCONZ*

VOLUME [ "/root/.local/share/dresden-elektronik/deCONZ" ]

EXPOSE ${DECONZ_WEB_PORT} ${DECONZ_WS_PORT} ${DECONZ_VNC_PORT} ${DECONZ_NOVNC_PORT}

ENTRYPOINT [ "/start.sh" ]
