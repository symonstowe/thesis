all: sub carleton_presentation.pdf
sub:
	cd imgs && $(MAKE) all 
latexmk = lualatex
%.pdf: %.tex 
	$(latexmk) $<
	$(latexmk) -c $<
	ls -alh $@
