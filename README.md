# UniFi Network (Docker)

This project runs the UniFi Network application from a custom image built from the included [Dockerfile](Dockerfile).

This setup is designed to:

- Use Traefik for UniFi Web UI and Inform URL access.
- Avoid publishing UniFi ports directly to the host.
- Attach UniFi to a VLAN-backed custom Docker network for controller subnet alignment.

## Files

- [Dockerfile](Dockerfile): Image definition using UniFi APT installation steps.
- [docker-compose.yml](docker-compose.yml): Local deployment with persistent volumes.
- [PORTAINER-STACK.md](PORTAINER-STACK.md): Portainer stack setup instructions.
- [.github/workflows/container-build.yml](.github/workflows/container-build.yml): GitHub Actions workflow for GHCR builds.

## GitHub Container Build (GHCR)

Repository: https://github.com/drmckay/unifi-network

Container package name:

- `ghcr.io/drmckay/unifi-network`

The workflow publishes on Git tag pushes (`v*`) and creates:

- version tag (example: `v1.0`)
- `latest` (same image digest)

Package-to-repository linking is enabled via:

- `GITHUB_TOKEN` publishing from the same repository
- OCI source label: `org.opencontainers.image.source`

First release build command:

- `git tag v1.0`
- `git push origin v1.0`

## Prerequisites

- Docker Engine
- Docker Compose v2
- Existing Traefik stack/network in Portainer (example network: `traefik_proxy`)
- VLAN/macvlan Docker network created in Portainer (example network: `unifi_vlan`)

## DNS / Hostnames

Set your DNS record to point to Traefik:

- `unifi.home` -> Traefik (Web UI + `/inform`)

Then update label hostnames in [docker-compose.yml](docker-compose.yml) to match your real domains.

## Start with Docker Compose

Before first start, ensure external networks exist:

- `traefik_proxy`
- `unifi_vlan`

1. Build and start:
   - `docker compose up -d --build`
2. Check status:
   - `docker compose ps`
3. View logs:
   - `docker compose logs -f unifi`

## Access UniFi

Open:

- `https://unifi.home`

Inform URL for device adoption:

- `http://unifi.home/inform`

If needed, install your browser certificate exception on first access.

## Stop / Remove

- Stop: `docker compose stop`
- Stop and remove containers: `docker compose down`
- Remove containers and volumes: `docker compose down -v`

## Data Persistence

The compose file creates named volumes:

- `unifi_data` -> `/var/lib/unifi`
- `unifi_logs` -> `/usr/lib/unifi/logs`
- `unifi_config` -> `/etc/unifi`

## Notes

- This image follows the requested APT-based UniFi installation flow.
- UniFi ports are not published on the host in this compose file.
- UniFi Web UI is routed by Traefik TCP passthrough to `8443`.
- Inform URL is routed by Traefik HTTP router to `8080`.
- For VLAN and Portainer setup details, see [PORTAINER-STACK.md](PORTAINER-STACK.md).
