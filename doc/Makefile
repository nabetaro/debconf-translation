all: tutorial.html tutorial.txt introduction.html introduction.txt
	./graph.pl `find .. -name \*.pm` > hierarchy.txt

%.html: %.xml
	jade -t sgml -V nochunks -d \
		 /usr/lib/sgml/stylesheet/dsssl/docbook/nwalsh/html/docbook.dsl \
		/usr/lib/sgml/declaration/xml.decl $< > $@

%.txt: %.html
	lynx -force_html -nolist -dump $< > $@

clean:
	rm -f hierarchy.txt tutorial.html tutorial.css tutorial.txt \
		introduction.html introduction.css introduction.txt
