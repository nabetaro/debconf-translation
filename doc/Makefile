all: tutorial.html tutorial.txt introduction.html introduction.txt
	./graph.pl `find .. -name \*.pm` > hierarchy.txt
	$(MAKE) -C spec all

%.html: %.xml html.dsl
	jade -V nochunks -t sgml -d html.dsl \
		/usr/lib/sgml/declaration/xml.decl $< | sed 's/&#13;//' > $@

%.txt: %.html
	w3m -dump $< > $@

clean:
	rm -f hierarchy.txt *.css *.html tutorial.txt introduction.txt
	$(MAKE) -C spec clean
