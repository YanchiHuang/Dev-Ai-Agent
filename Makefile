# Makefile - Automation targets for alias framework and related utilities

ALIASES_SETUP_SCRIPT = config/scripts/setup-aliases.sh
ALIASES_UNINSTALL_SCRIPT = config/scripts/uninstall-aliases.sh

.PHONY: aliases-install aliases-uninstall aliases-reinstall aliases-status shellcheck-aliases

aliases-install:
	bash $(ALIASES_SETUP_SCRIPT)

aliases-uninstall:
	bash $(ALIASES_UNINSTALL_SCRIPT)

aliases-reinstall: aliases-uninstall aliases-install

aliases-status:
	@bash -lc 'source $$HOME/.bashrc >/dev/null 2>&1 || true; ai_cli_status || echo "alias framework not loaded"'

shellcheck-aliases:
	@command -v shellcheck >/dev/null 2>&1 || { echo 'shellcheck not installed'; exit 1; }
	@shellcheck config/bash/aliases/*.sh config/bash/functions/*.sh config/bash/init.sh || true

