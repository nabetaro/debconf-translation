FILES=$(patsubst %.xml,%.txt,$(wildcard *.xml)) \
      $(patsubst %.xml,%.html,$(wildcard *.xml))

all: $(FILES)
	./graph.pl `find .. -name \*.pm` > hierarchy.txt
	-$(MAKE) -C spec all

%.html: %.xml html.dsl
	jade -V nochunks -t sgml -d html.dsl \
		/usr/lib/sgml/declaration/xml.decl $< | sed 's/&#13;//' > $@

%.txt: %.html
	w3m -dump $< > $@
#	lynx -dump $< > $@

clean:
	rm -f $(FILES) hierarchy.txt *.css *.html
	-$(MAKE) -C spec clean
