## Notes on migration

This image is replacing the `marthoc/deconz` image.

If you are migrating an existing `marthoc/deconz` install to `deconzcommunity/deconz`, you need to modify your configuration before starting up on the new image. _Carefully_ follow these steps:

1. Make sure you have the latest backup from Phoscon.
2. Change the image from `marthoc/deconz` to `deconzcommunity/deconz`. Available tags can be found [here](https://hub.docker.com/r/deconzcommunity/deconz/tags).
3. Change the container mount point for your existing deCONZ volume from `/root/.local/share/dresden-elektronik/deCONZ` to `/opt/deCONZ`.

Pull the new image and start up.

## Notes for Synology users

We've had numerous reports of issues when deCONZ is run as an unprivileged user, which is the default behaviour. Because of this, it is highly recommended that you run deCONZ as root. To do so, set the following two environment variables:

```
DECONZ_UID=0
DECONZ_GID=0
```

### Notes for Raspberry Pi users

It may be necessary to run the deCONZ docker image in privileged mode for it to be able to connect and control a Conbee II or Raspbee device.
Using a docker compose file is the easiest to do so, and you need to make sure that `privileged: true` is contained in it.

See [Configuring deCONZ Container for Conbee II on Raspberry Pi](#configuring-deconz-container-for-conbee-ii-on-raspberry-pi) below

---


## deCONZ Docker Image

This Docker image containerizes the deCONZ software from Dresden Elektronik, which controls a ZigBee network using a Conbee USB or RaspBee GPIO serial interface. This image runs deCONZ in "minimal" mode, for control of the ZigBee network via the WebUIs ("Wireless Light Control" and "Phoscon") and over the REST API and Websockets, and optionally runs a VNC server for viewing and interacting with the ZigBee mesh through the deCONZ UI.

Conbee is supported on `amd64`, `armhf`/`armv7`, and `aarch64`/`arm64` (i.e. RaspberryPi 2/3B/3B+, and other arm64 boards) architectures; RaspBee is supported on `armhf`/`armv7` and `aarch64`/`arm64` (and see the "Configuring Raspbian for RaspBee" section below for instructions to configure Raspbian to allow access to the RaspBee serial hardware).

Builds of this image are available on (and should be pulled from) Docker Hub or Github Container Registry, with the following tags:

|Tag|Description|
|---|-----------|
|latest|Latest release of deCONZ, stable or beta|
|stable|Stable releases of deCONZ only|
|beta|Beta releases of deCONZ only|
|version|Specific versions of deCONZ, use only if you wish to pin your version of deCONZ, eg 2.13.02|

The "latest", "stable", and "version" tags have multiarch support for amd64, armv7, and arm64, so specifying any of these tags will pull the correct version for your architecture.

Please consult Docker Hub or Github Container Registry for the latest available versions of this image.

### Registries

- Docker Hub: `docker pull deconzcommunity/deconz:latest`
- Github Container Registry: `docker pull ghcr.io/deconz-community/deconz-docker:latest`, more info on can be found [here](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

### Running the deCONZ Container

#### Pre-requisites

Before running the command that creates the deconz Docker container, you may need to add your Linux user to the `dialout` group, which allows the user access to serial devices (i.e. Conbee/Conbee II/RaspBee/RaspBeeII):

```bash
sudo usermod -a -G dialout $USER
```

For a RaspBee/Raspbee 2 installation on a Raspberry PI 4B : Make sure to have Wiring Pi updated to the latest version! Install instructions can be found on http://wiringpi.com/wiringpi-updated-to-2-52-for-the-raspberry-pi-4b/

#### Command Line

```bash
docker run -d \
    --name=deconz \
    --restart=always \
    -p 80:80 \
    -p 443:443 \
    -v /etc/localtime:/etc/localtime:ro \
    -v /opt/deconz:/opt/deCONZ \
    --device=/dev/ttyUSB0 \
    deconzcommunity/deconz
```

#### Command line Options

|Parameter|Description|
|---------|-----------|
|`--name=deconz`|Names the container "deconz".|
|`--net=host`|Uses host networking mode for proper uPNP functionality; by default, the web UIs and REST API listen on port 80 and the websockets service listens on port 443. If these ports conflict with other services on your host, you can change them through the environment variables DECONZ_WEB_PORT and DECONZ_WS_PORT described below.|
|`--restart=always`|Start the container when Docker starts (i.e. on boot/reboot).|
|`-v /etc/localtime:/etc/localtime:ro`|Ensure the container has the correct local time (alternatively, use the TZ environment variable, see below).|
|`-v /opt/deconz:/opt/deCONZ`|Bind mount /opt/deconz (or the directory of your choice) into the container for persistent storage.|
|`--device=/dev/ttyUSB0`|Pass the serial device at ttyUSB0 into the container for use by deCONZ (you may need to investigate which device name is assigned to your device depending on if you are also using other usb serial devices; by default ConBee = /dev/ttyUSB0, Conbee II = /dev/ttyACM0, RaspBee = /dev/ttyAMA0 or /dev/ttyS0).|
|`deconzcommunity/deconz`|This image uses a manifest list for multiarch support; specifying deconzcommunity/deconz:latest or deconzcommunity/deconz:stable will pull the correct version for your arch.|

#### Environment Variables

Use these environment variables to change the default behaviour of the container.

|Parameter|Description|
|---------|-----------|
|`-e DECONZ_WEB_PORT=8080`|By default, the web UIs ("Wireless Light Control" and "Phoscon") and the REST API listen on port 80; only set this environment variable if you wish to change the listen port.|
|`-e DECONZ_WS_PORT=8443`|By default, the websockets service listens on port 443; only set this environment variable if you wish to change the listen port.|
|`-e DEBUG_INFO=1`|Sets the level of the deCONZ command-line flag --dbg-info (default 1).|
|`-e DEBUG_APS=0`|Sets the level of the deCONZ command-line flag --dbg-aps (default 0).|
|`-e DEBUG_ZCL=0`|Sets the level of the deCONZ command-line flag --dbg-zcl (default 0).|
|`-e DEBUG_ZDP=0`|Sets the level of the deCONZ command-line flag --dbg-zdp (default 0).|
|`-e DEBUG_DDF=0`|Sets the level of the deCONZ command-line flag --dbg-ddf (default 0).|
|`-e DEBUG_DEV=0`|Sets the level of the deCONZ command-line flag --dbg-dev (default 0).|
|`-e DEBUG_OTA=0`|Sets the level of the deCONZ command-line flag --dbg-ota (default 0).|
|`-e DEBUG_ERROR=0`|Sets the level of the deCONZ command-line flag --dbg-error (default 0).|
|`-e DEBUG_HTTP=0`|Sets the level of the deCONZ command-line flag --dbg-http (default 0).|
|`-e DECONZ_DEVICE=/dev/ttyUSB1`|By default, deCONZ searches for RaspBee at /dev/ttyAMA0 and Conbee at /dev/ttyUSB0; when using other USB devices (e.g. a Z-Wave stick) deCONZ may not find RaspBee/Conbee properly. Set this environment variable to the same string passed to --device to force deCONZ to use the specific USB device.|
|`-e TZ=America/Toronto`|Set the local time zone so deCONZ has the correct time.|
|`-e DECONZ_VNC_MODE=1`|Set this option to enable VNC access to the container to view the deCONZ ZigBee mesh|
|`-e DECONZ_VNC_PORT=5900`|Default port for VNC mode is 5900; this option can be used to change this port|
|`-e DECONZ_VNC_PASSWORD=changeme`|Default password for VNC mode is 'changeme'; this option can (should) be used to change the default password|
|`-e DECONZ_VNC_PASSWORD_FILE=/var/secrets/my_secret`|Per default this is disabled and DECONZ_VNC_PASSWORD is used. Details on creating secrets for use with Docker containers can be found in the [corresponding section from the official documentation](https://docs.docker.com/engine/swarm/secrets/) |
|`-e DECONZ_NOVNC_PORT=6080`|Default port for noVNC is 6080; this option can be used to change this port; setting the port to `0` will disable the noVNC functionality|
|`-e DECONZ_UPNP=0`|Set this option to 0 to disable uPNP, see: https://github.com/dresden-elektronik/deconz-rest-plugin/issues/274|
|`-e DECONZ_UID=1000`|Set the user id of deCONZ volume|
|`-e DECONZ_GID=1000`|Set the group id of deCONZ volume|
|`-e DECONZ_START_VERBOSE=0`|Set this option to 0 to disable verbose of start script, set to 1 to enable `set -x` logging|

#### Docker-Compose

A full docker-compose.yml file is provided in the root of this image's GitHub repo. You may also copy/paste the following into your existing docker-compose.yml, modifying the options as required (omit the `version` and `services` lines as your docker-compose.yml will already contain these).

```yaml
version: "2"
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
      - DEBUG_OTAU=0
```

Then, you can do `docker-compose pull` to pull the latest deconzcommunity/deconz image, `docker-compose up -d` to start the deconz container service, and `docker-compose down` to stop the deconz service and delete the container. Note that these commands will also pull, start, and stop any other services defined in docker-compose.yml.

#### Healthcheck for container status

Healthcheck is used for checking Phoscon web app port for detect current healthy state of the running deCONZ container.

#### Running on Docker for Mac / Docker for Windows

The `--net=host` option is not yet supported on Mac/Windows. To run this container on those platforms, explicitly specify the ports in the run command and omit `--net=host`:

```bash
docker run -d \
    --name=deconz \
    -p 80:80 \
    -p 443:443 \
    --restart=always \
    -v /opt/deconz:/opt/deCONZ \
    --device=/dev/ttyUSB0 \
    -e DECONZ_WEB_PORT=80 \
    -e DECONZ_WS_PORT=443 \
    deconzcommunity/deconz
```

### Configuring Raspbian for RaspBee

Raspbian defaults Bluetooth to /dev/ttyAMA0 and configures a login shell over serial (tty). You must disable the tty login shell and enable the serial port hardware, and swap Bluetooth to /dev/S0, to allow RaspBee to work properly under Docker.

To disable the login shell over serial and enable the serial port hardware:

1. `sudo raspi-config`
2. Select `Interfacing Options`
3. Select `Serial`
4. “Would you like a login shell to be accessible over serial?” Select `No`
5. “Would you like the serial port hardware to be enabled?” Select `Yes`
6. Exit raspi-config and reboot

To swap Bluetooth to /dev/S0 (moving RaspBee to /dev/ttyAMA0), run the following command and then reboot:

```bash
echo 'dtoverlay=pi3-miniuart-bt' | sudo tee -a /boot/config.txt
```

After running the above command and rebooting, RaspBee should be available at /dev/ttyAMA0.

### Configuring deCONZ Container for Conbee II on Raspberry Pi

It may be necessary to run the deCONZ docker image in privileged mode for it to be able to connect and control a Conbee II or Raspbee device.
Using a docker compose file is the easiest to do so, and you need to make sure that `privileged: true` is contained in it.

Here is an example of a docker-compose file:

```yaml
version: "3"
services:
  deconz:
    image: deconzcommunity/deconz:stable
    container_name: deconz
    restart: always
    privileged: true                # This is important! Without it, the deCONZ image won't be able to connect to Conbee II.
    ports: 
      - 80:80
      - 443:443
    volumes:
      - /opt/deCONZ:/opt/deCONZ
    devices:
      - /dev/ttyACM0                # This is the USB device that Conbee II is running on.
    environment:
      - TZ=Europe/Berlin
      - DECONZ_WEB_PORT=80
      - DECONZ_WS_PORT=443
      - DEBUG_INFO=1
      - DEBUG_APS=0
      - DEBUG_ZCL=0
      - DEBUG_ZDP=0
      - DEBUG_OTAU=0
      - DEBUG_HTTP=0
      - DECONZ_DEVICE=/dev/ttyACM0   # This is the USB device that Conbee II is running on.
      - DECONZ_START_VERBOSE=0
```

Also note, that the USB device where Conbee II is installed needs to be mapped into the deCONZ docker container.
To find out which path Conbee II is on, you can use the following command: 

```shell
ls -al /dev/serial/by-id/usb-dresden_elektronik_ingenieurtechnik_GmbH_ConBee_II_DE2251419-if00

# output:
lrwxrwxrwx 1 root root 13 Jul 23 00:13 /dev/serial/by-id/usb-dresden_elektronik_ingenieurtechnik_GmbH_ConBee_II_DE2251419-if00 -> ../../ttyACM0
```

Note the symbolic link pointing to `/dev/ttyACM0`. That's the serial device that Conbee II USB Stick is occupying!

### Updating Conbee/RaspBee Firmware

Firmware updates from the web UI will fail silently. Instead, an interactive utility script is provided as part of this Docker image that you can use to flash your device's firmware. The script has been tested and verified to work for Conbee on amd64 Debian linux and armhf Raspbian Stretch and RaspBee on armhf Raspbian Stretch.

Note, however, that this way of flashing the firmware **is not guaranteed to work**. If it does it will speed up the whole process. If it doesn't you just have to update the firmware manually as described here:

https://github.com/dresden-elektronik/deconz-rest-plugin/wiki/Update-deCONZ-manually

This could involve that you have to plug your device into another system where the deCONZ software runs without docker (i.e. windows).

The script calls the flashing tool `GCFFlasher_internal` which will output any failures. In some situations the flasher runs successfully but deCONZ couldn't be started afterwards: `disconnected device`. In all these cases you may start the process some more times and/or play with the parameters for `retries` and `timeout`.

To use the script for updating the firmware, follow the below instructions:

##### 1. Check your deCONZ container logs for the update firmware file name:
Type `docker logs [container name]`, and look for lines near the beginning of the log that look like this, noting the `.GCF` file name listed (you'll need this later):
```
GW update firmware found: /usr/share/deCONZ/firmware/deCONZ_Rpi_0x261e0500.bin.GCF
GW firmware version: 0x261c0500
GW firmware version shall be updated to: 0x261e0500
```

##### 2. Stop your running deCONZ container. You must do this or the firmware update will fail:
```bash
docker stop [container name]
```
or
```bash
docker-compose down
```

##### 3. Invoke the firmware update script: 
```bash
docker run -it --rm --entrypoint "/firmware-update.sh" --privileged --cap-add=ALL -v /dev:/dev -v /lib/modules:/lib/modules -v /sys:/sys deconzcommunity/deconz
```

If you have multiple usb devices, you can map the `/dev/...` volume corresponding to your Conbee/Raspbee to avoid wrong path mapping. 

```bash
docker run -it --rm --entrypoint "/firmware-update.sh" --privileged --cap-add=ALL -v /dev/serial/by-id/usb-dresden_elektronik_ingenieurtechnik_GmbH_ConBee_II_DExxxxxxx-if00:/dev/ttyACM0  -v /lib/modules:/lib/modules -v /sys:/sys deconzcommunity/deconz
```

You could also put additional options to the end of this call:
```bash
docker run ... deconzcommunity/deconz [option1] [value1] [option2] [value2] ...
```
If these are valid options for the flashing tool they will be added to the call:
|Option|Description|Default (if any)|
|------|-----------|----------------|
|`-f [firmware]`|flash firmware file||
|`-d [device]`|device number or path to use, e.g. 0, /dev/ttyUSB0 or RaspBee|The value of DECONZ_DEVICE|
|`-t [timeout]`|retry until timeout (seconds) is reached|60|
|`-R [retries]`|max. retries||
|`-x [loglevel]`|debug log level 0, 1, 3||

Please note that the values for device and firmware-file are still asked by the script but your options are taken as default.

##### 4. Follow the prompts:
- Enter the path (e.g. `/dev/ttyUSB0`) that corresponds to your device in the listing.
- Type or paste the full file name that corresponds to the file name that you found in the deCONZ container logs in step 1 (or, select a different filename, but you should have a good reason for doing this).
If there are newer firmware files ([found here](https://deconz.dresden-elektronik.de/deconz-firmware/)) than the ones contained in your docker you could specify the name and the script will try to initiate a download. Just follow the prompts.
- If the device/path, file name and listed options look OK, type Y to start flashing!

##### 5. Restart your deCONZ container:
```bash
docker start [container name]
```
or
```bash
docker-compose up
```

#### Firmware Flashing Script FAQ

Q: Why does the script give an error about not being able to unload modules ftdi_sio and usbserial, or that the device couldn't be rest?

A: In order to flash the device, no other program or device on the system can be using these kernel modules or the device. Stop any program/container that could be using the modules or device (likely deCONZ) and then invoke the script again. If the error persists, you may need to temporarily remove other USB serial devices from the system in order allow the script to completely unload the kernel modules.

Q: Why does a flash run fail after some seconds even if I specified a timeout much longer?

A: By setting a timeout you allowed the flashing tool to start as many runs as will fit into this period. The timeout of a single run can not be changed by parameters.

### Notes on OTAU (Over The Air Updates)

The OTAU Plugin in deCONZ expects to find firmware files in the `/opt/deCONZ/otau` folder inside the container.

### Viewing the deCONZ ZigBee mesh with VNC

Setting the environment variable DECONZ_VNC_MODE to 1 enables a VNC server in the container; connect to this VNC server with a VNC client to view the deCONZ ZigBee mesh. The environment variable DECONZ_VNC_PORT allows you to control the port the VNC server listens on (default 5900); environment variable DECONZ_VNC_PASSWORD allows you to set the password for the VNC server (default is 'changeme' and should be changed!).

Note that if you are not using --host networking, you will need to add a -p directive for the DECONZ_VNC_PORT (i.e. `-p 5900:5900`).

If VNC does not work and you see an error like the following in the container logs, you can resolve by incrementing the DECONZ_VNC_PORT variable (i.e. to 5901 or 5902). 
```
tigervncserver: /usr/bin/Xtigervnc did not start up, please look into '/root/.vnc/debian:0.log' to determine the reason! -2
Invalid MIT-MAGIC-COOKIE-1 keyqt.qpa.screen: QXcbConnection: Could not connect to display :0
Could not connect to any X display.
```

By enabling VNC, per default, you also enabled noVNC which allows you to connect using a browser. Per default the port is been set to 6080 and if you are not using "--host" networking you need to open the port using the -p directive.
Access is through https://hostname:6080/vnc.html, this is a self signed SSL certificate so you need to accept it before you can access the page. If you do not want to enable noVNC, you can disable it using the environment variable `DECONZ_NOVNC_PORT=0`

NoVNC acts as a proxy for the VNC server, meaning that if you disable VNC functionality, noVNC will not be available either.

The minimum port for DECONZ_VNC_PORT must be 5900 or higher and the minimum port for DECONZ_NOVNC_PORT must be 6080 or higher. 

### Gotchas / Known Issues

Firmware updates from the web UI will fail silently and the Conbee/RaspBee device will stay at its current firmware level. See "Updating Conbee/RaspBee Firmware" above for instructions to update your device's firmware when a new version is available.

If you are NOT using host networking (i.e. `--net=host`), and wish to change the websocket port, make sure that both "ends" of the port directive (i.e. `-p`) are changed to match the port specified in the `DECONZ_WS_PORT` environment variable (otherwise, the websocket will not connect resulting in possibly no updating of lights, switches and sensors). For example, if you wish to change the websocket port to 4443, you must specify BOTH `-e DECONZ_WS_PORT=4443` AND `-p 4443:4443` in your `docker run` command.

Over-the-air update functionality is currently untested.

### Issues / Contributing

Please raise any issues with this container at its GitHub repo: https://github.com/deconz-community/deconz-docker. Please check the "Gotchas / Known Issues" section above before raising an Issue on GitHub in case the issue is already known.

To contribute, please fork the GitHub repo, create a feature branch, and raise a Pull Request; for simple changes/fixes, it may be more effective to raise an Issue instead.

### Building Locally

Pulling `deconzcommunity/deconz` from Docker Hub is the recommended way to obtain this image. However, you can build this image locally by:

```bash
git clone https://github.com/deconz-community/deconz-docker.git
cd deconz-docker
docker build --build-arg VERSION=`[BUILD_VERSION]` --build-arg CHANNEL=`[BUILD_CHANNEL]` -t "[your-user/]deconz[:local]" ./Docker/
```

|Parameter|Description|
|---------|-----------|
|`[BUILD_VERSION]`|The version of deCONZ you wish to build.|
|`[BUILD_CHANNEL]`|The channel (i.e. stable or beta) that corresponds to the deCONZ version you wish to build.|
|`[your-user/]`|Your username (optional).|
|`deconz`|The name you want the built Docker image to have on your system (default: deconz).|
|`[local]`|Adds the tag `:local` to the image (to help differentiate between this image and your locally built image) (optional).|

*Note: VERSION and CHANNEL are required arguments and the image will fail to build if they are not specified.*  

### Acknowledgments

Dresden Elektronik for making deCONZ and the Conbee and RaspBee hardware.

https://github.com/multiarch/qemu-user-static for making multi-arch builds on Travis CI possible.
