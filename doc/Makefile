all: tutorial.html tutorial.txt introduction.html introduction.txt
	./graph.pl `find .. -name \*.pm` > hierarchy.txt

%.html: %.xml html.dsl
	jade -V nochunks -t sgml -d html.dsl \
		/usr/lib/sgml/declaration/xml.decl $< > $@

%.txt: %.html
	lynx -underscore -force_html -nolist -dump $< > $@

clean:
	rm -f hierarchy.txt *.css *.html tutorial.txt introduction.txt
