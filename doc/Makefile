all: manpages
	./graph.pl `find .. -name \*.pm` > hierarchy.txt

pod2man=pod2man -c Debconf -r '' --utf8
manpages:
	cd man && po4a po4a/po4a.cfg
	for pod in man/*.pod; do \
		perl -pi -e 'if (not $$seen and /^=head1/) { print "=encoding UTF-8\n\n"; $$seen = 1; }' $$pod; \
	done
	install -d man/gen
	for num in 1 3 8; do \
		find man -maxdepth 1 -type f -name "*.$$num.pod" -printf '%P\n' | \
			xargs -i sh -c "cd man ; $(pod2man) --section=$$num {} > gen/\`basename {} .pod\`"; \
	done
	$(pod2man) --section=3 ../Debconf/Client/ConfModule.pm \
		> man/gen/Debconf::Client::ConfModule.3pm
	find .. -maxdepth 1 -perm +100 -type f \( -name debconf -or -name 'debconf-*' \) -printf '%P\n' | \
		xargs -i sh -c "cd .. ; $(pod2man) --section=1 {} > doc/man/gen/{}.1"
	find .. -maxdepth 1 -perm +100 -type f -name 'dpkg-*' -printf '%P\n' | \
		xargs -i sh -c "cd .. ; $(pod2man) --section=8 {} > doc/man/gen/{}.8"

clean:
	cd man && po4a --rm-translations po4a/po4a.cfg
	rm -f man/po4a/po/*~
	rm -f hierarchy.txt
	rm -rf man/gen
