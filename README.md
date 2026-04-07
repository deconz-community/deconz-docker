## Notes for Alexa users

If you are using Alexa and experiencing significant command response delays, you must set the WebSocket port to 8443. If you are using Docker Compose, set the following environment variable:

```
DECONZ_WS_PORT=8443
```

## Notes for ConBee 3 users

If you're using a ConBee 3 stick, you need to set the following environment variable for deCONZ to be able to communicate with the stick:

```
DECONZ_BAUDRATE=115200
```

## Notes for RaspBeeII users

If you're using a RaspBee II device, you need to set the following environment variable for deCONZ to be able to communicate with the device:

```
DECONZ_BAUDRATE=38400
```

## Notes for Synology users

We've had numerous reports of issues when deCONZ is run as an unprivileged user, which is the default behaviour. Because of this, it is highly recommended that you run deCONZ as root. To do so, set the following two environment variables:

```
DECONZ_UID=0
DECONZ_GID=0
```

---

## deCONZ Docker Image

This Docker image containerizes the deCONZ software from dresden elektronik, which controls a ZigBee network using a Conbee USB or RaspBee GPIO serial interface. This image runs deCONZ in "minimal" mode, for control of the ZigBee network via the WebUIs ("Wireless Light Control" and "Phoscon") and over the REST API and Websockets, and optionally runs a VNC server for viewing and interacting with the ZigBee mesh through the deCONZ UI.

Conbee is supported on `amd64`, `armhf`/`armv7`, and `aarch64`/`arm64` (i.e. RaspberryPi 2/3B/3B+, and other arm64 boards) architectures; RaspBee is supported on `armhf`/`armv7` and `aarch64`/`arm64` (and see the "Configuring Raspbian for RaspBee" section below for instructions to configure Raspbian to allow access to the RaspBee serial hardware).

Builds of this image are available on Docker Hub and Github Container Registry:

| Tag     | Description                               |
| ------- | ----------------------------------------- |
| latest  | Latest release of deCONZ, stable or beta  |
| stable  | Stable releases of deCONZ only            |
| beta    | Beta releases of deCONZ only              |
| version | Specific versions of deCONZ, e.g. 2.13.02 |

The "latest", "stable", and "version" tags have multiarch support for amd64, armv7, and arm64.

### Registries

