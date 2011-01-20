all :
	install -d puredatadir
	$(MAKE) DEST='puredatadir/' ARCH='puredata.cpp' LIB='' -f Makefile.pdcompile

jackqt :
	install -d jackqtdir
	$(MAKE) DEST='jackqtdir/' ARCH='jack-qt.cpp' LIB='-ljack' -f Makefile.qtcompile

clean :
	rm -rf *dir
	rm -rf *-svg