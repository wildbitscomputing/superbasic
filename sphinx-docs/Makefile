.PHONY: format html pdf livehtml clean

format:
	uv run mdformat .

html:
	uv run sphinx-build -b html . _build/html

help:
	uv run sphinx-build -b wildbits-help . _build/help

GRC_LATEX_CONFIG := $(abspath .grc/latex.conf)

pdf:
	uv run sphinx-build \
	    -b latex \
		-D pygments_style=superbasic_style.PDFStyle \
	    . _build/latex

	cd _build/latex && grc -c $(GRC_LATEX_CONFIG) xelatex \
    	-interaction=nonstopmode \
    	-halt-on-error \
    	-file-line-error \
    	f256-superbasic.tex \
        && xelatex f256-superbasic.tex

livehtml:
	uv run sphinx-autobuild . _build/html --port 8000

clean:
	rm -rf _build
