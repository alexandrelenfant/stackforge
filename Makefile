SHELL := /bin/bash

STACKFORGE_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ALIAS_NAME ?= stackforge

.PHONY: help generate install-alias

help:
	@echo "Available commands:"
	@echo "  make generate        - wrapper around ./stackforge.sh generate"
	@echo "  make install-alias   - wrapper around ./stackforge.sh install-alias"

generate:
	@"$(STACKFORGE_DIR)/stackforge.sh" generate

install-alias:
	@ALIAS_NAME="$(ALIAS_NAME)" "$(STACKFORGE_DIR)/stackforge.sh" install-alias
