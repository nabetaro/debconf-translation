FILES=$(patsubst %.xml,%.txt,$(wildcard *.xml)) \
      $(patsubst %.xml,%.html,$(wildcard *.xml))

base: tutorial.html tutorial.txt

all: $(FILES)
	./graph.pl `find .. -name \*.pm` > hierarchy.txt

%.html: %.xml html.dsl
	jade -V nochunks -t sgml -d html.dsl \
		/usr/lib/sgml/declaration/xml.dcl $< > $@
	-tidy -i -m -f /dev/null $@

%.txt: %.html
	perl -pe 's/[\r\0]//g' $< > $<.new ;html2text -style pretty -nobs $<.new > $@
	rm -f $<.new

clean:
	rm -f $(FILES) hierarchy.txt *.css *.html
