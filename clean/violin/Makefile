all :
	install -d puredatadir
	$(MAKE) DEST='puredatadir/' ARCH='puredata.cpp' INC='-I/opt/local/include' LIB='-L/opt/local/lib' -f Makefile.pdcompile

plot :
	install -d plotdir
	$(MAKE) DEST='plotdir/' ARCH='plot.cpp' LIB='-I ./' -f Makefile.compile

jackqt :
	install -d jackqtdir
	$(MAKE) DEST='jackqtdir/' ARCH='jack-qt.cpp' LIB='-ljack' -f Makefile.qtcompile

svg:
	$(MAKE) -f Makefile.svgcompile

clean :
	rm -rf *dir
	rm -rf *-svg
