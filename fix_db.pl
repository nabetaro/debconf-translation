#!/usr/bin/perl -w
use strict;
use Debconf::Db;
use Debconf::Log q{warn};

Debconf::Db->load;

if (! @ARGV || $ARGV[0] ne 'end') {
	# These actions need to be repeated until the db is consistent.
	my $fix=0;
	my $ok;
	my $counter=0;
	do {
		$ok=1;
	
		# There is no iterator method in the templates object, so I will do
		# some nasty hacking to get them all. Oh well. Nothing else needs to 
		# iterate templates..
		my %templates=();
		my $ti=$Debconf::Db::templates->iterator;
		while (my $t=$ti->iterate) {
			$templates{$t}=Debconf::Template->get($t);
		}
	
		my %questions=();
		my $qi=Debconf::Question->iterator;
		while (my $q=$qi->iterate) {
			# I have seen instances where a question would have no associated
			# template field. Always a bug.
			if (! defined $q->template) {
				warn "question \"".$q->name."\" has no template field; removing it.";
				$q->addowner("killme",""); # make sure it has one owner at least, so removal is triggered
				foreach my $owner (split(/, /, $q->owners)) {
					$q->removeowner($owner);
				}
				$ok=0;
				$fix=1;
			}
			elsif (! exists $templates{$q->template->template}) {
				warn "question \"".$q->name."\" uses nonexistant template ".$q->template->template."; removing it.";
				foreach my $owner (split(/, /, $q->owners)) {
					$q->removeowner($owner);
				}
				$ok=0;
				$fix=1;
			}
			else {
				$questions{$q->name}=$q;
			}
		}
		
		# I had a report of a templates db that had templates that claimed to
		# be owned by their matching questions -- but the questions didn't exist!
		# Check for such a thing.
		foreach my $t (keys %templates) {
			# Object has no owners method (not otherwise needed), so I'll do 
			# some nasty grubbing.
			my @owners=$Debconf::Db::templates->owners($t);
			if (! @owners) {
				warn "template \"$t\" has no owners; removing it.";
				$Debconf::Db::templates->addowner($t, "killme","");
				$Debconf::Db::templates->removeowner($t, "killme");
				$fix=1;
			}
			foreach my $q (@owners) {
				if (! exists $questions{$q}) {
					warn "template \"$t\" claims to be used by nonexistant question \"$q\"; removing that.";
					$Debconf::Db::templates->removeowner($t, $q);
					$ok=0;
					$fix=1;
				}
			}
		}
		$counter++;
	} until ($ok || $counter > 20);

	# If some fixes were done, save them and then fork a new process
	# to do the final fixes. Seems to be necessary to do this is the db was
	# really screwed up.
	if ($fix) {
		Debconf::Db->save;
		exec($0, "end");
		die "exec of self failed";
	}
}

# A bug in debconf between 0.5.x and 0.9.79 caused some shared templates
# owners to not be registered. The fix is nasty; we have to load up all
# templates belonging to all installed packages all over again.
# This also means that if any of the stuff above resulted in a necessary
# question and template being deleted, it will be reinstated now.
foreach my $templatefile (glob("/var/lib/dpkg/info/*.templates")) {
	my ($package) = $templatefile =~ m:/var/lib/dpkg/info/(.*?).templates:;
        Debconf::Template->load($templatefile, $package);
}

Debconf::Db->save;
