DEV_ROCKS = "lua-cjson 2.1.0" "kong 1.0.3" "luacov 0.12.0" "busted 2.0.rc12" "luacov-cobertura 0.2-1" "luacheck 0.20.0" "--server=http://luarocks.org/dev luaffi scm-1"
PROJECT_FOLDER = ./kong/plugins/api-transformer
LUA_PROJECT = kong-plugin-api-transformer

setup:
	@for rock in $(DEV_ROCKS) ; do \
		if luarocks list --porcelain $$rock | grep -q "installed" ; then \
			echo $$rock already installed, skipping ; \
		else \
			echo $$rock not found, installing via luarocks... ; \
			luarocks install $$rock; \
		fi \
	done;

check:
	cd $(PROJECT_FOLDER)
	@for rock in $(DEV_ROCKS) ; do \
		if luarocks list --porcelain $$rock | grep -q "installed" ; then \
			echo $$rock is installed ; \
		else \
			echo $$rock is not installed ; \
		fi \
	done;

install:
	-@luarocks remove $(LUA_PROJECT)
	luarocks make

test:
	busted --lazy /api-transformer/spec/fscgi_handler_spec.lua

package:
	luarocks make --pack-binary-rock

