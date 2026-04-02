FROM ubuntu:24.04
ARG LUX_VERSION=latest
RUN apt-get update && apt-get install -y --no-install-recommends \
        lua5.1 liblua5.1-dev libreadline-dev \
        build-essential git ca-certificates curl libgpgme11t64 jq \
    && DEB_ARCH=$(dpkg --print-architecture) \
    && DEB_URL=$(curl -fsSL "https://api.github.com/repos/lumen-oss/lux/releases/${LUX_VERSION}" \
       | jq -r --arg arch "$DEB_ARCH" '.assets[] | select(.name | test("_" + $arch + "\\.deb$")) | .browser_download_url') \
    && curl -fsSL "$DEB_URL" -o /tmp/lux.deb \
    && dpkg -i /tmp/lux.deb \
    && rm /tmp/lux.deb \
    && apt-get purge -y jq && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*
RUN lx install-lua \
    && ln -sf /usr/bin/lua5.1 /root/.local/share/lux/tree/5.1/.lua/bin/lua
WORKDIR /bar
