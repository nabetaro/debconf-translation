FILES=$(patsubst %.xml,%.txt,$(wildcard *.xml)) \
      $(patsubst %.xml,%.html,$(wildcard *.xml))

all: $(FILES) spec
	./graph.pl `find .. -name \*.pm` > hierarchy.txt
	-$(MAKE) -C spec all

%.html: %.xml html.dsl
	jade -V nochunks -t sgml -d html.dsl \
		/usr/lib/sgml/declaration/xml.decl $< | sed 's/&#13;//' > $@

%.txt: %.html
	w3m -dump $< > $@
#	lynx -dump $< > $@

clean: spec
	rm -f $(FILES) hierarchy.txt *.css *.html
	-$(MAKE) -C spec clean

# Spec is in a different cvs repository, make sure it's available.
# This is mostly for my own loacal use; I ship it in the source package.
spec:
	cvs -d :ext:joeyh@cvs.debian.org:/var/cvs/debconf co spec
