.PHONY: all clean clean_elixir deps up install_tools yarn_install build_docker run_docker

all: clean build yarn_install

clean : clean_elixir clean_static_assets clean_node_deps

clean_elixir:
		rm -rf deps/ _build/

clean_static_assets:
		rm -rf priv/static_assets

clean_node_deps:
		rm -rf assets/node_modules

require_asdf:
		@if ! command -v asdf > /dev/null; then echo "'asdf' not detected. Please install asdf (https://asdf-vm.com/) to build."; exit 1; fi;

install_asdf_plugins: require_asdf
		@asdf plugin-list | grep erlang || asdf plugin-add erlang
		@asdf plugin-list | grep elixir || asdf plugin-add elixir
		@asdf plugin-list | grep nodejs || asdf plugin-add nodejs
		@asdf plugin-list | grep yarn || asdf plugin-add yarn

install_tools : install_asdf_plugins
		asdf install

install_elixir_deps: install_tools
		mix deps.get

compile_elixir_deps: install_elixir_deps
		mix deps.compile

build: compile_elixir_deps
		mix compile

yarn_install: install_tools
		yarn install --cwd assets

up: build yarn_install
		mix phx.server

run:
	mix phx.server

build_docker:
		docker build -t open890 .

docker: build_docker
		docker run -p 4000:4000 -it --rm open890:latest
