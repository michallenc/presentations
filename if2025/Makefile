TARGETS = if2025.pdf

all: $(TARGETS)

.PHONNY: clean prepare

-include $(TARGETS:%=%.deps)

$(TARGETS): %.pdf: %.tex
	pdflatex $<
	#latexmk $< # See also .latexmkrc

%.png: %.svg
	inkscape --export-area-drawing --export-png=$@ --export-background-opacity=1.0 $<

%.pdf: %.svg
	inkscape --export-pdf=$@ $<

clean:
	rm -f $(foreach ext, nav out toc aux pdf dvi pyg fdb_latexmk snm fls synctex.gz log, \
	        $(TARGETS:%.pdf=%.$(ext)))

prepare: $(patsubst %.svg,%.pdf,$(wildcard *.svg))
