# -- build stage --
FROM hexpm/elixir:1.14.2-erlang-24.3.4.2-alpine-3.15.4 as build

ENV MIX_ENV=prod \
  LANG=C.UTF-8

RUN apk update
RUN apk add --no-cache make gcc libc-dev nodejs yarn libgcc libstdc++

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
RUN yarn --cwd assets install
RUN mix assets.deploy
RUN mix release

# -- application stage --
FROM alpine:3.15
ENV LANG=C.UTF-8

RUN apk add ncurses-dev libgcc libstdc++
RUN mkdir /app

COPY --from=build /app/_build/prod/rel/open890 /app

WORKDIR /app

# web UI
EXPOSE 4000

# UDP audio server
EXPOSE 60001

CMD ["/app/bin/open890", "start"]

