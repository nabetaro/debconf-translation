#!/usr/bin/perl

use Debconf::Db;

Debconf::Db->load;

# A bug in debconf between 0.5.x and 0.9.79 caused some shared templates
# owners to not be registered. The fix is nasty; we have to load up all
# templates belonging to all installed packages all over again.
foreach my $templatefile (glob("/var/lib/dpkg/info/*.templates")) {
	my ($package) = $templatefile =~ m:/var/lib/dpkg/info/(.*?).templates:;

        Debconf::Template->load($templatefile, $package);
}

Debconf::Db->save;
