# Install python dependencies
install:
    uv sync

build-html-docs:
    make -C sphinx-docs html

build-pdf-docs:
    make -C sphinx-docs pdf

build-docs: build-html-docs build-pdf-docs
