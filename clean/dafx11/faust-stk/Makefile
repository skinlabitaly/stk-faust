NAME = DAFx11-Faust-STK

all: $(NAME).tex ref.bib
	pdflatex $(NAME)
	bibtex $(NAME)
	pdflatex $(NAME)
	pdflatex $(NAME)

pdf p: $(NAME).pdf

pdfo po: $(NAME).pdf
	open $(NAME).pdf

clean:
	/bin/rm $(NAME).dvi $(NAME).aux *~ $(NAME).log $(NAME).out $(NAME).bbl $(NAME).d $(NAME).bak $(NAME).blg
