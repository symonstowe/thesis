# $Id $

################################################
# You (may) need:                              #
#    tex2pdf     http://tex2pdf.berlios.de/    #
#    latex2html  http://www.latex2html.org/    #
################################################


##### Variables #############
#############################

# Basename for result
TARGET=proposal

# Title & Author for pdf
AUTHOR=SymonStowe

# Sources
INPUTS=proposal.tex title.tex acknowledgements.tex abstract.tex abbrev_body.tex chapter1_body.tex

# Compiler 
COMPILER = pdflatex --halt-on-error

# ATTENTION!
# File-extensions to delete recursive from here
EXTENSION=aux toc idx ind ilg log out lof lot lol bbl blg

#############################
#############################

##### Targets ###############
#############################

${TARGET}.pdf: $(INPUTS)
	${COMPILER} ${TARGET}.tex
	${COMPILER} ${TARGET}.tex

#Clean
clean:
	for EXT in ${EXTENSION}; \
	do \
	find `pwd` -name \*\.$${EXT} -exec rm -v \{\} \; ;\
	done
#	rm -f ${TARGET}.dvi
#       rm -f ${TARGET}.ps
