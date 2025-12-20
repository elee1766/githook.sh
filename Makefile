.PHONY: build script site clean test test-hooks test-all

SRC := src/header.sh \
       src/constants.sh \
       src/utils.sh \
       src/commands.sh \
       src/main.sh \
       src/footer.sh

OUT ?= .githook.sh

build: script site

script: $(OUT)

$(OUT): $(SRC)
	@cat $(SRC) > $(OUT)
	@chmod +x $(OUT)

SITE_BASE := site/src/_base.m4
SITE_STATIC := site/src/style.css site/src/copy.js site/src/llms.txt

site: site/dist/index.html site/dist/docs/index.html site/dist/style.css site/dist/copy.js site/dist/llms.txt

site/dist/index.html: site/src/index.m4 $(SITE_BASE) | site/dist
	@cd site/src && m4 index.m4 > ../dist/index.html

site/dist/docs/index.html: site/src/docs/index.m4 $(SITE_BASE) | site/dist/docs
	@cd site/src && m4 docs/index.m4 > ../dist/docs/index.html

site/dist/%.css: site/src/%.css | site/dist
	@cp $< $@

site/dist/%.js: site/src/%.js | site/dist
	@cp $< $@

site/dist/%.txt: site/src/%.txt | site/dist
	@cp $< $@

site/dist:
	@mkdir -p site/dist

site/dist/docs: | site/dist
	@mkdir -p site/dist/docs

clean:
	rm -f $(OUT)
	rm -rf site/dist

test: build
	@sh test/run.sh

test-hooks: build
	@sh test/hooks/run.sh

test-all: test test-hooks
