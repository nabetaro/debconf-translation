FILES=$(patsubst %.xml,%.txt,$(wildcard *.xml)) \
      $(patsubst %.xml,%.html,$(wildcard *.xml))

all: $(FILES)
	./graph.pl `find .. -name \*.pm` > hierarchy.txt

%.html: %.xml html.dsl
	jade -V nochunks -t sgml -d html.dsl \
		/usr/lib/sgml/declaration/xml.dcl $< > $@
	-tidy -i -m -f /dev/null $@

%.txt: %.html
	links -dump $< | perl -pe 's/[\r\0]//g' > $@

clean:
	rm -f $(FILES) hierarchy.txt *.css *.html
