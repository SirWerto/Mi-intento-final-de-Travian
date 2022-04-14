# Build stage 0
FROM elixir:alpine

# Set working directory
RUN mkdir /buildroot
WORKDIR /buildroot

# Copy our Erlang test application
COPY my_travian my_travian

# And build the release
WORKDIR my_travian
RUN mix MIX_ENV=prod release collector

# Build stage 1
FROM alpine

# Install some libs
RUN apk add --no-cache openssl && \
    apk add --no-cache ncurses-libs openssl bash ca-certificates

# Install the released application
COPY --from=0 /buildroot/my_travian/_build/prod/rel/collector /my_travian

# Expose relevant ports
EXPOSE 8080
EXPOSE 8443

CMD ["/my_travian/bin/collector", "shell"]