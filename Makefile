test:
	./test.pl $(FRONTEND) samples/$(PACKAGE).templates samples/$(PACKAGE).config

clean:
	find . -name \*~ | xargs rm -f
