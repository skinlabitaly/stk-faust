NAME = dafx11-jos-rm

all: $(NAME).tex $(NAME).bib
	pdflatex $(NAME)
	bibtex $(NAME)
	pdflatex $(NAME)
	pdflatex $(NAME)

pdf p: all

pdfo po: $(NAME).pdf
	open $(NAME).pdf

clean:
	-/bin/rm $(NAME).dvi $(NAME).aux *~ $(NAME).log $(NAME).out $(NAME).bbl $(NAME).d $(NAME).bak $(NAME).blg

tclean: clean
	-/bin/rm eps/*-eps-converted-to.pdf
	/bin/rm $(NAME).pdf

