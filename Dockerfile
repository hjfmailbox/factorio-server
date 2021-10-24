FROM ubuntu:20.04

LABEL maintainer="fluorine <hjf-mailbox@163.com>"

ARG USER=factorio
ARG GROUP=factorio
ARG PUID=845
ARG PGID=845

# version checksum of the archive to download
ARG VERSION=1.1.42
ARG SHA256=42909906a258dcd538148258dcb0ee9e03ca063851d3d8ca03d17126993b41d0

ENV PORT=34197 \
    RCON_PORT=27015 \
    VERSION=${VERSION} \
    SHA256=${SHA256} \
    SAVES=/factorio/saves \
    CONFIG=/factorio/config \
    MODS=/factorio/mods \
    SERVER_SETTINGS=/factorio/server-settings.json \
    SCENARIOS=/factorio/scenarios \
    SCRIPTOUTPUT=/factorio/script-output \
    PUID="$PUID" \
    PGID="$PGID" \
	archive="/tmp/factorio_headless_x64_$VERSION.tar.xz"

#COPY factorio_headless_x64_$VERSION.tar.xz "$archive"

RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list \
    && sed -i s@/security.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list \
    && apt clean \
    && apt-get update -y \
    && apt upgrade -y \
    && apt install wget curl tar xz-utils libc6-amd64-cross qemu-user -y \
    && mkdir -p /opt /factorio \	
    && curl -sSL "https://www.factorio.com/get-download/$VERSION/headless/linux64" -o "$archive" \
    && echo "$archive" \
    && tar -xf "$archive" --directory /opt \
    && chmod ugo=rwx /opt/factorio \
    && rm "$archive" \
    && ln -s "$SCENARIOS" /opt/factorio/scenarios \
    && ln -s "$SAVES" /opt/factorio/saves \
    && ln -s "$MODS" /opt/factorio/mods \
    && ln -s "$SERVER_SETTINGS" /opt/factorio/data/server-settings.json \
    && mkdir -p /opt/factorio/config/ \
    && addgroup --gid "$PGID" "$GROUP" \
    && useradd -u "$PUID" -g "$PGID" -m -s /bin/sh "$USER" \
    && chown -R "$USER":"$GROUP" /opt/factorio /factorio

EXPOSE $PORT/udp $RCON_PORT/tcp

ENTRYPOINT ["/bin/qemu-x86_64", "-L", "/usr/x86_64-linux-gnu", "/opt/factorio/bin/x64/factorio", "--start-server", "/factorio/saves/save.zip", "--server-settings", "/factorio/server-settings.json"]
