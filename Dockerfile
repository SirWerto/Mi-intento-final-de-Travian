# Build stage 0
FROM elixir:alpine

# Set working directory
RUN mkdir /buildroot
WORKDIR /buildroot

# Copy our Elixir test application
COPY . my_travian

# And build the release
WORKDIR my_travian
ENV MIX_ENV=prod

# Create the storage directory
RUN mkdir storage

COPY mix.exs mix.lock ./
COPY config config
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

RUN mix release collector

# Build stage 1
FROM alpine

# Install some libs
RUN apk add --no-cache openssl && \
    apk add --no-cache ncurses-libs openssl bash ca-certificates libstdc++

# Install the released application
COPY --from=0 /buildroot/my_travian/_build/prod/rel/collector /my_travian

# Expose relevant ports
EXPOSE 8080
EXPOSE 8443

CMD ["/my_travian/bin/collector", "daemon"]