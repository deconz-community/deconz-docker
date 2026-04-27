# deCONZ Docker Image

This repository provides a Docker image for running deCONZ with ConBee and RaspBee adapters. The container includes Phoscon, the REST API, the WebSocket API, and optional VNC/noVNC access for mesh visualization.

- Architectures: `amd64`, `arm/v7`, `arm64`
- Registries:
  - Docker Hub: `deconzcommunity/deconz:latest`
  - GHCR: `ghcr.io/deconz-community/deconz-docker:latest`

| Tag     | Meaning                                      |
| ------- | -------------------------------------------- |
| latest  | Latest release (stable or beta)              |
| stable  | Stable releases only                         |
| beta    | Beta releases only                           |
| version | Specific version tag, e.g. `2.13.02`         |

## Quick Start

If you want a straightforward first setup, the steps below are usually enough to get deCONZ running.

1. Copy `docker-compose.yml` from this repository to your host.
2. Edit the compose file and set at least the following values:
   - `TZ` to your local timezone (for correct scheduling and logs)
   - `DECONZ_DEVICE` to your adapter path (for example `/dev/ttyACM0`)
   - the data volume path (for example `/opt/deconz:/opt/deCONZ`)
3. Pull and start the container:

```bash
docker compose pull
docker compose up -d
```

4. Open Phoscon in your browser: `http://<host-ip>:<DECONZ_WEB_PORT>`.

Use `docker compose down` when you want to stop the container.

> [!TIP]
> If your adapter is not detected on first boot, set `DECONZ_DEVICE` explicitly and restart once.

## Most Used Settings

Most installations only need a small set of settings. In practice, the values below are the most relevant for first setup and day-to-day operation.

| Variable | Typical value | Purpose |
| --- | --- | --- |
| `TZ` | `Europe/Berlin` | Container timezone |
| `DECONZ_DEVICE` | `/dev/ttyACM0` | Explicit ZigBee adapter path |
| `DECONZ_WEB_PORT` | `80` | HTTP UI + REST API |
| `DECONZ_WS_PORT` | `443` | WebSocket API |
| `DECONZ_BAUDRATE` | `115200` / `38400` | Required for ConBee III / RaspBee II |

<details>
<summary>Hardware-specific notes</summary>

- **Alexa delays**: set `DECONZ_WS_PORT=8443` and make sure the published port mapping matches this value.
- **ConBee III**: set `DECONZ_BAUDRATE=115200`.
- **RaspBee II**: set `DECONZ_BAUDRATE=38400`.
- **Synology permission issues**: if USB access fails, try `DECONZ_UID=0` and `DECONZ_GID=0`.

</details>

<details>
<summary>Environment variables (full list)</summary>

The following table includes all supported runtime variables exposed by this image. Defaults are shown so you can quickly see what changes are optional.

| Variable | Default | Description |
| --- | --- | --- |
| `DECONZ_WEB_PORT` | `80` | HTTP UI and REST API port |
| `DECONZ_WEBS_PORT` | `0` | HTTPS UI port (`0` disables) |
| `DECONZ_WS_PORT` | `443` | WebSocket port |
| `DECONZ_DEVICE` | auto | Adapter path (`/dev/ttyUSB0`, `/dev/ttyACM0`, `/dev/ttyAMA0`, `/dev/ttyS0` are auto-checked) |
| `DECONZ_BAUDRATE` | `0` | Adapter baud rate |
| `DECONZ_UPNP` | `1` | Set `0` to disable UPnP |
| `DECONZ_APPDATA_DIR` | `/opt/deCONZ` | App data directory |
| `DECONZ_UID` | `1000` | UID for data permissions |
| `DECONZ_GID` | `1000` | GID for data permissions |
| `NON_ROOT` | `0` | `0` runs as `deconz` user, `1` runs as root |
| `DECONZ_START_VERBOSE` | `0` | Set `1` for `set -x` start-script logging |
| `DECONZ_VNC_MODE` | `0` | Enable VNC mode |
| `DECONZ_VNC_PORT` | `5900` | VNC port |
| `DECONZ_VNC_PASSWORD` | `changeme` | VNC password |
| `DECONZ_VNC_DISABLE_PASSWORD` | `0` | Set `1` to disable VNC auth (trusted networks only) |
| `DECONZ_VNC_PASSWORD_FILE` | `0` | Read VNC password from file |
| `DECONZ_NOVNC_PORT` | `6080` | noVNC port (`0` disables) |
| `DECONZ_DEV_TEST_MANAGED` | `0` | deCONZ `--dev-test-managed` |
| `DEBUG_INFO` | `1` | deCONZ `--dbg-info` |
| `DEBUG_APS` | `0` | deCONZ `--dbg-aps` |
| `DEBUG_ZCL` | `0` | deCONZ `--dbg-zcl` |
| `DEBUG_ZDP` | `0` | deCONZ `--dbg-zdp` |
| `DEBUG_DDF` | `0` | deCONZ `--dbg-ddf` |
| `DEBUG_DEV` | `0` | deCONZ `--dbg-dev` |
| `DEBUG_OTA` | `0` | deCONZ `--dbg-ota` |
| `DEBUG_ERROR` | `0` | deCONZ `--dbg-error` |
| `DEBUG_HTTP` | `0` | deCONZ `--dbg-http` |

