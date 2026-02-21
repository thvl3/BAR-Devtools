ARG ELIXIR_VERSION=1.19.4
ARG OTP_VERSION=26.2.5.1
ARG DEBIAN_VERSION=trixie-20251208
FROM docker.io/hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
    build-essential git curl openssl libssl-dev inotify-tools \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /app
ENV MIX_ENV=dev

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY config config
RUN mix deps.compile

COPY lib lib
COPY priv priv
COPY assets assets
COPY rel rel
COPY test/support test/support

RUN printf 'import Config\n\
config :teiserver, Teiserver.Repo,\n\
  hostname: System.get_env("PGHOST", "localhost"),\n\
  pool_size: String.to_integer(System.get_env("PGPOOL", "20"))\n' > config/dev.secret.exs

RUN mix compile

RUN mix esbuild.install --if-missing
RUN mix sass.install

RUN mkdir -p priv/certs && cd priv/certs \
 && openssl dhparam -out dh-params.pem 2048 \
 && printf "[dn]\nCN=localhost\n[req]\ndistinguished_name=dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth" > /tmp/openssl.cnf \
 && openssl req -x509 -out localhost.crt -keyout localhost.key \
      -newkey rsa:2048 -nodes -sha256 \
      -subj '/CN=localhost' -extensions EXT -config /tmp/openssl.cnf \
 && rm /tmp/openssl.cnf

EXPOSE 4000 8200 8201 8888

CMD ["mix", "phx.server"]
