test:
	./frontend.pl cvs.templates cvs.config

clean:
	find . -name \*~ | xargs rm -f
