.PHONY: build clean test test-hooks test-all

SRC := src/header.sh \
       src/constants.sh \
       src/utils.sh \
       src/commands.sh \
       src/main.sh \
       src/footer.sh

OUT ?= .githook.sh

build: $(OUT)

$(OUT): $(SRC)
	@cat $(SRC) > $(OUT)
	@chmod +x $(OUT)

clean:
	rm -f $(OUT)

test: build
	@sh test/run.sh

test-hooks: build
	@sh test/hooks/run.sh

test-all: test test-hooks
