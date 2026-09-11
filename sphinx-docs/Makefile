.PHONY: format html pdf livehtml clean

format:
	uv run mdformat .

html:
	uv run sphinx-build -b html . _build/html

help:
	uv run sphinx-build -b wildbits-help . _build/help

pdf:
	uv run sphinx-build -b latex . _build/latex
	cd _build/latex && xelatex f256-superbasic.tex && xelatex f256-superbasic.tex

livehtml:
	uv run sphinx-autobuild . _build/html --port 8000

clean:
	rm -rf _build
