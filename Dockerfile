# -- build stage --
FROM elixir:1.11.4-alpine AS build
ENV MIX_ENV=prod \
  LANG=C.UTF-8

RUN apk update
RUN apk add --no-cache make gcc libc-dev

# hex & rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Create the application directory.
RUN mkdir /app
WORKDIR /app

COPY config ./config
COPY lib ./lib
COPY priv ./priv
COPY assets ./assets
COPY mix.exs .
COPY mix.lock .

RUN mix deps.get
RUN mix deps.compile
RUN mix assets.deploy
RUN mix release

# -- application stage --
FROM alpine:3.13
ENV LANG=C.UTF-8

RUN apk add ncurses-dev
RUN mkdir /app

COPY --from=build /app/_build/prod/rel/open890 /app

WORKDIR /app
CMD ["/app/bin/open890", "start"]

