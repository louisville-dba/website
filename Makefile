.PHONY: help install install-hugo serve build clean new-post check

# Hugo version & install location
HUGO_VERSION ?= 0.161.1
HUGO_BIN_DIR ?= $(HOME)/.local/bin
HUGO := $(shell command -v hugo 2>/dev/null || echo $(HUGO_BIN_DIR)/hugo)

# Detect OS / ARCH for the install target
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_S),Linux)
  HUGO_OS := linux
endif
ifeq ($(UNAME_S),Darwin)
  HUGO_OS := darwin
endif
ifeq ($(UNAME_M),x86_64)
  HUGO_ARCH := amd64
endif
ifeq ($(UNAME_M),aarch64)
  HUGO_ARCH := arm64
endif
ifeq ($(UNAME_M),arm64)
  HUGO_ARCH := arm64
endif

HUGO_TARBALL := hugo_extended_$(HUGO_VERSION)_$(HUGO_OS)-$(HUGO_ARCH).tar.gz
HUGO_URL := https://github.com/gohugoio/hugo/releases/download/v$(HUGO_VERSION)/$(HUGO_TARBALL)

help: ## Show this help
	@echo "Louisville DBA — site Makefile"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

install: install-hugo ## Install everything needed to develop the site

install-hugo: ## Install Hugo (extended) to ~/.local/bin if not already present
	@if command -v hugo >/dev/null 2>&1; then \
		echo "✓ hugo already installed: $$(hugo version)"; \
	else \
		echo "Installing Hugo extended v$(HUGO_VERSION) for $(HUGO_OS)-$(HUGO_ARCH)..."; \
		mkdir -p $(HUGO_BIN_DIR); \
		TMPDIR=$$(mktemp -d) && \
		curl -fsSL "$(HUGO_URL)" -o "$$TMPDIR/$(HUGO_TARBALL)" && \
		tar -xzf "$$TMPDIR/$(HUGO_TARBALL)" -C "$$TMPDIR" hugo && \
		mv "$$TMPDIR/hugo" $(HUGO_BIN_DIR)/hugo && \
		chmod +x $(HUGO_BIN_DIR)/hugo && \
		rm -rf "$$TMPDIR"; \
		echo "✓ hugo installed to $(HUGO_BIN_DIR)/hugo"; \
		case ":$$PATH:" in \
		  *":$(HUGO_BIN_DIR):"*) ;; \
		  *) echo ""; \
		     echo "⚠ $(HUGO_BIN_DIR) is not on your PATH."; \
		     echo "  Add this to your shell rc:"; \
		     echo "    export PATH=\"\$$PATH:$(HUGO_BIN_DIR)\"" ;; \
		esac; \
	fi

serve: install-hugo ## Run the local dev server (http://localhost:1313)
	@$(HUGO) server --buildDrafts --disableFastRender

build: install-hugo ## Build the production site into ./public
	@rm -rf public
	@$(HUGO) --minify
	@echo "✓ Built to ./public"

clean: ## Remove generated files
	@rm -rf public resources .hugo_build.lock
	@echo "✓ Cleaned"

new-post: install-hugo ## Create a new event page (usage: make new-post NAME=my-event)
	@if [ -z "$(NAME)" ]; then \
		echo "Usage: make new-post NAME=my-event"; \
		exit 1; \
	fi
	@$(HUGO) new events/$(NAME).md
	@echo "✓ Created content/events/$(NAME).md"

check: install-hugo ## Validate the site builds without warnings
	@$(HUGO) --printPathWarnings --printUnusedTemplates --minify --destination /tmp/louisville-dba-check
	@rm -rf /tmp/louisville-dba-check
	@echo "✓ Site builds cleanly"
