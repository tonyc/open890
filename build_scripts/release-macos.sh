#!/usr/bin/env bash

set -e
set -x

export MIX_ENV=prod
export SECRET_KEY_BASE=$(mix phx.gen.secret)

rm -rf _build/
mix clean --all
mix deps.get --only prod
yarn install --cwd assets
mix assets.deploy
mix release

