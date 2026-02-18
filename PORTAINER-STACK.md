# Portainer Stack Setup Guide (Traefik + VLAN)

This guide deploys UniFi with:

- Traefik access for Web UI and Inform URL
- No direct host port publishing from UniFi
- A VLAN-backed custom Docker network for proper subnet placement

## 1) Create VLAN interface on Docker host

Create the VLAN sub-interface on the host where Docker runs.

Example (VLAN ID 30 on `eth0`):

- `ip link add link eth0 name eth0.30 type vlan id 30`
- `ip link set eth0.30 up`

Make this persistent with your host network manager (Netplan, systemd-networkd, NetworkManager, etc.).

## 2) Create custom VLAN network in Portainer

In Portainer:

1. Go to **Networks** -> **Add network**.
2. Name: `unifi_vlan`
3. Driver: `macvlan`
4. Enable **Configuration** and set your subnet/gateway, for example:
   - Subnet: `192.168.30.0/24`
   - Gateway: `192.168.30.1`
5. Driver options:
   - `parent=eth0.30`
6. Create network.

Optional but recommended: set an **IP range** reserved for containers.

## 3) Confirm Traefik network name

Your Traefik container must already be attached to a shared Docker network (example: `traefik_proxy`).

If your Traefik network has a different name, replace `traefik_proxy` in the stack YAML.

## 4) Build UniFi image once on host

From this project directory:

- `docker compose build`

This creates the local image tag used below (`unifi-network_unifi:latest`).

## 5) Create stack in Portainer

1. Go to **Stacks** -> **Add stack**.
2. Name: `unifi-network`.
3. Paste this content:

```yaml
services:
  unifi:
    image: unifi-network_unifi:latest
    container_name: unifi-network
    restart: unless-stopped
    networks:
      - traefik_proxy
      - unifi_vlan
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=traefik_proxy"

      # UniFi Web UI over HTTPS (Traefik TCP passthrough -> container 8443)
      - "traefik.tcp.routers.unifi-ui.rule=HostSNI(`unifi.home`)"
      - "traefik.tcp.routers.unifi-ui.entrypoints=websecure"
      - "traefik.tcp.routers.unifi-ui.tls=true"
      - "traefik.tcp.routers.unifi-ui.tls.passthrough=true"
      - "traefik.tcp.routers.unifi-ui.service=unifi-ui-svc"
      - "traefik.tcp.services.unifi-ui-svc.loadbalancer.server.port=8443"

      # UniFi Inform URL over HTTP (Traefik HTTP router -> container 8080)
      - "traefik.http.routers.unifi-inform.rule=Host(`unifi.home`) && PathPrefix(`/inform`)"
      - "traefik.http.routers.unifi-inform.entrypoints=web"
      - "traefik.http.routers.unifi-inform.service=unifi-inform-svc"
      - "traefik.http.services.unifi-inform-svc.loadbalancer.server.port=8080"

    volumes:
      - unifi_data:/var/lib/unifi
      - unifi_logs:/usr/lib/unifi/logs
      - unifi_config:/etc/unifi

volumes:
  unifi_data:
  unifi_logs:
  unifi_config:

networks:
  traefik_proxy:
    external: true
  unifi_vlan:
    external: true
```

4. Verify hostname is set to:
  - `unifi.home`
5. Click **Deploy the stack**.

## 6) DNS and adoption

Create DNS record pointing to Traefik:

- `unifi.home`

For manual adoption from device CLI:

- `set-inform http://unifi.home/inform`

## 7) Validate

- In Portainer **Containers**, `unifi-network` should be running.
- Open `https://unifi.home` for the controller UI.
- Confirm adoption traffic reaches `http://unifi.home/inform`.

## 8) Update flow

After Dockerfile changes:

1. Rebuild on host: `docker compose build`
2. In Portainer stack view, click **Update the stack**.

## Notes

- This design intentionally does not publish UniFi ports to host.
- UniFi still receives LAN traffic through its `unifi_vlan` macvlan network IP.
- Keep Traefik and UniFi on a shared network (`traefik_proxy`) for proxy routing.