</details>

## Networking

deCONZ works well with both bridge and host networking, but it is important to keep port values and mappings aligned with your chosen mode.

- Bridge networking: publish the ports you actually use (`80`, `443`, and optionally `5900`, `6080` for VNC/noVNC).
- If you change `DECONZ_WS_PORT`, both sides of the port mapping must match (for example `4443:4443`).
- Host networking (`network_mode: host`): do not use `ports:` in the compose file.

> [!NOTE]
> If Alexa commands are delayed, the most common fix is `DECONZ_WS_PORT=8443` with matching port mapping.

## Troubleshooting

If startup does not behave as expected, the checks below cover the most common causes.

- Device not found: set `DECONZ_DEVICE` explicitly and verify the adapter path using `ls -al /dev/serial/by-id/`.
- VNC lock/cookie errors: increment `DECONZ_VNC_PORT` (for example `5901`) and restart the container.
- noVNC URL: `https://<host>:<DECONZ_NOVNC_PORT>/vnc.html`.

<details>
<summary>RaspBee on Raspberry Pi (serial setup)</summary>

Raspbian often assigns serial and Bluetooth devices in a way that conflicts with RaspBee, so this one-time host configuration is sometimes required.

1. Run `sudo raspi-config`.
2. Go to `Interfacing Options` -> `Serial`.
3. Disable login shell over serial.
4. Enable serial hardware.
5. Reboot.

Then run and reboot again:

```bash
echo 'dtoverlay=pi3-miniuart-bt' | sudo tee -a /boot/firmware/config.txt
```

On older systems use `/boot/config.txt`.

</details>

<details>
<summary>ConBee II on Raspberry Pi (privileged fallback)</summary>

If adapter access fails on Raspberry Pi, adding `privileged: true` in Compose can help in environments with stricter USB access behavior.

</details>

<details>
<summary>Firmware updates (ConBee/RaspBee)</summary>

Use [GCFFlasher](https://github.com/dresden-elektronik/gcfflasher) for firmware updates:

1. Stop deCONZ (`docker stop deconz` or `docker compose down`).
2. Download the correct firmware from <https://deconz.dresden-elektronik.de/deconz-firmware>.
3. Detect adapter: `GCFFlasher4 -l`.
4. Flash: `GCFFlasher4 -f <firmware-file> -d <device>`.
5. Restart the container.

OTAU files are expected in `/opt/deCONZ/otau` inside the container.

</details>

## Upgrading and Rollback

Upgrades are usually straightforward, but backing up your application data first makes rollback much safer if you need to return to a previous image tag.

- Back up app data (`/opt/deCONZ`) before upgrades.
- Upgrade:

```bash
docker compose pull
docker compose up -d
```

- Roll back: pin an older image tag in Compose and run `docker compose up -d` again.

> [!IMPORTANT]
> Keep a backup of `/opt/deCONZ` before major version upgrades so rollback is predictable and quick.

<details>
<summary>Build locally</summary>

```bash
git clone https://github.com/deconz-community/deconz-docker.git
cd deconz-docker
docker build --build-arg VERSION=<version> --build-arg CHANNEL=<stable|beta> -t deconz:local ./docker/
```

`VERSION` and `CHANNEL` are required build args.

</details>

## Issues and Contributing

If you run into image-specific issues, please open an issue in this repository. Contributions are welcome, and for smaller ideas or questions it is often helpful to discuss in an issue first.

- Issues: <https://github.com/deconz-community/deconz-docker/issues>
- PRs welcome; for small questions, opening an issue first can be faster.
