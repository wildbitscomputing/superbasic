.PHONY: html pdf livehtml clean

# Mermaid CLI needs a Chrome headless shell; point it at whatever is cached.
CHROME_HS := $(firstword $(wildcard $(HOME)/.cache/puppeteer/chrome-headless-shell/*/chrome-headless-shell-*/chrome-headless-shell))
export PUPPETEER_EXECUTABLE_PATH := $(CHROME_HS)

html:
	uv run sphinx-build -b html . _build/html

pdf:
	uv run sphinx-build -b latex . _build/latex
	cd _build/latex && xelatex f256-superbasic.tex && xelatex f256-superbasic.tex

livehtml:
	uv run sphinx-autobuild . _build/html --port 8000

clean:
	rm -rf _build
