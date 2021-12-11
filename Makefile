.PHONY: all clean clean_elixir deps up install_tools yarn_install

all: clean compile yarn_install

clean : clean_elixir clean_static_assets clean_node_deps

clean_elixir:
		mix clean --deps
		rm -rf deps/

clean_static_assets:
		rm -rf priv/static_assets

clean_node_deps:
		rm -rf assets/node_modules

install_tools : install_asdf_plugins
		asdf install

install_asdf_plugins:
		@asdf plugin-list | grep erlang || asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
		@asdf plugin-list | grep elixir || asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
		@asdf plugin-list | grep nodejs || asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
		@asdf plugin-list | grep yarn || asdf plugin-add yarn

install_elixir_deps: install_tools
		mix deps.get

compile_elixir_deps: install_elixir_deps
		mix deps.compile

compile: compile_elixir_deps
		mix compile

yarn_install: install_tools
		yarn install --cwd assets

up: compile yarn_install
		mix phx.server
