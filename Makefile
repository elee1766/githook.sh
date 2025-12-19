.PHONY: build clean test site-preview

SRC := src/header.sh \
       src/constants.sh \
       src/utils.sh \
       src/git.sh \
       src/semver.sh \
       src/http.sh \
       src/commands.sh \
       src/main.sh \
       src/footer.sh

OUT := githook.sh

build: $(OUT)

$(OUT): $(SRC)
	@cat $(SRC) > $(OUT)
	@chmod +x $(OUT)

clean:
	rm -f $(OUT)

test: build
	@sh test/run.sh

site-preview:
	caddy file-server --root site --listen :8283