- Docker Hub: `docker pull deconzcommunity/deconz:latest`
- Github Container Registry: `docker pull ghcr.io/deconz-community/deconz-docker:latest`, more info [here](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

### Running the deCONZ Container

#### Pre-requisites

Before running the command that creates the deconz Docker container, you may need to add your Linux user to the `dialout` group, which allows the user access to serial devices (i.e. Conbee/Conbee II/RaspBee/RaspBeeII):

```bash
sudo usermod -a -G dialout $USER
```

#### Environment Variables

Use these environment variables to change the default behaviour of the container.

| Parameter                                            | Description                                                                                                                                                                                                                                                                                             |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-e DECONZ_WEB_PORT=8080`                            | By default, the web HTTP UIs ("Wireless Light Control" and "Phoscon") and the REST API listen on port 80; only set this environment variable if you wish to change the listen port.                                                                                                                     |
| `-e DECONZ_WEBS_PORT=0`                              | By default, the web HTTPS UIs are disabled; only set this environment variable if you wish to enable and change the listen port.                                                                                                                                                                        |
| `-e DECONZ_WS_PORT=8443`                             | By default, the websockets service listens on port 443; only set this environment variable if you wish to change the listen port.                                                                                                                                                                       |
| `-e DEBUG_INFO=1`                                    | Sets the level of the deCONZ command-line flag --dbg-info (default 1).                                                                                                                                                                                                                                  |
| `-e DEBUG_APS=0`                                     | Sets the level of the deCONZ command-line flag --dbg-aps (default 0).                                                                                                                                                                                                                                   |
| `-e DEBUG_ZCL=0`                                     | Sets the level of the deCONZ command-line flag --dbg-zcl (default 0).                                                                                                                                                                                                                                   |
| `-e DEBUG_ZDP=0`                                     | Sets the level of the deCONZ command-line flag --dbg-zdp (default 0).                                                                                                                                                                                                                                   |
| `-e DEBUG_DDF=0`                                     | Sets the level of the deCONZ command-line flag --dbg-ddf (default 0).                                                                                                                                                                                                                                   |
| `-e DEBUG_DEV=0`                                     | Sets the level of the deCONZ command-line flag --dbg-dev (default 0).                                                                                                                                                                                                                                   |
| `-e DEBUG_OTA=0`                                     | Sets the level of the deCONZ command-line flag --dbg-ota (default 0).                                                                                                                                                                                                                                   |
| `-e DEBUG_ERROR=0`                                   | Sets the level of the deCONZ command-line flag --dbg-error (default 0).                                                                                                                                                                                                                                 |
| `-e DEBUG_HTTP=0`                                    | Sets the level of the deCONZ command-line flag --dbg-http (default 0).                                                                                                                                                                                                                                  |
| `-e DECONZ_DEV_TEST_MANAGED=0`                       | Sets the level of the deCONZ command-line flag --dev-test-managed (default 0).                                                                                                                                                                                                                          |
| `-e DECONZ_DEVICE=/dev/ttyUSB1`                      | By default, deCONZ searches for RaspBee at /dev/ttyAMA0 and Conbee at /dev/ttyUSB0; when using other USB devices (e.g. a Z-Wave stick) deCONZ may not find RaspBee/Conbee properly. Set this environment variable to the same string passed to --device to force deCONZ to use the specific USB device. |
| `-e TZ=America/Toronto`                              | Set the local time zone so deCONZ has the correct time.                                                                                                                                                                                                                                                 |
| `-e DECONZ_VNC_MODE=1`                               | Set this option to enable VNC access to the container to view the deCONZ ZigBee mesh.                                                                                                                                                                                                                   |
| `-e DECONZ_VNC_PORT=5900`                            | Default port for VNC mode is 5900; this option can be used to change this port.                                                                                                                                                                                                                         |
| `-e DECONZ_VNC_PASSWORD=changeme`                    | Default password for VNC mode is 'changeme'; this option can (should) be used to change the default password.                                                                                                                                                                                           |
| `-e DECONZ_VNC_PASSWORD_FILE=/var/secrets/my_secret` | Per default this is disabled and DECONZ_VNC_PASSWORD is used. Details on creating secrets for use with Docker containers can be found in the [corresponding section from the official documentation](https://docs.docker.com/engine/swarm/secrets/).                                                    |
| `-e DECONZ_NOVNC_PORT=6080`                          | Default port for noVNC is 6080; this option can be used to change this port; setting the port to `0` will disable the noVNC functionality.                                                                                                                                                              |
| `-e DECONZ_UPNP=0`                                   | Set this option to 0 to disable uPNP, see: https://github.com/dresden-elektronik/deconz-rest-plugin/issues/274                                                                                                                                                                                          |
| `-e DECONZ_UID=1000`                                 | Set the user id of deCONZ volume.                                                                                                                                                                                                                                                                       |
| `-e DECONZ_GID=1000`                                 | Set the group id of deCONZ volume.                                                                                                                                                                                                                                                                      |
| `-e DECONZ_START_VERBOSE=0`                          | Set this option to 0 to disable verbose of start script, set to 1 to enable `set -x` logging.                                                                                                                                                                                                           |
| `-e DECONZ_BAUDRATE=115200`                          | Set the baudrate of the device. Required for ConBee 3 (115200) and RaspBee II (38400).                                                                                                                                                                                                                  |
| `-e DECONZ_APPDATA_DIR=/opt/deCONZ`                  | Set an alternative appdata directory in case volume bindings are not possible, e.g. Home Assistant OS.                                                                                                                                                                                                  |
| `-e NON_ROOT=0`                                      | Set this option to 1 to enable non-root execution of deCONZ.                                                                                                                                                                                                                                            |

#### Docker Compose

A full docker-compose.yml file is provided in the root of this image's GitHub repo. You may also copy/paste the following into your existing docker-compose.yml, modifying the options as required:

```yaml
services:
  deconz:
    image: deconzcommunity/deconz
    container_name: deconz
    restart: always
    ports:
      - 80:80
      - 443:443
    volumes:
      - /opt/deconz:/opt/deCONZ
    devices:
      - /dev/ttyUSB0
    environment:
      - DECONZ_WEB_PORT=80
      - DECONZ_WS_PORT=443
      - DEBUG_INFO=1
      - DEBUG_APS=0
      - DEBUG_ZCL=0
      - DEBUG_ZDP=0
      - DEBUG_OTA=0
```

Then, you can do `docker compose pull` to pull the latest image, `docker compose up -d` to start the container, and `docker compose down` to stop it.

### Configuring Raspbian for RaspBee

Raspbian defaults Bluetooth to /dev/ttyAMA0 and configures a login shell over serial (tty). You must disable the tty login shell and enable the serial port hardware, and swap Bluetooth to /dev/S0, to allow RaspBee to work properly under Docker.

To disable the login shell over serial and enable the serial port hardware:

1. `sudo raspi-config`
2. Select `Interfacing Options`
3. Select `Serial`
4. "Would you like a login shell to be accessible over serial?" Select `No`
5. "Would you like the serial port hardware to be enabled?" Select `Yes`
6. Exit raspi-config and reboot

To swap Bluetooth to /dev/S0 (moving RaspBee to /dev/ttyAMA0), run the following command and then reboot:

```bash
echo 'dtoverlay=pi3-miniuart-bt' | sudo tee -a /boot/firmware/config.txt
```

Note: On Raspbian / Debian versions earlier than Bookworm the config is located under /boot/config.txt.

After running the above command and rebooting, RaspBee should be available at /dev/ttyAMA0.

### Configuring deCONZ Container for Conbee II on Raspberry Pi

It may be necessary to run the deCONZ docker image in privileged mode for it to be able to connect and control a Conbee II or RaspBee device on Raspberry Pi. Here is an example docker-compose.yml:

```yaml
services:
  deconz:
    image: deconzcommunity/deconz:stable
    container_name: deconz
    restart: always
    privileged: true # Required for deCONZ to connect to Conbee II / RaspBee
    ports:
      - 80:80
      - 443:443
    volumes:
      - /opt/deCONZ:/opt/deCONZ
    devices:
      - /dev/ttyACM0 # USB device path for Conbee II
    environment:
      - TZ=Europe/Berlin
      - DECONZ_WEB_PORT=80
      - DECONZ_WS_PORT=443
      - DECONZ_DEVICE=/dev/ttyACM0
```

To find the correct device path for your Conbee II, run:

```shell
ls -al /dev/serial/by-id/
# Example output:
# lrwxrwxrwx 1 root root 13 Jul 23 00:13 usb-dresden_elektronik_..._ConBee_II_XXXXXXX-if00 -> ../../ttyACM0
```

The symlink target (e.g. `ttyACM0`) is the device path to use.

### Updating Conbee/RaspBee Firmware

Use [GCFFlasher](https://github.com/dresden-elektronik/gcfflasher) to update the firmware on your device.

#### 1. Install GCFFlasher

Download and install the appropriate release for your platform from the [GCFFlasher releases page](https://github.com/dresden-elektronik/gcfflasher/releases).

#### 2. Stop deCONZ

The deCONZ software must not be running while flashing — it will hold the device open and prevent the flasher from accessing it.

```bash
docker stop deconz
# or
docker compose down
```

#### 3. Download the firmware

Download the correct firmware file for your device from [https://deconz.dresden-elektronik.de/deconz-firmware](https://deconz.dresden-elektronik.de/deconz-firmware).

The file naming scheme indicates which product the firmware is for:

- `ConBeeIII` — ConBee III USB stick
- `ConBeeII` — ConBee II USB stick
- `Rpi` — RaspBee (Raspberry Pi GPIO module)

#### 4. Flash the firmware

List detected devices to find your device path:

```bash
GCFFlasher4 -l
```

Then flash the firmware:

```bash
GCFFlasher4 -f <firmware-file> -d <device>
```

For example:

```bash
GCFFlasher4 -f deCONZ_ConBeeII_0x26720700.bin.GCF -d /dev/ttyACM0
```

#### 5. Restart deCONZ

```bash
docker start deconz
# or
docker compose up -d
```

### Notes on OTAU (Over The Air Updates)

The OTAU Plugin in deCONZ expects to find firmware files in the `/opt/deCONZ/otau` folder inside the container.

### Viewing the deCONZ ZigBee mesh with VNC

Setting the environment variable `DECONZ_VNC_MODE` to 1 enables a VNC server in the container. Connect to it with any VNC client to view the deCONZ ZigBee mesh. Set `DECONZ_VNC_PASSWORD` to change the default password ('changeme').

If not using host networking, add a `-p` directive for the VNC port (e.g. `-p 5900:5900`).

If VNC fails to start with a cookie error in the logs, try incrementing `DECONZ_VNC_PORT` (e.g. to 5901).

Enabling VNC also enables noVNC (browser-based access) on port 6080 by default, accessible at `https://hostname:6080/vnc.html`. Disable it with `DECONZ_NOVNC_PORT=0`.

### Gotchas / Known Issues

If you are not using host networking (`--net=host`) and wish to change the websocket port, make sure both sides of the `-p` port mapping match the `DECONZ_WS_PORT` value. For example, to use port 4443: `-e DECONZ_WS_PORT=4443 -p 4443:4443`.

### Issues / Contributing

Please raise any issues with this container at its GitHub repo: https://github.com/deconz-community/deconz-docker. Please check the "Gotchas / Known Issues" section above before raising an Issue on GitHub.

To contribute, please fork the GitHub repo, create a feature branch, and raise a Pull Request; for simple changes/fixes, it may be more effective to raise an Issue instead.

### Building Locally

Pulling `deconzcommunity/deconz` from Docker Hub is the recommended way to obtain this image. However, you can build this image locally by:

```bash
git clone https://github.com/deconz-community/deconz-docker.git
cd deconz-docker
docker build --build-arg VERSION=[BUILD_VERSION] --build-arg CHANNEL=[BUILD_CHANNEL] -t "[your-user/]deconz[:local]" ./Docker/
```

| Parameter         | Description                                                                                 |
| ----------------- | ------------------------------------------------------------------------------------------- |
| `[BUILD_VERSION]` | The version of deCONZ you wish to build.                                                    |
| `[BUILD_CHANNEL]` | The channel (i.e. stable or beta) that corresponds to the deCONZ version you wish to build. |
| `[your-user/]`    | Your username (optional).                                                                   |
| `[local]`         | Adds the tag `:local` to differentiate from pulled images (optional).                       |

_Note: VERSION and CHANNEL are required arguments and the image will fail to build if they are not specified._

### Acknowledgments

Dresden Elektronik for making deCONZ and the Conbee and RaspBee hardware.
