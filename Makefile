REPO		?= riak_inex
PKG_REVISION    ?= $(shell git describe --tags)
PKG_VERSION	?= $(shell git describe --tags | tr - .)
PKG_ID           = riak_inex-$(PKG_VERSION)
PKG_BUILD        = 1
BASE_DIR         = $(shell pwd)
ERLANG_BIN       = $(shell dirname $(shell which erl))
REBAR            = $(BASE_DIR)/rebar
OVERLAY_VARS    ?=


.PHONY: all dist package.src package clean deps test escriptize

all: compile escriptize

compile: deps
	./rebar compile

deps:
	./rebar get-deps

clean:
	./rebar clean

escriptize:
	./rebar escriptize skip_deps=true

test: compile
	./rebar eunit skip_deps=true

export PKG_VERSION PKG_ID PKG_BUILD BASE_DIR ERLANG_BIN REBAR OVERLAY_VARS RELEASE RIAK_CS_EE_DEPS

dist: package.src
	cp package/$(PKG_ID).tar.gz .

package: package/$(PKG_ID).tar.gz
	$(MAKE) -C package -f $(PKG_ID)/deps/node_package/Makefile

package/$(PKG_ID).tar.gz: package.src

package.src: deps
	mkdir -p package
	rm -rf package/$(PKG_ID)
	git archive --format=tar --prefix=$(PKG_ID)/ $(PKG_REVISION)| (cd package && tar -xf -)
	make -C package/$(PKG_ID) deps
	for dep in package/$(PKG_ID)/deps/*; do \
		echo "Processing dep: $${dep}"; \
	    mkdir -p $${dep}/priv; \
        git --git-dir=$${dep}/.git describe --tags >$${dep}/priv/vsn.git; \
	done
	find package/$(PKG_ID) -depth -name ".git" -exec rm -rf {} \;
	tar -C package -czf package/$(PKG_ID).tar.gz $(PKG_ID)
