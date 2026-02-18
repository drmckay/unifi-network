FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV UNIFI_DEB_URL=https://dl.ui.com/unifi/10.1.85/unifi_sysvinit_all.deb

# 1) Base dependencies required by UniFi repo setup
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		apt-transport-https \
		wget \
		gnupg \
	&& rm -rf /var/lib/apt/lists/*

# 2) Add MongoDB 8.0 repository (Ubuntu 24.04 / noble)
RUN wget -qO - https://pgp.mongodb.com/server-8.0.asc \
	| gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg \
	&& echo 'deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse' \
	> /etc/apt/sources.list.d/mongodb-org-8.0.list

# 3) Install dependencies required by UniFi 10.1.x on Ubuntu 24.04
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		openjdk-25-jre-headless \
		mongodb-org-server \
		binutils \
		coreutils \
		adduser \
		libcap2 \
		curl \
		logrotate \
	&& rm -rf /var/lib/apt/lists/*

# 4) Install UniFi Network application from official .deb release
RUN wget -q "$UNIFI_DEB_URL" -O /tmp/unifi.deb \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends /tmp/unifi.deb \
	&& rm -f /tmp/unifi.deb \
	&& rm -rf /var/lib/apt/lists/*

# UniFi ports (informational + convenience for local testing)
EXPOSE 3478/udp 10001/udp 8080 8443 8843 8880 6789 27117

# Start UniFi service and keep container running
CMD ["bash", "-lc", "service unifi start && tail -F /usr/lib/unifi/logs/server.log"]
