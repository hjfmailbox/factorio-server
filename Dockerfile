FROM ubuntu:20.04

LABEL maintainer="fluorine <hjf-mailbox@163.com>"

ARG USER=factorio
ARG GROUP=factorio
ARG PUID=845
ARG PGID=845

# version checksum of the archive to download
ARG VERSION
ARG SHA256

ENV DEBIAN_FRONTEND=noninteractive \
    PORT=34197 \
    RCON_PORT=27015 \
    VERSION=${VERSION} \
    SHA256=${SHA256} \
    SAVES=/factorio/saves \
    CONFIG=/factorio/config \
    MODS=/factorio/mods \
    SERVER_SETTINGS=/factorio/server-settings.json \
    SCENARIOS=/factorio/scenarios \
    SCRIPTOUTPUT=/factorio/script-output \
    PUID=${PUID} \
    PGID=${PGID} 

#COPY factorio_headless_x64_$VERSION.tar.xz /tmp/factorio_headless_x64_$VERSION.tar.xz
COPY files/scripts/*.sh /

#for arm64
COPY files/sources.list.d/sources-arm64.list /etc/apt/sources.list

#for amd(test on pc)
#COPY files/sources.list.d/sources-amd.list /etc/apt/sources.list

COPY files/config.ini /opt/factorio/config/config.ini

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
RUN set -ox pipefail \
    && if [[ "${VERSION}" == "" ]]; then \
        echo "build-arg VERSION is required" \
        && exit 1; \
    fi \
    && if [[ "${SHA256}" == "" ]]; then \
        echo "build-arg SHA256 is required" \
        && exit 1; \
    fi \
    && archive="/tmp/factorio_headless_x64_$VERSION.tar.xz" \
	&& mkdir -p /opt /factorio \
    #&& sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list \
    #&& sed -i s@/security.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list \
    && apt clean \
    && apt-get update -y \
    && apt upgrade -y \
    && apt install apt-utils wget curl tar xz-utils libc6-amd64-cross qemu-user pwgen -y \	
    && curl -sSL "https://www.factorio.com/get-download/$VERSION/headless/linux64" -o "$archive" \
	&& echo "$SHA256  $archive" | sha256sum -c \
    || (sha256sum "$archive" && file "$archive" && exit 1) \
    && tar -xf "$archive" --directory /opt \
    && chmod ugo=rwx /opt/factorio \
    && rm "$archive" \
    && ln -s "$SCENARIOS" /opt/factorio/scenarios \
    && ln -s "$SAVES" /opt/factorio/saves \
    && addgroup --gid "$PGID" "$GROUP" \
    && useradd -u "$PUID" -g "$PGID" -m -s /bin/sh "$USER" \
    && chown -R "$USER":"$GROUP" /opt/factorio /factorio \
	&& chmod +x /docker-entrypoint.sh

VOLUME /factorio
EXPOSE $PORT/udp $RCON_PORT/tcp
#ENTRYPOINT ["/bin/qemu-x86_64", "-L", "/usr/x86_64-linux-gnu", "/opt/factorio/bin/x64/factorio", "--start-server", "/factorio/saves/save.zip", "--server-settings", "/factorio/server-settings.json"]
ENTRYPOINT ["/docker-entrypoint.sh"]