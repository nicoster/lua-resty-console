DST_DIR = lua-resty-console

all: lint test

lint:
	docker-compose run --rm app luacheck .

build:
	docker build -t nickxiao/openresty-testsuite:latest -f Dockfile .

push_images:
	docker push nickxiao/openresty-testsuite:latest

test: test_openresty test_luajit_integrational

test_openresty:
	@echo OPENRESTY:
	@docker-compose run --rm app resty-busted spec

test_luajit_integrational:
	@echo LUAJIT INTEGRATIONAL:
	@docker-compose run --rm app bin/test_with_expect

shell:
	docker-compose run --rm app

sync:
	time (for d in lib/ Makefile lua/ bin/ conf/; do rsync -rP $$d $(TARGET):$(DST_DIR)/$$d & done; wait)

.PHONY: lint test shell repl build push_images test_openresty \
	test_luajit_integrational 
