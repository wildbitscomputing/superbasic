.PHONY: html pdf livehtml clean

html:
	sphinx-build -b html . _build/html

pdf:
	sphinx-build -b latex . _build/latex
	cd _build/latex && xelatex f256-superbasic.tex && xelatex f256-superbasic.tex

livehtml:
	sphinx-autobuild . _build/html --port 8000

clean:
	rm -rf _build
