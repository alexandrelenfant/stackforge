SHELL := /bin/bash
.PHONY: help certs dev test prod down logs ps

# =========================
# HELP
# =========================

help:
	@./project.sh help

certs:
	@./project.sh certs

dev:
	@./project.sh dev

test:
	@./project.sh test

prod:
	@./project.sh prod

logs:
	@./project.sh logs

ps:
	@./project.sh ps

down:
	@./project.sh down
