test:
	./frontend.pl samples/cvs.templates samples/cvs.config

test2:
	./frontend.pl samples/exim.templates samples/exim.config

clean:
	find . -name \*~ | xargs rm -f
